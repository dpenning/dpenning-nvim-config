local constants = require("theme.constants")

local function ensure_highlights()
  local whitespace = vim.api.nvim_get_hl(0, { name = "Whitespace", link = false })
  if not whitespace or vim.tbl_count(whitespace) == 0 then
    whitespace = vim.api.nvim_get_hl(0, { name = "LineNr", link = false })
  end

  for _, name in ipairs(constants.indent_highlights) do
    if vim.fn.hlexists(name) == 0 then
      vim.api.nvim_set_hl(0, name, whitespace)
    end
  end
end

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  init = ensure_highlights,
  opts = {
    indent = {
      char = "│",
      highlight = vim.deepcopy(constants.indent_highlights),
    },
    scope = {
      enabled = true,
      show_start = false,
      show_end = false,
    },
  },
}
