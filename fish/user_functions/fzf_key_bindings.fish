# Key bindings
# ------------
function fzf_key_bindings

    # Store current token in $dir as root for the 'find' command
    function fzf-file-widget -d "List files and folders"
        set -l commandline (__fzf_parse_commandline)
        set -l dir $commandline[1]
        set -l fzf_query $commandline[2]

        # "-path \$dir'*/\\.*'" matches hidden files/folders inside $dir but not
        # $dir itself, even if hidden.
        set -q FZF_CTRL_T_COMMAND; or set -l FZF_CTRL_T_COMMAND "
    command find -L \$dir -mindepth 1 \\( -path \$dir'*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | sed 's@^\./@@'"

        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT --reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS"
            eval "$FZF_CTRL_T_COMMAND | "(__fzfcmd)' -m --query "'$fzf_query'"' | while read -l r
                set result $result $r
            end
        end
        if [ -z "$result" ]
            commandline -f repaint
            return
        else
            # Remove last token from commandline.
            commandline -t ""
        end
        for i in $result
            commandline -it -- (string escape $i)
            commandline -it -- ' '
        end
        commandline -f repaint
    end

    function fzf-history-widget -d "Show command history"
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT $FZF_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m"

            set -l FISH_MAJOR (echo $version | cut -f1 -d.)
            set -l FISH_MINOR (echo $version | cut -f2 -d.)

            # history's -z flag is needed for multi-line support.
            # history's -z flag was added in fish 2.4.0, so don't use it for versions
            # before 2.4.0.
            if [ "$FISH_MAJOR" -gt 2 -o \( "$FISH_MAJOR" -eq 2 -a "$FISH_MINOR" -ge 4 \) ]
                history -z | eval (__fzfcmd) --read0 --print0 -q '(commandline)' | read -lz result
                and commandline -- $result
            else
                history | eval (__fzfcmd) -q '(commandline)' | read -l result
                and commandline -- $result
            end
        end
        commandline -f repaint
    end

    function fzf-cd-widget -d "Change directory"
        set -l commandline (__fzf_parse_commandline)
        set -l dir $commandline[1]
        set -l fzf_query $commandline[2]

        set -q FZF_ALT_C_COMMAND; or set -l FZF_ALT_C_COMMAND "
    command find -L \$dir -mindepth 1 \\( -path \$dir'*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
    -o -type d -print 2> /dev/null | sed 's@^\./@@'"
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS"
            eval "$FZF_ALT_C_COMMAND | "(__fzfcmd)' +m --query "'$fzf_query'"' | read -l result

            if [ -n "$result" ]
                cd $result

                # Remove last token from commandline.
                commandline -t ""
            end
        end

        commandline -f repaint
    end

    function fzf-cd-ghq -d "Efficient fish keybindinging for fzf with ghq"
        ghq list | fzf --query (commandline) | read -z select

        if not test -z $select
            cd (ghq root)/(builtin string trim "$select")
        end

        commandline -f repaint
    end

    function fzf-code-ghq -d "Efficient fish keybindinging for fzf with ghq"
        ghq list | fzf --query (commandline) | read -z select

        if not test -z $select
            code (ghq root)/(builtin string trim "$select")
        end

        commandline -f repaint
    end

    function fzf-launch-ghq -d "Pick a ghq repo; Enter = cd, Alt-Enter = choose action then run"
        set -l root_dir (ghq root)

        set -l key path
        ghq list \
            | fzf --reverse --height 40% \
            --prompt="Repo> " \
            --query (commandline) \
            --expect=enter,alt-enter \
            | read -z key path

        test -z "$path"; and return

        if test "$key" = alt-enter
            set -l action (printf "%s\n" \
                "claude code" cursor code lazygit "gh repo view -w" open \
                | fzf --prompt="Action for $path> " --height 30% --reverse)

            cd $root_dir/(builtin string trim "$path")
            switch $action
                case claude code
                    claude code
                case cursor
                    cursor .
                case code
                    code .
                case lazygit
                    lazygit -p .
                case 'gh repo view -w'
                    gh repo view --web (basename -- $path)
                case open
                    open .
                case '*'
                    return
            end
        else
            cd $root_dir/(builtin string trim "$path")
        end

        commandline -f repaint
    end

    function fzf-launch-sandbox -d "Pick a sandbox; Enter = cd, Alt-Enter = choose action then run"
        fzf-launch-dir ~/sandbox
    end

    function fzf-cd-gwq -d "Pick a git worktree with fzf; Enter=cd, Ctrl-X=remove"
        # fzf の出力: 1行目=キー, 2行目以降=選択項目
        # ソート順: * (current) -> + (worktree) -> 無印
        set -l output (begin
                git branch | grep '^\*'
                git branch | grep '^+'
                git branch | grep '^  '
                echo "  [new]"
            end \
            | fzf --reverse --height 40% \
                --prompt="Branch> " \
                --query (commandline) \
                --expect=enter,ctrl-x \
                --multi)

        test (count $output) -lt 2; and commandline -f repaint; and return

        set -l key $output[1]
        set -l selections $output[2..-1]

        # 先頭の "* " や "  " や "+ " を除去してブランチ名を取得
        set -l branches
        for sel in $selections
            set -l b (string replace -r '^[\*\+ ] +' '' $sel)
            set -a branches $b
        end

        if test "$key" = "ctrl-x"
            # Ctrl+X: worktree を削除 (.worktree を含むもののみ)
            set -l targets
            for b in $branches
                set -l path (gwq list --json | jq -r --arg b "$b" '.[] | select(.branch == $b) | .path')
                if test -n "$path"; and string match -q '*.worktree*' "$path"
                    set -a targets $b
                end
            end
            if test (count $targets) -gt 0
                echo "Targets: $targets"
                set -l action (printf '%s\n' \
                    "Remove worktree only" \
                    "Remove worktree and branch" \
                    "Cancel" \
                    | fzf --reverse --height 20% --prompt="Action> ")
                # メインリポジトリに移動（worktree 内から削除できないため）
                set -l main_repo (gwq list --json | jq -r '.[] | select(.path | contains(".worktree") | not) | .path')
                if test -n "$main_repo"
                    cd $main_repo
                end
                switch $action
                    case '*worktree only*'
                        for b in $targets
                            gwq remove -f $b
                        end
                    case '*worktree and branch*'
                        for b in $targets
                            gwq remove -f -b $b
                        end
                    case '*'
                        # Cancel
                end
            end
        else
            # Enter: cd または作成
            set -l b $branches[1]
            if test "$b" = "[new]"
                read -P "New branch name: " branch_name
                test -z "$branch_name"; and commandline -f repaint; and return
                gwq add -b $branch_name
                set -l path (gwq list --json | jq -r --arg b "$branch_name" '.[] | select(.branch == $b) | .path')
                if test -n "$path"
                    cd $path
                end
            else
                set -l path (gwq list --json | jq -r --arg b "$b" '.[] | select(.branch == $b) | .path')
                if test -n "$path"
                    cd $path
                else
                    gwq add $b
                end
            end
        end

        commandline -f repaint
    end

    function fzf-launch-dir \
        --argument-names root_dir \
        -d "Pick a root directory; Enter = cd, Alt-Enter = choose action then run"
        set -l finder "fd -t d -d 3 . $root_dir | sed \"s|$root_dir/||\""

        set -l key path
        eval $finder \
            | fzf  --reverse --height 40% \
            --prompt="Repo> " \
            --query (commandline) \
            --expect=enter,alt-enter \
            | read -z key path

        test -z "$path"; and return

        if test "$key" = alt-enter
            set -l action (printf "%s\n" \
                "claude code" cursor code lazygit "gh repo view -w" open \
                | fzf --prompt="Action for $path> " --height 30% --reverse)

            eval "cd $root_dir/$path"
            switch $action
                case claude code
                    eval "claude code"
                case cursor
                    eval "cursor ."
                case code
                    eval "code ."
                case lazygit
                    eval "lazygit -p ."
                case 'gh repo view -w'
                    eval "gh repo view --web (basename -- $path)"
                case open
                    eval "open ."
                case '*'
                    return
            end
        else
            eval "cd $root_dir/$path"
        end

        commandline -f repaint
    end

    function __fzfcmd
        set -q FZF_TMUX; or set FZF_TMUX 0
        set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
        if [ $FZF_TMUX -eq 1 ]
            echo "fzf-tmux -d$FZF_TMUX_HEIGHT"
        else
            echo fzf
        end
    end

    bind \ct fzf-file-widget
    bind \cr fzf-history-widget
    bind \ec fzf-cd-widget
    bind \c] fzf-launch-ghq
    bind \cq fzf-cd-gwq
    bind \e\[91\;5u fzf-launch-sandbox

    if bind -M insert >/dev/null 2>&1
        bind -M insert \ct fzf-file-widget
        bind -M insert \cr fzf-history-widget
        bind -M insert \ec fzf-cd-widget
    end

    function __fzf_parse_commandline -d 'Parse the current command line token and return split of existing filepath and rest of token'
        # eval is used to do shell expansion on paths
        set -l commandline (eval "printf '%s' "(commandline -t))

        if [ -z $commandline ]
            # Default to current directory with no --query
            set dir '.'
            set fzf_query ''
        else
            set dir (__fzf_get_dir $commandline)

            if [ "$dir" = "." -a (string sub -l 1 $commandline) != '.' ]
                # if $dir is "." but commandline is not a relative path, this means no file path found
                set fzf_query $commandline
            else
                # Also remove trailing slash after dir, to "split" input properly
                set fzf_query (string replace -r "^$dir/?" '' "$commandline")
            end
        end

        echo $dir
        echo $fzf_query
    end

    function __fzf_get_dir -d 'Find the longest existing filepath from input string'
        set dir $argv

        # Strip all trailing slashes. Ignore if $dir is root dir (/)
        if [ (string length $dir) -gt 1 ]
            set dir (string replace -r '/*$' '' $dir)
        end

        # Iteratively check if dir exists and strip tail end of path
        while [ ! -d "$dir" ]
            # If path is absolute, this can keep going until ends up at /
            # If path is relative, this can keep going until entire input is consumed, dirname returns "."
            set dir (dirname "$dir")
        end

        echo $dir
    end

end
