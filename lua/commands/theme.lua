local theme = require("theme")
local creator = require("commands.theme_creator")
local utils = require("theme.utils")

local function is_light(hex)
    if not hex then return false end
    local r, g, b = utils.hex_to_rgb(hex)
    -- Perceived brightness (standard formula)
    local brightness = (r * 299 + g * 587 + b * 114) / 1000
    return brightness > 128
end

local function build_lines(entries, current_name, active_tab)
    local lines = {}
    local width = 40 -- Minimum width

    -- Tab Header (Lines 1-2)
    local header = ""
    if active_tab == "dark" then
        header = "  [ Dark Themes ]    Light Themes   "
    else
        header = "    Dark Themes    [ Light Themes ] "
    end
    table.insert(lines, header)
    table.insert(lines, string.rep("─", #header))
    width = math.max(width, #header)

    -- Create Entry (Line 3)
    table.insert(lines, "  [+ Create New Theme] ")
    
    -- Separator (Line 4)
    table.insert(lines, "")

    -- Theme Entries (Lines 5+)
    local filtered = {}
    for _, entry in ipairs(entries) do
        local entry_is_light = is_light(entry.background)
        if (active_tab == "light" and entry_is_light) or (active_tab == "dark" and not entry_is_light) then
            table.insert(filtered, entry)
        end
    end

    for _, entry in ipairs(filtered) do
        local marker = entry.name == current_name and "*" or " "
        local delete_btn = entry.type == "custom" and " [X]" or ""
        local description = entry.description and (" - " .. entry.description) or ""
        local line = string.format(" %s %s%s%s", marker, entry.label, delete_btn, description)
        table.insert(lines, line)
        width = math.max(width, #line)
    end

    return lines, width, filtered
end

local function open_theme_picker()
    -- Load all themes and classify
    local all_entries = theme.list()
    local current_name = theme.current_name()
    local current_theme = theme.get(current_name)
    
    local active_tab = "dark"
    if current_theme and is_light(current_theme.background) then
        active_tab = "light"
    end

    -- State
    local state = {
        tab = active_tab,
        entries = all_entries,
        current_filtered = {} -- Populated by build_lines
    }

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("filetype", "theme-picker", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    vim.api.nvim_buf_set_var(buf, "smart_quit_disabled", true)

    local lines, content_width, _ = build_lines(state.entries, current_name, state.tab)
    local width = math.max(content_width + 4, 60)
    local max_height = math.max(10, math.floor(vim.o.lines * 0.7))
    local height = math.min(#lines, max_height)

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
        if row == 3 then return "create" end
        if row < 5 then return nil end
        return state.current_filtered[row - 4]
    end

    local function redraw()
        local new_lines, new_width, filtered = build_lines(state.entries, theme.current_name(), state.tab)
        state.current_filtered = filtered
        
        vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
        vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    end

    local function switch_tab()
        state.tab = state.tab == "dark" and "light" or "dark"
        redraw()
        -- Reset cursor to top of list
        vim.api.nvim_win_set_cursor(win, { 5, 0 })
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
        if not selection then
            -- Check if clicking header (lines 1-2) to switch? 
            -- For now just ignore
            local row = vim.api.nvim_win_get_cursor(win)[1]
            if row <= 2 then
                switch_tab()
            end
            return 
        end

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
            state.entries = theme.list() -- Refresh list
            redraw()
            vim.notify("Deleted theme: " .. selection.name, vim.log.levels.INFO)
        end
    end

    local function handle_edit()
        local selection = get_selected_entry()
        if not selection or selection == "create" or selection.type ~= "custom" then
            return
        end
        close_picker({ keep = true }) -- Keep current preview
        vim.schedule(function() creator.open({ name = selection.name }) end)
    end

    local map_opts = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set("n", "<CR>", handle_cr, map_opts)
    vim.keymap.set("n", "x", handle_delete, map_opts)
    vim.keymap.set("n", "d", handle_delete, map_opts)
    vim.keymap.set("n", "e", handle_edit, map_opts)
    vim.keymap.set("n", "<Esc>", function() close_picker({ keep = false }) end, map_opts)
    vim.keymap.set("n", "q", function() close_picker({ keep = false }) end, map_opts)
    
    -- Tab switching
    vim.keymap.set("n", "<Tab>", switch_tab, map_opts)
    vim.keymap.set("n", "L", switch_tab, map_opts)
    vim.keymap.set("n", "H", switch_tab, map_opts)
    -- Also allow arrow keys if on header? Or just global tab switch
    vim.keymap.set("n", "<Right>", switch_tab, map_opts)
    vim.keymap.set("n", "<Left>", switch_tab, map_opts)

    -- Initial draw
    redraw()

    -- Start cursor at current theme if visible, else top of list
    local found = false
    if current_name then
        for i, entry in ipairs(state.current_filtered) do
            if entry.name == current_name then
                vim.api.nvim_win_set_cursor(win, { i + 4, 0 })
                found = true
                break
            end
        end
    end
    if not found then
        vim.api.nvim_win_set_cursor(win, { 5, 0 })
    end
end

vim.api.nvim_create_user_command("Theme", open_theme_picker, {})

return {
    open = open_theme_picker,
}