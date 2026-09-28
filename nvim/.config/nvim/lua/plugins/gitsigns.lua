return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    attach_to_untracked = true,
    signs_staged_enable = true, -- Distinct signs for staged changes
    current_line_blame_opts = {
      delay = 100,
    },
    preview_config = {
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
      map('n', ']h', function()
        gs.nav_hunk 'next'
      end, 'Next Hunk')
      map('n', '[h', function()
        gs.nav_hunk 'prev'
      end, 'Prev Hunk')

      -- Actions. stage_hunk toggles: run it on a staged sign to unstage
      map('x', '<leader>hs', function()
        gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Stage Hunk')
      map('x', '<leader>hr', function()
        gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Reset Hunk')
      map('n', '<leader>hs', gs.stage_hunk, 'Stage/unstage Hunk')
      map('n', '<leader>hr', gs.reset_hunk, 'Reset Hunk')
      map('n', '<leader>hS', gs.stage_buffer, 'Stage Buffer')
      map('n', '<leader>hR', gs.reset_buffer, 'Reset Buffer')
      map('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
      map('n', '<leader>hi', gs.preview_hunk_inline, 'Preview Hunk inline')
      map('n', '<leader>hb', function()
        gs.blame_line { full = true }
      end, 'Blame line')
      map('n', '<leader>hB', gs.blame, 'Blame buffer')
      map('n', '<leader>hd', gs.diffthis, 'Diff this')
      map('n', '<leader>hD', function()
        gs.diffthis '@'
      end, 'Diff against last commit')
      map('n', '<leader>hq', gs.setqflist, 'Hunks to quickfix')

      -- Toggles
      map('n', '<leader>tb', gs.toggle_current_line_blame, 'Toggle line blame')
      map('n', '<leader>tw', gs.toggle_word_diff, 'Toggle word diff')

      -- Text object
      map({ 'o', 'x' }, 'ih', gs.select_hunk, 'Gitsigns select hunk')
    end,
  },
}
