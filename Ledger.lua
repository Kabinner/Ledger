local _G = getfenv(0)

local function id(_)
    return string.sub(tostring(_), -8)
end
local function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end
local Addon = {
    name = "Ledger",
    Frame = nil,
    events = {},
    debug = true,
    object = nil,
    object_map = {},
    object_map_reversed = {}
}
function Addon:new(object)
    self.Frame = CreateFrame("Frame", "FRAME_" .. string.upper("%u*", self.name), UIParent)
    self.object = object
    for function_name in self.object do
        if function_name ~= "new" and type(self.object[function_name]) == "function" then
            self:debug("Mapping ", function_name, " to: ", self.object[function_name])
            self.object_map[function_name] = self.object[function_name]

            self:debug("Mapping ", id(self.object[function_name]), " to: ", function_name)
            self.object_map_reversed[id(self.object[function_name])] = self.object[function_name]
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
function Addon:callback(callback)
    return self.object_map_reversed[id(callback)](self.object)
end
function Addon:dispatch(e)
    if e == "ADDON_LOADED" and arg1 == self.name then
        self.object["load"](self.object, self.Frame)
    elseif e ~= "ADDON_LOADED" then
        func = self.events[e]
        self:debug(e, " -> ", func)
        self:callback(func, self.Frame)
    end
end
function Addon:load()

    self.Frame:SetScript('OnEvent', function () self:dispatch(event) end)
end

function UI()
    local LedgerFrame = CreateFrame("Frame", "FRAME_LEDGER_PANEL", Addon.Frame)
    LedgerFrame:SetWidth(384)
    LedgerFrame:SetHeight(512)
    LedgerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    LedgerFrame:EnableMouse(true)
    LedgerFrame:SetMovable(true)
    LedgerFrame:SetUserPlaced(true)

    LedgerFrame:RegisterForDrag("LeftButton")
    LedgerFrame:SetScript("OnDragStart", function() LedgerFrame:StartMoving() end)
    LedgerFrame:SetScript("OnDragStop", function() LedgerFrame:StopMovingOrSizing() end)

    local CloseButton = CreateFrame("Button", "SpellBookCloseButton", LedgerFrame, "UIPanelCloseButton")
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

    local TitleText = LedgerFrame:CreateFontString("SpellBookTitleText", "ARTWORK", "GameFontNormal")
    TitleText:SetPoint("CENTER", LedgerFrame, "CENTER", 6, 230)
    TitleText:SetText("Ledger")

    local PageText = LedgerFrame:CreateFontString("SpellBookPageText", "ARTWORK", "GameFontNormal")
    PageText:SetWidth(102)
    PageText:SetPoint("BOTTOM", LedgerFrame, "BOTTOM", -14, 96)
    PageText:SetText("Page 1")

    LedgerFrame:Show()
end

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
function Ledger:load() 
    self:print("Load.")
    UI()
end
function Ledger:enable() 
    self:print("Enable.")

    SLASH_LEDGER1 = "/ledger"
    SlashCmdList["LEDGER"] = function(msg)
        addon:debug("/ledger command.")
    end
end
function Ledger:disable() 
end

ledger = Ledger:new()
addon = Addon:new(ledger)

addon:on("ADDON_LOADED", ledger.load)
addon:on("PLAYER_LOGIN", ledger.enable)
addon:on("PLAYER_LOGOUT", ledger.disable)

addon:load()
