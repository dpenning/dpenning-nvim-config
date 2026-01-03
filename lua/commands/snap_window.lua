local M = {}

function M.snap(direction)
    local script_content = [[
use framework "AppKit"
use scripting additions

on run argv
    set direction to item 1 of argv
    
    -- Get window bounds
    tell application "System Events"
        set frontProcess to first process whose name contains "neovide"
        set frontWindow to window 1 of frontProcess
        set {wPos, wSize} to {position, size} of frontWindow
    end tell
    
    set wX to item 1 of wPos
    set wY to item 2 of wPos
    set wW to item 1 of wSize
    set wH to item 2 of wSize
    set wMidX to wX + (wW / 2)
    set wMidY to wY + (wH / 2)
    
    -- Get screens info via AppKit
    set screens to current application's NSScreen's screens()
    set primaryScreen to item 1 of screens
    set {{pX, pY}, {pW, pH}} to primaryScreen's frame()
    
    set targetScreen to missing value
    
    -- Find which screen the window center is currently on
    repeat with i from 1 to (count of screens)
        set aScreen to item i of screens
        set {{sX, sY}, {sW, sH}} to aScreen's frame()
        
        -- Convert Cocoa Y (bottom-left origin) to System Y (top-left origin)
        set sysTop to pH - (sY + sH)
        
        if (wMidX >= sX) and (wMidX < (sX + sW)) and (wMidY >= sysTop) and (wMidY < (sysTop + sH)) then
            set targetScreen to aScreen
            exit repeat
        end if
    end repeat
    
    -- Fallback to primary if not found
    if targetScreen is missing value then set targetScreen to primaryScreen
    
    -- Get visible frame (work area excluding dock/menu)
    set {{vX, vY}, {vW, vH}} to targetScreen's visibleFrame()
    
    -- Convert Visible Frame Cocoa -> System Events
    set finalSysY to pH - (vY + vH)
    set finalSysX to vX
    
    -- Calculate new bounds
    if direction is "left" then
        set newX to finalSysX
        set newY to finalSysY
        set newW to vW / 2
        set newH to vH
    else
        set newX to finalSysX + (vW / 2)
        set newY to finalSysY
        set newW to vW / 2
        set newH to vH
    end if
    
    -- Apply changes
    tell application "System Events"
        tell frontWindow
            set position to {newX, newY}
            set size to {newW, newH}
        end tell
    end tell
end run
]]

    -- Write script to a temporary file
    local tmp_file = os.tmpname()
    local f = io.open(tmp_file, "w")
    if f then
        f:write(script_content)
        f:close()
        -- Execute the script with the direction argument
        local output = vim.fn.system({"osascript", tmp_file, direction})
        if vim.v.shell_error ~= 0 then
            vim.notify("SnapWindow failed: " .. output, vim.log.levels.ERROR)
        end
        -- Clean up
        os.remove(tmp_file)
    else
        vim.notify("Failed to write temporary AppleScript file", vim.log.levels.ERROR)
    end
end

-- Register the command
vim.api.nvim_create_user_command("SnapWindow", function(opts)
    M.snap(opts.args:lower())
end, {
    nargs = 1,
    complete = function()
        return { "left", "right" }
    end,
    desc = "Snap Neovide window to left or right of the current screen"
})

return M