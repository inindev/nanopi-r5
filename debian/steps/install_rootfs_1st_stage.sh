#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

print_hdr "installing root filesystem from debian.org"

pkgs="linux-image-arm64, dbus, dhcpcd, libpam-systemd, openssh-server, systemd-timesyncd"
pkgs="$pkgs, rfkill, wireless-regdb, wpasupplicant"
pkgs="$pkgs, $extra_pkgs"
debootstrap --foreign --arch arm64 --include "$pkgs" --exclude "isc-dhcp-client" \
    "$deb_dist" "rootfs" 'https://deb.debian.org/debian/'
