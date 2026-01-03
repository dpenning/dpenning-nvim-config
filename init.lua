require("config.leader")
require("plugins.lazy")
require("config.keymaps")
require("config.shell")
require("commands.smart_quit")
require("commands.explorer_touch")
require("commands.reload")
require("theme.midnight_blue")

if vim.g.neovide then
	require("config.neovide")
	require("commands.snap_window")
end
