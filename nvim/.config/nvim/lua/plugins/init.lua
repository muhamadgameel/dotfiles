-- Install Packer if not installed
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  local input = vim.fn.input("Download Packer? (y for yes): ")
  if input ~= "y" then
    return
  end

  print("Downloading packer.nvim...")
  vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)

  print("Cloning into '" .. install_path .. "'")
  print("Downloaded packer.nvim")
  print("Reopen Nvim and run :PackerSync twice")
  print("\n")
  return
end

-- Initialize Plugins
return require("packer").startup(
  {
    function(use)
      -- Packer can manage itself as an optional plugin
      use "wbthomason/packer.nvim"

      -- Dependencies
      use "kyazdani42/nvim-web-devicons"
      use "nvim-lua/plenary.nvim"

      -- Fix CursorHold Performance
      use {
        "antoinemadec/FixCursorHold.nvim",
        config = function()
          require "plugins.fix-cursorhold"
        end,
      }

      -- Keys Mapper
      use {
        "lazytanuki/nvim-mapper",
        config = function()
          require "plugins.nvim-mapper"
        end,
      }

      -- Color Schemes
      use {"tomasr/molokai", "morhetz/gruvbox", {"dracula/vim", as = "dracula"}}

      -- Telescope (Fizzy Finder)
      use {
        {
          "nvim-telescope/telescope.nvim",
          config = function()
            require "plugins.telescope"
          end,
        },
        {"nvim-telescope/telescope-fzf-native.nvim", run = "make"},
        {"gbrlsnchs/telescope-lsp-handlers.nvim"},
      }

      -- Treesitter (Syntax Parser)
      use {
        {
          "nvim-treesitter/nvim-treesitter",
          run = ":TSUpdate",
          config = function()
            require "plugins.treesitter"
          end,
        },
        {"nvim-treesitter/nvim-treesitter-textobjects"},
        {"RRethy/nvim-treesitter-textsubjects"},
        {"JoosepAlviste/nvim-ts-context-commentstring"},
        {"tpope/vim-commentary"},
        {"p00f/nvim-ts-rainbow"},
        {"windwp/nvim-ts-autotag"},
      }

      -- LSP (Language Server)
      use {
        {"williamboman/nvim-lsp-installer"},
        {
          "neovim/nvim-lspconfig",
          config = function()
            require "plugins.lsp"
          end,
        },
        {"ray-x/lsp_signature.nvim"},
      }

      -- Rust Tools
      use {
        "simrat39/rust-tools.nvim",
        config = function()
          require("plugins.rust-tools")
        end,
      }

      -- CMP (Auto Completion)
      use {
        {
          "hrsh7th/nvim-cmp",
          config = function()
            require "plugins.nvim-cmp"
          end,
        },
        {"hrsh7th/cmp-nvim-lsp"},
        {"hrsh7th/cmp-nvim-lua"},
        {"hrsh7th/cmp-path"},
        {"hrsh7th/cmp-calc"},
        {"hrsh7th/cmp-emoji"},
        {"hrsh7th/cmp-buffer"},
        {"saadparwaiz1/cmp_luasnip"},
        {"kdheepak/cmp-latex-symbols"},
      }

      -- Snippets
      use {
        "L3MON4D3/LuaSnip",
        config = function()
          require "plugins.snippets"
        end,
      }

      -- Inserts AutoPairs
      use {
        "windwp/nvim-autopairs",
        config = function()
          require "plugins.autopairs"
        end,
        after = "nvim-cmp",
      }

      -- Project Tree
      use {
        "kyazdani42/nvim-tree.lua",
        config = function()
          require "plugins.nvim-tree"
        end,
      }

      -- Statusline
      use {
        {
          "famiu/feline.nvim",
          config = function()
            require "plugins.feline-nvim"
          end,
        },
        {
          "SmiteshP/nvim-gps",
          requires = "nvim-treesitter/nvim-treesitter",
          config = function()
            require "plugins.nvim-gps"
          end,
        },
      }

      -- BufferLine & Better Buffers delete
      use {
        {
          "akinsho/bufferline.nvim",
          config = function()
            require "plugins.bufferline-nvim"
          end,
        },
        {"famiu/bufdelete.nvim"},
      }

      -- Pretty loc/quickfix Lists
      use {
        "folke/trouble.nvim",
        config = function()
          require "plugins.trouble"
        end,
      }

      -- List all comments with todo,fixme, bug ...
      use {
        "folke/todo-comments.nvim",
        config = function()
          require "plugins.todo-comments"
        end,
      }

      -- Indent Guides
      use {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
          require "plugins.indent-blankline"
        end,
      }

      -- Fast Colorizer
      use {
        "norcalli/nvim-colorizer.lua",
        config = function()
          require "plugins.nvim-colorizer"
        end,
      }

      -- Highlight word Under Cursor
      use {
        "xiyaowong/nvim-cursorword",
        config = function()
          require "plugins.nvim-cursorword"
        end,
      }

      -- Dims Inactive Windows
      use {
        "sunjon/Shade.nvim",
        config = function()
          require "plugins.shade"
        end,
      }

      -- Highlights line ranges entered in commandline
      use {
        "winston0410/range-highlight.nvim",
        requires = "winston0410/cmd-parser.nvim",
        config = function()
          require "plugins.range-highlight"
        end,
      }

      -- Git Signs & Hunks Management
      use {
        "lewis6991/gitsigns.nvim",
        config = function()
          require "plugins.gitsigns"
        end,
      }

      -- Formatter
      use {
        "mhartington/formatter.nvim",
        config = function()
          require "plugins.formatter-nvim"
        end,
      }

      -- Multi Cursors
      use {"mg979/vim-visual-multi"}

      -- Tpope plugins
      use "tpope/vim-obsession" -- Session Management
      use "tpope/vim-surround" -- Surround text object (quoting/parenthesizing)
      use "tpope/vim-repeat" -- support repeat to tpope plugins

      -- Regex syntax not supported by treesitter
      use {"mboughaba/i3config.vim"}

    end,
    config = {
      -- show floating window instead of vsplit
      display = {
        open_fn = function()
          return require("packer.util").float({border = "single"})
        end,
      },
    },
  }
)
