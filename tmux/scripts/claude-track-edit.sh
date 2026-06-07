#!/usr/bin/env bash
# Record every file this Claude instance edits, keyed by its tmux pane, so the
# diff viewer (prefix + D) can scope to exactly what this instance changed.
# Wired to the PostToolUse hook (Edit|Write|MultiEdit|NotebookEdit).
set -u

[ -n "${TMUX_PANE:-}" ] || exit 0

dir="$HOME/.cache/claude-tmux/panes"
mkdir -p "$dir"

json="$(cat 2>/dev/null || true)"
[ -n "$json" ] || exit 0

fp=$(printf '%s' "$json" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
[ -n "$fp" ] || exit 0

printf '%s\n' "$fp" >> "$dir/${TMUX_PANE}.files"
exit 0
