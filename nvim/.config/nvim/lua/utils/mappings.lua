local M = {}

Mapper = require("nvim-mapper")

local function map(mode, keys, action, category, unique_identifier, description)
  if category == nil then
    vim.api.nvim_set_keymap(mode, keys, action, {})
  else
    Mapper.map(mode, keys, action, {}, category, unique_identifier, description)
  end
end

local function noremap(mode, keys, action, category, unique_identifier, description)
  if category == nil then
    vim.api.nvim_set_keymap(mode, keys, action, {noremap = true})
  else
    Mapper.map(mode, keys, action, {noremap = true}, category, unique_identifier, description)
  end
end

local function noremap_buf(bufnr, mode, keys, action, category, unique_identifier, description)
  if category == nil then
    vim.api.nvim_buf_set_keymap(bufnr, mode, keys, action, {noremap = true, silent = true})
  else
    Mapper.map_buf(
      bufnr, mode, keys, action, {noremap = true, silent = true}, category, unique_identifier,
      description
    )
  end
end

local modes = {"n", "i", "v", "x", "o", "t"}

-- noremap
for _, mode in pairs(modes) do
  M[mode .. "noremap"] = function(keys, action, category, unique_identifier, description)
    noremap(mode, keys, action, category, unique_identifier, description)
  end
end

-- noremap buffer
for _, mode in pairs(modes) do
  M[mode .. "noremap_buf"] = function(
    bufnr, keys, action, category, unique_identifier, description
  )
    noremap_buf(bufnr, mode, keys, action, category, unique_identifier, description)
  end
end

-- map
for _, mode in pairs(modes) do
  M[mode .. "map"] = function(keys, action, category, unique_identifier, description)
    map(mode, keys, action, category, unique_identifier, description)
  end
end

-- Escape term codes
function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

_G.utils = _G.utils or {}
_G.utils.mappings = M

return M
