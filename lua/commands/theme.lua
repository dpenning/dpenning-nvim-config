-- Load theme UI modules
local picker = require("theme.ui.picker")
local creator = require("theme.ui.creator")
local debug = require("theme.ui.debug")

-- Register theme commands
vim.api.nvim_create_user_command("Theme", picker.open, {})
vim.api.nvim_create_user_command("ThemeCreator", creator.open, {})
vim.api.nvim_create_user_command("ThemeDebug", debug.open, {})
