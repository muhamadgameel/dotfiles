-- Docs: https://luals.github.io/wiki/settings/
return {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
      },
      completion = {
        callSnippet = 'Replace',
      },
      format = {
        enable = false,
      },
      telemetry = {
        enable = false,
      },
      hint = {
        enable = true,
        arrayIndex = 'Auto', -- "Enable" | "Auto" | "Disable"
        await = true,
        paramName = 'All', -- "All" | "Literal" | "Disable"
        paramType = true,
        semicolon = 'SameLine', -- "All" | "SameLine" | "Disable"
        setType = true,
      },
    },
  },
}
