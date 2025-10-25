return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    attach_to_untracked = true,
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
      local gs = require 'gitsigns'

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end

      -- Navigation
      map('n', ']h', gs.next_hunk, 'Next Hunk')
      map('n', '[h', gs.prev_hunk, 'Prev Hunk')

      -- Actions
      map('v', '<leader>hs', function()
        gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Stage Hunk')
      map('v', '<leader>hr', function()
        gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Reset Hunk')
      map('n', '<leader>hs', gs.stage_hunk, 'Stage Hunk')
      map('n', '<leader>hr', gs.reset_hunk, 'Reset Hunk')
      map('n', '<leader>hS', gs.stage_buffer, 'Stage Buffer')
      map('n', '<leader>hR', gs.reset_buffer, 'Reset Buffer')
      map('n', '<leader>hu', gs.undo_stage_hunk, 'Unstage Hunk')
      map('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
      map('n', '<leader>hb', gs.blame_line, 'Toggle line blame')
      map('n', '<leader>hd', gs.diffthis, 'Diff this')
      map('n', '<leader>hD', function()
        gs.diffthis '@'
      end, 'Diff against last commit')

      -- Toggles
      map('n', '<leader>tb', gs.toggle_current_line_blame, 'Toggle git show blame line')
      map('n', '<leader>tD', gs.preview_hunk_inline, 'Toggle git show Deleted')
      map('n', '<leader>tx', gs.toggle_deleted, 'Toggle git deleted hunks')

      -- Text object
      map({ 'o', 'x' }, 'ih', gs.select_hunk, 'Gitsigns select hunk')
    end,
  },
}
