-- Blacklist_Utils.lua
-- Namespace, constants, defaults, and data helpers

-- Addon namespace
Blacklist = Blacklist or {}

Blacklist.VERSION = "1.0"
Blacklist.ADDON_NAME = "Blacklist"

-- Chat colors
Blacklist.COLORS = {
    PREFIX  = "|cffcc3333",
    SUCCESS = "|cff00ff00",
    ERROR   = "|cffff0000",
    WARNING = "|cffffff00",
    INFO    = "|cffffffff",
    ALERT   = "|cffff6600",
    RESET   = "|r"
}

-- Alert sound (PvP flag warning)
Blacklist.ALERT_SOUND = 8332

-- Default settings
Blacklist.DEFAULTS = {
    settings = {
        enabled         = true,
        deathPopup      = true,
        notifyTarget    = true,
        notifyMouseover = true,
        notifyNameplate = true,
        notifySound     = true,
        notifyChat      = true,
        notifyCooldown  = 30,
        tooltipNote     = true,
    },
    players = {}
}

-- ============================================
-- DATABASE
-- ============================================

function Blacklist:InitDB()
    if not BlacklistDB then
        BlacklistDB = {}
    end

    -- Merge defaults
    for section, defaults in pairs(self.DEFAULTS) do
        if type(defaults) == "table" then
            BlacklistDB[section] = BlacklistDB[section] or {}
            if section == "settings" then
                for key, value in pairs(defaults) do
                    if BlacklistDB[section][key] == nil then
                        BlacklistDB[section][key] = value
                    end
                end
            end
        end
    end
end

-- ============================================
-- SETTINGS
-- ============================================

function Blacklist:GetSetting(key)
    if BlacklistDB and BlacklistDB.settings then
        return BlacklistDB.settings[key]
    end
    return self.DEFAULTS.settings[key]
end

function Blacklist:SetSetting(key, value)
    if BlacklistDB and BlacklistDB.settings then
        BlacklistDB.settings[key] = value
    end
end

-- ============================================
-- CHAT OUTPUT
-- ============================================

function Blacklist:Print(msg, msgType)
    msgType = msgType or "INFO"
    local color = self.COLORS[msgType] or self.COLORS.INFO
    local prefix = self.COLORS.PREFIX .. "[Blacklist]" .. self.COLORS.RESET .. " "
    print(prefix .. color .. msg .. self.COLORS.RESET)
end

-- ============================================
-- PLAYER DATA
-- ============================================

-- Add or update a player on the blacklist
function Blacklist:AddPlayer(name, reason, extraInfo)
    if not name or name == "" then return false end
    if not BlacklistDB.players then
        BlacklistDB.players = {}
    end

    local existing = BlacklistDB.players[name]
    local entry = existing or {}

    entry.reason    = reason or entry.reason or ""
    entry.timestamp = entry.timestamp or time()
    entry.lastSeen  = entry.lastSeen or 0

    -- Fill in extra info if provided (class, level, zone)
    if extraInfo then
        if extraInfo.class then entry.class = extraInfo.class end
        if extraInfo.level then entry.level = extraInfo.level end
        if extraInfo.zone  then entry.zone  = extraInfo.zone end
    end

    BlacklistDB.players[name] = entry

    if not existing then
        self:Print(name .. " added to blacklist.", "SUCCESS")
    else
        self:Print(name .. " updated.", "SUCCESS")
    end
    return true
end

-- Remove a player from the blacklist
function Blacklist:RemovePlayer(name)
    if not BlacklistDB.players or not BlacklistDB.players[name] then
        return false
    end
    BlacklistDB.players[name] = nil
    self:Print(name .. " removed from blacklist.", "INFO")
    return true
end

-- Check if player is on the blacklist
function Blacklist:IsBlacklisted(name)
    if not name or not BlacklistDB.players then return false end
    return BlacklistDB.players[name] ~= nil
end

-- Get player entry (or nil)
function Blacklist:GetPlayer(name)
    if not name or not BlacklistDB.players then return nil end
    return BlacklistDB.players[name]
end

-- Get total count
function Blacklist:GetPlayerCount()
    if not BlacklistDB.players then return 0 end
    local count = 0
    for _ in pairs(BlacklistDB.players) do
        count = count + 1
    end
    return count
end

-- Get sorted list of names (for the GUI)
function Blacklist:GetSortedNames(filter)
    local names = {}
    if not BlacklistDB.players then return names end

    filter = filter and strlower(filter) or nil

    for name in pairs(BlacklistDB.players) do
        if not filter or strfind(strlower(name), filter, 1, true) then
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

-- Clear entire blacklist
function Blacklist:ClearAll()
    BlacklistDB.players = {}
    self:Print("Blacklist cleared.", "SUCCESS")
end

-- ============================================
-- HELPERS
-- ============================================

-- Strip realm from "Player-Realm" format
function Blacklist:StripRealm(name)
    if not name then return nil end
    local stripped = strsplit("-", name)
    return stripped
end

-- Format a timestamp to readable date
function Blacklist:FormatDate(ts)
    if not ts or ts == 0 then return "Unknown" end
    return date("%Y-%m-%d %H:%M", ts)
end

-- Check if alert cooldown has passed for a player
function Blacklist:CanAlert(name)
    local entry = self:GetPlayer(name)
    if not entry then return false end

    local cooldown = self:GetSetting("notifyCooldown") or 30
    local now = GetTime()

    if (now - (entry.lastSeen or 0)) < cooldown then
        return false
    end
    return true
end

-- Mark player as recently alerted (resets cooldown)
function Blacklist:MarkAlerted(name)
    local entry = self:GetPlayer(name)
    if entry then
        entry.lastSeen = GetTime()
    end
end

-- Get unit info for filling in extra data
function Blacklist:GetUnitInfo(unit)
    if not unit or not UnitExists(unit) then return nil end

    local info = {}
    local _, class = UnitClass(unit)
    if class then info.class = class end

    local level = UnitLevel(unit)
    if level and level > 0 then info.level = level end

    local zone = GetZoneText()
    if zone and zone ~= "" then info.zone = zone end

    return info
end
