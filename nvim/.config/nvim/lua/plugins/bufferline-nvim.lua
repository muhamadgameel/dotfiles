-----------------------------------------------------------
-- Buffer line
-----------------------------------------------------------
local nnoremap = utils.mappings.nnoremap

require("bufferline").setup(
  {
    options = {
      numbers = "ordinal",
      diagnostics = "nvim_lsp",
      separator_style = "thick",
      always_show_bufferline = true,
      show_buffer_close_icons = true,
      show_close_icon = false,
      show_tab_indicators = true,
      right_mouse_command = "vertical sbuffer %d",
      left_mouse_command = "buffer %d",
      close_command = function(bufnum)
        require("bufdelete").bufdelete(bufnum, true)
      end,
      offsets = {{filetype = "NvimTree", text = "File Explorer", text_align = "center"}},
    },
  }
)

-- Navigate through buffers in order
-- e.g. if you change the order of buffers :bnext and :bprevious will not respect the custom ordering
nnoremap(
  "<leader>]", ":BufferLineCycleNext<cr>", "Buffer", "buffer_cycle_next",
  "Cycle to Next Buffer"
)
nnoremap(
  "<leader>[", ":BufferLineCyclePrev<cr>", "Buffer", "buffer_cycle_prev",
  "Cycle to Prev Buffer"
)

-- Move the current buffer backwards or forwards in the bufferline
nnoremap(
  "<leader>.", ":BufferLineMoveNext<cr>", "Buffer", "buffer_move_next",
  "Move Buffer to Next One"
)
nnoremap(
  "<leader>,", ":BufferLineMovePrev<cr>", "Buffer", "buffer_move_prev",
  "Move Buffer to Prev One"
)

-- Easy selection of a buffer in view
nnoremap("gb", ":BufferLinePick<cr>", "Buffer", "buffer_pick", "Pick a Buffer Visually")

-- Select a buffer by it's visible position in the bufferline
nnoremap("<A-1>", ":BufferLineGoToBuffer 1<cr>", "Buffer", "buffer_goto_1", "Go To Buffer 1")
nnoremap("<A-2>", ":BufferLineGoToBuffer 2<cr>", "Buffer", "buffer_goto_2", "Go To Buffer 2")
nnoremap("<A-3>", ":BufferLineGoToBuffer 3<cr>", "Buffer", "buffer_goto_3", "Go To Buffer 3")
nnoremap("<A-4>", ":BufferLineGoToBuffer 4<cr>", "Buffer", "buffer_goto_4", "Go To Buffer 4")
nnoremap("<A-5>", ":BufferLineGoToBuffer 5<cr>", "Buffer", "buffer_goto_5", "Go To Buffer 5")
nnoremap("<A-6>", ":BufferLineGoToBuffer 6<cr>", "Buffer", "buffer_goto_6", "Go To Buffer 6")
nnoremap("<A-7>", ":BufferLineGoToBuffer 7<cr>", "Buffer", "buffer_goto_7", "Go To Buffer 7")
nnoremap("<A-8>", ":BufferLineGoToBuffer 8<cr>", "Buffer", "buffer_goto_8", "Go To Buffer 8")
nnoremap("<A-9>", ":BufferLineGoToBuffer 9<cr>", "Buffer", "buffer_goto_9", "Go To Buffer 9")

-- close/delete buffer
nnoremap(
  "<leader>b", "<cmd>lua require('bufdelete').bufdelete(0, false)<cr>", "Buffer",
  "buffer_delete_current", "Delete Current Buffer"
)
