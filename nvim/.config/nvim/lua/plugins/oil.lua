local detail = false

return {
  'stevearc/oil.nvim',
  lazy = false,
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
  config = function(_, opts)
    -- Make renames performed inside oil LSP-aware, so moving a .tsx file
    -- updates every import that referenced it.
    require('oil').setup(opts)

    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('oil-lsp-rename', { clear = true }),
      pattern = 'OilActionsPost',
      callback = function(event)
        if event.data.actions.type == 'move' then
          Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
        end
      end,
      desc = 'Notify the LSP about files renamed in oil',
    })
  end,
}
