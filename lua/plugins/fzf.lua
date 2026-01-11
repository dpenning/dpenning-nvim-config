return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local fzf = require("fzf-lua")

    ------------------------------------------------------------------
    -- Project → ignored directories map (absolute paths)
    ------------------------------------------------------------------
    local ignore_map = {
      ["/Users/dpenning/Google/chromium/src"] = {
        ".cache",
	".github",
	"extensions",
	"agents",
        "android_webview",
        "apps",
        "ash",
        "build",
        "build_overrides",
        "chromecast",
        "clank",
        "clusterfuzz-data",
        "codelabs",
        "crypto",
        "dbus",
        "device",
        "fuchsia_web",
        "gin",
        "google_apis",
        "headless",
        "infra",
        "ios",
        "ios_internal",
        "ipc",
        "media",
        "net",
	"out",
        "pdf",
        "printing",
        "remoting",
        "rlz",
        "sandbox",
        "services",
        "signing_keys",
        "sql",
        "storage",
        "styleguide",
        "testing",
        "third_party",
        "tools",
        "v8",
        "webkit",
      },
    }

    ------------------------------------------------------------------
    -- Resolve current project root
    ------------------------------------------------------------------
    local function get_project_root()
      return vim.loop.cwd()
    end

    ------------------------------------------------------------------
    -- Build ripgrep glob exclusions for the project
    ------------------------------------------------------------------
    local function build_rg_ignore_globs(root)
      local ignores = ignore_map[root]
      if not ignores then
        return ""
      end

      local parts = {}
      for _, dir in ipairs(ignores) do
        parts[#parts + 1] = ("--glob '!%s/**'"):format(dir)
      end

      return table.concat(parts, " ")
    end

    ------------------------------------------------------------------
    -- Monkey-patch fzf-lua to apply project ignores automatically
    ------------------------------------------------------------------
    local original_files = fzf.files
    fzf.files = function(opts)
      opts = opts or {}
      local root = opts.cwd or get_project_root()
      local ignore_globs = build_rg_ignore_globs(root)
      
      if ignore_globs ~= "" then
        -- Force ripgrep to list files with our globs
        opts.cmd = "rg --files --color=never --hidden --follow --no-ignore-vcs " .. ignore_globs
      end
      return original_files(opts)
    end

    local original_live_grep = fzf.live_grep
    fzf.live_grep = function(opts)
      opts = opts or {}
      local root = opts.cwd or get_project_root()
      local ignore_globs = build_rg_ignore_globs(root)

      if ignore_globs ~= "" then
        local base_rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e"
        opts.rg_opts = ignore_globs .. " " .. base_rg_opts
      end
      return original_live_grep(opts)
    end

    ------------------------------------------------------------------
    -- fzf-lua setup
    ------------------------------------------------------------------
    fzf.setup({})

  end,
}

