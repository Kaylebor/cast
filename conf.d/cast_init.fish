# cast initialization
# Runs on every shell startup for prompt autogen.
# _cast_install handles one-time setup when Fisher emits the event.

# --- Install-time: create templates, gitignore, provider defaults ---
function _cast_install --on-event cast_install
    set -l user_dir $__fish_config_dir/cast/prompts
    if not test -d $user_dir
        mkdir -p $user_dir
    end

    set -l template_complete $__fish_config_dir/functions/_cast_user_complete.fish
    if not test -f $template_complete
        echo '# cast default completion provider' >$template_complete
        echo '# You own this file; cast will never overwrite it.' >>$template_complete
        echo '# Swap __cast_openai_complete for any other built-in or your own function.' >>$template_complete
        echo '' >>$template_complete
        echo 'function _cast_user_complete --argument input' >>$template_complete
        echo '    __cast_openai_complete $input' >>$template_complete
        echo 'end' >>$template_complete
    end

    set -l template_explain $__fish_config_dir/functions/_cast_user_explain.fish
    if not test -f $template_explain
        echo '# cast default explanation provider' >$template_explain
        echo '# You own this file; cast will never overwrite it.' >>$template_explain
        echo '' >>$template_explain
        echo 'function _cast_user_explain --argument input' >>$template_explain
        echo '    __cast_openai_explain $input' >>$template_explain
        echo 'end' >>$template_explain
    end

    # .gitignore hygiene (newline guard)
    set -l gitignore $__fish_config_dir/.gitignore
    if test -f $gitignore
        set -l last (tail -c 1 $gitignore | string collect -N)
        if not string match -q "\n" -- $last
            printf '\n' >>$gitignore
        end

        set -l lines "cast/prompts/" "functions/_cast_user_*.fish"
        for line in $lines
            if not grep -qxF $line $gitignore 2>/dev/null
                printf '%s\n' $line >>$gitignore
            end
        end
    end

    # Set universal provider defaults only if not already configured
    set -q cast_complete_provider; or set -U cast_complete_provider _cast_user_complete
    set -q cast_explain_provider;  or set -U cast_explain_provider _cast_user_explain

    echo "cast: installed. Set OPENAI_API_KEY or configure a custom provider. See https://github.com/Kaylebor/cast#setup"
end

# --- Update-time: notify only ---
function _cast_update --on-event cast_update
    echo "cast: updated. Review provider interface changes at https://github.com/Kaylebor/cast"
end

# --- Uninstall-time: erase universal variables ---
function _cast_uninstall --on-event cast_uninstall
    set -e cast_complete_provider 2>/dev/null
    set -e cast_explain_provider 2>/dev/null
    # Intentionally NOT removing user-created files under functions/ or cast/prompts/
end

# --- Every-init: prompt autogeneration ---
# User can drop new .md files anytime; we regenerate accessors on shell startup.
function __cast_init_prompts --description "Generate prompt accessor functions from .md files"
    set -l builtin_dir (path dirname (status -f))/../functions/prompts
    set -l user_dir $__fish_config_dir/cast/prompts

    if not test -d $user_dir
        mkdir -p $user_dir
    end

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
