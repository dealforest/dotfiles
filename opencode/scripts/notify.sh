#!/bin/bash
# OpenCode notification script
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
current_dir_suffix=$(basename "$PWD")
TITLE=""

if [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$TMUX_PANE_INDEX" ] && [ -n "$TMUX_TITLE" ]; then
    TITLE="[$TMUX_SESSION] - [$TMUX_TITLE]: $current_dir_suffix"
elif [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$TMUX_PANE_INDEX" ]; then
    TITLE="[$TMUX_SESSION] - [$TMUX_WINDOW]: $current_dir_suffix"
else
    terminal_name="${TERM_PROGRAM:-$TERM}"
    [ -z "$terminal_name" ] && terminal_name="Terminal"
    if [[ "$terminal_name" == xterm-* ]]; then
        terminal_name="${terminal_name#xterm-}"
    fi
    TITLE="[$terminal_name]: $current_dir_suffix"
fi

# Build -execute command: AppleScript to activate Ghostty window + switch tmux pane
if [ -n "$TMUX_SESSION" ] && [ -n "$TMUX_WINDOW" ] && [ -n "$TMUX_PANE_INDEX" ]; then
    TMP_SCRIPT=$(mktemp /tmp/notify-action.XXXXXX.sh)
    {
        echo "#!/bin/bash"
        echo "osascript -e 'tell application \"Ghostty\" to activate'"
        echo "tmux select-window -t '${TMUX_SESSION}:${TMUX_WINDOW}'"
        echo "tmux select-pane -t '${TMUX_SESSION}:${TMUX_WINDOW}.${TMUX_PANE_INDEX}'"
        echo "rm -f '$TMP_SCRIPT'"
    } > "$TMP_SCRIPT"
    chmod +x "$TMP_SCRIPT"
    (terminal-notifier \
        -title "$TITLE" \
        -message "$MESSAGE" \
        -sound "$SOUND" \
        -sender "com.mitchellh.ghostty" \
        -execute "$TMP_SCRIPT" >/dev/null 2>&1 &) &
else
    (terminal-notifier \
        -title "$TITLE" \
        -message "$MESSAGE" \
        -sound "$SOUND" \
        -sender "com.mitchellh.ghostty" \
        -activate "com.mitchellh.ghostty" >/dev/null 2>&1 &) &
fi
exit 0
