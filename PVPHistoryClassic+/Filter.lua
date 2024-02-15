FILTER = {}

filter = {
    charNames = { [UnitName("player")] = true },
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
    updateNumericFilterFromInput(filterPanel.currentRankInput, filterPanel.currentRankToggleButton, "currentRank")
    updateNumericFilterFromInput(filterPanel.durationInput, filterPanel.durationToggleButton, "duration")

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

-- Function to clear the filter, resetting fields to nil except for charName
function FILTER.Clear()
    filter.charName = UnitName("player") -- Reset charName to the current character's name
    filter.zoneName = nil
    filter.duration = nil
    filter.outcome = nil
    filter.kills = nil
    filter.deaths = nil
    filter.honorableKills = nil
    filter.honorGained = nil
    filter.killingBlows = nil
    filter.currentRank = nil
end

