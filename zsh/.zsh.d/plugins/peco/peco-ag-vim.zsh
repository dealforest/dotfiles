function peco-ag-vim () {
  vim $(ag $@ | peco | awk -F : '{print "-c " $2 " " $1}')
}
zle -N peco-ag-vim
