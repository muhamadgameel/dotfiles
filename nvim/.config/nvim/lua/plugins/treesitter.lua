return {
  --------------
  -- Treesitter
  --------------
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'RRethy/nvim-treesitter-endwise' },
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      {
        'windwp/nvim-ts-autotag',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
          require('nvim-ts-autotag').setup {}
        end,
      },
    },
    config = function()
      local treesitter = require 'nvim-treesitter.configs'

      vim.opt.foldenable = true
      vim.opt.foldmethod = 'expr'
      vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

      treesitter.setup {
        ensure_installed = {
          'jsdoc',
          'json',
          'json5',
          'jsonc',
          'javascript',
          'typescript',
          'tsx',
          'html',
          'css',
          'lua',
          'vim',
          'vimdoc',
          'query',
          'bash',
          'python',
          'c',
          'cpp',
          'rust',
          'go',
          'toml',
          'yaml',
          'git_config',
          'gitcommit',
          'gitignore',
          'markdown',
          'markdown_inline',
          'ruby',
          'regex',
          'sql',
          'svelte',
          'graphql',
          'dockerfile',
        },
        sync_install = false,
        auto_install = false,
        highlight = {
          enable = true,
          disable = {},
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        endwise = { enable = true },

        -- Incremental selection configuration
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<CR>',
            node_incremental = '<CR>',
            node_decremental = '<BS>',
            scope_incremental = '<TAB>',
          },
        },

        -- Textobjects configuration
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              ['al'] = '@loop.outer',
              ['il'] = '@loop.inner',
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = '@class.outer',
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[['] = '@class.outer',
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[]'] = '@class.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },
        },
      }
    end,
  },
}
