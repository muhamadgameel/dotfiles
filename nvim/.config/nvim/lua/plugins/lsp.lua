-----------------------------------------------------------
-- LSP
-----------------------------------------------------------
local nnoremap_buf = utils.mappings.nnoremap_buf

-- custom borders shapes
local border = {
    {"🭽", "FloatBorder"}, {"▔", "FloatBorder"}, {"🭾", "FloatBorder"},
    {"▕", "FloatBorder"}, {"🭿", "FloatBorder"}, {"▁", "FloatBorder"},
    {"🭼", "FloatBorder"}, {"▏", "FloatBorder"}
}

local on_attach = function(_, bufnr)
    -- bind lsp with omni completion
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- set custom borders
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
                                                 vim.lsp.handlers.hover,
                                                 {border = border})
    vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, {border = border})

    -- set custom diagnostic
    vim.lsp.handlers["textDocument/publishDiagnostics"] =
        vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            virtual_text = {spacing = 40},
            signs = true,
            underline = true,
            update_in_insert = true
        })

    -- add signature autocompletion while typing
    require("lsp_signature").on_attach()

    -- keymaps
    nnoremap_buf(bufnr, "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", "LSP",
                 "lsp_find_declarations", "Find Declaration")
    nnoremap_buf(bufnr, "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", "LSP",
                 "lsp_find_definitions", "Find Definition")
    nnoremap_buf(bufnr, "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>",
                 "LSP", "lsp_find_implementation", "Find Implementation")
    nnoremap_buf(bufnr, "gr", "<cmd>lua vim.lsp.buf.references()<cr>", "LSP",
                 "lsp_find_references", "Find References")
    nnoremap_buf(bufnr, "gs", "<cmd>lua vim.lsp.buf.document_symbol()<cr>",
                 "LSP", "lsp_find_doc_symbols", "Find Document Symbols")
    nnoremap_buf(bufnr, "gt", "<cmd>lua vim.lsp.buf.type_definition()<cr>",
                 "LSP", "lsp_find_type_def", "Find Type Definition")
    nnoremap_buf(bufnr, "gS", "<cmd>lua vim.lsp.buf.workspace_symbol()<cr>",
                 "LSP", "lsp_find_workspace_synbols", "Find Workspace Symbols")
    nnoremap_buf(bufnr, "gI", "<cmd>lua vim.lsp.buf.incoming_calls()<cr>",
                 "LSP", "lsp_find_inc_calls", "Find Incoming Calls")
    nnoremap_buf(bufnr, "gO", "<cmd>lua vim.lsp.buf.outgoing_calls()<cr>",
                 "LSP", "lsp_find_out_calls", "Find Outgoing Calls")
    nnoremap_buf(bufnr, "gR", "<cmd>lua vim.lsp.buf.rename()<cr>", "LSP",
                 "lsp_rename", "LSP Rename")
    nnoremap_buf(bufnr, "K", "<cmd>lua vim.lsp.buf.hover()<cr>", "LSP",
                 "lsp_hover", "LSP Hover Signature")
    nnoremap_buf(bufnr, "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>",
                 "LSP", "lsp_diagnostic_go_prev", "GoTo Prev Diagnostic")
    nnoremap_buf(bufnr, "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>",
                 "LSP", "lsp_diagnostic_go_next", "GoTo Next Diagnostic")
    nnoremap_buf(bufnr, "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>",
                 "LSP", "lsp_signature_help", "Signature Help")
end

local servers = {
    "html", "cssls", "jsonls", "tsserver", "eslint", "sumneko_lua",
    "rust_analyzer"
}

local nvim_lsp = require('lspconfig')
for _, server in pairs(servers) do
    local opts = {
        on_attach = on_attach,
        init_options = {
            onlyAnalyzeProjectsWithOpenFiles = true,
            suggestFromUnimportedLibraries = false,
            closingLabels = true
        }
    }

    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- nvim-cmp supports additional completion capabilities
    capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)

    -- support snippets
    capabilities.textDocument.completion.completionItem.snippetSupport = true

    opts.capabilities = capabilities
    nvim_lsp[server].setup(opts)
    -- server:setup(opts)
end

-- set custom diagnostic icons
local signs = {
    Error = "✘ ",
    Warning = " ",
    Hint = " ",
    Information = " "
}
for type, icon in pairs(signs) do
    local hl = "LspDiagnosticsSign" .. type
    vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = ""})
end
