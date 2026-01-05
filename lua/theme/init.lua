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

function M.apply(name_or_config, opts)
    if type(name_or_config) == "table" then
        apply_config(name_or_config, opts)
        return
    end

    local preset = presets.get(name_or_config)
    if not preset then
        vim.notify(string.format("Theme '%s' not found", tostring(name_or_config)), vim.log.levels.WARN)
        return
    end

    apply_config(preset, { name = preset.name })
end

-- Compatibility shim so existing requires that call theme.setup still work
function M.setup(config)
    apply_config(config or {})
end

function M.list()
    return presets.list()
end

function M.get(name)
    return presets.get(name)
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

    if not presets.get(target) then
        vim.notify(string.format("Cannot save unknown theme '%s'", target), vim.log.levels.WARN)
        return false
    end

    return storage.save(target)
end

return M
