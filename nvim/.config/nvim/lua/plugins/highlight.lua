return {
  -----------------
  -- Todo Comments
  -----------------
  {
    'folke/todo-comments.nvim',
    dependencies = {
      { 'BurntSushi/ripgrep' },
      { 'nvim-lua/plenary.nvim' },
    },
    config = function()
      local todo_comments = require 'todo-comments'

      todo_comments.setup {
        highlight = {
          pattern = [[.*<(KEYWORDS)\s*:?]],
        },
        search = {
          command = 'rg',
          args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--hidden',
            '--glob=!.git/',
          },
          pattern = [[\b(KEYWORDS):?]],
        },
      }
      vim.keymap.set('n', ']t', todo_comments.jump_next, { noremap = true, silent = true })
      vim.keymap.set('n', '[t', todo_comments.jump_prev, { noremap = true, silent = true })
    end,
  },
}
