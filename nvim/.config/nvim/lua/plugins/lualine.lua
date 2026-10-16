return {
  'nvim-lualine/lualine.nvim',
  lazy = false,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local lualine = require 'lualine'
    local lazy_status = require 'lazy.status'

    lualine.setup {
      options = {
        refresh = {
          statusline = 200,
          tabline = 500,
          winbar = 300,
        },
      },
      sections = {
        lualine_a = { { 'mode', icon = '' } },
        lualine_b = {
          { 'branch', icon = { '' } },
          {
            'diff',
            symbols = { added = ' ', modified = ' ', removed = ' ' },
          },
        },
        lualine_c = { { 'diagnostics' } },

        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = 'orange' },
          },
          { 'fileformat' },
        },
        lualine_y = { { 'filetype' } },
        lualine_z = { { 'progress' } },
      },
      extensions = {
        'oil',
        'quickfix',
        'trouble',
        'man',
        'mason',
        'lazy',
      },
    }
  end,
}
