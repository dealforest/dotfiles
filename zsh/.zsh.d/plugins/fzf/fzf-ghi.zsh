function fzf-ghi() {
    hub issue show $(hub issue --sort updated | fzf --reverse | awk '{ print $1 }' | sed -e 's/#//')
}
zle -N fzf-ghi
