
#shellcheck disable=SC1091
source /lib/zfsbootmenu-kcl.sh || exit 1
source /lib/kmsg-log-lib.sh || exit 1

if [ -z "${control_term}" ] && [ -f /etc/zfsbootmenu.conf ]; then
  #shellcheck disable=SC1091
  source /etc/zfsbootmenu.conf
fi

[ -c "${control_term}" ] || exit 1

# Ensure that control_term is not a serial console
tty_re='/dev/tty[0-9]'
[[ ${control_term} =~ ${tty_re} ]] || exit 1

if get_zbm_bool 1 zbm.autosize && ! font=$( get_zbm_arg rd.vconsole.font ) ; then
    setfont /fonts/Terminus/PSF/ter-powerline-v20b.psf.gz >/dev/null 2>&1
    if [ "${COLUMNS}" -ge 100 ]; then
        zdebug "set font to ${font}, screen is ${COLUMNS}x${LINES}"
    fi
fi
