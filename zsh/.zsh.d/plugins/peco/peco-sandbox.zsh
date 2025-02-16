function peco-sandbox() {
    local selected_dir=$(tree ~/sandbox -L 2 -dfi --noreport | peco)
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-sandbox
