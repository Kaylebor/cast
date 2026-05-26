function __cast_synthetic_chat --argument prompt
    set -q SYNTHETIC_API_KEY; or begin
        echo "cast: SYNTHETIC_API_KEY is not set." >&2
        return 1
    end

    set -l api_base (set -q SYNTHETIC_API_BASE; and echo $SYNTHETIC_API_BASE; or echo "api.synthetic.new/openai")
    set -l model (set -q SYNTHETIC_MODEL; and echo $SYNTHETIC_MODEL; or echo "hf:zai-org/GLM-4.7-Flash")

    set api_base (string replace -r '/$' '' -- $api_base)
    set -l url "https://$api_base/v1/chat/completions"

    if not command -sq jq
        echo "cast: jq is required for the built-in Synthetic provider." >&2
        return 1
    end

    set -l json_payload (jq -n \
        --arg model "$model" \
        --arg content "$prompt" \
        '{model: $model, messages: [{role: "user", content: $content}], temperature: 0.3}')

    set -l raw (curl -sS -m 30 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SYNTHETIC_API_KEY" \
        -d "$json_payload" \
        "$url")

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

function __cast_synthetic_complete --argument input
    set -l sys (cast_prompt complete 2>/dev/null; or echo "Complete or rewrite the following shell command. Output only the result, no explanations.")
    set -l prompt (printf '%s\n\n%s' "$sys" "$input")
    __cast_synthetic_chat $prompt
end

function __cast_synthetic_explain --argument input
    set -l sys (cast_prompt explain 2>/dev/null; or echo "Explain the following shell command concisely.")
    set -l prompt (printf '%s\n\n%s' "$sys" "$input")
    __cast_synthetic_chat $prompt
end
