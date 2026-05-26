function __cast_keybind_complete
    set -l buf (commandline -b | string collect)
    set -l debug
    set -q cast_debug; and set debug --debug

    # Detect codify signal: line starts with # (natural language task)
    if string match -q -r '^#\s*' -- $buf
        set -l result (cast_codify $buf $debug 2>/dev/null)
        if test $status -eq 0 -a -n "$result"
            commandline -r -- $result
        end
    else
        set -l result (cast_complete $buf $debug 2>/dev/null)
        if test $status -eq 0 -a -n "$result"
            commandline -r -- $result
        end
    end
end
