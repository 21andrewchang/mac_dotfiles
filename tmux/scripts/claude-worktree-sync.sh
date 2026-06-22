#!/usr/bin/env bash
# Claude Code worktree -> tmux window bridge.
#
# When a Claude session enters a git worktree, EnterWorktree switches the
# session's working directory into <repo>/.claude/worktrees/<name>. Every hook
# payload after that reports that path as .cwd. This script reads .cwd and, when
# it's a Claude worktree, stamps the tmux WINDOW with a @worktree option so:
#   - the top-left status shows the worktree dir + its branch (git-branch.sh)
#   - new splits (= - + _), `e`, and the diff popup (D/d) open INSIDE the
#     worktree, giving you a shell there to run tests / the server. (The Claude
#     pane's own shell stays at the repo root — Claude doesn't cd it — which is
#     exactly why those panes couldn't reach the worktree before.)
# When the session leaves the worktree (cwd back under the repo), the mark is
# cleared and the window reverts to the session @root.
#
# Wired to PostToolUse(EnterWorktree|ExitWorktree) for an instant update, plus
# UserPromptSubmit / Stop / SessionStart as a safety net (e.g. resuming a
# session that's already in a worktree). Detection is by the documented
# .claude/worktrees/ path, so it costs nothing on the hot path.
set -u

[ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] || exit 0

json="$(cat 2>/dev/null || true)"
cwd=$(printf '%s' "$json" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd="$PWD"

case "$cwd" in
    */.claude/worktrees/*)
        tmux set-window-option -t "$TMUX_PANE" @worktree "$cwd" 2>/dev/null
        ;;
    *)
        tmux set-window-option -t "$TMUX_PANE" -u @worktree 2>/dev/null
        ;;
esac

# Re-render the status bar now so the dir flips immediately (the branch follows
# within status-interval as the #() job re-runs).
tmux refresh-client -S 2>/dev/null
exit 0
