local M = {
  "williamboman/mason.nvim",
  dependencies = {
    { "williamboman/mason-lspconfig.nvim" },
    { "jay-babu/mason-null-ls.nvim" },
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

  -- download lsp servers
  local servers = require "lsp.servers"
  require("mason-lspconfig").setup {
    ensure_installed = servers,
    automatic_installation = false,
  }

  -- download formatters found in none-ls
  require("mason-null-ls").setup {
    ---@diagnostic disable-next-line: assign-type-mismatch
    ensure_installed = nil,
    automatic_installation = true,
  }
end

return M
