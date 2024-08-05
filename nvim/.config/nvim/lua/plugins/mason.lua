local M = {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
}

function M.config()
  require("mason").setup {
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  }

  require("mason-lspconfig").setup {}

  require("mason-tool-installer").setup {
    ensure_installed = {
      -- LSP
      "lua-language-server",
      "css-lsp",
      "html-lsp",
      "json-lsp",
      "typescript-language-server",
      "eslint-lsp",
      "bash-language-server",

      -- Linters
      "shellcheck", -- shell scripts
      "eslint_d",

      -- Formatters
      "prettierd",
      "stylua", -- lua
      "shfmt", -- shell script
    },
  }
end

return M
