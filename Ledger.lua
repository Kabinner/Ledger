-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({
    _G = _G
}, {
    __index = _G
})
setfenv(1, _G)

-- Settings
local Addon = {
    debug = true,
    name = "Ledger",
    Frame = nil,
    events = {},
    object = nil,
    object_map = {},
    object_map_reversed = {},
    object_map_lookup = {}
}

-- Utils
local function id(_)
    return string.sub(tostring(_), -8)
end
local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Debug
local Debug = {
    LEVEL="INFO",
    INFO="INFO",
    TRACE="TRACE"
}
function Debug:print(color, ...)
    if not Addon.debug then
        return
    end
    local msg = ""
    for idx, value in ipairs(arg) do
        if type(value) == "table" then
            msg = msg .. tostring(value) .. " "
        elseif type(value) == "function" then
            msg = msg .. id(value) .. " "
        elseif value == nil then
            msg = msg .. "nil" .. " "
        else
            msg = msg .. value .. " "
        end
    end
    print(color .. Addon.name .. " [DEBUG]: " .. msg)

end
function Debug:info(...)
    if self.LEVEL ~= self.INFO then
        return
    end
    self:print("|cffffd700", unpack(arg))
end
function Debug:trace(...)
    if self.LEVEL ~= self.TRACE then
        return
    end
    self:print("|cffffd700", unpack(arg))
end

-- API Hooks
local _CreateFrame = CreateFrame
CreateFrame = function(...)
    Frame = _CreateFrame(unpack(arg))
    function Frame:Texture(texture, width, height, opts)
        Debug:info(texture, width, height, opts)
        for func, args in pairs(opts) do
            Debug:info("function call", func, unpack(args))
        end
    end

    return Frame
end

-- Addon lib
function Addon:new(object)
    self.Frame = CreateFrame("Frame", "FRAME_" .. string.upper("%u*", self.name), UIParent)
    Debug:info("Frame: ", self.Frame)
    self.object = object
    for function_name in self.object do
        if function_name ~= "new" and type(self.object[function_name]) == "function" then
            Debug:trace("Mapping ", self.name .. ":" .. function_name, "to: ", self.object[function_name])
            self.object_map[function_name] = self.object[function_name]

            Debug:trace("Mapping ", id(self.object[function_name]), " to: ", self.name .. ":" .. function_name .. "")
            self.object_map_reversed[id(self.object[function_name])] = self.object[function_name]

            self.object_map_lookup[id(self.object[function_name])] = function_name
        end
    end
end
function Debug:info(...)
    if self.LEVEL ~= self.INFO then
        return
    end
    self:print("|cffffd700", unpack(arg))
end
function Debug:trace(...)
    if self.LEVEL ~= self.TRACE then
        return
    end
    self:print("|cffffd700", unpack(arg))
end

-- API Hooks
local _CreateFrame = CreateFrame
CreateFrame = function(...)
    Frame = _CreateFrame(unpack(arg))
    function Frame:Texture(texture, width, height, opts)
        Debug:info(texture, width, height, opts)
        for func, args in pairs(opts) do
            Debug:info("function call", func, unpack(args))
        end
    end

    return Frame
end

-- Addon lib
function Addon:new(object)
    self.Frame = CreateFrame("Frame", "FRAME_" .. string.upper("%u*", self.name), UIParent)
    Debug:info("Frame: ", self.Frame)
    self.object = object
    for function_name in self.object do
        if function_name ~= "new" and type(self.object[function_name]) == "function" then
            Debug:trace("Mapping ", self.name .. ":" .. function_name, "to: ", self.object[function_name])
            self.object_map[function_name] = self.object[function_name]

            Debug:trace("Mapping ", id(self.object[function_name]), " to: ", self.name .. ":" .. function_name .. "")
            self.object_map_reversed[id(self.object[function_name])] = self.object[function_name]

            self.object_map_lookup[id(self.object[function_name])] = function_name
        end
    end

    return setmetatable(Addon, {
        __index = Addon
    })
end
function Addon:on(event, callback)
    self.Frame:RegisterEvent(event)
    self.events[event] = callback
end
function Addon:callback(callback, ...)
    return self.object_map_reversed[id(callback)](self.object, self.Frame, unpack(arg))
end
function Addon:dispatch(e)
    if e == "ADDON_LOADED" and arg1 == self.name then
        self.object["load"](self.object, self.Frame)
    elseif e ~= "ADDON_LOADED" then
        func = self.events[e]
        Debug:info("Addon:dispatch: ", e, " -> ", self.name .. ":" .. self.object_map_lookup[id(func)], func)
        self:callback(func)
    end
end
function Addon:load()
    self.Frame:SetScript('OnEvent', function()
        self:dispatch(event)
    end)
    self.Frame:SetScript('OnEvent', function()
        self:dispatch(event)
    end)
end

-- Addon implementation
Ledger = {}
function Ledger:new()
    return setmetatable(Ledger, {
        __index = Ledger
    })
end
function Ledger:print(...)
    local msg = ""
    for idx, value in ipairs(arg) do
        if type(value) ~= "string" then
            return
        end
        msg = msg .. value .. " "
    end
    DEFAULT_CHAT_FRAME:AddMessage(Addon.name .. ": " .. msg);
end
function Ledger:load(Frame)
    Debug:info("Ledger:load", "Frame", Frame)
    self:print("Load.")
    self:UI(Frame)
end

function Ledger:enable(Frame)
    self:print("Enable.")
    Debug:info("Ledger:enable", "Frame", Frame)


    -- Frame:CreateTexture(nil, "BACKGROUND")
    -- Icon:SetTexture('Interface\\Spellbook\\Spellbook-Icon')
    -- Icon:SetWidth(58)
    -- Icon:SetHeight(58)
    -- Icon:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 10, -8)

    -- Frame.Texture:BACKGROUND

    Frame:Texture([[Interface\Spellbook\Spellbook-Icon]], 58, 58, {SetPoint={"TOPLEFT", 10, -8}})
    Debug:info("Ledger:enable", "Frame", Frame)

    SLASH_LEDGER1 = "/ledger"
    SlashCmdList["LEDGER"] = function(msg)
        Debug:info("/ledger command.")
    end
end
function Ledger:disable()
end

ledger = Ledger:new()
addon = Addon:new(ledger)

Debug:info("Ledger: ", ledger)
Debug:info("Ledger: ", ledger)

addon:on("ADDON_LOADED", ledger.load)
addon:on("PLAYER_LOGIN", ledger.enable)
addon:on("PLAYER_LOGOUT", ledger.disable)

addon:load()

function Ledger:UI(Frame)
    local LedgerFrame = CreateFrame("Frame", "FRAME_LEDGER_PANEL", Frame)
    LedgerFrame:SetWidth(384)
    LedgerFrame:SetHeight(512)
    LedgerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    LedgerFrame:EnableMouse(true)
    LedgerFrame:SetMovable(true)
    LedgerFrame:SetUserPlaced(true)

    LedgerFrame:RegisterForDrag("LeftButton")
    LedgerFrame:SetScript("OnDragStart", function()
        LedgerFrame:StartMoving()
    end)
    LedgerFrame:SetScript("OnDragStop", function()
        LedgerFrame:StopMovingOrSizing()
    end)

    local CloseButton = CreateFrame("Button", "FRAME_LEDGER_PANEL_BUTTON_CLOSE", LedgerFrame, "UIPanelCloseButton")
    CloseButton:SetPoint("CENTER", LedgerFrame, "TOPRIGHT", -44, -25)
    CloseButton:SetScript("OnClick", function()
        LedgerFrame:Hide()
    end)
    CloseButton:SetScript("OnClick", function()
        LedgerFrame:Hide()
    end)

    local Icon = LedgerFrame:CreateTexture(nil, "BACKGROUND")
    Icon:SetTexture([[Interface\Spellbook\Spellbook-Icon]])
    Icon:SetWidth(58)
    Icon:SetHeight(58)
    Icon:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 10, -8)

    local TopLeft = LedgerFrame:CreateTexture(nil, "ARTWORK")
    TopLeft:SetTexture([[Interface\Spellbook\UI-SpellbookPanel-TopLeft]])
    TopLeft:SetWidth(256)
    TopLeft:SetHeight(256)
    TopLeft:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 0, 0)

    local TopRight = LedgerFrame:CreateTexture(nil, "ARTWORK")
    TopRight:SetTexture([[Interface\Spellbook\UI-SpellbookPanel-TopRight]])
    TopRight:SetWidth(128)
    TopRight:SetHeight(256)
    TopRight:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", 0, 0)

    local BottomLeft = LedgerFrame:CreateTexture(nil, "ARTWORK")
    BottomLeft:SetTexture([[Interface\Spellbook\UI-SpellbookPanel-BotLeft]])
    BottomLeft:SetWidth(256)
    BottomLeft:SetHeight(256)
    BottomLeft:SetPoint("BOTTOMLEFT", LedgerFrame, "BOTTOMLEFT", 0, 0)

    local BottomRight = LedgerFrame:CreateTexture(nil, "ARTWORK")
    BottomRight:SetTexture([[Interface\Spellbook\UI-SpellbookPanel-BotRight]])
    BottomRight:SetWidth(128)
    BottomRight:SetHeight(256)
    BottomRight:SetPoint("BOTTOMRIGHT", LedgerFrame, "BOTTOMRIGHT", 0, 0)

    local TitleText = LedgerFrame:CreateFontString("FRAME_LEDGER_PANEL_TITLE_TEXT", "ARTWORK", "GameFontNormal")
    TitleText:SetPoint("CENTER", LedgerFrame, "CENTER", 6, 230)
    TitleText:SetText("Ledger")

    local PageText = LedgerFrame:CreateFontString("FRAME_LEDGER_PANEL_PAGE_TEXT", "ARTWORK", "GameFontNormal")
    PageText:SetWidth(102)
    PageText:SetPoint("BOTTOM", LedgerFrame, "BOTTOM", -14, 96)
    PageText:SetText("Page 1")

    local Page = {
        currentPage = 1,
        pages = {{"Page 1 Line 1", "Page 1 Line 2", "Page 1 Line 3"},
                 {"Page 2 Line 1", "Page 2 Line 2", "Page 2 Line 3"},
                 {"Page 3 Line 1", "Page 3 Line 2", "Page 3 Line 3"}}
    }

    local PrevButton = CreateFrame("Button", "FRAME_LEDGER_PREV_BUTTON", LedgerFrame, "UIPanelButtonTemplate")
    PrevButton:SetPoint("BOTTOM", LedgerFrame, "BOTTOMLEFT", 50, 85)
    PrevButton:SetWidth(32)
    PrevButton:SetHeight(32)

    local normTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    normTex:SetAllPoints()
    normTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    PrevButton:SetNormalTexture(normTex)

    local pushTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    pushTex:SetAllPoints()
    pushTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    PrevButton:SetPushedTexture(pushTex)

    local disableTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    disableTex:SetAllPoints()
    disableTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Disabled]])
    PrevButton:SetDisabledTexture(disableTex)

    PrevButton:SetScript("OnClick", function()
        PlaySound("igAbiliityPageTurn")
        Page:SetPage(Page.currentPage - 1)
    end)

    local NextButton = CreateFrame("Button", "FRAME_LEDGER_NEXT_BUTTON", LedgerFrame, "UIPanelButtonTemplate")
    NextButton:SetPoint("BOTTOM", LedgerFrame, "BOTTOMRIGHT", -70, 85)
    NextButton:SetWidth(32)
    NextButton:SetHeight(32)

    local normTex = NextButton:CreateTexture(nil, "BACKGROUND")
    normTex:SetAllPoints()
    normTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    NextButton:SetNormalTexture(normTex)

    local pushTex = NextButton:CreateTexture(nil, "BACKGROUND")
    pushTex:SetAllPoints()
    pushTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    NextButton:SetPushedTexture(pushTex)

    local disableTex = NextButton:CreateTexture(nil, "BACKGROUND")
    disableTex:SetAllPoints()
    disableTex:SetTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Disabled]])
    NextButton:SetDisabledTexture(disableTex)

    NextButton:SetScript("OnClick", function()
        PlaySound("igAbilityPageTurn")
        Page:SetPage(Page.currentPage + 1)
    end)

    PrevButton:Disable()
    Debug:info("pages: ", table.getn(Page.pages))
    if table.getn(Page.pages) <= 1 then
        NextButton:Enable()
    end

    function Page:SetPage(page)
        self.currentPage = math.max(1, math.min(page, table.getn(self.pages)))
        PageText:SetText("Page " .. self.currentPage)
        self:UpdatePageContent()

        -- Update button states
        if self.currentPage > 1 then
            PrevButton:Enable()
        else
            PrevButton:Disable()
        end
        if self.currentPage < table.getn(self.pages) then
            NextButton:Enable()
        else
            NextButton:Disable()
        end
    end
    function Page:UpdatePageContent()
        local content = self.pages[self.currentPage] or {}
        for i = 1, 3 do
            _G["LedgerText" .. i]:SetText(content[i] or "")
        end
    end

    local textY = -70
    for i = 1, 3 do
        local text = LedgerFrame:CreateFontString("LedgerText" .. i, "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 30, textY)
        text:SetWidth(324)
        text:SetJustifyH("LEFT")
        textY = textY - 30
    end
    Page:UpdatePageContent()
    LedgerFrame:Show()
end

-- -- Adjust text area dimensions and add scrollable content
-- local VISIBLE_LINES = 8
-- local LINE_HEIGHT = 16
-- local textYStart = -70
-- local textX = 30

-- -- Create scroll frame container
-- local ScrollFrame = CreateFrame("Frame", nil, LedgerFrame)
-- ScrollFrame:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", textX, textYStart)
-- ScrollFrame:SetPoint("BOTTOMRIGHT", LedgerFrame, "BOTTOMRIGHT", -40, 100)
-- ScrollFrame:SetClipsChildren(true)

-- -- Create text lines within scroll frame
-- local textLines = {}
-- for i = 1, 12 do  -- Create 12 lines (4 more than visible for buffer)
--     local text = ScrollFrame:CreateFontString("LedgerText"..i, "ARTWORK", "GameFontNormal")
--     text:SetPoint("TOPLEFT", ScrollFrame, "TOPLEFT", 0, -(i-1)*LINE_HEIGHT)
--     text:SetWidth(300)
--     text:SetJustifyH("LEFT")
--     textLines[i] = text
-- end

-- -- Scrollbar construction
-- local ScrollBar = CreateFrame("Frame", nil, LedgerFrame)
-- ScrollBar:SetWidth(24)
-- ScrollBar:SetPoint("TOPRIGHT", ScrollFrame, "TOPRIGHT", 12, 0)
-- ScrollBar:SetPoint("BOTTOMRIGHT", ScrollFrame, "BOTTOMRIGHT", 12, 0)

-- -- Scroll track background
-- local Track = ScrollBar:CreateTexture(nil, "BACKGROUND")
-- Track:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
-- Track:SetTexCoord(0, 0.45, 0, 0.98)
-- Track:SetAllPoints()

-- -- Thumb texture
-- local Thumb = ScrollBar:CreateTexture(nil, "ARTWORK")
-- Thumb:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button")
-- Thumb:SetWidth(24)
-- Thumb:SetHeight(24)

-- -- Scroll buttons
-- local UpButton = CreateFrame("Button", nil, ScrollBar)
-- UpButton:SetWidth(24)
-- UpButton:SetHeight(24)
-- UpButton:SetPoint("TOP", ScrollBar, "TOP")
-- UpButton:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Up")
-- UpButton:SetPushedTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Down")
-- UpButton:SetDisabledTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Disabled")

-- local DownButton = CreateFrame("Button", nil, ScrollBar)
-- DownButton:SetWidth(24)
-- DownButton:SetHeight(24)
-- DownButton:SetPoint("BOTTOM", ScrollBar, "BOTTOM")
-- DownButton:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Down")
-- DownButton:SetPushedTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Down")
-- DownButton:SetDisabledTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar-Button-Disabled")

-- -- Scrollbar logic
-- local currentScroll = 0
-- local maxScroll = 0
-- local isDragging = false

-- local function UpdateScroll()
--     maxScroll = math.max(0, #Page.pages[Page.currentPage] - VISIBLE_LINES)
--     currentScroll = math.min(currentScroll, maxScroll)

--     -- Update thumb position
--     local ratio = maxScroll > 0 and currentScroll / maxScroll or 0
--     Thumb:SetPoint("CENTER", ScrollBar, "TOP", 0, -ratio * (ScrollBar:GetHeight() - Thumb:GetHeight()) - 12)

--     -- Update text positions
--     for i = 1, #textLines do
--         local lineIndex = i + currentScroll
--         if lineIndex <= #Page.pages[Page.currentPage] then
--             textLines[i]:SetText(Page.pages[Page.currentPage][lineIndex] or "")
--             textLines[i]:Show()
--         else
--             textLines[i]:Hide()
--         end
--     end

--     -- Update button states
--     UpButton:SetEnabled(currentScroll > 0)
--     DownButton:SetEnabled(currentScroll < maxScroll)
-- end

-- -- Scrollbar interaction
-- UpButton:SetScript("OnClick", function()
--     currentScroll = math.max(0, currentScroll - 1)
--     UpdateScroll()
--     PlaySound("igAbilityPageTurn")
-- end)

-- DownButton:SetScript("OnClick", function()
--     currentScroll = math.min(maxScroll, currentScroll + 1)
--     UpdateScroll()
--     PlaySound("igAbilityPageTurn")
-- end)

-- Thumb:SetScript("OnMouseDown", function()
--     isDragging = true
--     this:GetParent():SetScript("OnUpdate", function()
--         if isDragging then
--             local _, y = GetCursorPosition()
--             local scale = this:GetEffectiveScale()
--             y = y / scale

--             local minY = this:GetTop() - ScrollBar:GetHeight() + Thumb:GetHeight()/2
--             local maxY = this:GetTop() - Thumb:GetHeight()/2
--             local ratio = (y - minY) / (maxY - minY)

--             currentScroll = math.floor(ratio * maxScroll + 0.5)
--             UpdateScroll()
--         end
--     end)
-- end)

-- Thumb:SetScript("OnMouseUp", function()
--     isDragging = false
--     this:GetParent():SetScript("OnUpdate", nil)
-- end)

-- -- Modify the Page table and functions:
-- local Page = {
--     currentPage = 1,
--     pages = {
--         {"Line 1", "Line 2", "Line 3", "Line 4", "Line 5", "Line 6", "Line 7", "Line 8", "Line 9", "Line 10"},
--         {"Page 2 Line 1", "Page 2 Line 2", "Page 2 Line 3"},
--         {"Page 3 Content 1", "Page 3 Content 2", "Page 3 Content 3", "Page 3 Content 4"}
--     }
-- }

-- function Page:SetPage(page)
--     self.currentPage = math.max(1, math.min(page, table.getn(self.pages)))
--     PageText:SetText("Page "..self.currentPage)
--     currentScroll = 0  -- Reset scroll when changing pages
--     UpdateScroll()

--     -- Keep original button state logic
--     PrevButton:SetEnabled(self.currentPage > 1)
--     NextButton:SetEnabled(self.currentPage < table.getn(self.pages))
-- end