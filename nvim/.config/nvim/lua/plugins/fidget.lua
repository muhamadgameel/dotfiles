local M = {
  "j-hui/fidget.nvim",
  event = "LspAttach",
}

function M.config()
  require("fidget").setup {}
end

return M
