return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    preset = 'helix',
    delay = 300,
    spec = {
      { '<leader>b', group = 'buffer' },
      { '<leader>c', group = 'code' },
      { '<leader>h', group = 'git hunk' },
      { '<leader>o', group = 'open/search' },
      { '<leader>og', group = 'git' },
      { '<leader>p', group = 'swap param' },
      { '<leader>r', group = 'rename/replace' },
      { '<leader>s', group = 'split/session' },
      { '<leader>t', group = 'toggle' },
      { '<leader>u', group = 'utils' },
      { '<leader>x', group = 'trouble' },
      { 'gr', group = 'LSP goto/actions' },
    },
  },
}
