local show_files_details = false

return {
  -----------------------
  -- Oil (File Explorer)
  -----------------------
  {
    'stevearc/oil.nvim',
    event = 'VeryLazy',
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
        natural_order = true,
        is_always_hidden = function(name, _)
          return name == '..' or name == '.git' or name == '.DS_Store'
        end,
      },
    },
    keys = {
      { '_', mode = 'n', '<cmd>Oil<cr>', desc = 'Open Oil File Explorer' },
      {
        'gd',
        mode = 'n',
        function()
          show_files_details = not show_files_details
          if show_files_details then
            require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
          else
            require('oil').set_columns { 'icon' }
          end
        end,
        desc = 'Toggle File Details View',
      },
    },
  },

  -----------------------
  -- Sessions Management
  -----------------------
  {
    'rmagatti/auto-session',
    config = function()
      local auto_session = require 'auto-session'
      auto_session.setup {
        auto_restore = true,
        suppressed_dirs = { '~/', '~/Downloads', '~/Documents', '/' },
      }

      local keymap = vim.keymap.set

      keymap('n', '<leader>ss', '<cmd>SessionSave<cr>', { desc = 'Save session' })
      keymap('n', '<leader>sr', '<cmd>SessionRestore<cr>', { desc = 'Restore session' })
      keymap('n', '<leader>sf', '<cmd>SessionSearch<cr>', { desc = 'Search session' })
      keymap('n', '<leader>sd', '<cmd>SessionDelete<cr>', { desc = 'Delete session' })
    end,
  },
}
