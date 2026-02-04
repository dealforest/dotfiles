function tmux-claude-layout -a claude_args -d "Create dev layout with tig and claude"
    set -l name (basename (pwd))
    set -l claude_cmd "claude $claude_args"

    if test -n "$TMUX"
        tmux new-window -n $name
    else
        tmux new-session -d -s $name
        tmux attach-session -t $name
    end

    tmux split-window -v -p 50
    tmux split-window -h -t 0
    tmux send-keys -t 0 'tig' C-m
    tmux send-keys -t 2 $claude_cmd C-m
    tmux select-pane -t 2
end
