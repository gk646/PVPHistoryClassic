FILTER = {}

filter = {
    charNames = {},
    zoneNames = {},
    outcomes = {},
    duration = { value = nil, lowerBound = true },
    killingBlows = { value = nil, lowerBound = true },
    deaths = { value = nil, lowerBound = true },
    honorableKills = { value = nil, lowerBound = true },
    honorGained = { value = nil, lowerBound = true },
    currentRank = { value = nil, lowerBound = true },
}

-- Handle numeric input fields with toggle for comparison bounds
local function updateNumericFilterFromInput(inputField, toggleButton, filterField)
    local value = tonumber(inputField:GetText())
    local lowerBound = toggleButton:GetText() == "<"
    filter[filterField].value = value
    filter[filterField].lowerBound = lowerBound
end

-- Sets the values from the filterPanel
function FILTER.SetValue(filterPanel)
    updateNumericFilterFromInput(filterPanel.killingBlowsInput, filterPanel.killingBlowsToggleButton, "killingBlows")
    updateNumericFilterFromInput(filterPanel.deathsInput, filterPanel.deathsToggleButton, "deaths")
    updateNumericFilterFromInput(filterPanel.honorableKillsInput, filterPanel.honorableKillsToggleButton, "honorableKills")
    updateNumericFilterFromInput(filterPanel.honorGainedInput, filterPanel.honorGainedToggleButton, "honorGained")
    updateNumericFilterFromInput(filterPanel.durationInput, filterPanel.durationToggleButton, "duration")

    local num = tonumber(filterPanel.currentRankInput:GetText())
    if num then
        filter["currentRank"].value =  num + 4
    end
    filter["currentRank"].lowerBound = filterPanel.currentRankToggleButton:GetText() == "<"
end

local function checkNumericField(field, battlegroundValue)
    if not field.value then
        return true  -- If no filter is set, accept by default
    end
    if field.lowerBound then
        return battlegroundValue < field.value
    else
        return battlegroundValue > field.value
    end
end

-- Function to check if a battleground object matches the filter criteria
function FILTER.IsAccepted(battleground)
    if next(filter.charNames) and not filter.charNames[battleground.playerName] then
        return false
    end
    if next(filter.zoneNames) and not filter.zoneNames[battleground.name] then
        return false
    end
    if next(filter.outcomes) and not filter.outcomes[battleground.outcome] then
        return false
    end

    if not checkNumericField(filter.deaths, battleground.deaths) then
        return false
    end
    if not checkNumericField(filter.honorableKills, battleground.honorableKills) then
        return false
    end
    if not checkNumericField(filter.honorGained, battleground.honorGained) then
        return false
    end
    if not checkNumericField(filter.killingBlows, battleground.killingBlows) then
        return false
    end
    if not checkNumericField(filter.currentRank, battleground.currentRank) then
        return false
    end
    if not checkNumericField(filter.duration, battleground.duration) then
        return false
    end

    return true
end

function RefreshDropdown(dropdown, name, items)
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.isNotRadio = true
        info.keepShownOnClick = true
        for _, v in ipairs(items) do
            info.text = v
            info.checked = filter[name][v] or false
            info.func = function(self)
                filter[name][v] = not filter[name][v]
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
end

-- Function to clear the filter, resetting fields to nil except for charName
function FILTER.Clear(sidePanel)
    for key in pairs(filter.charNames) do
        filter.charNames[key] = nil
    end

    for key in pairs(filter.zoneNames) do
        filter.zoneNames[key] = nil
    end

    for key in pairs(filter.outcomes) do
        filter.outcomes[key] = nil
    end

    -- Reset numeric filters
    local numericFields = { "duration", "kills", "deaths", "honorableKills", "honorGained", "killingBlows", "currentRank" }
    for _, field in ipairs(numericFields) do
        if filter[field] then
            filter[field].value = nil
            if sidePanel[field .. "Input"] then
                sidePanel[field .. "Input"]:SetText("")
            end
        end
    end

    filter["charNames"][UnitName("player")] = true
    for _, v in ipairs(outcomeItems) do
        filter["outcomes"][v] = true
    end
    for _, v in ipairs(zoneNameItems) do
        filter["zoneNames"][v] = true
    end
end

