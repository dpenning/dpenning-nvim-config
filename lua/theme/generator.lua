local M = {}
local utils = require("theme.utils")

function M.setup(config)
    config = config or {}
    local base_color = config.base or "#1e1e2e" -- Default dark
    local highlight_color = config.highlight or "#89b4fa" -- Default blueish

    -- 1. Generate Palette
    local colors = {}

    -- Backgrounds
    colors.bg = base_color
    colors.bg_dark = utils.adjust_lightness(base_color, -0.05)
    colors.bg_darker = utils.adjust_lightness(base_color, -0.10)
    colors.bg_light = utils.adjust_lightness(base_color, 0.05)
    colors.bg_lighter = utils.adjust_lightness(base_color, 0.10)
    colors.bg_highlight = utils.mix(base_color, highlight_color, 0.15) -- Selection background

    -- Foregrounds (Text)
    -- We assume a dark theme for now, so we lighten the base color heavily for text
    colors.fg = utils.adjust_lightness(base_color, 0.80)
    colors.fg_dim = utils.adjust_lightness(base_color, 0.50)
    colors.fg_dark = utils.adjust_lightness(base_color, 0.30) -- Comments, ignored text

    -- Accents
    colors.accent = highlight_color
    colors.accent_dim = utils.mix(base_color, highlight_color, 0.40) -- Fainter accent

    -- Semantic Colors (Blended with Highlight)
    -- We take standard "idea" colors for these meanings and tint them towards the highlight color
    local mix_amount = 0.25 
    colors.error = utils.mix("#e06c75", highlight_color, mix_amount)
    colors.warning = utils.mix("#e5c07b", highlight_color, mix_amount)
    colors.info = utils.mix("#61afef", highlight_color, mix_amount)
    colors.hint = utils.mix("#56b6c2", highlight_color, mix_amount)
    colors.success = utils.mix("#98c379", highlight_color, mix_amount)

    -- 2. Define Highlight Groups
    local groups = {
        -- Base
        Normal = { fg = colors.fg, bg = colors.bg },
        NormalFloat = { fg = colors.fg, bg = colors.bg_dark },
        FloatBorder = { fg = colors.accent_dim, bg = colors.bg_dark },
        NonText = { fg = colors.fg_dark },
        Comment = { fg = colors.fg_dim, italic = true },
        Constant = { fg = colors.info },
        String = { fg = colors.success },
        Character = { fg = colors.success },
        Number = { fg = colors.warning },
        Boolean = { fg = colors.warning },
        Float = { fg = colors.warning },
        Identifier = { fg = colors.fg },
        Function = { fg = colors.accent, bold = true },
        Statement = { fg = colors.accent },
        Conditional = { fg = colors.accent },
        Repeat = { fg = colors.accent },
        Label = { fg = colors.accent },
        Operator = { fg = colors.fg_dim },
        Keyword = { fg = colors.accent, italic = true },
        Exception = { fg = colors.error },
        PreProc = { fg = colors.hint },
        Type = { fg = colors.info },
        Structure = { fg = colors.info },
        Special = { fg = colors.hint },
        SpecialChar = { fg = colors.hint },
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
    }

    -- 3. Apply Highlights
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end
    vim.g.colors_name = "generated_theme"

    for group, settings in pairs(groups) do
        vim.api.nvim_set_hl(0, group, settings)
    end
end

return M
