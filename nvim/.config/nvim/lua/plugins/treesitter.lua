local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  dependencies = {
    { "windwp/nvim-ts-autotag" },
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      event = "VeryLazy",
    },
  },
}

function M.config()
  local configs = require "nvim-treesitter.configs"

  ---@diagnostic disable-next-line: missing-fields
  configs.setup {
    ensure_installed = "all",
    sync_install = false,
    auto_install = false,
    highlight = {
      enable = true,
      disable = {},
      additional_vim_regex_highlighting = false,
    },
    autotag = { enable = true },
    indent = { enable = true },
  }
end

return M
