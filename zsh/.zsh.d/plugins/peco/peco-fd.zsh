function peco-fd() {
  local target_dir=$(fd --type directory --no-ignore --hidden --exclude ".git" | peco)
  local current_dir=$(pwd)

  if [ -n "$target_dir" ]; then
    BUFFER="cd ${current_dir}/${target_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N peco-fd
