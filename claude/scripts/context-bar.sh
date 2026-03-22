#!/bin/bash

# Colors
C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'
C_DIM='\033[38;5;240m'
C_BAR_EMPTY='\033[38;5;238m'
C_MODEL='\033[38;5;175m'       # pink/rose for model name
C_BRANCH='\033[38;5;143m'      # olive/yellow for branch
C_ADD='\033[38;5;108m'         # green for additions
C_DEL='\033[38;5;131m'         # red for deletions
C_COST='\033[38;5;179m'        # gold for cost
C_BAR_CTX='\033[38;5;143m'     # olive for context bar
C_BAR_5H='\033[38;5;143m'      # olive for 5h bar
C_BAR_7D='\033[38;5;179m'      # gold for 7d bar
C_WARN='\033[38;5;136m'
C_DANGER='\033[38;5;131m'

input=$(cat)

# Extract fields
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Shorten path: replace $HOME with ~
if [[ -n "$cwd" ]]; then
    display_path="${cwd/#$HOME/~}"
else
    display_path="?"
fi

# Worktree info
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# Git info
branch=""
diff_stat=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
    if [[ -n "$worktree_branch" ]]; then
        branch="$worktree_branch"
    else
        branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    fi
    if [[ -n "$branch" ]]; then
        # Get diff stats (additions/deletions) against HEAD
        stats=$(git -C "$cwd" --no-optional-locks diff --shortstat 2>/dev/null)
        staged_stats=$(git -C "$cwd" --no-optional-locks diff --cached --shortstat 2>/dev/null)

        additions=0
        deletions=0
        if [[ -n "$stats" ]]; then
            a=$(echo "$stats" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
            d=$(echo "$stats" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
            [[ -n "$a" ]] && additions=$((additions + a))
            [[ -n "$d" ]] && deletions=$((deletions + d))
        fi
        if [[ -n "$staged_stats" ]]; then
            a=$(echo "$staged_stats" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
            d=$(echo "$staged_stats" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
            [[ -n "$a" ]] && additions=$((additions + a))
            [[ -n "$d" ]] && deletions=$((deletions + d))
        fi

        if [[ $additions -gt 0 || $deletions -gt 0 ]]; then
            diff_stat=" ${C_ADD}+${additions}${C_GRAY}/${C_DEL}-${deletions}"
        fi
    fi
fi

# Context window
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
max_context=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
max_k=$((max_context / 1000))

# --- Bar builder ---
build_bar() {
    local pct=$1
    local bar_color=$2
    local bar_width=10
    local bar=""

    for ((i=0; i<bar_width; i++)); do
        bar_start=$((i * 10))
        progress=$((pct - bar_start))
        if [[ $progress -ge 8 ]]; then
            bar+="${bar_color}█${C_RESET}"
        elif [[ $progress -ge 3 ]]; then
            bar+="${bar_color}▄${C_RESET}"
        else
            bar+="${C_BAR_EMPTY}░${C_RESET}"
        fi
    done
    echo "$bar"
}

# Calculate context usage
baseline=20000
pct=0
pct_prefix=""
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    context_length=$(jq -s '
        map(select(.message.usage and .isSidechain != true and .isApiErrorMessage != true)) |
        last |
        if . then
            (.message.usage.input_tokens // 0) +
            (.message.usage.cache_read_input_tokens // 0) +
            (.message.usage.cache_creation_input_tokens // 0)
        else 0 end
    ' < "$transcript_path")

    if [[ "$context_length" -gt 0 ]]; then
        pct=$((context_length * 100 / max_context))
    else
        pct=$((baseline * 100 / max_context))
        pct_prefix="~"
    fi
else
    pct=$((baseline * 100 / max_context))
    pct_prefix="~"
fi
[[ $pct -gt 100 ]] && pct=100

# Context bar color based on usage
ctx_color="$C_BAR_CTX"
[[ $pct -ge 70 ]] && ctx_color="$C_WARN"
[[ $pct -ge 90 ]] && ctx_color="$C_DANGER"

ctx_bar=$(build_bar "$pct" "$ctx_color")

# Rate limits
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_remaining=$(echo "$input" | jq -r '.rate_limits.five_hour.remaining_seconds // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Format remaining time
format_time() {
    local secs=$1
    if [[ -z "$secs" || "$secs" == "null" ]]; then
        echo ""
        return
    fi
    local h=$((secs / 3600))
    local m=$(( (secs % 3600) / 60 ))
    if [[ $h -gt 0 ]]; then
        echo "${h}h${m}m"
    else
        echo "${m}m"
    fi
}

# Get Claude Code version
cc_version="v$(echo "$input" | jq -r '.version // "?"')"

# === LINE 1: version model | ♪ branch +X/-Y | path ===
line1="🤖 ${C_MODEL}${cc_version} - ${model}${C_GRAY} | "

if [[ -n "$worktree_name" ]]; then
    line1+="${C_BRANCH}wt:${worktree_name}${C_GRAY} "
fi

if [[ -n "$branch" ]]; then
    line1+="🔀 ${C_BRANCH}${branch}${diff_stat}${C_GRAY}"
    line1+=" | "
fi

line1+="📁 ${C_GRAY}${display_path}${C_RESET}"

printf '%b\n' "$line1"

# === LINE 2: [bar] pct%/maxk 5h [bar] pct%(time) 7d [bar] pct% ===
line2=""

# Context
line2+="📊 ${ctx_bar} ${ctx_color}${pct_prefix}${pct}%${C_GRAY}/${max_k}k"

# 5h rate limit
if [[ -n "$five_pct" ]]; then
    five_int=$(printf '%.0f' "$five_pct")
    five_bar=$(build_bar "$five_int" "$C_BAR_5H")
    time_str=$(format_time "$five_remaining")
    line2+=" ${C_GRAY}5h ${five_bar} ${C_BAR_5H}${five_int}%"
    if [[ -n "$time_str" ]]; then
        line2+="${C_DIM}(${time_str})"
    fi
fi

# 7d rate limit
if [[ -n "$week_pct" ]]; then
    week_int=$(printf '%.0f' "$week_pct")
    week_bar=$(build_bar "$week_int" "$C_BAR_7D")
    line2+=" ${C_GRAY}7d ${week_bar} ${C_BAR_7D}${week_int}%"
fi

line2+="${C_RESET}"

printf '%b\n' "$line2"

# === LINE 3: ccusage daily/monthly costs ===
today=$(date +%Y%m%d)
month_start=$(date +%Y%m01)
month_label=$(date +%Y/%m)

daily_cost=""
monthly_cost=""

# Get daily cost
daily_json=$(npx --yes ccusage daily --json --since "$today" --offline 2>/dev/null)
if [[ -n "$daily_json" ]]; then
    daily_usd=$(echo "$daily_json" | jq -r '.daily[0].totalCost // 0')
    if [[ -n "$daily_usd" ]] && (( $(echo "$daily_usd > 0" | bc -l 2>/dev/null) )); then
        daily_fmt=$(printf '%.2f' "$daily_usd" 2>/dev/null)
        daily_cost="\$${daily_fmt}"
    fi
fi

# Get monthly cost
monthly_json=$(npx --yes ccusage monthly --json --since "$month_start" --offline 2>/dev/null)
if [[ -n "$monthly_json" ]]; then
    monthly_usd=$(echo "$monthly_json" | jq -r '.monthly[0].totalCost // 0')
    if [[ -n "$monthly_usd" ]] && (( $(echo "$monthly_usd > 0" | bc -l 2>/dev/null) )); then
        monthly_fmt=$(printf '%.2f' "$monthly_usd" 2>/dev/null)
        monthly_cost="\$${monthly_fmt}"
    fi
fi

if [[ -n "$daily_cost" || -n "$monthly_cost" ]]; then
    line3=""
    if [[ -n "$daily_cost" ]]; then
        line3+="💰 ${C_GRAY}Today ${daily_cost}"
    fi
    if [[ -n "$monthly_cost" ]]; then
        [[ -n "$line3" ]] && line3+=" | "
        line3+="${C_GRAY}${month_label} ${monthly_cost}"
    fi
    line3+="${C_RESET}"
    printf '%b\n' "$line3"
fi
