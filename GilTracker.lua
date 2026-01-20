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
    hourly = "0",
    daily = "0",
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

    -- Calculate Estimates
    local hourly = 0
    if (elapsed > 0) then hourly = (diff / elapsed) * 3600 end
    local daily = hourly * 24

    GilTracker.cache.current = GilTracker.FormatNumber(GilTracker.currentGil)
    GilTracker.cache.hourly  = GilTracker.FormatNumber(math.floor(hourly))
    GilTracker.cache.daily   = GilTracker.FormatNumber(math.floor(daily))
    
    return cGil
end

function GilTracker.Draw(event, tick)
    if (not GilTracker.open) then return end

    GUI:SetNextWindowSize(200, 150, GUI.SetCond_FirstUseEver)
    GilTracker.visible, GilTracker.open = GUI:Begin(GilTracker.windowName, GilTracker.open)
    
    if (GilTracker.visible) then
        local now = os.clock()
        
        -- Initialization Logic
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
            
            if (not GilTracker.initialized) then
                GUI:Text("Initializing...")
            end
        else
            -- Main Logic Throttling
            if (now - GilTracker.lastUpdate > GilTracker.updateInterval) then
                GilTracker.lastUpdate = now
                GilTracker.UpdateData()
            end

            -- Render using Cached Strings (Very fast)
            GUI:Text("Time: " .. GilTracker.cache.time)
            
            GUI:Separator()
            GUI:Text("Current: " .. GilTracker.cache.current)
            
            -- Color logic is fast enough to keep here or could be cached too, but simple ifs are cheap
            GUI:Text("Change:  ")
            GUI:SameLine(80)
            local d = GilTracker.cache.diff
            if (d > 0) then 
                GUI:TextColored(0, 1, 0, 1, GilTracker.cache.change)
            elseif (d < 0) then 
                GUI:TextColored(1, 0, 0, 1, GilTracker.cache.change)
            else 
                GUI:Text(GilTracker.cache.change) 
            end

            GUI:Separator()
            GUI:Text("1h Est:  " .. GilTracker.cache.hourly)
            GUI:Text("24h Est: " .. GilTracker.cache.daily)
        end
    end
    GUI:End()
end

-- Register Event
RegisterEventHandler("Gameloop.Draw", GilTracker.Draw, "GilTracker_Draw")
-- Remove debug prints for final version
