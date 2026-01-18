#!/bin/bash
m=$1 p=$2 n=1
shift 2
while [[ $1 == --parallel ]]; do
	n=$2
	shift 2
done
[[ $1 == "--" ]] && shift
[[ $# -eq 0 ]] && set -- --allow-all-tools --disallow-temp-dir
d="$PWD/.worktrees"
b=$(git rev-parse --abbrev-ref HEAD)
mkdir -p "$d/.locks"
trap 'rm -rf "$d/.locks"/$$.* 2>/dev/null' EXIT INT TERM
acquire() { while :; do
	for i in $(seq 1 $n); do mkdir "$d/.locks/w$i.lock" 2>/dev/null && {
		echo $i
		return
	}; done
	sleep 0.1
done; }
release() { rm -rf "$d/.locks/w$1.lock" 2>/dev/null; }
setup() {
	local w="$d/worker-$1"
	[[ -d "$w" ]] || git worktree add -d "$w" HEAD >/dev/null 2>&1
	echo "$w"
}
process() {
	[[ -z "$1" ]] && return
	local i w
	i=$(acquire)
	w=$(setup "$i")
	echo "[Worker-$i] $1" >&2
	(cd "$w" && copilot --model "$m" --prompt "You are working in an isolated git worktree. When done, commit changes with 'git add -A && git commit -m <message>'. $p $1" "${@:2}" --silent) || :
	release "$i"
}
export -f process acquire release setup
export m p n d b
xargs -I {} -P "$n" bash -c "process '{}' $*"
