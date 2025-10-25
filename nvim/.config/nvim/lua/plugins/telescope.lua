local keymap = vim.keymap.set

return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    { 'nvim-tree/nvim-web-devicons' },
  },
  config = function()
    -- General
    local builtin = require 'telescope.builtin'
    keymap('n', '<leader>oo', builtin.find_files, { desc = 'Find Files' })
    keymap('n', '<leader>os', builtin.live_grep, { desc = 'Live Search' })
    keymap('n', '<leader>oS', builtin.spell_suggest, { desc = 'Spell Suggest' })
    keymap('n', '<leader>ob', builtin.buffers, { desc = 'Buffers' })
    keymap('n', '<leader>oh', builtin.help_tags, { desc = 'Help Tags' })
    keymap('n', '<leader>oc', builtin.commands, { desc = 'Commands' })
    keymap('n', '<leader>oC', builtin.colorscheme, { desc = 'Color Schemes' })
    keymap('n', '<leader>ot', builtin.filetypes, { desc = 'File Types' })
    keymap('n', '<leader>ok', builtin.keymaps, { desc = 'Keymaps' })
    keymap('n', '<leader>oq', builtin.quickfix, { desc = 'QuickFix List' })
    keymap('n', '<leader>oa', builtin.autocommands, { desc = 'Auto Commands' })
    keymap('n', '<leader>or', builtin.registers, { desc = 'Registers' })
    keymap('n', '<leader>od', builtin.diagnostics, { desc = 'Diagnostics' })
    -- Git
    keymap('n', '<leader>ogs', builtin.git_status, { desc = 'Git Status' })
    keymap('n', '<leader>ogb', builtin.git_branches, { desc = 'Git Branches' })
    keymap('n', '<leader>ogc', builtin.git_commits, { desc = 'Git Commits' })
    keymap('n', '<leader>ogt', builtin.git_stash, { desc = 'Git Stash' })

    local telescope = require 'telescope'
    local telescopeConfig = require 'telescope.config'
    local actions = require 'telescope.actions'
    local action_layout = require 'telescope.actions.layout'

    -- Grep, support search in hidden files, and trim white space for results
    local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }
    table.insert(vimgrep_arguments, '--hidden')
    table.insert(vimgrep_arguments, '--trim')
    table.insert(vimgrep_arguments, '--glob')
    table.insert(vimgrep_arguments, '!**/.git/*')

    telescope.setup {
      defaults = {
        prompt_prefix = '🔍' .. ' ',
        selection_caret = '' .. ' ', -- TODO: choose another icon
        path_display = { 'filename_first' },
        initial_mode = 'insert',
        dynamic_preview_title = true,
        vimgrep_arguments = vimgrep_arguments,
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
        },
        buffers = {
          theme = 'dropdown',
          previewer = false,
          sort_lastused = true,
          mappings = {
            i = { ['<C-x>'] = actions.delete_buffer + actions.move_to_top },
            n = { ['dd'] = actions.delete_buffer },
          },
        },
        colorscheme = {
          theme = 'dropdown',
          previewer = false,
          enable_preview = true,
        },
        commands = {
          theme = 'ivy',
        },
        autocommands = {
          theme = 'ivy',
        },
        keymaps = {
          theme = 'ivy',
        },
        filetypes = {
          theme = 'dropdown',
        },
        registers = {
          theme = 'dropdown',
        },
      },
    }

    telescope.load_extension 'fzf'
  end,
}
