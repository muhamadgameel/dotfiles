local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, silent = true }
  local keymap = vim.keymap.set
  local telescope_builtin = require 'telescope.builtin'

  opts.desc = 'Go to declaration'
  keymap('n', 'gD', vim.lsp.buf.declaration, opts)

  opts.desc = 'Show LSP definitions'
  keymap('n', 'gd', vim.lsp.buf.definition, opts)

  opts.desc = 'Show LSP implementations'
  keymap('n', 'gi', vim.lsp.buf.implementation, opts)

  opts.desc = 'Show LSP type definitions'
  keymap('n', 'gt', telescope_builtin.lsp_type_definitions, opts)

  opts.desc = 'Smart code rename'
  keymap('n', 'gr', vim.lsp.buf.rename, opts)

  opts.desc = 'Show line diagnostics'
  keymap('n', 'gl', vim.diagnostic.open_float, opts)

  opts.desc = 'Show signature'
  keymap('n', 'gs', vim.lsp.buf.signature_help, opts)

  opts.desc = 'Go to next diagnostic'
  keymap('n', ']d', vim.diagnostic.goto_next, opts)

  opts.desc = 'Go to previous diagnostic'
  keymap('n', '[d', vim.diagnostic.goto_prev, opts)

  opts.desc = 'Show documentation for what is under cursor'
  keymap('n', 'K', vim.lsp.buf.hover, opts)

  opts.desc = 'Show workspace diagnostics'
  keymap('n', 'ge', telescope_builtin.diagnostics, opts)

  opts.desc = 'Show LSP references'
  keymap('n', 'gR', telescope_builtin.lsp_references, opts)

  opts.desc = 'Toggle inlay hints'
  keymap('n', 'gh', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr }, { bufnr })
  end, opts)
end

local common_capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  return capabilities
end

return {
  -------
  -- LSP
  -------
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'b0o/schemastore.nvim' },
      {
        --------------------------
        -- Lsp (Typescript tools)
        --------------------------
        'pmizio/typescript-tools.nvim',
        config = function()
          require('typescript-tools').setup {
            on_attach = function(_, bufnr)
              local opts = { buffer = bufnr, silent = true }
              local keymap = vim.keymap.set

              keymap('n', 'go', '<cmd>TSToolsOrganizeImports<cr>', opts)
              keymap('n', 'gI', '<cmd>TSToolsAddMissingImports<cr>', opts)
              keymap('n', 'gf', '<cmd>TSToolsFixAll<cr>', opts)
              keymap('n', '<leader>gd', '<cmd>TSToolsGoToSourceDefinition<cr>', opts)
              keymap('n', '<leader>gr', '<cmd>TSToolsRenameFile<cr>', opts)
              keymap('n', '<leader>gR', '<cmd>TSToolsFileReferences<cr>', opts)
            end,

            settings = {
              separate_diagnostic_server = true,
              publish_diagnostic_on = 'insert_leave',
              expose_as_code_action = 'all',
              tsserver_path = nil,
              tsserver_plugins = {},
              tsserver_max_memory = 'auto',

              tsserver_file_preferences = {
                includeInlayParameterNameHints = 'all',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
                includeCompletionsForModuleExports = true,
                quotePreference = 'auto',
              },
              tsserver_format_options = {
                allowIncompleteCompletions = false,
                allowRenameOfImportPath = false,
              },
            },
          }
        end,
      },
    },
    -------
    -- Lsp
    -------
    config = function()
      local lspconfig = require 'lspconfig'
      local icons = require 'core.icons'

      -- Set rounded border for floating info windows
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
      vim.lsp.handlers['textDocument/signatureHelp'] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })
      require('lspconfig.ui.windows').default_options.border = 'rounded'

      -- Diagnostic ui
      local default_diagnostic_config = {
        signs = {
          active = true,
          values = {
            { name = 'DiagnosticSignError', text = icons.diagnostics.Error },
            { name = 'DiagnosticSignWarn', text = icons.diagnostics.Warning },
            { name = 'DiagnosticSignHint', text = icons.diagnostics.Hint },
            { name = 'DiagnosticSignInfo', text = icons.diagnostics.Information },
          },
        },
        virtual_text = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          focusable = true,
          style = 'minimal',
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        },
      }
      vim.diagnostic.config(default_diagnostic_config)

      for _, sign in ipairs(vim.tbl_get(vim.diagnostic.config(), 'signs', 'values') or {}) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = sign.name })
      end

      -- Setup servers
      local servers = {
        'lua_ls',
        'cssls',
        'html',
        'jsonls',
        'eslint',
        'bashls',
      }

      for _, server in pairs(servers) do
        local opts = {
          on_attach = on_attach,
          capabilities = common_capabilities(),
        }

        -- Load custom server settings if found
        local require_ok, settings = pcall(require, 'lsp.' .. server)
        if require_ok then
          opts = vim.tbl_deep_extend('force', settings, opts)
        end

        lspconfig[server].setup(opts)
      end
    end,
  },

  ------------------------
  -- Code Actions Preview
  ------------------------
  {
    'aznhe21/actions-preview.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      vim.keymap.set(
        { 'v', 'n' },
        'ga',
        require('actions-preview').code_actions,
        { silent = true, desc = 'Show code actions' }
      )
    end,
  },
}
