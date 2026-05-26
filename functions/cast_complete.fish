function cast_complete --description "Replace current line with LLM completion"
    set -l buffer $argv[1]
    set -l debug false
    for arg in $argv[2..-1]
        if test "$arg" = --debug
            set debug true
        end
    end

    if test -z "$cast_complete_provider"
        echo "cast: \$cast_complete_provider not set. Set it in your config.fish (e.g. set -g cast_complete_provider _cast_user_complete). See https://github.com/Kaylebor/cast#setup" >&2
        return 1
    end

    if not functions --query $cast_complete_provider
        echo "cast: provider '$cast_complete_provider' is not a defined function." >&2
        return 127
    end

    set -l output ($cast_complete_provider $buffer $debug 2>&1)
    set -l code $status

    if test $code -ne 0
        echo "cast: provider '$cast_complete_provider' failed (exit $code)." >&2
        echo "---" >&2
        printf '%s\n' $output >&2
        echo "---" >&2
        echo "See troubleshooting: https://github.com/Kaylebor/cast#troubleshooting" >&2
        return $code
    end

    if test -z "$output"
        echo "cast: provider '$cast_complete_provider' returned empty output." >&2
        return 1
    end

    printf '%s\n' $output
end
