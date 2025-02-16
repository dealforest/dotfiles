function fzf-select-history() {
    BUFFER=`history -n 1 | tac | awk '!a[$0]++' | fzf --reverse`
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
