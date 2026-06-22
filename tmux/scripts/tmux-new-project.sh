#!/usr/bin/env bash
# tmux-new-project — spin up a brand-new project from scratch. Type a name,
# pick which root it lives under (work / dev / notes / …), and this makes the
# directory then hands off to the sessionizer to create + switch to a session
# for it. Bound to `prefix + S`.
#
#   1. type the project name
#   2. pick the parent root with fzf
#   -> mkdir <root>/<name>, then create-or-switch a session named after it
#      (same create path — @root, hydrate, switch — as `prefix + s`).

# Parent roots a new project can live under. Keep in sync with search_dirs
# in tmux-sessionizer.sh.
roots=(
    "$HOME/work"
    "$HOME/dev"
    "$HOME/notes"
)

sessionizer="$HOME/.config/tmux/scripts/tmux-sessionizer.sh"

# 1. Project name (typed in the popup). `read` trims surrounding whitespace.
read -rp 'new project name: ' name
[[ -z "$name" ]] && exit 0

# 2. Pick the parent root with fzf (matches the sessionizer's look).
root=$(printf '%s\n' "${roots[@]}" | fzf --ansi --reverse \
    --prompt="create '$name' in > " --header 'pick the parent directory') || exit 0
[[ -z "$root" ]] && exit 0

dir="$root/$name"
if ! mkdir -p "$dir"; then
    tmux display-message "new-project: could not create $dir"
    exit 1
fi

# Hand off to the sessionizer: it resolves the absolute dir, creates (or
# switches to) a session named after it, runs hydrate, and switches the client.
exec "$sessionizer" "$dir"
