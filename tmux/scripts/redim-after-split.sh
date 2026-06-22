#!/usr/bin/env bash
# Re-dim the previously-active pane after a split.
#
# Splitting resizes the old pane. For a simple pane tmux's own post-split redraw
# re-emits its grid through the patched colour_dim() (dimmed) and we're done. But
# a full-screen TUI there (claude, nvim, lazygit) repaints itself AFTER that
# redraw — that repaint lands on the terminal UNDIMMED, and nothing redraws the
# pane again until the next focus change. That's why manually switching panes
# "fixes" it: the pane-focus hook fires refresh-client, a late grid redraw that
# re-emits the cells dimmed.
#
# So we replay that late redraw ourselves: a few staggered refresh-client calls
# after the split, timed to land once the TUI has finished repainting. Once the
# pane is idle the dim sticks. Re-emitting already-dimmed cells is a no-op, so the
# extra shots are harmless.
#
# $1 = client name (#{client_name}) — target explicitly; this runs detached (-b)
# so there is no implicit "current client".
client="$1"

# Three staggered shots: early ones catch fast repaints, the 0.6s shot covers
# slower TUIs that are still drawing their first frame.
for delay in 0.12 0.35 0.6; do
	sleep "$delay"
	# Bail the moment the client is gone (detached/closed) so we don't spin.
	tmux refresh-client -t "$client" 2>/dev/null || exit 0
done
