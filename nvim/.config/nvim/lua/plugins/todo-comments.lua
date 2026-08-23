return {
  'folke/todo-comments.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  cmd = { 'TodoTrouble', 'TodoQuickFix', 'TodoLocList' },
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local todo_comments = require 'todo-comments'

    todo_comments.setup {
      keywords = {
        TODO = { icon = ' ', color = 'info' },
      },
    }

    -- snacks.picker has no todo_comments source, so the listing goes through
    -- trouble.nvim (already a dependency of this config) instead.
    vim.keymap.set('n', '<leader>ot', '<cmd>TodoTrouble<cr>', { desc = 'TODO comments' })
    vim.keymap.set('n', '<leader>oT', '<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>', { desc = 'TODO/FIX comments' })

    vim.keymap.set('n', ']t', function()
      todo_comments.jump_next()
    end, { desc = 'Next todo comment' })
    vim.keymap.set('n', '[t', function()
      todo_comments.jump_prev()
    end, { desc = 'Previous todo comment' })
  end,
}
