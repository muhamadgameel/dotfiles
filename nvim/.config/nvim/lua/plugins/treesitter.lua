-- these are included with neovim:
-- (c, lua, vim, vimdoc, query, markdown, markdown_inline)
local languages = {
  'jsdoc',
  'json',
  'json5',
  'javascript',
  'typescript',
  'tsx',
  'html',
  'css',
  'bash',
  'python',
  'cpp',
  'rust',
  'zig',
  'go',
  'toml',
  'yaml',
  'git_config',
  'gitcommit',
  'gitignore',
  'ruby',
  'regex',
  'sql',
  'svelte',
  'xml',
  'graphql',
  'dockerfile',
  'qmldir',
  'qmljs',
  'zsh',
  'hyprlang',
  'diff',
  'git_rebase',
  'printf',
  'gomod',
  'gosum',
  'gowork',
  'kotlin',
  'groovy',
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').install(languages)

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter.setup', {}),
      callback = function(args)
        local buf = args.buf
        local filetype = args.match

        -- you need some mechanism to avoid running on buffers that do not
        -- correspond to a language (like oil.nvim buffers), this implementation
        -- checks if a parser exists for the current language
        local language = vim.treesitter.language.get_lang(filetype) or filetype
        if not vim.treesitter.language.add(language) then
          return
        end

        -- highlight
        vim.treesitter.start(buf, language)

        -- indentation, where the parser ships indent rules; the rest keep Vim's own
        if vim.treesitter.query.get(language, 'indents') then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
