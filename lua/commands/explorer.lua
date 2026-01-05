local function open_neotree(dir)
  local parts = {
    "Neotree",
    "toggle",
    "left",
    "filesystem",
    "reveal",
    "reveal_force_cwd=true",
  }
  if dir and dir ~= "" then
    local absolute = vim.fn.fnamemodify(dir, ":p")
    table.insert(parts, "dir=" .. vim.fn.fnameescape(absolute))
  end
  vim.cmd(table.concat(parts, " "))
end

local command_opts = { nargs = "?", complete = "dir", force = true }

vim.api.nvim_create_user_command("Explorer", function(opts)
  open_neotree(opts.args)
end, command_opts)

vim.api.nvim_create_user_command("Explore", function(opts)
  open_neotree(opts.args)
end, command_opts)
