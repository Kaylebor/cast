function __cast_keybind_explain
    set -l buf (commandline -b)

    set -l result (cast_explain $buf 2>/dev/null)
    if test $status -eq 0 -a -n "$result"
        # Pipe long output through less; short output goes straight to terminal
        begin
            set -l count (printf '%s\n' $result | wc -l)
            if test $count -gt (math "(tput lines) - 4")
                printf '%s\n' $result | less -R
            else
                printf '%s\n' $result
            end
        end
    end
end
