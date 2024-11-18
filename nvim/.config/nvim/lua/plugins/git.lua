return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufRead', 'BufNewFile' },
  config = function()
    require('gitsigns').setup {
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 100,
      },
      preview_config = {
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local keymap = vim.keymap.set

        -- Navigation
        keymap('n', ']h', function()
          if vim.wo.diff then
            return ']h'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })

        keymap('n', '[h', function()
          if vim.wo.diff then
            return '[h'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr })

        -- Actions
        keymap('n', '<leader>hs', gs.stage_hunk)
        keymap('n', '<leader>hr', gs.reset_hunk)
        keymap('n', '<leader>hu', gs.undo_stage_hunk)
        keymap('v', '<leader>hs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end)
        keymap('v', '<leader>hr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end)
        keymap('n', '<leader>hS', gs.stage_buffer)
        keymap('n', '<leader>hR', gs.reset_buffer)
        keymap('n', '<leader>hp', gs.preview_hunk)
        keymap('n', '<leader>hB', function()
          gs.blame_line { full = true }
        end)
        keymap('n', '<leader>hd', gs.diffthis)
        keymap('n', '<leader>hb', gs.toggle_current_line_blame)
        keymap('n', '<leader>hx', gs.toggle_deleted)
        keymap('n', '<leader>hl', '<cmd>Gitsigns setloclist<cr>')
        keymap('n', '<leader>hq', '<cmd>Gitsigns setqflist<cr>')

        -- Text object
        keymap({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      end,
    }
  end,
}
