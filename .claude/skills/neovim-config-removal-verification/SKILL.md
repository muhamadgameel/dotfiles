---
name: neovim-config-removal-verification
description: Use when removing Neovim config: state dump verifies no-ops.
category: testing
---

**Before removing:** Measure impact of what you're about to delete. Create two XDG_CONFIG_HOME scratch copies, one with the config as-is (control), one with the item removed. Run 20 headless start-ups on each with `--startuptime`, interleaved, to detect real change vs. noise; startup time jitter on a balanced profile is ~2 ms. If the setting is claimed to enable a feature (colours, codelens, hints), test it still works post-removal: in a scratch buffer with appropriate ft, trigger the feature and compare state before/after. For deprecated options, run `:checkhealth vim.deprecated` before and after. Keep the original claim and measurement in commit notes; a removal of a "no-op" that costs 5ms startup or breaks a feature is a second bug.

**After removal:** Dump comprehensive state before the change: plugin count and names, available commands, LSP servers with their resolved configs and binaries, mason tools installed, autocmd groups and patterns, and exit cursor state. After the change, rerun the same dump and diff. For filetypes affected by the removal (find them with `grep` and `find`), verify the corpus detects correctly: headless Neovim with `-i NONE`, `swapfile` off, `eventignore=FileType`, then per-file `noautocmd edit` + `doautocmd filetypedetect BufRead` to read `vim.bo.filetype`. Test exit cursor in a pty, raw terminal, no shell. Run lint. The before/after diff should show only the exact elements you removed—no cascading effects.

See [[zsh-interactive-testing]] for the pty harness and state-dump scripts. Use headless and `--cmd`/`-c` flags to disable modules or autocmd groups without editing files.