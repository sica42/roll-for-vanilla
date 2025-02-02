#!/usr/bin/env bash

function main() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <tag>"
    exit 1
  fi

  git tag "$1" -f
  git push origin "$1" -f

  local git_branch
  git_branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ "$git_branch" == "master" ]]; then
    echo "Pushing latest tag..." >&2
    git tag latest -f
    git push origin latest -f
  elif [[ "$git_branch" == "v4" ]]; then
    echo "Pushing beta tag..." >&2
    git tag beta -f
    git push origin beta -f
  fi

  local release_dir="$HOME/Dropbox"
  local latest_file="${release_dir}/RollFor.zip"
  local version_file="${release_dir}/RollFor-$1.zip"

  rm -f "$latest_file"
  rm -f "$version_file"

  zip -r "$latest_file" RollFor
  cp "$latest_file" "$version_file"
}

main "$@"
