
-- Close all buffers and open only the files that have been modified since git diff main.
-- This is useful for cleaning up the buffer list and focusing on the current task.
-- The command preserves the terminal and neo-tree splits if they exist.
--
-- To use this command, run:
-- :GitDiffOpen
--
-- Or map it to a keybinding in your keymaps.lua file:
-- keymap.set("n", "<leader>gdo", "<cmd>GitDiffOpen<cr>", { desc = "Git Diff Open" })

local function git_diff_open()
  -- Get the list of modified files
  local files = vim.fn.systemlist("git diff --name-only main")

  -- Store the current window layout
  local term_win = nil
  local neo_tree_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if buf_name:match("term://") then
      term_win = win
    elseif buf_name:match("neo-tree") then
      neo_tree_win = win
    end
  end

  -- Remove all file buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(buf, "buftype") == "" and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  -- Restore the terminal and neo-tree splits
  if neo_tree_win then
    vim.cmd("vsplit")
    vim.cmd("NeoTreeShow")
  end
  if term_win then
    vim.cmd("vsplit")
    vim.cmd("toggleterm")
  end


  -- Open the modified files
  if #files == 0 or (#files == 1 and files[1] == "") then
    vim.cmd("enew")
  else
    for _, file in ipairs(files) do
      if file ~= "" then
        vim.cmd("edit " .. file)
      end
    end
  end
end

vim.api.nvim_create_user_command("GitDiffOpen", git_diff_open, {})
