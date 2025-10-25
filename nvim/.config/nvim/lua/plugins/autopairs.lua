return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  opts = {
    -- TODO: test these strings after adding treesitter
    check_ts = true,
    ts_config = {
      lua = { 'string' },
      javascript = { 'template_string' },
      typescript = { 'template_string' },
      typescriptreact = { 'template_string' },
    },
  },
  config = true,
}
