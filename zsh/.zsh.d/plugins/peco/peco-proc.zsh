function peco-proc () {
    ps ax -o pid,lstart,command | peco | awk '{print $1}' | xargs kill
    zle clear-screen
}
zle -N peco-proc
