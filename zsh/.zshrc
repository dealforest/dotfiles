# zmodload zsh/zprof && zprof

autoload -U colors; colors
autoload -Uz is-at-least
autoload -Uz add-zsh-hook

bindkey -e

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
REPORTTIME=3

setopt auto_cd
# setopt auto_pushd
setopt magic_equal_subst
setopt no_flow_control

setopt append_history
setopt extended_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store
# setopt pushd_ignore_dups
setopt share_history

setopt prompt_subst
setopt no_prompt_cr
setopt transient_rprompt

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'

function _ls_chpwd { ls }
add-zsh-hook chpwd _ls_chpwd

if [ -f "$(which starship)" ]; then
    RPROMPT="%{${fg[yellow]}%}%n@%m%{$reset_color%}"
    eval "$(starship init zsh)"
else
    local prompt_color="${fg[yellow]}"
    if test ${UID} -eq 0; then; prompt_color="${fg[red]}"; fi
    PROMPT="%{$prompt_color%}[%n@%m%1(v|%{${fg[green]}%}%1v%f|)%{$prompt_color%}]%{${reset_color}%}%b "

    # -------------------------------------------------------------------------
    # vcs_info
    # see also: http://qiita.com/items/8d5a627d773758dd8078
    # -------------------------------------------------------------------------
    if is-at-least 4.3.10; then
        autoload -Uz vcs_info
        zstyle ':vcs_info:*' enable git svn
        zstyle ':vcs_info:*' formats       ':(%s)%b' '%c%u%m'
        zstyle ':vcs_info:*' actionformats ':(%s)%b|%a' '%c%u%m'
        zstyle ':vcs_info:git:*' check-for-changes true
        zstyle ':vcs_info:git:*' stagedstr   "+"
        zstyle ':vcs_info:git:*' unstagedstr "-"
        bindkey '^R' history-incremental-pattern-search-backward
        bindkey '^S' history-incremental-pattern-search-forward

        function _update_vcs_info_msg() {
            local -a messages
            local prompt

            LANG=en_US.UTF-8 vcs_info

            if [[ -z ${vcs_info_msg_0_} ]]; then
                prompt=""
            else
                psvar=()
                [[ -n "$vcs_info_msg_0_" ]] && psvar[1]=( "${vcs_info_msg_0_}" )
                [[ -n "$vcs_info_msg_1_" ]] && messages+=( "${vcs_info_msg_1_}" )
                prompt="$messages"
            fi
            RPROMPT="%{${fg[red]}%}[%{${fg[green]}%}$prompt%{${fg[red]}%}:%~]%{$reset_color%}"
        }
        add-zsh-hook precmd _update_vcs_info_msg
    fi

    if is-at-least 4.3.11; then
        zstyle ':vcs_info:git+set-message:*' hooks \
                                                git-hook-begin \
                                                git-untracked \
                                                git-push-status \
                                                git-nomerge-branch \
                                                git-stash-count
        function +vi-git-hook-begin() {
            if [[ $(command git rev-parse --is-inside-work-tree 2> /dev/null) != 'true' ]]; then
                return 1
            fi

            return 0
        }

        function +vi-git-untracked() {
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            if command git status --porcelain 2> /dev/null \
                | awk '{print $1}' \
                | command grep -F '??' > /dev/null 2>&1 ; then
                hook_com[unstaged]+='?'
            fi
        }

        function +vi-git-push-status() {
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            if [[ "${hook_com[branch]}" != "master" ]]; then
                return 0
            fi

            local ahead
            ahead=$(command git rev-list origin/master..master 2>/dev/null \
                | wc -l \
                | tr -d ' ')

            if [[ "$ahead" -gt 0 ]]; then
                hook_com[misc]+="(p${ahead})"
            fi
        }

        function +vi-git-nomerge-branch() {
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            if [[ "${hook_com[branch]}" == "master" ]]; then
                return 0
            fi

            local nomerged
            nomerged=$(command git rev-list master..${hook_com[branch]} 2>/dev/null | wc -l | tr -d ' ')

            if [[ "$nomerged" -gt 0 ]] ; then
                hook_com[misc]+="(m${nomerged})"
            fi
        }

        function +vi-git-stash-count() {
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            local stash
            stash=$(command git stash list 2>/dev/null | wc -l | tr -d ' ')
            if [[ "${stash}" -gt 0 ]]; then
                hook_com[misc]+="|S${stash}"
            fi
        }
    fi
fi

# -------------------------------------------------------------------------
# chpwd_recent_dirs
# -------------------------------------------------------------------------
if is-at-least 4.3.11; then
  autoload -U chpwd_recent_dirs cdr
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ":chpwd:*" recent-dirs-max 500
  zstyle ":chpwd:*" recent-dirs-default true
  zstyle ":completion:*" recent-dirs-insert always
fi

# -------------------------------------------------------------------------
# smart-insert-last-word
# -------------------------------------------------------------------------
autoload -U smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
zstyle :insert-last-word match \
  '*([^[:space:]][[:alpha:]/\\]|[[:alpha:]/\\][^[:space:]])*'
bindkey '^[' insert-last-word

# -------------------------------------------------------------------------
# modify-current-argument
# -------------------------------------------------------------------------
autoload -U modify-current-argument
_quote-previous-word-in-single() {
    modify-current-argument '${(qq)${(Q)ARG}}'
    zle vi-forward-blank-word
}
_quote-previous-word-in-double() {
    modify-current-argument '${(qqq)${(Q)ARG}}'
    zle vi-forward-blank-word
}
zle -N _quote-previous-word-in-single
zle -N _quote-previous-word-in-double
bindkey '^[s' _quote-previous-word-in-single
bindkey '^[d' _quote-previous-word-in-double

# -------------------------------------------------------------------------
# select-word-style
# -------------------------------------------------------------------------
autoload -Uz select-word-style; select-word-style default
zstyle ':zle:*' word-chars " _-./;@"
zstyle ':zle:*' word-style unspecified

# -------------------------------------------------------------------------
# history-search-end
# -------------------------------------------------------------------------
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
bindkey "\\ep" history-beginning-search-backward-end
bindkey "\\en" history-beginning-search-forward-end

# -------------------------------------------------------------------------
# bindkey
# -------------------------------------------------------------------------
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line

# -------------------------------------------------------------------------
# load function
# -------------------------------------------------------------------------
function source_if { [ -f $1 ] && source $1 }
source_if ~/.zsh.d/function
source_if ~/.zsh.d/plugin

# -------------------------------------------------------------------------
# load zplug
# -------------------------------------------------------------------------
# if [ -d "$(brew --prefix zplug 2>/dev/null)" ]; then
#   export ZPLUG_HOME=/usr/local/opt/zplug
#   source $ZPLUG_HOME/init.zsh

#   zplug 'zsh-users/zsh-autosuggestions'
#   zplug 'zsh-users/zsh-completions'
#   zplug 'zsh-users/zsh-syntax-highlighting'

#   if ! zplug check --verbose; then
#     printf 'Install? [y/N]: '
#     if read -q; then
#       echo; zplug install
#     fi
#   fi

#   zplug load
# fi

# -------------------------------------------------------------------------
# load function
# -------------------------------------------------------------------------
if [ -d $HOME/.zsh.d/completions ]; then
    fpath=($HOME/.zsh.d/completions(N) $fpath)
fi
if [ -d $HOME/.zsh.d/plugins/zsh-completions ]; then
    fpath=($HOME/.zsh.d/plugins/zsh-completions/src(N) $fpath)
fi
autoload -U compinit; compinit -u -C

# -------------------------------------------------------------------------
# load other dotfile
# -------------------------------------------------------------------------
source_if ~/.zshrc.local

# if type zprof > /dev/null 2>&1; then
#   zprof | less
# fi
