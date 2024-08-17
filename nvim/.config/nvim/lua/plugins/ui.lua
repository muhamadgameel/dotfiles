return {
  ----------------
  -- Color Scheme
  ----------------
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('tokyonight').setup {
        style = 'storm',
        dim_inactive = true,
        lualine_bold = true,
        on_colors = function(colors)
          colors.hint = colors.orange
          colors.error = '#ff0000'
        end,
      }

      vim.cmd.colorscheme 'tokyonight'
    end,
  },

  -----------
  -- Lualine
  -----------
  {
    'nvim-lualine/lualine.nvim',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      event = 'VeryLazy',
    },
    config = function()
      local icons = require 'icons'

      require('lualine').setup {
        options = {
          theme = 'tokyonight',
          component_separators = { left = icons.ui.DividerRight, right = icons.ui.DividerLeft },
          section_separators = { left = icons.ui.BoldDividerRight, right = icons.ui.BoldDividerLeft },
          ignore_focus = { 'NvimTree' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff' },
          lualine_c = { 'diagnostics' },
          lualine_x = { 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { '' },
        },
        extensions = { 'quickfix', 'trouble', 'man', 'mason', 'lazy', 'fugitive' },
      }
    end,
  },

  -------------------------
  -- Code Window (minimap)
  -------------------------
  {
    'gorbit99/codewindow.nvim',
    event = { 'BufRead', 'BufNewFile' },
    config = function()
      local codewindow = require 'codewindow'
      codewindow.setup {
        auto_enable = true,
        width_multiplier = 2,
        show_cursor = false,
        screen_bounds = 'background',
        window_border = 'none',
      }
      codewindow.apply_default_keybinds()
    end,
  },

  ---------------------------------------
  -- Fidget (LSP progress notifications)
  ---------------------------------------
  {
    'j-hui/fidget.nvim',
    event = 'LspAttach',
    config = function()
      require('fidget').setup {}
    end,
  },

  -------------
  -- Neoscroll
  -------------
  {
    'karb94/neoscroll.nvim',
    event = 'BufRead',
    config = function()
      require('neoscroll').setup {
        mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
        hide_cursor = true,
        stop_eof = true,
        easing_function = 'sine',
        respect_scrolloff = false,
        performance_mode = false,
      }
    end,
  },

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
    event = 'BufRead',
    config = function()
      require('ibl').setup { scope = { enabled = false } }
    end,
  },
}
