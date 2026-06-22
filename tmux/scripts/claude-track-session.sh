#!/usr/bin/env bash
# On SessionStart, initialize per-SESSION diff tracking keyed by Claude's stable
# session_id, and refresh the pane->session map. Keying by session_id (not the
# tmux pane id) keeps tracking correct when a session is resumed into a new pane.
# Wired to the SessionStart hook.
set -u

dir="$HOME/.cache/claude-tmux/panes"
mkdir -p "$dir"

json="$(cat 2>/dev/null || true)"
sid=$(printf '%s' "$json" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
source=$(printf '%s' "$json" | jq -r '.source // empty' 2>/dev/null)
cwd=$(printf '%s' "$json" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"

# Point the current pane at this session so the d/D keybind can resolve it.
[ -n "${TMUX_PANE:-}" ] && printf '%s\n' "$sid" > "$dir/pane-${TMUX_PANE}.session"

# Initialize on a fresh start, OR when we've never seen this session id (e.g. a
# resume that minted a new id). Otherwise keep the accumulated state so
# resume/clear continue the same work.
if [ "$source" = "startup" ] || [ -z "$source" ] || [ ! -f "$dir/${sid}.base" ]; then
    : > "$dir/${sid}.files"
    base=$(git -C "$cwd" rev-parse HEAD 2>/dev/null)
    if [ -n "$base" ]; then
        printf '%s\n' "$base" > "$dir/${sid}.base"
    else
        rm -f "$dir/${sid}.base"
    fi

    # Snapshot the working tree at session start as the baseline for the `d`
    # (this-session) diff, so it excludes changes that were already present when
    # the session opened. claude-diff.sh diffs this against a fresh snapshot.
    snap=$("$(dirname "$0")/claude-snapshot-tree.sh" "$cwd")
    if [ -n "$snap" ]; then
        printf '%s\n' "$snap" > "$dir/${sid}.start.snap"
    else
        rm -f "$dir/${sid}.start.snap"
    fi
fi
exit 0
