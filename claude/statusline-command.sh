#!/usr/bin/env bash
# Claude Code status line — mirrors oh-my-posh config

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
sess=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Colors (ANSI — terminal will dim them)
magenta='\033[35m'
blue='\033[34m'
cyan='\033[36m'
green='\033[32m'
red='\033[31m'
yellow='\033[33m'
reset='\033[0m'
bold='\033[1m'

# Path segment
path_part="${cwd:-$(pwd)}"

# Git segment
git_info=""
if git_branch=$(git -C "${path_part}" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  git_color="$cyan"
  # Check working tree status (skip optional locks)
  if git -C "${path_part}" diff --quiet 2>/dev/null && git -C "${path_part}" diff --cached --quiet 2>/dev/null; then
    # Check ahead/behind
    ahead=$(git -C "${path_part}" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "${path_part}" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
      git_color="$cyan"
    elif [ "$ahead" -gt 0 ]; then
      git_color="$blue"
    elif [ "$behind" -gt 0 ]; then
      git_color="$cyan"
    fi
  else
    git_color="$red"
  fi
  last_commit=$(git -C "${path_part}" log --pretty=format:%cr -1 2>/dev/null || date +%H:%M:%S)
  git_info=" $(printf "${git_color}(${git_branch})${reset}")"
  time_info="$last_commit"
else
  time_info=$(date +%H:%M:%S)
fi

# Model + context
model_part=""
if [ -n "$model" ]; then
  model_part=" | $model"
  [ -n "$effort" ] && model_part+=" ${effort}"
fi

# Render a 10-cell meter for a 0-100 percent, colored by pressure
make_bar() {
  local p=${1%.*} width=10 i filled empty
  [ -z "$p" ] && p=0
  filled=$(( (p * width + 50) / 100 ))    # round to nearest cell
  [ "$filled" -gt "$width" ] && filled=$width
  [ "$filled" -lt 0 ] && filled=0
  empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty;  i++)); do bar+="░"; done
  local c="$green"
  [ "$p" -ge 60 ] && c="$yellow"
  [ "$p" -ge 85 ] && c="$red"
  printf "${c}[${bar}]${reset}"
}

# Usage bar — current 5-hour session quota (matches /usage "Current session")
usage_part=""
if [ -n "$sess" ]; then
  usage_part=" | $(printf "%b sess %s%%" "$(make_bar "$sess")" "$sess")"
fi

# Context window fill — turns red near the auto-compact threshold
ctx_compact_at=80
ctx_part=""
if [ -n "$used" ]; then
  up=${used%.*}; [ -z "$up" ] && up=0
  if [ "$up" -ge "$ctx_compact_at" ]; then
    ctx_part=" | $(printf "${red}ctx ${used}%%${reset}")"
  else
    ctx_part=" | ctx ${used}%"
  fi
fi

out="${bold}${magenta}${path_part}${reset}${git_info} ${yellow}${time_info}${reset}${model_part}${usage_part}${ctx_part}"
printf '%b' "$out"
