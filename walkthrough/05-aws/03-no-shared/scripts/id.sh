#!/usr/bin/env bash

random_string() {
	LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | fold -w 5 | head -n 1 | tr -d '[:space:]'
	echo -n
}

main() {
	local -r id_file="$1"

	if [[ -f "$id_file" ]]; then
		cat "$id_file"

		return
	fi

	random_string >"$id_file"

	cat "$id_file"
}

: "${1:?Usage: $0 <id_file>}"

main "$@"
