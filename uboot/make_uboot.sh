#!/bin/sh

set -e

# script exit codes:
#   5: invalid file hash

main() {
    local utag='v2023.04'
    local atf_file='../rkbin/rk3568_bl31_v1.28.elf'
    local tpl_file='../rkbin/rk3568_ddr_1560MHz_v1.15.bin'

    if [ '_clean' = "_$1" ]; then
        rm -f u-boot/simple-bin.fit.*
        make -C u-boot distclean
        git -C u-boot clean -f
        git -C u-boot checkout master
        git -C u-boot branch -D $utag 2>/dev/null || true
        git -C u-boot pull --ff-only
        rm -f *.img *.itb
        exit 0
    fi

    check_installed 'bc' 'bison' 'flex' 'libssl-dev' 'make' 'python3-dev' 'python3-pyelftools' 'python3-setuptools' 'swig'

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
        make -C u-boot nanopi-r5-rk3568_defconfig
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
    # rockchip: sdhci: rk3568: fix clock setting logic
    # https://github.com/u-boot/u-boot/commit/7786710adb76720be8e693c4efcea039af7ae086
    git -C u-boot cherry-pick 7786710adb76720be8e693c4efcea039af7ae086

    # rockchip: gpio: rk_gpio: use ROCKCHIP_GPIOS_PER_BANK as divider
    # https://github.com/u-boot/u-boot/commit/3c4549771dd0352e893a0bc9d2344cd8ecd8033d
    git -C u-boot cherry-pick 3c4549771dd0352e893a0bc9d2344cd8ecd8033d

    # gpio: rockchip: Add support for RK3568 and RK3588 banks
    # https://github.com/u-boot/u-boot/commit/88b962f3934a29c825cde579844642d8a57fd212
    git -C u-boot cherry-pick 88b962f3934a29c825cde579844642d8a57fd212

    # pinctrl: rockchip: Fix IO mux selection on RK3568
    # https://github.com/u-boot/u-boot/commit/518fa3441e1f04806e6151baae4dd4c694a46948
    git -C u-boot cherry-pick 518fa3441e1f04806e6151baae4dd4c694a46948

    # clk: rockchip: rk3568: Add dummy I2S1_MCLKOUT_TX clock support
    # https://github.com/u-boot/u-boot/commit/45717d6efd7ad3acc4a49490746221bae00d7c15
    git -C u-boot cherry-pick 45717d6efd7ad3acc4a49490746221bae00d7c15

    # mmc: sdhci: Fix HISPD bit handling for MMC HS 52MHz mode
    # https://github.com/u-boot/u-boot/commit/7774b7929961ec5b69cec95a0acc51d10e7564ed
    git -C u-boot cherry-pick 7774b7929961ec5b69cec95a0acc51d10e7564ed

    # mmc: sdhci: Set UHS Mode Select field for UHS SDR25 mode
    # https://github.com/u-boot/u-boot/commit/c1425ed8f873a1739874639bc120aab89a443539
    git -C u-boot cherry-pick c1425ed8f873a1739874639bc120aab89a443539

    # mmc: rockchip_sdhci: Fix use of device private data
    # https://github.com/u-boot/u-boot/commit/b8c394b7268d5a8f927b30296ffe9cb4d71b06fc
    git -C u-boot cherry-pick b8c394b7268d5a8f927b30296ffe9cb4d71b06fc

    # mmc: rockchip_sdhci: Remove unneeded emmc_phy_init
    # https://github.com/u-boot/u-boot/commit/0030d4971561c20edf66a76952ba32e5adf77ff5
    git -C u-boot cherry-pick 0030d4971561c20edf66a76952ba32e5adf77ff5

    # mmc: rockchip_sdhci: Add set_clock and config_dll sdhci_ops
    # https://github.com/u-boot/u-boot/commit/7e74522d5fbf2409974300d5de3e67e9c536a181
    git -C u-boot cherry-pick 7e74522d5fbf2409974300d5de3e67e9c536a181

    # mmc: rockchip_sdhci: Use set_clock and config_dll sdhci_ops
    # https://github.com/u-boot/u-boot/commit/b8a63c869cafc1509193b6b7544c03fcdd0265ca
    git -C u-boot cherry-pick b8a63c869cafc1509193b6b7544c03fcdd0265ca

    # mmc: rockchip_sdhci: Refactor execute tuning error handling
    # https://github.com/u-boot/u-boot/commit/ba9f5e541d78b7200fc7fa56e4e056c3b92ea451
    git -C u-boot cherry-pick ba9f5e541d78b7200fc7fa56e4e056c3b92ea451

    # mmc: rockchip_sdhci: Update speed mode controls in set_ios_post
    # https://github.com/u-boot/u-boot/commit/6de4438576ed5c8e099b52f5ee6ad549dca6aa9d
    git -C u-boot cherry-pick 6de4438576ed5c8e099b52f5ee6ad549dca6aa9d

    # mmc: rockchip_sdhci: Remove empty get_phy and set_enhanced_strobe ops
    # https://github.com/u-boot/u-boot/commit/667576c59d492116b0c4ffc0194b3b86b84c85e3
    git -C u-boot cherry-pick 667576c59d492116b0c4ffc0194b3b86b84c85e3

    # mmc: rockchip_sdhci: Rearrange and simplify used regs and flags
    # https://github.com/u-boot/u-boot/commit/8874c417ab87e559c018461effca1191e1c45fe5
    git -C u-boot cherry-pick 8874c417ab87e559c018461effca1191e1c45fe5

    # mmc: rockchip_sdhci: Fix HS400 and HS400ES mode on RK3568
    # https://github.com/u-boot/u-boot/commit/d2cece03003ea811a42d471a4733276391f4e1bf
    git -C u-boot cherry-pick d2cece03003ea811a42d471a4733276391f4e1bf

    # mmc: sdhci: Allow disabling of SDMA in SPL
    # https://github.com/u-boot/u-boot/commit/3cd664dc92ca832506f1a4e7769cb5ee6a88137d
    git -C u-boot cherry-pick 3cd664dc92ca832506f1a4e7769cb5ee6a88137d

    # mmc: rockchip_sdhci: Limit number of blocks read in a single command
    # https://github.com/u-boot/u-boot/commit/2cc6cde647e2cf61a29f389e8d263bf19672f0f5
    git -C u-boot cherry-pick 2cc6cde647e2cf61a29f389e8d263bf19672f0f5
}

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

