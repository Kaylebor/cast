# cast initialization
# Runs on every shell startup for prompt autogen.
# _cast_install / _cast_update / _cast_uninstall are Fisher event hooks.

# --- Shared utilities for .gitignore block management ---
function __cast_gitignore_remove --description "Remove the cast ignore block from ~/.config/fish/.gitignore"
    set -l gitignore $__fish_config_dir/.gitignore
    if not test -f $gitignore
        return
    end

    set -l block_start "# >>> cast managed"
    set -l block_end   "# <<< cast managed"

    set -l has_start (grep -n -F $block_start $gitignore 2>/dev/null | head -1)
    set -l has_end   (grep -n -F $block_end   $gitignore 2>/dev/null | head -1)

    if test -z "$has_start" -o -z "$has_end"
        return
    end

    set -l start_line (echo $has_start | cut -d: -f1)
    set -l end_line   (echo $has_end   | cut -d: -f1)

    sed -i '' "$start_line,${end_line}d" $gitignore 2>/dev/null
        ; or sed -i "$start_line,${end_line}d" $gitignore 2>/dev/null
end

function __cast_gitignore_sync --description "Synchronize the cast ignore block in ~/.config/fish/.gitignore"
    set -l gitignore $__fish_config_dir/.gitignore
    if not test -f $gitignore
        return
    end

    set -l block_start "# >>> cast managed"
    set -l block_end   "# <<< cast managed"

    set -l block \
        $block_start \
        "conf.d/cast_init.fish" \
        "functions/__cast_*.fish" \
        "functions/cast_complete.fish" \
        "functions/cast_explain.fish" \
        "functions/cast_prompt.fish" \
        "functions/prompts/" \
        "cast/prompts/" \
        "functions/_cast_user_*.fish" \
        $block_end

    # Check if block already exists by start+end delimiter
    set -l has_start (grep -n -F $block_start $gitignore 2>/dev/null | head -1)
    set -l has_end   (grep -n -F $block_end   $gitignore 2>/dev/null | head -1)

    if test -n "$has_start" -a -n "$has_end"
        # Block exists: extract current content between delimiters
        set -l start_line (echo $has_start | cut -d: -f1)
        set -l end_line   (echo $has_end   | cut -d: -f1)

        # Read existing lines (excluding delimiters)
        set -l existing (sed -n (math "$start_line + 1")","(math "$end_line - 1")"p" $gitignore 2>/dev/null)

        # Compare with expected block (excluding delimiters)
        set -l expected (printf '%s\n' $block[2..-2])
        if test "$existing" = "$expected"
            # Block matches — nothing to do
            return
        end

        # Block mismatched — replace it
        # Delete old block (start through end line)
        sed -i '' "$start_line,${end_line}d" $gitignore 2>/dev/null
            ; or sed -i "$start_line,${end_line}d" $gitignore 2>/dev/null
    end

    # Ensure trailing newline before appending
    set -l last (tail -c 1 $gitignore | string collect -N)
    if not string match -q "\n" -- $last
        printf '\n' >>$gitignore
    end

    # Append block
    for line in $block
        printf '%s\n' $line >>$gitignore
    end
end

# --- Install-time: create templates, set provider defaults, sync .gitignore ---
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

    __cast_gitignore_sync

    set -q cast_complete_provider; or set -U cast_complete_provider _cast_user_complete
    set -q cast_explain_provider;  or set -U cast_explain_provider _cast_user_explain

    echo "cast: installed. Set OPENAI_API_KEY or configure a custom provider. See https://github.com/Kaylebor/cast#setup"
end

# --- Update-time: sync .gitignore block, notify only ---
function _cast_update --on-event cast_update
    __cast_gitignore_sync
    echo "cast: updated. Review provider interface changes at https://github.com/Kaylebor/cast"
end

# --- Uninstall-time: remove .gitignore block, erase universal variables ---
function _cast_uninstall --on-event cast_uninstall
    __cast_gitignore_remove
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
