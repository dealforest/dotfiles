export LC_ALL='en_US.UTF-8'
export BASH_SILENCE_DEPRECATION_WARNING=1

export EDITOR=nvim

export ARCH=$(uname -m)

# PATH
export XDG_CONFIG_HOME="$HOME/.config"
export AQUA_ROOT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua"
export AQUA_BIN_PATH="${AQUA_ROOT_DIR}/bin"
export LOCALBIN="$HOME/.local/bin"
export BUNBIN="$HOME/.bun/bin"
export XCODEBIN="/Applications/Xcode.app/Contents/Developer/usr/bin"
export HOMEBREW_BIN="/opt/homebrew/bin"
export SCRIPTS_PATH="$HOME/.scripts"
export SCRIPTS_BIN_PATH="$HOME/.scripts/bin"

PATH=${HOMEBREW_BIN}:${LOCALBIN}:/usr/bin:/bin:/opt/local/sbin:${PATH}
PATH=${SCRIPTS_PATH}:${SCRIPTS_BIN_PATH}:${AQUA_BIN_PATH}:${BUNBIN}:${PATH}:${XCODEBIN}

# aqua
export AQUA_GLOBAL_CONFIG=${AQUA_GLOBAL_CONFIG:-}:${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml

# python
export BETTER_EXCEPTIONS=1

# brew
export HOMEBREW_BUNDLE_FILE="$HOME/.Brewfile"
export HOMEBREW_NO_ANALYTICS=1

# zoxide
eval "$(zoxide init bash)"

# direnv
eval "$(direnv hook bash)"

# bat
export BAT_THEME="TwoDark"

# ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

# man pager
if command -v nvim &> /dev/null; then
    export MANPAGER="nvim -c ASMANPAGER -"
fi

if [[ -t 0 ]]; then
  stty stop undef
  stty start undef
fi
