PVP_HISTORY = PVP_HISTORY or {}

PVP_TRACKER = {}
local CURRENT_BATTLEGROUND
local BATTLEGROUND_START_TIME = nil
local PLAYER_FACTION = nil

local function IsBattlegroundZone(zoneName)
    return zoneName == "Warsong Gulch" or zoneName == "Arathi Basin" or zoneName == "Alterac Valley"
end

local function SaveTeamComposition()
    for i = 1, GetNumBattlefieldScores() do
        local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, _, class = GetBattlefieldScore(i)

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

local function StartBattleground(zoneName)
    print("started")
    CURRENT_BATTLEGROUND = {
        name = zoneName,
        date = date("%Y-%m-%d %H:%M"),
        duration = 0,
        durationText = nil,
        outcome = "In Progress",
        kills = 0,
        deaths = 0,
        honorableKills = 0,
        killingBlows = 0,
        teamComposition = { Horde = {}, Alliance = {} }
    }
    BATTLEGROUND_START_TIME = GetTime()
end

local function EndBattleground()
    if CURRENT_BATTLEGROUND then
        print("ended")
        local endTimeInSeconds = GetTime()
        CURRENT_BATTLEGROUND.duration = endTimeInSeconds - BATTLEGROUND_START_TIME
        CURRENT_BATTLEGROUND.durationText = SecondsToTime(CURRENT_BATTLEGROUND.duration)
        table.insert(PVP_HISTORY, CURRENT_BATTLEGROUND)
        CURRENT_BATTLEGROUND = nil
    else
        print("Error!")
    end
end

local battlegroundHistoryFrame = FRAME_UI.CreateBattlegroundHistoryFrame(frame)
FRAME_UI.UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)

function PVP_TRACKER.UpdateBattlegroundStats()
    if CURRENT_BATTLEGROUND then
        for i = 1, GetNumBattlefieldScores() do
            local name, killingBlows, honorableKills, deaths, honorGained, faction, rank, _, class = GetBattlefieldScore(i)

            -- Update player's own stats
            if name == UnitName("player") then
                CURRENT_BATTLEGROUND.kills = killingBlows
                CURRENT_BATTLEGROUND.deaths = deaths
                CURRENT_BATTLEGROUND.honorableKills = honorableKills
                CURRENT_BATTLEGROUND.honorGained = honorGained
                PLAYER_FACTION = faction
                break
            end
        end

        -- Determine the outcome based on the player's faction and the winner
        local winner = GetBattlefieldWinner()
        print("Winner: " .. tostring(winner) .. ", Player Faction: " .. tostring(PLAYER_FACTION))
        if winner and CURRENT_BATTLEGROUND.outcome == "In Progress" then
            SaveTeamComposition()
            if (winner == 0 and PLAYER_FACTION == 0) or (winner == 1 and PLAYER_FACTION == 1) then
                CURRENT_BATTLEGROUND.outcome = "Victory"
            elseif (winner == 0 and PLAYER_FACTION == 1) or (winner == 1 and PLAYER_FACTION == 0) then
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
end

