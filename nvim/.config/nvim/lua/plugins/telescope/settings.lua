local telescope = require("telescope")
local actions = require("telescope.actions")

-- Setup
telescope.setup {
  defaults = {
    file_ignore_patterns = {"Session.vim", "node_modules", ".cache"},
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-h>"] = actions.select_horizontal,
        ["<esc>"] = actions.close,
      },
    },
  },
  pickers = {
    find_files = {
      find_command = {"fd", "--type", "file", "--hidden", "--follow", "--exclude", ".git"},
    },
    buffers = {
      sort_lastused = true,
      mappings = {
        i = {["<C-x>"] = actions.delete_buffer},
        n = {["<C-x>"] = actions.delete_buffer},
      },
    },
    filetypes = {theme = "dropdown"},
    registers = {theme = "ivy"},
    colorscheme = {theme = "dropdown"},
    commands = {theme = "ivy"},
    command_history = {theme = "dropdown"},
    search_history = {theme = "dropdown"},
    keymaps = {theme = "dropdown"},
    spell_suggest = {theme = "cursor"},
    lsp_code_actions = {theme = "cursor"},
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {},
    },

  },
}

-- Load Extensions
telescope.load_extension("fzf")
telescope.load_extension("lsp_handlers")
telescope.load_extension("mapper")
telescope.load_extension("ui-select")
