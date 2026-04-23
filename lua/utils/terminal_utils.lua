local M = {}

-- Constant for terminal marking
M.MAIN_TERMINAL_VAR = "is_main_terminal"

local function is_valid_terminal_buffer(buf)
    return buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal"
end

local function basename(path)
    return (path and path:match("([^/\\]+)$")) or path
end

local function is_allowed_shell_command(cmd)
    local cmd_str = cmd
    if type(cmd) == "table" then
        cmd_str = cmd[1]
    end
    if type(cmd_str) ~= "string" or cmd_str == "" then
        return false
    end

    local first_token = cmd_str:match("^%s*(%S+)") or cmd_str
    local exe = basename(first_token)
    return exe == "zsh" or exe == "bash"
end

function M.is_shell_terminal(buf)
    if not is_valid_terminal_buffer(buf) then
        return false
    end

    local ok_job, job_id = pcall(vim.api.nvim_buf_get_var, buf, "terminal_job_id")
    if ok_job and job_id then
        local has_jobinfo = vim.fn.exists("*jobinfo") == 1
        if has_jobinfo then
            local ok_info, info = pcall(vim.fn.jobinfo, job_id)
            if ok_info and type(info) == "table" then
                local entry = info[1] or info
                if type(entry) == "table" and is_allowed_shell_command(entry.cmd) then
                    return true
                end
            end
        end
    end

    local ok_title, term_title = pcall(vim.api.nvim_buf_get_var, buf, "term_title")
    local name = vim.api.nvim_buf_get_name(buf)
    local fallback = ((ok_title and term_title) or "") .. " " .. (name or "")
    fallback = fallback:lower()

    local has_shell = fallback:match("%f[%a]zsh%f[^%a]") or fallback:match("%f[%a]bash%f[^%a]")
    local has_tool = fallback:match("fzf") or fallback:match("neo%-tree")
    return has_shell and not has_tool
end

-- Finds the main terminal buffer
function M.find_main_terminal()
    -- 1. Look for marked buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if M.is_shell_terminal(buf) then
            local ok, is_main = pcall(vim.api.nvim_buf_get_var, buf, M.MAIN_TERMINAL_VAR)
            if ok and is_main then
                return buf
            end
        end
    end

    -- 2. Fallback: Search for an existing shell terminal buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if M.is_shell_terminal(buf) then
            -- Mark it as main for next time
            M.mark_as_main(buf)
            return buf
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
