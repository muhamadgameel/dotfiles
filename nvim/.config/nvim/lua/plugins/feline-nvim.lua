local lsp = require("feline.providers.lsp")
local vi_mode_utils = require("feline.providers.vi_mode")

local b = vim.b

-- Init Properties
-----------------------------------------------------------
local bg = "#111111"
local fg = "#eeeeee"
local force_inactive = {filetypes = {}, buftypes = {}, bufnames = {}}

force_inactive.filetypes = {
    "NvimTree", "Trouble", "packer", "fugitive", "fugitiveblame", "help"
}

force_inactive.buftypes = {"terminal"}

-- Init Components
-----------------------------------------------------------
local components = {active = {}, inactive = {}}

-- Insert three sections (left, mid and right) for the active statusline
table.insert(components.active, {})
table.insert(components.active, {})
table.insert(components.active, {})

-- Insert two sections (left and right) for the inactive statusline
table.insert(components.inactive, {})
table.insert(components.inactive, {})

-----------------------------------------------------------
-- Left Active
-----------------------------------------------------------
table.insert(components.active[1], {provider = "▊ ", hl = {fg = "skyblue"}})

table.insert(components.active[1], {
    provider = "vi_mode",
    hl = function()
        local val = {}

        val.name = vi_mode_utils.get_mode_highlight_name()
        val.fg = vi_mode_utils.get_mode_color()
        val.style = "bold"

        return val
    end,
    right_sep = " "
})

table.insert(components.active[1], {
    provider = "vi_mode",
    hl = function()
        local val = {}

        val.name = vi_mode_utils.get_mode_highlight_name()
        val.fg = vi_mode_utils.get_mode_color()
        val.style = "bold"

        return val
    end,
    right_sep = " ",
    icon = ""
})

table.insert(components.active[1], {
    provider = "file_info",
    hl = {fg = "white", bg = "oceanblue", style = "bold"},
    left_sep = {
        " ", "slant_left_2", {str = " ", hl = {bg = "oceanblue", fg = "NONE"}}
    },
    right_sep = {
        {str = " ", hl = {bg = "oceanblue", fg = "NONE"}}, "slant_right_2", " "
    }
})

table.insert(components.active[1], {
    provider = "diagnostic_errors",
    enabled = function()
        return lsp.diagnostics_exist(vim.diagnostic.severity.ERROR)
    end,
    hl = {fg = "red"},
    icon = "✘ ",
    right_sep = " "
})

table.insert(components.active[1], {
    provider = "diagnostic_warnings",
    enabled = function()
        return lsp.diagnostics_exist(vim.diagnostic.severity.WARN)
    end,
    hl = {fg = "yellow"},
    icon = " ",
    right_sep = " "
})

table.insert(components.active[1], {
    provider = "diagnostic_hints",
    enabled = function()
        return lsp.diagnostics_exist(vim.diagnostic.severity.HINT)
    end,
    hl = {fg = "cyan"},
    icon = " ",
    right_sep = " "
})

table.insert(components.active[1], {
    provider = "diagnostic_info",
    enabled = function()
        return lsp.diagnostics_exist(vim.diagnostic.severity.INFO)
    end,
    hl = {fg = "skyblue"},
    icon = " ",
    right_sep = " "
})

-----------------------------------------------------------
-- Left InActive
-----------------------------------------------------------
table.insert(components.inactive[1], {
    provider = "file_type",
    hl = {fg = "white", bg = "oceanblue", style = "bold"},
    left_sep = {str = " ", hl = {fg = "NONE", bg = "oceanblue"}},
    right_sep = {
        {str = " ", hl = {fg = "NONE", bg = "oceanblue"}}, "slant_right"
    }
})

-----------------------------------------------------------
-- Right
-----------------------------------------------------------
table.insert(components.active[3], {
    provider = function() return require("nvim-gps").get_location() end,
    enabled = function() return require("nvim-gps").is_available() end,
    hl = {fg = "orange", bg = "#111111", style = "bold"},
    right_sep = {
        " ", {str = "vertical_bar_thin", hl = {bg = "#111111", fg = "orange"}},
        " "
    }
})

table.insert(components.active[3], {
    provider = " ",
    hl = {fg = "NONE", bg = "#3F3F46"},
    left_sep = {str = "left_rounded", hl = {bg = bg, fg = "#3F3F46"}},
    enabled = function() return b.gitsigns_status_dict end
})

table.insert(components.active[3], {
    provider = "git_branch",
    hl = {fg = "white", bg = "#3F3F46", style = "bold"}
})

table.insert(components.active[3], {
    provider = "git_diff_added",
    hl = {fg = "#22C55E", bg = "#3F3F46"}
})

table.insert(components.active[3], {
    provider = "git_diff_changed",
    hl = {fg = "#FACC15", bg = "#3F3F46"}
})

table.insert(components.active[3], {
    provider = "git_diff_removed",
    hl = {fg = "#F87171", bg = "#3F3F46"}
})

table.insert(components.active[3], {
    provider = " ",
    hl = {fg = "NONE", bg = "#3F3F46"},
    right_sep = {str = "right_rounded", hl = {bg = bg, fg = "#3F3F46"}},
    enabled = function() return b.gitsigns_status_dict end
})

table.insert(components.active[3], {
    provider = "line_percentage",
    hl = {style = "bold"},
    left_sep = " ",
    right_sep = " "
})

table.insert(components.active[3],
             {provider = "scroll_bar", hl = {fg = "skyblue", style = "bold"}})

-----------------------------------------------------------
-- Setup
-----------------------------------------------------------
local colors = {bg = '#111111', black = '#111111', yellow = '#d8a657'}

require("feline").setup({
    theme = colors,
    default_bg = bg,
    default_fg = fg,
    components = components,
    force_inactive = force_inactive
})
