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
    
    set currentScreen to missing value
    
    -- Find which screen the window center is currently on
    repeat with i from 1 to (count of screens)
        set aScreen to item i of screens
        set {{sX, sY}, {sW, sH}} to aScreen's frame()
        
        -- Convert Cocoa Y (bottom-left origin) to System Y (top-left origin)
        set sysTop to pH - (sY + sH)
        
        if (wMidX >= sX) and (wMidX < (sX + sW)) and (wMidY >= sysTop) and (wMidY < (sysTop + sH)) then
            set currentScreen to aScreen
            set currentFrame to {{sX, sY}, {sW, sH}}
            exit repeat
        end if
    end repeat
    
    -- Fallback to primary if not found
    if currentScreen is missing value then 
        set currentScreen to primaryScreen
        set currentFrame to primaryScreen's frame()
    end if

    -- Get properties of current screen
    set {{cX, cY}, {cW, cH}} to currentFrame
    set {{vX, vY}, {vW, vH}} to currentScreen's visibleFrame()
    set currSysX to vX
    
    -- Check if currently snapped
    set tolerance to 30
    set isSnappedLeft to false
    set isSnappedRight to false
    
    -- Check widths and heights
    set wDiff to wW - (vW / 2)
    if wDiff < 0 then set wDiff to -wDiff
    
    set hDiff to wH - vH
    if hDiff < 0 then set hDiff to -hDiff
    
    if (wDiff < tolerance) and (hDiff < tolerance) then
        -- Check positions
        set xDiffLeft to wX - currSysX
        if xDiffLeft < 0 then set xDiffLeft to -xDiffLeft
        
        set xDiffRight to wX - (currSysX + (vW / 2))
        if xDiffRight < 0 then set xDiffRight to -xDiffRight
        
        if xDiffLeft < tolerance then set isSnappedLeft to true
        if xDiffRight < tolerance then set isSnappedRight to true
    end if
    
    set targetScreen to currentScreen
    
    -- Logic to move to adjacent screen
    if (direction is "left" and isSnappedLeft) then
        set bestX to -1000000
        set candidate to missing value
        
        repeat with i from 1 to (count of screens)
            set s to item i of screens
            if s is not currentScreen then
                set {{sX, sY}, {sW, sH}} to s's frame()
                -- Look for screen to the left (sX < cX)
                if sX < cX then
                    if sX > bestX then
                        set bestX to sX
                        set candidate to s
                    end if
                end if
            end if
        end repeat
        if candidate is not missing value then set targetScreen to candidate
        
    else if (direction is "right" and isSnappedRight) then
        set bestX to 1000000
        set candidate to missing value
        
        repeat with i from 1 to (count of screens)
            set s to item i of screens
            if s is not currentScreen then
                set {{sX, sY}, {sW, sH}} to s's frame()
                -- Look for screen to the right (sX > cX)
                if sX > cX then
                    if sX < bestX then
                        set bestX to sX
                        set candidate to s
                    end if
                end if
            end if
        end repeat
        if candidate is not missing value then set targetScreen to candidate
    end if
    
    -- Get visible frame of target screen
    set {{tVX, tVY}, {tVW, tVH}} to targetScreen's visibleFrame()
    
    -- Convert Visible Frame Cocoa -> System Events
    set finalSysY to pH - (tVY + tVH)
    set finalSysX to tVX
    
    -- Calculate new bounds
    if direction is "left" then
        set newX to finalSysX
        set newY to finalSysY
        set newW to tVW / 2
        set newH to tVH
    else if direction is "right" then
        set newX to finalSysX + (tVW / 2)
        set newY to finalSysY
        set newW to tVW / 2
        set newH to tVH
    else if direction is "full" then
        set newX to finalSysX
        set newY to finalSysY
        set newW to tVW
        set newH to tVH
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
        return { "left", "right", "full" }
    end,
    desc = "Snap Neovide window to left or right of the current screen"
})

return M