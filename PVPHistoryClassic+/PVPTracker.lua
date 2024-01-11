PVP_HISTORY = PVP_HISTORY or {}

PVP_TRACKER = {}
local CURRENT_BATTLEGROUND
local BATTLEGROUND_START_TIME = nil
local SORT_DIRECTION = "ASC"  -- Global variable to toggle sorting direction
local PLAYER_FACTION, _ = UnitFactionGroup("player")  -- "Horde" or "Alliance"

local function SortByDate(a, b)
    if not a or not a.date or not b or not b.date then
        return false
    end
    if SORT_DIRECTION == "ASC" then
        return a.date < b.date
    else
        return a.date > b.date
    end
end

local function SortByName(a, b)
    if not a or not b then
        return false
    end
    if SORT_DIRECTION == "ASC" then
        return a.name < b.name
    else
        return a.name > b.name
    end
end

local function SortByKills(a, b)
    if not a or not b then
        return false
    end
    if SORT_DIRECTION == "ASC" then
        return a.kills < b.kills
    else
        return a.kills > b.kills
    end
end

local function SortByDeaths(a, b)
    if not a or not b then
        return false
    end
    if SORT_DIRECTION == "ASC" then
        return a.deaths < b.deaths
    else
        return a.deaths > b.deaths
    end
end

local function SortByDuration(a, b)
    if not a or not b then
        return false
    end
    if SORT_DIRECTION == "ASC" then
        return a.duration > b.duration
    else
        return a.duration < b.duration
    end
end

local function SortByOutCome(a, b)
    if not a or not b then
        return false
    end

    -- Convert outcomes to comparable values
    local outcomeValues = { Victory = 3, Defeat = 1, Abandoned = 2 }

    local aValue = outcomeValues[a.outcome] or 0
    local bValue = outcomeValues[b.outcome] or 0

    if SORT_DIRECTION == "ASC" then
        return aValue < bValue
    else
        return aValue > bValue
    end
end


local function IsBattlegroundZone(zoneName)
    return zoneName == "Warsong Gulch" or zoneName == "Arathi Basin" or zoneName == "Alterac Valley"
end


local function StartBattleground(zoneName)
    CURRENT_BATTLEGROUND = {
        name = zoneName,
        kills = 0,
        deaths = 0,
        date = date("%Y-%m-%d %H:%M"),  -- Get the current date and time
        endTime = nil,
        outcome = "In Progress",
        duration = 0,
        durationText = "In Progress" ,
        honorableKills = 0
    }
    BATTLEGROUND_START_TIME = GetTime() 
end


local function EndBattleground()
    if CURRENT_BATTLEGROUND then
        CURRENT_BATTLEGROUND.endTime = date("%Y-%m-%d %H:%M")  -- Get the current date and time
        -- Calculate duration in seconds
        local endTimeInSeconds = GetTime()
        CURRENT_BATTLEGROUND.duration = endTimeInSeconds - BATTLEGROUND_START_TIME
        -- Convert duration to a more readable format (e.g., minutes:seconds)
        CURRENT_BATTLEGROUND.durationText = SecondsToTime(CURRENT_BATTLEGROUND.duration)
        table.insert(PVP_HISTORY, CURRENT_BATTLEGROUND)
        CURRENT_BATTLEGROUND = nil
    end
end

local function CreateTableHeader(parent, width, height, text, anchorPoint, relativeTo, relativePoint, xOffset, yOffset)
    local header = CreateFrame("Button", nil, parent)
    header:SetSize(width, height)
    header:SetPoint(anchorPoint, relativeTo, relativePoint, xOffset, yOffset)

    header.text = header:CreateFontString(nil, "OVERLAY")
    header.text:SetFontObject("GameFontHighlight")
    header.text:SetPoint("CENTER", header, "CENTER", 0, 0)  -- Center text within the header
    header.text:SetText(text)

    header.arrow = header:CreateTexture(nil, "OVERLAY")
    header.arrow:SetSize(15, 15)
    header.arrow:SetPoint("RIGHT", -5, 0)
    header.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    header.arrow:Hide()

    -- Adjust hover effect to cover the entire header button
    header:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    local highlight = header:GetHighlightTexture()
    highlight:ClearAllPoints()  -- Clear existing points
    highlight:SetSize(width + math.abs(xOffset), height)  -- Set the size of the highlight to match the header
    highlight:SetPoint("TOPLEFT", header, "TOPLEFT", 22 + xOffset, 0)  -- Align top left point

    return header
end


local function UpdateBattlegroundHistoryFrame(frame)
    -- Clear existing rows
    for i, row in ipairs(frame.rows or {}) do
        row:Hide()
    end
    frame.rows = frame.rows or {}

    local rowHeight = 20
    local columnWidth = 120  

    for i, bg in ipairs(PVP_HISTORY) do
        local row = frame.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, frame.scrollChild)
            row:SetSize(600, rowHeight)  
            row:SetPoint("TOPLEFT", 10, -(i - 1) * rowHeight)
            frame.rows[i] = row

            -- Create text elements for each column in the row
            row.startTime = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.startTime:SetPoint("LEFT", 0, 0)
            row.startTime:SetSize(columnWidth, rowHeight)

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.name:SetPoint("LEFT", row.startTime, "RIGHT", 0, 0)
            row.name:SetSize(columnWidth, rowHeight)

            row.kills = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.kills:SetPoint("LEFT", row.name, "RIGHT", 0, 0)
            row.kills:SetSize(columnWidth, rowHeight)

            row.deaths = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.deaths:SetPoint("LEFT", row.kills, "RIGHT", 0, 0)
            row.deaths:SetSize(columnWidth, rowHeight)

            row.duration = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.duration:SetPoint("LEFT", row.deaths, "RIGHT", 0, 0)
            row.duration:SetSize(columnWidth, rowHeight)

            row.outcome = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.outcome:SetPoint("LEFT", row.duration, "RIGHT", 0, 0)
            row.outcome:SetSize(columnWidth, rowHeight)
        end

        -- Set text for each column
        row.startTime:SetText(bg.date)
        row.name:SetText(bg.name)
        row.kills:SetText(bg.kills)
        row.deaths:SetText(bg.deaths)
        row.duration:SetText(bg.durationText)
        row.outcome:SetText(bg.outcome)

        -- Color coding for outcome
        if bg.outcome == "Victory" then
            row.outcome:SetTextColor(0, 1, 0)  -- Green for victory
        elseif bg.outcome == "Defeat" then
            row.outcome:SetTextColor(1, 0, 0)  -- Red for defeat
        else
            row.outcome:SetTextColor(1, 1, 1)  -- Default color
        end

        row:Show()
    end
end

local width = 125
local frame = CreateFrame("Frame", "BattlegroundHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
local dateHeader = CreateTableHeader(frame, width, 20, "Date", "TOPLEFT", frame, "TOPLEFT", 10, -30)
local nameHeader = CreateTableHeader(frame, width, 20, "Zone", "LEFT", dateHeader, "RIGHT", 0, 0)
local killsHeader = CreateTableHeader(frame, width, 20, "Kills", "LEFT", nameHeader, "RIGHT", 0, 0)
local deathsHeader = CreateTableHeader(frame, width, 20, "Deaths", "LEFT", killsHeader, "RIGHT", -5, 0)
local durationHeader = CreateTableHeader(frame, width, 20, "Duration", "LEFT", deathsHeader, "RIGHT", -10, 0)
local outcomeHeader = CreateTableHeader(frame, width, 20, "Outcome", "LEFT", durationHeader, "RIGHT", -10, 0)


local function UpdateSortArrows(header)
    -- Hide all arrows and show the one on the active header
    for _, h in pairs({ dateHeader, nameHeader, killsHeader, deathsHeader, durationHeader }) do
        h.arrow:Hide()
    end

    header.arrow:Show()
    if SORT_DIRECTION == "ASC" then
        header.arrow:SetTexCoord(0, 0.56, 0, 1)
    else
        header.arrow:SetTexCoord(0, 0.56, 1, 0)
    end
end


local function CreateBattlegroundHistoryFrame(frame)
    frame:SetSize(755, 360)  -- Width, Height
    frame:SetPoint("CENTER")  -- Position on the screen
    frame:SetResizable(true)  -- Enable resizing
    frame:SetResizeBounds(755, 100, 755,800) 

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Battleground History")


    -- Create a resize handle
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, button)
        frame:StopMovingOrSizing()
        -- Update any necessary layout or content due to the size change
    end)

    -- Add sorting functionality to headers here

    frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", 10, -60)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
    frame.scrollChild:SetSize(470, 340)  -- Scroll child size
    frame.scrollFrame:SetScrollChild(frame.scrollChild)

    -- Create rows for data display here
    dateHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDate)
        UpdateSortArrows(dateHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)

    nameHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByName)
        UpdateSortArrows(nameHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)

    killsHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByKills)
        UpdateSortArrows(killsHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)

    deathsHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDeaths)
        UpdateSortArrows(deathsHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)

    durationHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDuration)
        UpdateSortArrows(durationHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)

    outcomeHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByOutCome)
        UpdateSortArrows(outcomeHeader)
        UpdateBattlegroundHistoryFrame(frame)
    end)
    

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    tinsert(UISpecialFrames, frame:GetName())
    frame:Hide()  -- Hide the frame initially

    return frame
end

local battlegroundHistoryFrame = CreateBattlegroundHistoryFrame(frame)
UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)

function PVP_TRACKER.UpdateBattlegroundStats()
    if CURRENT_BATTLEGROUND then
        for i = 1, GetNumBattlefieldScores() do
            local name, killingBlows, honorableKills, deaths = GetBattlefieldScore(i)
            if name == UnitName("player") then
                CURRENT_BATTLEGROUND.kills = killingBlows
                CURRENT_BATTLEGROUND.deaths = deaths
                break
            end
        end


         -- Determine the outcome based on the player's faction and the winner
        local winner = GetBattlefieldWinner()
        if winner and CURRENT_BATTLEGROUND.outcome == "In Progress" then 
            if (winner == 0 and PLAYER_FACTION == "Horde") or (winner == 1 and PLAYER_FACTION == "Alliance") then
                CURRENT_BATTLEGROUND.outcome = "Victory"
            elseif (winner == 0 and PLAYER_FACTION == "Alliance") or (winner == 1 and PLAYER_FACTION == "Horde") then
                CURRENT_BATTLEGROUND.outcome = "Defeat"
            elseif winner == 255 then
                CURRENT_BATTLEGROUND.outcome = "Draw"
            else
                CURRENT_BATTLEGROUND.outcome = "Unknown"
            end
        end
    end
end


-- Function to toggle the display of the frame
function PVP_TRACKER.ToggleBattlegroundHistory()
    if battlegroundHistoryFrame:IsShown() then
        battlegroundHistoryFrame:Hide()
    else
        UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)
        battlegroundHistoryFrame:Show()
    end
end

-- Add a slash command to toggle the battleground history frame
SLASH_PVPHISTORY1 = "/pvphistory"
SlashCmdList["PVPHISTORY"] = PVP_TRACKER.ToggleBattlegroundHistory

function PVP_TRACKER.OnPlayerLogout()
    if CURRENT_BATTLEGROUND then
        PVP_TRACKER.UpdateBattlegroundStats()
        EndBattleground()
    end
end

function PVP_TRACKER.OnPlayerEnteringWorld()
    local zoneName = GetRealZoneText()
    if IsBattlegroundZone(zoneName) then
        if CURRENT_BATTLEGROUND then 
            PVP_TRACKER.UpdateBattlegroundStats()
            EndBattleground()
        else
        StartBattleground(zoneName)
        end
    else
        if CURRENT_BATTLEGROUND then
            PVP_TRACKER.UpdateBattlegroundStats()
            EndBattleground()
        end
    end
end

