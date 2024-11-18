return {
  ----------------
  -- Color Scheme
  ----------------
  {
    'folke/tokyonight.nvim',
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
    event = { 'BufReadPost', 'BufNewFile' },
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

  -----------
  -- Lualine
  -----------
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local icons = require 'core.icons'

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
          lualine_x = {},
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
    config = function()
      local icons = require 'core.icons'
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
