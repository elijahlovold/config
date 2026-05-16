#!/usr/bin/env bash
set -euo pipefail

PACKAGES_DIR="./packages"

install_aur() {
  pkgs="$(grep -vE '^\s*#|^\s*$' "$1")"
  [ -z "$pkgs" ] && return 0

  yay -S --needed $pkgs
}

list_package_files() {
  find "$PACKAGES_DIR" -maxdepth 1 -type f -name "*.txt" | sort
}

echo "Package files found:"
mapfile -t files < <(list_package_files)

for i in "${!files[@]}"; do
  printf "  [%d] %s\n" "$i" "$(basename "${files[$i]}")"
done

echo
echo "Enter numbers to skip (space-separated):"
read -r -a skip

for i in "${!files[@]}"; do
  skip_it=0

  for s in "${skip[@]:-}"; do
    [[ "$s" == "$i" ]] && skip_it=1
  done

  base="$(basename "${files[$i]}")"

  if [[ "$skip_it" -eq 1 ]]; then
    echo "Skipping $base"
    continue
  fi

  echo "Installing $base"
  install_aur "${files[$i]}"
done

echo "Done"
