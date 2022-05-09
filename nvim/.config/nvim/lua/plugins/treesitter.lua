require"nvim-treesitter.configs".setup({
    ensure_installed = "all",
    ignore_install = {},

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- syntax coloring
    highlight = {
        enable = true,
        disable = {},
        additional_vim_regex_highlighting = false,
    },

    -- disable this builtin infavor of text subjects
    incremental_selection = { enable = false },

    -- indentation based on treesitter for the = operator
    indent = { enable = true },

    --  html tags auto closing
    autotag = { enable = true },

    -- comments management based on cursor position
    context_commentstring = { enable = true },

    -- parentheses coloring
    rainbow = { enable = true, extended_mode = false, max_file_lines = 1000 },

    -- location & syntax aware text objects
    textsubjects = {
        enable = true,
        keymaps = {
            ["."] = "textsubjects-smart",
            [";"] = "textsubjects-container-outer",
        },
    },

    -- text objects for language features
    textobjects = {
        select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ["af"] = "@function.outer",
                ["if"] = "@function.inner",
                ["al"] = "@loop.outer",
                ["il"] = "@loop.inner",
                ["ac"] = "@conditional.outer",
                ["ic"] = "@conditional.inner",
                ["ap"] = "@parameter.outer",
                ["ip"] = "@parameter.inner",

                -- xml attribute
                ["ax"] = "@attribute.outer",
                ["ix"] = "@attribute.inner",

                -- json
                ["ak"] = "@key.outer",
                ["ik"] = "@key.inner",
                ["av"] = "@value.outer",
                ["iv"] = "@value.inner",
            },
        },
        -- Go to next/prev function/class
        move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
                ["]]"] = "@function.outer",
                ["]c"] = "@class.outer",
            },
            goto_next_end = {
                ["]["] = "@function.outer",
                ["]C"] = "@class.outer",
            },
            goto_previous_start = {
                ["[["] = "@function.outer",
                ["[c"] = "@class.outer",
            },
            goto_previous_end = {
                ["[]"] = "@function.outer",
                ["[C"] = "@class.outer",
            },
        },
        -- Swap function parameters
        swap = {
            enable = true,
            swap_next = { ["<leader>xp"] = "@parameter.inner" },
            swap_previous = { ["<leader>xP"] = "@parameter.inner" },
        },
    },
})

-----------------------------------------------------------
-- Folding
-----------------------------------------------------------
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
