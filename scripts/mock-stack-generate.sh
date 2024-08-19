#!/usr/bin/env bash

set -euo pipefail

DEBUG="${DEBUG:-false}"

debug() {
	local -r msg="$1"

	if [[ "$DEBUG" == 'true' ]]; then
		>&2 echo "$msg"
	fi
}

generate_unit() {
	local -r unit_source="$1"
	local -r unit_path="$2"

	mkdir -p ".terragrunt-stack/$unit_path"

	cp -R "./$unit_source/" ".terragrunt-stack/$unit_path/"
}

generate_child_stack() {
	local -r stack_source="$1"
	local -r stack_path="$2"

	mkdir -p ".terragrunt-stack/$stack_path"

	cp -R "./$stack_source/" ".terragrunt-stack/$stack_path/"

	pushd ".terragrunt-stack/$stack_path" >/dev/null
	generate_stack_hcl
	popd >/dev/null
}

generate_stack_hcl() {
	local unit_name=''
	local unit_source
	local unit_path

	local stack_name=''
	local stack_source
	local stack_path

	mkdir -p .terragrunt-stack

	while read -r line; do
		if [[ $line == "unit"* ]]; then
			unit_name="$(awk '{print $2}' <<<"$line" | tr -d '"')"
			debug "Rendering unit $unit_name"
		fi

		if [[ $line == "source"* ]] && [[ "$unit_name" != "" ]]; then
			unit_source="$(awk -F '=' '{print $2}' <<<"$line" | tr -d '"' | tr -d '[:space:]')"
			debug "Unit source: $unit_source ..."
		fi

		if [[ $line == "path"* ]] && [[ "$unit_name" != "" ]]; then
			unit_path="$(awk -F '=' '{print $2}' <<<"$line" | tr -d '"' | tr -d '[:space:]')"
			debug "Unit path: $unit_path ..."
		fi

		if [[ $line = *"}"* ]] && [[ "$unit_name" != "" ]]; then
			generate_unit "$unit_source" "$unit_path"
			unit_name=""
		fi

		if [[ $line == "stack"* ]]; then
			stack_name="$(awk '{print $2}' <<<"$line" | tr -d '"')"
			debug "Rendering stack $stack_name"
		fi

		if [[ $line == "source"* ]] && [[ "$stack_name" != "" ]]; then
			stack_source="$(awk -F '=' '{print $2}' <<<"$line" | tr -d '"' | tr -d '[:space:]')"
			debug "Stack source: $stack_source ..."
		fi

		if [[ $line == "path"* ]] && [[ "$stack_name" != "" ]]; then
			stack_path="$(awk -F '=' '{print $2}' <<<"$line" | tr -d '"' | tr -d '[:space:]')"
			debug "Stack path: $stack_path ..."
		fi

		if [[ $line = *"}"* ]] && [[ "$stack_name" != "" ]]; then
			generate_child_stack "$stack_source" "$stack_path"
			stack_name=""
		fi
	done <terragrunt.stack.hcl
}

generate_stack() {
	local -r stack="$1"

	pushd "$(dirname "$stack")" >/dev/null
	generate_stack_hcl
	popd >/dev/null
}

find_stacks() {
	find . -type f -name terragrunt.stack.hcl
}

main() {
	local stack

	for stack in $(find_stacks); do
		debug "Rendering stack $stack"
		generate_stack "$stack"
	done
}

main
