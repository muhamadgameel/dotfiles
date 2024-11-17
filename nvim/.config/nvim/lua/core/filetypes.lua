vim.filetype.add {
  extension = {
    zsh = 'zsh',
  },
  filename = {
    ['.zshrc'] = 'zsh',
    ['.zshenv'] = 'zsh',
    ['.zprofile'] = 'zsh',
    ['.zlogin'] = 'zsh',
    ['.zlogout'] = 'zsh',
  },
  pattern = {
    ['.*/.zsh/.*'] = 'zsh',
    ['.*zsh.*'] = 'zsh',
  },
}
