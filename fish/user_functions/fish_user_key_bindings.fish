# function fish_user_key_bindings
#   fzf_key_bindings
# end
function end-of-line-or-execute
    set -l line (commandline -L)
    set -l cmd (commandline)
    set -l cursor (commandline -C)
    if test (string length -- $cmd[$line]) = $cursor
        # commandline -f execute
        commandline -f accept-autosuggestion
    else
        commandline -f end-of-line
    end
end

function fish_user_key_bindings
    bind \cx\ck fkill

    fzf_key_bindings
end
