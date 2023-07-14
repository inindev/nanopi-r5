#!/bin/sh

set -e

# script exit codes:
#   1: missing utility
#   5: invalid file hash

main() {
    local linux='https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.4.3.tar.xz'
    local lxsha='7134ed29360df6f37a26410630283f0592c91a6d2178a9648226d30ddf8c88a1'

    local lf="$(basename "$linux")"
    local lv="$(echo "$lf" | sed -nE 's/linux-(.*)\.tar\..z/\1/p')"

    if [ '_clean' = "_$1" ]; then
        rm -f *.dt*
        rm -rf "linux-$lv"
        echo '\nclean complete\n'
        exit 0
    fi

    check_installed 'device-tree-compiler' 'gcc' 'wget' 'xz-utils'

    [ -f "$lf" ] || wget "$linux"

    if [ "_$lxsha" != _$(sha256sum "$lf" | cut -c1-64) ]; then
        echo "invalid hash for linux source file: $lf"
        exit 5
    fi

    local rkpath="linux-$lv/arch/arm64/boot/dts/rockchip"
    if ! [ -d "linux-$lv" ]; then
        tar xavf "$lf" "linux-$lv/include/dt-bindings" "linux-$lv/include/uapi" "$rkpath"

        # lan activity indicators
        sed -i '/gpio3 RK_PA3 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-1-100:00:link";' "$rkpath/rk3568-nanopi-r5c.dts"
        sed -i '/gpio3 RK_PA4 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-2-100:00:link";' "$rkpath/rk3568-nanopi-r5c.dts"

        sed -i '/gpio3 RK_PD6 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-0-100:00:link";' "$rkpath/rk3568-nanopi-r5s.dts"
        sed -i '/gpio3 RK_PD7 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-1-100:00:link";' "$rkpath/rk3568-nanopi-r5s.dts"
        sed -i '/gpio2 RK_PC1 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "stmmac-0:01:link";' "$rkpath/rk3568-nanopi-r5s.dts"
    fi

    local rkfl='rk356x.dtsi rk3568.dtsi rk3568-pinctrl.dtsi rk3568-nanopi-r5s.dtsi rk3568-nanopi-r5s.dts rk3568-nanopi-r5c.dts rockchip-pinconf.dtsi'
    if [ '_links' = "_$1" ]; then
        for rkf in $rkfl; do
            ln -sfv "$rkpath/$rkf"
        done
        echo '\nlinks created\n'
        exit 0
    fi

    # build
    local dts='rk3568-nanopi-r5s rk3568-nanopi-r5c'
    local fldtc='-Wno-interrupt_provider -Wno-unique_unit_address -Wno-unit_address_vs_reg -Wno-avoid_unnecessary_addr_size -Wno-alias_paths -Wno-graph_child_address -Wno-simple_bus_reg'
    for dt in $dts; do
        gcc -I "linux-$lv/include" -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o "${dt}-top.dts" "$rkpath/${dt}.dts"
        dtc -I dts -O dtb -b 0 ${fldtc} -o "${dt}.dtb" "${dt}-top.dts"
        echo "\n${cya}device tree ready: ${dt}.dtb${rst}\n"
    done
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

main "$@"

