-- Main event handling
frame = CreateFrame("Frame")

frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event)
    if event == "ZONE_CHANGED_NEW_AREA" then
        PVP_TRACKER.OnPlayerChangingZone()
    elseif event == "PLAYER_LOGOUT" then
        PVP_TRACKER.OnPlayerLogout()
    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        PVP_TRACKER.UpdateBattlegroundStats()
    end
end)


-- Add a slash command to toggle the battleground history frame
SLASH_PVPHISTORY1 = "/pvphistory"
SlashCmdList["PVPHISTORY"] = PVP_TRACKER.ToggleBattlegroundHistory
