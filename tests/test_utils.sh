#!/usr/bin/env bash

set -euo pipefail

echo "Running ToolGit utility smoke tests..."

for script in bin/*; do
  echo "Checking $script is executable..."
  test -x "$script"
done

echo "All scripts are executable."
