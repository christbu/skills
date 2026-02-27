#!/usr/bin/env bash
# Sets up shared hooks for a git worktree.
# Run from the main repo to enable worktree config, then from within a worktree to configure hooks.
set -euo pipefail

if git rev-parse --git-common-dir &>/dev/null; then
  common_dir="$(git rev-parse --git-common-dir)"
  git_dir="$(git rev-parse --git-dir)"

  if [ "$git_dir" = "$common_dir" ]; then
    # We're in the main repo — enable worktree config support
    echo "Common dir: $PWD/$common_dir"
    git config extensions.worktreeconfig true
    echo "✓ Enabled extensions.worktreeconfig in main repo"
  else
    # We're in a worktree — point hooks at the shared hooks directory
    hooks="$common_dir/hooks"
    git config --worktree core.hookspath "$hooks"
    echo "✓ Set core.hookspath to $hooks for this worktree"
  fi
else
  echo "Error: not inside a git repository" >&2
  exit 1
fi
