local M = {}

local TRACK_VAR = "term80_managed"
local tracked_buf

local function is_valid_terminal(buf)
	return buf
		and vim.api.nvim_buf_is_valid(buf)
		and vim.bo[buf].buftype == "terminal"
end

local function has_track_flag(buf)
	if not is_valid_terminal(buf) then
		return false
	end
	local ok, value = pcall(vim.api.nvim_buf_get_var, buf, TRACK_VAR)
	return ok and value and value ~= 0
end

local function mark_tracked(buf)
	if not is_valid_terminal(buf) then
		return
	end
	tracked_buf = buf
	vim.g.term80_buf = buf
	pcall(vim.api.nvim_buf_set_var, buf, TRACK_VAR, true)
end

local function find_tracked_terminal()
	if is_valid_terminal(tracked_buf) then
		return tracked_buf
	end

	local global_buf = tonumber(vim.g.term80_buf)
	if is_valid_terminal(global_buf) then
		tracked_buf = global_buf
		return global_buf
	end

	local fallback
	local total = 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if is_valid_terminal(buf) then
			total = total + 1
			if has_track_flag(buf) then
				tracked_buf = buf
				return buf
			elseif not fallback then
				fallback = buf
			end
		end
	end

	if fallback and total == 1 then
		mark_tracked(fallback)
		return fallback
	end

	tracked_buf = nil
	vim.g.term80_buf = nil
	return nil
end

local function close_terminal_windows(buf)
	local wins = vim.fn.win_findbuf(buf)
	if not wins or #wins == 0 then
		return false
	end
	for _, win in ipairs(wins) do
		if vim.api.nvim_win_is_valid(win) then
			local ok = pcall(vim.api.nvim_win_close, win, false)
			if not ok then
				vim.api.nvim_set_current_win(win)
				vim.cmd("enew")
			end
		end
	end
	return true
end

local function open_terminal_window(buf)
	vim.cmd("botright 80vsplit")
	vim.api.nvim_set_current_buf(buf)
	vim.cmd("startinsert")
end

local function create_terminal_window()
	vim.cmd("botright 80vsplit")
	vim.cmd("term")
	local buf = vim.api.nvim_get_current_buf()
	mark_tracked(buf)
	vim.cmd("startinsert")
end

function M.toggle_terminal_80()
	local terminal_buf = find_tracked_terminal()

	if terminal_buf then
		if close_terminal_windows(terminal_buf) then
			return
		end
		open_terminal_window(terminal_buf)
		return
	end

	create_terminal_window()
end

-- Register the command
vim.api.nvim_create_user_command("Term80", M.toggle_terminal_80, {
	desc = "Toggle the dedicated 80-col terminal split",
})

return M
