function herdr-workspace-rename
    read -P "new workspace name: " name
    if test -n "$name"
        herdr workspace rename (herdr workspace list | grep "*" | awk '{print $1}') --label "$name"
    end
end
