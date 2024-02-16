MinimapButtonDB = MinimapButtonDB or {}
MinimapButtonDB.lockDistance = true

-- Main event handling
mainFrame = CreateFrame("Frame")

mainFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
mainFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
mainFrame:RegisterEvent("ADDON_LOADED")

mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        PVP_TRACKER.OnPlayerChangingZone()
    elseif event == "PLAYER_LOGOUT" then
        PVP_TRACKER.OnPlayerLogout()
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        PVP_TRACKER.UpdateBattlegroundStats()
    elseif even == "COMBAT_LOG_EVENT_UNFILTERED" then
        PVP_TRACKER.OnCombatLogEventUnfiltered(...)
    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        local battleFieldIndex = ...
        PVP_TRACKER.OnUpdateBattlefieldStatus(battleFieldIndex)
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "PVPHistoryClassic+" then
            battlegroundHistoryFrame = FRAME_UI.CreateBattlegroundHistoryFrame(frame)
            FRAME_UI.UpdateBattlegroundHistoryFrame(battlegroundHistoryFrame)
            MinimapButton.Init(MinimapButtonDB, "Interface\\Icons\\Ability_Warrior_OffensiveStance",
                    function(self, button)
                        if button == "LeftButton" then
                            PVP_TRACKER.ToggleBattlegroundHistory()
                        end
                    end,
                    "PVPHistoryClassic+"
            )
        end
    end
end)


-- Add a slash command to toggle the battleground history mainFrame
SLASH_PVPHISTORY1 = "/pvphistory"
SlashCmdList["PVPHISTORY"] = PVP_TRACKER.ToggleBattlegroundHistory
