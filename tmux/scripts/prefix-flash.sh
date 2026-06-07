#!/usr/bin/env bash
# Flash the tmux-prefix Ghostty shader (shaders/prefix_flash.glsl).
#
# A GPU shader can't be signaled directly, so we smuggle the "prefix is active"
# state through the cursor color: set it to a super-light-orange sentinel that
# the shader detects (isPrefix()) and paints a pulsing glow + ripples around.
# We hold the orange for exactly as long as the prefix key-table is active
# (polling client_key_table), so the pulsing glow lasts while the prefix is
# held, then reset the cursor color. Bound from tmux.conf on the prefix key.
#
#   $1 = client tty (Ghostty's terminal device) to write the escapes to
#   $2 = client name/target used to poll the key table (defaults to $1)
set -euo pipefail
tty="${1:?usage: prefix-flash.sh <tty> [client]}"
client="${2:-$tty}"

ORANGE='\033]12;#ffd9b3\007'   # super light orange sentinel (matches isPrefix())
RESET='\033]112\007'           # reset cursor color to terminal default

printf '%b' "$ORANGE" > "$tty"
sleep 0.10                      # min visible flash + let switch-client take effect

# Hold the orange while the prefix key-table is active; bail after ~5s as a
# safety cap so a stuck table never leaves the cursor recolored.
for _ in $(seq 1 100); do
    state=$(tmux display -p -t "$client" '#{client_key_table}' 2>/dev/null || echo root)
    [ "$state" = "prefix" ] || break
    sleep 0.05
done

printf '%b' "$RESET" > "$tty"
