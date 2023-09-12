#!/bin/bash

# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

SRC_ROOT=${SRC_ROOT:-$(dirname "$(dirname "$(dirname "$DIR")")")}
COOKBOOK_ROOT=${COOKBOOK_ROOT:-${SRC_ROOT}/contrib/cookbook}
RECIPES_ROOT=${RECIPES_ROOT:-${SRC_ROOT}/contrib/cookbook/recipes}
ZBM_BUILDER=$(realpath "${ZBM_BUILDER:-${SRC_ROOT}/zbm-builder.sh}")
DOCKER_ROOT=$SRC_ROOT/releng/docker
GENERATE_ZBM=$SRC_ROOT/bin/generate-zbm
ARGS_AFTER_TWO=("${@:2}")
RECIPE_BUILDER="recipe-builder"
OUTPUT_DIR=${COOKBOOK_ROOT}/output

DOCKER=docker # or podman or buildah bud

debug=
debug="--entrypoint=/bin/bash"

# shellcheck disable=SC2034
loglevel=4
# shellcheck disable=SC1091
source "$SRC_ROOT/zfsbootmenu/lib/echo-log-lib.sh"

if which yq-go >/dev/null; then
    YG=yq-go
elif which yq >/dev/null; then
    YG=yq
else
    echo "yq (or yq-go) is required"
    exit 1
fi

# any additional mounts
additional_mounts=(
    # this will be removed before PR
    "-v $COOKBOOK_ROOT/bin/debug-build-raw.sh:/rc.stop.d/debug-build-raw.sh"
)

# shellcheck disable=SC2317
oci_init() {
    packages=()
    # shellcheck disable=SC2016
    mapfile -t -O "${#packages[@]}" packages < <($YG eval-all '. as $item ireduce ({}; . *+ $item) | (... | select(type == "!!seq")) |= unique | .xbps-packages[] | .. style=""' "$COOKBOOK_ROOT"/etc/base-package.yaml "$RECIPES_ROOT"/*/package.yaml)
    ( 
        cd "$DOCKER_ROOT" || exit 1;
        zinfo "Build command: " "$DOCKER" build . -t "$RECIPE_BUILDER" --build-arg "KERNELS=linux6.1" --build-arg "PACKAGES=${packages[*]}"
        $DOCKER build . -t "$RECIPE_BUILDER" --build-arg "KERNELS=linux6.1" --build-arg "PACKAGES=${packages[*]}"
    )
    #alternative "$IMAGE_BUILDER" "${packages[@]/#/"-p "}" "$RECIPE_BUILDER"
}

# shellcheck disable=SC2317
oci_build() {
    echo "Merging configs for recipes"
    # shellcheck disable=SC2016
    merged=$($YG eval-all '. as $item ireduce ({}; . *+ $item) | (... | select(type == "!!seq")) |= unique' "$COOKBOOK_ROOT"/etc/base-config.yaml "$RECIPES_ROOT"/*/config.yaml)
    zinfo "$merged" | $YG 
    TMPFILE=$(mktemp)
    echo "$merged" > "$TMPFILE"
    if [[ $(df . -TP  | tail -n -1 | awk '{print $2}') == nfs* ]]; then
        ZBM_DST=/zbm_alt
        ALTMOUNT=/alt
    else   
        ZBM_DST=/zbm
        ALTMOUNT=""
    fi

    # mount any recipe specific rc.d files
    mounts=()
    for file in "$RECIPES_ROOT"/*/rc.d/*; do
        [ -e "$file" ] || continue
        base=$(basename "$file")
        mounts+=("-v $file:/rc.d/$base")
    done
    # mount any recipe specific mounts
    for file in "$RECIPES_ROOT"/*/package.yaml; do
        mounts+=("$(ALTMOUNT=$ALTMOUNT BASENAME=$(dirname "$file") $YG e '.mount | "-v " + env(BASENAME) + "/" + (.src) + ":" + env(ALTMOUNT) + (.dst)' "$file")")
    done

    mkdir -p "$OUTPUT_DIR"
    # shellcheck disable=SC2068,SC2086
    $DOCKER run --rm -it \
        -v "$SRC_ROOT:$ZBM_DST" \
        ${mounts[@]} \
        ${additional_mounts[@]} \
        -v "${COOKBOOK_ROOT}/output:/build/build" \
        -v "$TMPFILE:/build/config.yaml" \
        $debug \
        "$RECIPE_BUILDER" -- "${ARGS_AFTER_TWO[@]}"
    # this is DEBUG
    mv -v "$OUTPUT_DIR"/boot-vfs.raw /LUNA/ALPHA/PVE_VIRTUAL_MACHINES/NFS_DISKS/images/2200/vm-2200-disk-0.raw
}

# shellcheck disable=SC2317
build() {
    echo "For a successful build, please make sure your distro packages equivalent to these void-linux packages"
    # shellcheck disable=SC2016
    $YG eval-all '. as $item ireduce ({}; . *+ $item) | (... | select(type == "!!seq")) |= unique | .xbps-packages[]' "$RECIPES_ROOT"/*/package.yaml
    # shellcheck disable=SC2016
    merged=$($YG eval-all '. as $item ireduce ({}; . *+ $item) | (... | select(type == "!!seq")) |= unique' "$RECIPES_ROOT"/base-config.yaml "$RECIPES_ROOT"/*/config.yaml)
    zinfo "$merged" | $YG 
    cpanm --notest --installdeps $SRC_ROOT
    mkdir -pv /etc/zfsbootmenu/dracut.conf.d
    cp -vi "$SRC_ROOT"/etc/zfsbootmenu/release.conf.d/* /etc/zfsbootmenu/dracut.conf.d
    "$GENERATE_ZBM" -c <(echo "$merged") "${ARGS_AFTER_TWO[@]}"

}

cmd=${1:-}
cmds=(oci_init oci_build build)
if [ -n "$cmd" ] && [[ " ${cmds[*]} " =~ $cmd ]]; then
    $cmd
    exit $?
fi
tmp=${cmds[*]}
echo "Enter a command like: ${tmp// /, }"
exit 1