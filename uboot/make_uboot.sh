#!/bin/sh

set -e

# script exit codes:
#   5: invalid file hash

main() {
    local utag='v2023.01'
    local atf_file='../rkbin/rk3568_bl31_v1.28.elf'
    local tpl_file='../rkbin/rk3568_ddr_1560MHz_v1.15.bin'

    if [ '_clean' = "_$1" ]; then
        make -C u-boot distclean
        git -C u-boot clean -f
        git -C u-boot checkout master
        git -C u-boot branch -D $utag 2>/dev/null || true
        git -C u-boot pull --ff-only
        rm -f *.img *.itb
        exit 0
    fi

    check_installed 'bison' 'flex' 'libssl-dev' 'make' 'python3-dev' 'python3-pyelftools' 'python3-setuptools' 'swig'

    if [ ! -d u-boot ]; then
        git clone https://github.com/u-boot/u-boot.git
        git -C u-boot fetch --tags
    fi

    if ! git -C u-boot branch | grep -q $utag; then
        git -C u-boot checkout -b $utag $utag

        cherry_pick

        for patch in patches/*.patch; do
            git -C u-boot am "../$patch"
        done
    elif [ "_$utag" != "_$(git -C u-boot branch --show-current)" ]; then
        git -C u-boot checkout $utag
    fi

    # outputs: idbloader.img & u-boot.itb
    rm -f idbloader.img u-boot.itb
    if [ '_inc' != "_$1" ]; then
        make -C u-boot distclean
        make -C u-boot nanopi5_defconfig
    fi
    make -C u-boot -j$(nproc) BL31=$atf_file ROCKCHIP_TPL=$tpl_file
    ln -sf u-boot/idbloader.img
    ln -sf u-boot/u-boot.itb

    echo "\n${cya}idbloader and u-boot binaries are now ready${rst}"
    echo "\n${cya}copy images to media:${rst}"
    echo "  ${cya}sudo dd bs=4K seek=8 if=idbloader.img of=/dev/sdX conv=notrunc${rst}"
    echo "  ${cya}sudo dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc,fsync${rst}"
    echo
}

cherry_pick() {
    # pinctrl: rockchip: Add pinctrl route types
    # https://github.com/u-boot/u-boot/commit/32b2ea9818c6157bfc077de487b78e78536ab4a8
    git -C u-boot cherry-pick 32b2ea9818c6157bfc077de487b78e78536ab4a8

    # Revert "rockchip: Only call binman when TPL available"
    # https://github.com/u-boot/u-boot/commit/1a45a031d75d8c1e4b63ff72ef5222e491f6481f
    git -C u-boot cherry-pick 1a45a031d75d8c1e4b63ff72ef5222e491f6481f

    # mmc: rockchip_dw_mmc: fix DDR52 8-bit mode handling
    # https://github.com/u-boot/u-boot/commit/ea0f7662531fd360abf300691c85ceff5a0d0397
    git -C u-boot cherry-pick ea0f7662531fd360abf300691c85ceff5a0d0397

    # rockchip: sdram: add basic support for sdram reg info version 3
    # https://github.com/u-boot/u-boot/commit/bde73b14f0f46760f1a0ec84a9474ed93a22e496
    git -C u-boot cherry-pick bde73b14f0f46760f1a0ec84a9474ed93a22e496

    # rockchip: sdram: add dram bank with usable memory beyond 4GB
    # https://github.com/u-boot/u-boot/commit/2ec15cabe973efd9a4f5324b48f566a03c8663d5
    # git -C u-boot cherry-pick 2ec15cabe973efd9a4f5324b48f566a03c8663d5
    git -C u-boot format-patch -1 2ec15cabe973efd9a4f5324b48f566a03c8663d5
    sed -i 's/CFG_SYS_SDRAM_BASE/CONFIG_SYS_SDRAM_BASE/g' u-boot/0001-rockchip-sdram-add-dram-bank-with-usable-memory-beyo.patch
    git -C u-boot am 0001-rockchip-sdram-add-dram-bank-with-usable-memory-beyo.patch
    rm u-boot/0001-rockchip-sdram-add-dram-bank-with-usable-memory-beyo.patch

    # binman: Add support for a rockchip-tpl entry
    # https://github.com/u-boot/u-boot/commit/05b978be5f5c5494044bd749f9b6b38f2bb5e0cc
    # git -C u-boot cherry-pick 05b978be5f5c5494044bd749f9b6b38f2bb5e0cc
    git -C u-boot format-patch -1 05b978be5f5c5494044bd749f9b6b38f2bb5e0cc
    sed -i 's/386,6 +6388,11/077,5 +6079,10/' u-boot/0001-binman-Add-support-for-a-rockchip-tpl-entry.patch
    sed -i "s/self\.assertEqual(\['u-boot', 'atf-2'\],/    'Cannot write symbols to an ELF file without Python elftools',/" u-boot/0001-binman-Add-support-for-a-rockchip-tpl-entry.patch
    sed -i "s/             fdt_util\.GetStringList(node, 'loadables'))/str(exc\.exception))/" u-boot/0001-binman-Add-support-for-a-rockchip-tpl-entry.patch
    sed -ni '/__name__/{x;d;};1h;1!{x;p;};${x;p;}' u-boot/0001-binman-Add-support-for-a-rockchip-tpl-entry.patch
    git -C u-boot am 0001-binman-Add-support-for-a-rockchip-tpl-entry.patch
    rm u-boot/0001-binman-Add-support-for-a-rockchip-tpl-entry.patch

    # rockchip: Use an external TPL binary on RK3568
    # https://github.com/u-boot/u-boot/commit/4773e9d5ed4c12e02759f1d732bb66006139037a
    git -C u-boot cherry-pick 4773e9d5ed4c12e02759f1d732bb66006139037a

    # Revert "board: rockchip: Fix binman_init failure on EVB-RK3568"
    # https://github.com/u-boot/u-boot/commit/d1bdffa8a2409727a270c8edaa5d82fdc4eee1a3
    git -C u-boot cherry-pick d1bdffa8a2409727a270c8edaa5d82fdc4eee1a3

    # rockchip: mkimage: Add rv1126 support
    # https://github.com/u-boot/u-boot/commit/6d70d826f553a321193ad917cd651fc5b12739ac
    git -C u-boot cherry-pick 6d70d826f553a321193ad917cd651fc5b12739ac

    # rockchip: mkimage: Update init size limit for RK3568
    # https://github.com/u-boot/u-boot/commit/5fc5a840d4cf189616aba3a4a7bf10c4ac8edc83
    git -C u-boot cherry-pick 5fc5a840d4cf189616aba3a4a7bf10c4ac8edc83

    # binman: Mark mkimage entry missing when its subnodes is missing
    # https://github.com/u-boot/u-boot/commit/40389c2a462256da7f2348bed791c8ba2ae6eec6

    # arm64: dts: rockchip: rk3568: Add Radxa ROCK 3 Model A board support
    # https://github.com/u-boot/u-boot/commit/b44c54f600abf7959977579f6bfc2670835a52b0
    git -C u-boot cherry-pick b44c54f600abf7959977579f6bfc2670835a52b0

    # rockchip: rk3568: Move DM_RESET in arch kconfig
    # https://github.com/u-boot/u-boot/commit/5f5b1cf3fff1c12d12207e1c415aff9bdcb432cc
    git -C u-boot cherry-pick 5f5b1cf3fff1c12d12207e1c415aff9bdcb432cc

    # dt-bindings: rockchip: Sync rockchip, vop2.h from Linux
    # https://github.com/u-boot/u-boot/commit/1bb92d7cb310dec146abed88b446e983b16150b5
    git -C u-boot cherry-pick 1bb92d7cb310dec146abed88b446e983b16150b5

    # phy: rockchip: inno-usb2: Add support #address_cells = 2
    # https://github.com/u-boot/u-boot/commit/d538efb9adcfa28e238c26146f58e040b0ffdc5b

    # phy: rockchip-inno-usb2: Add USB2 PHY for rk3568
    # https://github.com/u-boot/u-boot/commit/3da15f0b49a22743b6ed5756e4082287a384bc83
    git -C u-boot cherry-pick 3da15f0b49a22743b6ed5756e4082287a384bc83

    # drivers: phy: add naneng combphy for rk3568
    # https://github.com/u-boot/u-boot/commit/82220526ac9887c39d2d5caa567a20378b3122b7
    git -C u-boot cherry-pick 82220526ac9887c39d2d5caa567a20378b3122b7

    # arm64: dts: rk356x-u-boot: Drop combphy1 assigned-clocks/rates
    # https://github.com/u-boot/u-boot/commit/3abfd33e5715ad31c4c358704a2506c9d52a6189
    git -C u-boot cherry-pick 3abfd33e5715ad31c4c358704a2506c9d52a6189

    # rockchip: rk3568: add rk3568 pinctrl driver
    # https://github.com/u-boot/u-boot/commit/1977d746aa54ae197a9d5f24414680d3ca321fb1
    git -C u-boot cherry-pick 1977d746aa54ae197a9d5f24414680d3ca321fb1

    # rockchip: rk3568: Select DM_REGULATOR_FIXED
    # https://github.com/u-boot/u-boot/commit/2c9919857475807f5e09707e0e79a36a2a60215e
    git -C u-boot cherry-pick 2c9919857475807f5e09707e0e79a36a2a60215e

    # gpio: gpio-rockchip: parse gpio-ranges for bank id
    # https://github.com/u-boot/u-boot/commit/904b8700f81cbc6a49c4f693744a4d2c6c393d6d
    git -C u-boot cherry-pick 904b8700f81cbc6a49c4f693744a4d2c6c393d6d

    # arm64: dts: rockchip: Sync rk356x from Linux main
    # https://github.com/u-boot/u-boot/commit/e2df30c6c64919e11ba0ba33c813d29d949aa7c1
    git -C u-boot cherry-pick e2df30c6c64919e11ba0ba33c813d29d949aa7c1

    # rockchip: rk3568: add boot device detection
    # https://github.com/u-boot/u-boot/commit/0d61f8e5f1c0035c3ee105d940b5b8d90bcec5b0
    git -C u-boot cherry-pick 0d61f8e5f1c0035c3ee105d940b5b8d90bcec5b0

    # rockchip: rk3568: enable automatic power savings
    # https://github.com/u-boot/u-boot/commit/95ef2aaedc7adeb2dcb922c6525d5b3df1b198e5
    git -C u-boot cherry-pick 95ef2aaedc7adeb2dcb922c6525d5b3df1b198e5

    # arm64: dts: rockchip: add gpio-ranges property to gpio nodes
    # https://github.com/u-boot/u-boot/commit/e92754e20cca37dcd62e195499ade25186d5f5e5
    git -C u-boot cherry-pick e92754e20cca37dcd62e195499ade25186d5f5e5

    # clk: rockchip: rk3568: Fix reset handler
    # https://github.com/u-boot/u-boot/commit/a67e219d0ca1b4b45ddb0cfb0afa2d1781262f62
    git -C u-boot cherry-pick a67e219d0ca1b4b45ddb0cfb0afa2d1781262f62
}

# check if utility program is installed
check_installed() {
    local todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
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

main $@

