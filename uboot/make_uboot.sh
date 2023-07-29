#!/bin/sh

set -e

# script exit codes:
#   1: missing utility
#   6: invalid config

main() {
    local utag='v2023.07.02'
    local atf_file='../rkbin/rk3568_bl31_v1.28.elf'
    local tpl_file='../rkbin/rk3568_ddr_1560MHz_v1.15.bin'

    # branch name is yyyy.mm
    local branch="$(echo "$utag" | sed -rn 's/.*(20[2-9][3-9]\.[0-1][0-9]).*/\1/p')"
    echo "${bld}branch: $branch${rst}"

    if is_param 'clean' "$@"; then
        rm -f *.img *.itb
        if [ -d u-boot ]; then
            rm -f u-boot/simple-bin.fit.*
            make -C u-boot distclean
            git -C u-boot clean -f
            git -C u-boot checkout master
            git -C u-boot branch -D "$branch" 2>/dev/null || true
            git -C u-boot pull --ff-only
        fi
        echo '\nclean complete\n'
        exit 0
    fi

    check_installed 'bc' 'bison' 'flex' 'libssl-dev' 'make' 'python3-dev' 'python3-pyelftools' 'python3-setuptools' 'swig'

    if [ ! -d u-boot ]; then
        git clone https://github.com/u-boot/u-boot.git
        git -C u-boot fetch --tags
    fi

    if ! git -C u-boot branch | grep -q "$branch"; then
        git -C u-boot checkout -b "$branch" "$utag"

        local patch
        for patch in patches/*.patch; do
            git -C u-boot am "../$patch"
        done
    elif [ "$branch" != "$(git -C u-boot branch --show-current)" ]; then
        git -C u-boot checkout "$branch"
    fi

    rm -f idbloader*.img u-boot*.itb
    local model models='r5c r5s'
    if is_param 'inc' "$@"; then
        model=$(cat "u-boot/.config" | sed -rn 's/CONFIG_DEFAULT_DEVICE_TREE=\"rk3568-nanopi-(.*)\"/\1/p')
        if [ "_$model" != '_r5c' -a "_$model" != '_r5s' ]; then
            echo "${red}unknown config for incremental build: $model${rst}"
            exit 6
        fi
        echo "\n${bld}incremental build for nanopi-${model}${rst}"
        models="${model}"
    else
        is_param 'r5c' "$@" && ! is_param 'r5s' "$@" && models='r5c'
        is_param 'r5s' "$@" && ! is_param 'r5c' "$@" && models='r5s'
        make -C u-boot distclean
    fi

    for model in $models; do
        if ! is_param 'inc' "$@"; then
            echo "\n${bld}configuring nanopi-${model}${rst}"
            make -C u-boot "nanopi-${model}-rk3568_defconfig"
        fi
        echo "\n${bld}building nanopi-${model}${rst}"
        make -C u-boot -j$(nproc) BL31="$atf_file" ROCKCHIP_TPL="$tpl_file"
        cp 'u-boot/idbloader.img' "idbloader-${model}.img"
        cp 'u-boot/u-boot.itb' "u-boot-${model}.itb"
        is_param 'cp' "$@" && cp_to_debian "${model}"
    done

    echo "\n${cya}idbloader and u-boot binaries are now ready${rst}\n"
    for model in $models; do
        echo "${cya}copy nanopi ${model} images to media:${rst}"
        echo "  ${cya}sudo dd bs=4K seek=8 if=idbloader-${model}.img of=/dev/sdX conv=notrunc${rst}"
        echo "  ${cya}sudo dd bs=4K seek=2048 if=u-boot-${model}.itb of=/dev/sdX conv=notrunc,fsync${rst}"
        echo
    done
}

cp_to_debian() {
    local model="$1"

    local deb_dist=$(cat "../debian/nanopi-${model}/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')
    [ -z "$deb_dist" ] && return

    local cdir="../debian/nanopi-${model}/cache.$deb_dist"
    echo "\ncopying to debian nanopi-${model} cache..."
    sudo mkdir -p "$cdir"
    sudo cp -v "./idbloader-${model}.img" "$cdir"
    sudo cp -v "./u-boot-${model}.itb" "$cdir"
}

check_installed() {
    local item todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
}

is_param() {
    local item match
    for item in "$@"; do
        if [ -z "$match" ]; then
            match="$item"
        elif [ "$match" = "$item" ]; then
            return 0
        fi
    done
    return 1
}

rst='\033[m'
bld='\033[1m'
red='\033[31m'
grn='\033[32m'
yel='\033[33m'
blu='\033[34m'
mag='\033[35m'
cya='\033[36m'
h1="${blu}==>${rst} ${bld}"

cd "$(dirname "$(realpath "$0")")"
main "$@"

