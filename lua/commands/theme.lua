local theme = require("theme")

local function build_lines(entries, current)
    local lines = {}
    local width = 0

    for _, preset in ipairs(entries) do
        local marker = preset.name == current and "*" or " "
        local description = preset.description and (" - " .. preset.description) or ""
        local line = string.format("%s %s%s", marker, preset.label, description)
        table.insert(lines, line)
        width = math.max(width, #line)
    end

    return lines, width
end

local function open_theme_picker()
    local entries = theme.list()
    if #entries == 0 then
        vim.notify("No themes available", vim.log.levels.WARN)
        return
    end

    local current_name = theme.current_name()
    local lines, content_width = build_lines(entries, current_name)
    local width = content_width + 2
    local max_height = math.max(3, math.floor(vim.o.lines * 0.6))
    local height = math.min(#lines, max_height)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("filetype", "theme-picker", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    vim.api.nvim_buf_set_var(buf, "smart_quit_disabled", true)

    local editor_height = vim.o.lines
    local editor_width = vim.o.columns
    local row = math.max(0, math.floor((editor_height - height) / 2) - 1)
    local col = math.max(0, math.floor((editor_width - width) / 2))

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        row = row,
        col = col,
        width = width,
        height = height,
        border = "rounded",
        zindex = 60,
    })

    vim.api.nvim_set_option_value("wrap", false, { win = win })
    vim.api.nvim_set_option_value("cursorline", true, { win = win })
    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })

    local saved_snapshot = {
        name = current_name,
        config = theme.last_config(),
    }
    local preview_name = current_name
    local dirty = false
    local current_index = nil
    local cursor_move_autocmd = nil

    local function set_dirty(flag)
        dirty = flag
    end

    local function update_dirty_state(name)
        if saved_snapshot.name then
            set_dirty(name ~= saved_snapshot.name)
        else
            set_dirty(name ~= nil)
        end
    end

    local function revert_to_saved()
        if saved_snapshot.name then
            theme.apply(saved_snapshot.name)
            return
        end
        if saved_snapshot.config then
            theme.apply(saved_snapshot.config)
        end
    end

    local function close_picker(opts)
        opts = opts or {}
        if cursor_move_autocmd then
            pcall(vim.api.nvim_del_autocmd, cursor_move_autocmd)
            cursor_move_autocmd = nil
        end
        if not opts.keep and dirty then
            revert_to_saved()
        end
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
            win = nil
        end
        if buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
            buf = nil
        end
    end

    local function apply_index(idx)
        local preset = entries[idx]
        if not preset then
            return
        end
        current_index = idx
        if preset.name == preview_name then
            return
        end
        preview_name = preset.name
        theme.apply(preset.name)
        update_dirty_state(preview_name)
    end

    local start_index = 1
    if preview_name then
        for i, preset in ipairs(entries) do
            if preset.name == preview_name then
                start_index = i
                break
            end
        end
    end
    current_index = start_index
    vim.api.nvim_win_set_cursor(win, { start_index, 0 })

    cursor_move_autocmd = vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then
                return
            end
            local cursor = vim.api.nvim_win_get_cursor(win)
            apply_index(cursor[1])
        end,
    })

    local function persist_selection()
        local selection = entries[current_index or 1]
        if not selection then
            return
        end
        if selection.name ~= preview_name then
            preview_name = selection.name
            theme.apply(selection.name)
            update_dirty_state(preview_name)
        end
        if not theme.save(selection.name) then
            return
        end
        saved_snapshot = {
            name = selection.name,
            config = theme.last_config(),
        }
        preview_name = selection.name
        set_dirty(false)
        vim.notify(string.format("Theme saved: %s", selection.label), vim.log.levels.INFO)
    end

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            persist_selection()
        end,
    })

    local function apply_and_close()
        persist_selection()
        close_picker({ keep = true })
    end

    vim.keymap.set("n", "<CR>", apply_and_close, { buffer = buf, nowait = true, silent = true })
    vim.keymap.set("n", "<Esc>", close_picker, { buffer = buf, nowait = true, silent = true })
    vim.keymap.set("n", "q", close_picker, { buffer = buf, nowait = true, silent = true })

    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        once = true,
        callback = function()
            if cursor_move_autocmd then
                pcall(vim.api.nvim_del_autocmd, cursor_move_autocmd)
                cursor_move_autocmd = nil
            end
            close_picker()
        end,
    })
end

vim.api.nvim_create_user_command("Theme", open_theme_picker, {})

return {
    open = open_theme_picker,
}
