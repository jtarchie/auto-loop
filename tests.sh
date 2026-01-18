#!/bin/bash
set -e

# Save script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "==> Setting up test environment in $TEMP_DIR"
cp -r "$SCRIPT_DIR/examples" "$TEMP_DIR/"
cd "$TEMP_DIR"

# Initialize git repo
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
git add -A
git commit -q -m "Initial commit"

echo ""
echo "==> Installing dependencies"
cd examples
npm install --silent
cd ..

echo ""
echo "==> Adding features in parallel (2 workers)"
timeout 180 bash -c "cat examples/features.txt | '$SCRIPT_DIR/auto-parallel.sh' claude-sonnet-4.5 'In the Express app at examples/, implement:' --parallel 2"

echo ""
echo "==> Review changes in worktrees:"
for w in .worktrees/worker-*; do
	[[ -d "$w" ]] || continue
	echo ""
	echo "=== $w ==="
	git -C "$w/examples" diff --stat 2>/dev/null || echo "  (no changes)"
	git -C "$w" log -1 --oneline 2>/dev/null || echo "  (no commits)"
done

echo ""
echo "==> Test completed successfully!"
echo "Temp directory: $TEMP_DIR"
