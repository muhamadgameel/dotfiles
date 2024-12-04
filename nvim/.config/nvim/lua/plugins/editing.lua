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
        allow_caps_additions = {
          { 'error', 'warn' },
          { 'up', 'down' },
          { 'top', 'right', 'bottom', 'left' },
        },
        additions = {},
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

  ------------
  -- Comments
  ------------
  {
    'numToStr/Comment.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      require('ts_context_commentstring').setup {
        enable = true,
        enable_autocmd = false,
      }

      vim.g.skip_ts_context_commentstring_module = true

      require('Comment').setup {
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  },

  -----------------
  -- Todo Comments
  -----------------
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    config = function()
      local todo_comments = require 'todo-comments'

      todo_comments.setup {
        highlight = {
          pattern = [[.*<(KEYWORDS)\s*:?]],
        },
        search = {
          command = 'rg',
          args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--hidden',
            '--glob=!.git/',
          },
          pattern = [[\b(KEYWORDS):?]],
        },
      }
      vim.keymap.set('n', ']t', todo_comments.jump_next, { desc = 'Jump to next todo comment' })
      vim.keymap.set('n', '[t', todo_comments.jump_prev, { desc = 'Jump to previous todo comment' })
    end,
  },
}
