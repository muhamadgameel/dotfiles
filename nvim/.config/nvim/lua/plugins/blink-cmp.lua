return {
  'saghen/blink.cmp',
  -- CmdlineEnter is needed alongside InsertEnter so ':' completion still
  event = { 'InsertEnter', 'CmdlineEnter' },
  version = '1.*',
  dependencies = {
    { 'moyiz/blink-emoji.nvim' },
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      },
    },
  },
  opts = {
    keymap = {
      preset = 'super-tab',
      ['<Enter>'] = { 'accept', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
    },
    signature = { enabled = true },
    sources = {
      default = { 'lsp', 'lazydev', 'path', 'buffer', 'emoji' },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
        emoji = {
          module = 'blink-emoji',
          name = 'Emoji',
          score_offset = 15,
          opts = { insert = true },
          should_show_items = function()
            return vim.tbl_contains({ 'gitcommit', 'markdown' }, vim.o.filetype)
          end,
        },
      },
    },
  },
}
