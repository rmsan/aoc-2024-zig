#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ -z ${1+x} ]; then
    hyperfine -w 5 -N $(ls -f zig-out/bin/day*)
else
    hyperfine -w 5 -N zig-out/bin/"day$1"
fi
