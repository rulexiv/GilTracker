-- Gil Tracker Addon (Optimized)
-- Localizing globals for performance
local GUI = GUI
local Inventory = Inventory
local math = math
local string = string
local os = os

GilTracker = {}
GilTracker.name = "Gil Tracker"
GilTracker.open = true
GilTracker.visible = true
GilTracker.initialized = false
GilTracker.windowName = "Gil Tracker##GilTrackerWindow"

-- State
GilTracker.startGil = 0
GilTracker.startTime = 0
GilTracker.currentGil = 0

-- Performance: Cache for display strings to avoid formatting every frame
GilTracker.cache = {
    time = "00:00:00",
    current = "0",
    change = "0",
    diff = 0
}
GilTracker.lastUpdate = 0
GilTracker.updateInterval = 1.0 -- Update logic every 1 second (Extreme efficiency)

-- Helper to get Gil safely
function GilTracker.GetGil()
    if (Inventory) then
        return Inventory:GetCurrencyCountByID(1)
    end
    return 0
end

function GilTracker.FormatNumber(n)
    local formatted = tostring(n)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then break end
    end
    return formatted
end

function GilTracker.FormatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

function GilTracker.UpdateData()
    -- Get current Gil
    local cGil = GilTracker.GetGil()
    if (cGil > 0) then
        GilTracker.currentGil = cGil
    end

    -- Calculate Time
    local elapsed = os.time() - GilTracker.startTime
    GilTracker.cache.time = GilTracker.FormatTime(elapsed)

    -- Calculate Diff
    local diff = GilTracker.currentGil - GilTracker.startGil
    GilTracker.cache.diff = diff
    
    local diffStr = GilTracker.FormatNumber(diff)
    if (diff > 0) then diffStr = "+" .. diffStr end
    GilTracker.cache.change = diffStr

    GilTracker.cache.current = GilTracker.FormatNumber(GilTracker.currentGil)
    
    return cGil
end

function GilTracker.Draw(event, tick)
    if (not GilTracker.open) then return end

    local now = os.clock()
        
    -- Initialization Logic (Run regardless of visibility so data is ready)
    if (not GilTracker.initialized) then
        -- Throttle init checks too
        if (now - GilTracker.lastUpdate > 1.0) then 
            GilTracker.lastUpdate = now
            local currentGil = GilTracker.GetGil()
            if (currentGil > 0) then
                GilTracker.startGil = currentGil
                GilTracker.currentGil = currentGil
                GilTracker.startTime = os.time()
                GilTracker.initialized = true
                -- Initial update of cache
                GilTracker.UpdateData()
            end
        end
    else
        -- Main Logic Throttling (Run regardless of visibility)
        if (now - GilTracker.lastUpdate > GilTracker.updateInterval) then
            GilTracker.lastUpdate = now
            GilTracker.UpdateData()
        end
    end

    -- Fixed Bar Mode Logic
    local sw, sh = GUI:GetScreenSize()
    local barHeight = 15
    local barWidth = 175 -- Adjusted width to be centered
    
    -- Position at bottom right of screen
    GUI:SetNextWindowPos(sw - barWidth, sh - barHeight, GUI.SetCond_Always)
    GUI:SetNextWindowSize(barWidth, barHeight, GUI.SetCond_Always)
    
    -- Flags to make it look like a static bar
    local flags = 0
    if (GUI.WindowFlags_NoTitleBar)       then flags = flags + GUI.WindowFlags_NoTitleBar end
    if (GUI.WindowFlags_NoResize)         then flags = flags + GUI.WindowFlags_NoResize end
    if (GUI.WindowFlags_NoMove)           then flags = flags + GUI.WindowFlags_NoMove end
    if (GUI.WindowFlags_NoCollapse)       then flags = flags + GUI.WindowFlags_NoCollapse end
    if (GUI.WindowFlags_NoScrollbar)      then flags = flags + GUI.WindowFlags_NoScrollbar end
    if (GUI.WindowFlags_NoSavedSettings)  then flags = flags + GUI.WindowFlags_NoSavedSettings end

    -- Eliminate Window Padding for compact look
    GUI:PushStyleVar(GUI.StyleVar_WindowPadding, 5, 0) -- 5px left/right, 0px top/bottom
    GUI:PushStyleVar(GUI.StyleVar_WindowMinSize, 1, 1) -- Allow small windows

    -- Begin Fixed Window
    -- Note: We pass 'true' for open to avoid the X button logic interfering, 
    -- as we control visibility via the main Draw event check.
    if (GUI:Begin("GilTrackerFixedBar###GilTrackerFixed", true, flags)) then
        local now = os.clock()
        
        -- Initialization Logic
        if (not GilTracker.initialized) then
            -- Throttle init checks
            if (now - GilTracker.lastUpdate > 1.0) then 
                GilTracker.lastUpdate = now
                local currentGil = GilTracker.GetGil()
                if (currentGil > 0) then
                    GilTracker.startGil = currentGil
                    GilTracker.currentGil = currentGil
                    GilTracker.startTime = os.time()
                    GilTracker.initialized = true
                    GilTracker.UpdateData()
                end
            end
            
            GUI:Text("Init...")
        else
            -- Main Logic Throttling
            if (now - GilTracker.lastUpdate > GilTracker.updateInterval) then
                GilTracker.lastUpdate = now
                GilTracker.UpdateData()
            end
            
            -- Draw Content
            -- Use AlignTextToFramePadding to center vertically if height allows, 
            -- but with 20px height and standard font, it should be fine.
            
            -- Time
            GUI:Text(GilTracker.cache.time)
            
            GUI:SameLine()
            GUI:Text(" ") -- Minimal Spacer
            GUI:SameLine()
            
            -- Change (Colored)
            local d = GilTracker.cache.diff
            if (d > 0) then 
                GUI:TextColored(0, 1, 0, 1, GilTracker.cache.change)
            elseif (d < 0) then 
                GUI:TextColored(1.0, 0.4, 0.7, 1, GilTracker.cache.change)
            else 
                GUI:Text(GilTracker.cache.change) 
            end
            
            -- Optional: Add hourly/daily stats if there is room?
            -- For now keeping it simple as per request.
        end
    end
    GUI:End()
    GUI:PopStyleVar(2) -- Pop WindowPadding and WindowMinSize
end

-- Register Event
RegisterEventHandler("Gameloop.Draw", GilTracker.Draw, "GilTracker_Draw")
-- Remove debug prints for final version
