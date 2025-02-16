function clean
    # brew
    type -q brew && brew cleanup -s

    set -l CONFIG_CACHE $FISH_CACHE_DIR/config.fish

    test -e $CONFIG_CACHE && rm -rf $CONFIG_CACHE

    init
    exit
end
