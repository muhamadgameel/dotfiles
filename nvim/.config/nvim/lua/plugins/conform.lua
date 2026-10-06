-- The eslint fix-on-save in plugins/lsp.lua reads the same two flags.
local function toggle(scope, where)
  scope.disable_autoformat = not scope.disable_autoformat
  vim.notify(('Format on save%s: %s'):format(where, scope.disable_autoformat and 'off' or 'on'))
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>F',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = { 'n', 'x' },
      desc = 'Format buffer',
    },
    {
      '<leader>tf',
      function()
        toggle(vim.g, '')
      end,
      desc = 'Toggle format on save',
    },
    {
      '<leader>tF',
      function()
        toggle(vim.b, ' in this buffer')
      end,
      desc = 'Toggle format on save (buffer)',
    },
  },
  config = function()
    local conform = require 'conform'

    conform.setup {
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        html = { 'prettierd' },
        css = { 'prettierd' },
        markdown = { 'prettierd' },
        yaml = { 'prettierd' },
        graphql = { 'prettierd' },
        toml = { 'taplo' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        rust = { 'rustfmt' },
        go = { lsp_format = 'prefer' }, -- gopls, which applies gofumpt
        python = { 'ruff_organize_imports', 'ruff_format' },
        qml = { 'qmlformat' },
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
    }

    -- /usr/bin/qmlformat is Qt 5: it ignores .qmlformat.ini and can't parse `?.`
    conform.formatters.qmlformat = {
      command = '/usr/lib/qt6/bin/qmlformat',
    }
  end,
}
