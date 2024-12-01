#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ -z ${1+x} ]; then
    for day in $(ls -d day*); do zig build "$day" -Doptimize=ReleaseFast; done
else
    zig build "day$1" -Doptimize=ReleaseFast
fi
