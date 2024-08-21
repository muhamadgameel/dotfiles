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

  ---------
  -- Noice
  ---------
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

  ---------------
  -- Buffer line
  ---------------
  {
    'akinsho/bufferline.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    lazy = false,
    config = function()
      local icons = require 'icons'
      require('bufferline').setup {
        options = {
          separator_style = 'slant',
          indicator = {
            style = 'underline',
          },
          hover = {
            enabled = true,
            delay = 200,
            reveal = { 'close' },
          },
          diagnostics = 'nvim_lsp',
          diagnostics_indicator = function(count, level, _, _)
            local icon = level:match 'error' and icons.diagnostics.Error .. ' ' or icons.diagnostics.Warning .. ' '
            return ' ' .. icon .. count
          end,
        },
      }
    end,
  },
}
