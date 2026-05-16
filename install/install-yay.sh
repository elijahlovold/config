#!/usr/bin/sh
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

sudo pacman -S --needed git base-devel

git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
cd "$tmpdir/yay"

makepkg -si --noconfirm
