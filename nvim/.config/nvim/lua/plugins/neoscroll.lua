local M = {
  "karb94/neoscroll.nvim",
  event = "BufRead",
}

function M.config()
  require("neoscroll").setup {
    mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = true,
    stop_eof = true,
    easing_function = "sine",
    respect_scrolloff = false,
    performance_mode = false,
  }
end

return M
