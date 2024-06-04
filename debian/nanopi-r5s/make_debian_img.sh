#!/bin/sh

# For configuration, see ../env.sh
# For return codes, see ../main.sh
cd "$(dirname "$(realpath "$0")")/.."
exec sh ./main.sh r5s "$@"
