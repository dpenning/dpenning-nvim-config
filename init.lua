require("config.leader")
require("config.lazy")
require("config.keymaps")
require("config.shell")
require("config.editor")
require("commands.explorer_touch")
require("commands.explorer")
require("commands.fix")
require("commands.reload")
require("commands.terminal_split")
require("commands.theme")
require("commands.theme_creator")
require("commands.theme_debug")

if vim.g.neovide then
	require("config.neovide")
	require("commands.snap_window")
end
