-- Monorepos work out of the box: nvim-lspconfig roots the server at the nearest
-- lockfile and the server resolves a config per file, so no workingDirectories
-- tuning is needed here.
--
-- NOTE: no on_attach here on purpose. It would replace the one in
-- nvim-lspconfig's lsp/eslint.lua, which creates the LspEslintFixAll command.
-- The fix-on-save autocmd lives in the LspAttach handler in plugins/lsp.lua
-- instead.
return {
  settings = {
    format = false, -- prettierd (via conform) owns formatting
  },
}
