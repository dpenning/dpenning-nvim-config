-- Helper function for transparency and blur
vim.g.neovide_opacity = 0.9
vim.g.neovide_window_blurred = true 

vim.api.nvim_create_autocmd("UIEnter", {
  once = true, -- Ensure this only runs once on startup
  callback = function()
    -- We use 'System Events' to find any process named 'neovide' (case insensitive)
    -- and force it to the front. This is more robust than "tell application".
    vim.cmd("silent !osascript -e 'tell application \"System Events\" to set frontmost of processes whose name contains \"neovide\" to true'")
  end,
})

