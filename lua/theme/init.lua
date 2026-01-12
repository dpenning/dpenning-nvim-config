local generator = require("theme.generator")
local storage = require("theme.storage")

local M = {
    current = nil,
    _last_config = nil,
}

local function apply_config(config, opts)
    opts = opts or {}
    if not config
        or not config.foreground
        or not config.background
        or not config.highlight
        or not config.accent
    then
        vim.notify(
            "Theme configuration requires foreground, background, highlight, and accent colors",
            vim.log.levels.ERROR
        )
        return
    end
    generator.setup({
        foreground = config.foreground,
        background = config.background,
        highlight = config.highlight,
        accent = config.accent,
    })
    M.current = opts.name or config.name or nil
    M._last_config = {
        foreground = config.foreground,
        background = config.background,
        highlight = config.highlight,
        accent = config.accent,
    }
end

function M.list()
    local all_themes = {}
    local db_themes = storage.get_all_themes()
    
    for name, config in pairs(db_themes) do
        table.insert(all_themes, {
            name = name,
            label = config.label or name,
            description = config.description or "User Theme",
            type = "custom", -- Keeping "custom" type for compatibility with UI lists if they check it
            config = config,
            foreground = config.foreground,
            background = config.background,
            highlight = config.highlight,
            accent = config.accent,
        })
    end
    
    -- Sort by name for consistent UI
    table.sort(all_themes, function(a, b) return a.name < b.name end)
    
    return all_themes
end

function M.get(name)
    local theme = storage.get_theme(name)
    if theme then
        -- Ensure name is attached
        theme.name = name
        return theme
    end
    return nil
end

function M.apply(name_or_config, opts)
    if type(name_or_config) == "table" then
        apply_config(name_or_config, opts)
        return
    end

    local theme_data = M.get(name_or_config)
    if not theme_data then
        vim.notify(string.format("Theme '%s' not found", tostring(name_or_config)), vim.log.levels.WARN)
        return
    end

    apply_config(theme_data, { name = theme_data.name })
end

function M.delete(name)
    return storage.delete_theme(name)
end

function M.current_name()
    return M.current
end

function M.last_config()
    if not M._last_config then
        return nil
    end
    return vim.deepcopy(M._last_config)
end

function M.load(default_name)
    local saved_name = storage.load()
    if saved_name and M.get(saved_name) then
        M.apply(saved_name)
        return saved_name
    end

    if default_name then
        M.apply(default_name)
        return default_name
    end
    return nil
end

function M.save(name)
    local target = name or M.current
    if not target then
        vim.notify("No theme selected to save", vim.log.levels.WARN)
        return false
    end

    local theme_data = M.get(target)
    if not theme_data then
        vim.notify(string.format("Cannot save unknown theme '%s'", target), vim.log.levels.WARN)
        return false
    end

    return storage.save(target)
end

return M
