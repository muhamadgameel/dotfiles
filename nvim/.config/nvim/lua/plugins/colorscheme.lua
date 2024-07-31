local M = {
  "Mofiqul/dracula.nvim",
  lazy = false,
  priority = 1000,
}

function M.config()
  vim.cmd.colorscheme "dracula"
end

return M
