local addEventListener = utils.events.addEventListener

-- Highlight yanked text on yanking
addEventListener("YankHighlight", { "TextYankPost *" }, function() require"vim.highlight".on_yank {
    timeout = 500,
} end)

-- When opening a file, jump to the last known cursor position.
addEventListener("CursorJumpLastPos", { "BufReadPost *" },
    function() vim.cmd [[if line("'\"") >= 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif]] end)

-- remove trailing whitespace on save
addEventListener("RemoveTrailingSpaces", { "BufWritePre *" }, function() vim.cmd [[:%s/\s\+$//e]] end)
