return {
  'folke/todo-comments.nvim',
  event = 'VimEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local todo_comments = require 'todo-comments'

    todo_comments.setup {
      keywords = {
        TODO = { icon = ' ', color = 'info' },
      },
    }

    -- Todo Comments
    vim.keymap.set('n', '<leader>ot', '<cmd>TodoTelescope<cr>', { desc = 'TODO comments' })
    vim.keymap.set('n', '<leader>oT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>', { desc = 'TODO comments' })

    vim.keymap.set('n', ']t', todo_comments.jump_next, { desc = 'Next todo comment' })
    vim.keymap.set('n', '[t', todo_comments.jump_prev, { desc = 'Previous todo comment' })
  end,
}
