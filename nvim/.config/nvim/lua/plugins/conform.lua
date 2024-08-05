local M = {
  "stevearc/conform.nvim",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" },
}

function M.config()
  local conform = require "conform"

  conform.setup {
    formatters_by_ft = {
      lua = { "stylua" },
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescriptreact = { "prettierd" },
      json = { "prettierd" },
      html = { "prettierd" },
      css = { "prettierd" },
      markdown = { "prettierd" },
      yaml = { "prettierd" },
      graphql = { "prettierd" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  }

  conform.formatters.shfmt = {
    prepend_args = { "-i", "2", "-ci" },
  }

  vim.keymap.set({ "n", "v" }, "<leader>mp", function()
    conform.format {
      lsp_fallback = true,
      async = false,
      timeout_ms = 500,
    }
  end, { desc = "Format file or range (in visual mode)" })
end

return M
