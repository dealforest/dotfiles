function tmux-claude-layout -d "Create dev layout with tig and claude"
    set -l issue_url ""
    set -l claude_args_list

    for arg in $argv
        if string match -qr '^https?://.*/(issues|pull)/[0-9]+' $arg
            set issue_url $arg
        else
            set -a claude_args_list $arg
        end
    end

    if test -n "$issue_url"
        set -l issue_id (string match -r '/(issues|pull)/([0-9]+)' $issue_url)[3]
        if test -n "$issue_id"
            set -l branch_name "feature/$issue_id"
            set -l wt_path (gwq list --json | jq -r --arg b "$branch_name" '.[] | select(.branch == $b) | .path')
            if test -n "$wt_path"
                cd $wt_path
            else
                gwq add -b $branch_name
                set wt_path (gwq list --json | jq -r --arg b "$branch_name" '.[] | select(.branch == $b) | .path')
                if test -n "$wt_path"
                    cd $wt_path
                end
            end
        end
    end

    set -l name (basename (pwd))

    set -l claude_cmd "claude"
    if test (count $claude_args_list) -gt 0
        set claude_cmd "claude $claude_args_list"
    end
    if test -n "$issue_url"
        set claude_cmd "$claude_cmd $issue_url"
    end

    set -l viddy_cmd "viddy -- 'f=\$(ls -t .plans/*.md 2>/dev/null | head -1); echo \"\$f\"; CLICOLOR_FORCE=1 glow --style dark \"\$f\" 2>/dev/null || echo \"No plan files found\"'"

    if test -z "$TMUX"
        # tmux 外: 新規セッションを作成してアタッチ
        tmux new-session -d -s $name
        tmux attach-session -t $name \; \
            split-window -v -p 50 \; \
            split-window -h -t 0 \; \
            send-keys -t 0 'tig' C-m \; \
            send-keys -t 1 $viddy_cmd C-m \; \
            send-keys -t 2 $claude_cmd C-m \; \
            select-pane -t 2 \; \
            set-option -gF @ct_session "#{session_name}" \; \
            set-option -gF @ct_pane "#{pane_id}" \; \
            run-shell '$HOME/.config/tmux/scripts/choose-tree-filtered.sh'
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
