local M = {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    event = "VeryLazy",
  },
}

function M.config()
  local icons = require "icons"

  require("lualine").setup {
    options = {
      theme = "auto",
      component_separators = { left = icons.ui.DividerRight, right = icons.ui.DividerLeft },
      section_separators = { left = icons.ui.BoldDividerRight, right = icons.ui.BoldDividerLeft },
      ignore_focus = { "NvimTree" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { require("auto-session.lib").current_session_name, "branch", "diff" }, -- TODO should disable first item when auto-session is not avaiable
      lualine_c = { "diagnostics" },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "" },
    },
    extensions = { "quickfix", "trouble", "man", "mason", "lazy", "fugitive" },
  }
end

return M
