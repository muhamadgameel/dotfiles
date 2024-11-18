return {
  ---------------------------------------------------------------------
  -- Illuminate (Highlighting other uses of the word under the cursor)
  ---------------------------------------------------------------------
  {
    'RRethy/vim-illuminate',
    event = 'VeryLazy',
    config = function()
      require('illuminate').configure {
        filetypes_denylist = {
          'mason',
          'harpoon',
          'DressingInput',
          'NeogitCommitMessage',
          'qf',
          'dirbuf',
          'dirvish',
          'oil',
          'minifiles',
          'fugitive',
          'alpha',
          'NvimTree',
          'lazy',
          'NeogitStatus',
          'Trouble',
          'netrw',
          'lir',
          'DiffviewFiles',
          'Outline',
          'Jaq',
          'spectre_panel',
          'toggleterm',
          'DressingSelect',
          'TelescopePrompt',
        },
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
      vim.keymap.set('n', ']t', todo_comments.jump_next, { desc = "Jump to next todo comment" })
      vim.keymap.set('n', '[t', todo_comments.jump_prev, { desc = "Jump to previous todo comment" })
    end,
  },

  ------------------------------------
  -- Indent Blankline (Indent guides)
  ------------------------------------
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'VeryLazy',
    config = function()
      require('ibl').setup { scope = { enabled = false } }
    end,
  },
}
