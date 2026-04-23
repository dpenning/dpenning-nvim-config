local M = {}

local function is_file_buffer(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return false
	end
	if vim.fn.buflisted(buf) == 0 then
		return false
	end
	if vim.bo[buf].buftype ~= "" then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	return name ~= nil and name ~= ""
end

local function pick_fallback_buffer(current_buf)
	local alt = vim.fn.bufnr("#")
	if alt > 0 and alt ~= current_buf and is_file_buffer(alt) then
		return alt
	end

	local candidates = vim.fn.getbufinfo({ buflisted = 1 })
	table.sort(candidates, function(a, b)
		return (a.lastused or 0) > (b.lastused or 0)
	end)

	for _, info in ipairs(candidates) do
		local buf = info.bufnr
		if buf ~= current_buf and is_file_buffer(buf) then
			return buf
		end
	end

	return nil
end

function M.close_current_buffer()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_win = vim.api.nvim_get_current_win()

	if not is_file_buffer(current_buf) then
		vim.notify("CloseBuffer works on regular file buffers", vim.log.levels.WARN)
		return
	end

	if vim.bo[current_buf].modified then
		local answer = vim.fn.confirm("Buffer has unsaved changes. Close anyway?", "&Yes\n&No", 2)
		if answer ~= 1 then
			return
		end
	end

	local fallback = pick_fallback_buffer(current_buf)
	if fallback and vim.api.nvim_buf_is_valid(fallback) then
		vim.api.nvim_win_set_buf(current_win, fallback)
	else
		vim.cmd("enew")
	end

	if vim.api.nvim_buf_is_valid(current_buf) then
		local ok, err = pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
		if not ok then
			vim.notify("CloseBuffer: " .. err, vim.log.levels.ERROR)
		end
	end
end

vim.api.nvim_create_user_command("CloseBuffer", function()
	M.close_current_buffer()
end, {
	desc = "Close the current file buffer but keep the split open",
})

return M
