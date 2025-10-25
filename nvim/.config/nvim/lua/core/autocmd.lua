-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank { timeout = 200 }
  end,
})

-- Enable spell checking for markdown and text files
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.opt_local.spell = true
  end,
})
