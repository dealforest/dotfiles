alias vim nvim
abbr -a v nvim
abbr -a nv nvim

abbr -a bash 'bash --norc'
abbr -a src source
abbr -a sc "source $FISH_CONFIG"
abbr -a vd "fd . ~/.ghq/github.com/dealforest/dotfiles/ | fzf | xargs nvim"

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
abbr -a o 'open .'

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

# claude code
abbr -a -- cc 'claude code'
abbr -a -- ccd 'claude code --sandbox --dangerously-skip-permissions'

# tmux
abbr -a tm 'tmux new -s'
abbr -a tma 'tmux attach'
abbr -a tml 'tmux ls'
abbr -a tmk 'tmux kill-server'

function _tmc
    set -l session '(basename (pwd))'
    set -l sep '\\;'
    echo "tmux new-session -s $session" \
        "$sep split-window -v -p 50" \
        "$sep split-window -h -t 0" \
        "$sep send-keys -t 0 'tig' C-m" \
        "$sep send-keys -t 2 'claude' C-m" \
        "$sep select-pane -t 2"
end
abbr -a tmc -f _tmc

function _tmcd
    set -l session '(basename (pwd))'
    set -l sep '\\;'
    echo "tmux new-session -s $session" \
        "$sep split-window -v -p 50" \
        "$sep split-window -h -t 0" \
        "$sep send-keys -t 0 'tig' C-m" \
        "$sep send-keys -t 2 'claude --sandbox --dangerously-skip-permissions' C-m" \
        "$sep select-pane -t 2"
end
abbr -a tmcd -f _tmcd

# phantom (Claude Code 並列実行向け)
abbr -a ph phantom
abbr -a phc 'phantom create'
abbr -a phl 'phantom list'
abbr -a phd 'phantom delete --fzf'
abbr -a phs 'phantom shell --fzf'
abbr -a phw 'phantom where --fzf'

# phantom + Claude Code
abbr -a phcc 'phantom exec --fzf claude'
abbr -a phccd 'phantom exec --fzf claude --sandbox --dangerously-skip-permissions'
abbr -a phtc 'phantom shell --fzf --tmux --exec claude'

# GitHub PR + Claude Code
abbr -a phgh 'phantom github checkout'
