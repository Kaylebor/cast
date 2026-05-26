function __cast_keybind_complete
    # Read current buffer up to cursor; preserve line and history
    set -l buf (commandline -b)

    # Execute completion and replace buffer if successful
    set -l result (cast_complete $buf 2>/dev/null)
    if test $status -eq 0 -a -n "$result"
        commandline -r -- $result
    end
end
