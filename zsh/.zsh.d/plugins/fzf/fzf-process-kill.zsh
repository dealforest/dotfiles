function fzf-process-kill () {
    ps ax -o pid,lstart,command | fzf --reverse | awk '{print $1}' | xargs kill
    zle clear-screen
}
zle -N fzf-process-kill
