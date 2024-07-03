#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>
# Copyright (C) 2024, Etienne Dublé <etienne.duble@imag.fr>

set -e
. ./env.sh
. ./tools.sh

print_hdr "downloading: $(basename "$1")"

download() {
    local url="$1"

    mkdir -p "downloads"

    local filename="$(basename "$url")"
    local filepath="downloads/$filename"
    wget -nv "$url" -P "downloads"
    [ -f "$filepath" ] || exit 2

    echo "$filepath"
}

check_hash() {
    local filepath="$1"
    local sha="$2"
    [ "$sha" = $(sha256sum "$filepath" | cut -c1-64) ] || { echo "invalid hash for $filepath"; exit 5; }
}

# download
filepath=$(download "$1")

# check hash if specified
if [ ! -z "$2" ]
then
    check_hash "$filepath" "$2"
fi
