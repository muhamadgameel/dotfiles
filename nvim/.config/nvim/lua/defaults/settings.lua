-----------------------------------------------------------
-- API aliases
-----------------------------------------------------------
local cmd = vim.cmd -- execute Vim commands
local g = vim.g -- global variables
local o = vim.o -- global options
local w = vim.wo -- windows-scoped options

-----------------------------------------------------------
-- General
-----------------------------------------------------------
g.mapleader = " " -- change leader to space
g.maplocalleader = " " -- change local leader to space
o.mouse = "a" -- enable mouse support
o.clipboard = "unnamedplus" -- copy/paste to system clipboard
o.swapfile = false -- don't use swapfile
o.undofile = true -- cache undo even after closing files

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
w.cursorline = true -- highlight the screen line of the cursor
w.number = true -- show line number
w.relativenumber = true -- Show relative line number
w.numberwidth = 4 -- set the number of columns showing line number
w.signcolumn = "yes" -- show signcolumn
w.wrap = false -- no line wrapping
o.breakindent = true -- wrapped line will continue visually indented
o.showmatch = true -- highlight matching parenthesis
o.splitright = true -- vertical split to the right
o.splitbelow = true -- orizontal split to the bottom
o.scrolloff = 5 -- line offset to hit to scroll vertically
o.sidescrolloff = 10 -- column offset to hit to scroll horizontally
o.sidescroll = 1 -- the number of columns when scrolling horizontally
o.inccommand = "split" -- Incremental live preview for :substitute
o.laststatus = 3; -- set global status bar, instead of one per window
-----------------------------------------------------------
-- Search
-----------------------------------------------------------
o.ignorecase = true -- ignore case letters when search
o.smartcase = true -- if pattern is upper-case its sensitive, otherwise it is insensitive
o.gdefault = true -- use 'g' flag by default with :s/foo/bar/.

-----------------------------------------------------------
-- Tabs, indent
-----------------------------------------------------------
o.expandtab = true -- insert spaces instead of tabs
o.shiftwidth = 2 -- amount of (tab/spaces) when indenting
o.tabstop = 2 -- width of tab character (1 tab == 2 spaces)
o.softtabstop = 2 -- amount of space to replace tab
o.smartindent = true -- autoindent new lines
o.shiftround = true -- round indent to multiple of shiftwidth applies to > and <

-----------------------------------------------------------
-- Folding
-----------------------------------------------------------
w.foldmethod = "indent" -- fold by indentation
w.foldlevel = 99 -- start unfolded

-----------------------------------------------------------
-- Memory, CPU
-----------------------------------------------------------
o.hidden = true -- enable background buffers
o.history = 10000 -- remember n lines in history
o.undolevels = 1000 -- max numbers of changes to remember in undo
o.lazyredraw = true -- faster scrolling
o.updatetime = 4000 -- write swap file when this time passes

-----------------------------------------------------------
-- Colorscheme
-----------------------------------------------------------
o.termguicolors = true -- enable 24-bit RGB colors (true colors)
cmd([[silent! colorscheme dracula]]) -- set colorscheme
