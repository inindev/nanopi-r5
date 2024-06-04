#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

# script exit codes:
#   1: missing utility
#   2: download failure
#   3: image mount failure
#   4: missing file
#   5: invalid file hash
#   9: superuser required
#   10: board model not supported
#   11: invalid script usage

# check the model specified
check_specified_model() {
    if [ "$1" != "r5c" -a "$1" != "r5s" ]
    then
        echo "first argument must be r5c or r5s"
        exit 10
    fi
}

# check if debian package is installed
check_installed() {
    local item todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
}

check_docker() {
    if ! docker info >/dev/null 2>/dev/null
    then
        echo "This script requires a working docker setup. This usually means:"
        echo "   ${bld}${grn} sudo apt update ${rst}\n"
        echo "   ${bld}${grn} sudo apt -y install docker.io ${rst}\n"
        echo "   ${bld}${grn} sudo usermod -a -G docker $USER\n"
        echo "For the usermod change to be effective, one must disconnect from all shell sessions and then reconnect."
        exit 1
    fi
}

get_docker_image_id() {
    docker_image_name="$1"
    docker image ls -q "$docker_image_name" || true
}

# Fetch the image generated in the docker image.
fetch_image_file() {
    docker_image_name="$1"
    madia_path="$2"
    cid=$(docker create "$docker_image_name")
    docker cp $cid:/root/image.dd - > "$media_path"
    docker rm $cid
}

model="$1"; shift
check_specified_model "${model}"
check_docker
[ "$(uname -m)" = "aarch64" ] || check_installed "qemu-user-static"

docker_image_name="nanopi-${model}-build"
media_path="nanopi-${model}/$media"
# save the ID of the current "nanopi-r5[cs]-build" docker image
# because if this new build succeeds, it will overwrite the image tag
# and we want to avoid "dangling" images.
prev_id=$(get_docker_image_id "$docker_image_name")

if is_param 'clean' "$@"; then
    if [ ! -z "$prev_id" ]; then
        docker rmi "$docker_image_name"
    fi
    rm -f "$media_path"
    echo "\n${cya}clean complete${rst}"
    echo "\n${cya}if you want to cleanup docker disk cache, use:${rst}"
    echo "  ${cya}docker system prune${rst}"
    exit 0
fi

# no compression if disabled or block media
compress=$(is_param 'nocomp' "$@" || [ -b "$media_path" ] && echo false || echo true)

if ! $compress && [ -f "$media_path" ]; then
    read -p "file $media exists, overwrite? <y/N> " yn
    if ! [ "$yn" = 'y' -o "$yn" = 'Y' -o "$yn" = 'yes' -o "$yn" = 'Yes' ]; then
        echo 'exiting...'
        exit 0
    fi
fi

if $compress && [ -f "$media_path.xz" ]; then
    read -p "file $media.xz exists, overwrite? <y/N> " yn
    if ! [ "$yn" = 'y' -o "$yn" = 'Y' -o "$yn" = 'yes' -o "$yn" = 'Yes' ]; then
        echo 'exiting...'
        exit 0
    fi
fi

print_hdr "starting docker build"

docker build --progress=plain \
             -t "$docker_image_name" \
             --build-arg MODEL="$model" \
             --build-arg PARAMS="$@" \
             --build-arg KERNEL_FW_URL="$kernel_fw_url" \
             --build-arg KERNEL_FW_SHA256="$kernel_fw_sha256" \
             --build-arg RELEASE_URL="$release_url" \
             -f Dockerfile .

new_id=$(get_docker_image_id "$docker_image_name")
if [ ! -z "$prev_id" -a "$new_id" != "$prev_id" ]
then
    # remove the docker image of the previous build,
    # since it is now a dangling image
    docker rmi "$prev_id"
fi

if $compress; then
    print_hdr "compressing image file"
    docker run --rm "$docker_image_name" \
        xz -z8v /root/image.dd --keep --stdout > "$media_path.xz"
    echo "\n${cya}compressed image is now ready${rst}"
    echo "\n${cya}copy image to target media:${rst}"
    echo "  ${cya}sudo sh -c 'xzcat $media.xz > /dev/sdX && sync'${rst}"
elif [ -b "$media_path" ]; then
    print_hdr "copying image file to $media"
    fetch_image_file "$docker_image_name" "$media_path"
    echo "\n${cya}media is now ready${rst}"
else
    print_hdr "retrieving image file from docker build env"
    fetch_image_file "$docker_image_name" "$media_path"
    echo "\n${cya}image is now ready${rst}"
    echo "\n${cya}copy image to media:${rst}"
    echo "  ${cya}sudo sh -c 'cat $media > /dev/sdX && sync'${rst}"
fi
