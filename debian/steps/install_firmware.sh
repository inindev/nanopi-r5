#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

print_hdr "installing firmware"

mkdir -p "rootfs/usr/lib/firmware"
lfw=$(ls downloads/linux-firmware*.tar.xz)
lfwn=$(basename "$lfw")
lfwbn="${lfwn%%.*}"
tar -C "rootfs/usr/lib/firmware" --strip-components=1 --wildcards -xavf "$lfw" \
    "$lfwbn/rockchip" \
    "$lfwbn/rtl_bt" \
    "$lfwbn/rtl_nic" \
    "$lfwbn/rtlwifi" \
    "$lfwbn/rtw88" \
    "$lfwbn/rtw89"

# install device tree
install -vm 644 downloads/*.dtb "rootfs/boot"
