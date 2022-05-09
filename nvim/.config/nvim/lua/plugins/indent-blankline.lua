-- Setup
require("indent_blankline").setup {
  show_current_context = true,
  buftype_exclude = {"terminal", "nofile"},
  filetype_exclude = {"help", "packer"},
  show_trailing_blankline_indent = false,
}
