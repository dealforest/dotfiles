function fzf-bundle-cd () {
  cd $(bundle show $(bundle list | awk '{ print $2 }' | fzf --reverse))
}
zle -N fzf-bundle-cd
