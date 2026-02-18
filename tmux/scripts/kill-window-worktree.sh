#!/bin/bash
export PATH="/opt/homebrew/bin:$PATH"

SCRIPT="$HOME/.config/tmux/scripts/kill-window-worktree.sh"

if [ "$1" = "--exec" ]; then
  PANE_PATH=$(tmux display-message -p '#{pane_current_path}')
  GWQ_JSON=$(gwq list --json)
  BRANCH=$(echo "$GWQ_JSON" | jq -r --arg p "$PANE_PATH" \
    '[.[] | select(.path as $path | $p | startswith($path))] | sort_by(.path | length) | last | .branch')
  MAIN_REPO=$(echo "$GWQ_JSON" | jq -r '.[] | select(.path | contains(".worktree") | not) | .path')

  if [ -n "$BRANCH" ] && [ "$BRANCH" != "null" ]; then
    cd "$MAIN_REPO"
    gwq remove -f "$BRANCH"
  fi
  tmux kill-window
  exit 0
fi

# 検出モード
PANE_PATH=$(tmux display-message -p '#{pane_current_path}')

if [[ "$PANE_PATH" == *".worktree"* ]]; then
  BRANCH=$(gwq list --json | jq -r --arg p "$PANE_PATH" \
    '[.[] | select(.path as $path | $p | startswith($path))] | sort_by(.path | length) | last | .branch')

  if [ -n "$BRANCH" ] && [ "$BRANCH" != "null" ]; then
    tmux confirm-before -p "kill worktree ($BRANCH) and window? (y/n)" \
      "run-shell '$SCRIPT --exec'"
  else
    tmux confirm-before -p "kill window? (y/n)" "kill-window"
  fi
else
  tmux confirm-before -p "kill window? (y/n)" "kill-window"
fi
