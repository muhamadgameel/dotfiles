return {
  --------------
  -- Treesitter
  --------------
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      { 'RRethy/nvim-treesitter-endwise' },
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      config = function()
        local configs = require 'nvim-treesitter.configs'

        vim.opt.foldmethod = 'expr'
        vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        configs.setup {
          ensure_installed = {
            'tsx',
            'html',
            'css',
            'jsdoc',
            'json',
            'json5',
            'jsonc',
            'javascript',
            'typescript',
            'tsx',
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
            'sql',
            'regex',
            'latex',
          },
          sync_install = false,
          auto_install = true,
          highlight = {
            enable = true,
            disable = {},
            additional_vim_regex_highlighting = false,
          },
          autotag = { enable = true },
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
  },

  -----------
  -- Autotag
  -----------
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('nvim-ts-autotag').setup {}
    end,
  },

  ---------------------------------------------
  -- TreeSJ (splitting/joining blocks of code)
  ---------------------------------------------
  {
    'Wansmer/treesj',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local treesj = require 'treesj'

      treesj.setup { use_default_keymaps = false }

      vim.keymap.set('n', '<leader>j', treesj.toggle)
      vim.keymap.set('n', '<leader>J', function()
        treesj.toggle { split = { recursive = true } }
      end)
    end,
  },
}
