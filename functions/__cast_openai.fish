function __cast_openai_chat --argument messages_json debug
    set -q OPENAI_API_KEY; or begin
        echo "cast: OPENAI_API_KEY is not set." >&2
        return 1
    end

    set -l api_base (set -q OPENAI_API_BASE; and echo $OPENAI_API_BASE; or echo "api.openai.com")
    set -l model (set -q OPENAI_MODEL; and echo $OPENAI_MODEL; or echo "gpt-4o-mini")

    set api_base (string replace -r '/$' '' -- $api_base)
    set -l url "https://$api_base/v1/chat/completions"

    if not command -sq jq
        echo "cast: jq is required for the built-in OpenAI provider." >&2
        return 1
    end

    set -l payload (echo "$messages_json" | jq \
        --arg model "$model" \
        '{model: $model, messages: .messages, temperature: 0.3}')

    __cast_chat "$url" "$OPENAI_API_KEY" "$payload" "$debug"
end

function __cast_openai_complete
    set -l messages $argv[1]
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]
    __cast_openai_chat "$messages" "$debug"
end

function __cast_openai_explain
    set -l messages $argv[1]
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]
    __cast_openai_chat "$messages" "$debug"
end

function __cast_openai_codify
    set -l messages $argv[1]
    set -l debug false
    test (count $argv) -ge 2; and set debug $argv[2]
    __cast_openai_chat "$messages" "$debug"
end
