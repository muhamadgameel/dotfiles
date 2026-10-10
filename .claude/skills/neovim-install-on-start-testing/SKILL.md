---
name: neovim-install-on-start-testing
description: "When testing treesitter: use scratch XDG_CONFIG_HOME."
category: testing
---

Plugins that install on every start (nvim-treesitter's `install(languages)`, mason-tool-installer's tool list) run at config load time. Testing by editing the list in the real config and starting will install to `~/.local/share/nvim`. Isolate this with scratch directories: seed `XDG_CONFIG_HOME` from `git archive HEAD nvim/.config/nvim` and set `XDG_CACHE_HOME` to scratch to avoid pollution of real data and cache folders.

Alternatively, replace auto-install with `require('nvim-treesitter').setup { install_dir = '<scratch>' }` during testing.