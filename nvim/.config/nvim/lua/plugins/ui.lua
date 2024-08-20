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

  ------------------------------------
  -- Noice
  ------------------------------------
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    config = function()
      local icons = require 'icons'

      require('noice').setup {
        presets = {
          bottom_search = false,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
        lsp = {
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true,
          },
        },
        cmdline = {
          format = {
            help = { icon = icons.misc.Help },
          },
        },
        routes = {
          {
            filter = { event = 'msg_show', kind = '' },
            opts = { skip = true },
          },
        },
      }
    end,
  },

  -----------
  -- Lualine
  -----------
  {
    'nvim-lualine/lualine.nvim',
    lazy = false,
    dependencies = {
      { 'nvim-tree/nvim-web-devicons' },
      { 'folke/noice.nvim' },
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

          lualine_x = {
            {
              require('noice').api.status.message.get_hl,
              cond = require('noice').api.status.message.has,
            },
            {
              require('noice').api.status.command.get,
              cond = require('noice').api.status.command.has,
              color = { fg = '#ff9e64' },
            },
            {
              require('noice').api.status.mode.get,
              cond = require('noice').api.status.mode.has,
              color = { fg = '#ff9e64' },
            },
          },
          lualine_y = { 'filetype' },
          lualine_z = { 'progress' },
        },
        extensions = { 'quickfix', 'trouble', 'man', 'mason', 'lazy', 'fugitive' },
      }
    end,
  },
}
