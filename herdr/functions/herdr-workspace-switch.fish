function herdr-workspace-switch
    set -l workspace (herdr workspace list | fzf | awk '{print $1}')
    if test -n "$workspace"
        herdr workspace attach "$workspace"
    end
end
