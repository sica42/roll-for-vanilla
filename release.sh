#!/usr/bin/env bash

function main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <tag>"
    exit 1
  fi

  git tag "$1" -f
  git push origin "$1" -f
  git tag latest -f
  git push origin latest -f

  local release_dir="$HOME/Dropbox"
  local latest_file="${release_dir}/RollFor.zip"
  local version_file="${release_dir}/RollFor-$1.zip"

  rm -f "$latest_file"
  rm -f "$version_file"

  zip -r "$latest_file" RollFor
  cp "$latest_file" "$version_file"
}

main "$@"

