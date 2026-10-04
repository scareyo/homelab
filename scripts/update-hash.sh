#!/usr/bin/env bash

# Updates the chartHash of every chart spec block in a given nix chart file

log () {
  echo "[update-hash] $1"
}

set -e

file=$1

mapfile -t hashes < <(grep -n 'chartHash[[:space:]]*=' "$file" | cut -d: -f1)

if [ ${#hashes[@]} -eq 0 ]; then
  log "no chart spec blocks found in $file"
  exit 1
fi

for line in "${hashes[@]}"; do
  start=$(awk -v l="$line" 'NR < l && /\{[[:space:]]*$/ { s = NR } NR == l { print s; exit }' "$file")
  end=$(awk -v l="$line" 'NR > l && /};/ { print NR; exit }' "$file")

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
