vim.g.neovide_opacity = 1.0
vim.g.neovide_window_blurred = false
vim.g.neovide_scale_factor = vim.g.neovide_scale_factor or 1.0

local function change_scale(delta)
  -- Keep a sane minimum scale factor so text never becomes invisible
  local new_scale = math.max(0.3, (vim.g.neovide_scale_factor or 1.0) + delta)
  vim.g.neovide_scale_factor = new_scale
end

vim.keymap.set({ "n", "i", "v" }, "<C-=>", function()
  change_scale(0.1)
end, { desc = "Increase Neovide font size" })

vim.keymap.set({ "n", "i", "v" }, "<C-->", function()
  change_scale(-0.1)
end, { desc = "Decrease Neovide font size" })

vim.api.nvim_create_autocmd("UIEnter", {
  once = true, -- Ensure this only runs once on startup
  callback = function()
    -- We use 'System Events' to find any process named 'neovide' (case insensitive)
    -- and force it to the front. This is more robust than "tell application".
    vim.cmd("silent !osascript -e 'tell application \"System Events\" to set frontmost of processes whose name contains \"neovide\" to true'")
  end,
})
