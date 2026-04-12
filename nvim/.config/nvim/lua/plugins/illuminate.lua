return {
  'RRethy/vim-illuminate',
  event = 'VeryLazy',
  config = function()
    require('illuminate').configure {
      filetypes_denylist = {
        'mason',
        'harpoon',
        'qf',
        'oil',
        'lazy',
        'Trouble',
        'toggleterm',
        'TelescopePrompt',
      },
    }
  end,
}
