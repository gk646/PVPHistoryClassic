FRAME_UI = {}

frame = CreateFrame("Frame", "BattlegroundHistoryFrame", UIParent, "BasicFrameTemplateWithInset")
local SORT_DIRECTION = "ASC"  -- Global variable to toggle sorting direction
local function CreateTextString(parent, font, point, relativeTo, relativePoint, xOff, yOff, text)
    local textString = parent:CreateFontString(nil, "OVERLAY", font)
    textString:SetPoint(point, relativeTo, relativePoint, xOff, yOff)
    textString:SetText(text)
    textString:Hide()  -- Initially hide the text
    return textString
end
local function GenericSort(a, b, key, isNumeric)
    if not a or not b or not a[key] or not b[key] then
        return false
    end

    if isNumeric then
        -- For numeric values, higher numbers can be considered 'greater'
        if SORT_DIRECTION == "ASC" then
            return a[key] > b[key]
        else
            return a[key] < b[key]
        end
    else
        -- For non-numeric values, use standard Lua string comparison
        if SORT_DIRECTION == "ASC" then
            return tostring(a[key]) < tostring(b[key])
        else
            return tostring(a[key]) > tostring(b[key])
        end
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
local function FormatTime(totalSeconds)
    local seconds = totalSeconds % 60
    local totalMinutes = math.floor(totalSeconds / 60)
    local minutes = totalMinutes % 60
    local totalHours = math.floor(totalMinutes / 60)
    local hours = totalHours % 24
    local days = math.floor(totalHours / 24)

    if days > 0 then
        return string.format("%dd:%02dh:%02dm:%02ds", days, hours, minutes, seconds)
    else
        return string.format("%02dh:%02dm", hours, minutes)
    end
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
local function AddSortingFunctions(baseFrame)
    local function SortData(key, isNumeric)
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, function(a, b)
            return GenericSort(a, b, key, isNumeric)
        end)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end
    dateHeader:SetScript("OnClick", function()
        SortData("date", false)
        UpdateSortArrows(dateHeader)
    end)

    nameHeader:SetScript("OnClick", function()
        SortData("name", false)
        UpdateSortArrows(nameHeader)
    end)

    killsHeader:SetScript("OnClick", function()
        SortData("kills", true)
        UpdateSortArrows(killsHeader)
    end)

    deathsHeader:SetScript("OnClick", function()
        SortData("deaths", true)
        UpdateSortArrows(deathsHeader)
    end)

    durationHeader:SetScript("OnClick", function()
        SortData("duration", true)
        UpdateSortArrows(durationHeader)
    end)

    outcomeHeader:SetScript("OnClick", function()
        -- Assuming outcome sorting is special and uses SortByOutCome
        SORT_DIRECTION = SORT_DIRECTION == "ASC" and "DESC" or "ASC"
        table.sort(PVP_HISTORY, SortByOutCome)
        UpdateSortArrows(outcomeHeader)
    end)
end
local function CalculateBattlegroundStatsAndTotals(filteredList)
    local totalKills, totalDeaths, totalWins, totalHonorableKills, totalDuration, totalBattles, totalHonorGained = 0, 0, 0, 0, 0, 0, 0

    for _, bg in ipairs(filteredList) do
        totalBattles = totalBattles + 1
        totalHonorGained = totalHonorGained + (bg.honorGained or 0)
        totalKills = totalKills + (bg.kills or 0)
        totalDeaths = totalDeaths + (bg.deaths or 0)
        totalHonorableKills = totalHonorableKills + (bg.honorableKills or 0)
        totalDuration = totalDuration + (bg.duration or 0)

        if bg.outcome == "Victory" then
            totalWins = totalWins + 1
        end
    end

    local avgKills = totalBattles > 0 and totalKills / totalBattles or 0
    local avgDeaths = totalBattles > 0 and totalDeaths / totalBattles or 0
    local avgHonorableKills = totalBattles > 0 and totalHonorableKills / totalBattles or 0
    local avgDuration = totalBattles > 0 and totalDuration / totalBattles or 0
    local winRate = totalBattles > 0 and (totalWins / totalBattles) * 100 or 0
    local avgHonor = totalHonorGained > 0 and totalHonorGained / totalBattles or 0

    return avgKills, avgDeaths, avgHonorableKills, avgDuration, winRate, totalKills, totalDeaths, totalHonorableKills, totalDuration, totalBattles, avgHonor, totalHonorGained
end
local function AddDiagramPlaceholders(baseFrame)
    -- Line Chart Placeholder
    baseFrame.lineChartPlaceholder = CreateFrame("Frame", nil, baseFrame)
    baseFrame.lineChartPlaceholder:SetSize(250, 150)  -- Adjusted size
    baseFrame.lineChartPlaceholder:SetPoint("TOPRIGHT", baseFrame, "TOPRIGHT", -30, -40)
    baseFrame.lineChartPlaceholder:Hide()  -- Initially hidden

    -- Class Distribution Placeholder
    baseFrame.classDistributionPlaceholder = CreateFrame("Frame", nil, baseFrame)
    baseFrame.classDistributionPlaceholder:SetSize(250, 150)  -- Adjusted size
    baseFrame.classDistributionPlaceholder:SetPoint("TOPRIGHT", baseFrame.lineChartPlaceholder, "BOTTOMRIGHT", 0, -30)
    baseFrame.classDistributionPlaceholder:Hide()  -- Initially hidden

    -- Texture for Line Chart Placeholder
    local texture = baseFrame.lineChartPlaceholder:CreateTexture()
    texture:SetAllPoints(true)
    texture:SetColorTexture(0.3, 0.3, 0.3, 0.7)  -- Grey color

    -- Texture for Class Distribution Placeholder
    local texture2 = baseFrame.classDistributionPlaceholder:CreateTexture()
    texture2:SetAllPoints(true)
    texture2:SetColorTexture(0.3, 0.3, 0.3, 0.7)  -- Grey color
end

local function AddStatisticsText(baseFrame)
    local indent = 20  -- Indentation for items within a category
    local categorySpacing = 30  -- Vertical space between categories

    -- Averages per Match Category
    baseFrame.categoryHeader = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame, "TOPLEFT", 20, -40, "Averages per Match:")
    baseFrame.averageKillingBlowsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.categoryHeader, "BOTTOMLEFT", indent, -10, "Average Killing Blows: ")
    baseFrame.averageHonorableKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageKillingBlowsText, "BOTTOMLEFT", 0, -10, "Average Honorable Kills: ")
    baseFrame.averageDeathsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageHonorableKillsText, "BOTTOMLEFT", 0, -10, "Average Deaths: ")
    baseFrame.averageDurationText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageDeathsText, "BOTTOMLEFT", 0, -10, "Average Duration: ")
    baseFrame.averageHonourText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.averageDurationText, "BOTTOMLEFT", 0, -10, "Average Honour: ")

    -- Totals Category
    baseFrame.totalsCategoryHeader = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame.averageHonourText, "BOTTOMLEFT", -20, -categorySpacing, "Totals:")
    baseFrame.winRateText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalsCategoryHeader, "BOTTOMLEFT", indent, -10, "Winrate: ")
    baseFrame.totalKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.winRateText, "BOTTOMLEFT", 0, -10, "Kills: ")
    baseFrame.totalDeathsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalKillsText, "BOTTOMLEFT", 0, -10, "Deaths: ")
    baseFrame.totalHonorableKillsText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalDeathsText, "BOTTOMLEFT", 0, -10, "Honorable Kills: ")
    baseFrame.timeInsideText = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.totalHonorableKillsText, "BOTTOMLEFT", 0, -10, "Time Inside: ")
    baseFrame.totalHonorGained = CreateTextString(baseFrame, "GameFontNormal", "TOPLEFT", baseFrame.timeInsideText, "BOTTOMLEFT", 0, -10, "Honor: ")

    baseFrame.totalEntries = CreateTextString(baseFrame, "GameFontNormalLarge", "TOPLEFT", baseFrame, "TOPLEFT", 250, -35, "Total Entries: ")
end
local function AddSecondTab(baseFrame)
    AddStatisticsText(baseFrame)
    AddDiagramPlaceholders(baseFrame)
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

    bgFrame.categoryHeader:SetShown(isStatsTab)
    bgFrame.averageKillingBlowsText:SetShown(isStatsTab)
    bgFrame.averageHonorableKillsText:SetShown(isStatsTab)
    bgFrame.averageDeathsText:SetShown(isStatsTab)
    bgFrame.averageDurationText:SetShown(isStatsTab)
    bgFrame.averageHonourText:SetShown(isStatsTab)

    bgFrame.totalsCategoryHeader:SetShown(isStatsTab)
    bgFrame.winRateText:SetShown(isStatsTab)
    bgFrame.totalKillsText:SetShown(isStatsTab)
    bgFrame.totalDeathsText:SetShown(isStatsTab)
    bgFrame.totalHonorableKillsText:SetShown(isStatsTab)
    bgFrame.timeInsideText:SetShown(isStatsTab)
    bgFrame.totalHonorGained:SetShown(isStatsTab)
    bgFrame.totalEntries:SetShown(isStatsTab)

    bgFrame.lineChartPlaceholder:SetShown(isStatsTab)
    bgFrame.classDistributionPlaceholder:SetShown(isStatsTab)
end
local function AddResizeHandler(baseFrame)
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
    end)

    resizeHandle:SetScript("OnEnter", function(self)
        SetCursor("Interface\\CURSOR\\openhandglow")
    end)

    resizeHandle:SetScript("OnLeave", function(self)
        ResetCursor()
    end)

end
local function GetFilteredHistory(totalHistory)
    return totalHistory
end
function FRAME_UI.UpdateBattlegroundHistoryFrame(battleGroundFrame)
    UpdateTabVisibility(battleGroundFrame.selectedTab, battleGroundFrame)
    local isHistoryTab = battleGroundFrame.selectedTab == 1
    local isStatsTab = battleGroundFrame.selectedTab == 2
    if isHistoryTab then
        -- Clear existing rows
        for i, row in ipairs(battleGroundFrame.rows or {}) do
            row:Hide()
        end
        battleGroundFrame.rows = battleGroundFrame.rows or {}

        local rowHeight = 20
        local columnWidth = 120

        for i, bg in ipairs(GetFilteredHistory(PVP_HISTORY)) do
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
    elseif isStatsTab then
        local avgKills, avgDeaths, avgHonorableKills, avgDuration, winRate, totalKills, totalDeaths, totalHonorableKills, totalTimeInside, totalEntries, avgHonour, totalHonour = CalculateBattlegroundStatsAndTotals(GetFilteredHistory(PVP_HISTORY))

        -- Format duration as minutes:seconds
        local avgDurationFormatted = string.format("%d:%02d", math.floor(avgDuration / 60), avgDuration % 60)
        battleGroundFrame.totalEntries:SetText("Total Entries: " .. totalEntries)

        battleGroundFrame.averageKillingBlowsText:SetText("Killing Blows: " .. string.format("%.2f", avgKills))
        battleGroundFrame.averageHonorableKillsText:SetText("Honorable Kills: " .. string.format("%.2f", avgHonorableKills))
        battleGroundFrame.averageDeathsText:SetText("Deaths: " .. string.format("%.2f", avgDeaths))
        battleGroundFrame.averageDurationText:SetText("Duration: " .. avgDurationFormatted)
        battleGroundFrame.averageHonourText:SetText("Honor: " .. avgHonour)

        battleGroundFrame.winRateText:SetText("Winrate: " .. string.format("%.2f%%", winRate))
        battleGroundFrame.totalKillsText:SetText("Kills: " .. totalKills)
        battleGroundFrame.totalDeathsText:SetText("Deaths: " .. totalDeaths)
        battleGroundFrame.totalHonorableKillsText:SetText("Honorable Kills: " .. totalHonorableKills)
        battleGroundFrame.timeInsideText:SetText("Time Inside: " .. FormatTime(totalTimeInside))  -- FormatTime should convert seconds to a readable format
        battleGroundFrame.totalHonorGained:SetText("Honour: " .. totalHonour)  -- FormatTime should convert seconds to a readable format
    end

end
function FRAME_UI.CreateBattlegroundHistoryFrame(baseFrame)
    baseFrame:SetSize(755, 400)  -- Width, Height
    baseFrame:SetPoint("CENTER")  -- Position on the screen
    baseFrame:SetResizable(true)  -- Enable resizing
    baseFrame:SetResizeBounds(755, 400, 755, 800) -- Minimum Resize Bounds

    baseFrame.title = baseFrame:CreateFontString(nil, "OVERLAY")
    baseFrame.title:SetFontObject("GameFontHighlight")
    baseFrame.title:SetPoint("LEFT", baseFrame.TitleBg, "LEFT", 5, 0)
    baseFrame.title:SetText("Battleground History")

    -- Create a resize handle
    AddResizeHandler(baseFrame)

    -- Add sorting functionality to headers here
    AddSortingFunctions(baseFrame)

    baseFrame.scrollFrame = CreateFrame("ScrollFrame", nil, baseFrame, "UIPanelScrollFrameTemplate")
    baseFrame.scrollFrame:SetPoint("TOPLEFT", 10, -60)
    baseFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    baseFrame.scrollChild = CreateFrame("Frame", nil, baseFrame.scrollFrame)
    baseFrame.scrollChild:SetSize(470, 340)  -- Scroll child size
    baseFrame.scrollFrame:SetScrollChild(baseFrame.scrollChild)

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
        baseFrame.selectedTab = 1
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
    end)
    tab2:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 2)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
        baseFrame.selectedTab = 2
    end)
    tab3:SetScript("OnClick", function()
        PanelTemplates_SetTab(baseFrame, 3)
        FRAME_UI.UpdateBattlegroundHistoryFrame(baseFrame)
        baseFrame.selectedTab = 3
    end)
    baseFrame.selectedTab = 1

    -- Initialize Tabs
    PanelTemplates_SetNumTabs(baseFrame, 3)
    PanelTemplates_SetTab(baseFrame, 1)
    UpdateTabVisibility(1, baseFrame)

    tinsert(UISpecialFrames, baseFrame:GetName())
    baseFrame:Hide()  -- Hide the frame initially

    return baseFrame
end