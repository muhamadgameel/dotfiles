local M = {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "BufRead",
}

function M.config()
  require("ibl").setup {}
end

return M
