alias vim nvim
abbr -a v nvim
abbr -a nv nvim

abbr -a bash 'bash --norc'
abbr -a src source
abbr -a sc "source $FISH_CONFIG"

alias ls eza
abbr -a -- ls 'eza --icons auto'
abbr -a -- la 'eza --icons --git --time-style relative -al'
abbr -a -- ll 'eza --icons --git --time-style relative -l'

abbr -a -- find fd
abbr -a -- less bat
abbr -a -- cat gat

abbr -a cdr 'cd (git root)'
abbr -a cdd __fzf_cd

abbr -a lzg lazygit
abbr -a lzd lazydocker
abbr -a py python
abbr -a y yazi
abbr -a yz yazi

abbr -a rr 'rm -r'
abbr -a rf 'rm -rf'
abbr -a mkd 'mkdir -p'
abbr -a mkdir 'mkdir -p'
abbr -a o open

abbr -a br brew
abbr -a bri 'brew install'
abbr -a bunb 'bun --bun'
abbr -a bunbx 'bunx --bun'
abbr -a vc 'code (pwd)'
abbr -a jn 'jupyter notebook'
abbr -a jl 'jupyter lab'

# aqua
abbr -a -- ag 'aqua g -i'
abbr -a -- ai 'aqua i -l'

# docker
abbr -a do docker container
abbr -a dop "docker container ps"
abbr -a dob "docker container build"
abbr -a dor "docker container run --rm"
abbr -a dox "docker container exec -it"

# docker compose
abbr -a dc docker compose
abbr -a dcu "docker compose up"
abbr -a dcub "docker compose up --build"
abbr -a dcd "docker compose down"
abbr -a dcr "docker compose restart"

# deno
abbr -a dr "deno run -A --unstable"
abbr -a deno-cache-clear "rm -rf (deno info | string match --entire --regex 'DENO_DIR*' | string split ' ')[-1]"
abbr -a dt "deno task"

abbr -a cpf "pbcopy < "
abbr -a paf "pbpaste > "

# git configs
type -q gti && alias git gti
abbr -a g git

# gh
abbr -a ghp 'gh poi'
abbr -a gh-fork-sync "gh repo list --limit 200 --fork --json nameWithOwner --jq '.[].nameWithOwner' | xargs -n1 gh repo sync"

# ghq
abbr -a gg 'ghq get'

# github copilot
abbr -a --set-cursor q gh copilot suggest -t shell \"%\"
abbr -a --set-cursor qgit gh copilot suggest -t git \"%\"
abbr -a --set-cursor qgh gh copilot suggest -t gh \"%\"

# misc
abbr -a n -f _na
abbr --position anywhere deal dealforest

