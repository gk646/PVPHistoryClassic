PVP_HISTORY = PVP_HISTORY or {}

PVP_TRACKER = {}
PVP_TRACKER.PLAYER_FACTION_STRING = UnitFactionGroup("player")

local CURRENT_BATTLEGROUND
local BATTLEGROUND_START_TIME = nil
local TEMPORARY_PLAYER_FACTION = nil
local IS_FIRST_ZONE = true

local function IsBattlegroundZone(zoneName)
    return zoneName == "Warsong Gulch" or zoneName == "Arathi Basin" or zoneName == "Alterac Valley"
end
local function SaveTeamComposition()
    local playerName = UnitName("player")
    for i = 1, GetNumBattlefieldScores() do
        local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, _, class = GetBattlefieldScore(i)

        -- Skip if the current entry is the player
        if name ~= playerName then
            -- Build team composition
            local team = faction == 0 and "Horde" or "Alliance"
            table.insert(CURRENT_BATTLEGROUND.teamComposition[team], {
                name = name,
                class = class,
                kills = killingBlows,
                deaths = deaths,
                honorableKills = honorableKills,
                rank = rank
            })
        end
    end
end
function PVP_TRACKER.OnCombatLogEventUnfiltered()
    -- Logic to detect honor kills and estimate honor gains
    -- Update CURRENT_BATTLEGROUND.honorGained
end
local function StartBattleground(zoneName)
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")

    CURRENT_BATTLEGROUND = {
        name = zoneName,
        date = date("%Y-%m-%d %H:%M"),
        duration = 0,
        durationText = nil,
        outcome = "In Progress",
        deaths = 0,
        honorableKills = 0,
        honorGained = 0,
        killingBlows = 0,
        currentRank = 0,
        teamComposition = { Horde = {}, Alliance = {} },
        playerName = playerName,
        playerClass = playerClass
    }
    BATTLEGROUND_START_TIME = GetTime()
end
local function EndBattleground()
    if CURRENT_BATTLEGROUND then
        local endTimeInSeconds = GetTime()
        CURRENT_BATTLEGROUND.duration = endTimeInSeconds - BATTLEGROUND_START_TIME
        CURRENT_BATTLEGROUND.durationText = SecondsToTime(CURRENT_BATTLEGROUND.duration)
        table.insert(PVP_HISTORY, CURRENT_BATTLEGROUND)
        CURRENT_BATTLEGROUND = nil
    else
        CURRENT_BATTLEGROUND = nil
    end
end

battlegroundHistoryFrame = FRAME_UI.CreateBattlegroundHistoryFrame(frame)
FRAME_UI.UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)

function PVP_TRACKER.OnUpdateBattlefieldStatus(battleFieldIndex)
    local status, mapName, instanceID = GetBattlefieldStatus(battleFieldIndex)

    if status == "active" and CURRENT_BATTLEGROUND and CURRENT_BATTLEGROUND.name == mapName then
        local winner = GetBattlefieldWinner()
        if winner then
            PVP_TRACKER.UpdateBattlegroundStats()
            EndBattleground()
        end
    end
end
function PVP_TRACKER.UpdateBattlegroundStats()
    if CURRENT_BATTLEGROUND then
        local playerName = UnitName("player")
        for i = 1, GetNumBattlefieldScores() do
            local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class = GetBattlefieldScore(i)

            -- Update player's own stats
            if name == playerName then
                CURRENT_BATTLEGROUND.killingBlows = killingBlows
                CURRENT_BATTLEGROUND.deaths = deaths
                CURRENT_BATTLEGROUND.honorableKills = honorableKills
                CURRENT_BATTLEGROUND.honorGained = honorGained
                CURRENT_BATTLEGROUND.currentRank = rank
                TEMPORARY_PLAYER_FACTION = faction
                break
            end
        end

        local winner = GetBattlefieldWinner()
        if winner and CURRENT_BATTLEGROUND.outcome == "In Progress" then
            SaveTeamComposition()
            if (winner == 0 and TEMPORARY_PLAYER_FACTION == 0) or (winner == 1 and TEMPORARY_PLAYER_FACTION == 1) then
                CURRENT_BATTLEGROUND.outcome = "Victory"
            elseif (winner == 0 and TEMPORARY_PLAYER_FACTION == 1) or (winner == 1 and TEMPORARY_PLAYER_FACTION == 0) then
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
        FRAME_UI.UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)
        battlegroundHistoryFrame:Show()
    end
end

-- Add a slash command to toggle the battleground history frame
SLASH_PVPHISTORY1 = "/pvphistory"
SlashCmdList[SLASH_PVPHISTORY1] = PVP_TRACKER.ToggleBattlegroundHistory

function PVP_TRACKER.OnPlayerLogout()
    if CURRENT_BATTLEGROUND then
        PVP_TRACKER.UpdateBattlegroundStats()
        EndBattleground()
    end
end
function PVP_TRACKER.OnPlayerChangingZone()
    local zoneName = GetRealZoneText()
    if IsBattlegroundZone(zoneName) then
        if IS_FIRST_ZONE then
            local lastEntry = PVP_HISTORY[#PVP_HISTORY]
            if lastEntry.outcome == "In Progress" then
                CURRENT_BATTLEGROUND = lastEntry
                return
            end
        end
        if CURRENT_BATTLEGROUND then
            PVP_TRACKER.UpdateBattlegroundStats()
            EndBattleground()
            StartBattleground(zoneName)
        else
            StartBattleground(zoneName)
        end
    else
        if CURRENT_BATTLEGROUND then
            PVP_TRACKER.UpdateBattlegroundStats()
            EndBattleground()
        end
    end
    IS_FIRST_ZONE = false
end

