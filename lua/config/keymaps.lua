---------------------
-- FXF implenentation
---------------------

local fzf = require('fzf-lua')

-- Find Files (matches filenames)
-- Use this to open files in your project
vim.keymap.set('n', '<leader>f', fzf.files, { desc = 'Fzf Files' })

-- Live Grep (matches text inside files)
-- Uses ripgrep to search for strings as you type
vim.keymap.set('n', '<leader>g', fzf.live_grep, { desc = 'Fzf Live Grep' })

-- Buffers (switch between open files)
vim.keymap.set('n', '<leader>b', fzf.buffers, { desc = 'Fzf Buffers' })

-- Bufferline navigation
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>BufferLinePick<CR>', { desc = 'Pick buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>BufferLinePickClose<CR>', { desc = 'Close buffer' })

-- Neo-tree file explorer
vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle left<CR>', { desc = 'Neo-tree toggle' })
vim.keymap.set('n', '<leader>E', '<cmd>Neotree focus<CR>', { desc = 'Neo-tree focus' })

-- Help Tags (search help documentation)
vim.keymap.set('n', '<leader>h', fzf.help_tags, { desc = 'Fzf Help' })

----------------------
-- User implementation
----------------------

-- Open an 80-character wide vertical split with a terminal
vim.keymap.set('n', '<leader>T', ':Term80<CR>', { desc = 'Terminal (80 chars)' })

-- Ask Gemma helper about Neovim actions
vim.keymap.set('n', '<leader>a', ':HowDoI<CR>', { desc = 'Gemma helper ask' })
