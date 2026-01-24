#!/bin/bash
m=$1 p=$2 v=$3 i=0
shift 2
[[ -n "$v" ]] && shift
[[ $1 == "--" ]] && shift
[[ $# -eq 0 ]] && set -- --allow-all-tools --disallow-temp-dir
while read -r s; do
	[[ -z "$s" ]] && continue
	echo "[$((++i))] $s" >&2
	while :; do
		pr="$p $s"
		[[ -n "$v" ]] && pr="$pr. Validate completion with: $v"
		if copilot --model "$m" --prompt "$pr" "$@" --silent; then
			if [[ -z "$v" ]] || eval "$v"; then
				break
			fi
		fi
		[[ -z "$v" ]] && exit 1
	done
done
