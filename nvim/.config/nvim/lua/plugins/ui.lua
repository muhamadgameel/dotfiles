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
          colors.error = colors.red1 or colors.error
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

  ------------
  -- Dressing
  ------------
  {
    'stevearc/dressing.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -----------
  -- Lualine
  -----------
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local icons = require 'core.icons'
      local lualine = require 'lualine'
      local lazy_status = require 'lazy.status'

      local trouble = require 'trouble'
      local symbols = trouble.statusline {
        mode = 'lsp_document_symbols',
        groups = {},
        title = false,
        filter = { range = true },
        format = '{kind_icon}{symbol.name:Normal}',
        hl_group = 'lualine_c_normal',
      }

      lualine.setup {
        options = {
          theme = 'tokyonight',
          component_separators = { left = icons.ui.DividerRight, right = icons.ui.DividerLeft },
          section_separators = { left = icons.ui.BoldDividerRight, right = icons.ui.BoldDividerLeft },
          ignore_focus = { 'NvimTree' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff' },
          lualine_c = {
            { 'diagnostics' },
            {
              symbols.get,
              cond = symbols.has,
            },
          },

          lualine_x = {
            {
              lazy_status.updates,
              cond = lazy_status.has_updates,
              color = { fg = 'orange' },
            },
            { 'fileformat' },
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
