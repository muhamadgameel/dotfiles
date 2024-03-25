local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Space as leader key
keymap({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Command mode
keymap("n", ";", ":", { noremap = true, silent = false })
keymap("n", ":", ";", opts)

-- Better up/down
keymap({ "n", "x", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap({ "n", "x", "v" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap({ "n", "x", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap({ "n", "x", "v" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Window
keymap("n", "<C-h>", "<C-w>h", { remap = true })
keymap("n", "<C-j>", "<C-w>j", { remap = true })
keymap("n", "<C-k>", "<C-w>k", { remap = true })
keymap("n", "<C-l>", "<C-w>l", { remap = true }) -- FIX: does not work
keymap("n", "<leader>-", "<C-w>s", opts)
keymap("n", "<leader>|", "<C-w>v", opts)
keymap("n", "<leader>ws", "<C-w>s", opts)
keymap("n", "<leader>wv", "<C-w>v", opts)
keymap("n", "<leader>wd", "<C-w>c", opts)
keymap("n", "<leader>ww", "<C-w>p", opts)

-- Resize window
keymap("n", "<C-Up>", "<cmd>resize +2<cr>", opts)
keymap("n", "<C-Down>", "<cmd>resize -2<cr>", opts)
keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", opts)
keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", opts)

-- Buffers
keymap("n", "<S-h>", "<cmd>bprevious<cr>", opts)
keymap("n", "<S-l>", "<cmd>bnext<cr>", opts)
keymap("n", "[b", "<cmd>bprevious<cr>", opts)
keymap("n", "]b", "<cmd>bnext<cr>", opts)
keymap("n", "<leader>`", "<cmd>e #<cr>", opts)
keymap("n", "<leader>bb", "<cmd>e #<cr>", opts)
keymap("n", "<leader>bd", "<cmd>bdelete<cr>", opts)

-- Tabs
keymap("n", "<leader>te", "<cmd>tabnew<cr>", opts)
keymap("n", "]t", "<cmd>tabnext<cr>", opts)
keymap("n", "[t", "<cmd>tabprevious<cr>", opts)
keymap("n", "<leader>tl", "<cmd>tablast<cr>", opts)
keymap("n", "<leader>tf", "<cmd>tabfirst<cr>", opts)
keymap("n", "<leader>td", "<cmd>tabclose<cr>", opts)

-- Location/QuickFix Lists
keymap("n", "<leader>xl", "<cmd>lopen<cr>", opts)
keymap("n", "<leader>xq", "<cmd>copen<cr>", opts)
keymap("n", "[q", vim.cmd.cprev, opts) -- FIX: does not work
keymap("n", "]q", vim.cmd.cnext, opts) -- FIX: does not work

-- Move Lines
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", opts)
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", opts)
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", opts)
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", opts)
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", opts)
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", opts)

-- Toggle options
keymap("n", "<leader>uw", ":lua vim.opt_local.wrap = not vim.opt_local.wrap:get()<cr>", opts)
keymap("n", "<leader>us", ":lua vim.opt_local.spell = not vim.opt_local.spell:get()<cr>", opts)
keymap("n", "<leader>ui", vim.show_pos, opts)

-- When jumping, center buffer window
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)
keymap("n", "*", "*zz", opts)
keymap("n", "#", "#zz", opts)
keymap("n", "g*", "g*zz", opts)
keymap("n", "g#", "g#zz", opts)

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
keymap({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", opts)

-- Quit
keymap("n", "<leader>q", "<cmd>q<cr>", opts)
keymap("n", "<leader>qq", "<cmd>qa<cr>", opts)
