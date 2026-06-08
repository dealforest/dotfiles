function herdr-codex-layout-debug -d "Debug version of herdr-codex-layout"
    set -l issue_url ""
    set -l codex_args_list

    for arg in $argv
        if string match -qr '^https?://.*/(issues|pull)/[0-9]+' $arg
            set issue_url $arg
        else
            set -a codex_args_list $arg
        end
    end

    set -l branch_name ""
    if test -n "$issue_url"
        set -l issue_id (string match -r '/(issues|pull)/([0-9]+)' $issue_url)[3]
        if test -n "$issue_id"
            set branch_name "feature/$issue_id"
            set -l wt_path (gwq list --json | jq -r --arg b "$branch_name" '.[] | select(.branch == $b) | .path')
            if test -n "$wt_path" && test "$wt_path" != "null"
                cd $wt_path
            else
                gwq add -b $branch_name
                set wt_path (gwq list --json | jq -r --arg b "$branch_name" '.[] | select(.branch == $b) | .path')
                if test -n "$wt_path" && test "$wt_path" != "null"
                    cd $wt_path
                end
            end
        end
    end

    set -l name (basename (pwd))
    echo "DEBUG: pwd=(pwd) name=$name branch_name=$branch_name"

    set -l codex_base codex
    for danger_flag in --dangerously-bypass-approvals-and-sandbox --dangerously-skip-permissions
        if contains -- $danger_flag $codex_args_list
            set codex_base sandbox-codex
            set -l idx (contains -i -- $danger_flag $codex_args_list)
            set -e codex_args_list[$idx]
        end
    end

    set -l codex_cmd $codex_base
    if test (count $codex_args_list) -gt 0
        set codex_cmd "$codex_base $codex_args_list"
    end
    if test -n "$issue_url"
        set codex_cmd "$codex_cmd $issue_url"
    end

    set -l viddy_cmd "viddy -- 'f=\$(ls -t .plans/*.md 2>/dev/null | head -1); echo \"\$f\"; CLICOLOR_FORCE=1 glow --style dark \"\$f\" 2>/dev/null || echo \"No plan files found\"'"

    # Prepare herdr workspace
    set -l result
    set -l workspace_id ""
    set -l root_pane_id ""

    if test -n "$branch_name"
        echo "DEBUG: Trying worktree open --branch $branch_name"
        set result (herdr worktree open --branch $branch_name --focus 2>&1)
        echo "DEBUG: worktree open result: $result"
        if echo "$result" | jq -e '.error' >/dev/null 2>&1
            echo "DEBUG: worktree open failed, trying create"
            set result (herdr worktree create --branch $branch_name 2>&1)
            echo "DEBUG: worktree create result: $result"
        end
    else
        echo "DEBUG: Trying workspace create --label $name --cwd (pwd)"
        set result (herdr workspace create --label $name --cwd (pwd) 2>&1)
        echo "DEBUG: workspace create result: $result"
    end

    set workspace_id (echo "$result" | jq -r '.result.workspace.workspace_id // empty')
    set root_pane_id (echo "$result" | jq -r '.result.root_pane.pane_id // empty')
    echo "DEBUG: workspace_id=$workspace_id root_pane_id=$root_pane_id"

    if test -z "$workspace_id" || test "$workspace_id" = "null"
        echo "Failed to create or open herdr workspace"
        return 1
    end

    echo "DEBUG: Creating tab"
    set -l tab_result (herdr tab create --workspace $workspace_id --label "codex" 2>&1)
    echo "DEBUG: tab create result: $tab_result"
    set root_pane_id (echo "$tab_result" | jq -r '.result.root_pane.pane_id // empty')
    set -l tab_id (echo "$tab_result" | jq -r '.result.tab.tab_id // empty')
    echo "DEBUG: tab_root_pane_id=$root_pane_id tab_id=$tab_id"

    if test -z "$root_pane_id" || test "$root_pane_id" = "null"
        echo "Failed to create tab in herdr workspace"
        return 1
    end

    echo "DEBUG: Splitting panes"
    set -l split_down (herdr pane split $root_pane_id --direction down 2>&1)
    echo "DEBUG: split down result: $split_down"
    set -l pane_down (echo "$split_down" | jq -r '.result.pane.pane_id // empty')
    echo "DEBUG: pane_down=$pane_down"

    set -l split_right (herdr pane split $root_pane_id --direction right 2>&1)
    echo "DEBUG: split right result: $split_right"
    set -l pane_right (echo "$split_right" | jq -r '.result.pane.pane_id // empty')
    echo "DEBUG: pane_right=$pane_right"

    echo "DEBUG: Running commands"
    herdr pane run $root_pane_id "tig" 2>&1
    herdr pane run $pane_right "$viddy_cmd" 2>&1
    herdr pane run $pane_down "$codex_cmd" 2>&1

    echo "DEBUG: Focusing tab"
    herdr tab focus $tab_id 2>&1 || true
    echo "DEBUG: Done"
end
