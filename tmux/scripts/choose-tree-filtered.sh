#!/bin/bash
PANE=$(tmux show-option -gv @ct_pane)
tmux choose-tree -t "$PANE" -NNsf '#{==:#{session_name},#{@ct_session}}' \
  "select-window -t '%%' ; run-shell '$HOME/.config/tmux/scripts/choose-tree-filtered.sh'"
tmux send-keys -t "$PANE" Right
