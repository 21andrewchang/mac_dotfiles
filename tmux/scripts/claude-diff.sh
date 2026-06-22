#!/usr/bin/env bash
# Diffview popups for prefix d / prefix D:
#   d (session) = EXCLUSIVELY what THIS Claude session changed — scoped to the
#                 files it edited, diffed from a snapshot of the tree taken when
#                 the session started. Shows "No changes made by this session"
#                 when it changed nothing; never falls back to the whole branch.
#   D (branch)  = every uncommitted change in the repo (the whole branch).
#
# $1 = pane id (resolves the session), $2 = mode (session|branch). Tracking is
# keyed by Claude's stable session_id via a pane->session map the hooks refresh,
# so it resolves correctly even after the pane id changes on a resume.
set -u

mode="${2:-session}"
dir="$HOME/.cache/claude-tmux/panes"

# Resolve the CURRENTLY FOCUSED pane (the bright one under inactive-pane dimming),
# not the popup's own pane. display-popup bakes #{pane_id} into $1, but that does
# not reliably reach us as the focused pane; querying tmux live from inside the
# popup returns the real active pane. Fall back to $1 if tmux is unavailable.
pane="${1:-}"
if [ -n "${TMUX:-}" ]; then
    p=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
    [ -n "$p" ] && pane="$p"
fi

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

# --- D: the whole branch (all uncommitted changes), no session scoping. ---
if [ "$mode" = "branch" ]; then
    if git diff --quiet && git diff --cached --quiet \
        && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        pause_and_exit "No changes on this branch."
    fi
    exec nvim -n -c "DiffviewOpen"
fi

# --- d: exclusively this session's changes. ---
# Resolve the pressed pane to its Claude session (map refreshed by the hooks;
# survives pane-id drift). Fall back to legacy pane-keyed files.
key="$pane"
if [ -n "$pane" ] && [ -f "$dir/pane-${pane}.session" ]; then
    sid=$(cat "$dir/pane-${pane}.session" 2>/dev/null)
    # Resolve to the session if it's tracked at all — a recorded edit list is
    # enough. The base may be absent (session started before this hook, or its
    # SessionStart didn't run); the baseline defaults to HEAD below in that case.
    if [ -n "$sid" ] && { [ -f "$dir/${sid}.files" ] || [ -f "$dir/${sid}.base" ]; }; then
        key="$sid"
    fi
fi

# Files this session edited: absolute -> repo-relative, deduped, in-repo only.
files=()
if [ -n "$key" ] && [ -f "$dir/${key}.files" ]; then
    while IFS= read -r f; do
        case "$f" in "$root"/*) files+=("${f#"$root"/}") ;; esac
    done < <(awk 'NF && !seen[$0]++' "$dir/${key}.files")
fi
[ ${#files[@]} -eq 0 ] && pause_and_exit "No changes made by this session."

# Baseline = snapshot of the tree when the session started (so changes that
# predate the session are excluded); fall back to the recorded base commit, HEAD.
baseline=""
[ -f "$dir/${key}.start.snap" ] && baseline=$(cat "$dir/${key}.start.snap" 2>/dev/null)
if [ -z "$baseline" ] || ! git cat-file -e "${baseline}^{commit}" 2>/dev/null; then
    baseline=$(cat "$dir/${key}.base" 2>/dev/null)
fi
if [ -z "$baseline" ] || ! git cat-file -e "${baseline}^{commit}" 2>/dev/null; then
    baseline="HEAD"
fi

# Diff against a fresh snapshot of the current tree so new (untracked) files this
# session created show up too. Fall back to the live working tree if it fails.
# Snapshot = the baseline with ONLY this session's files updated to their current
# content (force-added, so gitignored/untracked files show too). Staying O(edited
# files) instead of statting the whole tree keeps this fast even in big repos.
now=""
tmpidx=$(mktemp 2>/dev/null) && {
    GIT_INDEX_FILE="$tmpidx" git read-tree "$baseline" 2>/dev/null
    # Add each file independently — a single unaddable path (a submodule file, a
    # deleted file, one outside the repo) would otherwise abort the whole batch
    # and silently blank the diff.
    for f in "${files[@]}"; do
        [ -e "$f" ] && GIT_INDEX_FILE="$tmpidx" git add -Af -- "$f" 2>/dev/null
    done
    tree=$(GIT_INDEX_FILE="$tmpidx" git write-tree 2>/dev/null)
    rm -f "$tmpidx"
    [ -n "$tree" ] && now=$(git commit-tree "$tree" -p HEAD -m "claude diff snapshot" 2>/dev/null)
}
if [ -n "$now" ]; then
    git diff --quiet "$baseline" "$now" -- "${files[@]}" \
        && pause_and_exit "No changes made by this session."
    exec nvim -n -c "DiffviewOpen ${baseline}..${now} -- ${files[*]}"
fi
git diff --quiet "$baseline" -- "${files[@]}" \
    && pause_and_exit "No changes made by this session."
exec nvim -n -c "DiffviewOpen ${baseline} -- ${files[*]}"
