#!/usr/bin/env bash
# Record every file this Claude SESSION edits, keyed by Claude's stable
# session_id — NOT the tmux pane id, which changes when a session is resumed into
# a new pane and would split/orphan the tracked list. Also refreshes a
# pane->session map so the diff keybind can resolve the current pane to this
# session. Wired to PostToolUse (Edit|Write|MultiEdit|NotebookEdit).
set -u

dir="$HOME/.cache/claude-tmux/panes"
mkdir -p "$dir"

json="$(cat 2>/dev/null || true)"
[ -n "$json" ] || exit 0

sid=$(printf '%s' "$json" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0

# Keep the current pane pointed at this session (survives pane-id drift).
[ -n "${TMUX_PANE:-}" ] && printf '%s\n' "$sid" > "$dir/pane-${TMUX_PANE}.session"

fp=$(printf '%s' "$json" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
[ -n "$fp" ] || exit 0

printf '%s\n' "$fp" >> "$dir/${sid}.files"
exit 0
