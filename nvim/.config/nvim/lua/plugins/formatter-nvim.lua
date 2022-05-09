local addEventListener = utils.events.addEventListener

local prettier_cb = function()
  return {
    exe = "prettier",
    args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0))},
    stdin = true,
  }
end

-- TODO: Auto download formatters
require("formatter").setup(
  {
    filetype = {
      javascript = {prettier_cb},
      typescript = {prettier_cb},
      javascriptreact = {prettier_cb},
      typescriptreact = {prettier_cb},
      json = {prettier_cb},
      css = {prettier_cb},
      html = {prettier_cb},
      lua = {
        function()
          return {exe = "lua-format", args = {"-i"}, stdin = true}
        end,
      },
      rust = {
        function()
          return {exe = "rustfmt", args = {"--emit=stdout"}, stdin = true}
        end,
      },
    },
  }
)

-- format file on saving
addEventListener(
  "FormatBuffer", {"BufWritePost *.js,*.jsx,*.ts,*.tsx,*.json,*.css,*.html,*.lua,*.rs"},
  function()
    vim.cmd("FormatWrite")
  end
)
