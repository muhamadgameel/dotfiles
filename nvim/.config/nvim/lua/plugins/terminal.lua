return {
  'akinsho/toggleterm.nvim',
  event = 'VeryLazy',
  config = function()
    require('toggleterm').setup {
      open_mapping = [[\]],
      direction = 'float',
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      close_on_exit = true,
      float_opts = {
        border = 'curved',
        highlights = {
          border = 'Normal',
          background = 'Normal',
        },
      },
    }

    local Terminal = require('toggleterm.terminal').Terminal

    -- Lazy Git
    local lazygit = Terminal:new {
      cmd = 'lazygit',
      count = 5,
      float_opts = { border = 'double' },
    }
    vim.keymap.set('n', '<leader>tg', function()
      lazygit:toggle()
    end, { noremap = true, silent = true })
  end,
}
