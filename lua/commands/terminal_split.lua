local M = {}

function M.open_terminal_80()
    -- 'rightbelow' forces the new window to be to the right of the current one
    vim.cmd("rightbelow 80vsplit | term")
    -- Automatically enter insert mode
    vim.cmd("startinsert")
end

-- Register the command
vim.api.nvim_create_user_command("Term80", M.open_terminal_80, {})

return M
