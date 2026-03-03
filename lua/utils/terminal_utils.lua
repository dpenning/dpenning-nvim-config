local M = {}

-- Constant for terminal marking
M.MAIN_TERMINAL_VAR = "is_main_terminal"

-- Finds the main terminal buffer
function M.find_main_terminal()
    -- 1. Look for marked buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
            local ok, is_main = pcall(vim.api.nvim_buf_get_var, buf, M.MAIN_TERMINAL_VAR)
            if ok and is_main then
                return buf
            end
        end
    end

    -- 2. Fallback: Search for an existing shell terminal buffer that isn't fzf
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            local name = vim.api.nvim_buf_get_name(buf)
            local is_fuzzy = name:match("fzf") or name:match("FZF")
            local is_shell = name:match("bash") or name:match("zsh") or name:match("fish") or name:match("sh")
            
            if not is_fuzzy and (is_shell or name == "") then
                -- Mark it as main for next time
                M.mark_as_main(buf)
                return buf
            end
        end
    end

    return -1
end

-- Marks a buffer as the main terminal
function M.mark_as_main(buf)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_set_var(buf, M.MAIN_TERMINAL_VAR, true)
    end
end

return M
