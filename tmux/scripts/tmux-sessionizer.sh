#!/usr/bin/env bash
# tmux-sessionizer — fzf over your live sessions AND project dirs, then switch
# to (or create) the right session. Replaces the default choose-tree.
# Bound to `prefix + s` (and `prefix + f`). Adapted from ThePrimeagen's.
#
#   enter  on "[TMUX] name"  -> switch to that session
#   enter  on a directory     -> create-or-switch a session named after it
#   ctrl-x on "[TMUX] name"  -> kill that session, refresh the list
#
# New sessions get @root set by the session-created hook in tmux.conf, so the
# status bar shows  name  ~/path.

# Roots searched ONE level deep — each immediate subdir is offered as a project.
search_dirs=(
    "$HOME/work"
    "$HOME/dev"
    "$HOME/notes"
)
# Dirs offered as-is (the dir itself, not its children).
extra_dirs=(
    "$HOME/.config"
    "$HOME/climb"
    "$HOME/conductor"
)

# fzf list: live sessions first (so this doubles as a switcher), then projects.
list_candidates() {
    local current
    current=$(tmux display-message -p '#S' 2>/dev/null)
    tmux list-sessions -F '[TMUX] #{session_name}' 2>/dev/null | grep -vFx "[TMUX] $current"
    {
        find "${search_dirs[@]}" -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null
        printf '%s\n' "${extra_dirs[@]}"
    } | sort -u
}

# `--list` just prints candidates — used by fzf's reload after a kill.
if [[ "$1" == "--list" ]]; then
    list_candidates
    exit 0
fi

# Source a per-project (then global) startup script into a freshly made session,
# so one keystroke can rebuild a whole layout. Drop a `.tmux-sessionizer` file
# in a project root (or ~/) with e.g. `tmux split-window -h; tmux send-keys ...`.
hydrate() {
    local name="$1" dir="$2"
    if   [[ -f "$dir/.tmux-sessionizer" ]]; then
        tmux send-keys -t "$name" "source '$dir/.tmux-sessionizer'" C-m
    elif [[ -f "$HOME/.tmux-sessionizer" ]]; then
        tmux send-keys -t "$name" "source '$HOME/.tmux-sessionizer'" C-m
    fi
}

# Absolute path to this script, so fzf's reload binding can call it back.
self="${BASH_SOURCE[0]}"
[[ "$self" == /* ]] || self="$PWD/$self"

if [[ $# -eq 1 ]]; then
    selected="$1"
else
    selected=$(list_candidates | fzf --reverse --prompt='go > ' \
        --header 'enter: switch/open    ctrl-x: kill session' \
        --preview 'p={}; if [ -d "$p" ]; then ls -A "$p"; else tmux list-windows -t "${p#\[TMUX\] }" 2>/dev/null; fi' \
        --preview-window=right,45% \
        --bind 'ctrl-x:execute-silent(s={}; case "$s" in "[TMUX] "*) tmux kill-session -t "${s#\[TMUX\] }";; esac)+reload('"$self"' --list)')
fi

[[ -z "$selected" ]] && exit 0

if [[ "$selected" == "[TMUX] "* ]]; then
    # Existing session — just switch to it.
    name="${selected#\[TMUX\] }"
else
    # Directory — tmux names treat '.'/':' specially, so sanitize.
    name=$(basename "$selected" | tr ' .:' '___')
    if ! tmux has-session -t="$name" 2>/dev/null; then
        tmux new-session -ds "$name" -c "$selected"
        hydrate "$name" "$selected"
    fi
fi

if [[ -z "$TMUX" ]]; then
    tmux attach -t "$name"
else
    tmux switch-client -t "$name"
fi
