-- Aliases for conciseness
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Use space as leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Command mode
keymap('n', ':', ';', opts)
keymap('n', ';', ':', { noremap = true, silent = false })

-- Better movement
keymap('n', 'j', [[v:count?'j':'gj']], { noremap = true, expr = true })
keymap('n', 'k', [[v:count?'k':'gk']], { noremap = true, expr = true })

-- Better indenting (stay in indent mode)
keymap('v', '<', '<gv^', opts)
keymap('v', '>', '>gv^', opts)

-- Paste over currently selected text without yanking it
keymap('v', 'p', '"_dP', opts)

-- Increment/Decrement
keymap('n', '+', '<C-a>', opts)
keymap('n', '-', '<C-x>', opts)

-- Highlight last inserted/yanked text
keymap('n', 'gV', '`[v`]', opts)

-- When jumping, center buffer window
keymap('n', 'n', 'nzz', opts)
keymap('n', 'N', 'Nzz', opts)
keymap('n', '*', '*zz', opts)
keymap('n', '#', '#zz', opts)
keymap('n', 'g*', 'g*zz', opts)
keymap('n', 'g#', 'g#zz', opts)

-- Cancel search highlighting with ESC
keymap({ 'i', 'n' }, '<esc>', '<cmd>nohlsearch<cr><esc>', opts)

-- Select all
keymap('n', '<C-a>', 'ggVG', opts)

-- Better window navigation
keymap('n', '<C-h>', '<C-w>h', { remap = true })
keymap('n', '<C-j>', '<C-w>j', { remap = true })
keymap('n', '<C-k>', '<C-w>k', { remap = true })
keymap('n', '<C-l>', '<C-w>l', { remap = true }) -- FIXME: does not work because of key overlapping with the terminal

-- Resize with arrows
keymap('n', '<C-Up>', '<cmd>resize +2<cr>', opts)
keymap('n', '<C-Down>', '<cmd>resize -2<cr>', opts)
keymap('n', '<C-Left>', '<cmd>vertical resize -2<cr>', opts)
keymap('n', '<C-Right>', '<cmd>vertical resize +2<cr>', opts)

-- Move lines up and down
keymap('n', '<A-j>', '<cmd>m .+1<cr>==', opts)
keymap('n', '<A-k>', '<cmd>m .-2<cr>==', opts)
keymap('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', opts)
keymap('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', opts)
keymap('v', '<A-j>', "<cmd>m '>+1<cr>gv=gv", opts)
keymap('v', '<A-k>', "<cmd>m '<-2<cr>gv=gv", opts)

-- Switch buffer
keymap('n', '<S-h>', '<cmd>bprevious<cr>', opts)
keymap('n', '<S-l>', '<cmd>bnext<cr>', opts)
keymap('n', '[b', '<cmd>bprevious<cr>', opts)
keymap('n', ']b', '<cmd>bnext<cr>', opts)
keymap('n', '<leader>b', '<cmd>e #<cr>', opts)

-- Open Splitted windows
keymap('n', '<leader>-', '<C-w>s', opts)
keymap('n', '<leader>|', '<C-w>v', opts)

-- Quick save
keymap('n', '<leader>w', '<cmd>w<cr>', opts)

-- Quick quit
keymap('n', '<leader>q', '<cmd>q<cr>', opts)

-- Location/QuickFix Lists
keymap('n', '<leader>xl', '<cmd>lopen<cr>', opts)
keymap('n', '<leader>xq', '<cmd>copen<cr>', opts)
