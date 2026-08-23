return {
  {
    -- Fixes the biggest gap in the old config: rust-analyzer was never enabled,
    -- so Rust files had no LSP at all. rustaceanvim starts and owns the server
    -- itself, which is why rust_analyzer is absent from plugins/lsp.lua.
    'mrcjkb/rustaceanvim',
    version = '^6',
    lazy = false, -- Plugin sets up its own ft handling; do not call setup()
    init = function()
      vim.g.rustaceanvim = {
        server = {
          on_attach = function(_, bufnr)
            local map = function(keys, cmd, desc)
              vim.keymap.set('n', keys, cmd, { buffer = bufnr, desc = 'Rust: ' .. desc })
            end
            map('<leader>rr', '<cmd>RustLsp runnables<cr>', 'Runnables')
            map('<leader>rt', '<cmd>RustLsp testables<cr>', 'Testables')
            map('<leader>rm', '<cmd>RustLsp expandMacro<cr>', 'Expand macro')
            map('<leader>rc', '<cmd>RustLsp openCargo<cr>', 'Open Cargo.toml')
            map('<leader>rp', '<cmd>RustLsp parentModule<cr>', 'Parent module')
            map('<leader>rD', '<cmd>RustLsp externalDocs<cr>', 'Open external docs')
            map('<leader>ra', '<cmd>RustLsp codeAction<cr>', 'Code action (grouped)')
            -- Replaces the default K with rust-analyzer's richer hover
            map('K', '<cmd>RustLsp hover actions<cr>', 'Hover actions')
          end,
          default_settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = true,
              check = { command = 'clippy', extraArgs = { '--no-deps' } },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                },
              },
              inlayHints = {
                bindingModeHints = { enable = false },
                closureReturnTypeHints = { enable = 'with_block' },
                lifetimeElisionHints = { enable = 'skip_trivial', useParameterNames = true },
                parameterHints = { enable = true },
                typeHints = { enable = true },
              },
              files = {
                excludeDirs = { '.direnv', '.git', 'node_modules', 'target' },
              },
            },
          },
        },
        tools = {
          float_win_config = { border = 'rounded' },
        },
      }
    end,
  },
  {
    -- Inline crate versions / features in Cargo.toml
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    opts = {
      completion = { crates = { enabled = true } },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
