#!/bin/bash
# Claude Code statusLine command — mirrors the set_prompt PS1 from ~/.bashrc
# and surfaces all available Claude Code session status.

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

user=$(whoami)
host=$(hostname -s)
uid=$(id -u)

# ANSI color codes (real ESC bytes via $'...' syntax)
R=$'\e[0m'
bold=$'\e[1m'
dim=$'\e[2m'
bold_red=$'\e[1;31m'
bold_purple=$'\e[1;35m'
bold_cyan=$'\e[1;36m'
green=$'\e[0;32m'
bold_green=$'\e[1;32m'
bold_blue=$'\e[1;34m'
red=$'\e[0;31m'
yellow=$'\e[0;33m'
bold_yellow=$'\e[1;33m'
cyan=$'\e[0;36m'
white=$'\e[0;37m'
bold_white=$'\e[1;37m'
magenta=$'\e[0;35m'

SEP="${dim} | ${R}"

# ---------------------------------------------------------------------------
# 1. PS1-derived user@host:path
# ---------------------------------------------------------------------------

# User part: root=bold red, UID 1000=bold purple, others=plain
if [ "$uid" -eq 0 ]; then
    user_str="${bold_red}${user}${R}"
elif [ "$uid" -eq 1000 ]; then
    user_str="${bold_purple}${user}${R}"
else
    user_str="${user}"
fi

host_str="${bold_cyan}${host}${R}"

# Git-aware path (skipping optional locks to avoid blocking)
git_top=$(git --no-optional-locks -C "$cwd" rev-parse --show-toplevel 2>/dev/null)

if [ -n "$git_top" ]; then
    git_relative_top="${git_top/$HOME/\~}"
    reponame="${git_top##*/}"
    path_prefix="${git_relative_top%$reponame}"
    path_inside="${cwd#$git_top}"

    git_branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null || \
                 git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    if [ -n "$git_branch" ]; then
        if [[ "$git_branch" == "main" || "$git_branch" == "master" ]]; then
            branch_str="${bold_red}(${git_branch})${R}"
        else
            branch_str="${bold_green}(${git_branch})${R}"
        fi
    else
        branch_str=""
    fi

    path_str="${green}${path_prefix}${bold_green}${reponame}${R}${branch_str}${bold_blue}${path_inside}${R}"
else
    display_path="${cwd/$HOME/\~}"
    path_str="${bold_green}${display_path}${R}"
fi

shell_part="${user_str}@${host_str}:${path_str}"

# ---------------------------------------------------------------------------
# 2. Model
# ---------------------------------------------------------------------------
model=$(echo "$input" | jq -r '.model.display_name // empty')
model_part=""
[ -n "$model" ] && model_part="${bold_white}${model}${R}"

# ---------------------------------------------------------------------------
# 3. Context window usage
# ---------------------------------------------------------------------------
ctx_part=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
    used_int=$(printf '%.0f' "$used_pct")
    remaining_int=$((100 - used_int))
    if [ "$used_int" -ge 90 ]; then
        ctx_color="${bold_red}"
    elif [ "$used_int" -ge 75 ]; then
        ctx_color="${bold_yellow}"
    else
        ctx_color="${cyan}"
    fi
    ctx_part="${ctx_color}ctx:${remaining_int}%${R}"
fi

# ---------------------------------------------------------------------------
# 4. Effort level (when present)
# ---------------------------------------------------------------------------
effort_part=""
effort=$(echo "$input" | jq -r '.effort.level // empty')
if [ -n "$effort" ]; then
    effort_part="${magenta}effort:${effort}${R}"
fi

# ---------------------------------------------------------------------------
# 5. Thinking (when enabled)
# ---------------------------------------------------------------------------
thinking_part=""
thinking=$(echo "$input" | jq -r '.thinking.enabled // false')
if [ "$thinking" = "true" ]; then
    thinking_part="${magenta}thinking${R}"
fi

# ---------------------------------------------------------------------------
# 6. Vim mode (when active)
# ---------------------------------------------------------------------------
vim_part=""
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
if [ -n "$vim_mode" ]; then
    case "$vim_mode" in
        INSERT)      vim_color="${bold_green}" ;;
        NORMAL)      vim_color="${bold_cyan}" ;;
        VISUAL*)     vim_color="${bold_yellow}" ;;
        *)           vim_color="${bold_white}" ;;
    esac
    vim_part="${vim_color}[${vim_mode}]${R}"
fi

# ---------------------------------------------------------------------------
# 7. Rate limits (Claude.ai subscribers only)
# ---------------------------------------------------------------------------
rate_part=""
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rate_items=""
if [ -n "$five_pct" ]; then
    five_int=$(printf '%.0f' "$five_pct")
    [ "$five_int" -ge 80 ] && rc="${bold_red}" || rc="${yellow}"
    rate_items="${rc}5h:${five_int}%${R}"
fi
if [ -n "$week_pct" ]; then
    week_int=$(printf '%.0f' "$week_pct")
    [ "$week_int" -ge 80 ] && rc="${bold_red}" || rc="${yellow}"
    [ -n "$rate_items" ] && rate_items="${rate_items} "
    rate_items="${rate_items}${rc}7d:${week_int}%${R}"
fi
[ -n "$rate_items" ] && rate_part="${rate_items}"

# ---------------------------------------------------------------------------
# 8. Open PR / MR (when on a branch with one)
# ---------------------------------------------------------------------------
pr_part=""
pr_num=$(echo "$input" | jq -r '.pr.number // empty')
if [ -n "$pr_num" ]; then
    pr_kind=$(echo "$input" | jq -r '.pr.kind // empty')
    pr_state=$(echo "$input" | jq -r '.pr.review_state // "open"')
    [ "$pr_kind" = "mr" ] && pr_label="MR !${pr_num}" || pr_label="PR #${pr_num}"
    case "$pr_state" in
        approved)          pr_color="${bold_green}" ;;
        changes_requested) pr_color="${bold_red}" ;;
        draft)             pr_color="${dim}" ;;
        *)                 pr_color="${bold_yellow}" ;;
    esac
    pr_part="${pr_color}${pr_label}(${pr_state})${R}"
fi

# ---------------------------------------------------------------------------
# 9. Agent name (when launched with --agent)
# ---------------------------------------------------------------------------
agent_part=""
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
[ -n "$agent_name" ] && agent_part="${bold_yellow}agent:${agent_name}${R}"

# ---------------------------------------------------------------------------
# 10. Session name (when /rename has been used)
# ---------------------------------------------------------------------------
session_part=""
session_name=$(echo "$input" | jq -r '.session_name // empty')
[ -n "$session_name" ] && session_part="${dim}[${session_name}]${R}"

# ---------------------------------------------------------------------------
# Assemble — join non-empty parts with separator
# ---------------------------------------------------------------------------
parts=("$shell_part")
for part in "$vim_part" "$model_part" "$ctx_part" "$effort_part" "$thinking_part" \
            "$rate_part" "$pr_part" "$agent_part" "$session_part"; do
    [ -n "$part" ] && parts+=("$part")
done

line=""
for part in "${parts[@]}"; do
    [ -z "$line" ] && line="$part" || line="${line}${SEP}${part}"
done

printf '%s\n' "$line"
