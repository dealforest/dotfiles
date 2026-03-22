#!/bin/bash
# Claude Code notification script
# Usage: notify.sh <message> [sound]
# Sends a macOS notification via terminal-notifier.
# Clicking the notification brings Ghostty to front and switches to the tmux pane.

MESSAGE="$1"
SOUND="${2:-default}"

# Capture tmux session, window, and pane info
TMUX_SESSION=""
TMUX_WINDOW=""
TMUX_PANE_INDEX=""
TMUX_TITLE=""
if [ -n "$TMUX" ]; then
    TMUX_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    TMUX_WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null)
    TMUX_PANE_INDEX=$(tmux display-message -p '#{pane_index}' 2>/dev/null)
    TMUX_TITLE=$(tmux display-message -p '#W' 2>/dev/null)
fi

# Build title
TITLE="Claude Code"
if [ -n "$TMUX_TITLE" ]; then
    TITLE="Claude Code - $TMUX_TITLE"
fi

# Build -execute command: AppleScript to activate Ghostty window + switch tmux pane
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXECUTE_CMD=""
if [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$TMUX_PANE_INDEX" ] && [ -n "$TMUX_TITLE" ]; then
    EXECUTE_CMD="osascript '${SCRIPT_DIR}/activate-ghostty-window.scpt' '${TMUX_TITLE}' && tmux select-window -t '${TMUX_SESSION}:${TMUX_WINDOW}' && tmux select-pane -t '${TMUX_SESSION}:${TMUX_WINDOW}.${TMUX_PANE_INDEX}'"
elif [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$TMUX_PANE_INDEX" ]; then
    EXECUTE_CMD="osascript -e 'tell application \"Ghostty\" to activate' && tmux select-window -t '${TMUX_SESSION}:${TMUX_WINDOW}' && tmux select-pane -t '${TMUX_SESSION}:${TMUX_WINDOW}.${TMUX_PANE_INDEX}'"
fi

if [ -n "$EXECUTE_CMD" ]; then
    terminal-notifier \
        -title "$TITLE" \
        -message "$MESSAGE" \
        -sound "$SOUND" \
        -sender "com.mitchellh.ghostty" \
        -execute "$EXECUTE_CMD"
else
    terminal-notifier \
        -title "$TITLE" \
        -message "$MESSAGE" \
        -sound "$SOUND" \
        -sender "com.mitchellh.ghostty" \
        -activate "com.mitchellh.ghostty"
fi
