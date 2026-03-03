-- Load all command modules
require("commands.explorer_touch")
require("commands.explorer")
require("commands.fix")
require("commands.git_diff_open")
require("commands.open_chromium_source")
require("commands.reload")
require("commands.smart_quit")
require("commands.switch_source_header")
require("commands.terminal_clear")
require("commands.terminal_split")
require("commands.theme")

if vim.g.neovide then
	require("commands.snap_window")
end
