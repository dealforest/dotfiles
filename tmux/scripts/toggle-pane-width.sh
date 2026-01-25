#!/bin/bash
pane_width=$(tmux display -p '#{pane_width}')
window_width=$(tmux display -p '#{window_width}')
current_ratio=$((pane_width * 100 / window_width))

if [ $current_ratio -gt 65 ]; then
    tmux resize-pane -x 50%
else
    tmux resize-pane -x 80%
fi
