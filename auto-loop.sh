#!/bin/bash
m=$1 p=$2 i=0
shift 2
[[ $1 == "--" ]] && shift
while read -r s; do
	echo "[$((++i))] $s"
	copilot --model "$m" --prompt "$p $s" "${@:---allow-all-tools --disallow-temp-dir}" --silent
done
