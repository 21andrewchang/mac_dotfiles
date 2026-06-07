#!/usr/bin/env bash
# On a fresh Claude instance, reset its tracked-edit list and record the repo's
# starting commit, so the diff viewer can show everything this instance changed
# (including anything it commits) from that point on.
# Wired to the SessionStart hook.
set -u

[ -n "${TMUX_PANE:-}" ] || exit 0

dir="$HOME/.cache/claude-tmux/panes"
mkdir -p "$dir"

json="$(cat 2>/dev/null || true)"
source=$(printf '%s' "$json" | jq -r '.source // empty' 2>/dev/null)
cwd=$(printf '%s' "$json" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"

# Only reset for a brand-new instance — not resume/clear, which continue the
# same work and should keep the existing list + base.
if [ "$source" = "startup" ] || [ -z "$source" ]; then
    : > "$dir/${TMUX_PANE}.files"
    base=$(git -C "$cwd" rev-parse HEAD 2>/dev/null)
    if [ -n "$base" ]; then
        printf '%s\n' "$base" > "$dir/${TMUX_PANE}.base"
    else
        rm -f "$dir/${TMUX_PANE}.base"
    fi
fi
exit 0
