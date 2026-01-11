local M = {}
local term_split = require("commands.terminal_split")

function M.fix_layout()
	-- 1. Determine the buffer to keep in the center
	local current_buf = vim.api.nvim_get_current_buf()
	local current_ft = vim.bo[current_buf].filetype

	local target_buf = current_buf

	-- If current buffer is a "tool" buffer, try to find a real file buffer
	if current_ft == "neo-tree" or current_ft == "terminal" or current_ft == "qf" then
		local found_real_buf = false
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			-- Simple heuristic for "real" file: not special ft
			if ft ~= "neo-tree" and ft ~= "terminal" and ft ~= "qf" then
				target_buf = buf
				found_real_buf = true
				break
			end
		end

		if not found_real_buf then
			-- No real buffer found, create a new one
			target_buf = vim.api.nvim_create_buf(true, false)
		end
	end

	-- 2. Reset layout
	-- We want to ensure we are in a window that will become the center
	-- If we are in neotree, we switch buffer, then `only`
	vim.api.nvim_set_current_buf(target_buf)
	vim.cmd("only")

	-- 3. Open Neo-tree (Left, 40)
	vim.cmd("Neotree show left")
	-- Resize Neo-tree. It should be the current window or easily findable.
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "neo-tree" then
			vim.api.nvim_win_set_width(win, 40)
		end
	end

	-- 4. Focus the center window again
	-- The center window is the one displaying `target_buf` (or at least NOT neo-tree)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype ~= "neo-tree" then
			vim.api.nvim_set_current_win(win)
			break
		end
	end

	-- 5. Open Terminal (Right, 80)
	term_split.open_terminal_80()
end

vim.api.nvim_create_user_command("Fix", M.fix_layout, {})

return M
