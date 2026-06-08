function agent_bulk_update -d "Update Claude Code, Codex, and opencode"
    set -l failed 0

    if type -q claude
        echo "==> claude upgrade"
        claude upgrade
        or set failed 1
    else
        echo "claude not found"
        set failed 1
    end

    if type -q codex
        echo "==> codex update"
        codex update
        or set failed 1
    else
        echo "codex not found"
        set failed 1
    end

    if type -q opencode
        echo "==> opencode upgrade"
        opencode upgrade
        or set failed 1
    else
        echo "opencode not found"
        set failed 1
    end

    return $failed
end
