-- snacks.nvim replaces telescope + telescope-fzf-native, vim-illuminate (words),
-- neoscroll (scroll) and indent-blankline (indent).

-- Terminals have no real alpha, so "more transparent" indent guides means
-- blending their colour toward the window background. 0 = invisible (pure
-- background), 1 = the colour at full strength. Tune these two to taste.
local INDENT_ALPHA = 0.30 -- ordinary indent guides (default source: NonText)
local SCOPE_ALPHA = 0.50 -- the active scope guide (default source: Special)

-- Recomputed from the *source* groups rather than from SnacksIndent* itself,
-- so re-running on every ColorScheme cannot compound into a fade-to-nothing.
local function dim_indent_guides()
  local color, blend = Snacks.util.color, Snacks.util.blend
  -- color() returns nil on a transparent colorscheme; fall back to a dark base
  local bg = color('Normal', 'bg') or '#1f1f28'
  local indent_fg = color 'NonText' or '#54546d'
  local scope_fg = color 'Special' or '#7fb4ca'
  vim.api.nvim_set_hl(0, 'SnacksIndent', { fg = blend(indent_fg, bg, INDENT_ALPHA) })
  vim.api.nvim_set_hl(0, 'SnacksIndentScope', { fg = blend(scope_fg, bg, SCOPE_ALPHA) })
end
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true }, -- Disable heavy features on huge files
    quickfile = { enabled = true }, -- Render the file before loading plugins
    bufdelete = { enabled = true }, -- Close buffers without wrecking the layout
    input = { enabled = true }, -- Better vim.ui.input (LSP rename)
    rename = { enabled = true }, -- LSP-aware file rename (wired into oil below)
    gitbrowse = { enabled = true },
    notifier = { enabled = true, timeout = 3000 }, -- Needed since cmdheight = 0

    -- Replaces vim-illuminate, via native LSP document highlight
    words = { enabled = true, debounce = 200 },

    -- Replaces neoscroll. Animates through WinScrolled rather than remapping
    -- keys, so <C-d>/<C-u> stay ordinary mappings.
    scroll = { enabled = true },

    -- Replaces indent-blankline (and its hand-rolled highlight hook)
    indent = {
      enabled = true,
      indent = { char = '│' },
      scope = { char = '│', hl = 'SnacksIndentScope' },
      chunk = { enabled = false },
      animate = { enabled = false },
    },

    styles = {
      notification = { wo = { wrap = true } },
    },

    picker = {
      ui_select = true, -- Route vim.ui.select through the picker
      formatters = {
        file = { filename_first = true }, -- Matches the old telescope path_display
      },
      sources = {
        files = { hidden = true }, -- Hidden files included, .git excluded via exclude below
        grep = { hidden = true },
        explorer = { hidden = true },
        buffers = {
          layout = 'select',
          current = false,
          sort_lastused = true,
          -- Scoped here: the bufdelete action only exists on this source
          win = { list = { keys = { ['dd'] = 'bufdelete' } } },
        },
        colorschemes = { layout = 'select' },
        registers = { layout = 'select' },
        filetypes = { layout = 'select' },
        commands = { layout = 'ivy' },
        autocmds = { layout = 'ivy' },
        keymaps = { layout = 'ivy' },
      },
      exclude = { '.git' },
      win = {
        input = {
          keys = {
            -- Preserve the old telescope navigation muscle memory
            ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
            ['<C-x>'] = { 'edit_split', mode = { 'i', 'n' } },
            ['<C-v>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
            ['<C-p>'] = { 'toggle_preview', mode = { 'i', 'n' } },
            ['<Esc>'] = { 'close', mode = { 'i', 'n' } },
          },
        },
        list = {
          keys = {
            ['<C-x>'] = 'edit_split',
            ['<C-v>'] = 'edit_vsplit',
          },
        },
      },
    },
  },
  keys = {
    -- General (ported 1:1 from the old telescope <leader>o* maps)
    {
      '<leader>oo',
      function()
        Snacks.picker.files()
      end,
      desc = 'Find Files',
    },
    {
      '<leader>os',
      function()
        Snacks.picker.grep()
      end,
      desc = 'Live Search',
    },
    {
      '<leader>oS',
      function()
        Snacks.picker.spelling()
      end,
      desc = 'Spell Suggest',
    },
    {
      '<leader>ob',
      function()
        Snacks.picker.buffers()
      end,
      desc = 'Buffers',
    },
    {
      '<leader>oh',
      function()
        Snacks.picker.help()
      end,
      desc = 'Help Tags',
    },
    {
      '<leader>oc',
      function()
        Snacks.picker.commands()
      end,
      desc = 'Commands',
    },
    {
      '<leader>oC',
      function()
        Snacks.picker.colorschemes()
      end,
      desc = 'Color Schemes',
    },
    {
      '<leader>of',
      function()
        Snacks.picker.filetypes()
      end,
      desc = 'File Types',
    },
    {
      '<leader>ok',
      function()
        Snacks.picker.keymaps()
      end,
      desc = 'Keymaps',
    },
    {
      '<leader>oq',
      function()
        Snacks.picker.qflist()
      end,
      desc = 'QuickFix List',
    },
    {
      '<leader>oa',
      function()
        Snacks.picker.autocmds()
      end,
      desc = 'Auto Commands',
    },
    {
      '<leader>or',
      function()
        Snacks.picker.registers()
      end,
      desc = 'Registers',
    },
    {
      '<leader>od',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = 'Diagnostics',
    },
    -- Additions that have no telescope equivalent in the old config
    {
      '<leader>ow',
      function()
        Snacks.picker.grep_word()
      end,
      desc = 'Grep word under cursor',
      mode = { 'n', 'x' },
    },
    {
      '<leader>oR',
      function()
        Snacks.picker.resume()
      end,
      desc = 'Resume last picker',
    },
    {
      '<leader>o/',
      function()
        Snacks.picker.lines()
      end,
      desc = 'Search current buffer',
    },
    {
      '<leader>ou',
      function()
        Snacks.picker.undo()
      end,
      desc = 'Undo history',
    },

    -- Git
    {
      '<leader>ogs',
      function()
        Snacks.picker.git_status()
      end,
      desc = 'Git Status',
    },
    {
      '<leader>ogb',
      function()
        Snacks.picker.git_branches()
      end,
      desc = 'Git Branches',
    },
    {
      '<leader>ogc',
      function()
        Snacks.picker.git_log()
      end,
      desc = 'Git Commits',
    },
    {
      '<leader>ogf',
      function()
        Snacks.picker.git_log_file()
      end,
      desc = 'Git Log (file)',
    },
    {
      '<leader>gY',
      function()
        Snacks.gitbrowse()
      end,
      desc = 'Open in browser',
      mode = { 'n', 'v' },
    },

    -- Reference navigation (replaces vim-illuminate's motions)
    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = 'Next reference',
      mode = { 'n', 't' },
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = 'Prev reference',
      mode = { 'n', 't' },
    },
  },
  config = function(_, opts)
    require('snacks').setup(opts)
    dim_indent_guides()
    -- Colourschemes reset highlight groups, so recompute after every switch.
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('snacks-indent-dim', { clear = true }),
      callback = dim_indent_guides,
      desc = 'Re-dim snacks indent guides',
    })
  end,
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Make `:lua =expr` and vim.print use the snacks pretty printer
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        vim.print = _G.dd
      end,
    })
  end,
}
