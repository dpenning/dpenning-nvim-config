local terminal_utils = require("utils.terminal_utils")
local M = {}

function M.open_terminal_80()
    -- Search for the main terminal buffer
    local terminal_buf = terminal_utils.find_main_terminal()

    if terminal_buf ~= -1 then
        -- If found, check if it's already visible in a window
        local win = vim.fn.bufwinid(terminal_buf)
        if win ~= -1 then
            vim.api.nvim_set_current_win(win)
        else
            -- If not visible, open it in a 80vsplit
            vim.cmd("botright 80vsplit")
            vim.api.nvim_set_current_buf(terminal_buf)
        end
    else
        -- If no terminal exists, create a new one
        vim.cmd("botright 80vsplit | term")
        local new_buf = vim.api.nvim_get_current_buf()
        terminal_utils.mark_as_main(new_buf)
    end

    -- Automatically enter insert mode
    vim.cmd("startinsert")
end

-- Register the command
vim.api.nvim_create_user_command("Term80", M.open_terminal_80, {})

return M
