#!/bin/sh

set -e

# script exit codes:
#   1: missing utility

main() {
    local utag='v2023.07.02'
    local atf_file='../rkbin/rk3568_bl31_v1.28.elf'
    local tpl_file='../rkbin/rk3568_ddr_1560MHz_v1.15.bin'

    # branch name is yyyy.mm
    local branch="$(echo "$utag" | sed -rn 's/.*(20[2-9][3-9]\.[0-1][0-9]).*/\1/p')"
    echo "branch: $branch"

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

    rm -f idbloader.img u-boot.itb
    if ! is_param 'inc' "$@"; then
        make -C u-boot distclean
    fi

    # outputs: idbloader-r5c.img & u-boot-r5c.itb
    make -C u-boot nanopi-r5c-rk3568_defconfig
    make -C u-boot -j$(nproc) BL31="$atf_file" ROCKCHIP_TPL="$tpl_file"
    cp u-boot/idbloader.img idbloader-r5c.img
    cp u-boot/u-boot.itb u-boot-r5c.itb

    # outputs: idbloader-r5s.img & u-boot-r5s.itb
    make -C u-boot nanopi-r5s-rk3568_defconfig
    make -C u-boot -j$(nproc) BL31="$atf_file" ROCKCHIP_TPL="$tpl_file"
    cp u-boot/idbloader.img idbloader-r5s.img
    cp u-boot/u-boot.itb u-boot-r5s.itb

    is_param 'cp' "$@" && cp_to_debian

    echo "\n${cya}idbloader and u-boot binaries are now ready${rst}\n"
    echo "${cya}copy nanopi r5c images to media:${rst}"
    echo "  ${cya}sudo dd bs=4K seek=8 if=idbloader-r5c.img of=/dev/sdX conv=notrunc${rst}"
    echo "  ${cya}sudo dd bs=4K seek=2048 if=u-boot-r5c.itb of=/dev/sdX conv=notrunc,fsync${rst}"
    echo
    echo "${cya}copy nanopi r5s images to media:${rst}"
    echo "  ${cya}sudo dd bs=4K seek=8 if=idbloader-r5s.img of=/dev/sdX conv=notrunc${rst}"
    echo "  ${cya}sudo dd bs=4K seek=2048 if=u-boot-r5s.itb of=/dev/sdX conv=notrunc,fsync${rst}"
    echo
}

cp_to_debian() {
    local deb_dist=$(cat "../debian/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')
    [ -z "$deb_dist" ] && return
    local cdir="../debian/cache.$deb_dist"
    echo '\ncopying to debian cache...'
    sudo mkdir -p "$cdir"
    sudo cp -v './idbloader-r5c.img' "$cdir"
    sudo cp -v './u-boot-r5c.itb' "$cdir"
    sudo cp -v './idbloader-r5s.img' "$cdir"
    sudo cp -v './u-boot-r5s.itb' "$cdir"
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

