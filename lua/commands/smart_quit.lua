-- 1. The SmartQuit Command
-- Handles the logic: "If in file, go to explorer. If in explorer, quit."
vim.api.nvim_create_user_command("SmartQuit", function(opts)
  local explorers = { "netrw", "NvimTree", "neo-tree", "oil" }
  
  if vim.tbl_contains(explorers, vim.bo.filetype) then
    -- We are in the explorer: actually quit
    if opts.bang then
      vim.cmd("quit!")
    else
      vim.cmd("quit")
    end
  else
    -- We are in a file: go back to explorer
    -- We use "edit!" if bang is present to discard changes
    if opts.bang then
      vim.cmd("Ex!") 
    else
      vim.cmd("Ex")
    end
  end
end, { bang = true })

-- 2. The Interceptor (Fixed)
vim.keymap.set('c', '<CR>', function()
  local cmd = vim.fn.getcmdline()

  if cmd == 'q' then
    -- <C-u> clears the "q" you typed before running SmartQuit
    return '<C-u>SmartQuit<CR>'
  elseif cmd == 'q!' then
    return '<C-u>SmartQuit!<CR>'
  elseif cmd == 'wq' then
    -- <C-u> clears "wq", then writes, then runs SmartQuit
    return '<C-u>write | SmartQuit<CR>'
  else
    return '<CR>'
  end
end, { expr = true })
