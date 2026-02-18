function tmux-claude-monitor-layout -d "Create layout for monitoring claude sessions"
    set -l name (basename (pwd))
    set -l choose_tree_cmd '$HOME/.config/tmux/scripts/choose-tree-filtered.sh'

    if test -z "$TMUX"
        # tmux 外: 新規セッションを作成してアタッチ
        tmux new-session -d -s $name
        tmux attach-session -t $name \; \
            split-window -v -p 30 \; \
            select-pane -t 0 \; \
            set-option -gF @ct_session "#{session_name}" \; \
            set-option -gF @ct_pane "#{pane_id}" \; \
            run-shell $choose_tree_cmd \; \
            select-pane -t 1
    else
        # tmux 内: 現在のウィンドウで分割を実行
        tmux split-window -v -p 30
        tmux select-pane -t 0
        tmux set-option -gF @ct_session "#{session_name}"
        tmux set-option -gF @ct_pane "#{pane_id}"
        tmux run-shell $choose_tree_cmd
        tmux select-pane -t 1
    end
end
