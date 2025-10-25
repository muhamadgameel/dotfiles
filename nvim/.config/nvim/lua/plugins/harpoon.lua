return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local keymap = vim.keymap.set
    local harpoon = require 'harpoon'

    harpoon:setup()

    keymap('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Add to Harpoon' })

    keymap('n', '<leader>e', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Open Harpoon window' })

    keymap('n', '<leader>n', function()
      harpoon:list():next()
    end, { desc = 'Harpoon next file' })

    keymap('n', '<leader>p', function()
      harpoon:list():prev()
    end, { desc = 'Harpoon prev file' })
  end,
}
