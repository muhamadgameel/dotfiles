local g = vim.g -- global variables
local o = vim.opt -- global options

-----------------------------------------------------------
-- General
-----------------------------------------------------------
o.completeopt = { "menu", "menuone", "noselect" } -- mostly just for cmp
o.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
o.mouse = "a" -- allow the mouse to be used in neovim
o.wrap = false -- no line wrapping
o.breakindent = true -- wrapped line will continue visually indented
o.showmatch = true -- highlight matching parenthesis
o.scrolloff = 4 -- line offset to hit to scroll vertically
o.sidescrolloff = 8 -- column offset to hit to scroll horizontally
o.sidescroll = 1 -- the number of columns when scrolling horizontally
o.inccommand = "nosplit" -- preview incremental substitute
o.splitright = true -- vertical split to the right
o.splitbelow = true -- horizontal split to the bottom
o.confirm = true -- confirm to save changes before exiting modified buffer
o.conceallevel = 0 -- so that `` is visible in markdown files
o.fileencoding = "utf-8" -- the encoding written to a file
o.whichwrap = "bs<>[]hl" -- allow keys that move the cursor left/right to move to the prev/next line
o.spelllang = { "en" }

-----------------------------------------------------------
-- UI
-----------------------------------------------------------
o.cursorline = true -- highlight the current line
o.number = true -- show numbered lines
o.relativenumber = true -- set relative numbered lines
o.numberwidth = 4 -- set number column width
o.signcolumn = "yes" -- show signcolumn
o.laststatus = 3 -- set global status bar, instead of one per window
o.showtabline = 0 -- hide tabs line
o.showmode = false -- don't show mode since we have a statusline
o.pumheight = 10 -- maximum number of items to show in the popup-menu (0 => "use available screen space")
o.pumblend = 10 -- enables pseudo-transparency for the popup-menu (0 .. 100)
o.termguicolors = true -- enable 24-bit RGB colors (true colors)
o.title = false -- hide title in wm bar
o.cmdheight = 1 -- more space in the neovim command line for displaying messages
g.netrw_banner = 0 -- hide netrw top info
g.netrw_mouse = 2 -- support mouse in netrw

-----------------------------------------------------------
-- Search
-----------------------------------------------------------
o.ignorecase = true -- ignore case in search patterns
o.smartcase = true -- if pattern is upper-case its sensitive, otherwise it is insensitive
o.gdefault = true -- use 'g' flag by default with :s/foo/bar/.

-----------------------------------------------------------
-- Tabs
-----------------------------------------------------------
o.shiftwidth = 2 -- the number of spaces inserted for each indentation
o.tabstop = 2 -- insert 2 spaces for a tab
o.softtabstop = 2 -- amount of space to replace tab
o.expandtab = true -- convert tabs to spaces
o.smartindent = true -- autoindent new lines
o.shiftround = true -- round indent to multiple of shiftwidth applies to > and <
o.hlsearch = true -- highlight all matches on previous search pattern

-----------------------------------------------------------
-- Memory, CPU, Timing
-----------------------------------------------------------
o.hidden = true -- enable background buffers
o.backup = false -- don't create a backup file
o.writebackup = false -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
o.swapfile = false -- don't create swapfile
o.undofile = true -- cache undo even after closing files
o.lazyredraw = false -- faster scrolling
o.history = 10000 -- remember n lines in history
o.undolevels = 10000 -- max numbers of changes to remember in undo
o.updatetime = 200 -- save swap file and trigger CursorHold
o.timeoutlen = 500 -- time to wait for a mapped sequence to complete (in milliseconds)
