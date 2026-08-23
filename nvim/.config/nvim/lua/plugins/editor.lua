return {
  {
    -- Native `gc` uses a single 'commentstring' per buffer, which is wrong inside
    -- JSX: it emits `// ` where `{/* */}` is required. This picks the comment
    -- style per treesitter node instead.
    'folke/ts-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    -- s/S to jump anywhere on screen; S selects treesitter nodes, which makes
    -- grabbing a whole JSX element a two-keystroke operation.
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        -- Leave `/` and `f`/`t` alone; only the explicit s/S motions are new.
        search = { enabled = false },
        char = { enabled = false },
      },
    },
    keys = {
      {
        's',
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
        mode = { 'n', 'x', 'o' },
      },
      {
        'S',
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
        mode = { 'n', 'x', 'o' },
      },
      {
        'r',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
        mode = 'o',
      },
      {
        '<C-s>',
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
        mode = 'c',
      },
    },
  },
  {
    -- Project-wide find & replace with live preview. <leader>rw is buffer-only.
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        '<leader>rW',
        function()
          require('grug-far').open { transient = true }
        end,
        desc = 'Search/Replace in project',
      },
      {
        '<leader>rf',
        function()
          require('grug-far').open { transient = true, prefills = { paths = vim.fn.expand '%' } }
        end,
        desc = 'Search/Replace in current file',
      },
    },
  },
  {
    -- Outdated dependency versions inline in package.json
    'vuki656/package-info.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    event = { 'BufRead package.json' },
    opts = { package_manager = 'npm', hide_up_to_date = true },
    keys = {
      {
        '<leader>ns',
        function()
          require('package-info').show()
        end,
        desc = 'Show package versions',
      },
      {
        '<leader>nu',
        function()
          require('package-info').update()
        end,
        desc = 'Update package',
      },
      {
        '<leader>nc',
        function()
          require('package-info').change_version()
        end,
        desc = 'Change package version',
      },
    },
  },
}
