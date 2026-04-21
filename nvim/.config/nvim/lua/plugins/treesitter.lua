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
  'graphql',
  'dockerfile',
  'qmldir',
  'qmljs',
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

        -- fold
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        -- highlight
        vim.treesitter.start(buf, language)

        -- indentation
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
