-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank { timeout = 200 }
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

-- Set cursor back to blinking beam when leaving Neovim
vim.api.nvim_create_autocmd('ExitPre', {
  group = vim.api.nvim_create_augroup('RestoreCursor', { clear = true }),
  command = 'set guicursor=a:ver100,a:blinkwait0,a:blinkon500,a:blinkoff500',
  desc = 'Set cursor back to blinking beam when leaving Neovim',
})

-- Restore cursor position when reopening a file
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('RestoreCursorPosition', { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = 'Restore cursor to last position on file open',
})

-- Close special buffers with q
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('CloseWithQ', { clear = true }),
  pattern = { 'help', 'man', 'qf', 'checkhealth', 'lspinfo', 'notify', 'query', 'startuptime' },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = ev.buf, silent = true })
  end,
  desc = 'Close special buffers with q',
})
