local function do_clear()
    vim.opt_local.scrollback = 1
    vim.api.nvim_command("sleep 10m")
    vim.opt_local.scrollback = 10000
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('clear<CR>', true, false, true), 't', true)
    vim.cmd("startinsert")
end

vim.api.nvim_create_user_command('ClearTerm', function()
    if vim.bo.buftype == 'terminal' then
        do_clear()
        return
    end

    -- Search for an existing terminal buffer
    local terminal_buf = -1
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == "terminal" then
            terminal_buf = buf
            break
        end
    end

    if terminal_buf == -1 then
        print("No terminal buffer found.")
        return
    end

    -- Switch to the terminal window if it exists
    local win = vim.fn.bufwinid(terminal_buf)
    if win ~= -1 then
        vim.api.nvim_set_current_win(win)
        do_clear()
    else
        print("Found terminal buffer but it is not visible in any window.")
    end
end, { desc = 'Clear the terminal buffer so that it has no history' })
