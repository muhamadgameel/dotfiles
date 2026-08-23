local keymap = vim.keymap.set

-- Use space as leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- For conciseness
local opts = { noremap = true, silent = true }

-- Disable the spacebar key's default behavior in Normal and Visual modes
keymap({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Allow moving the cursor through wrapped lines with j, k
keymap('n', 'j', [[v:count ? 'j' : 'gj']], { expr = true, silent = true })
keymap('n', 'k', [[v:count ? 'k' : 'gk']], { expr = true, silent = true })

-- clear highlights
keymap('n', '<Esc>', '<cmd>noh<cr>', opts)

-- Find and center
keymap('n', 'n', 'nzzzv', opts)
keymap('n', 'N', 'Nzzzv', opts)
keymap('n', '*', '*zzzv', opts)
keymap('n', '#', '#zzzv', opts)
keymap('n', 'g*', 'g*zzzv', opts)
keymap('n', 'g#', 'g#zzzv', opts)

-- Join lines keeping cursor position
keymap('n', 'J', 'mzJ`z', opts)

-- Duplicate lines
keymap('n', '<leader>d', 'yyp', { desc = 'Duplicate line' })
keymap('v', '<leader>d', 'y`>p', { desc = 'Duplicate selection' })

-- Reselect pasted/changed
keymap('n', 'gV', '`[v`]', { desc = 'Select last change/paste' })

-- Redo
keymap('n', 'U', '<C-r>', opts)

-- Stay in indent mode
keymap('v', '<', '<gv', opts)
keymap('v', '>', '>gv', opts)

-- Keep last yanked when pasting
keymap({ 'x', 'v' }, 'p', '"_dP', opts)

-- Better line start/end (H and L are rarely used)
keymap({ 'n', 'v' }, 'H', '^', opts)
keymap({ 'n', 'v' }, 'L', '$', opts)

----------------------------------------------------------------------------------
-- Buffers
----------------------------------------------------------------------------------
keymap('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to last buffer' })
-- Snacks.bufdelete closes the buffer without collapsing the window layout
keymap('n', '<leader>bd', function()
  Snacks.bufdelete()
end, { desc = 'Delete buffer' })
keymap('n', '<leader>bo', function()
  Snacks.bufdelete.other()
end, { desc = 'Delete other buffers' })
keymap('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer' })
keymap('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Previous buffer' })
keymap('n', ']B', '<cmd>BufferLineMoveNext<cr>', { desc = 'Move buffer right' })
keymap('n', '[B', '<cmd>BufferLineMovePrev<cr>', { desc = 'Move buffer left' })

----------------------------------------------------------------------------------
-- Windows
----------------------------------------------------------------------------------
keymap('n', '<C-h>', '<C-w><C-h>', opts)
keymap('n', '<C-l>', '<C-w><C-l>', opts)
keymap('n', '<C-j>', '<C-w><C-j>', opts)
keymap('n', '<C-k>', '<C-w><C-k>', opts)

----------------------------------------------------------------------------------
-- Splits
----------------------------------------------------------------------------------
keymap('n', '<leader>sh', '<C-w>s', { desc = 'Split horizontal' })
keymap('n', '<leader>sv', '<C-w>v', { desc = 'Split vertical' })
keymap('n', '<leader>se', '<C-w>=', { desc = 'Equalize splits' })
keymap('n', '<leader>sx', '<cmd>close<cr>', { desc = 'Close split' })
keymap('n', '<leader>sm', '<C-w>_<C-w>|', { desc = 'Maximize window' })

----------------------------------------------------------------------------------
-- Move Lines
----------------------------------------------------------------------------------
keymap('n', '<A-j>', '<cmd>m .+1<cr>==', opts)
keymap('n', '<A-k>', '<cmd>m .-2<cr>==', opts)
keymap('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', opts)
keymap('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', opts)

----------------------------------------------------------------------------------
-- Files
----------------------------------------------------------------------------------
keymap('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save' })
keymap('n', '<leader>W', '<cmd>wa<cr>', { desc = 'Save all' })
keymap('n', '<leader>q', '<cmd>q<cr>', { desc = 'Quit' })
keymap('n', '<leader>Q', '<cmd>qa<cr>', { desc = 'Quit all' })

----------------------------------------------------------------------------------
-- Terminal
----------------------------------------------------------------------------------
keymap('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

----------------------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------------------
-- Copy filepath to the clipboard
keymap('n', '<leader>fp', function()
  local filePath = vim.fn.expand '%:~' -- Get the file path relative to home directory
  vim.fn.setreg('+', filePath) -- copy the file path to clipboard register
  print('File path copied to clipboard: ' .. filePath)
end, { desc = 'Copy file path to clipboard' })

-- Replace word under cursor (buffer-wide; <leader>rW is the project-wide version)
keymap(
  'n',
  '<leader>rw',
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = 'Replace word under cursor' }
)

----------------------------------------------------------------------------------
-- Quickfix & Location list
----------------------------------------------------------------------------------
keymap('n', ']q', '<cmd>cnext<cr>zz', { desc = 'Next quickfix item' })
keymap('n', '[q', '<cmd>cprev<cr>zz', { desc = 'Previous quickfix item' })
keymap('n', ']l', '<cmd>lnext<cr>zz', { desc = 'Next loclist item' })
keymap('n', '[l', '<cmd>lprev<cr>zz', { desc = 'Previous loclist item' })

----------------------------------------------------------------------------------
-- Built-in tools (Neovim 0.12)
----------------------------------------------------------------------------------
keymap('n', '<leader>uu', '<cmd>packadd nvim.undotree | Undotree<cr>', { desc = 'Undotree' })
