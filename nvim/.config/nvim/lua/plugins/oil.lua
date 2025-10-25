local detail = false

return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    columns = { 'icon' },
    keymaps = {
      ['<C-j>'] = 'actions.select',
      ['q'] = 'actions.close',
      ['gd'] = {
        desc = 'Toggle file detail view',
        callback = function()
          detail = not detail
          if detail then
            require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
          else
            require('oil').set_columns { 'icon' }
          end
        end,
      },
    },
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        return name == '..' or name == '.git' or name == '.DS_Store'
      end,
    },
  },
  keys = {
    { '-', '<cmd>Oil<cr>', desc = 'Open Oil' },
  },
}
