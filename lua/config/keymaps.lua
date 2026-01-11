-- Taken post leaders f, b, e, t, w
--
-- Try to use the following after post leader
-- p -> previous
-- n -> next
-- f -> file
-- g -> content
-- b -> buffer
-- c -> clear
-- v -> visual

--------------------------------
-- <Leader f> FXF implenentation
--------------------------------

local has_fzf, fzf = pcall(require, 'fzf-lua')

if has_fzf then
  vim.keymap.set('n', '<leader>ff', fzf.files, { desc = 'Search file names' })
  vim.keymap.set('n', '<leader>fg', fzf.live_grep, { desc = 'Search Content of files' })
  vim.keymap.set('n', '<leader>fb', fzf.buffers, { desc = 'Search open buffers' })
  vim.keymap.set({'n', 'v'}, '<leader>fvf', fzf.grep_visual, { desc = 'Search files from highlight'})
  vim.keymap.set({'n', 'v'}, '<leader>fvg', fzf.grep_visual, { desc = 'Search content from highlight'})
end

-----------------------------
-- <Leader b> Buffer Choosing 
-----------------------------

vim.keymap.set('n', '<leader>bp', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Open the previous buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>BufferLineCycleNext<CR>', { desc = 'Open the next buffer' })
vim.keymap.set('n', '<leader>bc', '<cmd>BufferLinePick<CR>', { desc = 'Pick a buffer from the buffer line by index' })

----------------------------
-- Error message integration
----------------------------

vim.keymap.set('n', '<leader>ee', vim.diagnostic.open_float, { desc = 'Show diagnostic error' })
vim.keymap.set('n', '<leader>ep', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic error' })
vim.keymap.set('n', '<leader>en', vim.diagnostic.goto_next, { desc = 'Next diagnostic error' })

-----------------------
-- Terminal Integration
-----------------------

-- Open an 80-character wide vertical split with a terminal
vim.keymap.set('n', '<leader>tt', ':Term80<CR>', { desc = 'Open the Terminal 80' })
vim.keymap.set('n', '<leader>tbc<CR>', ':TerminalClear<CR>', { desc = 'Clear the terminal and enter insert mode'})

---------------------
-- Window Integration
---------------------

vim.keymap.set('n', '<leader>w80', ':vertical resize 80<CR>', { desc = 'Resize the current window to 80 char'})
vim.keymap.set('n', '<leader>wf', ':Fix<CR>', { desc = 'Fix the window layout'})
