#!/usr/bin/env bash
# Print a dangling commit sha capturing the FULL working tree (tracked +
# untracked, .gitignore respected) of the repo containing $1 — without touching
# the real index or HEAD. Used by the turn tracker to mark "tree state at this
# instant" so two snapshots can be diffed into an exact per-turn change set.
# Empty output + nonzero exit when $1 isn't in a git repo (or repo has no HEAD).
set -u

cwd="${1:-$PWD}"
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 1
[ -n "$root" ] || exit 1

tmpidx=$(mktemp) || exit 1
GIT_INDEX_FILE="$tmpidx" git -C "$root" read-tree HEAD 2>/dev/null
GIT_INDEX_FILE="$tmpidx" git -C "$root" add -A 2>/dev/null
tree=$(GIT_INDEX_FILE="$tmpidx" git -C "$root" write-tree 2>/dev/null)
rm -f "$tmpidx"
[ -n "$tree" ] || exit 1

git -C "$root" commit-tree "$tree" -p HEAD -m "claude tree snapshot" 2>/dev/null
