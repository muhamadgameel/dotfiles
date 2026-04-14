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
        ensure_installed = { 'lua_ls', 'jsonls', 'ts_ls', 'html', 'cssls', 'bashls', 'taplo', 'vale_ls', 'qmlls' },
      },
    },
    {
      'rachartier/tiny-code-action.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
      event = 'LspAttach',
      opts = {
        backend = 'vim',
        picker = 'telescope',
      },
    },
    { 'j-hui/fidget.nvim', opts = {} },
    { 'b0o/schemastore.nvim' },
  },
  config = function()
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
        map('grx', vim.lsp.codelens.run, 'Run Codelens')

        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, ev.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = ev.buf })
          end, 'Toggle Inlay Hints')
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, ev.buf) then
          vim.lsp.codelens.refresh { bufnr = ev.buf }
          vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
            buffer = ev.buf,
            callback = function()
              vim.lsp.codelens.refresh { bufnr = ev.buf }
            end,
          })
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      underline = { severity = vim.diagnostic.severity.ERROR },
      float = {
        border = 'rounded',
        source = true,
      },
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
      },
    }
  end,
}
