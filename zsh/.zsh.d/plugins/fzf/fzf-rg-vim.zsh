function fzf-rg-vim () {
  vim $(rg $@ | fzf --reverse | awk -F : '{print "-c " $2 " " $1}')
}
zle -N fzf-rg-vim
