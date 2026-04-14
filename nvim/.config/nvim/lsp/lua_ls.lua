-- Docs: https://luals.github.io/wiki/settings/
return {
  settings = {
    Lua = {
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
        arrayIndex = 'Auto',
        await = true,
        paramName = 'All',
        paramType = true,
        semicolon = 'SameLine',
        setType = true,
      },
    },
  },
}
