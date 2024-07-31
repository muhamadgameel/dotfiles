-- Aliases for conciseness
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Command mode
keymap("n", ";", ":", { noremap = true, silent = false })
keymap("n", ":", ";", opts)

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { remap = true })
keymap("n", "<C-j>", "<C-w>j", { remap = true })
keymap("n", "<C-k>", "<C-w>k", { remap = true })
keymap("n", "<C-l>", "<C-w>l", { remap = true }) -- FIXME: does not work because of key overlapping with the terminal

-- Open Splitted windows
keymap("n", "<leader>-", "<C-w>s", opts)
keymap("n", "<leader>|", "<C-w>v", opts)

-- Resize with arrows
keymap("n", "<C-Up>", "<cmd>resize +2<cr>", opts)
keymap("n", "<C-Down>", "<cmd>resize -2<cr>", opts)
keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", opts)
keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", opts)

-- Buffers
keymap("n", "<S-h>", "<cmd>bprevious<cr>", opts)
keymap("n", "<S-l>", "<cmd>bnext<cr>", opts)
keymap("n", "[b", "<cmd>bprevious<cr>", opts)
keymap("n", "]b", "<cmd>bnext<cr>", opts)
keymap("n", "<leader>bd", "<cmd>bdelete<cr>", opts)
keymap("n", "<leader>`", "<cmd>e #<cr>", opts)
keymap("n", "<leader>bb", "<cmd>e #<cr>", opts)

-- Move Lines
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", opts)
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", opts)
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", opts)
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", opts)
keymap("v", "<A-j>", "<cmd>m '>+1<cr>gv=gv", opts)
keymap("v", "<A-k>", "<cmd>m '<-2<cr>gv=gv", opts)

-- When jumping, center buffer window
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)
keymap("n", "*", "*zz", opts)
keymap("n", "#", "#zz", opts)
keymap("n", "g*", "g*zz", opts)
keymap("n", "g#", "g#zz", opts)

-- Location/QuickFix Lists
keymap("n", "<leader>xl", "<cmd>lopen<cr>", opts)
keymap("n", "<leader>xq", "<cmd>copen<cr>", opts)

-- Clear search with <esc>
keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", opts)

-- Highlight last inserted/yanked text
keymap("n", "gV", "`[v`]", opts)

-- Better indenting (stay in indent mode)
keymap("v", "<", "<gv^", opts)
keymap("v", ">", ">gv^", opts)

-- Increment/Decrement
keymap("n", "+", "<C-a>", opts)
keymap("n", "-", "<C-x>", opts)

-- Select all
keymap("n", "<C-a>", "gg<S-v>G", opts)

-- Save file
keymap("n", "<leader>w", "<cmd>w<cr>", opts)

-- Quit
keymap("n", "<leader>q", "<cmd>q<cr>", opts)
