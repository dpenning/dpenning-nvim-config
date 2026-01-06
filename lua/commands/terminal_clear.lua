vim.api.nvim_create_user_command('ClearTerm', function()
	if vim.bo.buftype == 'terminal' then
		vim.opt_local.scrollback = 1
		vim.api.nvim_command("sleep 10m")
		vim.opt_local.scrollback = 10000
		vmi.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('clear<CR>', true, false, true), 't', true)
	else
		-- TODO find the terminal and do this, then put it in insert mode.
		print("Not a terminal buffer")
	end
end, {desc = 'Clear the terminal buffer so that it has no history'})
