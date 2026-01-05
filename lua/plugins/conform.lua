return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                zig = { "zigfmt" },
            },
            format_on_save = function(bufnr)
                local filetype = vim.bo[bufnr].filetype
                if filetype == "zig" then
                    return { lsp_fallback = true }
                end
                return false
            end,
        })
    end,
}
