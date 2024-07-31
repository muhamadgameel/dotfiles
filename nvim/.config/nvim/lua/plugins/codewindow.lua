local M = {
  "gorbit99/codewindow.nvim",
  lazy = true,
  event = { "BufRead", "BufNewFile" },
}

function M.config()
  local codewindow = require "codewindow"
  codewindow.setup {
    auto_enable = true,
    width_multiplier = 2,
    show_cursor = false,
    screen_bounds = "background",
    window_border = "none",
  }
  codewindow.apply_default_keybinds()
end

return M
