local M = {}

local function state_path()
    local state_dir = vim.fn.stdpath("state")
    if not state_dir or state_dir == "" then
        state_dir = vim.fn.stdpath("data")
    end
    local dir = vim.fn.fnamemodify(state_dir .. "/theme", ":p")
    vim.fn.mkdir(dir, "p")
    return dir .. "/preference.txt"
end

local preference_path = state_path()

function M.path()
    return preference_path
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.load()
    local file = io.open(preference_path, "r")
    if not file then
        return nil
    end
    local ok, content = pcall(function()
        local data = file:read("*a") or ""
        file:close()
        return data
    end)
    if not ok then
        return nil
    end
    content = trim(content)
    if content == "" then
        return nil
    end
    return content
end

function M.save(name)
    if not name or name == "" then
        return false
    end
    local ok, err = pcall(function()
        local file = assert(io.open(preference_path, "w"))
        file:write(name)
        file:close()
    end)
    if not ok then
        vim.notify(string.format("Failed to save theme preference: %s", err), vim.log.levels.ERROR)
        return false
    end
    return true
end

return M
