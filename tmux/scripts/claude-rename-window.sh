#!/usr/bin/env bash
# Rename the current tmux window to the Claude Code chat's AI title.
#
# Claude Code generates an "ai-title" for each chat (the same string used by
# /rename) and records it in the session transcript. This hook reads the hook
# JSON from stdin, pulls the latest ai-title out of the transcript, and renames
# the tmux window to match — so each tab reads like the chat it's running.
#
# Wire it to the Stop hook in ~/.config/claude/settings.json.
set -u

[ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] || exit 0

json="$(cat 2>/dev/null || true)"
[ -n "$json" ] || exit 0

# transcript_path is provided in every hook payload.
tp=$(printf '%s' "$json" | sed -n 's/.*"transcript_path":"\([^"]*\)".*/\1/p')
[ -n "$tp" ] && [ -f "$tp" ] || exit 0

# Latest ai-title wins (last occurrence in the JSONL transcript).
title=$(grep '"type":"ai-title"' "$tp" 2>/dev/null | tail -1 \
    | sed -n 's/.*"aiTitle":"\([^"]*\)".*/\1/p')
[ -n "$title" ] || exit 0

# Slugify into a short kebab tab name, biased toward FEWER words. We drop a
# leading verb, stopwords, and low-information "generic" words, then keep the
# first @claude-title-words (default 2) of what's left. If only one strong word
# survives, the name is a single word.
#   "Build tmux sidebar for project management" -> "tmux-sidebar"
maxw=$(tmux show-option -gqv @claude-title-words 2>/dev/null)
case "$maxw" in ''|*[!0-9]*) maxw=2 ;; esac

# Session name tokens are redundant context (session "tmux" -> drop "tmux" from
# the title), so a "tmux-sidebar" chat in the tmux session becomes just "sidebar".
sess=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
sessre=$(printf '%s' "$sess" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' \
    | awk '{for(i=1;i<=NF;i++) printf (i>1?"|":"") $i}')

slug=$(printf '%s' "$title" | awk -v max="$maxw" -v sessre="$sessre" '
{
  c = 0; g = 0
  for (i = 1; i <= NF; i++) {
    w = tolower($i)
    gsub(/[^a-z0-9]/, "", w)
    if (w == "") continue
    # skip a leading action verb
    if (i == 1 && w ~ /^(build|add|fix|create|make|refactor|implement|update|convert|display|explain|customize|customise|audit|review|setup|design|improve|enhance|remove|delete|debug|investigate|write|integrate|enable|disable|migrate|rename|configure|wire|set|support|adjust|tweak|handle|allow)$/) continue
    # skip filler / stopwords anywhere
    if (w ~ /^(for|the|a|an|to|of|and|in|on|with|into|from|by|at|as|is|its|it|that|this|using|via|or)$/) continue
    content[++c] = w
    # "strong" words exclude generics and the session-name tokens
    if (w !~ /^(project|management|system|logic|support|feature|features|app|code|tool|tools|config|configuration|settings|setting|default|new|mode|stuff|thing|things|general|various|core|main|functionality)$/ \
        && (sessre == "" || w !~ ("^(" sessre ")$"))) strong[++g] = w
  }
  k = (g > 0) ? g : c
  limit = (k < max) ? k : max
  s = ""
  for (j = 1; j <= limit; j++) s = s (j > 1 ? "-" : "") ((g > 0) ? strong[j] : content[j])
  print s
}')

[ -n "$slug" ] || exit 0

# rename-window implicitly disables automatic-rename for this window, so the
# name sticks instead of being overwritten by the running command name.
tmux rename-window -t "$TMUX_PANE" "$slug" 2>/dev/null
exit 0
