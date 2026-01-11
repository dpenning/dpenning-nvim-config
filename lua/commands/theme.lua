local theme = require("theme")
local creator = require("commands.theme_creator")

local function build_lines(entries, current)
    local lines = {}
    local width = 0

    -- Special entry for creation
    table.insert(lines, " [+ Create New Theme] ")
    width = math.max(width, #lines[1])
    table.insert(lines, "") -- Separator

    for _, entry in ipairs(entries) do
        local marker = entry.name == current and "*" or " "
        local delete_btn = entry.type == "custom" and " [X]" or ""
        local description = entry.description and (" - " .. entry.description) or ""
        local line = string.format("%s %s%s%s", marker, entry.label, delete_btn, description)
        table.insert(lines, line)
        width = math.max(width, #line)
    end

    return lines, width
end

local function open_theme_picker()
    local entries = theme.list()
    local current_name = theme.current_name()
    local lines, content_width = build_lines(entries, current_name)
    local width = math.max(content_width + 4, 40)
    local max_height = math.max(5, math.floor(vim.o.lines * 0.6))
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
        title = " Theme Manager ",
        title_pos = "center",
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
    local cursor_move_autocmd = nil

    local function revert_to_saved()
        if saved_snapshot.name then
            theme.apply(saved_snapshot.name)
        elseif saved_snapshot.config then
            theme.apply(saved_snapshot.config)
        end
    end

    local function close_picker(opts)
        opts = opts or {}
        if cursor_move_autocmd then
            pcall(vim.api.nvim_del_autocmd, cursor_move_autocmd)
            cursor_move_autocmd = nil
        end
        if not opts.keep then
            revert_to_saved()
        end
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end

    local function get_selected_entry(cursor_row)
        local row = cursor_row or vim.api.nvim_win_get_cursor(win)[1]
        if row == 1 then return "create" end
        if row == 2 then return nil end
        return entries[row - 2]
    end

    local function apply_preview(row)
        local selection = get_selected_entry(row)
        if not selection or selection == "create" or selection.name == preview_name then
            return
        end
        preview_name = selection.name
        theme.apply(selection.name)
    end

    cursor_move_autocmd = vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            if not vim.api.nvim_win_is_valid(win) then return end
            apply_preview(vim.api.nvim_win_get_cursor(win)[1])
        end,
    })

    local function handle_cr()
        local selection = get_selected_entry()
        if not selection then return end

        if selection == "create" then
            close_picker({ keep = false }) -- Revert to saved before opening creator
            vim.schedule(function() creator.open() end)
            return
        end

        theme.apply(selection.name)
        theme.save(selection.name)
        close_picker({ keep = true })
        vim.notify("Theme saved: " .. selection.label, vim.log.levels.INFO)
    end

    local function handle_delete()
        local selection = get_selected_entry()
        if not selection or selection == "create" or selection.type ~= "custom" then
            return
        end

        local confirm = vim.fn.confirm("Delete theme '" .. selection.name .. "'?", "&Yes\n&No", 2)
        if confirm == 1 then
            theme.delete(selection.name)
            entries = theme.list()
            local new_lines, _ = build_lines(entries, theme.current_name())
            vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
            vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
            vim.notify("Deleted theme: " .. selection.name, vim.log.levels.INFO)
        end
    end

    local function handle_edit()
        local selection = get_selected_entry()
        if not selection or selection == "create" or selection.type ~= "custom" then
            return
        end
        close_picker({ keep = true }) -- Keep current preview (which is this theme)
        vim.schedule(function() creator.open({ name = selection.name }) end)
    end

    local map_opts = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set("n", "<CR>", handle_cr, map_opts)
    vim.keymap.set("n", "x", handle_delete, map_opts)
    vim.keymap.set("n", "d", handle_delete, map_opts)
    vim.keymap.set("n", "e", handle_edit, map_opts)
    vim.keymap.set("n", "<Esc>", function() close_picker({ keep = false }) end, map_opts)
    vim.keymap.set("n", "q", function() close_picker({ keep = false }) end, map_opts)

    -- Start cursor at current theme
    if current_name then
        for i, entry in ipairs(entries) do
            if entry.name == current_name then
                vim.api.nvim_win_set_cursor(win, { i + 2, 0 })
                break
            end
        end
    end
end

vim.api.nvim_create_user_command("Theme", open_theme_picker, {})

return {
    open = open_theme_picker,
}
