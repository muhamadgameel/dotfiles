-- Aliases for conciseness
local keymap = vim.keymap.set

-- Use space as leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Command mode
keymap('n', ':', ';', { noremap = true, silent = true, desc = 'Command Mode' })
keymap('n', ';', ':', { noremap = true, silent = false })

-- Better movement
keymap('n', 'j', [[v:count?'j':'gj']], { noremap = true, expr = true })
keymap('n', 'k', [[v:count?'k':'gk']], { noremap = true, expr = true })

-- When jumping, center buffer window
keymap('n', 'n', 'nzz')
keymap('n', 'N', 'Nzz')
keymap('n', '*', '*zz')
keymap('n', '#', '#zz')
keymap('n', 'g*', 'g*zz')
keymap('n', 'g#', 'g#zz')

-- Better window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to Left Window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to Down Window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to Up Window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to Right Window' }) -- FIXME: does not work because of key overlapping with the terminal

-- Resize with arrows
keymap('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Resize Window Up' })
keymap('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Resize Window Down' })
keymap('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Resize Window Left' })
keymap('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Resize Window Right' })

-- Move lines up and down
keymap('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move Line Down' })
keymap('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move Line Up' })
keymap('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Line Down' })
keymap('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Line Up' })
keymap('v', '<A-j>', "<cmd>m '>+1<cr>gv=gv", { desc = 'Move Line Down' })
keymap('v', '<A-k>', "<cmd>m '<-2<cr>gv=gv", { desc = 'Move Line Up' })

-- Switch buffer
keymap('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
keymap('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
keymap('n', '[b', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
keymap('n', ']b', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
keymap('n', '<leader>b', '<cmd>e #<cr>', { desc = 'Switch Last Buffer' })
keymap('n', '<leader>c', '<cmd>:bd<cr>', { desc = 'Close Buffer' })

-- Misc
keymap({ 'i', 'n' }, '<esc>', '<cmd>nohlsearch<cr><esc>', { desc = 'Clear Search Highlight' })
keymap('v', '<', '<gv^', { desc = 'Indent Left' })
keymap('v', '>', '>gv^', { desc = 'Indent Right' })
keymap('v', 'p', '"_dP', { desc = 'Paste Over Selection' })
keymap('n', '+', '<C-a>', { desc = 'Increment' })
keymap('n', '-', '<C-x>', { desc = 'Decrement' })
keymap('n', 'gV', '`[v`]', { desc = 'Highlight Last Inserted Text' })
keymap('n', '<C-a>', 'ggVG', { desc = 'Select All' })
keymap('n', '<leader>-', '<C-w>s', { desc = 'Split Horizontally' })
keymap('n', '<leader>|', '<C-w>v', { desc = 'Split Vertically' })
keymap('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save Buffer' })
keymap('n', '<leader>q', '<cmd>q<cr>', { desc = 'Quit Buffer' })
keymap('n', '<leader>xl', '<cmd>lopen<cr>', { desc = 'Open Location List' })
keymap('n', '<leader>xq', '<cmd>copen<cr>', { desc = 'Open Quick Fix List' })
