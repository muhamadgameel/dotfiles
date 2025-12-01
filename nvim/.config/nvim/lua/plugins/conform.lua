return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
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
        html = { 'prettierd' },
        css = { 'prettierd' },
        markdown = { 'prettierd' },
        yaml = { 'prettierd' },
        graphql = { 'prettierd' },
        toml = { 'taplo' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        zsh = { 'shfmt' },
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

    vim.keymap.set({ 'n', 'v' }, '<leader>F', function()
      conform.format {
        async = true,
        lsp_format = 'fallback',
      }
    end, { desc = 'Format buffer' })
  end,
}
