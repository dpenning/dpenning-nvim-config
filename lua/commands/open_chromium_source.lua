local M = {}

function M.open_chromium_source()
  local filepath = vim.fn.expand('%:p')
  local line = vim.fn.line('.')
  local filename_base = vim.fn.expand('%:t:r')

  -- Attempt to find the path relative to 'src'
  local src_pattern = "/src/"
  local src_start, src_end = string.find(filepath, src_pattern, 1, true)
  
  local relative_path = ""
  if src_start then
    -- Extract everything after /src/
    relative_path = string.sub(filepath, src_end + 1)
  else
    -- Fallback: try to find git root and use relative path from there
    local git_cmd = "git -C " .. vim.fn.expand('%:p:h') .. " rev-parse --show-toplevel"
    local git_root = vim.fn.system(git_cmd):gsub('\n', '')
    
    if vim.v.shell_error == 0 and git_root ~= "" and string.find(filepath, git_root, 1, true) == 1 then
       -- Calculate relative path from git root
       -- git_root length + 1 (for next char) + 1 (for separator if not present in root, usually isn't)
       relative_path = string.sub(filepath, #git_root + 2)
    else
       vim.notify("Could not determine relative path. Not in a '/src/' directory or git repository.", vim.log.levels.ERROR)
       return
    end
  end

  local url = string.format(
    "https://source.chromium.org/chromium/chromium/src/+/main:%s;l=%d?q=%s&ss=chromium",
    relative_path,
    line,
    filename_base
  )

  -- Open the URL
  local open_cmd = "open"
  if vim.fn.has("linux") == 1 then
    open_cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    open_cmd = "explorer.exe" -- wsl usually can use explorer.exe
  end

  vim.fn.jobstart({open_cmd, url}, {detach = true})
  vim.notify("Opening " .. url, vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('OpenChromiumSource', M.open_chromium_source, {})

return M
