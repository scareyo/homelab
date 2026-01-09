#!/bin/sh

# Updates the hash of a given nix chart file

set -e

file=$1

repo=$(sed -n 's/.*repo\s*=\s*"\([^"]*\)".*/\1/p' $file)
chart=$(sed -n 's/.*chart\s*=\s*"\([^"]*\)".*/\1/p' $file)
version=$(sed -n 's/.*version\s*=\s*"\([^"]*\)".*/\1/p' $file)

echo "[update-hash] getting hash for $chart $version from $repo"

url=$(curl -Ls "$repo/index.yaml" | yq ".entries[\"$chart\"][] | select(.version == \"$version\").urls[0]")
if [[ "$url" != http://* && "$url" != https://* ]]; then
  url="$repo/$url"
fi

hash=$(nix hash convert --hash-algo sha256 "$(nix-prefetch-url --unpack "$url")")

echo "[update-hash] writing new hash $hash to $file"

sed -i "s|chartHash\s*=\s*\"[^\"]*\"|chartHash = \"$hash\"|" "$file"
