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
}
