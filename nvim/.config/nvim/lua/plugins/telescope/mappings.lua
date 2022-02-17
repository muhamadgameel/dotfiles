local nnoremap = utils.mappings.nnoremap

-- general
nnoremap("<leader>oo", "<cmd>lua require('telescope.builtin').find_files()<cr>", "Telescope", "telescope_find_files", "Find Files")
nnoremap("<leader>og", "<cmd>lua require('telescope.builtin').live_grep()<cr>", "Telescope", "telescope_grep", "Live Grep")
nnoremap("<leader>or", "<cmd>lua require('telescope.builtin').registers()<cr>", "Telescope", "telescope_registers", "Registers")
nnoremap("<leader>ob", "<cmd>lua require('telescope.builtin').buffers()<cr>", "Telescope", "telescope_buffers", "Buffers")
nnoremap("<leader>oh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", "Telescope", "telescope_help_tags", "Help Tags")
nnoremap("<leader>oC", "<cmd>lua require('telescope.builtin').colorscheme()<cr>", "Telescope", "telescope_color_schemes", "Color Schemes")
nnoremap("<leader>oc", "<cmd>lua require('telescope.builtin').commands()<cr>", "Telescope", "telescope_commands", "Commands")
nnoremap("<leader>o;", "<cmd>lua require('telescope.builtin').command_history()<cr>", "Telescope", "telescope_command_history", "Commad Line History")
nnoremap("<leader>o/", "<cmd>lua require('telescope.builtin').search_history()<cr>", "Telescope", "telescope_search_history", "Search History")
nnoremap("<leader>op", "<cmd>lua require('telescope.builtin').man_pages()<cr>", "Telescope", "telescope_man_pages", "Man Pages")
nnoremap("<leader>om", "<cmd>lua require('telescope.builtin').marks()<cr>", "Telescope", "telescope_mark", "Marks")
nnoremap("<leader>oK", "<cmd>lua require('telescope.builtin').keymaps()<cr>", "Telescope", "telescope_keymaps", "All Keymaps")
nnoremap("<leader>ok", "<cmd>Telescope mapper<cr>", "Telescope", "telescope_mapped_keys", "Mapped Keys")
nnoremap("<leader>of", "<cmd>lua require('telescope.builtin').filetypes()<cr>", "Telescope", "telescope_file_types", "FileTypes")
nnoremap("<leader>os", "<cmd>lua require('telescope.builtin').spell_suggest()<cr>", "Telescope", "telescope_spell_suggest", "Spell Suggests")

-- lsp
nnoremap("<leader>cd", "<cmd>lua require('telescope.builtin').lsp_workspace_diagnostics()<cr>", "Telescope", "telescope_diagnostics", "Diagnostic List")
nnoremap("<leader>ca", "<cmd>lua require('telescope.builtin').lsp_code_actions()<cr>", "Telescope", "telescope_code_actions", "Code Actions")

-- git
nnoremap("<leader>gf", "<cmd>lua require('telescope.builtin').git_files()<cr>", "Telescope", "telescope_git_files", "Git Files")
nnoremap("<leader>gs", "<cmd>lua require('telescope.builtin').git_status()<cr>", "Telescope", "telescope_git_status", "Git Status")
nnoremap("<leader>gb", "<cmd>lua require('telescope.builtin').git_branches()<cr>", "Telescope", "telescope_git_branches", "Git Branches")
nnoremap("<leader>gc", "<cmd>lua require('telescope.builtin').git_commits()<cr>", "Telescope", "telescope_git_commits", "Git Commits")
nnoremap("<leader>gt", "<cmd>lua require('telescope.builtin').git_stash()<cr>", "Telescope", "telescope_git_stash", "Git Stash")
