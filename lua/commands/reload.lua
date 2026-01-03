local M = {}

function M.reload()
    -- Clear all custom modules from the cache
    -- This filters for your own modules (config, theme, plugins, commands)
    for name, _ in pairs(package.loaded) do
        if name:match("^config") or name:match("^theme") or name:match("^plugins") or name:match("^commands") then
            package.loaded[name] = nil
        end
    end

    -- Clear the main init file
    package.loaded["init"] = nil

    -- Re-source init.lua
    vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua")
    
    -- Notify the user
    vim.notify("Configuration reloaded!", vim.log.levels.INFO)
end

-- Register the command
vim.api.nvim_create_user_command("ReloadConfig", M.reload, {})

return M
