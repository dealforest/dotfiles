function fzf_tmux_attach
    set -l session (tmux ls -F '#{session_name}' 2>/dev/null | fzf --height 40% --reverse)
    if test -n "$session"
        tmux attach -t "$session"
    end
end
