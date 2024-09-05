#!/usr/bin/env bash

set -euo pipefail

main() {
	local -r src_directory="$(realpath "$1")"

	local dist_directory="$2"
	mkdir -p "$dist_directory"
	dist_directory="$(realpath "$dist_directory")"

	pushd "$src_directory" >/dev/null
	zip -r "$dist_directory"/package.zip .
	popd >/dev/null
}

: "${1?"Usage: $0 <src_directory> <dist_directory>"}"
: "${2?"Usage: $0 <src_directory> <dist_directory>"}"

main "$@"
