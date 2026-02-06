function tmux-claude-layout -a claude_args -d "Create dev layout with tig and claude"
    set -l name (basename (pwd))
    set -l claude_cmd "claude $claude_args"
    set -l viddy_cmd "viddy -- 'bat --style=plain --color=always --paging=never \"\$(ls -t .plans/*.md 2>/dev/null | head -1)\" 2>/dev/null || echo \"No plan files found\"'"

    if test -z "$TMUX"
        # tmux 外: 新規セッションを作成してアタッチ
        tmux new-session -d -s $name
        tmux attach-session -t $name \; \
            split-window -v -p 50 \; \
            split-window -h -t 0 \; \
            send-keys -t 0 'tig' C-m \; \
            send-keys -t 1 $viddy_cmd C-m \; \
            send-keys -t 2 $claude_cmd C-m \; \
            select-pane -t 2
    else
        # tmux 内: 現在のウィンドウで分割を実行
        tmux split-window -v -p 50
        tmux split-window -h -t 0
        tmux send-keys -t 0 'tig' C-m
        tmux send-keys -t 1 $viddy_cmd C-m
        tmux send-keys -t 2 $claude_cmd C-m
        tmux select-pane -t 2
    end
end
