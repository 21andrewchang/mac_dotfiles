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
# Both blocks are ordered most-recently-used first: sessions by last-attached
# time, project dirs by directory mtime. (stat -f is BSD/macOS syntax.)
list_candidates() {
    local current
    current=$(tmux display-message -p '#S' 2>/dev/null)

    # Live sessions, most-recently-attached first. Each is shown as a single
    # Claude status dot (same dots as the window tabs) aggregated across its
    # windows by priority: done/blue (unviewed) > working/orange > seen/white >
    # idle/gray. The leading timestamp drives the sort, then is stripped off.
    local order win s color
    order=$(tmux list-sessions -F '#{session_last_attached} #{session_name}' 2>/dev/null \
        | sort -rn | sed 's/^[0-9]* //')
    win=$(tmux list-windows -a -F '#{session_name} #{@claude_status}' 2>/dev/null)
    while IFS= read -r s; do
        [[ -z "$s" || "$s" == "$current" ]] && continue
        case "$(awk -v n="$s" '$1==n{if($2=="done")d=1;else if($2=="working")w=1;else if($2=="seen")v=1}
                                END{print d?"done":w?"working":v?"seen":"idle"}' <<<"$win")" in
            done)    color=$'\033[38;2;68;136;245m'   ;;  # blue   #4488F5
            working) color=$'\033[38;2;255;158;100m' ;;  # orange #ff9e64
            seen)    color=$'\033[38;2;255;255;255m' ;;  # white  #ffffff
            *)       color=$'\033[38;2;86;96;137m'   ;;  # gray   #565f89
        esac
        printf '%s● \033[0m%s\n' "$color" "$s"
    done <<<"$order"

    # Project dirs, most-recently-modified first.
    {
        find "${search_dirs[@]}" -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null
        printf '%s\n' "${extra_dirs[@]}"
    } | sort -u \
      | tr '\n' '\0' \
      | xargs -0 stat -f '%m %N' 2>/dev/null \
      | sort -rn \
      | sed 's/^[0-9]* //'
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

# Turn a selection into a real directory. Curated candidates are already absolute
# paths; a typed query (.config/nvim, ~/x, sub/dir) is resolved relative to $HOME
# so you can spin up a session for any nested dir, not just the listed roots.
resolve_dir() {
    local q="$1"
    q="${q/#\~\//$HOME/}"
    if   [[ -d "$q" ]];       then printf '%s' "$q"
    elif [[ -d "$HOME/$q" ]]; then printf '%s' "$HOME/$q"
    else return 1
    fi
}

# Absolute path to this script, so fzf's reload binding can call it back.
self="${BASH_SOURCE[0]}"
[[ "$self" == /* ]] || self="$PWD/$self"

if [[ $# -eq 1 ]]; then
    selected="$1"
else
    # --print-query makes the typed text a fallback "selection": if it matches no
    # candidate, fzf still hands it back and we treat it as a path (.config/nvim).
    out=$(list_candidates | fzf --ansi --print-query --reverse --prompt='go > ' \
        --header 'enter: switch/open (or type a path)    ctrl-x: kill session' \
        --bind 'ctrl-x:execute-silent(s={}; case "$s" in "● "*) tmux kill-session -t "${s#● }";; esac)+reload('"$self"' --list)')
    code=$?
    # 0 = picked a row; 1 = no match but enter pressed (use the typed query).
    # Anything else (130 = ESC/ctrl-c, 2 = error) means cancel.
    [[ $code -eq 0 || $code -eq 1 ]] || exit 0
    # Line 1 is the query, line 2 (if present) the highlighted row. Prefer the row.
    query=$(sed -n '1p' <<<"$out")
    row=$(sed -n '2p' <<<"$out")
    selected="${row:-$query}"
fi

[[ -z "$selected" ]] && exit 0

if [[ "$selected" == "● "* ]]; then
    # Existing session (dot-prefixed row) — just switch to it.
    name="${selected#● }"
else
    # Curated absolute path or a typed query — resolve to a real directory.
    dir=$(resolve_dir "$selected") || {
        tmux display-message "sessionizer: no such directory: $selected"
        exit 1
    }
    # tmux names treat '.'/':' specially, so sanitize the basename.
    name=$(basename "$dir" | tr ' .:' '___')
    if ! tmux has-session -t="$name" 2>/dev/null; then
        tmux new-session -ds "$name" -c "$dir"
        hydrate "$name" "$dir"
    fi
fi

if [[ -z "$TMUX" ]]; then
    tmux attach -t "$name"
else
    tmux switch-client -t "$name"
fi
