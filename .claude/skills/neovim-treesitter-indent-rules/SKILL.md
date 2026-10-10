---
name: neovim-treesitter-indent-rules
description: "Treesitter indentexpr: only when parser has indent rules."
category: nvim-config
---

Guard the indentexpr assignment with a check for indent rules. Parsers lacking indent rules (golang, lua, qml, vim script, etc.) must fall back to Vim's built-in indent scripts:

```lua
if vim.treesitter.query.get(language, 'indents') then
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end
```

Without this guard, a new line under a block opener gets no indentation at all. Lua, QML, and Vim script had this bug in the config before adding new parsers; the guard prevents it for future additions.