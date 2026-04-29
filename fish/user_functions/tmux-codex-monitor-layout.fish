function tmux-codex-monitor-layout -d "Create layout for monitoring Codex sessions"
    set -l name (basename (pwd))
    set -l choose_tree_cmd '$HOME/.config/tmux/scripts/choose-tree-filtered.sh'

    if test -z "$TMUX"
        tmux new-session -d -s $name
        tmux attach-session -t $name \; \
            split-window -v -p 30 \; \
            select-pane -t 0 \; \
            set-option -gF @ct_session "#{session_name}" \; \
            set-option -gF @ct_pane "#{pane_id}" \; \
            run-shell $choose_tree_cmd \; \
            select-pane -t 1
    else
        tmux split-window -v -p 30
        tmux select-pane -t 0
        tmux set-option -gF @ct_session "#{session_name}"
        tmux set-option -gF @ct_pane "#{pane_id}"
        tmux run-shell $choose_tree_cmd
        tmux select-pane -t 1
    end
end
