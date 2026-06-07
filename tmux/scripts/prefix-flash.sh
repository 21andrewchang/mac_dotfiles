#!/usr/bin/env bash
# Prefix effect: sonic boom (once) + full-screen tint (while held), via CURSOR
# COLOR. No cursor shape change.
#
# Set the cursor to the cursor_blaze amber — that color change bumps Ghostty's
# iTimeCursorChange, so prefix_flash.glsl plays the boom once, AND the shader
# tints the whole screen for as long as the cursor stays amber. We hold the
# amber while the prefix key-table is active (polling client_key_table), then
# reset, so the tint tracks how long the prefix is actually held. Escapes go
# straight to Ghostty's tty ($1), bypassing tmux (tmux manages cursor shape,
# not color, so this sticks).
#
#   $1 = client tty (Ghostty's terminal device)
#   $2 = client name/target for polling the key table (defaults to $1)
set -euo pipefail
tty="${1:?usage: prefix-flash.sh <tty> [client]}"
client="${2:-$tty}"

printf '\033]12;#abb0c7\007' > "$tty"   # dim the cursor (#c0caf5 -> ~30% darker) -> boom + tint on
sleep 0.06                              # let switch-client -T prefix take effect

# Wait while the prefix key-table is active (the cursor was set dim once above
# and stays). Exits the instant you press the next key (key_table -> root), then
# resets below. ~5-min hard cap only as a safety net against a stuck state.
i=0
while [ "$(tmux display -p -t "$client" '#{client_key_table}' 2>/dev/null || echo root)" = "prefix" ]; do
    sleep 0.05
    i=$((i + 1)); [ "$i" -ge 6000 ] && break
done

printf '\033]112\007' > "$tty"          # reset cursor color to terminal default
