#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

print_hdr "finalizing root filesystem"

file_apt_sources() {
    local deb_dist="$1"

    cat <<-EOF
	# For information about how to configure apt package sources,
	# see the sources.list(5) manual.

	deb http://deb.debian.org/debian ${deb_dist} main contrib non-free non-free-firmware
	#deb-src http://deb.debian.org/debian ${deb_dist} main contrib non-free non-free-firmware

	deb http://deb.debian.org/debian-security ${deb_dist}-security main contrib non-free non-free-firmware
	#deb-src http://deb.debian.org/debian-security ${deb_dist}-security main contrib non-free non-free-firmware

	deb http://deb.debian.org/debian ${deb_dist}-updates main contrib non-free non-free-firmware
	#deb-src http://deb.debian.org/debian ${deb_dist}-updates main contrib non-free non-free-firmware
	EOF
}

file_wpa_supplicant_conf() {
    cat <<-EOF
	ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
	update_config=1
	EOF
}

file_locale_cfg() {
    cat <<-EOF
	LANG="C.UTF-8"
	LANGUAGE=
	LC_CTYPE="C.UTF-8"
	LC_NUMERIC="C.UTF-8"
	LC_TIME="C.UTF-8"
	LC_COLLATE="C.UTF-8"
	LC_MONETARY="C.UTF-8"
	LC_MESSAGES="C.UTF-8"
	LC_PAPER="C.UTF-8"
	LC_NAME="C.UTF-8"
	LC_ADDRESS="C.UTF-8"
	LC_TELEPHONE="C.UTF-8"
	LC_MEASUREMENT="C.UTF-8"
	LC_IDENTIFICATION="C.UTF-8"
	LC_ALL=
	EOF
}

model="$1"; shift

# apt sources & default locale
echo "$(file_apt_sources $deb_dist)\n" > "rootfs/etc/apt/sources.list"
echo "$(file_locale_cfg)\n" > "rootfs/etc/default/locale"

# wpa supplicant
rm -rfv "rootfs/etc/systemd/system/multi-user.target.wants/wpa_supplicant.service"
echo "$(file_wpa_supplicant_conf)\n" > "rootfs/etc/wpa_supplicant/wpa_supplicant.conf"
cp -v "rootfs/usr/share/dhcpcd/hooks/10-wpa_supplicant" "rootfs/usr/lib/dhcpcd/dhcpcd-hooks"

# motd -- off by default, use the following in debian/env.sh to define it:
#
# motd="$(cat << EOF
# Here is my motd.
# EOF
# )"
[ ! -z "$motd" ] && echo "$motd" > "rootfs/etc/motd"

# hostname
hostname=$(echo "$hostname_pattern" | sed -e "s/MODEL/${model}/")
echo $hostname > "rootfs/etc/hostname"

# note: /etc/hosts is bind-mounted read-only by docker,
# so debootstrap --second-stage could not populate it properly.
cat > "rootfs/etc/hosts" <<-EOF
127.0.0.1	localhost
127.0.1.1   $hostname
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
EOF

print_hdr "installing rootfs expansion script to /etc/rc.local"
install -Dvm 754 "files/rc.local" "rootfs/etc/rc.local"

# disable sshd until after keys are regenerated on first boot
rm -fv "rootfs/etc/systemd/system/sshd.service"
rm -fv "rootfs/etc/systemd/system/multi-user.target.wants/ssh.service"
rm -fv "rootfs/etc/ssh/ssh_host_"*

# generate machine id on first boot
rm -fv "rootfs/etc/machine-id"
