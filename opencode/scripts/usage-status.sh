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

# Get OpenCode version
cc_version="v$(echo "$input" | jq -r '.version // "?"')"

# Check if current model is Kimi
model_id=$(echo "$input" | jq -r '.model.id // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
is_kimi=false
if [[ "$model_id" == *"kimi"* || "$model_name" == *"Kimi"* ]]; then
    is_kimi=true
fi

# === OpenCode Go usage (cached) ===
OC_CACHE="/tmp/opencode_stats_cache"
OC_TTL=300  # 5 minutes

oc_daily_cost=""
oc_weekly_cost=""
oc_monthly_cost=""
oc_cache_valid=false

if [[ -f "$OC_CACHE" ]]; then
    oc_cache_age=$(( $(date +%s) - $(stat -f%m "$OC_CACHE") ))
    if [[ $oc_cache_age -lt $OC_TTL ]]; then
        source "$OC_CACHE"
        oc_cache_valid=true
    fi
fi

if ! $oc_cache_valid; then
    # Get today's cost (used as approximation for 5h)
    oc_stats_day=$(opencode stats --days 1 2>/dev/null)
    if [[ -n "$oc_stats_day" ]]; then
        oc_daily_cost=$(echo "$oc_stats_day" | grep 'Total Cost' | grep -oE '[0-9]+\.[0-9]+' | head -1)
    fi

    # Get last 7 days cost
    oc_stats_week=$(opencode stats --days 7 2>/dev/null)
    if [[ -n "$oc_stats_week" ]]; then
        oc_weekly_cost=$(echo "$oc_stats_week" | grep 'Total Cost' | grep -oE '[0-9]+\.[0-9]+' | head -1)
    fi

    # Get month-to-date cost
    days_this_month=$(date +%d)
    oc_stats_month=$(opencode stats --days "$days_this_month" 2>/dev/null)
    if [[ -n "$oc_stats_month" ]]; then
        oc_monthly_cost=$(echo "$oc_stats_month" | grep 'Total Cost' | grep -oE '[0-9]+\.[0-9]+' | head -1)
    fi

    # Write cache
    printf 'oc_daily_cost="%s"\noc_weekly_cost="%s"\noc_monthly_cost="%s"\n' "$oc_daily_cost" "$oc_weekly_cost" "$oc_monthly_cost" > "$OC_CACHE"
fi

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

# === LINE 3: ccusage daily/monthly costs (cached) ===
CCUSAGE_CACHE="/tmp/ccusage_statusline_cache"
CCUSAGE_TTL=300  # 5 minutes

today=$(date +%Y%m%d)
month_start=$(date +%Y%m01)
month_label=$(date +%Y/%m)

daily_cost=""
monthly_cost=""

# Use cache if fresh enough
cache_valid=false
if [[ -f "$CCUSAGE_CACHE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f%m "$CCUSAGE_CACHE") ))
    if [[ $cache_age -lt $CCUSAGE_TTL ]]; then
        cache_valid=true
    fi
fi

if $cache_valid; then
    source "$CCUSAGE_CACHE"
else
    # Get daily cost
    daily_json=$(ccusage daily --json --since "$today" --offline 2>/dev/null)
    if [[ -n "$daily_json" ]]; then
        daily_usd=$(echo "$daily_json" | jq -r 'if type == "array" and length > 0 then .[0].totalCost // 0 elif type == "object" then .totalCost // 0 else 0 end' 2>/dev/null)
        if [[ -n "$daily_usd" && "$daily_usd" != "null" ]] && (( $(echo "$daily_usd > 0" | bc -l 2>/dev/null) )); then
            daily_cost=$(printf '%.2f' "$daily_usd" 2>/dev/null)
        fi
    fi

    # Get monthly cost
    monthly_json=$(ccusage monthly --json --since "$month_start" --offline 2>/dev/null)
    if [[ -n "$monthly_json" ]]; then
        monthly_usd=$(echo "$monthly_json" | jq -r 'if type == "array" and length > 0 then .[0].totalCost // 0 elif type == "object" then .totalCost // 0 else 0 end' 2>/dev/null)
        if [[ -n "$monthly_usd" && "$monthly_usd" != "null" ]] && (( $(echo "$monthly_usd > 0" | bc -l 2>/dev/null) )); then
            monthly_cost=$(printf '%.2f' "$monthly_usd" 2>/dev/null)
        fi
    fi

    # Write cache
    printf 'daily_cost="%s"\nmonthly_cost="%s"\n' "$daily_cost" "$monthly_cost" > "$CCUSAGE_CACHE"
fi

# === LINE 3: OpenCode Go usage limits (Kimi only) ===
if $is_kimi; then
    line3=""
    
    # Helper: build Go limit bar
    build_go_bar() {
        local cost=$1
        local limit=$2
        if [[ -z "$cost" ]]; then
            echo ""
            return
        fi
        # Convert $X.YY to cents
        if [[ "$cost" == *"."* ]]; then
            local int_part=${cost%.*}
            local frac_part=${cost#*.}
            while [[ ${#frac_part} -lt 2 ]]; do frac_part="${frac_part}0"; done
            local cents="${int_part}${frac_part}"
        else
            local cents="${cost}00"
        fi
        # Remove leading zeros
        cents=$(echo "$cents" | sed 's/^0*//')
        [[ -z "$cents" ]] && cents=0
        local pct=$((cents * 100 / (limit * 100)))
        [[ $pct -gt 100 ]] && pct=100
        # Color based on limit type
        local color="$C_BAR_5H"
        if [[ "$limit" == "30" ]]; then
            color="$C_BAR_7D"
        elif [[ "$limit" == "60" ]]; then
            color="$C_BAR_7D"
        fi
        [[ $pct -ge 70 ]] && color="$C_WARN"
        [[ $pct -ge 90 ]] && color="$C_DANGER"
        local bar=$(build_bar "$pct" "$color")
        echo "${bar} ${color}\$${cost}${C_GRAY}/${color}\$${limit}"
    }
    
    line3=""

    # 7d limit ($30)
    if [[ -n "$oc_weekly_cost" ]]; then
        line3+="💵 "
        week_display=$(build_go_bar "$oc_weekly_cost" 30)
        line3+="${C_GRAY}7d ${week_display}"
    fi

    # Monthly limit ($60)
    if [[ -n "$oc_monthly_cost" ]]; then
        if [[ -n "$line3" ]]; then
            line3+=" | "
        else
            line3+="💵 "
        fi
        month_display=$(build_go_bar "$oc_monthly_cost" 60)
        line3+="${C_GRAY}Mon ${month_display}"
    fi
    
    if [[ -n "$line3" ]]; then
        line3+="${C_RESET}"
        printf '%b\n' "$line3"
    fi
fi

# === LINE 4: ccusage costs (if available) ===
if [[ -n "$daily_cost" || -n "$monthly_cost" ]]; then
    line4=""
    if [[ -n "$daily_cost" ]]; then
        line4+="${C_DIM}CC Today \$${daily_cost}"
    fi
    if [[ -n "$monthly_cost" ]]; then
        [[ -n "$line4" ]] && line4+=" | "
        line4+="${C_DIM}CC ${month_label} \$${monthly_cost}"
    fi
    line4+="${C_RESET}"
    printf '%b\n' "$line4"
fi
