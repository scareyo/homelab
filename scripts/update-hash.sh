#!/usr/bin/env bash

# Updates the hash of every downloadHelmChart block in a given nix chart file

log () {
  echo "[update-hash] $1"
}

set -e

file=$1

mapfile -t starts < <(grep -n 'downloadHelmChart {' "$file" | cut -d: -f1)

if [ ${#starts[@]} -eq 0 ]; then
  log "no downloadHelmChart blocks found in $file"
  exit 1
fi

for start in "${starts[@]}"; do
  end=$(awk -v s="$start" 'NR > s && /};/ { print NR; exit }' "$file")

  eval "$(sed -n "${start},${end}{s/^[[:space:]]*\(repo\|chart\|version\)[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1=\2/p}" "$file")"

  log "getting hash for $chart $version from $repo"

  tmpdir=$(mktemp -d -t homelab-update-hash.XXXXXXXXXX)

  flags=()
  if [[ "$repo" == http://* || "$repo" == https://* ]]; then
    flags=("--repo" "$repo" "$chart")
  fi

  if [[ "$repo" == oci://* ]]; then
    flags=("$repo/$chart")
  fi

  helm pull "${flags[@]}" --version "$version" -d "$tmpdir" --untar

  hash=$(nix-hash --type sha256 --sri "$tmpdir/$chart")

  log "writing new hash $hash to $file (lines $start-$end)"

  sed -i "${start},${end}s|chartHash[[:space:]]*=[[:space:]]*\"[^\"]*\"|chartHash = \"$hash\"|" "$file"

  rm -rf "$tmpdir"
done
