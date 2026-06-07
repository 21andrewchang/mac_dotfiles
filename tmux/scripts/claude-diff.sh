#!/usr/bin/env bash
# Open a side-by-side Diffview of what THIS Claude instance changed in the
# current repo. Invoked by the tmux prefix+D keybind, which splits a pane on the
# right with cwd = the originating pane's path and $1 = that pane's id.
#
# Scope comes from per-pane tracking written by claude-track-edit.sh /
# claude-track-session.sh (PostToolUse / SessionStart hooks):
#   <pane>.files = files this instance edited
#   <pane>.base  = HEAD when this instance started
# Falls back to the full working-tree diff when no tracking data exists.
set -u

pane="${1:-}"
dir="$HOME/.cache/claude-tmux/panes"

pause_and_exit() {
    printf '\n  %s\n  (press any key to close)\n' "$1"
    read -r -n 1 _ 2>/dev/null
    exit 0
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || pause_and_exit "Not a git repository — nothing to diff."
root=$(git rev-parse --show-toplevel 2>/dev/null)
# Run from the repo root so the root-relative pathspecs below resolve correctly
# (the repo may be an ancestor of this pane's dir, e.g. a ~/.config dotfiles repo).
cd "$root" 2>/dev/null || true

# Base ref recorded at session start (fall back to HEAD if missing/invalid).
base="HEAD"
if [ -n "$pane" ] && [ -f "$dir/${pane}.base" ]; then
    b=$(cat "$dir/${pane}.base" 2>/dev/null)
    if [ -n "$b" ] && git cat-file -e "${b}^{commit}" 2>/dev/null; then
        base="$b"
    fi
fi

# Files this instance edited: absolute -> repo-relative, deduped, in-repo only.
files=()
if [ -n "$pane" ] && [ -f "$dir/${pane}.files" ]; then
    while IFS= read -r f; do
        case "$f" in "$root"/*) files+=("${f#"$root"/}") ;; esac
    done < <(awk 'NF && !seen[$0]++' "$dir/${pane}.files")
fi

if [ ${#files[@]} -eq 0 ]; then
    # No per-instance data (e.g. session predates tracking) -> full diff.
    if [ "$base" = "HEAD" ] && git diff --quiet && git diff --cached --quiet \
        && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        pause_and_exit "No changes to review."
    fi
    exec nvim -n -c "DiffviewOpen $base"
fi

# Scoped: only the files this instance touched, diffed since session start.
exec nvim -n -c "DiffviewOpen $base -- ${files[*]}"
