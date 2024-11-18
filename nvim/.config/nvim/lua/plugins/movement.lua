return {
  -------------
  -- Neoscroll
  -------------
  {
    'karb94/neoscroll.nvim',
    event = 'BufRead',
    config = function()
      require('neoscroll').setup {
        mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
        hide_cursor = true,
        stop_eof = true,
        easing_function = 'sine',
        respect_scrolloff = false,
        performance_mode = false,
      }
    end,
  },

  ---------------------------------------
  -- Flash.nvim (faster motion movement)
  ---------------------------------------
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {
      { 'f', mode = { 'n' }, function() require('flash').jump() end, desc = 'Flash Jump' },
      { 'F', mode = { 'n' }, function() require('flash').treesitter() end, desc = 'Flash Select' },
      { 'r', mode = { 'o' }, function() require('flash').remote() end, desc = 'Remote Flash' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
    },
  },
}
