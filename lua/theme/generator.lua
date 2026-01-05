local M = {
	_last_palette = nil,
}
local constants = require("theme.constants")
local utils = require("theme.utils")

local GRADIENT_STEPS = 8

local function refresh_indent_highlights()
	local ok, highlights = pcall(require, "ibl.highlights")
	if not ok or type(highlights.setup) ~= "function" then
		return
	end
	pcall(highlights.setup)
end

function M.setup(config)
    config = config or {}
    local foreground_color = config.foreground or "#cdd6f4"
    local background_color = config.background or "#1e1e2e"
    local highlight_color = config.highlight or "#f5e0dc"
    local accent_color = config.accent or "#89b4fa"

    local function build_gradient(color_a, color_b)
        local gradient = {}
        for step = 0, GRADIENT_STEPS - 1 do
            local amount = (step + 1) / (GRADIENT_STEPS + 1)
            gradient[step + 1] = utils.mix(color_a, color_b, amount)
        end
        return gradient
    end

    local function mix_with_background(target, amount)
        return utils.mix(background_color, target, amount)
    end

    -- 1. Generate Palette
    local colors = {}

    local gradients = {
        background_to_foreground = build_gradient(background_color, foreground_color),
        background_to_highlight = build_gradient(background_color, highlight_color),
        background_to_accent = build_gradient(background_color, accent_color),
        foreground_to_highlight = build_gradient(foreground_color, highlight_color),
        foreground_to_accent = build_gradient(foreground_color, accent_color),
        highlight_to_accent = build_gradient(highlight_color, accent_color),
    }

    local function sample_gradient(gradient, amount)
        if not gradient or #gradient == 0 then
            return nil
        end
        local steps = #gradient
        local index = math.floor(amount * (steps - 1) + 1.5)
        index = math.max(1, math.min(steps, index))
        return gradient[index]
    end

    local function gradient_step_value(gradient, step)
        if not gradient or #gradient == 0 then
            return nil
        end
        local index = math.max(1, math.min(#gradient, step))
        return gradient[index]
    end

    local function gradient_color(gradient_name, step, fallback)
        local gradient = gradients[gradient_name]
        if not gradient then
            return fallback
        end
        local steps = #gradient
        if steps < 3 then
            return gradient_step_value(gradient, step) or fallback
        end
        local min_step = 2
        local max_step = steps - 1
        local clamped = math.max(min_step, math.min(max_step, step))
        return gradient_step_value(gradient, clamped) or fallback
    end

    colors.gradients = gradients

    -- Preserve original inputs for tooling like ThemeDebug
    colors.input_foreground = foreground_color
    colors.input_background = background_color
    colors.input_highlight = highlight_color
    colors.input_accent = accent_color

    -- Backgrounds derived from gradients
    local bg_gradient = gradients.background_to_foreground
    colors.bg = background_color
    colors.bg_dark = utils.adjust_lightness(background_color, -0.05)
    colors.bg_darker = utils.adjust_lightness(background_color, -0.10)
    colors.bg_light = utils.adjust_lightness(background_color, 0.05)
    colors.bg_lighter = utils.adjust_lightness(background_color, 0.10)
    colors.bg_highlight = mix_with_background(highlight_color, 0.35) -- Selection background

    -- Foregrounds (Text) from gradients
    local fg_gradient = gradients.background_to_foreground
    colors.fg = sample_gradient(fg_gradient, 1) or mix_with_background(foreground_color, 0.9)
    colors.fg_dim = sample_gradient(fg_gradient, 0.75) or mix_with_background(foreground_color, 0.65)
    colors.fg_dark = sample_gradient(fg_gradient, 0.5) or mix_with_background(foreground_color, 0.45)

    -- Accents derived from background -> accent gradients
    local accent_gradient = gradients.background_to_accent
    colors.accent = sample_gradient(accent_gradient, 1) or mix_with_background(accent_color, 0.85)
    colors.accent_dim = sample_gradient(accent_gradient, 0.7) or mix_with_background(accent_color, 0.55)

    -- Semantic Colors (tint canonical hues, then blend with background)
    local function semantic_color(hex)
        local tinted = utils.mix(hex, accent_color, 0.35)
        local blend_target = sample_gradient(gradients.background_to_highlight, 0.85) or background_color
        return utils.mix(blend_target, tinted, 0.85)
    end

    colors.error = semantic_color("#e06c75")
    colors.warning = semantic_color("#e5c07b")
    colors.info = semantic_color("#61afef")
    colors.hint = semantic_color("#56b6c2")
    colors.success = semantic_color("#98c379")

    -- Indent guides gradually mix towards the highlight color
    colors.indent_levels = {}
    local indent_mix_start = 0.35
    local indent_mix_step = 0.12
    local highlight_gradient = gradients.background_to_highlight
    for index, _ in ipairs(constants.indent_highlights) do
        local amount = math.min(indent_mix_start + (index - 1) * indent_mix_step, 0.95)
        colors.indent_levels[index] = sample_gradient(highlight_gradient, amount)
            or mix_with_background(highlight_color, amount)
    end

    local nontext_color = gradient_color("background_to_foreground", 6, colors.fg_dim)

    local syntax_specs = {
        Normal = { color = colors.fg }, -- Keep Normal tied to the theme foreground
        Comment = { gradient = "background_to_foreground", step = 2, fallback = colors.fg_dim },
        Constant = { gradient = "background_to_accent", step = 3, fallback = colors.info },
        String = { gradient = "background_to_highlight", step = 6, fallback = colors.success },
        Character = { gradient = "background_to_highlight", step = 3, fallback = colors.success },
        Number = { gradient = "background_to_accent", step = 5, fallback = colors.warning },
        Boolean = { gradient = "background_to_accent", step = 6, fallback = colors.warning },
        Float = { gradient = "background_to_accent", step = 7, fallback = colors.warning },
        Identifier = { gradient = "foreground_to_highlight", step = 6, fallback = colors.fg },
        Function = { gradient = "foreground_to_accent", step = 7, fallback = colors.accent },
        Statement = { gradient = "foreground_to_accent", step = 6, fallback = colors.accent },
        Conditional = { gradient = "foreground_to_accent", step = 5, fallback = colors.accent },
        Repeat = { gradient = "highlight_to_accent", step = 5, fallback = colors.accent },
        Label = { gradient = "foreground_to_highlight", step = 4, fallback = colors.accent },
        Operator = { gradient = "background_to_foreground", step = 4, fallback = colors.fg_dim },
        Keyword = { gradient = "highlight_to_accent", step = 4, fallback = colors.accent_dim },
        Exception = { gradient = "highlight_to_accent", step = 6, fallback = colors.error },
        PreProc = { gradient = "foreground_to_highlight", step = 7, fallback = colors.hint },
        Type = { gradient = "foreground_to_highlight", step = 5, fallback = colors.info },
        Structure = { gradient = "background_to_highlight", step = 5, fallback = colors.info },
        Special = { gradient = "foreground_to_highlight", step = 3, fallback = colors.hint },
        SpecialChar = { gradient = "foreground_to_highlight", step = 2, fallback = colors.hint },
    }

    local syntax_colors = {}
    for group, spec in pairs(syntax_specs) do
        if spec.color then
            syntax_colors[group] = spec.color
        else
            syntax_colors[group] = gradient_color(spec.gradient, spec.step, spec.fallback)
        end
    end

    -- 2. Define Highlight Groups
    local groups = {
        -- Base
        Normal = { fg = syntax_colors.Normal, bg = colors.bg },
        NormalFloat = { fg = colors.fg, bg = colors.bg_dark },
        FloatBorder = { fg = colors.accent_dim, bg = colors.bg_dark },
        NonText = { fg = nontext_color },
        Comment = { fg = syntax_colors.Comment, italic = true },
        Constant = { fg = syntax_colors.Constant },
        String = { fg = syntax_colors.String },
        Character = { fg = syntax_colors.Character },
        Number = { fg = syntax_colors.Number },
        Boolean = { fg = syntax_colors.Boolean },
        Float = { fg = syntax_colors.Float },
        Identifier = { fg = syntax_colors.Identifier },
        Function = { fg = syntax_colors.Function, bold = true },
        Statement = { fg = syntax_colors.Statement },
        Conditional = { fg = syntax_colors.Conditional },
        Repeat = { fg = syntax_colors.Repeat },
        Label = { fg = syntax_colors.Label },
        Operator = { fg = syntax_colors.Operator },
        Keyword = { fg = syntax_colors.Keyword, italic = true },
        Exception = { fg = syntax_colors.Exception },
        PreProc = { fg = syntax_colors.PreProc },
        Type = { fg = syntax_colors.Type },
        Structure = { fg = syntax_colors.Structure },
        Special = { fg = syntax_colors.Special },
        SpecialChar = { fg = syntax_colors.SpecialChar },
        Underlined = { underline = true },
        Error = { fg = colors.error },
        Todo = { fg = colors.warning, bold = true },

        -- UI
        Cursor = { reverse = true },
        CursorLine = { bg = colors.bg_light },
        CursorLineNr = { fg = colors.accent, bold = true },
        LineNr = { fg = colors.fg_dark },
        SignColumn = { bg = colors.bg },
        StatusLine = { fg = colors.fg, bg = colors.bg_darker },
        StatusLineNC = { fg = colors.fg_dim, bg = colors.bg_dark },
        VertSplit = { fg = colors.bg_darker, bg = colors.bg },
        WinSeparator = { fg = colors.bg_darker, bg = colors.bg },
        TabLine = { fg = colors.fg_dim, bg = colors.bg_dark },
        TabLineFill = { bg = colors.bg_darker },
        TabLineSel = { fg = colors.bg, bg = colors.accent },
        Title = { fg = colors.accent, bold = true },
        Visual = { bg = colors.bg_highlight },
        Search = { fg = colors.bg, bg = colors.warning },
        IncSearch = { fg = colors.bg, bg = colors.warning },
        MatchParen = { fg = colors.accent, bold = true, underline = true },
        Pmenu = { fg = colors.fg, bg = colors.bg_dark },
        PmenuSel = { fg = colors.bg, bg = colors.accent },
        PmenuSbar = { bg = colors.bg_darker },
        PmenuThumb = { bg = colors.fg_dim },
        Question = { fg = colors.info },

        -- Diagnostics
        DiagnosticError = { fg = colors.error },
        DiagnosticWarn = { fg = colors.warning },
        DiagnosticInfo = { fg = colors.info },
        DiagnosticHint = { fg = colors.hint },
        DiagnosticUnderlineError = { sp = colors.error, underline = true },
        DiagnosticUnderlineWarn = { sp = colors.warning, underline = true },
        DiagnosticUnderlineInfo = { sp = colors.info, underline = true },
        DiagnosticUnderlineHint = { sp = colors.hint, underline = true },

        -- Git / Diff
        DiffAdd = { fg = colors.success, bg = colors.bg_dark },
        DiffChange = { fg = colors.info, bg = colors.bg_dark },
        DiffDelete = { fg = colors.error, bg = colors.bg_dark },
        GitSignsAdd = { fg = colors.success },
        GitSignsChange = { fg = colors.info },
        GitSignsDelete = { fg = colors.error },

        -- Treesitter (Standard links usually work, but here are overrides)
        ["@variable"] = { fg = colors.fg },
        ["@property"] = { fg = colors.fg },
        ["@function.builtin"] = { fg = colors.accent_dim },
        ["@constructor"] = { fg = colors.accent },
        ["@keyword.function"] = { fg = colors.accent, italic = true },

        -- File explorers
        Directory = { fg = colors.accent, bold = true },
        NvimTreeNormal = { fg = colors.fg, bg = colors.bg_dark },
        NvimTreeNormalNC = { fg = colors.fg_dim, bg = colors.bg_dark },
        NvimTreeRootFolder = { fg = colors.accent, bold = true },
        NvimTreeFolderName = { fg = colors.accent },
        NvimTreeOpenedFolderName = { fg = colors.accent_dim },
        NvimTreeExecFile = { fg = colors.success },
        NvimTreeSpecialFile = { fg = colors.warning, italic = true },
        NvimTreeImageFile = { fg = colors.info },
        NvimTreeSymlink = { fg = colors.hint },
        NvimTreeIndentMarker = { fg = colors.bg_light },
        NvimTreeSignColumn = { bg = colors.bg_dark },
        NvimTreeWinSeparator = { fg = colors.bg_darker, bg = colors.bg_dark },
        NvimTreeGitDirty = { fg = colors.warning },
        NvimTreeGitNew = { fg = colors.success },
        NvimTreeGitDeleted = { fg = colors.error },
        NeoTreeNormal = { fg = colors.fg, bg = colors.bg_dark },
        NeoTreeNormalNC = { fg = colors.fg_dim, bg = colors.bg_dark },
        NeoTreeFloatBorder = { fg = colors.accent_dim, bg = colors.bg_dark },
        NeoTreeDirectoryIcon = { fg = colors.accent },
        NeoTreeDirectoryName = { fg = colors.accent },
        NeoTreeRootName = { fg = colors.accent, bold = true },
        NeoTreeGitAdded = { fg = colors.success },
        NeoTreeGitDeleted = { fg = colors.error },
        NeoTreeGitModified = { fg = colors.warning },
        NeoTreeGitConflict = { fg = colors.error, bold = true },

        -- Indent guides (ibl)
        IblIndent = { fg = colors.bg_light },
        IblWhitespace = { fg = colors.bg_dark },
        IblScope = { fg = colors.accent_dim },
    }

    for index, hl_name in ipairs(constants.indent_highlights) do
        local color = colors.indent_levels[index]
        if color then
            groups[hl_name] = { fg = color }
            local indent_char_name = string.format("@ibl.indent.char.%d", index)
            groups[indent_char_name] = { fg = color, nocombine = true }
        end
    end

    -- 3. Apply Highlights
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end
    vim.g.colors_name = "generated_theme"

    for group, settings in pairs(groups) do
        vim.api.nvim_set_hl(0, group, settings)
    end

    refresh_indent_highlights()

    M._last_palette = vim.deepcopy(colors)
end

function M.palette()
    if not M._last_palette then
        return nil
    end
    return vim.deepcopy(M._last_palette)
end

return M
