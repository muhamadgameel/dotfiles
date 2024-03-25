local M = {
  "karb94/neoscroll.nvim",
}

function M.config()
  require("neoscroll").setup {
    mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = true,
    easing_function = "sine",
    respect_scrolloff = false,
  }
end

return M
