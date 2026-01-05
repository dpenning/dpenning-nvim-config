local presets = {
    {
        name = "midnight_blue",
        label = "Midnight Blue",
        description = "Deep midnight base with cool sky-blue accents",
        foreground = "#cdd6f4",
        background = "#1a1b26",
        highlight = "#9ab0ff",
        accent = "#7aa2f7",
    },
    {
        name = "ember_glow",
        label = "Ember Glow",
        description = "Warm charcoal background with ember pink highlights",
        foreground = "#f4e0d9",
        background = "#221112",
        highlight = "#f0b7a4",
        accent = "#f38ba8",
    },
    {
        name = "forest_mist",
        label = "Forest Mist",
        description = "Muted evergreen shadows with mint accents",
        foreground = "#d6f4e1",
        background = "#101f17",
        highlight = "#b8f7ce",
        accent = "#a6e3a1",
    },
    {
        name = "aurora_dream",
        label = "Aurora Dream",
        description = "Dusky teal night with soft neon cyan highlights",
        foreground = "#d0f2ff",
        background = "#111a1f",
        highlight = "#a1e9f5",
        accent = "#89dceb",
    },
    {
        name = "solar_dawn",
        label = "Solar Dawn",
        description = "Amber sunrise glow with citrus highlights",
        foreground = "#f4e3c1",
        background = "#1f1a12",
        highlight = "#ffdd99",
        accent = "#f7b267",
    },
    {
        name = "oceanic_depths",
        label = "Oceanic Depths",
        description = "Deep navy sea with turquoise currents",
        foreground = "#c5f0ff",
        background = "#0b1c26",
        highlight = "#5ec4e6",
        accent = "#3aaed8",
    },
    {
        name = "neon_violet",
        label = "Neon Violet",
        description = "Dark club violet with electric lavender",
        foreground = "#efe0ff",
        background = "#181125",
        highlight = "#cfa7ff",
        accent = "#b480ff",
    },
    {
        name = "jade_city",
        label = "Jade City",
        description = "Noir green streets with radiant jade",
        foreground = "#c7fff1",
        background = "#001f1d",
        highlight = "#78f5d2",
        accent = "#35d9a9",
    },
    {
        name = "amber_forest",
        label = "Amber Forest",
        description = "Mossy woods with lantern-hued highlights",
        foreground = "#f2ffd6",
        background = "#1b2214",
        highlight = "#d7f28d",
        accent = "#b4e35c",
    },
    {
        name = "rose_quartz",
        label = "Rose Quartz",
        description = "Velvet plum dusk with rosy accents",
        foreground = "#ffe3ef",
        background = "#26111d",
        highlight = "#f6c3d8",
        accent = "#f08bb7",
    },
    {
        name = "arctic_night",
        label = "Arctic Night",
        description = "Polar midnight with icy azure flares",
        foreground = "#e0f0ff",
        background = "#101725",
        highlight = "#9bd0ff",
        accent = "#6bb1ff",
    },
    {
        name = "copper_rust",
        label = "Copper Rust",
        description = "Oxidized bronze shadows with ember accents",
        foreground = "#f8e0c7",
        background = "#1f1411",
        highlight = "#f2c199",
        accent = "#dd8a5f",
    },
}

local index = {}
for _, preset in ipairs(presets) do
    index[preset.name] = preset
end

local M = {}

function M.list()
    return presets
end

function M.get(name)
    return index[name]
end

return M
