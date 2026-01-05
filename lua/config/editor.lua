-- Enable tree-sitter powered folding in every window
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- If a buffer lacks a treesitter parser, fall back to indent folds
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		local ok = pcall(vim.treesitter.get_parser, args.buf)
		if ok then
			vim.opt_local.foldmethod = "expr"
			vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		else
			vim.opt_local.foldmethod = "indent"
			vim.opt_local.foldexpr = ""
		end
		vim.opt_local.foldenable = true
		vim.opt_local.foldlevel = 99
		vim.opt_local.foldlevelstart = 99
	end,
})

-- Only show the color column in real files (editor mode)
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
	pattern = "*",
	callback = function()
		local excluded_filetypes = {
			"netrw",
			"help",
			"lazy",
			"fzf",
			"qf",
			"lspinfo",
			"man",
			"startuptime",
			"checkhealth",
			"mason",
			"TelescopePrompt",
			"gitcommit",
			"gitrebase",
			"gitsendemail",
			"git",
			"alpha",
			"dashboard",
			"NvimTree",
			"neo-tree",
			"Trouble",
			"noice",
			"notify",
		}
		local excluded_buftypes = { "terminal", "nofile", "quickfix", "prompt" }

		local filetype = vim.bo.filetype
		local buftype = vim.bo.buftype
		local is_c_like = filetype == "c" or filetype == "cpp"
		local should_show = is_c_like
		local is_excluded = vim.tbl_contains(excluded_filetypes, filetype)
			or vim.tbl_contains(excluded_buftypes, buftype)
		if is_excluded or not should_show then
			vim.opt_local.colorcolumn = ""
		else
			vim.opt_local.colorcolumn = "80"
		end
	end,
})

-- Remove the startup scratch buffer once a real file opens
local initial_buffer = vim.api.nvim_get_current_buf()
local cleanup_group = vim.api.nvim_create_augroup("RemoveInitialBuffer", { clear = true })

local function delete_initial_if_safe()
	if not initial_buffer then
		return
	end
	if not vim.api.nvim_buf_is_valid(initial_buffer) then
		initial_buffer = nil
		return
	end
	local info = vim.fn.getbufinfo(initial_buffer)[1]
	if not info or info.name ~= "" or info.changed ~= 0 or info.buftype ~= "" then
		initial_buffer = nil
		return
	end
	for _, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if bufinfo.bufnr ~= initial_buffer and bufinfo.name ~= "" and bufinfo.buftype == "" then
			vim.api.nvim_buf_delete(initial_buffer, { force = true })
			initial_buffer = nil
			break
		end
	end
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
	group = cleanup_group,
	callback = function(args)
		if not initial_buffer then
			return
		end
		local target = args.buf or vim.api.nvim_get_current_buf()
		if not vim.api.nvim_buf_is_valid(target) then
			return
		end
		if vim.bo[target].buftype ~= "" then
			return
		end
		if vim.api.nvim_buf_get_name(target) == "" then
			return
		end
		delete_initial_if_safe()
	end,
})

-- When deleting a buffer, prefer focusing another real buffer instead of Neo-tree
local function focus_adjacent_file()
	local current = vim.api.nvim_get_current_buf()
	if vim.bo[current].filetype ~= "neo-tree" then
		return
	end

	local function is_real_buffer(buf)
		return vim.api.nvim_buf_is_valid(buf)
			and vim.api.nvim_buf_get_name(buf) ~= ""
			and vim.bo[buf].buftype == ""
			and vim.bo[buf].filetype ~= "neo-tree"
	end

	local target = nil
	local alt = vim.fn.bufnr("#")
	if alt > 0 and is_real_buffer(alt) then
		target = alt
	else
		for _, bufinfo in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
			local buf = bufinfo.bufnr
			if buf ~= current and is_real_buffer(buf) then
				target = buf
				break
			end
		end
	end

	if target then
		vim.cmd("buffer " .. target)
	end
end

local focus_group = vim.api.nvim_create_augroup("FocusAfterBufferDelete", { clear = true })
vim.api.nvim_create_autocmd("BufDelete", {
	group = focus_group,
	callback = function()
		vim.defer_fn(focus_adjacent_file, 5)
	end,
})
