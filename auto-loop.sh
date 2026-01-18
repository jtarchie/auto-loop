#!/bin/bash
m=$1 p=$2 i=0
eval "${3:-cat}" | while read -r s; do echo "[$((++i))] $s"; copilot --model "$m" --prompt "$p $s" --allow-all-tools --disallow-temp-dir --silent; done
