-- Load all config modules in the correct order
require("config.leader")
require("config.lazy")
require("config.keymaps")
require("config.shell")
require("config.editor")

if vim.g.neovide then
	require("config.neovide")
end
