#!/bin/bash
cd "$(dirname "$0")/.."

echo "==> Planning features (parallel)"
cat examples/features.txt | ./auto-parallel.sh gpt-5-mini "Create plan for" --parallel 4 -- --agent plan

echo ""
echo "==> Implementing features (parallel)"
cat examples/features.txt | ./auto-parallel.sh gpt-5-mini "Implement" --parallel 4 -- --agent task

echo ""
echo "==> Review changes in worktrees:"
for w in .worktrees/worker-*; do
	echo "[$w]"
	git -C "$w" log -1 --oneline
done

echo ""
echo "==> To merge changes:"
echo "for w in .worktrees/worker-*; do (cd \"\$w\" && git push origin HEAD); done"
echo "git pull"
