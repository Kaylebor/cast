# cast

Fish-native AI completion — pure Fish, zero Python, no hardcoded providers.

Inspired by [`Realiserad/fish-ai`](https://github.com/Realiserad/fish-ai). `cast` takes a different approach:

- **Interface-first**: the plugin never calls an LLM directly. You configure one shell variable pointing to your own Fish function.
- **Pure Fish**: no Python dependency. The built-in helper uses `curl` and `jq`.
- **Transparent**: prompts are plain `.md` files. You can override or extend them.

## Install

```fish
fisher install Kaylebor/cast
```

After installing, reload your shell or run `exec fish`.

## Setup

On first install, `cast` creates two template provider functions for you:

- `~/.config/fish/functions/_cast_user_complete.fish`
- `~/.config/fish/functions/_cast_user_explain.fish`

Add to your `config.fish`:

```fish
# Your OpenAI-compatible API key
set -gx OPENAI_API_KEY sk-...

# Optional: point to a different provider (e.g. local Ollama, Azure, etc.)
# set -gx OPENAI_API_BASE localhost:11434
# set -gx OPENAI_MODEL llama3.2

# Tell cast which functions to use
set -g cast_complete_provider _cast_user_complete
set -g cast_explain_provider  _cast_user_explain

# Optional: bind keys
bind \cp '__cast_keybind_complete'
bind \ce '__cast_keybind_explain'
```

Reload your shell.

## Use

| Feature | Default bind | Behaviour |
|---------|--------------|-----------|
| **Complete / Rewrite** | none — see Setup | Overwrites the current command line with the LLM result |
| **Explain** | none | Prints an explanation of the current command |

## How it works

### The interface

`cast` expects two named functions:

```fish
function cast_complete
    # Receives the current buffer as $argv[1]
    # Prints ONLY the replacement command to stdout
end

function cast_explain
    # Receives the current buffer as $argv[1]
    # Prints ONLY the explanation to stdout
end
```

The user controls which concrete functions implement this interface via:

```fish
set -g cast_complete_provider my_custom_function
```

This lets you swap providers on the fly, chain logic, or implement features like a "rotation" keybind that cycles `$cast_complete_provider` through a list of backends.

### Prompts

Prompts are plain `.md` files. Built-ins live inside the plugin at `functions/prompts/`.

You can shadow or extend prompts by dropping files in:

```
~/.config/fish/cast/prompts/
```

Any `*.md` there becomes callable as:

```fish
(cast_prompt my_prompt_name)
```

Example custom prompt:

```fish
# ~/.config/fish/cast/prompts/fix.md
Rewrite the following broken command to fix the likely mistake.
Output only the corrected command.

Command: ___
```

### Built-in provider helpers

`__cast_openai_complete` and `__cast_openai_explain` are shipped as a default `curl`+`jq` implementation. You can also write your own:

```fish
function _my_ollama_complete --argument input
    set -l prompt "Rewrite: $input"
    curl -s http://localhost:11434/api/generate \
        -d "{\"model\":\"llama3.2\",\"prompt\":\"$prompt\",\"stream\":false}" \
    | jq -r '.response'
end
```

Then `set -g cast_complete_provider _my_ollama_complete`.

## Configuration reference

| Variable | Default | Purpose |
|----------|---------|---------|
| `$cast_complete_provider` | `_cast_user_complete` | Function name for completion |
| `$cast_explain_provider` | `_cast_user_explain` | Function name for explanation |
| `$OPENAI_API_KEY` | — | Required for built-in OpenAI helper |
| `$OPENAI_API_BASE` | `api.openai.com` | Base URL for HTTP calls |
| `$OPENAI_MODEL` | `gpt-4o-mini` | Model identifier |

## Keybind helpers

`cast` deliberately does **not** set any keybinds automatically. We provide thin wrappers you can bind yourself:

```fish
bind \cp '__cast_keybind_complete'
bind \ce '__cast_keybind_explain'
```

Or build your own:

```fish
function my_custom_bind
    set -l buf (commandline -b)
    set -l result (cast_complete $buf 2>/dev/null)
    if test $status -eq 0
        commandline -r -- $result
    end
end
bind \cx my_custom_bind
```

## Updating

```fish
fisher update Kaylebor/cast
```

`cast` never overwrites your `_cast_user_*.fish` files. New plugin versions may add more `__cast_` helper functions; existing user overrides remain untouched.

If `.gitignore` exists in your `~/.config/fish/`, `cast` appends entries once to keep generated files out of your dotfiles repo.

## Troubleshooting

**"Provider failed"**
Run the provider function directly to see its raw output, then check your API key or network.

**"jq required"**
The built-in OpenAI helper needs `jq`. Install it, or supply your own provider function that doesn't use it.

## License

MIT
