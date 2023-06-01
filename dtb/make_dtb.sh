#!/bin/sh

set -e

# script exit codes:
#   1: missing utility
#   5: invalid file hash

main() {
    local linux='https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.3.5.tar.xz'
    local lxsha='f5cd478c3d8b908ab606afd1e95a4f8f77e7186b4a82829251d6e6aaafff825e'

    local lf=$(basename $linux)
    local lv=$(echo $lf | sed -nE 's/linux-(.*)\.tar\..z/\1/p')

    if [ '_clean' = "_$1" ]; then
        rm -f *.dt?
        rm -f *.dtsi
        rm -rf linux-$lv
        echo '\nclean complete\n'
        exit 0
    fi

    check_installed 'device-tree-compiler' 'gcc' 'wget' 'xz-utils'

    [ -f $lf ] || wget $linux

    if [ _$lxsha != _$(sha256sum $lf | cut -c1-64) ]; then
        echo "invalid hash for linux source file: $lf"
        exit 5
    fi

    local rkpath=linux-$lv/arch/arm64/boot/dts/rockchip
    if ! [ -d linux-$lv ]; then
        tar xavf $lf linux-$lv/include/dt-bindings linux-$lv/include/uapi $rkpath
        get_for_next $rkpath/rk356x.dtsi
        get_for_next $rkpath/rk3568-nanopi-r5s.dtsi

        get_for_next $rkpath/rk3568-nanopi-r5c.dts
        sed -i '/gpio3 RK_PA3 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-1-100:00:link";' $rkpath/rk3568-nanopi-r5c.dts
        sed -i '/gpio3 RK_PA4 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-2-100:00:link";' $rkpath/rk3568-nanopi-r5c.dts

        get_for_next $rkpath/rk3568-nanopi-r5s.dts
        sed -i '/gpio3 RK_PD6 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-0-100:00:link";' $rkpath/rk3568-nanopi-r5s.dts
        sed -i '/gpio3 RK_PD7 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "r8169-1-100:00:link";' $rkpath/rk3568-nanopi-r5s.dts
        sed -i '/gpio2 RK_PC1 GPIO_ACTIVE_HIGH/a \\t\t\tlinux,default-trigger = "stmmac-0:01:link";' $rkpath/rk3568-nanopi-r5s.dts
    fi

    if [ '_links' = "_$1" ]; then
        ln -sfv $rkpath/rk356x.dtsi
        ln -sfv $rkpath/rk3568.dtsi
        ln -sfv $rkpath/rk3568-pinctrl.dtsi
        ln -sfv $rkpath/rk3568-nanopi-r5s.dtsi
        ln -sfv $rkpath/rk3568-nanopi-r5s.dts
        ln -sfv $rkpath/rk3568-nanopi-r5c.dts
        echo '\nlinks created\n'
        exit 0
    fi

    # build
    local dt=rk3568-nanopi-r5s
    gcc -I linux-$lv/include -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o ${dt}-top.dts $rkpath/${dt}.dts
    dtc -@ -I dts -O dtb -o ${dt}.dtb ${dt}-top.dts
    echo "\n${cya}device tree ready: ${dt}.dtb${rst}\n"

    dt=rk3568-nanopi-r5c
    gcc -I linux-$lv/include -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp -o ${dt}-top.dts $rkpath/${dt}.dts
    dtc -@ -I dts -O dtb -o ${dt}.dtb ${dt}-top.dts
    echo "\n${cya}device tree ready: ${dt}.dtb${rst}\n"
}

get_for_next() {
    local filepath=$1
    local file=$(basename $filepath)
    local url=https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/plain/arch/arm64/boot/dts/rockchip/$file?h=next-20230505
    wget -O $filepath $url
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

