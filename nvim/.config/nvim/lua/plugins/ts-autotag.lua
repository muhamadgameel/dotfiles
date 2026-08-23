return {
  'windwp/nvim-ts-autotag',
  ft = {
    'html',
    'xml',
    'markdown',
    'svelte',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  -- NOTE: the options must stay nested under `opts`. A flat table either lands at
  -- the wrong level (and is silently ignored) or trips the plugin's legacy-config
  -- warning on every startup.
  opts = {
    opts = {
      enable_rename = true,
      enable_close = true,
      enable_close_on_slash = false,
    },
  },
}
