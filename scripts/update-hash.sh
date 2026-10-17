#!/usr/bin/env bash

# Updates the chartHash of every chart spec block and the hash of every
# fetchFromGitHub block in a given nix file

log () {
  echo "[update-hash] $1"
}

# Prints the string value of an attribute within the current block
field () {
  sed -n "${start},${end}s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file"
}

# Prints the line number of the first block end after the given line
block_end () {
  awk -v l="$1" 'NR > l && /};/ { print NR; exit }' "$file"
}

# Replaces the string value of an attribute within the current block with $hash
write_hash () {
  log "writing new hash $hash to $file (lines $start-$end)"
  sed -i "${start},${end}s|^\([[:space:]]*$1[[:space:]]*=[[:space:]]*\)\"[^\"]*\"|\1\"$hash\"|" "$file"
}

# Expands ${charts.<name>.<attr>} references using the chart spec blocks in the file
resolve () {
  local value=$1 match name attr start end resolved
  while [[ "$value" =~ \$\{charts\.([A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+)\} ]]; do
    match=${BASH_REMATCH[0]}
    name=${BASH_REMATCH[1]}
    attr=${BASH_REMATCH[2]}

    start=$(awk -v n="$name" '$0 ~ "charts\\." n "[[:space:]]*=[[:space:]]*\\{" { print NR; exit }' "$file")
    if [ -z "$start" ]; then
      log "cannot resolve $match: no charts.$name block in $file"
      exit 1
    fi
    end=$(block_end "$start")

    resolved=$(field "$attr")
    if [ -z "$resolved" ]; then
      log "cannot resolve $match: charts.$name has no $attr"
      exit 1
    fi

    value=${value//"$match"/$resolved}
  done
  echo "$value"
}

set -e

file=$1

mapfile -t hashes < <(grep -n 'chartHash[[:space:]]*=' "$file" | cut -d: -f1)
mapfile -t fetches < <(grep -n 'fetchFromGitHub[[:space:]]*{' "$file" | cut -d: -f1)

if [ ${#hashes[@]} -eq 0 ] && [ ${#fetches[@]} -eq 0 ]; then
  log "no chart spec or fetchFromGitHub blocks found in $file"
  exit 1
fi

for line in "${hashes[@]}"; do
  start=$(awk -v l="$line" 'NR < l && /\{[[:space:]]*$/ { s = NR } NR == l { print s; exit }' "$file")
  end=$(block_end "$line")

  repo=$(field repo)
  chart=$(field chart)
  version=$(field version)

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

  write_hash chartHash

  rm -rf "$tmpdir"
done

for start in "${fetches[@]}"; do
  end=$(block_end "$start")

  owner=$(resolve "$(field owner)")
  repo=$(resolve "$(field repo)")
  rev=$(resolve "$(field rev)")
  tag=$(resolve "$(field tag)")

  ref=${rev:-refs/tags/$tag}

  log "getting hash for github:$owner/$repo at $ref"

  # fetchFromGitHub hashes the unpacked archive, which is what --unpack produces
  base32=$(nix-prefetch-url --unpack "https://github.com/$owner/$repo/archive/$ref.tar.gz")
  hash=$(nix-hash --type sha256 --to-sri "$base32")

  write_hash hash
done
