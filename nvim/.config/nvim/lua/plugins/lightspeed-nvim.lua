local nmap = utils.mappings.nmap
local vmap = utils.mappings.vmap
local xmap = utils.mappings.xmap
local omap = utils.mappings.omap

-- Setup
require"lightspeed".setup {}

-- remove default binding
vim.api.nvim_del_keymap("n", "s")
vim.api.nvim_del_keymap("n", "S")
vim.api.nvim_del_keymap("v", "s")
vim.api.nvim_del_keymap("v", "S")

-- Mappings
nmap("<leader><leader>", "<Plug>Lightspeed_s", "LightSpeed", "lightspeed_n_forward", "Search Forward")
nmap("<leader><bs>", "<Plug>Lightspeed_S", "LightSpeed", "lightspeed_n_backward", "Search Backward")
vmap("<leader><leader>", "<Plug>Lightspeed_s", "LightSpeed", "lightspeed_v_forward", "Search Forward")
vmap("<leader><bs>", "<Plug>Lightspeed_S", "LightSpeed", "lightspeed_v_backward", "Search Backward")
xmap("<leader><leader>", "<Plug>Lightspeed_s", "LightSpeed", "lightspeed_x_forward", "Search Forward")
xmap("<leader><bs>", "<Plug>Lightspeed_S", "LightSpeed", "lightspeed_x_backward", "Search Backward")
omap("<leader><leader>", "<Plug>Lightspeed_s", "LightSpeed", "lightspeed_o_forward", "Search Forward")
omap("<leader><bs>", "<Plug>Lightspeed_S", "LightSpeed", "lightspeed_o_backward", "Search Backward")
