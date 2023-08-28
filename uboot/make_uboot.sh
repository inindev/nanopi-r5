#!/bin/sh

set -e

# script exit codes:
#   1: missing utility
#   6: invalid config

main() {
    local utag='v2023.07.02'
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
    # regulator: implement basic reference counter
    # https://github.com/u-boot/u-boot/commit/4fcba5d556b4224ad65a249801e4c9594d1054e8
    git -C u-boot cherry-pick 4fcba5d556b4224ad65a249801e4c9594d1054e8

    # regulator: rename dev_pdata to plat
    # https://github.com/u-boot/u-boot/commit/29fca9f23a3b730cbf91c18617e25d9d8e3a26b7
    git -C u-boot cherry-pick 29fca9f23a3b730cbf91c18617e25d9d8e3a26b7

    # dm: core: of_access: fix return value in of_property_match_string
    # https://github.com/u-boot/u-boot/commit/15a2865515fdd77d1edbc10e275b7b5a4914aa79
    git -C u-boot cherry-pick 15a2865515fdd77d1edbc10e275b7b5a4914aa79

    # rockchip: rk3568: Add support for FriendlyARM NanoPi R5S
    # https://github.com/u-boot/u-boot/commit/0ef326b5e92ee7c0f3cd27385510eb5c211b10fb
    git -C u-boot cherry-pick 0ef326b5e92ee7c0f3cd27385510eb5c211b10fb

    # rockchip: rk3568: Add support for FriendlyARM NanoPi R5C
    # https://github.com/u-boot/u-boot/commit/6a73211d4bb12d62ce82b33cee7d75d215a3d452
    git -C u-boot cherry-pick 6a73211d4bb12d62ce82b33cee7d75d215a3d452

    # rockchip: rk3568: Fix alloc space exhausted in SPL
    # https://github.com/u-boot/u-boot/commit/52472504e9c48cc1b34e0942c0075cd111ea85f0
    git -C u-boot cherry-pick 52472504e9c48cc1b34e0942c0075cd111ea85f0

    # core: read: add dev_read_addr_size_index_ptr function
    # https://github.com/u-boot/u-boot/commit/5e030632d49367944879e17a6d73828be22edd55
    git -C u-boot cherry-pick 5e030632d49367944879e17a6d73828be22edd55

    # pci: pcie_dw_rockchip: Get config region from reg prop
    # https://github.com/u-boot/u-boot/commit/bed7b2f00b1346f712f849d53c72fa8642601115
    git -C u-boot cherry-pick bed7b2f00b1346f712f849d53c72fa8642601115

    # pci: pcie_dw_rockchip: Use regulator_set_enable_if_allowed
    # https://github.com/u-boot/u-boot/commit/8b001ee59a9d4a6246098c8bc5bb894a752e7c0b
    git -C u-boot cherry-pick 8b001ee59a9d4a6246098c8bc5bb894a752e7c0b

    # pci: pcie_dw_rockchip: Speed up link probe
    # https://github.com/u-boot/u-boot/commit/7ce186ada2ce1ece344dacc20244fb91866e435b
    git -C u-boot cherry-pick 7ce186ada2ce1ece344dacc20244fb91866e435b

    # pci: pcie_dw_rockchip: Disable unused BARs of the root complex
    # https://github.com/u-boot/u-boot/commit/bc6b94b5788677c3633e0331203578ffa706ff4b
    git -C u-boot cherry-pick bc6b94b5788677c3633e0331203578ffa706ff4b

    # regulator: fixed: Add support for gpios prop
    # https://github.com/u-boot/u-boot/commit/f7b8a84a29833b6e6ddac67920d688330b299fa8
    git -C u-boot cherry-pick f7b8a84a29833b6e6ddac67920d688330b299fa8

    # rockchip: clk: clk_rk3568: Add CLK_PCIEPHY2_REF support
    # https://github.com/u-boot/u-boot/commit/583a82d5e2702f2c8aadcd75d416d6e45dd5188a
    git -C u-boot cherry-pick 583a82d5e2702f2c8aadcd75d416d6e45dd5188a

    # rockchip: rk3568-rock-3a: Enable PCIe and NVMe support
    # https://github.com/u-boot/u-boot/commit/a76aa6ffa6cd25eed282147f6e31b9c09272f930
    git -C u-boot cherry-pick a76aa6ffa6cd25eed282147f6e31b9c09272f930

    # rockchip: rk356x: Update PCIe config, IO and memory regions
    # https://github.com/u-boot/u-boot/commit/062b712999869bdd7d6283ab8eed50e5999ac88a
    git -C u-boot cherry-pick 062b712999869bdd7d6283ab8eed50e5999ac88a

    # ata: dwc_ahci: Fix support for other platforms
    # https://github.com/u-boot/u-boot/commit/7af6616c961d213b4bf2cc88003cbd868ea11ffa
    git -C u-boot cherry-pick 7af6616c961d213b4bf2cc88003cbd868ea11ffa

    # cmd: ini: Fix build warning
    # https://github.com/u-boot/u-boot/commit/8c1bb04b5699ce74ad727d4513e1a40a58c9c628
    git -C u-boot cherry-pick 8c1bb04b5699ce74ad727d4513e1a40a58c9c628

    # board: rockchip: Add Hardkernel ODROID-M1
    # https://github.com/u-boot/u-boot/commit/94da929b933668c4b9ece7d56a2a2bb5543198c9
    git -C u-boot cherry-pick 94da929b933668c4b9ece7d56a2a2bb5543198c9

    # Revert "arm: dts: rockchip: radxa-cm3-io, rock-3a: enable regulators for usb"
    # https://github.com/u-boot/u-boot/commit/bec51f3fb316b5a5ccedd7deb2e58ae6d7443cfa
    git -C u-boot cherry-pick bec51f3fb316b5a5ccedd7deb2e58ae6d7443cfa

    # usb: dwc3-generic: Return early when there is no child node
    # https://github.com/u-boot/u-boot/commit/4412a2bf0b674d7438821531a0a19bbcd4b80eda
    git -C u-boot cherry-pick 4412a2bf0b674d7438821531a0a19bbcd4b80eda

    # usb: dwc3-generic: Relax unsupported dr_mode check
    # https://github.com/u-boot/u-boot/commit/6913c30516022f86104c9fbe315499e43eee4ed6
    git -C u-boot cherry-pick 6913c30516022f86104c9fbe315499e43eee4ed6

    # usb: dwc3-generic: Add rk3568 support
    # https://github.com/u-boot/u-boot/commit/caaeac88466f4152bd126e2342765a4b740955ae
    git -C u-boot cherry-pick caaeac88466f4152bd126e2342765a4b740955ae

    # rockchip: rk3568: Use dwc3-generic driver
    # https://github.com/u-boot/u-boot/commit/f8a2d1c108da37fd5202d717c3e428e3dfc12f01
    git -C u-boot cherry-pick f8a2d1c108da37fd5202d717c3e428e3dfc12f01

    # rockchip: rk356x: Sync dtsi from linux v6.4
    # https://github.com/u-boot/u-boot/commit/0e3480c1f72f18f80690f8012404eacb67a61151
    git -C u-boot cherry-pick 0e3480c1f72f18f80690f8012404eacb67a61151

    # rockchip: rk356x-u-boot: Add bootph-all to common pinctrl nodes
    # https://github.com/u-boot/u-boot/commit/a3ef37a08df3c6aa463ad794e1f788d8a24b129c
    git -C u-boot cherry-pick a3ef37a08df3c6aa463ad794e1f788d8a24b129c

    # rockchip: rk356x-u-boot: Use relaxed u-boot,spl-boot-order
    # https://github.com/u-boot/u-boot/commit/f40dcc7d1e74ff5aa5f709918e26cb31277dcea0
    git -C u-boot cherry-pick f40dcc7d1e74ff5aa5f709918e26cb31277dcea0

    # rockchip: rk3568-rock-3a: Fix SPI Flash alias
    # https://github.com/u-boot/u-boot/commit/52f6b96d27c8aabca697ac395e86a3481f1c53b7
    git -C u-boot cherry-pick 52f6b96d27c8aabca697ac395e86a3481f1c53b7

    # power: regulator: rk8xx: Add 500us delay after LDO regulator is enabled
    # https://github.com/u-boot/u-boot/commit/fea7a29cc8d86a0bbcb4bcf740d47924839b1f81
    git -C u-boot cherry-pick fea7a29cc8d86a0bbcb4bcf740d47924839b1f81

    # bootflow: Export setup_fs()
    # https://github.com/u-boot/u-boot/commit/0c0c82b5177e9afb3a248da4d004f3dc48975c91
    git -C u-boot cherry-pick 0c0c82b5177e9afb3a248da4d004f3dc48975c91

    # bootstd: Use a function to detect network in EFI bootmeth
    # https://github.com/u-boot/u-boot/commit/146242cc998ed6e002831d4ff409189353e1960a
    git -C u-boot cherry-pick 146242cc998ed6e002831d4ff409189353e1960a

    # bootstd: Avoid allocating memory for the EFI file
    # https://github.com/u-boot/u-boot/commit/6a8c2f9781cede2a7cb2b95ee6310cd53b1c20e2
    git -C u-boot cherry-pick 6a8c2f9781cede2a7cb2b95ee6310cd53b1c20e2

    # bootstd: Init the size before reading the devicetree
    # https://github.com/u-boot/u-boot/commit/2984d21a28f812c9c1fd2243cc72796f69a61585
    git -C u-boot cherry-pick 2984d21a28f812c9c1fd2243cc72796f69a61585

    # bootstd: Init the size before reading extlinux file
    # https://github.com/u-boot/u-boot/commit/11158aef8939bb6e54361e4dae3809a9cbe78cff
    git -C u-boot cherry-pick 11158aef8939bb6e54361e4dae3809a9cbe78cff
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

