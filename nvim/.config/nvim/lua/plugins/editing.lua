return {
  ----------------
  -- Surround
  ----------------
  {
    'kylechui/nvim-surround',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('nvim-surround').setup {}
    end,
  },

  ----------------------
  -- Toggler && Cycling
  ----------------------
  {
    'nat-418/boole.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('boole').setup {
        mappings = {
          increment = '+',
          decrement = '-',
        },
        additions = {
          { 'error', 'warn' },
          { 'up', 'down' },
          { 'top', 'right', 'bottom', 'left' },
        },
      }
    end,
  },

  --------------
  -- Auto pairs
  --------------
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup {
        check_ts = true,
        disable_filetype = { 'TelescopePrompt', 'spectre_panel', 'vim' },
      }
    end,
  },

  ---------------------------------------
  -- Flash.nvim (faster motion movement)
  ---------------------------------------
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        search = {
          enabled = true,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
    },
  },
}
