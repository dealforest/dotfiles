function herdr-kill-worktree
    set -l pane_path (pwd)
    set -l gwq_json (gwq list --json)
    set -l branch (echo "$gwq_json" | jq -r --arg p "$pane_path" '[.[] | select(.path as $path | $p | startswith($path))] | sort_by(.path | length) | last | .branch')
    set -l main_repo (echo "$gwq_json" | jq -r '.[] | select(.path | contains(".worktree") | not) | .path')

    if test -n "$branch" && test "$branch" != "null"
        read -P "kill worktree ($branch) and pane? (y/n) " confirm
        if test "$confirm" = "y"
            cd "$main_repo"
            gwq remove -f "$branch"
            herdr pane close
        end
    else
        read -P "kill pane? (y/n) " confirm
        if test "$confirm" = "y"
            herdr pane close
        end
    end
end
