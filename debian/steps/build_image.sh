#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

SECTOR_SIZE=512
PART1_START=32768

make_image_file() {
    local filename="$1"
    local size="$2"
    truncate -s "$size" "$filename"
}

partition_image_file() {
    local image_file="$1"

    # partition with gpt
    cat <<-EOF | sfdisk "$image_file"
label: gpt
unit: sectors
sector-size: ${SECTOR_SIZE}
first-lba: 2048
part1: start=${PART1_START}, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=rootfs
EOF
    sync
}

get_partition_size() {
    local image_file="$1"
    sfdisk -d ${image_file} | grep -o "size= *[[:digit:]]\+" | sed -e "s/size=//"
}

format_partition_file() {
    local partition_file="$1"
    local root_dir="${2}"
    local uuid="$(cat fs.uuid)"
    mkfs.ext4 \
        -L rootfs -U "$uuid" -vO metadata_csum_seed \
        -d "$root_dir" \
        "$partition_file"
}

print_hdr "creating image file"
size="$(echo "$media" | sed -rn 's/.*mmc_([[:digit:]]+[m|g])\.img$/\1/p')"
make_image_file image.dd "$size"

print_hdr "partitioning image file"
partition_image_file image.dd

print_hdr "formatting and populating image file with root filesystem"
# The fastest process I could find was to prepare the content of
# of partition 1 first, in a dedicated partition image file, then
# prepend a file hole at offset 0 and another one at the end,
# to position the partition properly in the resulting disk image.
dd bs=4K count=8 if=image.dd of=part-table.dd   # save partition table
part1_size_sectors=$(get_partition_size image.dd)
part1_size_bytes=$(expr $part1_size_sectors \* $SECTOR_SIZE)
# recreate image.dd with just the size of part 1 for now
rm image.dd
make_image_file image.dd "$part1_size_bytes"
# populate part 1 with ext4 filesystem and rootfs content
format_partition_file image.dd rootfs
# prepend a file hole to shift the position of the partition in the image file
fallocate -i -o 0 -l $((SECTOR_SIZE*PART1_START)) image.dd
# append a file hole at the end to recover the exact target image size
truncate -s $size image.dd
# restore the partition table
dd bs=4K count=8 if=part-table.dd of=image.dd conv=notrunc
# cleanup
rm part-table.dd

print_hdr "installing u-boot"
uboot_spl=$(ls downloads/idbloader-*.img)
uboot_itb=$(ls downloads/u-boot-*.itb)
dd bs=4K seek=8 if="$uboot_spl" of=image.dd conv=notrunc
dd bs=4K seek=2048 if="$uboot_itb" of=image.dd conv=notrunc,fsync
