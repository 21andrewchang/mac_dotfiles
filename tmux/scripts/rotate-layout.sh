#!/usr/bin/env bash
# Rotate the current window 90 degrees clockwise (prefix r, repeatable).
#
# For two panes this cycles through all four rotational states rather than just
# toggling two. Follow pane `a` and it travels top -> right -> bottom -> left ->
# top, a quarter turn per press:
#
#   a      b a      b      a b      a
#   b  ->       ->  a  ->       ->  b
#
# The trick is that a clockwise quarter-turn is NOT "swap + flip" every time --
# that just oscillates between two states because the swap keeps undoing itself.
# It's asymmetric:
#   stacked      -> side-by-side : rotate the contents, THEN lay side by side
#   side-by-side -> stacked      : just lay stacked, no content rotation
# Run both transitions and pane `a` sweeps cleanly clockwise.
#
# Orientation is read from geometry, not tracked: count distinct pane top edges.
# All panes share one top edge => single row (side by side) => go stacked.
# Otherwise => stacked => rotate + go side by side. Exact for the 2-pane case.
#
#   $1 = window id (#{window_id}) — target explicitly; run-shell has no reliable
#        implicit "current window".
set -u
win="${1:?usage: rotate-layout.sh <window-id>}"

rows=$(tmux list-panes -t "$win" -F '#{pane_top}' | sort -u | wc -l)
if [ "$rows" -eq 1 ]; then
	# Side by side -> stacked. Left pane becomes top, right becomes bottom: that
	# is already even-vertical's index order, so no content rotation.
	tmux select-layout -t "$win" even-vertical
else
	# Stacked -> side by side. Top pane must end up on the right, so rotate the
	# contents first, then lay them out in a single row.
	tmux rotate-window -t "$win"
	tmux select-layout -t "$win" even-horizontal
fi
