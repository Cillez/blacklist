-- Blacklist_GUI.lua
-- Main list management window with search, add, edit, and remove

local GUI = nil
local ROW_HEIGHT = 24
local VISIBLE_ROWS = 14
local currentFilter = ""
local editingPlayer = nil

-- ============================================
-- MAIN FRAME
-- ============================================

local function CreateGUI()
    if GUI then return end

    GUI = CreateFrame("Frame", "BlacklistGUIFrame", UIParent, "BasicFrameTemplateWithInset")
    GUI:SetSize(480, 480)
    GUI:SetPoint("CENTER")
    GUI:SetMovable(true)
    GUI:SetClampedToScreen(true)
    GUI:EnableMouse(true)
    GUI:RegisterForDrag("LeftButton")
    GUI:SetScript("OnDragStart", GUI.StartMoving)
    GUI:SetScript("OnDragStop", GUI.StopMovingOrSizing)
    GUI:SetFrameStrata("HIGH")
    GUI:Hide()

    -- Resolve inset frame (varies by client version)
    local inset = GUI.InsetFrame or GUI.Inset
    if not inset then
        -- Fallback: create our own content area inside the frame
        inset = CreateFrame("Frame", nil, GUI)
        inset:SetPoint("TOPLEFT", 4, -24)
        inset:SetPoint("BOTTOMRIGHT", -4, 4)
    end
    GUI.inset = inset

    -- Title
    GUI.title = GUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    GUI.title:SetPoint("TOP", 0, -5)
    GUI.title:SetText("|cffcc3333Blacklist|r")

    -- Player count
    GUI.countText = GUI:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    GUI.countText:SetPoint("TOPRIGHT", -30, -5)
    GUI.countText:SetTextColor(0.7, 0.7, 0.7)

    -- ESC to close
    table.insert(UISpecialFrames, "BlacklistGUIFrame")

    -- ============================================
    -- SEARCH BAR
    -- ============================================
    local searchBox = CreateFrame("EditBox", "BlacklistSearchBox", inset, "InputBoxTemplate")
    searchBox:SetPoint("TOPLEFT", 10, -8)
    searchBox:SetSize(200, 20)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(30)

    -- Search label
    local searchLabel = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -4, 0)
    searchLabel:SetText("Search:")

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        currentFilter = self:GetText()
        Blacklist_GUI_Refresh()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        currentFilter = ""
        Blacklist_GUI_Refresh()
    end)

    GUI.searchBox = searchBox

    -- ============================================
    -- COLUMN HEADERS
    -- ============================================
    local headerY = -34
    local nameHeader = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameHeader:SetPoint("TOPLEFT", 10, headerY)
    nameHeader:SetTextColor(1, 0.82, 0)
    nameHeader:SetText("Name")

    local reasonHeader = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reasonHeader:SetPoint("TOPLEFT", 140, headerY)
    reasonHeader:SetTextColor(1, 0.82, 0)
    reasonHeader:SetText("Reason")

    local dateHeader = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dateHeader:SetPoint("TOPLEFT", 320, headerY)
    dateHeader:SetTextColor(1, 0.82, 0)
    dateHeader:SetText("Added")

    -- Divider line
    local divider = inset:CreateTexture(nil, "OVERLAY")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", 6, headerY - 14)
    divider:SetPoint("TOPRIGHT", -6, headerY - 14)
    divider:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- ============================================
    -- SCROLL FRAME
    -- ============================================
    local scrollFrame = CreateFrame("ScrollFrame", "BlacklistScrollFrame", inset, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, headerY - 18)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 80)

    GUI.scrollFrame = scrollFrame

    -- Create row buttons
    GUI.rows = {}
    for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", "BlacklistRow" .. i, inset)
        row:SetSize(420, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        -- Highlight texture
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.05)

        -- Alternating row background
        if i % 2 == 0 then
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.15, 0.15, 0.15, 0.4)
        end

        -- Name text
        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameText:SetPoint("LEFT", 4, 0)
        row.nameText:SetWidth(120)
        row.nameText:SetJustifyH("LEFT")

        -- Reason text
        row.reasonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.reasonText:SetPoint("LEFT", 134, 0)
        row.reasonText:SetWidth(170)
        row.reasonText:SetJustifyH("LEFT")
        row.reasonText:SetTextColor(0.8, 0.8, 0.8)

        -- Date text
        row.dateText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.dateText:SetPoint("LEFT", 314, 0)
        row.dateText:SetWidth(80)
        row.dateText:SetJustifyH("LEFT")
        row.dateText:SetTextColor(0.6, 0.6, 0.6)

        -- Remove button (small X)
        row.removeBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        row.removeBtn:SetSize(20, 20)
        row.removeBtn:SetPoint("RIGHT", row, "RIGHT", 18, 0)
        row.removeBtn:SetScript("OnClick", function()
            if row.playerName then
                Blacklist:RemovePlayer(row.playerName)
                Blacklist_GUI_Refresh()
            end
        end)

        -- Click row to edit
        row:SetScript("OnClick", function()
            if row.playerName then
                ShowEditPopup(row.playerName)
            end
        end)

        -- Tooltip on hover showing full details
        row:SetScript("OnEnter", function(self)
            if not self.playerName then return end
            local entry = Blacklist:GetPlayer(self.playerName)
            if not entry then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.playerName, 1, 0.2, 0.2)
            if entry.reason and entry.reason ~= "" then
                GameTooltip:AddLine("Reason: " .. entry.reason, 1, 1, 1, true)
            end
            if entry.class then
                GameTooltip:AddLine("Class: " .. entry.class, 0.7, 0.7, 0.7)
            end
            if entry.level then
                GameTooltip:AddLine("Level: " .. entry.level, 0.7, 0.7, 0.7)
            end
            if entry.zone then
                GameTooltip:AddLine("Zone: " .. entry.zone, 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine("Added: " .. Blacklist:FormatDate(entry.timestamp), 0.5, 0.5, 0.5)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Click to edit reason", 0.4, 0.8, 0.4)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        row.playerName = nil
        row:Hide()
        GUI.rows[i] = row
    end

    -- Scroll handler
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, Blacklist_GUI_Refresh)
    end)

    -- ============================================
    -- BOTTOM PANEL: ADD PLAYER
    -- ============================================
    local bottomY = 72

    -- Add label
    local addLabel = inset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addLabel:SetPoint("BOTTOMLEFT", 6, bottomY)
    addLabel:SetTextColor(1, 0.82, 0)
    addLabel:SetText("Add Player:")

    bottomY = bottomY - 4

    -- Name input
    local nameLabel = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("BOTTOMLEFT", 6, bottomY - 20)
    nameLabel:SetText("Name:")

    local nameInput = CreateFrame("EditBox", "BlacklistAddNameInput", inset, "InputBoxTemplate")
    nameInput:SetPoint("BOTTOMLEFT", 50, bottomY - 23)
    nameInput:SetSize(120, 20)
    nameInput:SetAutoFocus(false)
    nameInput:SetMaxLetters(24)
    GUI.nameInput = nameInput

    -- Reason input
    local reasonLabel = inset:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reasonLabel:SetPoint("BOTTOMLEFT", 180, bottomY - 20)
    reasonLabel:SetText("Reason:")

    local reasonInput = CreateFrame("EditBox", "BlacklistAddReasonInput", inset, "InputBoxTemplate")
    reasonInput:SetPoint("BOTTOMLEFT", 228, bottomY - 23)
    reasonInput:SetSize(140, 20)
    reasonInput:SetAutoFocus(false)
    reasonInput:SetMaxLetters(128)
    GUI.reasonInput = reasonInput

    -- Add button
    local addBtn = CreateFrame("Button", nil, inset, "UIPanelButtonTemplate")
    addBtn:SetPoint("BOTTOMLEFT", 376, bottomY - 24)
    addBtn:SetSize(60, 22)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function()
        local name = strtrim(nameInput:GetText() or "")
        local reason = strtrim(reasonInput:GetText() or "")
        if name == "" then
            Blacklist:Print("Enter a player name.", "WARNING")
            return
        end
        if reason == "" then reason = "Manually added" end
        Blacklist:AddPlayer(name, reason)
        nameInput:SetText("")
        reasonInput:SetText("")
        nameInput:ClearFocus()
        reasonInput:ClearFocus()
        Blacklist_GUI_Refresh()
    end)

    -- Enter key on inputs triggers add
    nameInput:SetScript("OnEnterPressed", function(self)
        if strtrim(self:GetText()) ~= "" then
            reasonInput:SetFocus()
        end
    end)
    reasonInput:SetScript("OnEnterPressed", function()
        addBtn:Click()
    end)
    nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    reasonInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Target fill button (fills name from current target)
    local targetBtn = CreateFrame("Button", nil, inset, "UIPanelButtonTemplate")
    targetBtn:SetPoint("BOTTOMLEFT", 6, bottomY - 50)
    targetBtn:SetSize(80, 22)
    targetBtn:SetText("Use Target")
    targetBtn:SetScript("OnClick", function()
        if UnitExists("target") and UnitIsPlayer("target") then
            local name = Blacklist:StripRealm(UnitName("target"))
            nameInput:SetText(name or "")
        else
            Blacklist:Print("No player targeted.", "WARNING")
        end
    end)

    -- Clear all button
    local clearAllBtn = CreateFrame("Button", nil, inset, "UIPanelButtonTemplate")
    clearAllBtn:SetPoint("BOTTOMRIGHT", -6, bottomY - 50)
    clearAllBtn:SetSize(80, 22)
    clearAllBtn:SetText("Clear All")
    clearAllBtn:SetScript("OnClick", function()
        StaticPopup_Show("BLACKLIST_CLEAR_ALL")
    end)
end

-- ============================================
-- EDIT POPUP
-- ============================================

StaticPopupDialogs["BLACKLIST_EDIT_REASON"] = {
    text = "Edit reason for |cffff0000%s|r:",
    button1 = "Save",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 260,
    maxLetters = 128,
    OnShow = function(self)
        local name = self.data
        local entry = Blacklist:GetPlayer(name)
        if entry and entry.reason then
            self.editBox:SetText(entry.reason)
        end
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    OnAccept = function(self)
        local name = self.data
        local reason = strtrim(self.editBox:GetText() or "")
        local entry = Blacklist:GetPlayer(name)
        if entry then
            entry.reason = reason
            Blacklist:Print(name .. " reason updated.", "SUCCESS")
            Blacklist_GUI_Refresh()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = parent.data
        local reason = strtrim(self:GetText() or "")
        local entry = Blacklist:GetPlayer(name)
        if entry then
            entry.reason = reason
            Blacklist:Print(name .. " reason updated.", "SUCCESS")
            Blacklist_GUI_Refresh()
        end
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["BLACKLIST_CLEAR_ALL"] = {
    text = "Clear your entire blacklist? This cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        Blacklist:ClearAll()
        Blacklist_GUI_Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function ShowEditPopup(name)
    local popup = StaticPopup_Show("BLACKLIST_EDIT_REASON", name)
    if popup then
        popup.data = name
    end
end

-- ============================================
-- REFRESH / UPDATE ROWS
-- ============================================

function Blacklist_GUI_Refresh()
    if not GUI or not GUI:IsShown() then return end

    local names = Blacklist:GetSortedNames(currentFilter)
    local total = #names
    local scrollFrame = GUI.scrollFrame

    FauxScrollFrame_Update(scrollFrame, total, VISIBLE_ROWS, ROW_HEIGHT)

    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, VISIBLE_ROWS do
        local row = GUI.rows[i]
        local index = offset + i

        if index <= total then
            local name = names[index]
            local entry = Blacklist:GetPlayer(name)

            row.playerName = name
            row.nameText:SetText(name)

            local reason = (entry and entry.reason) or ""
            if #reason > 28 then
                reason = strsub(reason, 1, 26) .. ".."
            end
            row.reasonText:SetText(reason)

            local dateStr = entry and Blacklist:FormatDate(entry.timestamp) or ""
            -- Just show the date part for the column
            if #dateStr > 10 then
                dateStr = strsub(dateStr, 1, 10)
            end
            row.dateText:SetText(dateStr)

            row:Show()
        else
            row.playerName = nil
            row:Hide()
        end
    end

    -- Update count
    local totalCount = Blacklist:GetPlayerCount()
    GUI.countText:SetText(totalCount .. " player" .. (totalCount ~= 1 and "s" or ""))
end

-- ============================================
-- TOGGLE / PUBLIC API
-- ============================================

function Blacklist_GUI_Toggle()
    -- Close chat editbox so it doesn't stay active after slash command
    if ChatFrame1EditBox and ChatFrame1EditBox:IsShown() then
        ChatFrame1EditBox:Hide()
    end

    CreateGUI()
    if GUI:IsShown() then
        GUI:Hide()
    else
        GUI:Show()
        Blacklist_GUI_Refresh()
    end
end
