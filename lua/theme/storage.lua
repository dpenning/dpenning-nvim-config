local M = {}

local COLOR_KEYS = { "foreground", "background", "highlight", "accent" }

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

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function json_encode(value)
    if vim.json and vim.json.encode then
        return vim.json.encode(value)
    end
    return vim.fn.json_encode(value)
end

local function json_decode(text)
    if vim.json and vim.json.decode then
        return vim.json.decode(text)
    end
    return vim.fn.json_decode(text)
end

local function read_content()
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
    return trim(content)
end

local function write_text(text)
    local ok, err = pcall(function()
        local file = assert(io.open(preference_path, "w"))
        file:write(text)
        file:close()
    end)
    if not ok then
        vim.notify(string.format("Failed to save theme preference: %s", err), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function canonical_config(config)
    if type(config) ~= "table" then
        return nil
    end
    local sanitized = {}
    for _, key in ipairs(COLOR_KEYS) do
        local value = config[key]
        if type(value) ~= "string" then
            return nil
        end
        value = value:lower()
        if not value:match("^#%x%x%x%x%x%x$") then
            return nil
        end
        sanitized[key] = value
    end
    return sanitized
end

local function write_state(state)
    local ok, encoded = pcall(json_encode, state)
    if not ok then
        vim.notify(string.format("Failed to serialize theme preference: %s", encoded), vim.log.levels.ERROR)
        return false
    end
    return write_text(encoded)
end

function M.path()
    return preference_path
end

function M.load()
    local content = read_content()
    if not content or content == "" then
        return nil
    end

    if content:sub(1, 1) == "{" then
        local ok, decoded = pcall(json_decode, content)
        if ok and type(decoded) == "table" then
            if decoded.type == "custom" then
                local sanitized = canonical_config(decoded.config or {})
                if sanitized then
                    return {
                        type = "custom",
                        name = decoded.name or "custom",
                        config = sanitized,
                    }
                end
                return nil
            elseif decoded.type == "preset" and type(decoded.name) == "string" then
                return {
                    type = "preset",
                    name = decoded.name,
                }
            end
        end
    end

    return content
end

function M.save(name)
    if type(name) ~= "string" then
        return false
    end
    name = trim(name)
    if name == "" then
        return false
    end
    return write_text(name)
end

function M.save_custom(config, opts)
    local sanitized = canonical_config(config)
    if not sanitized then
        vim.notify("Cannot save invalid custom theme", vim.log.levels.ERROR)
        return false
    end
    local state = {
        type = "custom",
        name = (opts and opts.name) or "custom",
        config = sanitized,
    }
    return write_state(state)
end

return M
