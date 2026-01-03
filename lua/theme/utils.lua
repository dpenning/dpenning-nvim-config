local M = {}

-- Utility: Clamp value between min and max
local function clamp(val, min, max)
    return math.min(max, math.max(min, val))
end

-- sRGB Gamma Expansion (sRGB to Linear RGB)
local function srgb_to_linear(c)
    c = c / 255
    if c <= 0.04045 then
        return c / 12.92
    else
        return ((c + 0.055) / 1.055) ^ 2.4
    end
end

-- sRGB Gamma Compression (Linear RGB to sRGB)
local function linear_to_srgb(c)
    if c <= 0.0031308 then
        return c * 12.92
    else
        return 1.055 * (c ^ (1.0 / 2.4)) - 0.055
    end
end

-- Hex to RGB
function M.hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

-- RGB to Hex
function M.rgb_to_hex(r, g, b)
    r = clamp(math.floor(r + 0.5), 0, 255)
    g = clamp(math.floor(g + 0.5), 0, 255)
    b = clamp(math.floor(b + 0.5), 0, 255)
    return string.format("#%02x%02x%02x", r, g, b)
end

-- RGB to OKLab
-- Uses the matrices from https://bottosson.github.io/posts/oklab/
function M.rgb_to_oklab(r, g, b)
    local lr = srgb_to_linear(r)
    local lg = srgb_to_linear(g)
    local lb = srgb_to_linear(b)

    local l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb
    local m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb
    local s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb

    local l_ = l ^ (1 / 3)
    local m_ = m ^ (1 / 3)
    local s_ = s ^ (1 / 3)

    return 
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
end

-- OKLab to RGB
function M.oklab_to_rgb(L, a, b)
    local l_ = L + 0.3963377774 * a + 0.2158037573 * b
    local m_ = L - 0.1055613458 * a - 0.0638541728 * b
    local s_ = L - 0.0894841775 * a - 1.2914855480 * b

    local l = l_ ^ 3
    local m = m_ ^ 3
    local s = s_ ^ 3

    local lr = 4.0766066871 * l - 3.3077115913 * m + 0.2309699292 * s
    local lg = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    local lb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    return 
        linear_to_srgb(lr) * 255,
        linear_to_srgb(lg) * 255,
        linear_to_srgb(lb) * 255
end

-- Mix two colors in OKLab space
-- amount: 0.0 (all color1) to 1.0 (all color2)
function M.mix(hex1, hex2, amount)
    local r1, g1, b1 = M.hex_to_rgb(hex1)
    local r2, g2, b2 = M.hex_to_rgb(hex2)

    local L1, a1, b1 = M.rgb_to_oklab(r1, g1, b1)
    local L2, a2, b2 = M.rgb_to_oklab(r2, g2, b2)

    local L = L1 * (1 - amount) + L2 * amount
    local a = a1 * (1 - amount) + a2 * amount
    local b = b1 * (1 - amount) + b2 * amount

    local r, g, bl = M.oklab_to_rgb(L, a, b)
    return M.rgb_to_hex(r, g, bl)
end

-- Adjust lightness in OKLab space
-- amount: positive to lighten, negative to darken (approximate range -1.0 to 1.0)
function M.adjust_lightness(hex, amount)
    local r, g, b = M.hex_to_rgb(hex)
    local L, a, bb = M.rgb_to_oklab(r, g, b)
    
    L = clamp(L + amount, 0, 1)
    
    local r_new, g_new, b_new = M.oklab_to_rgb(L, a, bb)
    return M.rgb_to_hex(r_new, g_new, b_new)
end

return M
