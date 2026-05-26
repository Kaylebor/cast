function __cast_synthetic_chat --argument messages_json debug
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

    set -l payload (echo "$messages_json" | jq \
        --arg model "$model" \
        --arg reasoning_effort "$reasoning_effort" \
        '{model: $model, messages: .messages, temperature: 0.3, reasoning_effort: $reasoning_effort}')

    __cast_chat "$url" "$SYNTHETIC_API_KEY" "$payload" "$debug"
end
