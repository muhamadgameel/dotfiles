local nnoremap = utils.mappings.nnoremap

require("todo-comments").setup({})

nnoremap("<F4>", ":TodoTelescope<cr>", "Telescope", "telescope_find_todos", "Find All ToDos, Bugs ...")
