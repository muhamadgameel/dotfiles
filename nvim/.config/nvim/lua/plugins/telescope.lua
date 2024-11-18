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

    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Built-in
    keymap('n', '<leader>oo', builtin.find_files, opts)
    keymap('n', '<leader>os', builtin.live_grep, opts)
    keymap('n', '<leader>oG', builtin.grep_string, opts)
    keymap('n', '<leader>ob', builtin.buffers, opts)
    keymap('n', '<leader>oc', builtin.commands, opts)
    keymap('n', '<leader>oC', builtin.colorscheme, opts)
    keymap('n', '<leader>of', builtin.filetypes, opts)
    keymap('n', '<leader>ok', builtin.keymaps, opts)
    keymap('n', '<leader>oh', builtin.help_tags, opts)
    keymap('n', '<leader>om', builtin.man_pages, opts)

    -- Git
    keymap('n', '<leader>ogs', '<cmd>Telescope git_status<cr>', opts)
    keymap('n', '<leader>ogb', '<cmd>Telescope git_branches<cr>', opts)
    keymap('n', '<leader>ogc', '<cmd>Telescope git_commits<cr>', opts)

    -- Todo Comments
    local todo_comments_require_ok = pcall(require, 'todo-comments')
    if todo_comments_require_ok then
      keymap('n', '<leader>ot', '<cmd>TodoTelescope<cr>', opts)
    end

    local telescope = require 'telescope'
    local icons = require 'core.icons'
    local actions = require 'telescope.actions'
    local action_layout = require 'telescope.actions.layout'

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
