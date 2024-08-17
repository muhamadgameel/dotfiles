-- https://luals.github.io/wiki/settings/
return {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        special = {
          spec = 'require',
        },
      },
      diagnostics = {
        globals = { 'vim', 'spec' },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          [vim.fn.expand '$VIMRUNTIME/lua'] = true,
          [vim.fn.stdpath 'config' .. '/lua'] = true,
        },
      },
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = 'Replace',
      },
      format = {
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
