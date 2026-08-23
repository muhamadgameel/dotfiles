-- Monorepos work out of the box: nvim-lspconfig roots the server at the nearest
-- lockfile and the server resolves a config per file, so no workingDirectories
-- tuning is needed here.
--
-- NOTE: no on_attach here on purpose. nvim-lspconfig's own lsp/eslint.lua
-- defines one (it creates the LspEslintFixAll command), and re-applying a user
-- on_attach that chains to it would recurse. The fix-on-save autocmd lives in
-- the LspAttach handler in plugins/lsp.lua instead.
return {
  settings = {
    format = false, -- prettierd (via conform) owns formatting
  },
}
