#!/bin/sh

# file media is sized with the number between 'mmc_' and '.img'
#   use 'm' for 1024^2 and 'g' for 1024^3
media='mmc_2g.img' # or block device '/dev/sdX'
deb_dist='bookworm'
acct_uid='debian'
acct_pass='debian'
extra_pkgs='curl, pciutils, sudo, unzip, wget, xxd, xz-utils, zip, zstd'
hostname_pattern='nanopi-MODEL-arm64'
kernel_fw_url="https://mirrors.edge.kernel.org/pub/linux/kernel/firmware/linux-firmware-20230210.tar.xz"
kernel_fw_sha256="6e3d9e8d52cffc4ec0dbe8533a8445328e0524a20f159a5b61c2706f983ce38a"
release_url="https://github.com/inindev/nanopi-r5/releases/download/v12.0.1"

rst='\033[m'
bld='\033[1m'
red='\033[31m'
grn='\033[32m'
yel='\033[33m'
blu='\033[34m'
mag='\033[35m'
cya='\033[36m'
