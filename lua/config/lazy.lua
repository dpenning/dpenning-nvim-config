-- 1. Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. Set Leader Key (Must be before setup)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 3. Load lazy.nvim
-- This tells Lazy to look for plugin specs in the "lua/plugins" folder
require("lazy").setup("plugins")

return {}
