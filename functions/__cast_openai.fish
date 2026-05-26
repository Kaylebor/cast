function __cast_openai_chat --argument prompt
    set -q OPENAI_API_KEY; or begin
        echo "cast: OPENAI_API_KEY is not set." >&2
        return 1
    end

    set -l api_base (set -q OPENAI_API_BASE; and echo $OPENAI_API_BASE; or echo "api.openai.com")
    set -l model   (set -q OPENAI_MODEL;   and echo $OPENAI_MODEL;   or echo "gpt-4o-mini")

    set api_base (string replace -r '/$' '' -- $api_base)
    set -l url "https://$api_base/v1/chat/completions"

    if not command -sq jq
        echo "cast: jq is required for the built-in OpenAI provider." >&2
        return 1
    end

    # Build and send JSON safely
    printf '%s' $prompt \
        | jq -Rs --arg model "$model" '{model: $model, messages: [{role: "user", content: .}], temperature: 0.3}' \
        | read -z json_payload

    set -l raw (curl -sS -m 30 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$json_payload" \
        "$url")

    # Extract and check error
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

function __cast_openai_complete --argument input
    set -l sys (cast_prompt complete 2>/dev/null; or echo "Complete or rewrite the following shell command. Output only the result, no explanations.")
    set -l prompt "$sys\n\n$input"
    __cast_openai_chat $prompt
end

function __cast_openai_explain --argument input
    set -l sys (cast_prompt explain 2>/dev/null; or echo "Explain the following shell command concisely.")
    set -l prompt "$sys\n\n$input"
    __cast_openai_chat $prompt
end
