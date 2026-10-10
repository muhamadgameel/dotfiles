---
name: zsh-zoxide-completion-after-compinit
description: Use when zoxide cd picker fails: initialize after compinit.
category: shell-config
---

Initialize zoxide after `compinit` runs in your zsh config, not before. zoxide registers its `cd` completion via `compdef`, which does not exist until compinit has been called. If you initialize zoxide early (e.g., in aliases.zsh), the completion silently fails to register, and `cd dir<Space><Tab>` will not open the picker.

## Implementation

Source the cached zoxide init in `init.zsh` right after the `core/completion.zsh` file runs (which calls compinit), using `cached-eval`:

```zsh
# zoxide as `cd`. After compinit, because it registers its completion through compdef.
cached-eval zoxide zoxide init zsh --cmd cd
```

Remove any earlier zoxide initialization from files like `core/aliases.zsh`.

## Why cached-eval

zoxide's init is a large bash/zsh script that runs on every shell startup. `cached-eval` writes it to a file in `~/.cache/zsh` once and sources the cache on subsequent starts, saving 2–3 ms per interactive shell.
