function __cast_synthetic_chat
    set -l prompt $argv[1]
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]

    set -q SYNTHETIC_API_KEY; or begin
        echo "cast: SYNTHETIC_API_KEY is not set." >&2
        return 1
    end

    set -l api_base (set -q SYNTHETIC_API_BASE; and echo $SYNTHETIC_API_BASE; or echo "api.synthetic.new/openai")
    set -l model (set -q SYNTHETIC_MODEL; and echo $SYNTHETIC_MODEL; or echo "hf:zai-org/GLM-4.7-Flash")
    set -l reasoning_effort (set -q SYNTHETIC_REASONING_EFFORT; and echo $SYNTHETIC_REASONING_EFFORT; or echo "low")

    set api_base (string replace -r '/$' '' -- $api_base)
    set -l url "https://$api_base/v1/chat/completions"

    if not command -sq jq
        echo "cast: jq is required for the built-in Synthetic provider." >&2
        return 1
    end

    set -l json_payload (jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        --arg reasoning_effort "$reasoning_effort" \
        '{model: $model, messages: [{role: "user", content: $content}], temperature: 0.3, reasoning_effort: $reasoning_effort}')

    if test "$debug" = true
        echo "[cast debug] url: $url" >&2
        echo "[cast debug] model: $model" >&2
        echo "[cast debug] reasoning_effort: $reasoning_effort" >&2
        echo "[cast debug] payload: $json_payload" >&2
    end

    set -l raw (curl -sS -m 60 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SYNTHETIC_API_KEY" \
        -d "$json_payload" \
        "$url")

    if test "$debug" = true
        echo "[cast debug] raw response:" >&2
        echo "$raw" >&2
    end

    if string match -q '*"error"*' -- $raw
        echo "cast: API returned an error." >&2
        echo $raw | jq -r '.error.message // .error // "Unknown error"' >&2
        return 1
    end

    set -l content (echo $raw | jq -r '.choices[0].message.content // empty')
    if test -z "$content"
        echo "cast: empty response from API." >&2
        echo $raw | jq . >&2
        return 1
    end

    printf '%s\n' $content
end

function __cast_synthetic_complete
    set -l sys (cast_prompt complete 2>/dev/null; or echo "Complete or rewrite the following shell command. Output only the result, no explanations.")
    set -l prompt (printf '%s\n\n%s' "$sys" "$argv[1]")
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]
    __cast_synthetic_chat $prompt $debug
end

function __cast_synthetic_explain
    set -l sys (cast_prompt explain 2>/dev/null; or echo "Explain the following shell command concisely.")
    set -l prompt (printf '%s\n\n%s' "$sys" "$argv[1]")
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]
    __cast_synthetic_chat $prompt $debug
end
