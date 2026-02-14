#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIRS=()
trap 'rm -rf "${DIRS[@]}"' EXIT

setup() {
	local d
	d=$(mktemp -d)
	DIRS+=("$d")
	cp -r "$SCRIPT_DIR/examples" "$d/"
	cp "$SCRIPT_DIR/auto-loop.rb" "$d/"
	cd "$d"
	git init -q
	git config user.email "test@example.com"
	git config user.name "Test User"
	git add -A && git commit -q -m "Initial commit"
	cd examples && npm install --silent && cd ..
}

echo "==> Test 1: sequential features"
setup
cat examples/features.txt | ./auto-loop.rb \
	--model gpt-5-mini \
	--prompt "In the Express app at examples/, implement:"
git diff --stat && git log --oneline

echo "==> Test 2: grouped features with after-group"
setup
cat examples/grouped-features.txt | ./auto-loop.rb \
	--model gpt-5-mini \
	--prompt "In the Express app at examples/, implement:" \
	--group-pattern '^\*\*.*:\*\*' \
	--after-group "cd examples && node -e 'require(\"./index\")' && cd .."
git diff --stat && git log --oneline

echo "==> Tests passed!"
