#!/bin/bash
m=$1 p=$2 i=0
shift 2
[[ $1 == "--" ]] && shift
[[ $# -eq 0 ]] && set -- --allow-all-tools --disallow-temp-dir
while read -r s; do
	[[ -z "$s" ]] && continue
	echo "[$((++i))] $s" >&2
	copilot --model "$m" --prompt "$p $s" "$@" --silent || exit 1
done
