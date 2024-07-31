local M = {
  "rmagatti/auto-session",
  event = "VimEnter",
}

function M.config()
  vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

  require("auto-session").setup {
    log_level = "error",
    auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    auto_session_enable_last_session = false,
    auto_session_root_dir = vim.fn.stdpath "data" .. "/sessions/",
    auto_session_enabled = true,
    auto_save_enabled = nil,
    auto_restore_enabled = nil,
    auto_session_use_git_branch = nil,
    bypass_session_save_file_types = nil,
  }

  local telescope_ok, telescope = pcall(require, "telescope")
  if telescope_ok then
    telescope.load_extension "session-lens"
    vim.keymap.set(
      "n",
      "<leader>os",
      "<cmd>Telescope session-lens search_session<CR>",
      { noremap = true, silent = true }
    )
  end
end

return M
