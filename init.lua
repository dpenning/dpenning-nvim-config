require("config.leader")
require("plugins.lazy")
require("config.keymaps")
require("commands.smart_quit")

if vim.g.neovide then
	require("config.neovide")
end
