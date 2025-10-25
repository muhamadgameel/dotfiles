return {
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      require('tokyonight').setup {
        style = 'night',
        dim_inactive = true,
        lualine_bold = true,
      }
    end,
  },
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    build = function()
      vim.cmd 'KanagawaCompile'
    end,
    config = function()
      require('kanagawa').setup {
        compile = true,
        dimInactive = true,
        overrides = function(colors)
          local theme = colors.theme
          return {
            Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
            PmenuSel = { fg = 'NONE', bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = theme.ui.bg_m1 },
            PmenuThumb = { bg = theme.ui.bg_p2 },
          }
        end,
      }

      vim.cmd.colorscheme 'kanagawa'
    end,
  },
}
