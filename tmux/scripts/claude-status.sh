#!/usr/bin/env bash
# Claude Code -> tmux window status-dot bridge.
#
# Three states rendered by status-overrides.conf:
#   @claude_status == working -> white dot (Claude actively running)
#   @claude_status == done    -> blue dot  (Claude finished / your turn)
#   (unset)                   -> gray dot  (idle / untouched window)
#
# Usage:
#   claude-status.sh working    # Claude is running (UserPromptSubmit/PreToolUse)
#   claude-status.sh done       # Claude finished (Stop hook)
#   claude-status.sh reset-all  # clear every dot to gray (from tmux.conf reload)
set -u

state="${1:-}"

# --- Bulk reset: wipe all dots back to gray. Run on config reload. ------------
if [ "$state" = "reset-all" ]; then
    tmux list-windows -a -F '#{window_id}' 2>/dev/null | while read -r w; do
        tmux set-window-option -u -t "$w" @claude_status 2>/dev/null
    done
    exit 0
fi

# --- Hook path: must be inside a tmux pane. -----------------------------------
[ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] || exit 0

case "$state" in
    working)
        tmux set-window-option -t "$TMUX_PANE" @claude_status working 2>/dev/null
        exit 0
        ;;
    done)
        tmux set-window-option -t "$TMUX_PANE" @claude_status done 2>/dev/null
        ;;
    *)
        exit 0
        ;;
esac

# --- Chime on done, only when you're NOT looking at this window. --------------
# "attended" = window is active AND its session has a client attached.
attended=$(tmux display-message -p -t "$TMUX_PANE" \
    '#{&&:#{window_active},#{session_attached}}' 2>/dev/null)
if [ "$attended" != "1" ]; then
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
fi
exit 0
