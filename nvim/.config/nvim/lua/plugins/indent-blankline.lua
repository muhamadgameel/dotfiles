return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = 'VeryLazy',
  config = function()
    local hooks = require 'ibl.hooks'
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, 'IndentLine', { fg = '#22262D' })
    end)

    require('ibl').setup {
      indent = { highlight = { 'IndentLine' } },
      scope = { enabled = false },
    }
  end,
}
