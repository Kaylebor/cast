# cast initialization
# Runs on every interactive Fish shell startup after fisher install/update.

function __cast_init_prompts --description "Generate prompt accessor functions from .md files"
    set -l builtin_dir (path dirname (status -f))/../functions/prompts
    set -l user_dir $__fish_config_dir/cast/prompts

    if not test -d $user_dir
        mkdir -p $user_dir
    end

    # Built-in prompts (lowest priority)
    if test -d $builtin_dir
        for md in $builtin_dir/*.md
            set -l name (basename $md .md)
            eval "function __cast_prompt_$name; cat $md; end"
        end
    end

    # User prompts (override built-ins by same name)
    if test -d $user_dir
        for md in $user_dir/*.md
            set -l name (basename $md .md)
            eval "function __cast_prompt_$name; cat $md; end"
        end
    end
end

function __cast_init_template --description "Install default user provider template once"
    set -l template_complete $__fish_config_dir/functions/_cast_user_complete.fish
    if not test -f $template_complete
        echo '# cast default completion provider' >$template_complete
        echo '# You own this file; it will never be overwritten by cast updates.' >>$template_complete
        echo '# Change __cast_openai_complete to your own function or a different built-in provider.' >>$template_complete
        echo '' >>$template_complete
        echo 'function _cast_user_complete --argument input' >>$template_complete
        echo '    __cast_openai_complete $input' >>$template_complete
        echo 'end' >>$template_complete
    end

    set -l template_explain $__fish_config_dir/functions/_cast_user_explain.fish
    if not test -f $template_explain
        echo '# cast default explanation provider' >$template_explain
        echo '# You own this file; it will never be overwritten by cast updates.' >>$template_explain
        echo '' >>$template_explain
        echo 'function _cast_user_explain --argument input' >>$template_explain
        echo '    __cast_openai_explain $input' >>$template_explain
        echo 'end' >>$template_explain
    end
end

function __cast_init_gitignore --description "Add cast entries to .gitignore if present"
    set -l gitignore $__fish_config_dir/.gitignore
    if not test -f $gitignore
        return
    end

    set -l lines "cast/prompts/" "functions/_cast_user_*.fish"
    for line in $lines
        if not grep -qxF $line $gitignore 2>/dev/null
            echo $line >>$gitignore
        end
    end
end

set -q cast_initialized; and return

__cast_init_prompts
__cast_init_template
__cast_init_gitignore

# Set default provider variable if not yet configured by user
set -q cast_complete_provider; or begin
    if functions --query _cast_user_complete
        set -g cast_complete_provider _cast_user_complete
    end
end

set -q cast_explain_provider; or begin
    if functions --query _cast_user_explain
        set -g cast_explain_provider _cast_user_explain
    end
end

set -g cast_initialized 1
