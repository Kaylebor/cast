# cast initialization
# Runs on every shell startup for prompt autogen.
# _cast_install / _cast_update / _cast_uninstall are Fisher event hooks.

# --- .gitignore block management ---
function __cast_gitignore_remove --description "Remove the cast block from .gitignore"
    set -l gitignore $__fish_config_dir/.gitignore
    if not test -f $gitignore
        return
    end
    sed -i '' '/# >>> cast managed/,/# <<< cast managed/d' $gitignore 2>/dev/null
    or sed -i '/# >>> cast managed/,/# <<< cast managed/d' $gitignore 2>/dev/null
end

function __cast_gitignore_sync --description "Ensure cast block in .gitignore is current"
    set -l gitignore $__fish_config_dir/.gitignore
    if not test -f $gitignore
        return
    end

    set -l block_start "# >>> cast managed"
    set -l block_body "conf.d/cast_init.fish
conf.d/cast_user_keybinds.fish
functions/__cast_*.fish
functions/cast_complete.fish
functions/cast_explain.fish
functions/cast_codify.fish
functions/cast_prompt.fish
functions/__cast_openai_compat_chat.fish
functions/prompts/
cast/prompts/
functions/_cast_user_*.fish"
    set -l block_end "# <<< cast managed"

    # If old block exists, remove it (range delete: start through end)
    if grep -qF $block_start $gitignore 2>/dev/null
        sed -i '' '/# >>> cast managed/,/# <<< cast managed/d' $gitignore 2>/dev/null
        or sed -i '/# >>> cast managed/,/# <<< cast managed/d' $gitignore 2>/dev/null
    end

    # Ensure file ends with a single newline before appending
    set -l last (tail -c 1 $gitignore | string collect -N)
    if not string match -q "\n" -- $last
        printf '\n' >>$gitignore
    end

    # Append block as raw text
    printf '%s\n%s\n%s\n' $block_start $block_body $block_end >>$gitignore
end

# --- Install: templates, defaults, .gitignore sync ---
function _cast_install --on-event cast_init_install
    set -l user_dir $__fish_config_dir/cast/prompts
    test -d $user_dir; or mkdir -p $user_dir

    set -l template_complete $__fish_config_dir/functions/_cast_user_complete.fish
    if not test -f $template_complete
        echo '# cast default completion provider
# You own this file; cast will never overwrite it.
# Swap __cast_openai_complete for any other built-in or your own function.

function _cast_user_complete --argument input
    __cast_openai_complete $input
end' >$template_complete
    end

    set -l template_explain $__fish_config_dir/functions/_cast_user_explain.fish
    if not test -f $template_explain
        echo '# cast default explanation provider
# You own this file; cast will never overwrite it.

function _cast_user_explain --argument input
    __cast_openai_explain $input
end' >$template_explain
    end

    set -l keybinds $__fish_config_dir/conf.d/cast_user_keybinds.fish
    if not test -f $keybinds
        printf '%s\n' '# cast user keybinds' \
            '# You own this file; cast will never overwrite it.' \
            '# Change the bindings below or remove this file entirely.' \
            '' \
            'status is-interactive; and begin' \
            "    bind \\cp '__cast_keybind_complete'" \
            "    bind \\ce '__cast_keybind_explain'" \
            'end' >$keybinds
    end

    __cast_gitignore_sync

    set -q cast_complete_provider; or set -U cast_complete_provider _cast_user_complete
    set -q cast_explain_provider;  or set -U cast_explain_provider _cast_user_explain

    echo "cast: installed. Set OPENAI_API_KEY or configure a custom provider. See https://github.com/Kaylebor/cast#setup"
end

# --- Update: sync .gitignore only, then notify ---
function _cast_update --on-event cast_init_update
    __cast_gitignore_sync
    echo "cast: updated. Review provider changes at https://github.com/Kaylebor/cast"
end

# --- Uninstall: remove block, erase universal variables ---
function _cast_uninstall --on-event cast_init_uninstall
    __cast_gitignore_remove
    set -e cast_complete_provider 2>/dev/null
    set -e cast_explain_provider 2>/dev/null
    # Intentionally NOT removing user-created files under functions/ or cast/prompts/
end

# --- Canonical provider builders ---
function __cast_openai --description "OpenAI-compatible API transport"
    # Arguments: messages_json debug
    set -q OPENAI_API_KEY; or begin
        echo "cast: OPENAI_API_KEY is not set." >&2
        return 1
    end
    set -l api_base (set -q OPENAI_API_BASE; and echo $OPENAI_API_BASE; or echo "api.openai.com")
    set -l model  (set -q OPENAI_MODEL;   and echo $OPENAI_MODEL;   or echo "gpt-4o-mini")
    set api_base (string replace -r '/$' '' -- $api_base)
    set -l payload (echo "$argv[1]" | jq --arg model "$model" '{model: $model, messages: .messages, temperature: 0.3}')
    __cast_openai_compat_chat "https://$api_base/v1/chat/completions" "$OPENAI_API_KEY" "$payload" "$argv[2]"
end

function __cast_synthetic --description "Synthetic API transport"
    set -q SYNTHETIC_API_KEY; or begin
        echo "cast: SYNTHETIC_API_KEY is not set." >&2
        return 1
    end
    set -l api_base (set -q SYNTHETIC_API_BASE; and echo $SYNTHETIC_API_BASE; or echo "api.synthetic.new/openai")
    set -l model    (set -q SYNTHETIC_MODEL;    and echo $SYNTHETIC_MODEL;    or echo "hf:zai-org/GLM-4.7-Flash")
    set -l reasoning_effort (set -q SYNTHETIC_REASONING_EFFORT; and echo $SYNTHETIC_REASONING_EFFORT; or echo "low")
    set api_base (string replace -r '/$' '' -- $api_base)
    set -l payload (echo "$argv[1]" | jq --arg model "$model" --arg reasoning_effort "$reasoning_effort" '{model: $model, messages: .messages, temperature: 0.3, reasoning_effort: $reasoning_effort}')
    __cast_openai_compat_chat "https://$api_base/v1/chat/completions" "$SYNTHETIC_API_KEY" "$payload" "$argv[2]"
end

# --- Every-init: prompt autogeneration ---
function __cast_init_prompts --description "Generate prompt accessor functions from .md files"
    set -l builtin_dir (path dirname (status -f))/../functions/prompts
    set -l user_dir $__fish_config_dir/cast/prompts
    test -d $user_dir; or mkdir -p $user_dir
    if test -d $builtin_dir
        for md in $builtin_dir/*.md
            set -l name (basename $md .md)
            eval "function __cast_prompt_$name; cat $md; end"
        end
    end
    if test -d $user_dir
        for md in $user_dir/*.md
            set -l name (basename $md .md)
            eval "function __cast_prompt_$name; cat $md; end"
        end
    end
end

__cast_init_prompts
