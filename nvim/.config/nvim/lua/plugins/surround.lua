local M = {
  "kylechui/nvim-surround",
  event = "VeryLazy",
}

function M.config()
  ---@diagnostic disable-next-line: missing-fields
  require("nvim-surround").setup {}
end

return M
