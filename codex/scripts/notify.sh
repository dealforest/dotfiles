#!/bin/bash

set -euo pipefail

payload="$(cat)"

first_string() {
    printf '%s' "$payload" | jq -r "$1" 2>/dev/null
}

event="$(first_string 'first([
    .event,
    .type,
    .kind,
    .notification.event,
    .notification.type
] | map(select(type == "string" and length > 0))) // empty')"

message="$(first_string 'first([
    .message,
    .body,
    .text,
    .title,
    .notification.message,
    .notification.body,
    .notification.title
] | map(select(type == "string" and length > 0))) // empty')"

sound="default"

case "$event" in
    approval-requested|permission-requested|input-required)
        sound="Blow"
        ;;
    agent-turn-complete|task-complete|turn-complete|completed)
        sound="Pop"
        ;;
esac

if [[ -z "$message" ]]; then
    case "$event" in
        approval-requested|permission-requested|input-required)
            message="確認が必要です"
            ;;
        agent-turn-complete|task-complete|turn-complete|completed)
            message="レスポンスがあります"
            ;;
        *)
            message="Codex から通知があります"
            ;;
    esac
fi

tmux_session=""
tmux_window=""
tmux_pane_index=""
tmux_title=""

if [[ -n "${TMUX:-}" ]]; then
    tmux_session="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
    tmux_window="$(tmux display-message -p '#{window_index}' 2>/dev/null || true)"
    tmux_pane_index="$(tmux display-message -p '#{pane_index}' 2>/dev/null || true)"
    tmux_title="$(tmux display-message -p '#W' 2>/dev/null || true)"
fi

# Build title
current_dir_suffix=$(basename "$PWD")
title=""

if [[ -n "$tmux_session" && -n "$tmux_window" && -n "$tmux_pane_index" && -n "$tmux_title" ]]; then
    title="[$tmux_session] - [$tmux_title]: $current_dir_suffix"
elif [[ -n "$tmux_session" && -n "$tmux_window" && -n "$tmux_pane_index" ]]; then
    title="[$tmux_session] - [$tmux_window]: $current_dir_suffix"
else
    terminal_name="${TERM_PROGRAM:-$TERM}"
    [[ -z "$terminal_name" ]] && terminal_name="Terminal"
    if [[ "$terminal_name" == xterm-* ]]; then
        terminal_name="${terminal_name#xterm-}"
    fi
    title="[$terminal_name]: $current_dir_suffix"
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
execute_cmd=""

if [[ -n "$tmux_session" && -n "$tmux_window" && -n "$tmux_pane_index" && -n "$tmux_title" ]]; then
    execute_cmd="osascript '${script_dir}/activate-ghostty-window.scpt' '${tmux_title}' && tmux select-window -t '${tmux_session}:${tmux_window}' && tmux select-pane -t '${tmux_session}:${tmux_window}.${tmux_pane_index}'"
elif [[ -n "$tmux_session" && -n "$tmux_window" && -n "$tmux_pane_index" ]]; then
    execute_cmd="osascript -e 'tell application \"Ghostty\" to activate' && tmux select-window -t '${tmux_session}:${tmux_window}' && tmux select-pane -t '${tmux_session}:${tmux_window}.${tmux_pane_index}'"
fi

if [[ -n "$execute_cmd" ]]; then
    (terminal-notifier \
        -title "$title" \
        -message "$message" \
        -sound "$sound" \
        -sender "com.mitchellh.ghostty" \
        -execute "$execute_cmd" >/dev/null 2>&1 &) &
else
    (terminal-notifier \
        -title "$title" \
        -message "$message" \
        -sound "$sound" \
        -sender "com.mitchellh.ghostty" \
        -activate "com.mitchellh.ghostty" >/dev/null 2>&1 &) &
fi
