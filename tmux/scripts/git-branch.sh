#!/usr/bin/env bash
# Print " <branch>" for the git repo at $1, for the top-left status bar.
#
# $1 is the directory whose branch to show, expanded by tmux before the #() job
# runs (see status-overrides.conf status-left). It FOLLOWS THE ACTIVE PANE:
#   - the window's Claude worktree (@worktree) if a Claude session entered one
#     (set by claude-worktree-sync.sh; forced because Claude's own shell stays
#     at the repo root), else
#   - the active pane's cwd (#{pane_current_path}).
# So `cd`-ing a pane into a worktree/repo shows that branch, and a manual
# `git checkout` is reflected on its own since git is read live every
# status-interval. Prints nothing when $1 isn't a git repo (status-left then
# shows just the directory).
#
#  is U+E0A0 (powerline branch glyph). Detached HEAD -> short sha.
set -u

dir="${1:-}"
[ -n "$dir" ] && [ -d "$dir" ] || exit 0

branch=$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null) \
    || branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null) \
    || exit 0

[ -n "$branch" ] && printf ' %s' "$branch"
exit 0
