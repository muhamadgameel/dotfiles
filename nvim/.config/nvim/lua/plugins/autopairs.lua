local M = {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
}

function M.config()
  require("nvim-autopairs").setup {
    check_ts = true,
    disable_filetype = { "TelescopePrompt", "spectre_panel", "vim" },
  }

  local require_ok, cmp = pcall(require, "cmp")
  if require_ok then
    local cmp_autopairs = require "nvim-autopairs.completion.cmp"
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
end

return M
