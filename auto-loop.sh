#!/bin/bash
m=$1 p=$2; shift 2; [[ $1 == "--" ]] && shift
i=0; while read -r s; do echo "[$((++i))] $s"; copilot --model "$m" --prompt "$p $s" "${@:---allow-all-tools --disallow-temp-dir}" --silent; done
