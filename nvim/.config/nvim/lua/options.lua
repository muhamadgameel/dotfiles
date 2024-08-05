-- Aliases for conciseness
local opt = vim.opt

-- Helper function to set multiple options at once
local function set_options(options)
  for k, v in pairs(options) do
    opt[k] = v
  end
end

----------------------------------------------------------------------------------
-- Editor Behavior
----------------------------------------------------------------------------------
set_options {
  -- Indentation
  expandtab = true, -- Convert tabs to spaces
  cindent = true, -- Enable automatic C-style indentation
  smartindent = true, -- Smarter indenting
  shiftround = true, -- Round indent to multiple of 'shiftwidth'
  shiftwidth = 2, -- Number of spaces for each step of (auto)indent
  tabstop = 2, -- Number of spaces that a <Tab> in the file counts for
  softtabstop = 2, -- Number of spaces that a <Tab> counts for while performing editing operations

  -- Text Handling
  wrap = false, -- Don't wrap lines
  linebreak = true, -- Wrap long lines at a character in 'breakat' rather than at the last character that fits
  breakindent = true, -- Preserve indentation in wrapped text
  formatoptions = "jcroqlnt", -- Improve auto-formatting options

  -- Editing Experience
  showmatch = true, -- Briefly jump to the matching bracket when inserted
  timeoutlen = 500, -- Time to wait for a mapped sequence to complete
  updatetime = 200, -- Delay before writing swap file to disk (also affects CursorHold)
}
opt.mouse:append "a" -- Enable mouse support in all modes
opt.iskeyword:append "-" -- Consider '-' as part of a word
opt.whichwrap:append "<,>,[,],h,l" -- Allow more keys to move across lines

----------------------------------------------------------------------------------
-- User Interface
----------------------------------------------------------------------------------
set_options {
  -- Display
  number = true, -- Show line numbers
  relativenumber = true, -- Show relative line numbers
  termguicolors = true, -- Enable 24-bit RGB colors in the TUI
  cursorline = false, -- No highlight the text line of the cursor
  signcolumn = "yes", -- Always show the sign column
  showmode = false, -- Don't show the mode in the last line
  showcmd = false, -- Don't show (partial) command in the last line of the screen
  laststatus = 3, -- Always display the status line and make it global
  showtabline = 0, -- Never show the tab line

  -- Scrolling and Viewport
  scrolloff = 10, -- Minimum number of screen lines to keep above and below the cursor
  sidescrolloff = 10, -- Minimum number of screen columns to keep to the left and right of the cursor
  smoothscroll = true, -- Scroll by visual lines with <C-U>, <C-D>, etc.

  -- Windows and Splits
  splitright = true, -- Open new vertical split to the right
  splitbelow = true, -- Open new horizontal split below

  -- Command Line and Popups
  cmdheight = 1, -- Hide command line when not in use (requires laststatus=3)
  pumheight = 10, -- Maximum number of items to show in the popup menu
  pumblend = 10, -- Pseudo-transparency for popup menu (0-100)
  winblend = 10, -- Pseudo-transparency for floating windows (0-100)
}

----------------------------------------------------------------------------------
-- Search and Replace
----------------------------------------------------------------------------------
set_options {
  ignorecase = true, -- Ignore case in search patterns
  smartcase = true, -- Override 'ignorecase' if search pattern contains upper case characters
  gdefault = true, -- Substitute all matches in a line by default with :s/foo/bar/
  inccommand = "nosplit", -- Show effects of substitution incrementally
}

----------------------------------------------------------------------------------
-- Completion and Wildmenu
----------------------------------------------------------------------------------
set_options {
  completeopt = { "menu", "menuone", "noselect" }, -- Options for insert mode completion
  infercase = true, -- Adjust case of match for keyword completion
  wildoptions = "pum", -- Use popup menu for command-line completion
  wildmode = "longest:full,full", -- Command-line completion mode
}

----------------------------------------------------------------------------------
-- File handling
----------------------------------------------------------------------------------
set_options {
  confirm = true, -- Prompt to save changes before exiting modified buffer
  writebackup = false, -- Don't create a backup before overwriting a file
  swapfile = false, -- Don't use swapfiles
  undofile = true, -- Persist undo history to a file
  undolevels = 10000, -- Maximum number of changes that can be undone
}
opt.clipboard:append "unnamedplus" -- Use system clipboard

----------------------------------------------------------------------------------
-- Diff Mode
----------------------------------------------------------------------------------
set_options {
  diffopt = { "internal", "filler", "closeoff", "hiddenoff", "algorithm:patience" },
}

----------------------------------------------------------------------------------
-- Folding
----------------------------------------------------------------------------------
set_options {
  foldenable = false,
  foldmethod = "indent",
}

----------------------------------------------------------------------------------
-- Messaging and notifications
----------------------------------------------------------------------------------
opt.shortmess:append "c" -- Avoid showing message about ins-completion-menu
