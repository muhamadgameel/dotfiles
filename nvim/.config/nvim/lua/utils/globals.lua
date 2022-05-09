local M = {}

-- Add a path to the run_time_path (rtp)
function M.add_rtp(path)
  local rtp = vim.o.rtp
  rtp = rtp .. "," .. path
end

_G.utils = _G.utils or {}
_G.utils.vim = M

return M
