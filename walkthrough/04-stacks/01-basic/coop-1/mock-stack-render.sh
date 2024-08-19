#!/usr/bin/env bash

set -euo pipefail

DEBUG="${DEBUG:-false}"

debug() {
  local -r msg="$1"

  if [[ "$DEBUG" == 'true' ]]; then
    >&2 echo "$msg"
  fi
}

render_unit() {
  local -r unit_source="$1"
  local -r unit_path="$2"

  mkdir -p ".terragrunt-stack/$unit_path"

  cp -R "$unit_source/" ".terragrunt-stack/$unit_path/"
}

render_stack_hcl() {
  local unit_name
  local unit_source
  local unit_path

  mkdir -p .terragrunt-stack

  while read -r line; do
    if [[ $line == "unit"* ]]; then
      unit_name="$(awk '{print $2}' <<< "$line" | tr -d '"')"
      debug "Rendering unit $unit_name"
    fi

    if [[ $line == "source"* ]]; then
      unit_source="$(awk -F '=' '{print $2}' <<< "$line" | tr -d '"' | tr -d '[:space:]')"
      debug "Unit source: $unit_source ..."
    fi

    if [[ $line == "path"* ]]; then
      unit_path="$(awk -F '=' '{print $2}' <<< "$line" | tr -d '"' | tr -d '[:space:]')"
      debug "Unit path: $unit_path ..."
    fi

    if [[ $line = *"}"* ]]; then
      render_unit "$unit_source" "$unit_path"
    fi
  done < terragrunt.stack.hcl
}

render_stack_hcl

