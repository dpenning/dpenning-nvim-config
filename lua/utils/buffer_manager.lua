local M = {}

-- Captures the current state of buffers and windows
function M.get_editor_state()
	local buffers = {}
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
			table.insert(buffers, buf)
		end
	end

	local windows = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) then
			local buf = vim.api.nvim_win_get_buf(win)
			table.insert(windows, {
				id = win,
				buf = buf,
				filetype = vim.bo[buf].filetype,
				buftype = vim.bo[buf].buftype,
			})
		end
	end

	return {
		buffers = buffers,
		windows = windows,
		current_win = vim.api.nvim_get_current_win(),
		current_buf = vim.api.nvim_get_current_buf(),
	}
end

-- Determines what changes are needed to close a buffer without closing windows
function M.get_close_plan(state, target_buf)
	local plan = {
		to_delete = target_buf,
		window_updates = {},
		create_scratch = false,
	}

	-- Find all windows displaying this buffer
	local windows_with_buf = {}
	for _, win in ipairs(state.windows) do
		if win.buf == target_buf then
			table.insert(windows_with_buf, win)
		end
	end

	if #windows_with_buf == 0 then
		return plan
	end

	-- Find a fallback buffer
	local fallback = nil
	-- 1. Try alternate buffer
	local alt = vim.fn.bufnr("#")
	if
		alt > 0
		and alt ~= target_buf
		and vim.api.nvim_buf_is_valid(alt)
		and vim.bo[alt].buflisted
		and vim.bo[alt].buftype == ""
	then
		fallback = alt
	end

	-- 2. Try any other listed "real" buffer
	if not fallback then
		for _, buf in ipairs(state.buffers) do
			if buf ~= target_buf and vim.bo[buf].buftype == "" then
				fallback = buf
				break
			end
		end
	end

	-- 3. If no fallback, we will create a scratch
	if not fallback then
		plan.create_scratch = true
	end

	for _, win in ipairs(windows_with_buf) do
		table.insert(plan.window_updates, {
			win_id = win.id,
			fallback = fallback,
		})
	end

	return plan
end

-- Executes the close plan
function M.apply_plan(plan, force)
	if not vim.api.nvim_buf_is_valid(plan.to_delete) then
		return true
	end

	-- Pre-check: if modified and not forced, abort early
	if not force and vim.bo[plan.to_delete].modified then
		vim.api.nvim_err_writeln("E37: No write since last change (add ! to override)")
		return false
	end

	-- Create scratch if needed
	local fallback_buf = nil
	if plan.create_scratch then
		fallback_buf = vim.api.nvim_create_buf(true, false)
		vim.bo[fallback_buf].buftype = ""
	end

	-- Update windows
	for _, update in ipairs(plan.window_updates) do
		if vim.api.nvim_win_is_valid(update.win_id) then
			local target_fallback = update.fallback or fallback_buf
			vim.api.nvim_win_set_buf(update.win_id, target_fallback)
		end
	end

	-- Finally delete the buffer
	local ok, err = pcall(vim.api.nvim_buf_delete, plan.to_delete, { force = force })
	if not ok then
		-- This shouldn't really happen after our pre-check, but safety first
		vim.api.nvim_err_writeln("Failed to delete buffer: " .. tostring(err))
		return false
	end

	return true
end

return M
