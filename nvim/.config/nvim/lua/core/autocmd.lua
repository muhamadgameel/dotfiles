-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank { timeout = 200 }
  end,
  desc = 'Highlight when yanking text',
})

-- Enable spell checking for markdown and text files
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.opt_local.spell = true
  end,
  desc = 'Enable spell check',
})

vim.api.nvim_create_autocmd('ExitPre', {
  group = vim.api.nvim_create_augroup('RestoreCursor', { clear = true }),
  command = 'set guicursor=a:ver100,a:blinkwait0,a:blinkon500,a:blinkoff500',
  desc = 'Set cursor back to blinking beam when leaving Neovim',
})
