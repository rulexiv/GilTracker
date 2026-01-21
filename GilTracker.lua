-- Gil Tracker Addon
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

-- Statistics
GilTracker.stats = {
    maxGil = 0,
    minGil = 0,
    maxDrawdown = 0,
    maxDrawup = 0,
    hourlyRate = 0,
    dailyRate = 0
}

-- History for Graph (Store profit diff every hour)
GilTracker.history = {} 
GilTracker.historyLimit = 24
GilTracker.lastHistoryUpdate = 0

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

function GilTracker.Reset()
    local currentGil = GilTracker.GetGil()
    if (currentGil > 0) then
        GilTracker.startGil = currentGil
        GilTracker.currentGil = currentGil
        GilTracker.startTime = os.time()
        
        -- Reset Statistics
        GilTracker.stats.maxGil = currentGil
        GilTracker.stats.minGil = currentGil
        GilTracker.stats.maxDrawdown = 0
        GilTracker.stats.maxDrawup = 0
        GilTracker.stats.hourlyRate = 0
        GilTracker.stats.dailyRate = 0
        
        -- Reset History
        GilTracker.history = { 0 }
        GilTracker.lastHistoryUpdate = os.time()
        
        -- Update cache
        GilTracker.UpdateData()
    end
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

    local now = os.time()
    local elapsed = now - GilTracker.startTime
    
    -- Calculate Time
    GilTracker.cache.time = GilTracker.FormatTime(elapsed)

    -- Calculate Diff
    local diff = GilTracker.currentGil - GilTracker.startGil
    GilTracker.cache.diff = diff
    
    local diffStr = GilTracker.FormatNumber(diff)
    if (diff > 0) then diffStr = "+" .. diffStr end
    GilTracker.cache.change = diffStr

    GilTracker.cache.current = GilTracker.FormatNumber(GilTracker.currentGil)
    
    -- Update Stats
    if (GilTracker.stats.maxGil == 0 or GilTracker.currentGil > GilTracker.stats.maxGil) then
        GilTracker.stats.maxGil = GilTracker.currentGil
    end
    if (GilTracker.stats.minGil == 0 or GilTracker.currentGil < GilTracker.stats.minGil) then
        GilTracker.stats.minGil = GilTracker.currentGil
    end

    local drawdown = GilTracker.stats.maxGil - GilTracker.currentGil
    if (drawdown > GilTracker.stats.maxDrawdown) then
        GilTracker.stats.maxDrawdown = drawdown
    end

    local drawup = GilTracker.currentGil - GilTracker.stats.minGil
    if (drawup > GilTracker.stats.maxDrawup) then
        GilTracker.stats.maxDrawup = drawup
    end

    -- Rates
    if (elapsed > 0) then
        GilTracker.stats.hourlyRate = math.floor(diff / (elapsed / 3600))
        GilTracker.stats.dailyRate = math.floor(diff / (elapsed / 86400))
    end

    -- History Update (Every 1 hour = 3600 seconds)
    -- Initialize history if empty
    if (#GilTracker.history == 0) then
        table.insert(GilTracker.history, 0)
        GilTracker.lastHistoryUpdate = now
    end

    if (now - GilTracker.lastHistoryUpdate >= 3600) then
        table.insert(GilTracker.history, diff)
        if (#GilTracker.history > GilTracker.historyLimit) then
            table.remove(GilTracker.history, 1)
        end
        GilTracker.lastHistoryUpdate = now
    end

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

    -- Fixed Window Setup
    local sw, sh = GUI:GetScreenSize()
    local barHeight = 15
    local barWidth = 174
    
    -- Position at bottom right
    GUI:SetNextWindowPos(sw - barWidth, sh - barHeight, GUI.SetCond_Always)
    GUI:SetNextWindowSize(barWidth, barHeight, GUI.SetCond_Always)
    
    local flags = 0
    if (GUI.WindowFlags_NoTitleBar)       then flags = flags + GUI.WindowFlags_NoTitleBar end
    if (GUI.WindowFlags_NoResize)         then flags = flags + GUI.WindowFlags_NoResize end
    if (GUI.WindowFlags_NoMove)           then flags = flags + GUI.WindowFlags_NoMove end
    if (GUI.WindowFlags_NoCollapse)       then flags = flags + GUI.WindowFlags_NoCollapse end
    if (GUI.WindowFlags_NoScrollbar)      then flags = flags + GUI.WindowFlags_NoScrollbar end
    if (GUI.WindowFlags_NoSavedSettings)  then flags = flags + GUI.WindowFlags_NoSavedSettings end

    GUI:PushStyleVar(GUI.StyleVar_WindowPadding, 5, 5)
    GUI:PushStyleVar(GUI.StyleVar_WindowMinSize, 1, 1)

    if (GUI:Begin("GilTrackerFixedBar###GilTrackerFixed", true, flags)) then
        -- Invisible button for context menu
        GUI:SetCursorPos(5, 5) -- Reset cursor to padding offset for content
        GUI:InvisibleButton("##GilTrackerClickArea", barWidth, barHeight)
        if (GUI:IsItemClicked(1)) then
            GilTracker.openContextMenu = true
        end
        GUI:SetCursorPos(5, 0)
        
        local isHovered = GUI:IsWindowHovered() or GUI:IsItemHovered()

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

            -- Tooltip on Hover
            if (isHovered and not GUI:IsPopupOpen("GilTrackerContextMenu")) then
                GUI:BeginTooltip()
                GUI:TextColored(1, 0.8, 0.2, 1, "Gil Tracker Details")
                GUI:Separator()
                
                local colWidth = 115 -- Width for tight right alignment

                -- Session Stats
                GUI:Text("Session Start:") GUI:SameLine(colWidth) GUI:Text(GilTracker.FormatNumber(GilTracker.startGil))
                GUI:Text("Current Gil:")   GUI:SameLine(colWidth) GUI:Text(GilTracker.cache.current)
                GUI:Text("Total Profit:")  GUI:SameLine(colWidth) 
                if (d > 0) then GUI:TextColored(0, 1, 0, 1, GilTracker.cache.change)
                elseif (d < 0) then GUI:TextColored(1.0, 0.4, 0.7, 1, GilTracker.cache.change)
                else GUI:Text(GilTracker.cache.change) end
                
                GUI:Separator()
                
                -- Rates
                GUI:Text("Hourly Rate:")   GUI:SameLine(colWidth) GUI:Text(GilTracker.FormatNumber(GilTracker.stats.hourlyRate) .. " /h")
                GUI:Text("Daily Rate:")    GUI:SameLine(colWidth) GUI:Text(GilTracker.FormatNumber(GilTracker.stats.dailyRate) .. " /d")
                
                GUI:Separator()
                
                -- Volatility (Swapped Up/Down)
                GUI:Text("Max Drawup:")    GUI:SameLine(colWidth) GUI:TextColored(0.4, 1, 0.4, 1, GilTracker.FormatNumber(GilTracker.stats.maxDrawup))
                GUI:Text("Max Drawdown:")  GUI:SameLine(colWidth) GUI:TextColored(1.0, 0.4, 0.7, 1, GilTracker.FormatNumber(GilTracker.FormatNumber(GilTracker.stats.maxDrawdown)))
                
                GUI:Separator()
                
                -- History (Text List)
                GUI:Text("Profit History (Last 12h)")
                if (#GilTracker.history > 0) then
                    local count = #GilTracker.history
                    local start = math.max(1, count - 11) -- Show last 12
                    for i = count, start, -1 do
                        local val = GilTracker.history[i]
                        local prefix = (val > 0 and "+") or ""
                        local color = (val > 0 and {0,1,0,1}) or (val < 0 and {1.0, 0.4, 0.7, 1}) or {1,1,1,1}
                        
                        GUI:Text(string.format("%2dh ago:", count - i))
                        GUI:SameLine(colWidth)
                        GUI:TextColored(color[1], color[2], color[3], color[4], prefix .. GilTracker.FormatNumber(val))
                    end
                else
                    GUI:Text("No history data yet...")
                end
                
                GUI:EndTooltip()
            end
        end
    end
    GUI:End()
    GUI:PopStyleVar(2) -- Pop WindowPadding and WindowMinSize

    -- Context Menu
    if (GilTracker.openContextMenu) then
        GUI:OpenPopup("GilTrackerContextMenu")
        GilTracker.openContextMenu = false
    end

    GUI:PushStyleVar(GUI.StyleVar_WindowPadding, 8, 6)
    GUI:PushStyleVar(GUI.StyleVar_WindowBorderSize, 0)
    if (GUI:BeginPopup("GilTrackerContextMenu")) then
        if (GUI:MenuItem("Reset Tracker")) then
            GilTracker.Reset()
        end
        GUI:EndPopup()
    end
    GUI:PopStyleVar(2)
end

-- Register Event
RegisterEventHandler("Gameloop.Draw", GilTracker.Draw, "GilTracker_Draw")
