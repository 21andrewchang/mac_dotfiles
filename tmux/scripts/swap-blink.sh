#!/usr/bin/env bash
# "pick a number" blink, shared by prefix m (swap) and prefix M (merge): while
# the given key-table is active — after the prefix key, until you press a digit
# (act) or any other key (cancel) — the current window's tab (#I:#W) *breathes*:
# its fg fades smoothly white <-> dim on a cosine ease, driven frame-by-frame
# through the @swap_blink option that status-overrides.conf reads
# (`#[fg=#{@swap_blink}]`). Unset -> solid #ffffff.
#
# Mirrors prefix-flash.sh: poll #{client_key_table} and stop the instant the
# client leaves the table. A single keypress always returns the table to root,
# so act and cancel both exit here the same way — no cancel binding.
#
#   $1 = client name (#{client_name}) — target explicitly; runs detached (-b).
#   $2 = window id   (#{window_id})   — the window being moved (stable across
#        the index renumber that swap-window triggers).
#   $3 = key-table to watch           — "swapwin" (default) or "mergewin".
#   $4 = dim end color  (hex)         — the breath's far end; defaults to the
#        swap blue-gray. merge passes a distinct color so the modes differ.
set -u
client="${1:?usage: swap-blink.sh <client> <window-id> [table] [dim-hex]}"
win="${2:?usage: swap-blink.sh <client> <window-id> [table] [dim-hex]}"
table="${3:-swapwin}"
dim="${4:-#3b4261}"; dim="${dim#\#}"
dr=$((16#${dim:0:2})); dg=$((16#${dim:2:2})); db=$((16#${dim:4:2}))

# One full breath as a gradient of truecolor hex values: bright #ffffff at the
# ends, the dim color at the middle, cosine-eased so the motion has no hard edges.
# STEPS * the sleep below sets the cycle length (~16 * 0.025s ≈ 0.4s per breath).
mapfile -t PALETTE < <(awk -v steps=16 -v dr="$dr" -v dg="$dg" -v db="$db" 'BEGIN{
    pi = 3.14159265358979;
    br = 255; bg = 255; bb = 255;        # bright end  (#ffffff)
    for (i = 0; i < steps; i++) {
        t = (1 - cos(2 * pi * i / steps)) / 2;   # 0 -> 1 -> 0, smooth
        r = br + (dr - br) * t;
        g = bg + (dg - bg) * t;
        b = bb + (db - bb) * t;
        printf "#%02x%02x%02x\n", int(r + 0.5), int(g + 0.5), int(b + 0.5);
    }
}')
n=${#PALETTE[@]}

idx=0
i=0
while [ "$(tmux display -p -t "$client" '#{client_key_table}' 2>/dev/null || echo root)" = "$table" ]; do
    # Set the frame's color and repaint the status line in one tmux call.
    tmux set-window-option -t "$win" @swap_blink "${PALETTE[idx]}" \; \
         refresh-client -S -t "$client" 2>/dev/null
    idx=$(((idx + 1) % n))
    sleep 0.025
    i=$((i + 1)); [ "$i" -ge 560 ] && break   # ~14s safety cap (560 * 0.025s)
done

# Restore solid (unset -> not truthy -> #ffffff) and repaint.
tmux set-window-option -u -t "$win" @swap_blink 2>/dev/null
tmux refresh-client -S -t "$client" 2>/dev/null
