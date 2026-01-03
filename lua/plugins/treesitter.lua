return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false, -- Recommended by the new nvim-treesitter version
    config = function()
        -- 1. Install Parsers
        -- The "configs" module is gone. We now use .install() directly.
        require("nvim-treesitter").install({ "c", "lua", "vim", "vimdoc", "python", "cpp" })

        -- 2. Enable Highlighting
        -- We now use Neovim's built-in treesitter support via autocommands.
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                -- Attempt to start treesitter. pcall prevents errors if no parser is available.
                pcall(vim.treesitter.start)
            end,
        })

        -- 3. Enable Indentation
        -- This is the new way to enable indentation provided by the plugin.
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end
}