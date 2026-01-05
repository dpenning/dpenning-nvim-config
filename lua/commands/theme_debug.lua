local theme = require("theme")
local generator = require("theme.generator")
local constants = require("theme.constants")

local block = function(text)
    return string.format("████ %s ████", text)
end

local COLOR_SWATCH = "██████"
local palette_sources = {}

local function map_palette_source(label, groups)
    for _, group in ipairs(groups) do
        palette_sources[group] = label
    end
end

local function map_gradient_source(name, step, groups)
    local label = string.format("gradient:%s[%d]", name, step)
    map_palette_source(label, groups)
end

local function normalize_hex(color)
    if type(color) ~= "string" then
        return nil
    end
    if not color:match("^#%x%x%x%x%x%x$") then
        return nil
    end
    return color:lower()
end

local function get_swatch_highlight(color)
    local normalized = normalize_hex(color)
    if not normalized then
        return nil
    end
    local group_name = "ThemeDebugSwatch_" .. normalized:sub(2)
    vim.api.nvim_set_hl(0, group_name, { fg = normalized })
    return group_name
end

local indent_entries = {}
for index, name in ipairs(constants.indent_highlights) do
    table.insert(indent_entries, {
        label = string.format("Indent guide %d", index),
        group = name,
        sample = block(string.format("Guide %d", index)),
    })
    palette_sources[name] = string.format("indent_%d", index)
end

local sections = {
    {
        title = "Editor",
        description = "Core syntax, UI, and diagnostics derived from the active palette.",
        groups = {
            {
                title = "Syntax & Text",
                entries = {
                    { label = "Normal text", group = "Normal", sample = block("Normal") },
                    { label = "Comments", group = "Comment", sample = block("Comment") },
                    { label = "Constants", group = "Constant", sample = block("Constant") },
                    { label = "Strings", group = "String", sample = block("String") },
                    { label = "Characters", group = "Character", sample = block("Character") },
                    { label = "Numbers", group = "Number", sample = block("Number") },
                    { label = "Booleans", group = "Boolean", sample = block("Boolean") },
                    { label = "Floats", group = "Float", sample = block("Float") },
                    { label = "Identifiers", group = "Identifier", sample = block("Identifier") },
                    { label = "Functions", group = "Function", sample = block("Function") },
                    { label = "Statements", group = "Statement", sample = block("Statement") },
                    { label = "Conditionals", group = "Conditional", sample = block("Conditional") },
                    { label = "Loops", group = "Repeat", sample = block("Repeat") },
                    { label = "Labels", group = "Label", sample = block("Label") },
                    { label = "Operators", group = "Operator", sample = block("Operator") },
                    { label = "Keywords", group = "Keyword", sample = block("Keyword") },
                    { label = "Exceptions", group = "Exception", sample = block("Exception") },
                    { label = "Preprocessor", group = "PreProc", sample = block("PreProc") },
                    { label = "Types", group = "Type", sample = block("Type") },
                    { label = "Structures", group = "Structure", sample = block("Structure") },
                    { label = "Special text", group = "Special", sample = block("Special") },
                    { label = "Special chars", group = "SpecialChar", sample = block("SpecialChar") },
                    { label = "Underlined", group = "Underlined", sample = block("Underlined") },
                    { label = "Errors", group = "Error", sample = block("Error") },
                    { label = "TODO", group = "Todo", sample = block("Todo") },
                },
            },
            {
                title = "UI & Layout",
                entries = {
                    { label = "Floating text", group = "NormalFloat", sample = block("NormalFloat") },
                    { label = "Float border", group = "FloatBorder", sample = block("FloatBorder") },
                    { label = "Dimmed text", group = "NonText", sample = block("NonText") },
                    { label = "Cursor", group = "Cursor", sample = block("Cursor") },
                    { label = "Cursor line", group = "CursorLine", sample = block("CursorLine") },
                    { label = "Cursor line nr", group = "CursorLineNr", sample = block("CursorLineNr") },
                    { label = "Line numbers", group = "LineNr", sample = block("LineNr") },
                    { label = "Sign column", group = "SignColumn", sample = block("SignColumn") },
                    { label = "Status line", group = "StatusLine", sample = block("StatusLine") },
                    { label = "Status line NC", group = "StatusLineNC", sample = block("StatusLineNC") },
                    { label = "Vert split", group = "VertSplit", sample = block("VertSplit") },
                    { label = "Win separator", group = "WinSeparator", sample = block("WinSeparator") },
                    { label = "Tab line", group = "TabLine", sample = block("TabLine") },
                    { label = "Tab filler", group = "TabLineFill", sample = block("TabLineFill") },
                    { label = "Selected tab", group = "TabLineSel", sample = block("TabLineSel") },
                    { label = "Title / Accent", group = "Title", sample = block("Title") },
                    { label = "Visual select", group = "Visual", sample = block("Visual") },
                    { label = "Search", group = "Search", sample = block("Search") },
                    { label = "Inc Search", group = "IncSearch", sample = block("IncSearch") },
                    { label = "Match Paren", group = "MatchParen", sample = block("MatchParen") },
                    { label = "Popup menu", group = "Pmenu", sample = block("Pmenu") },
                    { label = "Popup selected", group = "PmenuSel", sample = block("PmenuSel") },
                    { label = "Popup scrollbar", group = "PmenuSbar", sample = block("PmenuSbar") },
                    { label = "Popup thumb", group = "PmenuThumb", sample = block("PmenuThumb") },
                    { label = "Question / prompts", group = "Question", sample = block("Question") },
                },
            },
            {
                title = "Diagnostics & Diff",
                entries = {
                    { label = "Diagnostic Error", group = "DiagnosticError", sample = block("Diag Error") },
                    { label = "Diagnostic Warn", group = "DiagnosticWarn", sample = block("Diag Warn") },
                    { label = "Diagnostic Info", group = "DiagnosticInfo", sample = block("Diag Info") },
                    { label = "Diagnostic Hint", group = "DiagnosticHint", sample = block("Diag Hint") },
                    { label = "Underline Error", group = "DiagnosticUnderlineError", sample = block("Underline Err") },
                    { label = "Underline Warn", group = "DiagnosticUnderlineWarn", sample = block("Underline Warn") },
                    { label = "Underline Info", group = "DiagnosticUnderlineInfo", sample = block("Underline Info") },
                    { label = "Underline Hint", group = "DiagnosticUnderlineHint", sample = block("Underline Hint") },
                    { label = "Diff Added", group = "DiffAdd", sample = block("Diff Add") },
                    { label = "Diff Changed", group = "DiffChange", sample = block("Diff Change") },
                    { label = "Diff Deleted", group = "DiffDelete", sample = block("Diff Delete") },
                },
            },
        },
    },
    {
        title = "Explorer",
        description = "Common highlight groups used by file explorers (NvimTree / Neo-tree).",
        groups = {
            {
                title = "NvimTree",
                entries = {
                    { label = "Explorer normal", group = "NvimTreeNormal", sample = block("NvimTree") },
                    { label = "Explorer normal NC", group = "NvimTreeNormalNC", sample = block("NvimTreeNC") },
                    { label = "Explorer root", group = "NvimTreeRootFolder", sample = block("Root folder") },
                    { label = "Explorer folder", group = "NvimTreeFolderName", sample = block("Folder") },
                    { label = "Explorer folder open", group = "NvimTreeOpenedFolderName", sample = block("Open folder") },
                    { label = "Explorer exec file", group = "NvimTreeExecFile", sample = block("Exec file") },
                    { label = "Explorer special file", group = "NvimTreeSpecialFile", sample = block("Special file") },
                    { label = "Explorer image", group = "NvimTreeImageFile", sample = block("Image file") },
                    { label = "Explorer symlink", group = "NvimTreeSymlink", sample = block("Symlink") },
                    { label = "Explorer indent", group = "NvimTreeIndentMarker", sample = block("Indent") },
                    { label = "Explorer sign column", group = "NvimTreeSignColumn", sample = block("Sign column") },
                    { label = "Explorer separator", group = "NvimTreeWinSeparator", sample = block("Separator") },
                    { label = "Explorer git dirty", group = "NvimTreeGitDirty", sample = block("Git dirty") },
                    { label = "Explorer git new", group = "NvimTreeGitNew", sample = block("Git new") },
                    { label = "Explorer git deleted", group = "NvimTreeGitDeleted", sample = block("Git deleted") },
                },
            },
            {
                title = "Neo-tree",
                entries = {
                    { label = "Neo-tree normal", group = "NeoTreeNormal", sample = block("NeoTree") },
                    { label = "Neo-tree normal NC", group = "NeoTreeNormalNC", sample = block("NeoTreeNC") },
                    { label = "Neo-tree border", group = "NeoTreeFloatBorder", sample = block("Float border") },
                    { label = "Neo-tree icon", group = "NeoTreeDirectoryIcon", sample = block("Dir icon") },
                    { label = "Neo-tree directory", group = "NeoTreeDirectoryName", sample = block("Dir name") },
                    { label = "Neo-tree root", group = "NeoTreeRootName", sample = block("Root") },
                    { label = "Neo-tree git added", group = "NeoTreeGitAdded", sample = block("Git added") },
                    { label = "Neo-tree git deleted", group = "NeoTreeGitDeleted", sample = block("Git deleted") },
                    { label = "Neo-tree git modified", group = "NeoTreeGitModified", sample = block("Git modified") },
                    { label = "Neo-tree git conflict", group = "NeoTreeGitConflict", sample = block("Git conflict") },
                },
            },
        },
    },
    {
        title = "Plugins",
        description = "Plugin-specific groups derived from theme colors.",
        groups = {
            {
                title = "Indent Guides",
                description = "Rainbow columns rendered by indent-blankline.",
                entries = indent_entries,
            },
            {
                title = "Version Control",
                entries = {
                    { label = "GitSigns add", group = "GitSignsAdd", sample = block("Git add") },
                    { label = "GitSigns change", group = "GitSignsChange", sample = block("Git change") },
                    { label = "GitSigns delete", group = "GitSignsDelete", sample = block("Git delete") },
                },
            },
            {
                title = "Treesitter",
                entries = {
                    { label = "@variable", group = "@variable", sample = block("@variable") },
                    { label = "@property", group = "@property", sample = block("@property") },
                    { label = "@function.builtin", group = "@function.builtin", sample = block("@function.builtin") },
                    { label = "@constructor", group = "@constructor", sample = block("@constructor") },
                    { label = "@keyword.function", group = "@keyword.function", sample = block("@keyword.func") },
                },
            },
        },
    },
}

map_gradient_source("background_to_foreground", 7, { "Normal" })
map_gradient_source("background_to_foreground", 2, { "Comment" })
map_gradient_source("background_to_foreground", 6, { "NonText" })
map_gradient_source("background_to_foreground", 4, { "Operator" })
map_gradient_source("background_to_accent", 3, { "Constant" })
map_gradient_source("background_to_highlight", 6, { "String" })
map_gradient_source("background_to_highlight", 3, { "Character" })
map_gradient_source("background_to_accent", 5, { "Number" })
map_gradient_source("background_to_accent", 6, { "Boolean" })
map_gradient_source("background_to_accent", 7, { "Float" })
map_gradient_source("foreground_to_highlight", 6, { "Identifier" })
map_gradient_source("foreground_to_accent", 7, { "Function" })
map_gradient_source("foreground_to_accent", 6, { "Statement" })
map_gradient_source("foreground_to_accent", 5, { "Conditional" })
map_gradient_source("highlight_to_accent", 5, { "Repeat" })
map_gradient_source("foreground_to_highlight", 4, { "Label" })
map_gradient_source("highlight_to_accent", 4, { "Keyword" })
map_gradient_source("highlight_to_accent", 6, { "Exception" })
map_gradient_source("foreground_to_highlight", 7, { "PreProc" })
map_gradient_source("foreground_to_highlight", 5, { "Type" })
map_gradient_source("background_to_highlight", 5, { "Structure" })
map_gradient_source("foreground_to_highlight", 3, { "Special" })
map_gradient_source("foreground_to_highlight", 2, { "SpecialChar" })
map_palette_source(
    "success",
    { "NvimTreeExecFile", "GitSignsAdd", "NeoTreeGitAdded", "NvimTreeGitNew" }
)
map_palette_source(
    "info",
    { "Question", "NvimTreeImageFile", "GitSignsChange", "DiagnosticInfo" }
)
map_palette_source(
    "warning",
    { "Todo", "Search", "IncSearch", "NvimTreeSpecialFile", "NvimTreeGitDirty", "NeoTreeGitModified", "DiagnosticWarn" }
)
map_palette_source("fg", { "@variable", "@property" })
map_palette_source(
    "accent",
    {
        "Title",
        "CursorLineNr",
        "MatchParen",
        "NeoTreeDirectoryIcon",
        "NeoTreeDirectoryName",
        "NeoTreeRootName",
        "NvimTreeRootFolder",
        "NvimTreeFolderName",
        "@constructor",
        "@keyword.function",
    }
)
map_palette_source(
    "error",
    {
        "Error",
        "GitSignsDelete",
        "NvimTreeGitDeleted",
        "NeoTreeGitDeleted",
        "NeoTreeGitConflict",
        "DiagnosticError",
    }
)
map_palette_source("hint", { "NvimTreeSymlink", "DiagnosticHint" })
map_palette_source("accent_dim", { "NvimTreeOpenedFolderName", "@function.builtin" })
map_palette_source("fg/bg_dark", { "NormalFloat", "Pmenu", "NvimTreeNormal", "NeoTreeNormal" })
map_palette_source("accent_dim/bg_dark", { "FloatBorder", "NeoTreeFloatBorder" })
map_palette_source("fg_dark", { "LineNr" })
map_palette_source("fg_dim", { "PmenuThumb" })
palette_sources["Cursor"] = "reverse"
map_palette_source("bg_light", { "CursorLine", "NvimTreeIndentMarker" })
map_palette_source("bg", { "SignColumn" })
map_palette_source("fg/bg_darker", { "StatusLine" })
map_palette_source("fg_dim/bg_dark", { "StatusLineNC", "TabLine", "NvimTreeNormalNC", "NeoTreeNormalNC" })
map_palette_source("bg_darker/bg", { "VertSplit", "WinSeparator" })
map_palette_source("bg_darker/bg_dark", { "NvimTreeWinSeparator" })
map_palette_source("bg_darker", { "TabLineFill", "PmenuSbar" })
map_palette_source("bg/accent", { "TabLineSel", "PmenuSel" })
map_palette_source("bg_highlight", { "Visual" })
map_palette_source("bg_dark", { "NvimTreeSignColumn" })
map_palette_source("warning underline", { "DiagnosticUnderlineWarn" })
map_palette_source("error underline", { "DiagnosticUnderlineError" })
map_palette_source("info underline", { "DiagnosticUnderlineInfo" })
map_palette_source("hint underline", { "DiagnosticUnderlineHint" })
map_palette_source("success/bg_dark", { "DiffAdd" })
map_palette_source("info/bg_dark", { "DiffChange" })
map_palette_source("error/bg_dark", { "DiffDelete" })
palette_sources["Underlined"] = "style only"

local function highlight_exists(name)
    return vim.fn.hlexists(name) == 1
end

local function compute_max_label()
    local max_label = 0
    for _, section in ipairs(sections) do
        for _, group in ipairs(section.groups or {}) do
            for _, entry in ipairs(group.entries or {}) do
                max_label = math.max(max_label, #entry.label)
            end
        end
    end
    return max_label
end

local function add_line(lines, text)
    table.insert(lines, text)
end

local function entry_sample_text(entry)
    local palette_label = palette_sources[entry.group]
    if palette_label then
        return block(palette_label)
    end
    return entry.sample or block(entry.label)
end

local function add_line_with_swatch(lines, highlights, text, group)
    if not group then
        add_line(lines, text)
        return
    end

    add_line(lines, text)
    local row = #lines - 1
    local start_byte = select(1, text:find(COLOR_SWATCH, 1, true))
    if not start_byte then
        return
    end
    table.insert(highlights, {
        row = row,
        start_col = start_byte - 1,
        end_col = start_byte - 1 + #COLOR_SWATCH,
        group = group,
    })
end

local function build_theme_info_lines()
    local lines = {}
    local highlights = {}
    local current_name = theme.current_name()
    local preset = current_name and theme.get(current_name) or nil
    local palette = generator.palette()
    local last_config = theme.last_config() or {}

    local theme_label
    if preset and preset.label then
        theme_label = string.format("%s (%s)", preset.label, preset.name)
    elseif current_name then
        theme_label = current_name
    else
        theme_label = "None (theme not loaded)"
    end

    add_line(lines, "Theme Information")
    add_line(lines, string.rep("-", 17))
    add_line(lines, string.format("Active theme : %s", theme_label))

    if preset and preset.description then
        add_line(lines, string.format("Description  : %s", preset.description))
    end

    if current_name and not preset then
        add_line(lines, string.format("Identifier   : %s", current_name))
    end

    local color_entries = {
        { label = "Foreground", config_key = "foreground", palette_key = "input_foreground" },
        { label = "Background", config_key = "background", palette_key = "input_background" },
        { label = "Highlight", config_key = "highlight", palette_key = "input_highlight" },
        { label = "Accent", config_key = "accent", palette_key = "input_accent" },
    }

    local label_padding = 12
    for _, entry in ipairs(color_entries) do
        local value = last_config[entry.config_key] or (palette and palette[entry.palette_key])
        if value then
            local swatch_group = get_swatch_highlight(value)
            local line = string.format("%-" .. label_padding .. "s : %s", entry.label, value)
            if swatch_group then
                line = string.format("%s  %s", line, COLOR_SWATCH)
                add_line_with_swatch(lines, highlights, line, swatch_group)
            else
                add_line(lines, line)
            end
        end
    end

    if palette then
        add_line(lines, "")
        add_line(lines, "Palette")
        add_line(lines, string.rep("-", 7))

        local palette_keys = {
            "input_foreground",
            "input_background",
            "input_highlight",
            "input_accent",
            "bg",
            "bg_dark",
            "bg_darker",
            "bg_light",
            "bg_lighter",
            "bg_highlight",
            "fg",
            "fg_dim",
            "fg_dark",
            "accent",
            "accent_dim",
            "error",
            "warning",
            "info",
            "hint",
            "success",
        }

        local max_key = 0
        for _, key in ipairs(palette_keys) do
            if palette[key] then
                max_key = math.max(max_key, #key)
            end
        end
        max_key = math.max(max_key, 1)
        local format_str = "%-" .. max_key .. "s : %s"
        local format_str_with_swatch = format_str .. "  %s"

        for _, key in ipairs(palette_keys) do
            local value = palette[key]
            if value then
                local group = get_swatch_highlight(value)
                if group then
                    local line = string.format(format_str_with_swatch, key, value, COLOR_SWATCH)
                    add_line_with_swatch(lines, highlights, line, group)
                else
                    add_line(lines, string.format(format_str, key, value))
                end
            end
        end

        if palette.gradients then
            add_line(lines, "")
            add_line(lines, "Gradients")
            add_line(lines, string.rep("-", 9))
            for name, gradient in pairs(palette.gradients) do
                local header = string.format("%s:", name)
                add_line(lines, header)
                if type(gradient) == "table" and #gradient > 0 then
                    for index, hex in ipairs(gradient) do
                        local label = string.format("  Step %d", index)
                        local swatch_group = get_swatch_highlight(hex)
                        local line = string.format("%-8s : %s", label, hex)
                        if swatch_group then
                            line = string.format("%s  %s", line, COLOR_SWATCH)
                            add_line_with_swatch(lines, highlights, line, swatch_group)
                        else
                            add_line(lines, line)
                        end
                    end
                else
                    add_line(lines, "  (no data)")
                end
                add_line(lines, "")
            end
            if lines[#lines] == "" then
                lines[#lines] = nil
            end
        end
    end

    return lines, highlights
end

local function build_lines()
    local max_label = compute_max_label()

    local lines = {}
    local highlights = {}

    local info_lines, info_highlights = build_theme_info_lines()
    local current_line_count = #lines
    for _, info_line in ipairs(info_lines) do
        add_line(lines, info_line)
    end
    for _, region in ipairs(info_highlights) do
        table.insert(highlights, {
            row = region.row + current_line_count,
            start_col = region.start_col,
            end_col = region.end_col,
            group = region.group,
        })
    end

    if #lines > 0 then
        add_line(lines, "")
    end

    add_line(lines, "Theme Debug Overview")
    add_line(lines, string.rep("=", 22))
    add_line(lines, "")
    add_line(lines, "Sections: Editor, Explorer, and Plugins.")
    add_line(lines, "Left column shows the semantic role.")
    add_line(lines, "Right column previews the highlight colors.")
    add_line(lines, "")

    for _, section in ipairs(sections) do
        add_line(lines, section.title)
        add_line(lines, string.rep("-", #section.title))
        if section.description then
            add_line(lines, section.description)
        end
        add_line(lines, "")

        for group_index, group in ipairs(section.groups or {}) do
            if group.title and group.title ~= "" then
                add_line(lines, group.title)
                add_line(lines, string.rep("~", #group.title))
            end
            if group.description then
                add_line(lines, group.description)
            end

            for _, entry in ipairs(group.entries or {}) do
                local padded_label = string.format("%-" .. max_label .. "s", entry.label)
                local sample = entry_sample_text(entry)
                local line = string.format("%s | %s", padded_label, sample)
                add_line(lines, line)

                local row = #lines - 1
                local start_col = #padded_label + 3
                local end_col = start_col + #sample

                table.insert(highlights, {
                    row = row,
                    start_col = start_col,
                    end_col = end_col,
                    group = entry.group,
                })
            end

            if group_index < #section.groups then
                add_line(lines, "")
            end
        end

        add_line(lines, "")
    end

    if lines[#lines] == "" then
        lines[#lines] = nil
    end

    return lines, highlights
end

local function create_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    vim.api.nvim_set_option_value("filetype", "theme-debug", { buf = buf })
    return buf
end

local function populate_buffer(buf)
    local lines, highlights = build_lines()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    for _, region in ipairs(highlights) do
        local group = highlight_exists(region.group) and region.group or "Normal"
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            group,
            region.row,
            region.start_col,
            region.end_col
        )
    end

    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function open_window(buf)
    vim.cmd("tabnew")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_option_value("wrap", false, { win = win })
    vim.api.nvim_set_option_value("number", false, { win = win })
    vim.api.nvim_set_option_value("relativenumber", false, { win = win })
end

vim.api.nvim_create_user_command("ThemeDebug", function()
    local buf = create_buffer()
    populate_buffer(buf)
    open_window(buf)
end, {})
