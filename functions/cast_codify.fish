function cast_codify --description "Convert a natural-language description into a shell command"
    set -l buffer $argv[1]
    set -l debug false
    for arg in $argv[2..-1]
        if test "$arg" = --debug
            set debug true
        end
    end

    # Strip leading # if present (codify signal)
    set buffer (string replace -r '^#\s*' '' -- $buffer)

    if test -z "$cast_complete_provider"
        echo "cast: \$cast_complete_provider not set." >&2
        return 1
    end

    if not functions --query $cast_complete_provider
        echo "cast: provider '$cast_complete_provider' is not a defined function." >&2
        return 127
    end

    set -l prompt (cast_prompt codify)
    set -l full (printf '%s\n\n%s' "$prompt" "$buffer")

    set -l output ($cast_complete_provider $full $debug 2>&1)
    set -l code $status

    if test $code -ne 0
        echo "cast: provider '$cast_complete_provider' failed (exit $code)." >&2
        echo "---" >&2
        printf '%s\n' $output >&2
        echo "---" >&2
        return $code
    end

    if test -z "$output"
        echo "cast: provider '$cast_complete_provider' returned empty output." >&2
        return 1
    end

    printf '%s\n' $output
end
