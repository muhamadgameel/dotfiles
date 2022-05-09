local opt = {
  server = {settings = {["rust-analyzer"] = {checkOnSave = {command = "clippy"}}}},
}

require("rust-tools").setup(opt)
