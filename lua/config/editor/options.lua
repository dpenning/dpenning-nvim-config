-- Provide line number with relative for easy navigation
vim.opt.number = true
vim.opt.relativenumber = true

-- Use open should keep the buffers from being opened multiple times
-- meaning that if you try to open editor.lua and its already open it
-- will just activate it.
vim.opt.switchbuf = "useopen"

-- Splits should usually open to the right
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Automatically read files when they are changed outside of Neovim
vim.opt.autoread = true
vim.opt.cursorline = true
