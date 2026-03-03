#!/bin/bash
# Claude Code status line
# Reads JSON from stdin, outputs a styled single line
# Order: repo · %_context · model · branch · time

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name // .model.id')
context_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Simplify directory path
display_dir="${cwd/#$HOME/~}"

# Git branch
branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    [ -z "$branch" ] && branch="detached"
    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
        branch="${branch}*"
    fi
fi

# Context color: green >50%, yellow 20-50%, red <20%
ctx=""
if [ -n "$context_remaining" ]; then
    ctx_int=${context_remaining%.*}
    if [ "$ctx_int" -ge 50 ]; then
        ctx="\033[32m${context_remaining}%\033[0m"
    elif [ "$ctx_int" -ge 20 ]; then
        ctx="\033[33m${context_remaining}%\033[0m"
    else
        ctx="\033[31m${context_remaining}%\033[0m"
    fi
fi

sep="\033[2m · \033[0m"
time_now=$(date +%H:%M:%S)

# Build: repo · %_context · model · branch · [vim_mode] · time
out="\033[36m${display_dir}\033[0m"
[ -n "$ctx" ] && out="${out}${sep}${ctx}"
out="${out}${sep}\033[34m${model}\033[0m"
[ -n "$branch" ] && out="${out}${sep}\033[35m${branch}\033[0m"
[ -n "$vim_mode" ] && out="${out}${sep}\033[33m${vim_mode}\033[0m"
out="${out}${sep}\033[2m${time_now}\033[0m"

echo -e "$out"
