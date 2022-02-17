require("nvim-gps").setup({
    icons = {
        ["class-name"] = " ",
        ["function-name"] = " ",
        ["method-name"] = " ",
    },
    -- Disable any languages individually over here
    -- Any language not disabled here is enabled by default
    languages = {
        -- ["bash"] = false,
    },
    separator = " > ",
})
