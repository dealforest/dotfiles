#!/bin/bash
# Claude Code notification script

MESSAGE="$1"
SOUND="${2:-default}"

# Get tmux window title if available
TMUX_TITLE=""
if [ -n "$TMUX" ]; then
    TMUX_TITLE=$(tmux display-message -p '#W' 2>/dev/null)
fi

# Build title
TITLE="Claude Code"
if [ -n "$TMUX_TITLE" ]; then
    TITLE="Claude Code - $TMUX_TITLE"
fi

terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound "$SOUND"
