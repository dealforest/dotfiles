setopt no_global_rcs

# -------------------------------------------------------------------------
# init path for OS X
# http://karur4n.hatenablog.com/entry/2016/01/18/100000
# -------------------------------------------------------------------------
if [ -x /usr/libexec/path_helper ]; then
  eval `/usr/libexec/path_helper -s`
fi

# -------------------------------------------------------------------------
# init enviroemtns
# -------------------------------------------------------------------------
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="$HOME/bin:$PATH"
export LANG='ja_JP.UTF-8'
export EDITOR=vim
export GIT_EDITOR="vim -u NONE"
export GREP_OPTIONS="--color=auto"
export PAGER=less
export LESS='-R'
export MYSQL_PS1='\\u@\\h [\\d] > '

if [ -f "~/.ssh/config" ]; then
    _cache_hosts=(`perl -ne  'if (/^Host\s([a-zA-Z0-9.-]+)/) { print "$1\n";}' ~/.ssh/config`)
fi

# -------------------------------------------------------------------------
# package enviroments
# -------------------------------------------------------------------------

function export_path_if_exists { [[ -d "$1" ]] && export PATH="$1:$PATH" }

export_path_if_exists "$GOPATH/bin"
export_path_if_exists "$HOME/.rbenv/shims" && eval "$(rbenv init --no-rehash - zsh)"
export_path_if_exists "$HOME/.nodenv/shims" && eval "$(nodenv init --no-rehash -)"
export_path_if_exists "$HOME/.pyenv/bin" && eval "$(pyenv init --no-rehash -)"
export_path_if_exists "$HOME/.plenv/bin" && eval "$(plenv init -)"
export_path_if_exists "$HOME/.poetry/bin" && source $HOME/.poetry/env
# export_path_if_exists "$HOME/miniforge3/bin" && eval "conda activate python3.8"
export_path_if_exists /opt/homebrew/share/git-core/contrib/workdir
export_path_if_exists /opt/homebrew/share/git-core/contrib/diff-highlight
export_path_if_exists /opt/homebrew/share/npm/bin && {
  export NODE_PATH="/opt/homebrew/share/npm/lib/node_modules"
}

if [ -f "/opt/homebrew/bin/brew" ]; then
    eval $(/opt/homebrew/bin/brew shellenv)
fi

if type brew > /dev/null; then
    eval $(brew shellenv)

    BREW_PREFIX=`brew --prefix`
    fpath=($BREW_PREFIX/share/zsh/functions(N) $BREW_PREFIX/share/zsh/site-functions(N) $fpath)

    if [ -d "$(brew --prefix coreutils 2>/dev/null)/libexec/gnubin" ]; then
        export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
    fi
fi

if type hub > /dev/null; then
  eval "$(hub alias -s zsh)"
fi

if type hub > /dev/null; then
  export_path_if_exists "$HOME/.rbenv/shims" && eval "$(rbenv init --no-rehash - zsh)"
fi

if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export PATH="$HOME/Library/Android/sdk/ndk-bundle:$PATH"
    export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
fi

if [ `uname` = 'Darwin' ]; then
    export SETUP_SH_VMARGS=-Dfile.encoding=UTF8
    if type rbenv > /dev/null; then
      eval "$(rbenv init --no-rehash - zsh)"
    fi
    if type nodenv > /dev/null; then
      eval "$(nodenv init --no-rehash -)"
    fi
fi

# -------------------------------------------------------------------------
# settings alias
# -------------------------------------------------------------------------
alias ...='cd ../../' ....='cd ../../../'
alias l='gls --color=auto' ls='gls --color=auto' ll='gls -l --color=auto' la='gls -la --color=auto' lt='gls -lt'
alias vi=vim v=vim
if [ -f "$(which nvim)" ]; then
  alias vim=nvim vi=nvim v=nvim
fi
alias g=git gti=git
alias phpinfo='php -r "phpinfo\(\);"'
alias static_httpd="plackup -MPlack::App::Directory -e 'Plack::App::Directory->new->to_app'"
alias rspec_pry="ruby -rpry -rrspec/autorun -e'describe do it do binding.pry end end'"

alias -g B='`git branch | peco | sed -e "s/^\*[ ]*//g"`'
alias -g R='`git remote | peco | sed -e "s/^\*[ ]*//g"`'
alias -g RH='`curl -sL https://api.github.com/users/dealforest/repos | jq -r ".[].full_name" | peco | sed -e "s/^\*[ ]*//g"`'
alias -g V='| vim -R -'
alias -g L='| less -R'
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g W='| wc'
alias -g S='| sed'
alias -g A='| awk'
alias -g X='| xargs'
alias -g F='| fzf --reverse'
alias -g J='| jq "."'
alias -g LV='| lv -c'
alias -g LE='|& less'
alias -g HE='|& head'
alias -g TE='|& tail'
alias -g GE='|& grep'
alias -g WE='|& wc'
alias -g SE='|& sed'
alias -g AE='|& awk'
alias -g XE='|& xargs'
alias -g PE='|& peco'
alias -g JE='|& jq "."'
alias -g WIN='| iconv -f UTF8-MAC -t UTF-8'
alias -g FIN='; growlnotify -t finished -m "end commandline"'

if which pbcopy >/dev/null 2>&1 ; then
    alias -g C='| pbcopy'                   # Mac
elif which xsel >/dev/null 2>&1 ; then
    alias -g C='| xsel --input --clipboard' # Linux
elif which putclip >/dev/null 2>&1 ; then
    alias -g C='| putclip'                  # Cygwin
fi

if [ `uname` = "Darwin" ]; then
    alias eog='open -a Preview'
    alias port='sudo lsof -nP i4TCP'
fi
alias -s {png,jpg,bmp,PNG,JPG,BMP}=eog

# -------------------------------------------------------------------------
# package alias
# -------------------------------------------------------------------------
if [ -f "$(which rbenv)" ]; then
    alias be='bundle exec'
    alias bep='bundle exec pry'
    alias bepr='bundle exec pry-remote'
    alias bo='bundle open'
    alias bf='bundle exec foreman start'
fi

if [ -f "$(which pyenv)" ]; then
    alias pr='pipenv run'
fi

if [ -f "$(which tmux)" ]; then
    alias tm='tmux new-session -s'
    alias tmr='tmux attach -t'
    alias tml='tmux list-sessions'
    alias tmd='tmux detach'
fi

if [ -f "$(which lsd)" ]; then
    alias l='ls' ls='lsd' ll='lsd --long' la='ls --all --long' lt='ll --timesort'
fi

if [ -f "$(which bat)" ]; then
    alias cat='bat'
fi

if [ -f "$(which fd)" ]; then
    alias find='fd'
fi

if [ -f "$(which dust)" ]; then
    alias du='dust -r'
fi

if [ -f "$(which rg)" ]; then
  export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi

if [ -s "$HOME/.tmuxinator/scripts/tmuxinator" ]; then
    source $HOME/.tmuxinator/scripts/tmuxinator
fi

if [ `uname` = 'Darwin' ]; then
    alias o='open .'
    alias updatedb='sudo /usr/libexec/locate.updatedb'
    alias locate='/usr/bin/locate'
fi

# -------------------------------------------------------------------------
# package enviroemtns
# -------------------------------------------------------------------------
#
if [ -f "$(which fzf)" ]; then
    export FZF_DEFAULT_COMMAND='fd --type file --color=always --hidden --follow --exclude .git'
    export FZF_DEFAULT_OPTS='--ansi'

    # alias
    alias rv='fzf-rg-vim'
    alias bc='fzf-bundle-cd'
    alias pk='fzf-process-kill'
    alias ghi='fzf-ghi'
fi

# -------------------------------------------------------------------------
# perl language
# -------------------------------------------------------------------------
alias perldoc='env LANG=C perldoc'
alias perld='perl -MO=Deparse,-x5'
alias cpan-uninstall='\perl -MExtUtils::Install -MExtUtils::Installed -e "unshift@ARGV,new ExtUtils::Installed;sub a{\@ARGV};uninstall((eval{a->[0]->packlist(a->[1])}||do{require CPAN;a->[0]->packlist(CPAN::Shell->expandany(a->[1])->distribution->base_id=~m/(.*)-[^-]+$/)})->packlist_file,1,a->[2])"'
alias cpan-update-all='perl -MCPAN -e '"'"'CPAN::Shell->install(CPAN::Shell->r)'"'"

# if [ -d "$HOME/local" ]; then
#     eval $(perl -I$HOME/local/lib/perl5 -Mlocal::lib=$HOME/local)
# fi

# -------------------------------------------------------------------------
# iOS
# -------------------------------------------------------------------------
export DEVELOPER_DIR=`xcode-select -print-path`
alias symbolicatecrash='/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash'

# cd ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins
# cd ~/Library/Developer/CoreSimulator/Devices/
# cd ~/Library/Developer/Xcode/DerivedData
# cd ~/Library/MobileDevice/Provisioning Profiles
