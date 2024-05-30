#!/bin/sh

# For return codes, see common/make_debian_img_for_model.sh
cd "$(dirname "$(realpath "$0")")"
exec sh ../common/make_debian_img_for_model.sh r5c "$@"
