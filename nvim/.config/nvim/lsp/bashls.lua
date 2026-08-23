-- bash-language-server runs shellcheck internally when the binary is on PATH
return {
  filetypes = { 'sh', 'bash', 'zsh' },
  settings = {
    bashIde = {
      shellcheckArguments = '--external-sources --enable=all',
    },
  },
}
