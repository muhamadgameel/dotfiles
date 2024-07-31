local M = {
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {},
}

function M.config()
  require("typescript-tools").setup {
    on_attach = function(_, bufnr)
      local opts = { buffer = bufnr, silent = true }
      local keymap = vim.keymap.set

      keymap("n", "go", "<cmd>TSToolsOrganizeImports<cr>", opts)
      keymap("n", "gI", "<cmd>TSToolsAddMissingImports<cr>", opts)
      keymap("n", "gf", "<cmd>TSToolsFixAll<cr>", opts)
      keymap("n", "<leader>gd", "<cmd>TSToolsGoToSourceDefinition<cr>", opts)
      keymap("n", "<leader>gr", "<cmd>TSToolsRenameFile<cr>", opts)
      keymap("n", "<leader>gR", "<cmd>TSToolsFileReferences<cr>", opts)
    end,

    settings = {
      separate_diagnostic_server = true,
      publish_diagnostic_on = "insert_leave",
      expose_as_code_action = "all",
      tsserver_path = nil,
      tsserver_plugins = {},
      tsserver_max_memory = "auto",

      tsserver_file_preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
        includeCompletionsForModuleExports = true,
        quotePreference = "auto",
      },
      tsserver_format_options = {
        allowIncompleteCompletions = false,
        allowRenameOfImportPath = false,
      },
    },
  }
end

return M
