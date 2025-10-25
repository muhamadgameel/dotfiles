return {
  'saghen/blink.cmp',
  event = 'VimEnter',
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
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = 'make install_jsregexp',
      dependencies = {
        'rafamadriz/friendly-snippets',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
        end,
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
    appearance = { nerd_font_variant = 'mono' },
    completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
    signature = { enabled = true },
    sources = {
      default = { 'lsp', 'lazydev', 'path', 'snippets', 'buffer', 'emoji' },
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
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
  opts_extend = { 'sources.default' },
}
