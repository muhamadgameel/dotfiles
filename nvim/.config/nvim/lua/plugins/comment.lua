local M = {
  "numToStr/Comment.nvim",
  lazy = true,
  event = { "BufRead", "BufNewFile" },
  dependencies = {
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      event = "VeryLazy",
    },
  },
}

function M.config()
  require("ts_context_commentstring").setup {
    enable = true,
    enable_autocmd = false,
  }

  vim.g.skip_ts_context_commentstring_module = true

  require("Comment").setup {
    pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
  }
end

return M
