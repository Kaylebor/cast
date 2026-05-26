function __cast_keybind_explain
    set -l buf (commandline -b | string collect)
    set -l result (cast_explain $buf 2>/dev/null)
    if test $status -ne 0 -o -z "$result"
        return
    end

    set -l count (printf '%s\n' $result | wc -l)
    if test $count -gt (math "(tput lines) - 4")
        printf '%s\n' $result | less -R
    else
        printf '%s\n' $result
    end
end
