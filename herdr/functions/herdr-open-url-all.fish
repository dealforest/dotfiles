function herdr-open-url-all
    set -l urls (herdr pane list | awk '{print $1}' | xargs -I {} herdr pane get-content -t {} | grep -oE 'https?://[^ ]+' | sort -u)
    if test -n "$urls"
        echo "$urls" | fzf --tac | xargs open
    end
end
