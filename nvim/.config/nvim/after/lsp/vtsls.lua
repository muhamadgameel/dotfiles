-- vtsls wraps the official TypeScript language service and exposes commands that
-- plain ts_ls does not (source definitions, organize/add-missing imports, fix-all).
-- Docs: https://github.com/yioneko/vtsls
local inlay_hints = {
  enumMemberValues = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  parameterNames = { enabled = 'literals' },
  parameterTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  variableTypes = { enabled = false }, -- Noisy; the rest carry the value
}

return {
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true, -- Use the project's TS, not the bundled one
      experimental = {
        maxInlayHintLength = 30,
        completion = { enableServerSideFuzzyMatch = true },
      },
    },
    typescript = {
      -- React Native monorepos routinely exhaust the default tsserver heap
      tsserver = { maxTsServerMemory = 8192 },
      updateImportsOnFileMove = { enabled = 'always' },
      suggest = { completeFunctionCalls = true },
      preferences = {
        -- Respect tsconfig path aliases in auto-imports instead of ../../../
        importModuleSpecifier = 'non-relative',
        preferTypeOnlyAutoImports = true,
      },
      inlayHints = inlay_hints,
    },
    javascript = {
      updateImportsOnFileMove = { enabled = 'always' },
      suggest = { completeFunctionCalls = true },
      inlayHints = inlay_hints,
    },
  },
}
