function herdr-codex-monitor-layout -d "Create layout for monitoring Codex sessions in herdr"
    set -l herdr_bin /opt/homebrew/bin/herdr
    set -lx PATH /opt/homebrew/bin $PATH

    set -l result ($herdr_bin workspace list 2>&1)
    set -l workspace_id (echo "$result" | jq -r '.result.workspaces[] | select(.focused == true) | .workspace_id // empty')
    set -l root_pane_id (echo "$result" | jq -r '.result.workspaces[] | select(.focused == true) | .root_pane_id // empty')

    if test -z "$workspace_id" || test "$workspace_id" = "null"
        echo "Failed to detect current herdr workspace"
        return 1
    end

    # Get currently focused tab's root pane
    set root_pane_id ($herdr_bin pane list 2>&1 | jq -r '.result.panes[] | select(.focused == true) | .pane_id // empty')
    if test -z "$root_pane_id" || test "$root_pane_id" = "null"
        echo "Failed to detect current pane"
        return 1
    end

    # Split: down 30% (bottom pane for shell, top for workspace switcher)
    set -l split_down ($herdr_bin pane split $root_pane_id --direction down --focus 2>&1)
    set -l pane_down (echo "$split_down" | jq -r '.result.pane.pane_id // empty')

    if test -z "$pane_down" || test "$pane_down" = "null"
        echo "Failed to split pane"
        return 1
    end

    # Run workspace switcher in top pane
    $herdr_bin pane run $root_pane_id "fish -c 'herdr-workspace-switch'"

    # Focus bottom pane
    $herdr_bin pane focus $pane_down 2>/dev/null || true
end
