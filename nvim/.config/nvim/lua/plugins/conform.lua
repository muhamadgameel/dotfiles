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
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    }

    -- /usr/bin/qmlformat is Qt 5: it ignores .qmlformat.ini and can't parse `?.`
    conform.formatters.qmlformat = {
      command = '/usr/lib/qt6/bin/qmlformat',
    }
  end,
}
