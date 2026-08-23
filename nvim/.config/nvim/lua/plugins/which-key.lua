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
      { '<leader>n', group = 'npm package' },
      { '<leader>r', group = 'rename/replace/rust' },
      { '<leader>s', group = 'split/session' },
      { '<leader>t', group = 'toggle' },
      { '<leader>u', group = 'utils' },
      { '<leader>x', group = 'trouble' },
      { 'gr', group = 'LSP goto/actions' },
      { ']', group = 'next' },
      { '[', group = 'prev' },
    },
  },
}
