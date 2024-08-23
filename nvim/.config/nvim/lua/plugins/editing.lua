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

  -----------------------------------
  -- JS/TS template string converter
  -----------------------------------
  {
    'axelvc/template-string.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('template-string').setup {
        filetypes = {
          'html',
          'typescript',
          'javascript',
          'typescriptreact',
          'javascriptreact',
          'vue',
          'svelte',
          'python',
        },
        jsx_brackets = true,
        remove_template_string = true,
        restore_quotes = {
          normal = [[']],
          jsx = [["]],
        },
      }
    end,
  },
}
