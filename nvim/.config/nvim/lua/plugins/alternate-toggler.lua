local M = {
  "rmagatti/alternate-toggler",
  lazy = true,
  event = { "BufReadPost" },
}

function M.config()
  require("alternate-toggler").setup {
    alternates = {
      ["==="] = "!==",
      ["=="] = "!=",
      ["error"] = "warn",
    },
  }

  vim.keymap.set("n", "<leader>i", "<cmd>lua require('alternate-toggler').toggleAlternate()<CR>")
end

return M
