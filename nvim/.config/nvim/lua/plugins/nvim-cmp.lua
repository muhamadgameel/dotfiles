-----------------------------------------------------------
-- Autocompletion
-----------------------------------------------------------
local cmp = require("cmp")
local luasnip = require "luasnip"
local t = utils.mappings.t

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and
           vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") ==
           nil
end

-- completion symbols
local completion_symbols_map = {
  Class = " Class",
  Color = " Color",
  Constant = " Constant",
  Constructor = " Constructor",
  Enum = " Enum",
  EnumMember = " EnumMember",
  Event = " Event",
  Field = " Field",
  File = " File",
  Folder = " Folder",
  Function = " Function",
  Interface = "ﰮ Interface",
  Keyword = " Keyword",
  Method = " Method",
  Module = " Module",
  Operator = "",
  Property = "ﰠ Property",
  Reference = "",
  Snippet = " Snippet",
  Struct = "פּ Struct",
  Text = " Text",
  TypeParameter = "",
  Unit = " Unit",
  Value = " Value",
  Variable = " Variable",
}

-- setup
cmp.setup(
  {
    completion = {completeopt = "menu,menuone,noselect"},

    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },

    mapping = {
      ["<C-k>"] = cmp.mapping.select_prev_item(),
      ["<C-j>"] = cmp.mapping.select_next_item(),
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.close(),
      ["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      }),
      ["<Tab>"] = cmp.mapping(
        function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, {"i"}
      ),
      ["<S-Tab>"] = cmp.mapping(
        function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, {"i"}
      ),
    },

    sources = {
      {name = "nvim_lsp"},
      {name = "luasnip"},
      {name = "nvim_lua"},
      {name = "path"},
      {name = "calc"},
      {name = "latex_symbols"},
      {name = "emoji"},
      {name = "buffer"},
    },

    formatting = {
      -- add formattings (icons) to completion items
      format = function(_, vim_item)
        vim_item.kind = completion_symbols_map[vim_item.kind] or vim_item.kind
        return vim_item
      end,
    },
  }
)
