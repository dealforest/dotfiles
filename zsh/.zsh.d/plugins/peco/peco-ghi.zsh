function peco-ghi() {
    ghi show $(ghi list --sort updated | grep -v 'open issue' | grep -v 'Not Found' | peco | awk '{ print $1 }')
}
zle -N peco-ghi
