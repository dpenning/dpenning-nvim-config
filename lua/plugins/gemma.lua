local plugin_path = "/Users/david/Code/nvim/gemma_nvim_helper"

if vim.fn.isdirectory(plugin_path) == 0 then
  return {}
end

return {
  {
    dir = plugin_path,
    name = "gemma_nvim_helper",
    lazy = false,
    config = function()
      require("gemma_nvim_helper").setup({
        use_help_context = true,
      })
    end,
  },
}

