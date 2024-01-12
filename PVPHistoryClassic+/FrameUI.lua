FRAME_UI = {}

frame = CreateFrame("Frame", "BattlegroundHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
local SORT_DIRECTION = "ASC"  -- Global variable to toggle sorting direction

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
        return a.kills > b.kills
    else
        return a.kills < b.kills
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
    highlight:ClearAllPoints()
    highlight:SetSize(width + math.abs(xOffset), height)  -- Set the size of the highlight to match the header
    highlight:SetPoint("TOPLEFT", header, "TOPLEFT", 22 + xOffset, 0)  -- Align top left point

    return header
end

local width = 125
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

local function AddSecondTab(baseFrame)
    baseFrame.statsTitle = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    baseFrame.statsTitle:SetPoint("TOP", baseFrame, "TOP", 0, -40)
    baseFrame.statsTitle:SetText("Battleground Statistics")

    baseFrame.averageKillsText = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    baseFrame.averageKillsText:SetPoint("TOPLEFT", baseFrame.statsTitle, "BOTTOMLEFT", 0, -20)

    baseFrame.averageDeathsText = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    baseFrame.averageDeathsText:SetPoint("TOPLEFT", baseFrame.averageKillsText, "BOTTOMLEFT", 0, -10)

    baseFrame.winRateText = baseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    baseFrame.winRateText:SetPoint("TOPLEFT", baseFrame.averageDeathsText, "BOTTOMLEFT", 0, -10)

    -- Initially hide the statistics text
    baseFrame.statsTitle:Hide()
    baseFrame.averageKillsText:Hide()
    baseFrame.averageDeathsText:Hide()
    baseFrame.winRateText:Hide()

end

local function CalculateBattlegroundStats()
    local totalKills, totalDeaths, totalWins, totalBattles = 0, 0, 0, #PVP_HISTORY
    for _, bg in ipairs(PVP_HISTORY) do
        totalKills = totalKills + bg.kills
        totalDeaths = totalDeaths + bg.deaths
        if bg.outcome == "Victory" then
            totalWins = totalWins + 1
        end
    end

    local averageKills = totalBattles > 0 and totalKills / totalBattles or 0
    local averageDeaths = totalBattles > 0 and totalDeaths / totalBattles or 0
    local winRate = totalBattles > 0 and (totalWins / totalBattles) * 100 or 0

    return averageKills, averageDeaths, winRate
end

local function UpdateTabVisibility(selectedTab, bgFrame)
    local isHistoryTab = selectedTab == 1
    local isStatsTab = selectedTab == 2

    -- Show or hide headers based on the selected tab
    dateHeader:SetShown(isHistoryTab)
    nameHeader:SetShown(isHistoryTab)
    killsHeader:SetShown(isHistoryTab)
    deathsHeader:SetShown(isHistoryTab)
    durationHeader:SetShown(isHistoryTab)
    outcomeHeader:SetShown(isHistoryTab)

    for i, row in ipairs(bgFrame.rows or {}) do
        row:SetShown(isHistoryTab)
    end

    bgFrame.statsTitle:SetShown(isStatsTab)
    bgFrame.averageKillsText:SetShown(isStatsTab)
    bgFrame.averageDeathsText:SetShown(isStatsTab)
    bgFrame.winRateText:SetShown(isStatsTab)

    if isStatsTab then
        local avgKills, avgDeaths, winRate = CalculateBattlegroundStats()
        bgFrame.averageKillsText:SetText("Average Kills: " .. string.format("%.2f", avgKills))
        bgFrame.averageDeathsText:SetText("Average Deaths: " .. string.format("%.2f", avgDeaths))
        bgFrame.winRateText:SetText("Win Rate: " .. string.format("%.2f%%", winRate))
    end
end

function FRAME_UI.UpdateBattlegroundHistoryFrame(battleGroundFrame)
    -- Clear existing rows
    for i, row in ipairs(battleGroundFrame.rows or {}) do
        row:Hide()
    end
    battleGroundFrame.rows = battleGroundFrame.rows or {}

    local rowHeight = 20
    local columnWidth = 120

    for i, bg in ipairs(PVP_HISTORY) do
        local row = battleGroundFrame.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, battleGroundFrame.scrollChild)
            row:SetSize(600, rowHeight)
            row:SetPoint("TOPLEFT", 10, -(i - 1) * rowHeight)
            battleGroundFrame.rows[i] = row

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

function FRAME_UI.CreateBattlegroundHistoryFrame(baseFrame)
    baseFrame:SetSize(755, 360)  -- Width, Height
    baseFrame:SetPoint("CENTER")  -- Position on the screen
    baseFrame:SetResizable(true)  -- Enable resizing
    baseFrame:SetResizeBounds(755, 100, 755, 800)

    baseFrame.title = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.title:SetFontObject("GameFontHighlight")
    baseFrame.title:SetPoint("LEFT", baseFrame.TitleBg, "LEFT", 5, 0)
    baseFrame.title:SetText("Battleground History")


    -- Create a resize handle
    local resizeHandle = CreateFrame("Button", nil, baseFrame)
    resizeHandle:SetPoint("BOTTOMRIGHT", baseFrame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            baseFrame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, button)
        baseFrame:StopMovingOrSizing()
        -- Update any necessary layout or content due to the size change
    end)

    -- Add sorting functionality to headers here

    baseFrame.scrollFrame = CreateFrame("ScrollFrame", nil, baseFrame, "UIPanelScrollFrameTemplate")
    baseFrame.scrollFrame:SetPoint("TOPLEFT", 10, -60)
    baseFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    baseFrame.scrollChild = CreateFrame("Frame", nil, baseFrame.scrollFrame)
    baseFrame.scrollChild:SetSize(470, 340)  -- Scroll child size
    baseFrame.scrollFrame:SetScrollChild(baseFrame.scrollChild)

    -- Create rows for data display here
    dateHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDate)
        UpdateSortArrows(dateHeader)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    nameHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByName)
        UpdateSortArrows(nameHeader)
        FRAME_UI. UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    killsHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByKills)
        UpdateSortArrows(killsHeader)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    deathsHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDeaths)
        UpdateSortArrows(deathsHeader)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    durationHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByDuration)
        UpdateSortArrows(durationHeader)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    outcomeHeader:SetScript("OnClick", function()
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByOutCome)
        UpdateSortArrows(outcomeHeader)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)

    baseFrame:SetMovable(true)
    baseFrame:EnableMouse(true)
    baseFrame:RegisterForDrag("LeftButton")
    baseFrame:SetScript("OnDragStart", baseFrame.StartMoving)
    baseFrame:SetScript("OnDragStop", baseFrame.StopMovingOrSizing)

    AddSecondTab(baseFrame)

    -- Create Tabs
    local tab1 = CreateFrame("Button", "$parentTab1", baseFrame, "CharacterFrameTabButtonTemplate")
    tab1:SetPoint("BOTTOMLEFT", baseFrame, "BOTTOMLEFT", 5, -27)
    tab1:SetText("History")
    tab1:SetID(1)

    local tab2 = CreateFrame("Button", "$parentTab2", baseFrame, "CharacterFrameTabButtonTemplate")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -14, 0)
    tab2:SetText("Stats")
    tab2:SetID(2)

    local tab3 = CreateFrame("Button", "$parentTab3", baseFrame, "CharacterFrameTabButtonTemplate")
    tab3:SetPoint("LEFT", tab2, "RIGHT", -14, 0)
    tab3:SetText("Info")
    tab3:SetID(3)

    -- Tab Scripts
    tab1:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 1)
        UpdateTabVisibility(1,baseFrame)
    end)
    tab2:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 2)
        UpdateTabVisibility(2,baseFrame)
    end)
    tab3:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 3)
        UpdateTabVisibility(3,baseFrame)
    end)

    -- Initialize Tabs
    PanelTemplates_SetNumTabs(baseFrame, 3)
    PanelTemplates_SetTab(baseFrame, 1)
    UpdateTabVisibility(1,baseFrame)


    tinsert(UISpecialFrames, baseFrame:GetName())
    baseFrame:Hide()  -- Hide the frame initially

    return baseFrame
end