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

		if
			vim.tbl_contains(excluded_filetypes, vim.bo.filetype)
			or vim.tbl_contains(excluded_buftypes, vim.bo.buftype)
		then
			vim.opt_local.colorcolumn = ""
		else
			vim.opt_local.colorcolumn = "80"
		end
	end,
})
