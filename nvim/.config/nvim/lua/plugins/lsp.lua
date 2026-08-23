-- Server settings live in the native `lsp/<name>.lua` directory (Neovim 0.11+).
-- Those files are merged on top of nvim-lspconfig's defaults, and enabled by the
-- explicit vim.lsp.enable call below.
local servers = {
  'lua_ls',
  'vtsls',
  'eslint',
  'jsonls',
  'html',
  'cssls',
  'bashls',
  'taplo',
  'qmlls',
}

-- rust_analyzer is deliberately absent: rustaceanvim owns it (see plugins/rust.lua).
-- Enabling it here too would start two competing clients.
local mason_ensure = {
  'lua-language-server',
  'vtsls',
  'eslint-lsp',
  'json-lsp',
  'html-lsp',
  'css-lsp',
  'bash-language-server',
  'taplo',
  'shellcheck', -- consumed by bashls, not by a separate linter
  'prettierd',
  'stylua',
  'shfmt',
}

return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    { 'mason-org/mason.nvim', version = '^2', opts = {} },
    {
      'mason-org/mason-lspconfig.nvim',
      version = '^2',
      -- Servers are enabled explicitly below so that non-mason servers work too.
      opts = { ensure_installed = {}, automatic_enable = false },
    },
    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      opts = { ensure_installed = mason_ensure, run_on_start = true },
    },
    {
      'rachartier/tiny-code-action.nvim',
      dependencies = { 'folke/snacks.nvim' },
      event = 'LspAttach',
      opts = {
        backend = 'vim',
        picker = 'snacks',
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

        local picker = Snacks.picker
        local codeAction = require 'tiny-code-action'

        map('grd', picker.lsp_definitions, 'Goto Definition')
        map('grr', picker.lsp_references, 'Goto References')
        map('gri', picker.lsp_implementations, 'Goto Implementation')
        map('grt', picker.lsp_type_definitions, 'Goto Type Definition')
        map('gra', codeAction.code_action, 'Open Code Actions', { 'n', 'x' })
        map('grn', vim.lsp.buf.rename, 'Rename')
        map('grD', vim.lsp.buf.declaration, 'Goto Declaration')
        map('gO', picker.lsp_symbols, 'Open Document Symbols')
        map('gW', picker.lsp_workspace_symbols, 'Open Workspace Symbols')
        map('grx', vim.lsp.codelens.run, 'Run Codelens')
        map('<leader>cR', function()
          Snacks.rename.rename_file()
        end, 'Rename file (update imports)')

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
          return
        end

        local supports = function(method)
          return client:supports_method(method, ev.buf)
        end

        if supports(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = ev.buf }, { bufnr = ev.buf })
          end, 'Toggle Inlay Hints')
        end

        -- Inline colour swatches (0.12). Applies to cssls; vtsls reports
        -- colorProvider=false, so TSX/StyleSheet values are not covered.
        if supports(vim.lsp.protocol.Methods.textDocument_documentColor) then
          vim.lsp.document_color.enable(true, { bufnr = ev.buf })
        end

        -- 0.12's codelens capability refreshes itself on document changes
        if supports(vim.lsp.protocol.Methods.textDocument_codeLens) then
          vim.lsp.codelens.enable(true, { bufnr = ev.buf })
        end

        -- Fix-on-save for eslint. This lives here rather than in lsp/eslint.lua
        -- because nvim-lspconfig defines its own on_attach for this server and
        -- would override a user one (see the vim.lsp.config re-apply below).
        if client.name == 'eslint' then
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = vim.api.nvim_create_augroup('eslint-fix-all-' .. ev.buf, { clear = true }),
            buffer = ev.buf,
            command = 'LspEslintFixAll',
            desc = 'Apply eslint fixes on save',
          })
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      underline = { severity = vim.diagnostic.severity.ERROR },
      float = { source = true },
      jump = { float = true },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      },
      -- TypeScript errors are far too long for virtual text; virtual_lines on the
      -- current line only shows them in full without cluttering every other line.
      virtual_text = false,
      virtual_lines = { current_line = true },
    }

    vim.keymap.set('n', '<leader>td', function()
      local cfg = vim.diagnostic.config()
      if cfg.virtual_lines then
        vim.diagnostic.config { virtual_lines = false, virtual_text = { source = 'if_many', spacing = 4 } }
      else
        vim.diagnostic.config { virtual_lines = { current_line = true }, virtual_text = false }
      end
    end, { desc = 'Toggle diagnostic virtual lines' })

    -- nvim-lspconfig ships its own lsp/<name>.lua files. Neovim merges every
    -- copy found on the runtimepath, and the plugin sits *later* in that list,
    -- so for any key both define the plugin silently wins
    local config_dir = vim.fn.stdpath 'config' .. '/lsp/'
    for _, name in ipairs(servers) do
      local file = config_dir .. name .. '.lua'
      if vim.uv.fs_stat(file) then
        local ok, user_cfg = pcall(dofile, file)
        if ok and type(user_cfg) == 'table' then
          vim.lsp.config(name, user_cfg)
        elseif not ok then
          vim.notify(('lsp: failed to load %s.lua: %s'):format(name, user_cfg), vim.log.levels.WARN)
        end
      end
    end

    vim.lsp.enable(servers)
  end,
}
