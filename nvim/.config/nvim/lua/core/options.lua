-- Aliases for conciseness
local opt = vim.opt -- For setting options

----------------------------------------------------------------------------------
-- Editor Behavior
----------------------------------------------------------------------------------
-- Indentation
opt.expandtab = true -- Convert tabs to spaces
opt.cindent = true -- Enable automatic C-style indentation
opt.smartindent = true -- Smarter indenting
opt.shiftround = true -- Round indent to multiple of 'shiftwidth'
opt.shiftwidth = 2 -- Number of spaces for each step of (auto)indent
opt.tabstop = 2 -- Number of spaces that a <Tab> in the file counts for
opt.softtabstop = 2 -- Number of spaces that a <Tab> counts for while performing editing operations

-- Text Handling
opt.textwidth = 120 -- Set text width for automatic wrapping
opt.wrap = false -- Don't wrap lines
opt.linebreak = true -- Wrap long lines at a character in 'breakat' rather than at the last character that fits
opt.breakindent = true -- Preserve indentation in wrapped text
opt.formatoptions = 'jcroqlnt' -- Improve auto-formatting options
opt.iskeyword:append '-' -- Consider '-' as part of a word

-- Editing Experience
opt.showmatch = true -- Briefly jump to the matching bracket when inserted
opt.timeoutlen = 400 -- Time to wait for a mapped sequence to complete
opt.updatetime = 100 -- Delay before writing swap file to disk (also affects CursorHold)
opt.mouse = 'a' -- Enable mouse support in all modes
opt.clipboard = 'unnamedplus' -- Use system clipboard
opt.whichwrap:append '<,>,[,],h,l' -- Allow more keys to move across lines
opt.spelllang = { 'en_us' } -- Set spell checking language
opt.fixeol = false -- Don't automatically add EOL at EOF
opt.jumpoptions = 'stack' -- Make jumplist behave like a stack

----------------------------------------------------------------------------------
-- User Interface
----------------------------------------------------------------------------------
-- Display
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers
opt.termguicolors = true -- Enable 24-bit RGB colors in the TUI
opt.background = 'dark' -- Use dark version of the color scheme
opt.cursorline = false -- No highlight the text line of the cursor
opt.signcolumn = 'yes' -- Always show the sign column
opt.showmode = false -- Don't show the mode in the last line
opt.showcmd = false -- Don't show (partial) command in the last line of the screen
opt.laststatus = 3 -- Always display the status line and make it global not per window
opt.showtabline = 0 -- Never show the tab line
opt.list = true -- Show some invisible characters
opt.listchars = { -- Define which invisible characters to show
  tab = '» ',
  trail = '·',
  nbsp = '␣',
  extends = '❯',
  precedes = '❮',
}
vim.g.netrw_liststyle = "3" -- Show Netrw in tree-like view

-- Scrolling and Viewport
opt.scrolloff = 10 -- Minimum number of screen lines to keep above and below the cursor
opt.sidescrolloff = 10 -- Minimum number of screen columns to keep to the left and right of the cursor
opt.smoothscroll = true -- Smooth scrolling for half-page/page up/down movements

-- Windows and Splits
opt.splitright = true -- Open new vertical split to the right
opt.splitbelow = true -- Open new horizontal split below
opt.equalalways = false -- Don't resize windows on split or close
opt.title = true -- Set the window's title to the current file
opt.titlestring = "%{substitute(getcwd(), $HOME, '~', '')}" -- Show current directory in the title

-- Command Line and Popups
opt.cmdheight = 0 -- Number of screen lines to use for the command-line
opt.pumheight = 10 -- Maximum number of items to show in the popup menu
opt.pumblend = 10 -- Pseudo-transparency for popup menu (0-100)
opt.winblend = 10 -- Pseudo-transparency for floating windows (0-100)

----------------------------------------------------------------------------------
-- Search and Replace
----------------------------------------------------------------------------------
opt.ignorecase = true -- Ignore case in search patterns
opt.smartcase = true -- Override 'ignorecase' if search pattern contains upper case characters
opt.gdefault = true -- Substitute all matches in a line by default with :s/foo/bar/
opt.inccommand = 'nosplit' -- Show effects of substitution incrementally
opt.hlsearch = true -- Highlight all matches on previous search pattern
opt.incsearch = true -- Show where the pattern matches as it is typed

----------------------------------------------------------------------------------
-- Completion and Wildmenu
----------------------------------------------------------------------------------
opt.completeopt = { 'menu', 'menuone', 'noselect' } -- Options for insert mode completion
opt.infercase = true -- Adjust case of match for keyword completion
opt.wildoptions = 'pum' -- Use popup menu for command-line completion
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.wildignore:append { -- Ignore certain file types and directories
  '*.o',
  '*.obj',
  '*.bin',
  '*.dll',
  '*.exe',
  '*/.git/*',
  '*/.hg/*',
  '*/.svn/*',
  '*.jpg',
  '*.bmp',
  '*.gif',
  '*.png',
  '*.jpeg',
}
opt.wildignorecase = true -- Ignore case when completing file names and directories

----------------------------------------------------------------------------------
-- File handling
----------------------------------------------------------------------------------
opt.confirm = true -- Prompt to save changes before exiting modified buffer
opt.writebackup = false -- Don't create a backup before overwriting a file
opt.swapfile = false -- Don't use swapfiles
opt.undofile = true -- Persist undo history to a file
opt.undolevels = 10000 -- Maximum number of changes that can be undone
opt.autoread = true -- Automatically read file when changed outside of Vim
opt.autowrite = true -- Automatically write a file when leaving a modified buffer
opt.backup = false -- Don't keep backup files
opt.backupcopy = 'yes' -- Overwrite the original backup file

----------------------------------------------------------------------------------
-- Folding
----------------------------------------------------------------------------------
opt.foldenable = false -- Disable folding
opt.foldmethod = 'indent' -- Use indentation by default for folding
opt.foldlevel = 99 -- Open all folds by default
opt.foldcolumn = '1' -- Show a small column on the side to indicate folds

----------------------------------------------------------------------------------
-- Performance
----------------------------------------------------------------------------------
opt.hidden = true -- Allow switching buffers without saving
opt.history = 1000 -- Increase command-line history
opt.redrawtime = 1500 -- Time in milliseconds for redrawing the display
opt.lazyredraw = false -- Disable lazy redraw while doing operations like macros
opt.synmaxcol = 200 -- Only highlight the first 200 columns
opt.ttyfast = true -- Indicate a fast terminal connection

----------------------------------------------------------------------------------
-- Diff Mode
----------------------------------------------------------------------------------
opt.diffopt = {
  'internal', -- Use the internal diff library
  'filler', -- Add filler lines for synchronized scrolling
  'closeoff', -- Turn off diff mode when one window is closed
  'hiddenoff', -- Don't use diff mode for a buffer when it becomes hidden
  'algorithm:patience', -- Use the patience diff algorithm
  'linematch:60', -- Align lines by similar text (up to 60% different)
  'indent-heuristic', -- Use the indent heuristic for the patience algorithm
}

----------------------------------------------------------------------------------
-- Messaging and notifications
----------------------------------------------------------------------------------
opt.shortmess:append 'c' -- Avoid showing message about ins-completion-menu
opt.report = 0 -- Always report the number of lines changed
