-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

-- Utils
local function id(_)
    return string.sub(tostring(_), -8)
end
local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Addon
local Addon = {
    name = "Ledger",
    Frame = nil,
    events = {},
    debug = true,
    object = nil,
    object_map = {},
    object_map_reversed = {},
    object_map_lookup = {}
}
function Addon:new(object)
    self.Frame = CreateFrame("Frame", "FRAME_" .. string.upper("%u*", self.name), UIParent)
    self:debug("Frame: ", self.Frame)
    self.object = object
    for function_name in self.object do
        if function_name ~= "new" and type(self.object[function_name]) == "function" then
            self:debug("Mapping ", self.name .. ":" .. function_name, "to: ", self.object[function_name])
            self.object_map[function_name] = self.object[function_name]

            self:debug("Mapping ", id(self.object[function_name]), " to: ", self.name .. ":" .. function_name .. "")
            self.object_map_reversed[id(self.object[function_name])] = self.object[function_name]

            self.object_map_lookup[id(self.object[function_name])] = function_name
        end
    end

    return setmetatable(Addon, { __index = Addon })
end
function Addon:debug(...)
    if not self.debug then return; end

    local msg = ""
    for idx in arg do
        if idx == "n" then
            break
        end
        local value = arg[idx]

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
    print("|cffffd700" .. self.name .. " [DEBUG]: " .. msg)
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
        self:debug("Addon:dispatch: ", e, " -> ", self.name .. ":" .. self.object_map_lookup[id(func)], func)
        self:callback(func)
    end
end
function Addon:load()
    self.Frame:SetScript('OnEvent', function () self:dispatch(event) end)
end


-- Begin
Ledger = {}
function Ledger:new()
    return setmetatable(Ledger, { __index = Ledger })
end
function Ledger:print(...)
    local msg = ""
    for idx in arg do
        if idx == "n" then
            break
        end
        local value = arg[idx]

        if type(value) == "table" then
            msg = msg .. tostring(value) .. " "
        elseif type(value) == "function" then
            msg = msg .. tostring(value) .. " "
        else
            msg = msg .. value .. " "
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(Addon.name .. ": " .. msg);
end
function Ledger:load(Frame)
    Addon:debug("Ledger:load", "Frame", Frame)
    self:print("Load.")
    self:UI(frame)
end
function Ledger:enable(Frame) 
    self:print("Enable.")
    Addon:debug("Ledger:enable", "Frame", Frame)

    SLASH_LEDGER1 = "/ledger"
    SlashCmdList["LEDGER"] = function(msg)
        addon:debug("/ledger command.")
    end
end
function Ledger:disable() 
end

ledger = Ledger:new()
addon = Addon:new(ledger)

Addon:debug("Ledger: ", ledger)

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
    LedgerFrame:SetScript("OnDragStart", function() LedgerFrame:StartMoving() end)
    LedgerFrame:SetScript("OnDragStop", function() LedgerFrame:StopMovingOrSizing() end)

    local CloseButton = CreateFrame("Button", "FRAME_LEDGER_PANEL_BUTTON_CLOSE", LedgerFrame, "UIPanelCloseButton")
    CloseButton:SetPoint("CENTER", LedgerFrame, "TOPRIGHT", -44, -25)
    CloseButton:SetScript("OnClick", function() LedgerFrame:Hide() end)

    local Icon = LedgerFrame:CreateTexture(nil, "BACKGROUND")
    Icon:SetTexture('Interface\\Spellbook\\Spellbook-Icon')
    Icon:SetWidth(58)
    Icon:SetHeight(58)
    Icon:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 10, -8)

    local TopLeft = LedgerFrame:CreateTexture(nil, "ARTWORK")
    TopLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopLeft")
    TopLeft:SetWidth(256)
    TopLeft:SetHeight(256)
    TopLeft:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 0, 0)

    local TopRight = LedgerFrame:CreateTexture(nil, "ARTWORK")
    TopRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-TopRight")
    TopRight:SetWidth(128)
    TopRight:SetHeight(256)
    TopRight:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", 0, 0)

    local BottomLeft = LedgerFrame:CreateTexture(nil, "ARTWORK")
    BottomLeft:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotLeft")
    BottomLeft:SetWidth(256)
    BottomLeft:SetHeight(256)
    BottomLeft:SetPoint("BOTTOMLEFT", LedgerFrame, "BOTTOMLEFT", 0, 0)

    local BottomRight = LedgerFrame:CreateTexture(nil, "ARTWORK")
    BottomRight:SetTexture("Interface\\Spellbook\\UI-SpellbookPanel-BotRight")
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
        pages = {
            { "Page 1 Line 1", "Page 1 Line 2", "Page 1 Line 3" },
            { "Page 2 Line 1", "Page 2 Line 2", "Page 2 Line 3" },
            { "Page 3 Line 1", "Page 3 Line 2", "Page 3 Line 3" }
        }
    }

    local PrevButton = CreateFrame("Button", "FRAME_LEDGER_PREV_BUTTON", LedgerFrame, "UIPanelButtonTemplate")
    PrevButton:SetPoint("BOTTOM", LedgerFrame, "BOTTOMLEFT", 50, 85)
    PrevButton:SetWidth(32)
    PrevButton:SetHeight(32)

    local normTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    normTex:SetAllPoints()
    normTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    PrevButton:SetNormalTexture(normTex)

    local pushTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    pushTex:SetAllPoints()
    pushTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    PrevButton:SetPushedTexture(pushTex)

    local disableTex = PrevButton:CreateTexture(nil, "BACKGROUND")
    disableTex:SetAllPoints()
    disableTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
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
    normTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    NextButton:SetNormalTexture(normTex)

    local pushTex = NextButton:CreateTexture(nil, "BACKGROUND")
    pushTex:SetAllPoints()
    pushTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    NextButton:SetPushedTexture(pushTex)

    local disableTex = NextButton:CreateTexture(nil, "BACKGROUND")
    disableTex:SetAllPoints()
    disableTex:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    NextButton:SetDisabledTexture(disableTex)

    NextButton:SetScript("OnClick", function()
        PlaySound("igAbiliityPageTurn")
        Page:SetPage(Page.currentPage + 1)
    end)

    PrevButton:Disable(false)
    Addon:debug("pages: ", table.getn(Page.pages))
    if table.getn(Page.pages) <= 1 then
        NextButton:Enable(false)
    end


    
    function Page:SetPage(page)
        self.currentPage = math.max(1, math.min(page, table.getn(self.pages)))
        PageText:SetText("Page "..self.currentPage)
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
            _G["LedgerText"..i]:SetText(content[i] or "")
        end
    end

    local textY = -70
    for i = 1, 3 do
        local text = LedgerFrame:CreateFontString("LedgerText"..i, "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 30, textY)
        text:SetWidth(324)
        text:SetJustifyH("LEFT")
        textY = textY - 30
    end
    Page:UpdatePageContent()
    LedgerFrame:Show()
end
