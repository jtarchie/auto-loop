#!/bin/bash
set -e

echo "==> Setting up demo app"
cd examples
npm install --silent

echo ""
echo "==> Committing initial state"
git add -A
git commit -m "Initial Express app" || true

cd ..

echo ""
echo "==> Adding features in parallel (2 workers)"
cat examples/features.txt | ./auto-parallel.sh claude-sonnet-4.5 "In the Express app at examples/, implement:" --parallel 2

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
echo "==> Next steps:"
echo "# Review changes:"
echo "for w in .worktrees/worker-*; do git -C \"\$w/examples\" diff; done"
echo ""
echo "# Test the app in a worktree:"
echo "cd .worktrees/worker-1/examples && npm start"
echo ""
echo "# Merge changes:"
echo "for w in .worktrees/worker-*; do (cd \"\$w\" && git push origin HEAD); done"
