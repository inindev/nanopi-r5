#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

# enable ll alias
# the 1st line modifies /etc/skel, so do this before useradd below.
sed -i '/alias.ll=/s/^#*\s*//' "/etc/skel/.bashrc"
sed -i '/export.LS_OPTIONS/s/^#*\s*//' "/root/.bashrc"
sed -i '/eval.*dircolors/s/^#*\s*//' "/root/.bashrc"
sed -i '/alias.l.=/s/^#*\s*//' "/root/.bashrc"

print_hdr "creating user account"
useradd -m "$acct_uid" -s '/bin/bash'
echo $acct_uid:$acct_pass | /usr/sbin/chpasswd -c YESCRYPT
passwd -e "$acct_uid"
(umask 377 && echo "$acct_uid ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$acct_uid")

