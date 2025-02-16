function peco-bundle-cd () {
  cd $(bundle show $(bundle list | awk '{ print $2 }' | peco))
}
zle -N peco-bundle-cd
