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
      mode = { 'n', 'v' },
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
        qml = { '/usr/lib/qt6/bin/qmlformat' }, -- Externally downloaded
        ['_'] = { 'trim_whitespace', 'trim_newlines' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    }

    conform.formatters.shfmt = {
      append_args = { '-i', '2' },
    }
  end,
}
