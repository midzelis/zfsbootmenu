#!/bin/bash
# vim: softtabstop=2 shiftwidth=2 expandtab

check() {
  # Do not include this module by default; it must be requested
  return 255
}

depends() {
  echo bash udev-rules
  return 0
}


install_essential_mods() {
   instmods -c "$1"
}

install_zbm_resource() {
  local fatal=$1
  local command=$2
  local item=$3
  local msg=$4
  if ! $command "$item"; then
    if (( fatal == 1 )); then
      # shellcheck disable=SC2059
      [ -n "$msg" ] && dfatal "$(printf "$msg" "$item")"
      exit 1
    else
      # shellcheck disable=SC2059
      [ -n "$msg" ] && dwarning "$(printf "$msg" "$item")"
    fi
  fi
}

expand_pattern() {
  local saved_globstar expanded
  if shopt -q globstar; then
    saved_globstar=-s
  else
    saved_globstar=-u
  fi
  shopt -s globstar
  expanded=$(compgen -G "$1")
  shopt $saved_globstar globstar
  echo "$expanded"
}

install_zbm_resources() {
  local fatal=$1
  local command=$2
  local -n array=$3
  local msg=$4
  local item
  local dir
  local expanded
  set -x
  for item in "${array[@]}"; do
    # is the pattern a glob pattern?
    if [[ $item =~ [\*\[\{\^\|] ]]; then
      if [ "$command" = inst_library ]; then
        # shellcheck disable=SC2154
        for dir in $libdirs; do
          for expanded in $(expand_pattern "$dir/$item"); do
            install_zbm_resource "$fatal" "$command" "$expanded" "$msg"
          done
        done
      elif [ "$command" = install_essential_mods ] || [ "$command" = instmods ]; then
        # shellcheck disable=SC2154
        for expanded in $(expand_pattern "$srcmods/kernel/$item"); do
          install_zbm_resource "$fatal" "$command" "$expanded" "$msg"
        done
      else 
        for expanded in $(expand_pattern "$item"); do
          install_zbm_resource "$fatal" "$command" "$expanded" "$msg"
        done
      fi
    else
      install_zbm_resource "$fatal" "$command" "$item" "$msg"
    fi
  done
}

install_optional_file() {
  if [ -f "$1" ]; then
    inst "$1"
  else
    return 1
  fi
}

install_zbm_hooks() {
    local files=$1
    local hookname=$2
    local msg=$2
    local _exec
    if [ -n "${files}" ]; then
      for _exec in ${files}; do
        if [ -x "${_exec}" ]; then
          inst_simple "${_exec}" "/libexec/$hookname/$(basename "${_exec}")"
        else
          dwarning "$(printf  "%s script (%s) missing or not executable; cannot install" "$hookname" "$_exec")"
        fi
      done
    fi
}

installkernel() {
  install_zbm_resources 1 install_essential_mods zfsbootmenu_essential_modules "Required kernel module '%s' is missing, aborting image creation!"
  install_zbm_resources 0 instmods zfsbootmenu_optional_modules 
}

install() {
  : "${zfsbootmenu_module_root:=/usr/share/zfsbootmenu}"

  # shellcheck disable=SC1091
  if ! source "${zfsbootmenu_module_root}/install-helpers.sh" ; then
    dfatal "Unable to source ${zfsbootmenu_module_root}/install-helpers.sh"
    exit 1
  fi

  # BUILDROOT is an initcpio-ism
  # shellcheck disable=SC2154,2034
  BUILDROOT="${initdir}"
  # shellcheck disable=SC2034
  BUILDSTYLE="dracut"

  local  _ret
  set -x
  install_zbm_resources 1 inst_rules zfsbootmenu_udev_rules "failed to install udev rule '%s'"
  install_zbm_resources 1 dracut_install zfsbootmenu_essential_binaries "failed to install essential binary '%s'"
  install_zbm_resources 0 dracut_install zfsbootmenu_optional_binaries "optional binary '%s' could not be installed, omitting from image"
  install_zbm_resources 1 inst_simple zfsbootmenu_essential_files "essential file '%s' could not be installed, omitting from image"
  install_zbm_resources 0 install_optional_file zfsbootmenu_optional_files "optional file '%s' not found, will omit"
  echo "essential libraries"
  install_zbm_resources 1 inst_library zfsbootmenu_essential_libraries "failed to install essential library '%s'"
  install_zbm_resources 0 inst_library zfsbootmenu_optional_libraries "optional library '%s' not found, will omit"

  # Add libgcc_s as appropriate
  local _libgcc_s
  if ! _libgcc_s="$( find_libgcc_s )"; then
    dfatal "Unable to locate libgcc_s.so"
    exit 1
  fi

  local _lib
  while read -r _lib ; do
    [ -n "${_lib}" ] || continue
    if ! dracut_install "${_lib}"; then
      dfatal "Failed to install '${_lib}'"
      exit 1
    fi
  done <<< "${_libgcc_s}"

  # shellcheck disable=SC2154
  while read -r doc ; do
    relative="${doc//${zfsbootmenu_module_root}\//}"
    inst_simple "${doc}" "/usr/share/docs/${relative}"
  done <<<"$( find "${zfsbootmenu_module_root}/help-files" -type f )"

  compat_dirs=( "/etc/zfs/compatibility.d" "/usr/share/zfs/compatibility.d/" )
  for compat_dir in "${compat_dirs[@]}"; do
    # shellcheck disable=2164
    [ -d "${compat_dir}" ] && tar -cf - "${compat_dir}" | ( cd "${initdir}" ; tar xfp - )
  done
  _ret=0

  # Core ZFSBootMenu functionality
  # shellcheck disable=SC2154
  for _lib in "${zfsbootmenu_module_root}"/lib/*; do
    inst_simple "${_lib}" "/lib/$( basename "${_lib}" )" || _ret=$?
  done

  # Helper tools not intended for direct human consumption
  for _libexec in "${zfsbootmenu_module_root}"/libexec/*; do
    inst_simple "${_libexec}" "/libexec/$( basename "${_libexec}" )" || _ret=$?
  done

  # User-facing utilities, useful for running in a recovery shell
  for _bin in "${zfsbootmenu_module_root}"/bin/*; do
    inst_simple "${_bin}" "/bin/$( basename "${_bin}" )" || _ret=$?
  done

  # Hooks necessary to initialize ZBM
  inst_hook cmdline 95 "${zfsbootmenu_module_root}/hook/zfsbootmenu-parse-commandline.sh" || _ret=$?
  inst_hook pre-mount 90 "${zfsbootmenu_module_root}/hook/zfsbootmenu-preinit.sh" || _ret=$?

  # Hooks to force the dracut event loop to fire at least once
  # Things like console configuration are done in optional event-loop hooks
  inst_hook initqueue/settled 99 "${zfsbootmenu_module_root}/hook/zfsbootmenu-ready-set.sh" || _ret=$?
  inst_hook initqueue/finished 99 "${zfsbootmenu_module_root}/hook/zfsbootmenu-ready-chk.sh" || _ret=$?

  # optionally enable early Dracut profiling
  if [ -n "${dracut_trace_enable}" ]; then
    inst_hook cmdline 00 "${zfsbootmenu_module_root}/profiling/profiling-lib.sh"
  fi

echo "start hooks"
set -x

  # Install keyprompt - there can only be one
  # shellcheck disable=SC2154
  if [ -x "${zfsbootmenu_keyprompt}" ]; then
    inst_simple "${zfsbootmenu_keyprompt}" "/libexec/keyprompt.sh" || _ret=$?
  else
    dwarning "setup script (${zfsbootmenu_keyprompt}) missing or not executable; cannot install"
  fi

  # Install "preprompt" hooks
  # shellcheck disable=SC2154
  install_zbm_hooks "$zfsbootmenu_preprompt" preprompt.d || _ret=$?
  # Install "early setup" hooks
  # shellcheck disable=SC2154
  install_zbm_hooks "$zfsbootmenu_early_setup" early-setup.d || _ret=$?
  # Install "setup" hooks
  # shellcheck disable=SC2154
  install_zbm_hooks "$zfsbootmenu_setup" setup.d || _ret=$?
  # Install "teardown" hooks
  # shellcheck disable=SC2154
  install_zbm_hooks "$zfsbootmenu_teardown" teardown.d || _ret=$?

  if [ ${_ret} -ne 0 ]; then
    dfatal "Unable to install core ZFSBootMenu functions"
    exit 1
  fi

  # vdev_id.conf and hostid files are host-specific
  # and do not belong in public release images
  if [ -z "${release_build}" ]; then
    if [ -e /etc/zfs/vdev_id.conf ]; then
      inst /etc/zfs/vdev_id.conf
      type mark_hostonly >/dev/null 2>&1 && mark_hostonly /etc/zfs/vdev_id.conf
    fi

    # Try to synchronize hostid between host and ZFSBootMenu
    #
    # DEPRECATION NOTICE: on musl systems, zfs < 2.0 produced a bad hostid in
    # dracut images. Unfortunately, this should be replicated for now to ensure
    # those images are bootable. After some time, remove this version check.
    ZVER="$( zfs version | head -n1 | sed 's/zfs-\(kmod-\)\?//' )"
    if [ -n "${ZVER}" ] && printf '%s\n' "${ZVER}" "2.0" | sort -VCr; then
      NEWZFS=yes
    else
      NEWZFS=""
    fi

    if [ -n "${NEWZFS}" ] && [ -e /etc/hostid ]; then
      # With zfs >= 2.0, prefer the hostid file if it exists
      inst /etc/hostid
    elif HOSTID="$( hostid 2>/dev/null )"; then
      # Fall back to `hostid` output when it is nonzero or with zfs < 2.0
      if [ -z "${NEWZFS}" ]; then
        # In zfs < 2.0, zgenhostid does not provide necessary behavior
        echo -ne "\\x${HOSTID:6:2}\\x${HOSTID:4:2}\\x${HOSTID:2:2}\\x${HOSTID:0:2}" > "${initdir}/etc/hostid"
      elif [ "${HOSTID}" != "00000000" ]; then
        # In zfs >= 2.0, zgenhostid writes the output, but only with nonzero hostid
        # shellcheck disable=SC2154
        zgenhostid -o "${initdir}/etc/hostid" "${HOSTID}"
      fi
    fi
  fi

  # shellcheck disable=SC2154
  if [ -e "${initdir}/etc/hostid" ] && type mark_hostonly >/dev/null 2>&1; then
    mark_hostonly /etc/hostid
  fi

  # Embed a kernel command line in the initramfs
  # shellcheck disable=SC2154
  if [ -n "${embedded_kcl}" ]; then
    echo "export embedded_kcl=\"${embedded_kcl}\"" >> "${initdir}/etc/zfsbootmenu.conf"
  fi

  # Force rd.hostonly=0 in the KCL for releases, this will purge itself after 99base/init.sh runs
  # shellcheck disable=SC2154
  if [ -n "${release_build}" ]; then
    echo "rd.hostonly=0" > "${initdir}/etc/cmdline.d/hostonly.conf"
  fi

  create_zbm_conf
  create_zbm_profiles
  create_zbm_traceconf
}
