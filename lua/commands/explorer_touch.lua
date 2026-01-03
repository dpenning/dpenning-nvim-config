vim.api.nvim_create_user_command("Touch", function(opts)
  -- 1. Get the directory path of the current buffer (the explorer view)
  -- 'expand("%:p")' returns the full path of the current buffer
  local current_dir = vim.fn.expand("%:p")

  -- 2. Handle potential missing trailing slash in directory path
  if not current_dir:match("/$") then
    current_dir = current_dir .. "/"
  end

  local filename = opts.args
  local full_path = current_dir .. filename

  -- 3. Run the touch command
  -- We use vim.fn.system to run it silently (no "Press Enter" prompt)
  vim.fn.system({ "touch", full_path })

  -- 4. Check for success and refresh the explorer
  if vim.v.shell_error == 0 then
    print("Created: " .. filename)
    vim.cmd("edit") -- Refreshes the directory view
  else
    print("Error creating file: " .. full_path)
  end
end, {
  nargs = 1,        -- Requires exactly 1 argument (the filename)
  complete = 'file' -- Enables autocomplete for file paths
})
