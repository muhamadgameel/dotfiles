return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'

    lint.linters_by_ft = {
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      json = { 'jsonlint' },
      bash = { 'shellcheck' },
      sh = { 'shellcheck' },
      zsh = { 'shellcheck' },
    }

    -- Configure shellcheck
    lint.linters.shellcheck.args = {
      '--shell=zsh', -- Use zsh as the default shell
      '--format=gcc', -- Use gcc format for output
      '--external-sources', -- Allow 'source' outside of FILES
      '--enable=all', -- Enable all checks
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        if vim.bo.modifiable then
          lint.try_lint()
        end
      end,
    })
  end,
}
