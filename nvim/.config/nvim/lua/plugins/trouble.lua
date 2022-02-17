local nnoremap = utils.mappings.nnoremap

require("trouble").setup({use_diagnostic_signs = true})

nnoremap("<F3>", ":TroubleToggle document_diagnostics<cr>", "Trouble",
         "trouble_list_diagnostics", "List Diagnostic")
