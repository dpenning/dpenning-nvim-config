return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false, -- plugin upstream explicitly disallows lazy-loading
  config = function()
    local languages = { "c", "lua", "vim", "vimdoc", "python", "cpp", "zig" }
    local ts = require("nvim-treesitter")

    -- Install missing parsers once during startup and wait so we do not spawn
    -- new downloads on every launch. Skip if the tree-sitter CLI is missing to
    -- avoid spamming the command line with errors on every start.
    if vim.fn.executable("tree-sitter") == 1 then
      local installed = {}
      for _, lang in ipairs(ts.get_installed("parsers")) do
        installed[lang] = true
      end

      local missing = {}
      for _, lang in ipairs(languages) do
        if not installed[lang] then
          table.insert(missing, lang)
        end
      end

      if #missing > 0 then
        local ok, job = pcall(ts.install, missing)
        if ok and job and job.wait then
          job:wait(300000)
        end
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
