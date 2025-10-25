return {
  'rmagatti/auto-session',
  opts = {
    allowed_dirs = { '~/Projects' },
  },
  config = function()
    require('auto-session').setup {}

    local keymap = vim.keymap.set
    keymap('n', '<leader>ss', '<cmd>AutoSession save<cr>', { desc = 'Save Session' })
    keymap('n', '<leader>sr', '<cmd>AutoSession restore<cr>', { desc = 'Restore Session' })
    keymap('n', '<leader>sf', '<cmd>AutoSession search<cr>', { desc = 'Search Session' })
    keymap('n', '<leader>sd', '<cmd>AutoSession delete<cr>', { desc = 'Delete Session' })
  end,
}
