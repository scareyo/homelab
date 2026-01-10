#!/bin/sh

# Updates the hash of a given nix chart file

log () {
  echo "[update-hash] $1"
}

set -e

file=$1

repo=$(sed -n 's/.*repo\s*=\s*"\([^"]*\)".*/\1/p' $file)
chart=$(sed -n 's/.*chart\s*=\s*"\([^"]*\)".*/\1/p' $file)
version=$(sed -n 's/.*version\s*=\s*"\([^"]*\)".*/\1/p' $file)

log "getting hash for $chart $version from $repo"

tmpdir=$(mktemp -d -t homelab-update-hash.XXXXXXXXXX)

if [[ "$repo" == http://* || "$repo" == https://* ]]; then
  flags="--repo $repo $chart"
fi

if [[ "$repo" == oci://* ]]; then
  flags="$repo/$chart"
fi

helm pull $flags --version $version -d $tmpdir --untar

hash=$(nix-hash --type sha256 --sri $tmpdir/$chart)

log "writing new hash $hash to $file"

sed -i "s|chartHash\s*=\s*\"[^\"]*\"|chartHash = \"$hash\"|" "$file"
