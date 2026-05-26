function cast_explain --description "Explain the given command via LLM"
    set -l input $argv[1]
    set -l debug false
    for arg in $argv[2..-1]
        if test "$arg" = --debug
            set debug true
        end
    end

    if test -z "$cast_explain_provider"
        echo "cast: \$cast_explain_provider not set." >&2
        return 1
    end

    if not functions --query $cast_explain_provider
        echo "cast: provider '$cast_explain_provider' is not a defined function." >&2
        return 127
    end

    set -l sys (cast_prompt explain 2>/dev/null; or echo "Explain the following shell command concisely.")

    set -l messages (jq -n \
        --arg sys "$sys" \
        --arg input "$input" \
        '{messages: [{role: "system", content: $sys}, {role: "user", content: $input}]}')

    set -l output ($cast_explain_provider "$messages" "$debug" 2>&1)
    set -l code $status

    if test $code -ne 0
        echo "cast: provider '$cast_explain_provider' failed (exit $code)." >&2
        echo "---" >&2
        printf '%s\n' $output >&2
        echo "---" >&2
        echo "See troubleshooting: https://github.com/Kaylebor/cast#troubleshooting" >&2
        return $code
    end

    if test -z "$output"
        echo "cast: provider '$cast_explain_provider' returned empty output." >&2
        return 1
    end

    printf '%s' $output
end
