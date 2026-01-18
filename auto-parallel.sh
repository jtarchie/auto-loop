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
trap 'rm -rf "$d/.locks" 2>/dev/null' EXIT INT TERM
process() {
	local line="$1"
	local wid="${line%%|*}"
	local task="${line#*|}"
	[[ -z "$task" ]] && return
	local w="$d/worker-$wid"
	[[ -d "$w" ]] || git worktree add -d "$w" HEAD >/dev/null 2>&1
	echo "[Worker-$wid] $task" >&2
	(cd "$w" && copilot --model "$m" --prompt "You are working in an isolated git worktree. When done, commit changes with 'git add -A && git commit -m <message>'. $p $task" "${@:2}" --silent) || :
}
export -f process
export m p d
nl -w1 -s'|' | xargs -I {} -P "$n" bash -c 'process "{}" '"$*"
