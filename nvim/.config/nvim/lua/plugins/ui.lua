return {
  -- Color Scheme
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
}
