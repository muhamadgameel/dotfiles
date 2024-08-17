return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  lazy = false,
  dependencies = {
    { 'windwp/nvim-ts-autotag' },
    { 'RRethy/nvim-treesitter-endwise' },
    { 'nvim-treesitter/nvim-treesitter-textobjects' },
    {
      ------------
      -- Comments
      ------------
      'numToStr/Comment.nvim',
      dependencies = {
        { 'JoosepAlviste/nvim-ts-context-commentstring' },
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
    {
      -----------------------------------
      -- JS/TS template string converter
      -----------------------------------
      'axelvc/template-string.nvim',
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
  },
  --------------
  -- Treesitter
  --------------
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
}
