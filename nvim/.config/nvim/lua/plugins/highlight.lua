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
