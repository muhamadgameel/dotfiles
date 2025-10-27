return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    {
      'williamboman/mason.nvim',
      opts = {
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      },
    },
    {
      'williamboman/mason-lspconfig.nvim',
      opts = {
        automatic_enable = true,
        ensure_installed = { 'lua_ls', 'jsonls', 'ts_ls', 'html', 'cssls', 'bashls', 'taplo', 'vale_ls' },
      },
    },
    {
      'rachartier/tiny-code-action.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      event = 'LspAttach',
      opts = {
        --- The backend to use, currently only "vim", "delta", "difftastic", "diffsofancy" are supported
        backend = 'vim',
        picker = 'telescope',
      },
    },
    { 'j-hui/fidget.nvim', opts = {} },
    { 'b0o/schemastore.nvim' },
  },
  config = function()
    -- LSP
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('LspAttachGroup', {}),
      callback = function(ev)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = ev.buf, desc = 'LSP: ' .. desc, noremap = true, silent = true })
        end

        local telescope = require 'telescope.builtin'
        local codeAction = require 'tiny-code-action'
        map('grd', telescope.lsp_definitions, 'Goto Definition')
        map('grr', telescope.lsp_references, 'Goto References')
        map('gri', telescope.lsp_implementations, 'Goto Implementation')
        map('grt', telescope.lsp_type_definitions, 'Goto Type Definition')
        map('gra', codeAction.code_action, 'Open Code Actions', { 'n', 'x' })
        map('grn', vim.lsp.buf.rename, 'Rename')
        map('grD', vim.lsp.buf.declaration, 'Goto Declaration')
        map('gO', telescope.lsp_document_symbols, 'Open Document Symbols')
        map('gW', telescope.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- Support Inlay Hints
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, ev.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = ev.buf })
          end, 'Toggle Inlay Hints')
        end
      end,
    })

    -- Diagnostic
    vim.diagnostic.config {
      severity_sort = true,
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      },
      virtual_text = {
        source = 'if_many',
        spacing = 4,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    }
  end,
}
