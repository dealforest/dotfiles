function herdr-open-url-current
    set -l urls (herdr pane get-content | grep -oE 'https?://[^ ]+' | sort -u)
    if test -n "$urls"
        echo "$urls" | fzf --tac | xargs open
    end
end
