#!/usr/bin/env bash

set -euo pipefail

package() {
	local -r src_directory="$1"
	local -r dist_directory="$2"

	pushd "$src_directory" >/dev/null
	GOOS=linux GOARCH=arm64 go build -o bootstrap
	zip "$dist_directory"/package.zip bootstrap
	popd >/dev/null
}

main() {
	local -r src_directory="$(realpath "$1")"
	local dist_directory="$2"

	mkdir -p "$dist_directory"
	dist_directory="$(realpath "$dist_directory")"

	package "$src_directory" "$dist_directory"
}

: "${1?"Usage: $0 <src_directory> <dist_directory> <architecture>"}"
: "${2?"Usage: $0 <src_directory> <dist_directory> <architecture>"}"

main "$@"
