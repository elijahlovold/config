#!/usr/bin/sh
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

git clone https://github.com/mmhobi7/xwinwrap.git "$tmpdir/xwinwrap"
cd "$tmpdir/xwinwrap"

make
sudo make install
