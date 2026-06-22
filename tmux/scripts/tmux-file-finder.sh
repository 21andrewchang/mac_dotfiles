#!/usr/bin/env bash
# tmux-file-finder — fzf over files under the session root, then open the pick
# in neovim in a new window. Bound to `prefix + E`.
# The file-level sibling of tmux-sessionizer.sh (prefix s).
#
#   enter -> open the file in nvim (new window, cwd = search root)
#
# File list uses `rg --files` with fd/find fallbacks. We pass --no-ignore-vcs so
# gitignored dotfiles (.env, .claude/, …) still show up — plain --hidden alone
# keeps respecting .gitignore and would hide them. node_modules is excluded so
# the un-ignore doesn't flood the list.

# Search root: the popup is launched with -d '#{@root}' (the session dir set by
# prefix w, pane path as fallback), so $PWD is already that root. Allow an
# explicit override as $1.
root="${1:-$PWD}"
cd "$root" || exit 1

list_files() {
    if command -v rg >/dev/null 2>&1; then
        rg --files --hidden --no-ignore-vcs --glob '!.git' --glob '!node_modules' 2>/dev/null
    elif command -v fd >/dev/null 2>&1; then
        fd --type f --hidden --no-ignore-vcs --exclude .git --exclude node_modules 2>/dev/null
    else
        find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed 's|^\./||'
    fi
}

selected=$(list_files | fzf --reverse --prompt='edit > ' \
    --header 'enter: open in nvim' \
    --preview 'p={}; if command -v bat >/dev/null 2>&1; then bat --color=always --style=numbers --line-range=:200 "$p"; else head -200 "$p"; fi' \
    --preview-window=right,55%)

[[ -z "$selected" ]] && exit 0

# New window running nvim, cwd = search root so relative paths / LSP / :Ex
# behave. %q-escape the path so spaces and friends survive the shell.
esc=$(printf '%q' "$selected")
tmux new-window -c "$root" -n "$(basename "$selected")" "nvim $esc"
