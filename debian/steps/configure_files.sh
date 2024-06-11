#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>
set -e
. ./env.sh
. ./tools.sh

print_hdr "configuring files"

file_fstab() {
    local uuid="$1"

    cat <<-EOF
	# if editing the device name for the root entry, it is necessary
	# to regenerate the extlinux.conf file by running /boot/mk_extlinux

	# <device>					<mount>	<type>	<options>		<dump> <pass>
	UUID=$uuid	/	ext4	errors=remount-ro	0      1
	EOF
}

model="$1"
mkdir -p "rootfs/etc"
echo 'link_in_boot = 1' > "rootfs/etc/kernel-img.conf"
echo 'do_symlinks = 0' >> "rootfs/etc/kernel-img.conf"

# setup fstab
cat /proc/sys/kernel/random/uuid > fs.uuid
uuid="$(cat fs.uuid)"
echo "$(file_fstab $uuid)\n" > "rootfs/etc/fstab"

# setup extlinux boot
for dst in "/etc/kernel/postinst.d/dtb_cp" \
           "/etc/kernel/postrm.d/dtb_rm" \
           "/boot/mk_extlinux"
do
    src=$(basename "${dst}")
    install -Dvm 754 "files/${src}" "rootfs${dst}"
    sed -i -e "s/MODEL/${model}/g" "rootfs${dst}"
done
ln -svf '../../../boot/mk_extlinux' "rootfs/etc/kernel/postinst.d/update_extlinux"
ln -svf '../../../boot/mk_extlinux' "rootfs/etc/kernel/postrm.d/update_extlinux"
