-- Blacklist_Options.lua
-- Settings panel registered in Interface > AddOns

local settingsCategory = nil
local optionsPanel = nil

-- ============================================
-- CREATE OPTIONS PANEL
-- ============================================

function Blacklist_CreateOptions()
    if optionsPanel then return end

    optionsPanel = CreateFrame("Frame", "Blacklist_OptionsPanel")
    optionsPanel.name = "Blacklist"

    -- Register with Settings API (2.5.5+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        settingsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(settingsCategory)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(optionsPanel)
    end

    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, optionsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(550, 650)
    scrollFrame:SetScrollChild(content)

    local yOffset = 0

    -- ============================================
    -- HEADER
    -- ============================================
    yOffset = CreateHeader(content, yOffset, "|cffcc3333Blacklist|r v" .. (Blacklist.VERSION or "1.0"))
    yOffset = yOffset + 5

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", 10, -yOffset)
    desc:SetWidth(500)
    desc:SetJustifyH("LEFT")
    desc:SetText("PvP blacklist tracker. Alerts you when blacklisted players are nearby.")
    desc:SetTextColor(0.7, 0.7, 0.7)
    yOffset = yOffset + 20

    -- ============================================
    -- GENERAL
    -- ============================================
    yOffset = CreateSectionHeader(content, yOffset, "General")

    yOffset = CreateCheckbox(content, yOffset, "enabled", "Enable Addon",
        "Master toggle for the blacklist addon")

    yOffset = yOffset + 10

    -- ============================================
    -- DEATH POPUP
    -- ============================================
    yOffset = CreateSectionHeader(content, yOffset, "Death Popup")

    yOffset = CreateCheckbox(content, yOffset, "deathPopup", "Prompt on PvP Death",
        "Show a popup after being killed by a player, allowing you to blacklist them")

    yOffset = yOffset + 10

    -- ============================================
    -- NOTIFICATIONS
    -- ============================================
    yOffset = CreateSectionHeader(content, yOffset, "Notifications")

    yOffset = CreateCheckbox(content, yOffset, "notifyTarget", "Alert on Target",
        "Notify when you target a blacklisted player")

    yOffset = CreateCheckbox(content, yOffset, "notifyMouseover", "Alert on Mouseover",
        "Notify when you mouseover a blacklisted player")

    yOffset = CreateCheckbox(content, yOffset, "notifyNameplate", "Alert on Nameplate",
        "Notify when a blacklisted player's nameplate appears nearby")

    yOffset = CreateCheckbox(content, yOffset, "notifyChat", "Chat Notification",
        "Print alert messages to chat")

    yOffset = CreateCheckbox(content, yOffset, "notifySound", "Sound Alert",
        "Play a warning sound when a blacklisted player is spotted")

    yOffset = yOffset + 5

    yOffset = CreateNumberInput(content, yOffset, "notifyCooldown", "Alert Cooldown (sec)",
        "Seconds between repeat alerts for the same player (5-120)", 5, 120)

    yOffset = yOffset + 10

    -- ============================================
    -- TOOLTIP
    -- ============================================
    yOffset = CreateSectionHeader(content, yOffset, "Tooltip")

    yOffset = CreateCheckbox(content, yOffset, "tooltipNote", "Show in Tooltip",
        "Display blacklist status and reason in player tooltips")

    yOffset = yOffset + 10

    -- ============================================
    -- ACTIONS
    -- ============================================
    yOffset = CreateSectionHeader(content, yOffset, "Actions")

    -- Open blacklist button
    local openBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    openBtn:SetPoint("TOPLEFT", 10, -yOffset)
    openBtn:SetSize(140, 22)
    openBtn:SetText("Open Blacklist")
    openBtn:SetScript("OnClick", function()
        if Blacklist_GUI_Toggle then
            Blacklist_GUI_Toggle()
        end
    end)

    -- Clear all button
    local clearBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    clearBtn:SetPoint("TOPLEFT", 160, -yOffset)
    clearBtn:SetSize(140, 22)
    clearBtn:SetText("Clear Blacklist")
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("BLACKLIST_CLEAR_ALL")
    end)
    yOffset = yOffset + 35

    -- Reset settings button
    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPLEFT", 10, -yOffset)
    resetBtn:SetSize(140, 22)
    resetBtn:SetText("Reset Settings")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("BLACKLIST_RESET_SETTINGS")
    end)
    yOffset = yOffset + 35

    -- Player count
    local statsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("TOPLEFT", 10, -yOffset)
    statsText:SetJustifyH("LEFT")
    statsText:SetWidth(400)

    local count = Blacklist:GetPlayerCount()
    statsText:SetText("Players on blacklist: |cffffffff" .. count .. "|r")

    -- ============================================
    -- HELP TEXT
    -- ============================================
    yOffset = yOffset + 30
    yOffset = CreateSectionHeader(content, yOffset, "Commands")

    local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("TOPLEFT", 10, -yOffset)
    helpText:SetJustifyH("LEFT")
    helpText:SetWidth(500)
    helpText:SetText(
        "|cffffd700/bl|r or |cffffd700/blacklist|r - Open blacklist window\n" ..
        "|cffffd700/bl add <name> [reason]|r - Add player to blacklist\n" ..
        "|cffffd700/bl remove <name>|r - Remove player\n" ..
        "|cffffd700/bl check|r - Check current target\n" ..
        "|cffffd700/bl config|r - Open this settings panel\n" ..
        "|cffffd700/bl help|r - Show all commands"
    )

    -- Reset settings confirmation
    StaticPopupDialogs["BLACKLIST_RESET_SETTINGS"] = {
        text = "Reset all Blacklist settings to defaults?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            BlacklistDB.settings = nil
            Blacklist:InitDB()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

-- ============================================
-- UI HELPER FUNCTIONS
-- ============================================

function CreateHeader(parent, yOffset, text)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -yOffset)
    header:SetText(text)
    return yOffset + 25
end

function CreateSectionHeader(parent, yOffset, text)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 10, -yOffset)
    header:SetTextColor(1, 0.82, 0)
    header:SetText("--- " .. text .. " ---")
    return yOffset + 20
end

function CreateCheckbox(parent, yOffset, settingKey, label, tooltip)
    local check = CreateFrame("CheckButton", "Blacklist_" .. settingKey .. "_Check", parent, "ChatConfigCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 10, -yOffset)
    _G[check:GetName() .. "Text"]:SetText(label)

    check:SetChecked(Blacklist:GetSetting(settingKey))
    check:SetScript("OnClick", function(self)
        Blacklist:SetSetting(settingKey, self:GetChecked())
    end)

    if tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return yOffset + 25
end

function CreateNumberInput(parent, yOffset, settingKey, label, tooltip, minVal, maxVal)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 10, -yOffset)
    labelText:SetText(label .. ":")

    local editBox = CreateFrame("EditBox", "Blacklist_" .. settingKey .. "_Edit", parent, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", 200, -yOffset + 3)
    editBox:SetSize(60, 20)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(4)

    local currentVal = Blacklist:GetSetting(settingKey) or minVal
    editBox:SetText(tostring(currentVal))
    editBox:SetCursorPosition(0)

    -- Range hint text
    local rangeText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rangeText:SetPoint("LEFT", editBox, "RIGHT", 8, 0)
    rangeText:SetText("(" .. minVal .. " - " .. maxVal .. ")")
    rangeText:SetTextColor(0.5, 0.5, 0.5)

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local val = tonumber(self:GetText())
        if val then
            val = math.max(minVal, math.min(maxVal, val))
            Blacklist:SetSetting(settingKey, val)
        end
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        -- Clamp on confirm
        local val = tonumber(self:GetText()) or minVal
        val = math.max(minVal, math.min(maxVal, val))
        self:SetText(tostring(val))
        Blacklist:SetSetting(settingKey, val)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(Blacklist:GetSetting(settingKey) or minVal))
        self:ClearFocus()
    end)

    if tooltip then
        editBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        editBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return yOffset + 30
end

-- ============================================
-- OPEN OPTIONS
-- ============================================

function Blacklist_OpenOptions()
    if Settings and Settings.OpenToCategory and settingsCategory then
        Settings.OpenToCategory(settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(Blacklist_OptionsPanel)
        InterfaceOptionsFrame_OpenToCategory(Blacklist_OptionsPanel)
    end
end
