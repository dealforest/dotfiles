function safe
    safehouse \
        --enable=ssh,xcode,macos-gui \
        --add-dirs="$HOME/.claude" \
        --add-dirs="$HOME/ScreenShots" \
        --add-dirs="$HOME/.codex" \
        --add-dirs="$HOME/.cache" \
        --add-dirs-ro="$HOME/.config/git" \
        --add-dirs-ro="$HOME/.local/share/aquaproj-aqua" \
        --add-dirs-ro="$HOME/.local/bin" \
        $argv
end

# Sandboxed helpers without overriding the original binary names.
function sandbox-claude
    safe claude --dangerously-skip-permissions $argv
end

function sandbox-codex
    safe codex --dangerously-bypass-approvals-and-sandbox $argv
end

function sandbox-amp
    safe amp --dangerously-allow-all $argv
end

function sandbox-gemini
    set -lx NO_BROWSER true
    safe gemini --yolo $argv
end
