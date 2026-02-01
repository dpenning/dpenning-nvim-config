local M = {}
local term_split = require("commands.terminal_split")

function M.fix_layout()
	-- 1. Determine the buffer to keep in the center
	local current_buf = vim.api.nvim_get_current_buf()
	local current_ft = vim.bo[current_buf].filetype
	local current_bt = vim.bo[current_buf].buftype

	local target_buf = current_buf
	local is_tool = (current_ft == "neo-tree" or current_ft == "qf" or current_bt == "terminal" or current_bt == "nofile")

	-- If current buffer is a "tool" buffer, try to find a real file buffer
	if is_tool then
		local found_real_buf = false
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			local bt = vim.bo[buf].buftype
			-- Simple heuristic for "real" file: not special ft/bt
			if ft ~= "neo-tree" and ft ~= "qf" and bt ~= "terminal" and bt ~= "nofile" then
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
	vim.api.nvim_set_current_buf(target_buf)
	vim.cmd("only")

	-- 3. Open Neo-tree (Left, 40)
	vim.cmd("Neotree show left")
	-- Resize Neo-tree.
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "neo-tree" then
			vim.api.nvim_win_set_width(win, 40)
		end
	end

	-- 4. Identify the center window (the one with the file)
	local center_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype ~= "neo-tree" then
			center_win = win
			break
		end
	end

	-- Focus center before opening terminal (helps split logic usually, though open_terminal_80 uses botright)
	if center_win then
		vim.api.nvim_set_current_win(center_win)
	end

	-- 5. Open Terminal (Right, 80)
	term_split.open_terminal_80()

	-- 6. Move cursor back to the file buffer (center window)
	if center_win and vim.api.nvim_win_is_valid(center_win) then
		vim.api.nvim_set_current_win(center_win)
	end
end

vim.api.nvim_create_user_command("Fix", M.fix_layout, {})

return M
