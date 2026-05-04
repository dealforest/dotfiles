on run argv
    set targetTitle to item 1 of argv
    tell application "Ghostty" to activate
    tell application "System Events"
        tell process "Ghostty"
            repeat with w in windows
                if name of w contains targetTitle then
                    perform action "AXRaise" of w
                    exit repeat
                end if
            end repeat
        end tell
    end tell
end run
