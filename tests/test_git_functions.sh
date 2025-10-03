#!/usr/bin/env bash
set -euo pipefail

echo "[TEST] Running git-helpers tests..."

# Load helpers
source ./bin/git_helpers.sh

# Create temporary test repo
TMPDIR=$(mktemp -d)
echo "Temporary directory created : $TMPDIR"

cd "$TMPDIR"
git init -q
git config user.email "test@example.com"
git config user.name "Tester"

echo "hello" > file.txt
git add file.txt
git commit -m "init commit" -q

# Create another branch
git checkout -b feature/test -q
echo "more" >> file.txt
git commit -am "feature commit" -q

# Run sample helper commands
echo "[TEST] current_branch:"
current_branch

echo "[TEST] gh_compare_hashes on feature/test:"
gh_compare_hashes feature/test origin || true

echo "[TEST] gh_search_commits --grep feature:"
gh_search_commits --grep feature || true

echo "[TEST] gh_assist_conflicts (should show none):"
gh_assist_conflicts

cd -
rm -rf "$TMPDIR"

echo "[TEST] All tests completed."

