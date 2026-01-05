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
