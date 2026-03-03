local buffer_manager = require("utils.buffer_manager")

local function smart_quit_disabled()
  local ok, value = pcall(vim.api.nvim_buf_get_var, 0, 'smart_quit_disabled')
  if ok and value then
    return true
  end

  local ft = vim.bo.filetype
  if ft == 'theme-picker' then
    return true
  end

  return false
end

local function close_buffer(bang)
  local state = buffer_manager.get_editor_state()
  local plan = buffer_manager.get_close_plan(state, state.current_buf)
  buffer_manager.apply_plan(plan, bang)
end

-- 1. The SmartQuit Command
-- Handles the logic: "If in file, close buffer but keep split. If in tool/explorer, quit window."
vim.api.nvim_create_user_command("SmartQuit", function(opts)
  if smart_quit_disabled() then
    if opts.bang then
      vim.cmd('quit!')
    else
      vim.cmd('quit')
    end
    return
  end

  local explorers = { "netrw", "NvimTree", "neo-tree", "oil" }
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype
  
  -- If it's an explorer or a special tool window, just quit the window
  if vim.tbl_contains(explorers, filetype) or buftype == "terminal" or buftype == "quickfix" then
    if opts.bang then
      vim.cmd("quit!")
    else
      vim.cmd("quit")
    end
  else
    -- We are in a real file: close the buffer but keep the window open
    close_buffer(opts.bang)
  end
end, { bang = true })

-- 2. The Interceptor (Fixed)
vim.keymap.set('c', '<CR>', function()
  if smart_quit_disabled() then
    return '<CR>'
  end
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
