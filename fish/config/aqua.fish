set -gx AQUA_ROOT_DIR $XDG_DATA_HOME/aquaproj-aqua
set -gx AQUA_GLOBAL_CONFIG $XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml
fish_add_path -p $AQUA_ROOT_DIR/bin

if command -v mise &> /dev/null
    mise activate fish | source
    fish_add_path --prepend --global ~/.local/share/mise/shims
end
