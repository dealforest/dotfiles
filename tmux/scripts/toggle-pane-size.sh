#!/bin/bash
pane_height=$(tmux display -p '#{pane_height}')
window_height=$(tmux display -p '#{window_height}')
current_ratio=$((pane_height * 100 / window_height))

if [ $current_ratio -gt 65 ]; then
    tmux resize-pane -y 50%
else
    tmux resize-pane -y 80%
fi
