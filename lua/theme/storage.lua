local M = {}

local COLOR_KEYS = { "foreground", "background", "highlight", "accent" }

local function get_data_dir()
    local state_dir = vim.fn.stdpath("state")
    if not state_dir or state_dir == "" then
        state_dir = vim.fn.stdpath("data")
    end
    local dir = vim.fn.fnamemodify(state_dir .. "/theme", ":p")
    vim.fn.mkdir(dir, "p")
    return dir
end

local function preference_path()
    return get_data_dir() .. "/preference.txt"
end

local function themes_db_path()
    return vim.fn.stdpath("config") .. "/lua/theme/themes.json"
end

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

local function read_file(path)
    local file = io.open(path, "r")
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

local function write_file(path, text)
    local ok, err = pcall(function()
        local file = assert(io.open(path, "w"))
        file:write(text)
        file:close()
    end)
    if not ok then
        vim.notify(string.format("Failed to write to %s: %s", path, err), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function canonical_config(config)
    if type(config) ~= "table" then
        return nil
    end
    local sanitized = {}
    -- Save description if present
    if config.description and type(config.description) == "string" then
        sanitized.description = trim(config.description)
    end
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

local function load_db()
    local content = read_file(themes_db_path())
    if not content or content == "" then
        return {}
    end
    local ok, decoded = pcall(json_decode, content)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return {}
end

local function save_db(db)
    local ok, encoded = pcall(json_encode, db)
    if not ok then
        return false
    end
    return write_file(themes_db_path(), encoded)
end

function M.path()
    return preference_path()
end

-- Loads the current *active* preference (what theme is selected)
function M.load()
    local content = read_file(preference_path())
    if not content or content == "" then
        return nil
    end

    -- Legacy/Simple format: just the name
    if content:sub(1, 1) ~= "{" then
        return content
    end

    -- JSON format
    local ok, decoded = pcall(json_decode, content)
    if ok and type(decoded) == "table" then
        if decoded.name then
            return decoded.name
        end
    end
    return nil
end

-- Saves the *active* preference pointer
function M.save(name)
    if type(name) ~= "string" then
        return false
    end
    name = trim(name)
    if name == "" then
        return false
    end
    return write_file(preference_path(), name)
end

-- Returns a map of all themes: { [name] = config }
function M.get_all_themes()
    return load_db()
end

-- Returns a specific theme config
function M.get_theme(name)
    local db = load_db()
    return db[name]
end

-- Saves/Upserts a theme into the DB
function M.save_theme(config, opts)
    local sanitized = canonical_config(config)
    if not sanitized then
        vim.notify("Cannot save invalid theme", vim.log.levels.ERROR)
        return false
    end
    
    local name = (opts and opts.name) or "custom"
    if name == "" then name = "custom" end

    local db = load_db()
    db[name] = sanitized
    
    if not save_db(db) then
        return false
    end

    -- Also update the active preference to point to this new theme
    write_file(preference_path(), name)

    return true
end

function M.delete_theme(name)
    local db = load_db()
    if not db[name] then
        return false
    end
    db[name] = nil
    return save_db(db)
end

return M
