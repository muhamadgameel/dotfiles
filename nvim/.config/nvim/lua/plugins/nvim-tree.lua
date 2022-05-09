local tree_cb = require"nvim-tree.config".nvim_tree_callback
local nmap = utils.mappings.nmap

-- Mappings
nmap("-", "<cmd>NvimTreeToggle<cr>", "Project Tree", "tree_toggle", "Toggle Project Tree")
nmap(
  "+", "<cmd>NvimTreeFindFile<cr>", "Project Tree", "tree_find_file",
  "Find File in Project Tree"
)

-- Setup
require("nvim-tree").setup {
  view = {
    width = 40,
    mappings = {
      list = {
        {key = "-", cb = tree_cb("close")},
        {key = "?", cb = tree_cb("toggle_help")},
      },
    },
  },
}
