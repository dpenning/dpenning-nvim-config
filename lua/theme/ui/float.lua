-- lua/theme/ui/float.lua
local M = {}

function M.create(buf, opts)
    opts = opts or {}
    local width = opts.width or 60
    local height = opts.height or 20

    local editor_height = vim.o.lines
    local editor_width = vim.o.columns
    local row = math.max(0, math.floor((editor_height - height) / 2) - 1)
    local col = math.max(0, math.floor((editor_width - width) / 2))

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        row = row,
        col = col,
        width = width,
        height = height,
        border = opts.border or "rounded",
        zindex = 60,
        title = opts.title,
        title_pos = opts.title_pos or "center",
    })

    vim.api.nvim_set_option_value("wrap", false, { win = win })
    vim.api.nvim_set_option_value("cursorline", true, { win = win })
    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })

    return win
end

return M
