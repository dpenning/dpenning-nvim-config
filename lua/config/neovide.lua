vim.g.neovide_opacity = 1.0
vim.g.neovide_frame = "none"
vim.g.neovide_window_blurred = false
vim.g.neovide_scale_factor = vim.g.neovide_scale_factor or 1.0

local function change_scale(delta)
  -- Keep a sane minimum scale factor so text never becomes invisible
  local new_scale = math.max(0.3, (vim.g.neovide_scale_factor or 1.0) + delta)
  vim.g.neovide_scale_factor = new_scale
end

---------------------------------
-- Keymapping specific to neovide
---------------------------------

-- Resizing the font similar support from other editors.
vim.keymap.set({ "n", "i", "v" }, "<C-=>", function()
  change_scale(0.1)
end, { desc = "Increase Neovide font size" })

vim.keymap.set({ "n", "i", "v" }, "<C-->", function()
  change_scale(-0.1)
end, { desc = "Decrease Neovide font size" })

------------------
-- Startup Effects
------------------

-- On mac the process for Neovide starts in the background.
-- To pull it to the front applescript is used.
vim.api.nvim_create_autocmd("UIEnter", {
  once = true, -- Ensure this only runs once on startup
  callback = function()
    vim.cmd("silent !osascript -e 'tell application \"System Events\" to set frontmost of processes whose name contains \"neovide\" to true'")
  end,
})
