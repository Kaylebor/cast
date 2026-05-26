function cast_codify --description "Convert a natural-language description into a shell command"
    set -l input $argv[1]
    set -l debug false
    for arg in $argv[2..-1]
        if test "$arg" = --debug
            set debug true
        end
    end

    set input (string replace -r '^#\s*' '' -- "$input")

    set -l provider $cast_codify_provider
    if test -z "$provider"
        set provider $cast_complete_provider
    end

    if test -z "$provider"
        echo "cast: \$cast_codify_provider (or \$cast_complete_provider) not set." >&2
        return 1
    end

    if not functions --query $provider
        echo "cast: provider '$provider' is not a defined function." >&2
        return 127
    end

    set -l sys (cast_prompt codify 2>/dev/null; or echo "Respond with a fish shell command which carries out the user's task. Do not explain. Do not use markdown formatting. Only respond with a single line.")

    set -l messages (jq -n \
        --arg sys "$sys" \
        --arg input "$input" \
        --arg u1 "List all disks on the system" \
        --arg a1 "df -h" \
        --arg u2 "Pull the Alpine 3 container from DockerHub" \
        --arg a2 "docker pull alpine:3" \
        --arg u3 "Substitute all occurrences of \"foo\" with \"bar\"" \
        --arg a3 'sed -i "s/foo/bar/g" $file' \
        '{messages: [
            {role: "system", content: $sys},
            {role: "user", content: $u1},
            {role: "assistant", content: $a1},
            {role: "user", content: $u2},
            {role: "assistant", content: $a2},
            {role: "user", content: $u3},
            {role: "assistant", content: $a3},
            {role: "user", content: $input}
        ]}')

    set -l output ($provider "$messages" "$debug" 2>&1)
    set -l code $status

    if test $code -ne 0
        echo "cast: provider '$provider' failed (exit $code)." >&2
        echo "---" >&2
        printf '%s\n' $output >&2
        echo "---" >&2
        return $code
    end

    if test -z "$output"
        echo "cast: provider '$provider' returned empty output." >&2
        return 1
    end

    printf '%s' $output
end
