# Shared HTTP + parse logic for OpenAI-compatible chat endpoints.
# Arguments: url, api_key, payload_json, debug
function __cast_chat --argument url api_key payload_json debug
    if not command -sq jq
        echo "cast: jq is required." >&2
        return 1
    end

    if test "$debug" = true
        echo "[cast debug] url: $url" >&2
        echo "[cast debug] payload: $payload_json" >&2
    end

    set -l raw (curl -sS -m 60 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "$payload_json" \
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
