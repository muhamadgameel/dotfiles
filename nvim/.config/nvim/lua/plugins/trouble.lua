local M = {
  "folke/trouble.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
}

function M.config()
  local trouble = require "trouble"
  require("trouble").setup { use_diagnostic_signs = true }

  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }

  keymap("n", "<leader>xx", function()
    trouble.toggle()
  end, opts)
  keymap("n", "<leader>xw", function()
    trouble.toggle "workspace_diagnostics"
  end, opts)
  keymap("n", "<leader>xd", function()
    trouble.toggle "document_diagnostics"
  end, opts)
  keymap("n", "<leader>xq", function()
    trouble.toggle "quickfix"
  end, opts)
  keymap("n", "<leader>xl", function()
    trouble.toggle "loclist"
  end, opts)
  keymap("n", "gR", function()
    trouble.toggle "lsp_references"
  end, opts)
end

return M
