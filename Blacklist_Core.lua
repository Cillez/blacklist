-- Blacklist_Core.lua
-- Event handling: death detection, proximity alerts, tooltip hook, slash commands

local addonLoaded = false
local lastAttacker = nil
local lastAttackerGUID = nil
local playerGUID = nil

-- Main event frame
local frame = CreateFrame("Frame", "BlacklistCoreFrame")

-- ============================================
-- COMBAT LOG TRACKING
-- ============================================

-- Track the last enemy player who damaged us
local function HandleCombatLog()
    local _, subevent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName = CombatLogGetCurrentEventInfo()

    -- Only care about damage done to us
    if destGUID ~= playerGUID then return end

    -- Check if source is a hostile player
    if not sourceGUID or not sourceName then return end
    if not strfind(sourceGUID, "^Player") then return end

    -- Filter to actual damage events
    local isDamage = (subevent == "SWING_DAMAGE"
        or subevent == "SPELL_DAMAGE"
        or subevent == "RANGE_DAMAGE"
        or subevent == "SPELL_PERIODIC_DAMAGE")

    if not isDamage then return end

    -- Store attacker info
    lastAttacker = Blacklist:StripRealm(sourceName)
    lastAttackerGUID = sourceGUID
end

-- ============================================
-- DEATH POPUP
-- ============================================

-- StaticPopup definition for adding killer to blacklist
StaticPopupDialogs["BLACKLIST_ADD_KILLER"] = {
    text = "Add |cffff0000%s|r to your blacklist?",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 260,
    maxLetters = 128,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
        -- Placeholder text hint
        self.editBox:SetScript("OnEnter", function(eb)
            GameTooltip:SetOwner(eb, "ANCHOR_RIGHT")
            GameTooltip:SetText("Enter a reason (optional)", nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        self.editBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end,
    OnAccept = function(self)
        local name = self.data
        local reason = self.editBox:GetText() or ""
        reason = strtrim(reason)
        if reason == "" then reason = "Killed me" end

        -- Try to grab extra info if we still have a unit reference
        local info = { zone = GetZoneText() }
        Blacklist:AddPlayer(name, reason, info)

        -- Refresh GUI if open
        if Blacklist_GUI_Refresh then
            Blacklist_GUI_Refresh()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = parent.data
        local reason = self:GetText() or ""
        reason = strtrim(reason)
        if reason == "" then reason = "Killed me" end

        local info = { zone = GetZoneText() }
        Blacklist:AddPlayer(name, reason, info)

        if Blacklist_GUI_Refresh then
            Blacklist_GUI_Refresh()
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 60,
    whileDead = true,
    hideOnEscape = true,
}

local function ShowDeathPopup()
    if not lastAttacker then return end
    if not Blacklist:GetSetting("deathPopup") then return end

    -- Don't prompt if already blacklisted
    if Blacklist:IsBlacklisted(lastAttacker) then
        -- Still alert though
        Blacklist:Print(lastAttacker .. " killed you (already blacklisted).", "WARNING")
        return
    end

    local popup = StaticPopup_Show("BLACKLIST_ADD_KILLER", lastAttacker)
    if popup then
        popup.data = lastAttacker
    end
end

-- ============================================
-- PROXIMITY ALERTS
-- ============================================

local function AlertPlayer(name, source)
    if not Blacklist:GetSetting("enabled") then return end
    if not Blacklist:IsBlacklisted(name) then return end
    if not Blacklist:CanAlert(name) then return end

    Blacklist:MarkAlerted(name)

    local entry = Blacklist:GetPlayer(name)
    local reason = entry and entry.reason or ""

    -- Chat notification
    if Blacklist:GetSetting("notifyChat") then
        local msg = "BLACKLISTED player spotted: " .. name
        if reason ~= "" then
            msg = msg .. " (" .. reason .. ")"
        end
        msg = msg .. " [" .. source .. "]"
        Blacklist:Print(msg, "ALERT")
    end

    -- Sound
    if Blacklist:GetSetting("notifySound") then
        PlaySound(Blacklist.ALERT_SOUND, "Master")
    end
end

-- Check target
local function CheckTarget()
    if not Blacklist:GetSetting("notifyTarget") then return end
    if not UnitExists("target") then return end
    if not UnitIsPlayer("target") then return end
    if UnitIsFriend("player", "target") then return end

    local name = Blacklist:StripRealm(UnitName("target"))
    if name then
        AlertPlayer(name, "target")
    end
end

-- Check mouseover
local function CheckMouseover()
    if not Blacklist:GetSetting("notifyMouseover") then return end
    if not UnitExists("mouseover") then return end
    if not UnitIsPlayer("mouseover") then return end
    if UnitIsFriend("player", "mouseover") then return end

    local name = Blacklist:StripRealm(UnitName("mouseover"))
    if name then
        AlertPlayer(name, "mouseover")
    end
end

-- Check nameplate unit
local function CheckNameplate(unit)
    if not Blacklist:GetSetting("notifyNameplate") then return end
    if not UnitExists(unit) then return end
    if not UnitIsPlayer(unit) then return end
    if UnitIsFriend("player", unit) then return end

    local name = Blacklist:StripRealm(UnitName(unit))
    if name then
        AlertPlayer(name, "nameplate")
    end
end

-- ============================================
-- TOOLTIP HOOK
-- ============================================

local function OnTooltipSetUnit(tooltip)
    if not Blacklist:GetSetting("tooltipNote") then return end

    local _, unit = tooltip:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local name = Blacklist:StripRealm(UnitName(unit))
    if not name then return end

    local entry = Blacklist:GetPlayer(name)
    if not entry then return end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cffcc3333[BLACKLISTED]|r", 1, 0.2, 0.2)
    if entry.reason and entry.reason ~= "" then
        tooltip:AddLine("Reason: " .. entry.reason, 1, 0.6, 0.2)
    end
    tooltip:Show()
end

-- ============================================
-- EVENT HANDLER
-- ============================================

local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Blacklist" then
        Blacklist:InitDB()
        addonLoaded = true
        playerGUID = UnitGUID("player")

        -- Hook tooltip
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)

        -- Delayed init for options and GUI
        C_Timer.After(0.5, function()
            if Blacklist_CreateOptions then
                Blacklist_CreateOptions()
            end
        end)

        Blacklist:Print("v" .. Blacklist.VERSION .. " loaded. /bl for commands.", "INFO")
        return
    end

    if not addonLoaded then return end
    if not Blacklist:GetSetting("enabled") then return end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog()
        return
    end

    if event == "PLAYER_DEAD" then
        ShowDeathPopup()
        return
    end

    if event == "PLAYER_TARGET_CHANGED" then
        CheckTarget()
        return
    end

    if event == "UPDATE_MOUSEOVER_UNIT" then
        CheckMouseover()
        return
    end

    if event == "NAME_PLATE_UNIT_ADDED" then
        CheckNameplate(arg1)
        return
    end

    -- Clear last attacker on respawn
    if event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        lastAttacker = nil
        lastAttackerGUID = nil
        return
    end
end

-- ============================================
-- REGISTER EVENTS
-- ============================================

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

-- ============================================
-- SLASH COMMANDS
-- ============================================

local function HandleSlashCommand(msg)
    msg = strtrim(msg or "")
    local cmd, rest = strsplit(" ", msg, 2)
    cmd = strlower(cmd or "")
    rest = rest and strtrim(rest) or ""

    -- No args or "list" - open the GUI
    if cmd == "" or cmd == "list" then
        if Blacklist_GUI_Toggle then
            Blacklist_GUI_Toggle()
        end
        return
    end

    -- Add player
    if cmd == "add" then
        if rest == "" then
            -- Try to add current target
            if UnitExists("target") and UnitIsPlayer("target") then
                local name = Blacklist:StripRealm(UnitName("target"))
                local info = Blacklist:GetUnitInfo("target")
                Blacklist:AddPlayer(name, "Added via /bl add", info)
            else
                Blacklist:Print("Usage: /bl add <name> [reason]", "WARNING")
            end
        else
            local name, reason = strsplit(" ", rest, 2)
            name = strtrim(name)
            reason = reason and strtrim(reason) or "Added via /bl add"
            Blacklist:AddPlayer(name, reason)
        end

        if Blacklist_GUI_Refresh then
            Blacklist_GUI_Refresh()
        end
        return
    end

    -- Remove player
    if cmd == "remove" or cmd == "rm" or cmd == "delete" then
        if rest == "" then
            Blacklist:Print("Usage: /bl remove <name>", "WARNING")
        else
            Blacklist:RemovePlayer(rest)
            if Blacklist_GUI_Refresh then
                Blacklist_GUI_Refresh()
            end
        end
        return
    end

    -- Check current target
    if cmd == "check" then
        if UnitExists("target") and UnitIsPlayer("target") then
            local name = Blacklist:StripRealm(UnitName("target"))
            local entry = Blacklist:GetPlayer(name)
            if entry then
                local msg = name .. " is BLACKLISTED"
                if entry.reason and entry.reason ~= "" then
                    msg = msg .. " - " .. entry.reason
                end
                Blacklist:Print(msg, "ALERT")
            else
                Blacklist:Print(name .. " is not on your blacklist.", "INFO")
            end
        else
            Blacklist:Print("No player targeted.", "WARNING")
        end
        return
    end

    -- Open config
    if cmd == "config" or cmd == "options" or cmd == "settings" then
        if Blacklist_OpenOptions then
            Blacklist_OpenOptions()
        end
        return
    end

    -- Help
    if cmd == "help" then
        Blacklist:Print("=== Blacklist Commands ===", "INFO")
        Blacklist:Print("/bl - Open blacklist window", "INFO")
        Blacklist:Print("/bl add <name> [reason] - Add player", "INFO")
        Blacklist:Print("/bl remove <name> - Remove player", "INFO")
        Blacklist:Print("/bl check - Check current target", "INFO")
        Blacklist:Print("/bl config - Open settings", "INFO")
        Blacklist:Print("/bl help - Show this help", "INFO")
        return
    end

    -- Unknown command
    Blacklist:Print("Unknown command. Type /bl help", "WARNING")
end

SLASH_BLACKLIST1 = "/bl"
SLASH_BLACKLIST2 = "/blacklist"
SlashCmdList["BLACKLIST"] = HandleSlashCommand
