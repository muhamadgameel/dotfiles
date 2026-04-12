return {
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  event = 'VeryLazy',
  config = function()
    local hooks = require 'ibl.hooks'
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      local bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
      local r = math.floor(bg / 65536) % 256
      local g = math.floor(bg / 256) % 256
      local b = bg % 256
      local shift = vim.o.background == 'dark' and 12 or -12
      local clamp = function(v) return math.max(0, math.min(255, v + shift)) end
      vim.api.nvim_set_hl(0, 'IblIndentLight', { fg = string.format('#%02x%02x%02x', clamp(r), clamp(g), clamp(b)) })
    end)

    require('ibl').setup {
      indent = { char = '│', highlight = 'IblIndentLight' },
      scope = { enabled = true, show_start = false, show_end = false },
    }
  end,
}