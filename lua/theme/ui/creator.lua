local api = vim.api
local theme = require("theme")
local generator = require("theme.generator")
local storage = require("theme.storage")
local theme_debug = require("commands.theme_debug")

local DEFAULT_CONFIG = {
    foreground = "#cdd6f4",
    background = "#1e1e2e",
    highlight = "#f5e0dc",
    accent = "#89b4fa",
}

local COLOR_FIELDS = {
    { key = "foreground", label = "Foreground" },
    { key = "background", label = "Background" },
    { key = "highlight", label = "Highlight" },
    { key = "accent", label = "Accent" },
}

local META_FIELDS = {
    { key = "name", label = "Name" },
    { key = "description", label = "Description" },
}

local CUSTOM_THEME_NAME = "custom"
local STATUS_NS = api.nvim_create_namespace("theme_creator_status")
local PREVIEW_NS = api.nvim_create_namespace("theme_creator_preview")
local SWATCH_TEXT = "##"

local GRADIENT_SPECS = {
    { key = "background_to_foreground", label = "BG -> FG" },
    { key = "background_to_highlight", label = "BG -> Highlight" },
    { key = "background_to_accent", label = "BG -> Accent" },
    { key = "foreground_to_highlight", label = "FG -> Highlight" },
    { key = "foreground_to_accent", label = "FG -> Accent" },
    { key = "highlight_to_accent", label = "Highlight -> Accent" },
}

local active_instance = nil

local function notify_theme_change()
    for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_valid(buf) and api.nvim_get_option_value("filetype", { buf = buf }) == "theme-debug" then
            theme_debug.refresh(buf)
        end
    end
end

local function current_theme_config()
    return theme.last_config() or vim.deepcopy(DEFAULT_CONFIG)
end

local function build_lines(config, name)
    local lines = {
        "# Theme Creator",
        "# Edit the fields below. Colors update live as you type.",
        "# :w saves the theme. :q closes without saving changes.",
        "",
    }
    for _, field in ipairs(META_FIELDS) do
        local val = config[field.key]
        if field.key == "name" and (not val or val == "") then val = name end
        if field.key == "name" and val == CUSTOM_THEME_NAME then val = "" end
        table.insert(lines, string.format("%-12s = %s", field.key, val or ""))
    end
    table.insert(lines, "")
    for _, field in ipairs(COLOR_FIELDS) do
        table.insert(lines, string.format("%-12s = %s", field.key, config[field.key] or ""))
    end
    table.insert(lines, "")
    table.insert(lines, "# Gradient preview (read-only)")
    table.insert(lines, "# Each row shows the gradient steps used across the theme.")
    local preview_anchor = #lines + 1
    table.insert(lines, "")
    return lines, preview_anchor
end

local function max_width(lines)
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    return width
end

local function set_status(instance, text, hl)
    if not instance or not api.nvim_buf_is_valid(instance.buf) then
        return
    end
    api.nvim_buf_clear_namespace(instance.buf, STATUS_NS, 0, -1)
    if not text or text == "" then
        return
    end
    local line = instance.status_line or 1
    api.nvim_buf_set_extmark(instance.buf, STATUS_NS, line, 0, {
        virt_text = { { text, hl or "Comment" } },
        virt_text_pos = "right_align",
    })
end

local function normalize_hex(color)
    if type(color) ~= "string" then
        return nil
    end
    local normalized = color:lower()
    if not normalized:match("^#%x%x%x%x%x%x$") then
        return nil
    end
    return normalized
end

local function get_swatch_highlight(color)
    local normalized = normalize_hex(color)
    if not normalized then
        return nil
    end
    local group = "ThemeCreatorSwatch_" .. normalized:sub(2)
    api.nvim_set_hl(0, group, { fg = normalized })
    return group
end

local function build_gradient_preview_lines(palette, opts)
    if opts and opts.message then
        return { { { opts.message, "Comment" } } }
    end
    if not palette or type(palette.gradients) ~= "table" then
        return { { { "Gradients unavailable", "Comment" } } }
    end

    local virt_lines = {}
    for _, spec in ipairs(GRADIENT_SPECS) do
        local gradient = palette.gradients[spec.key]
        local label = spec.label or spec.key
        local chunks = { { string.format("%s: ", label), "Comment" } }
        if gradient and #gradient > 0 then
            for _, hex in ipairs(gradient) do
                local hl = get_swatch_highlight(hex) or "Normal"
                table.insert(chunks, { SWATCH_TEXT, hl })
                table.insert(chunks, { " ", "Normal" })
            end
            chunks[#chunks] = nil
        else
            table.insert(chunks, { "(no data)", "Comment" })
        end
        table.insert(virt_lines, chunks)
    end

    if #virt_lines == 0 then
        table.insert(virt_lines, { { "Gradients unavailable", "Comment" } })
    end
    return virt_lines
end

local function render_gradient_preview(instance, opts)
    if not instance or not instance.preview_line then
        return
    end
    if not instance.buf or not api.nvim_buf_is_valid(instance.buf) then
        return
    end
    if instance.preview_mark then
        pcall(api.nvim_buf_del_extmark, instance.buf, PREVIEW_NS, instance.preview_mark)
        instance.preview_mark = nil
    end
    local virt_lines = build_gradient_preview_lines(opts and opts.palette or generator.palette(), opts)
    instance.preview_mark = api.nvim_buf_set_extmark(instance.buf, PREVIEW_NS, instance.preview_line, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
    })
end

local function extract_values(buf)
    local result = {}
    local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
    for _, line in ipairs(lines) do
        local key, value = line:match("^%s*([%w_]+)%s*=%s*(.*)$")
        if key then
            key = key:lower()
            value = vim.trim(value)
            
            local is_color = false
            for _, field in ipairs(COLOR_FIELDS) do
                if field.key == key then
                    if value:match("^#[%xX]+") then
                        result[key] = value:match("^(#[%xX]+)")
                    else
                        result[key] = value
                    end
                    is_color = true
                    break
                end
            end
            
            if not is_color then
                for _, field in ipairs(META_FIELDS) do
                    if field.key == key then
                        result[key] = value
                        break
                    end
                end
            end
        end
    end
    return result
end

local function validate_config(values)
    local config = {}
    for _, field in ipairs(COLOR_FIELDS) do
        local raw = values[field.key]
        if type(raw) ~= "string" then
            return nil, string.format("%s color missing", field.label)
        end
        local normalized = raw:lower()
        if not normalized:match("^#%x%x%x%x%x%x$") then
            return nil, string.format("%s must be #RRGGBB", field.label)
        end
        config[field.key] = normalized
    end
    
    for _, field in ipairs(META_FIELDS) do
        if values[field.key] then
            config[field.key] = values[field.key]
        end
    end
    
    return config, nil
end

local function configs_equal(a, b)
    if not a or not b then
        return false
    end
    for _, field in ipairs(COLOR_FIELDS) do
        if a[field.key] ~= b[field.key] then
            return false
        end
    end
    -- Also check name/desc? Maybe strictly colors for dirty check
    -- If name/desc changes, it is dirty.
    for _, field in ipairs(META_FIELDS) do
        if (a[field.key] or "") ~= (b[field.key] or "") then
            return false
        end
    end
    return true
end

local function apply_snapshot(snapshot)
    if not snapshot or not snapshot.config then
        return
    end
    theme.apply(snapshot.config, { name = snapshot.name })
end

local function capture_snapshot(name, config)
    return {
        name = name,
        config = vim.deepcopy(config),
    }
end

local function perform_preview(instance)
    if not api.nvim_buf_is_valid(instance.buf) then
        return
    end
    local values = extract_values(instance.buf)
    local config, err = validate_config(values)
    if config then
        theme.apply(config, { name = CUSTOM_THEME_NAME })
        notify_theme_change()
        instance.last_preview_config = vim.deepcopy(config)
        instance.dirty = not configs_equal(config, instance.saved_config)
        if instance.dirty then
            set_status(instance, "Previewing unsaved theme", "DiagnosticWarn")
        else
            set_status(instance, "All changes saved", "DiagnosticOk")
        end
        render_gradient_preview(instance, { palette = generator.palette() })
    else
        instance.last_preview_config = nil
        instance.dirty = true
        set_status(instance, err or "Enter #RRGGBB colors", "WarningMsg")
        render_gradient_preview(instance, { message = err or "Invalid colors" })
    end
    api.nvim_set_option_value("modified", false, { buf = instance.buf })
end

local function schedule_preview(instance)
    if instance.pending_update then
        return
    end
    instance.pending_update = true
    instance.dirty = true
    if instance.buf and api.nvim_buf_is_valid(instance.buf) then
        api.nvim_set_option_value("modified", false, { buf = instance.buf })
    end
    vim.schedule(function()
        if not instance.buf or not api.nvim_buf_is_valid(instance.buf) then
            return
        end
        instance.pending_update = false
        perform_preview(instance)
    end)
end

local function persist_theme(instance)
    if not api.nvim_buf_is_valid(instance.buf) then
        return
    end
    local values = extract_values(instance.buf)
    local config, err = validate_config(values)
    if not config then
        set_status(instance, err or "Invalid colors", "WarningMsg")
        vim.notify(err or "Enter valid hex colors", vim.log.levels.WARN)
        return
    end

    local name = config.name
    if not name or name == "" or name == CUSTOM_THEME_NAME then
        -- Fallback to input if empty in buffer
        name = vim.fn.input("Theme Name: ", instance.theme_name ~= CUSTOM_THEME_NAME and instance.theme_name or "")
        if name == "" then
            vim.notify("Save cancelled: Name required", vim.log.levels.WARN)
            return
        end
        config.name = name
    end

    theme.apply(config, { name = name })
    notify_theme_change()
    if not storage.save_custom(config, { name = name }) then
        return
    end
    
    instance.theme_name = name
    instance.saved_config = vim.deepcopy(config)
    instance.snapshot = capture_snapshot(name, config)
    instance.dirty = false
    api.nvim_set_option_value("modified", false, { buf = instance.buf })
    set_status(instance, "Theme saved: " .. name, "DiagnosticOk")
    render_gradient_preview(instance, { palette = generator.palette() })
    vim.notify("Theme saved: " .. name, vim.log.levels.INFO)
end

local function close_instance(instance)
    if not instance then
        return
    end
    if instance.dirty then
        apply_snapshot(instance.snapshot)
    end
    if instance.win and api.nvim_win_is_valid(instance.win) then
        api.nvim_win_close(instance.win, true)
    elseif instance.buf and api.nvim_buf_is_valid(instance.buf) then
        api.nvim_buf_delete(instance.buf, { force = true })
    end
end

local function open_theme_creator(opts)
    opts = opts or {}
    if active_instance and active_instance.buf and api.nvim_buf_is_valid(active_instance.buf) then
        if active_instance.win and api.nvim_win_is_valid(active_instance.win) then
            api.nvim_set_current_win(active_instance.win)
        else
            api.nvim_set_current_buf(active_instance.buf)
        end
        return
    end

    local theme_name = opts.name or theme.current_name()
    local initial_config = current_theme_config()
    local snapshot = capture_snapshot(theme_name, initial_config)
    local lines, preview_anchor = build_lines(initial_config, theme_name)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(buf, "ThemeCreator_" .. os.time())
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    api.nvim_set_option_value("swapfile", false, { buf = buf })
    api.nvim_set_option_value("filetype", "theme-creator", { buf = buf })
    api.nvim_buf_set_var(buf, "smart_quit_disabled", true)

    local width = math.max(40, max_width(lines) + 4)
    local height = #lines + 2
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = api.nvim_open_win(buf, true, {
        relative = "editor",
        row = math.max(row, 1),
        col = math.max(col, 1),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        zindex = 60,
    })

    api.nvim_set_option_value("winhighlight", "NormalFloat:Normal", { win = win })
    api.nvim_set_option_value("number", false, { win = win })
    api.nvim_set_option_value("relativenumber", false, { win = win })
    api.nvim_set_option_value("cursorline", false, { win = win })
    api.nvim_set_option_value("wrap", false, { win = win })

    local instance = {
        buf = buf,
        win = win,
        theme_name = theme_name,
        snapshot = snapshot,
        saved_config = vim.deepcopy(initial_config),
        status_line = 1,
        dirty = false,
        preview_line = preview_anchor and (preview_anchor - 1) or nil,
        preview_mark = nil,
    }
    active_instance = instance

    set_status(instance, "Edit colors to preview", "Comment")
    perform_preview(instance)

    api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = buf,
        callback = function()
            schedule_preview(instance)
        end,
    })

    api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            persist_theme(instance)
        end,
    })

    api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = function()
            if instance.dirty then
                apply_snapshot(instance.snapshot)
            end
            active_instance = nil
        end,
    })
end

vim.api.nvim_create_user_command("ThemeCreator", open_theme_creator, {})

return {
    open = open_theme_creator,
    close = close_instance,
}
