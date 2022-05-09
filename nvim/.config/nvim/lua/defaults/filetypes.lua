local addEventListener = utils.events.addEventListener

-- ZSH
addEventListener(
  "ZSH Local Settings", {"Filetype zsh"}, function()
    vim.cmd [[setlocal tabstop=2 shiftwidth=2]]
  end
)
