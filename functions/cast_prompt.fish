function cast_prompt --argument name --description "Return the content of a named prompt"
    set -l fn "__cast_prompt_$name"
    if not functions --query $fn
        echo "cast: unknown prompt '$name'. Built-ins and user prompts are loaded from *.md files." >&2
        return 1
    end
    $fn
end
