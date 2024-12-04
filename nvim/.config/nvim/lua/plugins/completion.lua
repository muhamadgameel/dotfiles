local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
end

return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    { 'hrsh7th/cmp-nvim-lsp', event = 'InsertEnter' },
    { 'hrsh7th/cmp-emoji', event = 'InsertEnter' },
    { 'hrsh7th/cmp-buffer', event = 'InsertEnter' },
    { 'hrsh7th/cmp-path', event = 'InsertEnter' },
    { 'hrsh7th/cmp-calc', event = 'InsertEnter' },
    { 'hrsh7th/cmp-nvim-lua', event = 'InsertEnter' },
    { 'saadparwaiz1/cmp_luasnip', event = 'InsertEnter' },
    {
      'L3MON4D3/LuaSnip',
      event = 'InsertEnter',
      dependencies = { 'rafamadriz/friendly-snippets' },
    },
    { 'windwp/nvim-autopairs', event = 'InsertEnter' },
    { 'folke/lazydev.nvim', ft = 'lua' },
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    local icons = require 'core.icons'

    -- load some predefined snippets
    require('luasnip/loaders/from_vscode').lazy_load()

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      enabled = function()
        local context = require 'cmp.config.context'

        -- disable inside of prompts
        if vim.bo.buftype == 'prompt' then
          return false
        end

        -- disable completion in comments
        if context.in_treesitter_capture 'comment' or context.in_syntax_group 'Comment' then
          return false
        end

        return true
      end,
      mapping = cmp.mapping.preset.insert {
        ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
        ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
        ['<Up>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
        ['<Down>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
        ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
        ['<C-e>'] = cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close() },
        ['<CR>'] = cmp.mapping.confirm { select = true },
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      },
      sources = cmp.config.sources {
        { name = 'lazydev', group_index = 0 },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'nvim_lua' },
        { name = 'path' },
        { name = 'calc' },
        { name = 'emoji' },
        { name = 'buffer' },
      },
      view = {
        entries = { name = 'custom', selection_order = 'near_cursor' }, -- custom or native
      },
      window = {
        completion = {
          border = 'rounded',
          scrollbar = false,
        },
        documentation = {
          border = 'rounded',
        },
      },
      formatting = {
        fields = { 'abbr', 'kind', 'menu' },
        format = function(entry, vim_item)
          vim_item.kind = string.format('%s %s', icons.kind[vim_item.kind], vim_item.kind)
          vim_item.menu = ({
            lazydev = '',
            buffer = '',
            nvim_lsp = '',
            luasnip = '',
            nvim_lua = '',
            path = '',
            latex_symbols = '',
            emoji = '',
          })[entry.source.name]

          if entry.source.name == 'calc' then
            vim_item.kind = icons.ui.Calc
          end

          if entry.source.name == 'emoji' then
            vim_item.kind = icons.misc.Smiley
          end

          return vim_item
        end,
      },
      confirm_opts = {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
      experimental = {
        ghost_text = false,
      },
    }

    -- Support auto pairs
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
  end,
}
