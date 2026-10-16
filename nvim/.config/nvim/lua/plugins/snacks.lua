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

-- Shell terminals, toggled the way toggleterm did it: backslash opens and
-- closes the one used last, and a count picks another (2\). They are kept here
-- because Snacks.terminal() looks its terminals up by working directory, so a
-- `:cd` would start a new one.
local terminals, last_terminal = {}, 1

local function terminal()
  if vim.v.count > 0 then
    last_terminal = vim.v.count
  end
  local id = last_terminal
  local term = terminals[id]
  if term and term:buf_valid() then
    return term:toggle()
  end

  term = Snacks.terminal.open(nil, {
    count = id,
    -- snacks keeps a terminal open, with an error, when its command exits
    -- non-zero. Right for a tool, wrong for a shell, so TermClose closes it below.
    auto_close = false,
    win = {
      keys = {
        -- Backslash closes it too, so Alt+\ is how to type one in here.
        hide_backslash = {
          '\\',
          function(self)
            last_terminal = id
            self:hide()
          end,
          mode = 't',
          desc = 'Hide Terminal',
        },
        type_backslash = {
          '<M-\\>',
          function()
            vim.api.nvim_chan_send(vim.b.terminal_job_id, '\\')
          end,
          mode = 't',
          desc = 'Type a backslash',
        },
      },
    },
  })
  term:on('TermClose', function()
    term:close()
    vim.cmd.checktime()
  end, { buf = true })
  terminals[id] = term
end

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true }, -- Disable heavy features on huge files
    quickfile = { enabled = true }, -- Render the file before loading plugins
    input = { enabled = true }, -- Better vim.ui.input (LSP rename)
    notifier = { enabled = true }, -- Needed since cmdheight = 0

    -- Replaces vim-illuminate, via native LSP document highlight
    words = { enabled = true },

    -- Replaces neoscroll. Animates through WinScrolled rather than remapping
    -- keys, so <C-d>/<C-u> stay ordinary mappings.
    scroll = { enabled = true },

    -- Replaces indent-blankline (and its hand-rolled highlight hook)
    indent = {
      enabled = true,
      animate = { enabled = false },
    },

    -- A shell opens as a bottom split by default. As a float it needs a border to
    -- stand out from the editor behind it; `true` follows 'winborder' (rounded).
    terminal = { win = { position = 'float', border = true } },

    styles = {
      notification = { wo = { wrap = true } },
    },

    picker = {
      formatters = {
        file = { filename_first = true }, -- Matches the old telescope path_display
      },
      sources = {
        files = { hidden = true }, -- Hidden files included, .git excluded via exclude below
        grep = { hidden = true },
        todo_comments = { hidden = true },
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
    { '\\', terminal, desc = 'Toggle Terminal' },

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
      mode = { 'n', 'x' },
    },
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Lazygit',
    },
    {
      '<leader>gl',
      function()
        Snacks.lazygit.log()
      end,
      desc = 'Lazygit log',
    },
    {
      '<leader>gf',
      function()
        Snacks.lazygit.log_file()
      end,
      desc = 'Lazygit file history',
    },

    -- Reference navigation (replaces vim-illuminate's motions)
    {
      ']]',
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = 'Next reference',
    },
    {
      '[[',
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = 'Prev reference',
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
