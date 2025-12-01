return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    { 'nvim-treesitter/nvim-treesitter-textobjects' },
  },
  config = function()
    local treesitter = require 'nvim-treesitter.configs'

    vim.opt.foldmethod = 'expr'
    vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

    treesitter.setup {
      auto_install = true,
      sync_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          node_decremental = '<BS>',
          scope_incremental = '<TAB>',
        },
      },

      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
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
          set_jumps = true,
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
            ['<leader>pa'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>pA'] = '@parameter.inner',
          },
        },
      },

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
        'qmldir',
        'qmljs',
      },
    }
  end,
}
