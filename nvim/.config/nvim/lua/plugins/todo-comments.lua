local M = {
  "folke/todo-comments.nvim",
  dependencies = {
    { "BurntSushi/ripgrep" },
    { "nvim-lua/plenary.nvim" },
  },
}

function M.config()
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }

  local todo_comments = require "todo-comments"

  todo_comments.setup {
    highlight = {
      pattern = [[.*<(KEYWORDS)\s*:?]],
    },
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--hidden",
        "--glob=!.git/",
      },
      pattern = [[\b(KEYWORDS):?]],
    },
  }

  keymap("n", "]t", todo_comments.jump_next, opts)
  keymap("n", "[t", todo_comments.jump_prev, opts)

  local trouble_require_ok = pcall(require, "trouble")
  if trouble_require_ok then
    keymap("n", "<leader>xt", "<cmd>TodoTrouble<cr>", opts)
  end

  local telescope_require_ok = pcall(require, "telescope")
  if telescope_require_ok then
    keymap("n", "<leader>ot", "<cmd>TodoTelescope<cr>", opts)
  end
end

return M
