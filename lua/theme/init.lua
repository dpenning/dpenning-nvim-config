local generator = require("theme.generator")
local presets = require("theme.presets")
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
    
    -- Add presets
    local preset_list = presets.list()
    for _, p in ipairs(preset_list) do
        table.insert(all_themes, p)
    end

    -- Add custom themes
    local custom = storage.list_custom()
    for name, config in pairs(custom) do
        table.insert(all_themes, {
            name = name,
            label = name, -- Custom themes might not have a separate label
            description = config.description or "Custom User Theme",
            type = "custom",
            config = config, -- Store config for easy access
            foreground = config.foreground,
            background = config.background,
            highlight = config.highlight,
            accent = config.accent,
        })
    end
    
    return all_themes
end

function M.get(name)
    local preset = presets.get(name)
    if preset then
        return preset
    end
    local custom = storage.get_custom(name)
    if custom then
        return {
            name = name,
            description = custom.description or "Custom User Theme",
            type = "custom",
            foreground = custom.foreground,
            background = custom.background,
            highlight = custom.highlight,
            accent = custom.accent,
        }
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
    return storage.delete_custom(name)
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
    local saved = storage.load()
    if type(saved) == "table" then
        if saved.type == "custom" and saved.config then
            apply_config(saved.config, { name = saved.name or "custom" })
            return saved.name or "custom"
        elseif saved.type == "preset" and saved.name and presets.get(saved.name) then
            M.apply(saved.name)
            return saved.name
        end
    elseif type(saved) == "string" then
        if presets.get(saved) then
            M.apply(saved)
            return saved
        end
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
