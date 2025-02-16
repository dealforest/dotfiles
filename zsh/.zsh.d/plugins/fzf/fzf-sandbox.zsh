function fzf-sandbox() {
    local selected_dir=$(fd --type directory --maxdepth 2 . ~/sandbox | fzf --reverse)
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N fzf-sandbox
