function herdr-codex-layout -d "Create dev layout with tig and Codex in herdr"
    # Ensure Homebrew herdr takes precedence over aqua proxy
    set -l herdr_bin /opt/homebrew/bin/herdr
    set -lx PATH /opt/homebrew/bin $PATH

    set -l issue_url ""
    set -l codex_args_list
    set -l use_current_tab false

    for arg in $argv
        if test "$arg" = "--current-tab"
            set use_current_tab true
        else if string match -qr '^https?://.*/(issues|pull)/[0-9]+' $arg
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

    # Prepare herdr workspace / tab
    set -l result
    set -l workspace_id ""
    set -l root_pane_id ""
    set -l tab_id ""

    if test "$use_current_tab" = "true"
        # Use the currently focused pane in the current workspace
        set workspace_id ($herdr_bin workspace list 2>&1 | jq -r '.result.workspaces[] | select(.focused == true) | .workspace_id // empty')
        set root_pane_id ($herdr_bin pane list 2>&1 | jq -r '.result.panes[] | select(.focused == true) | .pane_id // empty')

        if test -z "$workspace_id" || test "$workspace_id" = "null"
            echo "Failed to detect current herdr workspace"
            return 1
        end
        if test -z "$root_pane_id" || test "$root_pane_id" = "null"
            echo "Failed to detect current pane"
            return 1
        end
    else if test -n "$branch_name"
        # Try opening existing worktree workspace first
        set result ($herdr_bin worktree open --branch $branch_name --focus 2>&1)
        if echo "$result" | jq -e '.error' >/dev/null 2>&1
            # If open fails, create new worktree workspace
            set result ($herdr_bin worktree create --branch $branch_name 2>&1)
        end

        set workspace_id (echo "$result" | jq -r '.result.workspace.workspace_id // empty')
        set root_pane_id (echo "$result" | jq -r '.result.root_pane.pane_id // empty')

        if test -z "$workspace_id" || test "$workspace_id" = "null"
            echo "Failed to create or open herdr workspace"
            echo "Raw result: $result"
            return 1
        end

        # Create a new tab for the codex layout
        set -l tab_result ($herdr_bin tab create --workspace $workspace_id --label "codex" 2>&1)
        set root_pane_id (echo "$tab_result" | jq -r '.result.root_pane.pane_id // empty')
        set tab_id (echo "$tab_result" | jq -r '.result.tab.tab_id // empty')

        if test -z "$root_pane_id" || test "$root_pane_id" = "null"
            echo "Failed to create tab in herdr workspace"
            echo "Raw result: $tab_result"
            return 1
        end
    else
        set result ($herdr_bin workspace create --label $name --cwd (pwd) 2>&1)
        set workspace_id (echo "$result" | jq -r '.result.workspace.workspace_id // empty')
        set root_pane_id (echo "$result" | jq -r '.result.root_pane.pane_id // empty')

        if test -z "$workspace_id" || test "$workspace_id" = "null"
            echo "Failed to create or open herdr workspace"
            echo "Raw result: $result"
            return 1
        end

        # Create a new tab for the codex layout
        set -l tab_result ($herdr_bin tab create --workspace $workspace_id --label "codex" 2>&1)
        set root_pane_id (echo "$tab_result" | jq -r '.result.root_pane.pane_id // empty')
        set tab_id (echo "$tab_result" | jq -r '.result.tab.tab_id // empty')

        if test -z "$root_pane_id" || test "$root_pane_id" = "null"
            echo "Failed to create tab in herdr workspace"
            echo "Raw result: $tab_result"
            return 1
        end
    end

    # Split layout:
    # 1. root pane -> down (bottom pane for codex)
    set -l split_down ($herdr_bin pane split $root_pane_id --direction down 2>&1)
    set -l pane_down (echo "$split_down" | jq -r '.result.pane.pane_id // empty')

    # 2. root pane -> right (top-right pane for viddy)
    set -l split_right ($herdr_bin pane split $root_pane_id --direction right 2>&1)
    set -l pane_right (echo "$split_right" | jq -r '.result.pane.pane_id // empty')

    # Run commands in each pane
    $herdr_bin pane run $root_pane_id "tig"
    $herdr_bin pane run $pane_right "$viddy_cmd"
    $herdr_bin pane run $pane_down "$codex_cmd"

    # Focus the new tab if we created one
    if test -n "$tab_id" && test "$tab_id" != "null"
        $herdr_bin tab focus $tab_id 2>/dev/null || true
    end
end
