#!/usr/bin/env bash
# Shortcut cheatsheet rendered in a rounded display-popup (bound to prefix ?).
# Lists the custom bindings from tmux.conf. Closes on any key.
# test comment for diff viewer

b=$'\e[1m'; r=$'\e[0m'
dim=$'\e[38;2;86;96;138m'
acc=$'\e[38;2;122;162;247m'
key=$'\e[38;2;255;255;255m'
sec=$'\e[1;38;2;122;162;247m'

p() { printf '  %s%-8s%s %s\n' "$key" "$1" "$r" "$2"; }
h() { printf '\n%s%s%s\n' "$sec" "$1" "$r"; }

clear
printf '%shelp%s   %sprefix = Ctrl-a%s\n' "$b$acc" "$r" "$dim" "$r"

h 'Windows'
p 'o'        'open terminal'
p 'O'        'open claude'
p 'e'        'editor'
p 'E'        'fzf editor'
p '1-9'      'go to N'
p 'n / p'    'next / prev window'
p 'm #'      'move tab to position #'
p 'w'        'set workspace dir'

h 'Panes'
p '= / -'    'split right / down'
p '+ / _'    'new claude split'
p 'h j k l'  'resize pane'
p 'f'        'full-screen'
p 'x'        'kill pane'
p 'b'        'break pane'
p 'r'        'rotate panes'

h 'Sessions'
p 's'        'sessionizer (fzf)'
p 'S'        'new project + session'

h 'Misc'
p 'd'        'diff: this session'
p 'D'        'diff: whole branch'
p 'v'        'vim mode'
p 'R'        'reload config'
p '?'        'this cheatsheet'

read -rsn1
