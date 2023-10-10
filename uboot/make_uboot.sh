#!/bin/sh

set -e

# script exit codes:
#   1: missing utility
#   6: invalid config

main() {
    local utag='v2023.10'
    local atf_file='../rkbin/rk3568_bl31_v1.28.elf'
    local tpl_file='../rkbin/rk3568_ddr_1560MHz_v1.15.bin'

    # branch name is yyyy.mm[-rc]
    local branch="$(echo "$utag" | grep -Po '\d{4}\.\d{2}(.*-rc\d)*')"
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

        cherry_pick

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

cherry_pick() {
    # pci: pcie_dw_rockchip: Configure number of lanes and link width speed
    # https://github.com/u-boot/u-boot/commit/9af0c7732bf1df29138bb63712dc3fcbc6d821af
    git -C u-boot cherry-pick 9af0c7732bf1df29138bb63712dc3fcbc6d821af

    # phy: rockchip: snps-pcie3: Refactor to use clk_bulk API
    # https://github.com/u-boot/u-boot/commit/3b39592e8e245fc5c7b0a003ac65672ce9cfaf0f
    git -C u-boot cherry-pick 3b39592e8e245fc5c7b0a003ac65672ce9cfaf0f

    # phy: rockchip: snps-pcie3: Refactor to use a phy_init ops
    # https://github.com/u-boot/u-boot/commit/6cacdf842db5e62e9c26d015eddadd2f2410a6de
    git -C u-boot cherry-pick 6cacdf842db5e62e9c26d015eddadd2f2410a6de

    # phy: rockchip: snps-pcie3: Add bifurcation support for RK3568
    # https://github.com/u-boot/u-boot/commit/1ebebfcc25bc8963cbdc6e35504160e5b745cabd
    git -C u-boot cherry-pick 1ebebfcc25bc8963cbdc6e35504160e5b745cabd

    # phy: rockchip: naneng-combphy: Use signal from comb PHY on RK3588
    # https://github.com/u-boot/u-boot/commit/b37260bca1aa562c6c99527d997c768a12da017b
    git -C u-boot cherry-pick b37260bca1aa562c6c99527d997c768a12da017b

    # rockchip: rk3568-nanopi-r5: Update defconfig for NanoPi R5C and R5S
    # https://github.com/u-boot/u-boot/commit/5b155997d445f770e9a2c0d4a20e4eb13eedfede
    git -C u-boot cherry-pick 5b155997d445f770e9a2c0d4a20e4eb13eedfede

    # rockchip: rk3568-nanopi-r5: Enable PCIe on NanoPi R5C and R5S
    # https://github.com/u-boot/u-boot/commit/a9e9445ea2bb010444621e563a79bc33fe064f9c
    git -C u-boot cherry-pick a9e9445ea2bb010444621e563a79bc33fe064f9c

    # power: regulator: Only run autoset once for each regulator
    # https://github.com/u-boot/u-boot/commit/d99fb64a98af3bebf6b0c134291c4fb89e177aa2
    git -C u-boot cherry-pick d99fb64a98af3bebf6b0c134291c4fb89e177aa2

    # regulator: rk8xx: Return correct voltage for buck converters
    # https://github.com/u-boot/u-boot/commit/04c38c6c4936f353de36be60655f402922292a37
    git -C u-boot cherry-pick 04c38c6c4936f353de36be60655f402922292a37

    # regulator: rk8xx: Return correct voltage for switchout converters
    # https://github.com/u-boot/u-boot/commit/bb657ffdd688dc08073734a402914ec0a8492d53
    git -C u-boot cherry-pick bb657ffdd688dc08073734a402914ec0a8492d53
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

