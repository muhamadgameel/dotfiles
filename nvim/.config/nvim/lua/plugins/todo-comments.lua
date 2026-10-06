return {
  'folke/todo-comments.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  cmd = { 'TodoTrouble', 'TodoQuickFix', 'TodoLocList' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local todo_comments = require 'todo-comments'

    todo_comments.setup()

    vim.keymap.set('n', '<leader>ot', function()
      Snacks.picker.todo_comments()
    end, { desc = 'TODO comments' })
    vim.keymap.set('n', '<leader>oT', function()
      Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } }
    end, { desc = 'TODO/FIX comments' })

    vim.keymap.set('n', ']t', function()
      todo_comments.jump_next()
    end, { desc = 'Next todo comment' })
    vim.keymap.set('n', '[t', function()
      todo_comments.jump_prev()
    end, { desc = 'Previous todo comment' })
  end,
}
