#!/usr/bin/env bash
# Claude Code -> tmux window status-dot bridge.
#
# Four states rendered by status-overrides.conf:
#   @claude_status == working -> orange dot (Claude actively running)
#   @claude_status == done    -> blue dot   (Claude finished, you haven't looked)
#   @claude_status == seen     -> white dot  (Claude finished, you've viewed it)
#   (unset)                   -> gray dot   (idle / untouched window)
#
# done -> seen happens when you focus the window (pane-focus-in hook in
# tmux.conf), or immediately here if Claude finishes while you're already
# looking at the window.
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

# --- Focus path: viewing a fresh "done" window marks it "seen" (blue -> white).
# Called from the pane-focus-in hook with the focused window id. Only the blue
# (unviewed) state flips; working/seen/idle are left alone.
if [ "$state" = "seen-if-done" ]; then
    w="${2:-}"
    [ -n "$w" ] || exit 0
    [ "$(tmux display-message -p -t "$w" '#{@claude_status}' 2>/dev/null)" = "done" ] \
        && tmux set-window-option -t "$w" @claude_status seen 2>/dev/null
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
        # If you're already looking at this window, it's "seen" (white) right
        # away; otherwise it's a fresh, unviewed "done" (blue) until you focus
        # it, and we chime. "attended" = window active AND a client is attached.
        attended=$(tmux display-message -p -t "$TMUX_PANE" \
            '#{&&:#{window_active},#{session_attached}}' 2>/dev/null)
        if [ "$attended" = "1" ]; then
            tmux set-window-option -t "$TMUX_PANE" @claude_status seen 2>/dev/null
        else
            tmux set-window-option -t "$TMUX_PANE" @claude_status done 2>/dev/null
            afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
        fi
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
