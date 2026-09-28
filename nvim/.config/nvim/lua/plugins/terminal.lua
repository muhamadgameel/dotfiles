return {
  'akinsho/toggleterm.nvim',
  event = 'VeryLazy',
  keys = {
    { '<C-/>', '<Cmd>ToggleTerm<CR>', mode = 't', desc = 'Toggle terminal' },
    { '<C-_>', '<Cmd>ToggleTerm<CR>', mode = 't', desc = 'Toggle terminal' },
  },
  opts = {
    open_mapping = [[\]],
    direction = 'float',
    start_in_insert = true,
    insert_mappings = false,
    terminal_mappings = false,
    close_on_exit = true,
    float_opts = {
      highlights = {
        border = 'Normal',
        background = 'Normal',
      },
    },
  },
}
