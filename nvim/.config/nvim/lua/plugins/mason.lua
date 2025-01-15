return {
  'williamboman/mason.nvim',
  dependencies = {
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
  },
  config = function()
    require('mason').setup {
      ui = {
        border = 'rounded',
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    }

    require('mason-lspconfig').setup {}

    require('mason-tool-installer').setup {
      ensure_installed = {
        -- LSP
        'lua-language-server',
        'css-lsp',
        'html-lsp',
        'json-lsp',
        'eslint-lsp',
        'bash-language-server',

        -- Linters
        'shellcheck',
        'eslint_d',

        -- Formatters
        'prettierd',
        'stylua',
        'shfmt',
      },
    }
  end,
}
