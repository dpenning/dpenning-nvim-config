return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      {
        "s1n7ax/nvim-window-picker",
        version = "2.*",
        opts = {
          hint = "floating-big-letter",
          filter_rules = {
            autoselect_one = true,
            include_current_win = false,
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify" },
              buftype = { "terminal", "quickfix" },
            },
          },
        },
      },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.g.neo_tree_remove_legacy_commands = 1

      local function open_on_start(path)
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            local cmd = "Neotree left filesystem reveal"
            if path then
              cmd = cmd .. " dir=" .. vim.fn.fnameescape(path)
            end
            vim.cmd(cmd)
          end,
        })
      end

      if vim.fn.argc() == 1 then
        local arg = vim.fn.argv(0)
        local stat = (vim.uv or vim.loop).fs_stat(arg)
        if stat and stat.type == "directory" then
          open_on_start(vim.fn.fnamemodify(arg, ":p"))
        end
      end
    end,
    config = function()
      require("neo-tree").setup({
        enable_git_status = true,
        enable_diagnostics = true,
        sources = { "filesystem", "buffers", "git_status" },
        close_if_last_window = false,
        window = {
          width = 34,
          mappings = {
            ["<space>"] = "toggle_node",
            ["S"] = "split_with_window_picker",
            ["s"] = "vsplit_with_window_picker",
            ["H"] = "toggle_hidden",
          },
        },
        filesystem = {
          follow_current_file = { enabled = true, leave_dirs_open = true },
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_hidden = false,
          },
          hijack_netrw_behavior = "open_default",
        },
        buffers = {
          follow_current_file = { enabled = true },
        },
        default_component_configs = {
          indent = { padding = 0 },
          modified = { symbol = "*" },
        },
      })
    end,
  },
}
