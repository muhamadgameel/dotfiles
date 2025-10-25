local opt = vim.opt

----------------------------------------------------------------------------------
-- Indentation & Formatting
----------------------------------------------------------------------------------
opt.expandtab = true
opt.shiftwidth = 2 -- Spaces per indent level (>>, <<, ==)
opt.tabstop = 2 -- Spaces per Tab character
opt.softtabstop = 2 -- Spaces per Tab in insert mode
opt.shiftround = true -- Round indent to shiftwidth multiple
opt.smartindent = true
opt.breakindent = true -- Wrapped lines preserve indent
opt.formatoptions = 'jcroqlnt'

----------------------------------------------------------------------------------
-- Text Display & Wrapping
----------------------------------------------------------------------------------
opt.wrap = false
opt.linebreak = true -- Wrap at word boundaries
opt.textwidth = 120
opt.list = true -- Show invisible characters
opt.listchars = {
  tab = '» ',
  trail = '·',
  nbsp = '␣',
  extends = '❯',
  precedes = '❮',
}

----------------------------------------------------------------------------------
-- UI Appearance
----------------------------------------------------------------------------------
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.cursorlineopt = 'number' -- Only highlight line number
opt.signcolumn = 'yes' -- Always show sign column
opt.showmode = false -- Mode shown in statusline instead
opt.showcmd = false
opt.laststatus = 3 -- Global statusline
opt.showtabline = 0 -- Never show tabline
opt.fillchars = {
  foldopen = '-',
  foldclose = '+',
  fold = ' ',
  foldsep = ' ',
  vert = '│',
  diff = '╱',
  eob = ' ', -- Hide ~ for empty lines
}
opt.pumheight = 10 -- Max items in completion popup
opt.pumblend = 10 -- Popup transparency
opt.winblend = 10 -- Floating window transparency
opt.cmdheight = 0 -- Hide command line when not used

----------------------------------------------------------------------------------
-- Navigation & Scrolling
----------------------------------------------------------------------------------
opt.scrolloff = 10 -- Keep 10 lines above/below cursor
opt.sidescrolloff = 10 -- Keep 10 columns left/right of cursor
opt.smoothscroll = true -- Smooth <C-d>/<C-u> scrolling
opt.jumpoptions = 'stack' -- Jumplist behaves like browser history
opt.whichwrap:append '<,>,[,],h,l'
opt.virtualedit = 'block' -- Allow cursor past EOL in visual block

----------------------------------------------------------------------------------
-- Window & Split Behavior
----------------------------------------------------------------------------------
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = 'screen' -- Reduce scrolling when splitting
opt.equalalways = false -- Don't auto-resize splits
opt.title = true
opt.titlestring = "%{substitute(getcwd(), $HOME, '~', '')}"

----------------------------------------------------------------------------------
-- Search & Replace
----------------------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true -- Case-sensitive if uppercase used
opt.gdefault = true -- :s/// replaces ALL matches (not just first)
opt.inccommand = 'split' -- Live preview :substitute in split window
opt.grepprg = 'rg --vimgrep'
opt.grepformat = '%f:%l:%c:%m'

----------------------------------------------------------------------------------
-- Completion
----------------------------------------------------------------------------------
opt.completeopt = { 'menu', 'menuone', 'noselect', 'preview' }
opt.infercase = true -- Infer case in keyword completion
opt.wildmode = 'longest:full,full'
opt.wildoptions = 'pum' -- Command completion as popup
opt.wildignorecase = true
opt.wildignore:append {
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

----------------------------------------------------------------------------------
-- Files & Persistence
----------------------------------------------------------------------------------
opt.confirm = true -- Ask to save before quitting
opt.autowrite = true -- Auto-save before :next, :make, etc.
opt.undofile = true -- Persistent undo across sessions
opt.undolevels = 10000
opt.swapfile = false
opt.writebackup = false
opt.sessionoptions =
  { 'blank', 'buffers', 'curdir', 'folds', 'help', 'tabpages', 'winsize', 'winpos', 'terminal', 'localoptions' }

----------------------------------------------------------------------------------
-- Editing Behavior
----------------------------------------------------------------------------------
opt.mouse = 'a'
-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  opt.clipboard = 'unnamedplus'
end)
opt.showmatch = true -- Briefly jump to matching bracket
opt.timeoutlen = 500 -- Wait 500ms for mapped sequences
opt.updatetime = 250 -- CursorHold delay (affects plugins)
opt.fixeol = false -- Don't add final newline
opt.iskeyword:append '-' -- Treat kebab-case as one word

----------------------------------------------------------------------------------
-- Spelling
----------------------------------------------------------------------------------
opt.spelllang = { 'en_us' }
opt.spelloptions = 'camel' -- Spell check camelCase words separately

----------------------------------------------------------------------------------
-- Folding
----------------------------------------------------------------------------------
opt.foldmethod = 'indent'
opt.foldlevel = 99
opt.foldlevelstart = 99 -- Always open files unfolded
opt.foldcolumn = '1'

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
  'vertical', -- Makes diffs open vertically by default (common preference).
}

----------------------------------------------------------------------------------
-- Performance & UI Updates
----------------------------------------------------------------------------------
opt.redrawtime = 1500 -- Max time for syntax highlighting
opt.synmaxcol = 500 -- Syntax highlight only first 500 columns
opt.scrollback = 100000 -- Terminal scrollback lines

----------------------------------------------------------------------------------
-- Tab Pages
----------------------------------------------------------------------------------
opt.tabclose = 'left'

----------------------------------------------------------------------------------
-- Messages
----------------------------------------------------------------------------------
opt.shortmess:append 'c' -- Don't show completion messages
opt.report = 0 -- Always report changed lines

----------------------------------------------------------------------------------
-- External Integrations
----------------------------------------------------------------------------------
vim.g.netrw_liststyle = 3 -- Tree view
