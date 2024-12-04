-- highlight path part with some dimmed color (like comment)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'TelescopeResults',
  callback = function(ctx)
    vim.api.nvim_buf_call(ctx.buf, function()
      vim.fn.matchadd('TelescopeParent', '\t\t.*$')
      vim.api.nvim_set_hl(0, 'TelescopeParent', { link = 'Comment' })
    end)
  end,
})

-- show filename first, then path
local function filenameFirst(_, path)
  local tail = vim.fs.basename(path)
  local parent = vim.fs.dirname(path)
  if parent == '.' then
    return tail
  end
  return string.format('%s\t\t%s', tail, parent)
end

return {
  'nvim-telescope/telescope.nvim',
  event = 'VeryLazy',
  dependencies = {
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    },
  },
  config = function()
    local builtin = require 'telescope.builtin'

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { noremap = true, silent = true, desc = desc })
    end

    -- Built-in
    map('n', '<leader>oo', builtin.find_files, 'Files (Telescope)')
    map('n', '<leader>os', builtin.live_grep, 'Search (Telescope)')
    map('n', '<leader>oG', builtin.grep_string, 'Grep Search (Telescope)')
    map('n', '<leader>ob', builtin.buffers, 'Buffers (Telescope)')
    map('n', '<leader>oc', builtin.commands, 'Commands (Telescope)')
    map('n', '<leader>oC', builtin.colorscheme, 'Color Schemes (Telescope)')
    map('n', '<leader>of', builtin.filetypes, 'File Types (Telescope)')
    map('n', '<leader>ok', builtin.keymaps, 'Keymaps (Telescope)')
    map('n', '<leader>oh', builtin.help_tags, 'Help Tags (Telescope)')
    map('n', '<leader>om', builtin.man_pages, 'Man Pages (Telescope)')

    -- Git
    map('n', '<leader>ogs', '<cmd>Telescope git_status<cr>', 'Git Status (Telescope)')
    map('n', '<leader>ogb', '<cmd>Telescope git_branches<cr>', 'Git Branches (Telescope)')
    map('n', '<leader>ogc', '<cmd>Telescope git_commits<cr>', 'Git Commits (Telescope)')

    -- Todo Comments
    map('n', '<leader>ot', '<cmd>TodoTelescope<cr>', 'TODO comments (Telescope)')

    -- Trouble
    map('n', '<leader>ox', '<cmd>Trouble<cr>', 'Trouble (Telescope)')

    local telescope = require 'telescope'
    local icons = require 'core.icons'
    local actions = require 'telescope.actions'
    local action_layout = require 'telescope.actions.layout'
    local trouble = require 'trouble.sources.telescope'

    telescope.setup {
      defaults = {
        prompt_prefix = icons.ui.Telescope .. ' ',
        selection_caret = icons.ui.Forward .. ' ',
        path_display = { 'smart' },
        entry_prefix = '   ',
        initial_mode = 'insert',
        selection_strategy = 'reset',
        color_devicons = true,
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--hidden',
          '--glob=!.git/',
        },

        mappings = {
          i = {
            ['<c-t>'] = trouble.open,
            ['<C-j>'] = actions.move_selection_next,
            ['<C-k>'] = actions.move_selection_previous,
            ['<C-x>'] = actions.select_horizontal,
            ['<C-v>'] = actions.select_vertical,
            ['<C-p>'] = action_layout.toggle_preview,
            ['<esc>'] = actions.close,
          },
          n = {
            ['j'] = actions.move_selection_next,
            ['k'] = actions.move_selection_previous,
            ['q'] = actions.close,
            ['<c-t>'] = trouble.open,
            ['<C-p>'] = action_layout.toggle_preview,
            ['<esc>'] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          find_command = { 'fd', '--type', 'file', '--hidden', '--follow', '--exclude', '.git' },
          path_display = filenameFirst,
          theme = 'dropdown',
          previewer = false,
        },
        live_grep = {
          previewer = true,
        },
        grep_string = {
          previewer = true,
        },
        buffers = {
          theme = 'dropdown',
          previewer = false,
          initial_mode = 'normal',
          sort_lastused = true,
          mappings = {
            i = { ['<C-x>'] = actions.delete_buffer },
            n = { ['dd'] = actions.delete_buffer },
          },
        },
        planets = {
          show_pluto = true,
          show_moon = true,
        },
        colorscheme = {
          theme = 'dropdown',
          enable_preview = true,
        },
        commands = {
          theme = 'ivy',
        },
        filetypes = {
          theme = 'dropdown',
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = 'smart_case',
        },
      },
    }

    telescope.load_extension 'fzf'
  end,
}
