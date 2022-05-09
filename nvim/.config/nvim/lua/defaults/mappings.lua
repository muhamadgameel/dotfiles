local nnoremap = utils.mappings.nnoremap
local vnoremap = utils.mappings.vnoremap
local inoremap = utils.mappings.inoremap

-- easier command mode access swap : with ;
nnoremap(";", ":", "Remaps", "access_command_mode", "Command Mode ")
nnoremap(":", ";")

-- center buffer window when moving up and down using Ctrl+{u,d}
nnoremap("<C-u>", "<C-u>zz", "Remaps", "scroll_window_up", "Scroll Window Up")
nnoremap("<C-d>", "<C-d>zz", "Remaps", "scroll_window_down", "Scroll Window Down")

-- when jumping in search, center buffer window
nnoremap("n", "nzzzv", "Remaps", "next_search_result", "Next Search Result")
nnoremap("N", "Nzzzv", "Remaps", "prev_search_result", "Previous Search Result")

-- when lines wrap move up/down by visual line
nnoremap("j", "gj")
nnoremap("k", "gk")
vnoremap("j", "gj")
vnoremap("k", "gk")

-- disable this unusefull and mostly mistyped command line
nnoremap("q:", "<nop>")

-- clear search highlighting on escape
nnoremap("<esc>", ":noh<cr><esc>")

-- upper case a word {(i)Ctrl, (n)leader}+u
inoremap("<C-u>", "<esc>mmviwU`ma", "Defaults", "upper_case_word_i", "UpperCase a Word")
nnoremap("<leader>u", "mmviwU`m", "Defaults", "upper_case_word_n", "UpperCase a Word")

-- lower case a word {(i)Ctrl, (n)leader}+l
-- FIXME: <c-l> sends a clear event to vim or shell, disable that
inoremap("<C-l>", "<esc>mmviwu`ma", "Defaults", "lower_case_word_i", "LowerCase a Word")
nnoremap("<leader>l", "mmviwu`m", "Defaults", "lower_case_word_n", "LowerCase a Word")

-- capitalize a word {(i)Ctrl, (n)leader}+c
inoremap("<C-c>", "<esc>mmviwb<esc>vU`ma", "Defaults", "capitalize_word_i", "Capitalize a Word")
nnoremap("<leader>cc", "mmviwb<esc>vU`m", "Defaults", "capitalize_word_n", "Capitalize a Word")

-- highlight last inserted/yanked text
nnoremap(
  "gV", "`[v`]", "Defaults", "highlight_last_yanked_text", "Highlight Last Yanked/Inserted"
)

vnoremap(
  "<LeftRelease>", "\"+ygv", "Defaults", "copy_mouse_select",
  "Copy Selection With Mouse Left Release"
)

-- act like D and C
nnoremap("Y", "y$", "Defaults", "copy_to_end_of_line", "Copy till End of The Line")

-- beginning & end of line
nnoremap("H", "^", "Defaults", "start_of_line", "Start of Line")
nnoremap("L", "$", "Defaults", "end_of_line", "End of Line")

-- toggle spell checking
nnoremap(
  "<F2>", ":setlocal spell! spell?<cr>", "Defaults", "toggle_spell_checker",
  "Toggle Spell Checker"
)

-- paste inline from clipboard and respect formatting
inoremap(
  "<c-p>", "<esc>:set paste<cr>\"+p:set nopaste<cr>a", "Defaults", "paste_clipboard",
  "Paste From ClipBoard"
)

-- move up/down completion menu with Ctrl+{j,k}
inoremap(
  "<C-j>", "pumvisible() ? '<C-n>' : '<C-j>'", "Defaults", "move_down_in_compl_menu",
  "Move Down in Completion Menu"
)
inoremap(
  "<C-k>", "pumvisible() ? '<C-p>' : '<C-k>'", "Defaults", "move_up_in_compl_menu",
  "Move Up in completion Menu"
)

-- exit window
nnoremap("<leader>q", "<cmd>q<cr>", "Window", "exit_window", "Exit Window")
nnoremap("<leader>Q", "<cmd>q!<cr>", "Window", "exit_window_force", "Force Exit Window")

-- save/delete buffer
nnoremap("<leader>w", ":w<cr>", "Buffer", "default_buffer_save", "Save Buffer")
nnoremap("<leader>b", ":bd<cr>", "Buffer", "default_buffer_delete", "Delete Buffer")

-- faster buffer movement
nnoremap("<leader>]", ":bnext<cr>", "Buffer", "default_buffer_cycle_next", "Next Buffer")
nnoremap("<leader>[", ":bprev<cr>", "Buffer", "default_buffer_cycle_prev", "Previous Buffer")

-- swap between the last two buffers
nnoremap(
  "<leader>sw", "<C-^>", "Buffer", "default_buffer_swap_last_two", "Swap The Last Two Buffers"
)
