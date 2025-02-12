-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

local main = function ()
    -- Own code
    Ledger = {
        name = "Ledger",
        DEBUG_LEVEL = "TRACE",
        DEBUG = true,
    }

    function Ledger:new()
        Ledger.__index = Ledger
        local instance = {}
        setmetatable(instance, Ledger)
        Debug:trace(Ledger, "new")
        return instance
    end

    function Ledger:load(Frame)
        print(self, "load Frame: ", Frame)

        Frame = self:Panel(Frame)
        -- local Icon        = Frame:Texture("BACKGROUND", 58, 58, [[Interface\Spellbook\Spellbook-Icon]]).SetPoint("TOPLEFT", Frame, "TOPLEFT", 10, -8)
        -- local TopLeft     = Frame:Texture("ARTWORK", 256, 256, [[Interface\Spellbook\UI-SpellbookPanel-TopLeft]]).SetPoint("TOPLEFT", Frame, "TOPLEFT",0, 0)
        -- local TopRight    = Frame:Texture("ARTWORK", 256, 256, [[Interface\Spellbook\UI-SpellbookPanel-TopRight]]).SetPoint("TOPRIGHT", Frame, "TOPRIGHT", 0, 0)
        -- local BottomLeft  = Frame:Texture("ARTWORK", 256, 256, [[Interface\Spellbook\UI-SpellbookPanel-BotLeft]]).SetPoint("BOTTOMLEFT", Frame, "BOTTOMRLEFT", 0, 0)
        -- local BottomRight = Frame:Texture("ARTWORK", 128, 256, [[Interface\Spellbook\UI-SpellbookPanel-BotRight]]).SetPoint("BOTTOMRIGHT", Frame, "BOTTOMRIGHT", 0, 0)

    end

    function Ledger:enable(Frame)
        print(self, "Enable. Frame: ", Frame)

        SLASH_LEDGER1 = "/ledger"
        SlashCmdList["LEDGER"] = function(msg)
            Debug:log(self, "/ledger command.")
        end
    end
    function Ledger:disable()
    end

    Money = {
        name = "Money",
        DEBUG_LEVEL = "TRACE",
        DEBUG = true,
        money = 0,
    }
    function Money:new()
        Money.__index = Money
        local instance = {}
        setmetatable(instance, Money)
        Debug:trace(Money, "new")
        return instance
    end

    function Money:enable(Frame)
        self.money = GetMoney()
        print(self, "Enable. Money: ", self.money, " copper Frame:", Frame)
    end

    function Money:track(Frame, ...)
        Debug:trace(self, "args: ", string.unpack(arg))
        local money = GetMoney()
        local difference = money - self.money
        if difference ~= 0 then
            local action = (difference > 0) and "Gained" or "Lost"
            print(self, "track ", action, " ", math.abs(difference), " copper")
        end
        self.money = money
    end

    loader = Loader:new()
    ledger = Ledger:new()
    loader:init(ledger)
    loader:on("ADDON_LOADED", ledger.load)
    loader:on("PLAYER_LOGIN", ledger.enable)
    loader:on("PLAYER_LOGOUT", ledger.disable)
    loader:listen()


    loader2 = Loader:new()
    money = Money:new()
    loader2:init(money)
    loader2:on("PLAYER_LOGIN", money.enable)
    loader2:on("PLAYER_MONEY", money.track)
    loader2:hook("RepairAllItems", money.track)
    loader2:hook("UseContainerItem", money.track)
    loader2:hook("PickupMerchantItem", money.track)
    loader2:hook("SendMail", money.track)
    loader2:hook("PlaceAuctionBid", money.track)
    loader2:hook("PickupPlayerMoney", money.track)
    loader2:listen()

end

-- API Hooks
local _CreateFrame = CreateFrame
CreateFrame = function(...)
    Frame = _CreateFrame(unpack(arg))
    function Frame:Texture(type, width, height, texture, opts)
        Debug:log(type, " ", texture, " ", width, " ",  height, " ",  opts)
        for func, args in pairs(opts) do
            Debug:log("function call: ", func, " ", string.unpack(args))
        end
    end

    return Frame
end

utils = (function ()
    function id(_)
        return string.sub(tostring(_), -8)
    end
    function len(_)
        if type(_) == "table" and _["n"] then
            return table.getn(_)
        end
    end

    string = setmetatable(string, {})
    function string.unpack(_)
        if type(_) ~= "table" or not table.getn(_) then
            return
        end
        args = {}
        for idx, value in ipairs(_) do
            args[idx] = value .. " "
        end  
        return unpack(args)
    end    

    function print(_, ...)
        local msg = ""

        if type(_) == "table" then
            if _.name then
                msg = _.name .. ": "
            else
                msg = id(_)
            end
        elseif type(_) == "string" then
            msg = _
        end

        for idx, value in ipairs(arg) do
            if type(value) == "table" or type(value) == "function" then
                msg = msg .. id(value)
            elseif type(value) == "boolean" or type(value) == "number" then
                msg = msg .. tostring(value)
            elseif value == nil then
                msg = msg .. "nil"
            else
                msg = msg .. value
            end
        end

        DEFAULT_CHAT_FRAME:AddMessage(msg);
    end
end)()

debug = (function () 
    -- Debug
    Debug = {
        DEBUG_LEVEL="TRACE",
        INFO="INFO",
        TRACE="TRACE",
    }
    function Debug:print(_, level, color, ...)
        if type(_) == "table" and not _.DEBUG then
            return
        end

        local msg = ""
        if type(_) == "string" then
            msg = _
        end
        
        if type(_) == "table" and _.name then 
            msg =  color .. "[".. level .."] ".. _.name .."[" .. id(_) .."]:"
        end
        print(msg, unpack(arg))

    end
    function Debug:log(caller, ...)
        self:print(caller, Debug.INFO, "|cffffd700", unpack(arg))
    end
    function Debug:trace(caller, ...)
        if not caller or caller.DEBUG_LEVEL ~= self.TRACE then
            return
        end
        self:print(caller, Debug.TRACE, "|cffffd700", unpack(arg))
    end
end)()

loader = (function ()
    -- Loader lib
    Loader = {
        name = "Loader",
        DEBUG = true,
        DEBUG_LEVEL="TRACE",
    }
    function Loader:new(object)
        Loader.__index = Loader

        local instance = {    
            name = self.name,
            Frame = {},
            events = {},
            object = {},
            object_index = {},
            object_map = {},
            object_map_reversed = {},
            object_map_lookup = {},
            hooks = {},
        }
        setmetatable(instance, Loader)
        Debug:trace(Loader, "new")
        return instance
    end
    function Loader:map()
        for function_name,func in pairs(self.object_index) do
            if function_name ~= "new" and type(func) == "function" then
                local callback = self.object_index[function_name]
                Debug:trace(self, "map: ", self.object.name, "[", id(self.object), "] ", self.object.name, ".", function_name, " = ", callback)
                self.object_map[function_name] = callback

                Debug:trace(self, "map: ", self.object.name, "[", id(self.object), "] ", id(callback), " = ", self.object.name, ".", function_name)
                self.object_map_reversed[id(callback)] = callback

                self.object_map_lookup[id(callback)] = function_name
            end
        end
    end
    function Loader:init(object)
        self.Frame = CreateFrame("Frame", "FRAME_" .. string.upper("%u*", self.name), UIParent)
        self.object_index = getmetatable(object).__index
        self.object = object
        
        Debug:trace(self, "init ", self.object.name, "[", id(self.object), "/", id(self.object_index), "]", " Frame: ", self.Frame)
        self:map()
    end

    function Loader:on(event, callback)
        Debug:trace(self, "on ", self.object.name, "[", id(self.object), "] ", event, " -> ", self.object.name, ":", self.object_map_lookup[id(callback)])
        self.Frame:RegisterEvent(event)
        self.events[event] = callback
    end
    function Loader:callback(callback, ...)
        Debug:trace(self, "callback: ", self.object.name, "[", id(self.object), "] ", self.object.name, ":", self.object_map_lookup[id(callback)])

        return self.object_map_reversed[id(callback)](self.object_index, self.Frame, unpack(arg))
    end
    function Loader:hook(func, callback)
        Debug:trace(self, "hook: ", func, " -> ", self.object.name, ":", self.object_map_lookup[id(callback)])

        if not _G[func] then
            Debug:trace(self, "ERROR: ", func, " -> ", self.object.name, ":", self.object_map_lookup[id(callback)])
            return
        end

        self.hooks[func] = _G[func]
        _G[func] = function(...)
            args = {}
            args[1] = func
            for idx in ipairs(arg) do
                args[idx+1] = arg
            end
            Debug:trace(self, "args: ", string.unpack(args))
            self:callback(callback, unpack(args))
            return self.hooks[func](unpack(arg))
        end
    end
    function Loader:dispatch(e)
        local func = nil
        if e == "ADDON_LOADED" and arg1 == self.object.name then
            func = self.object["load"]
        elseif e ~= "ADDON_LOADED" then
            func = self.events[e]
        else
            return
        end

        Debug:trace(self, "dispatch ", e, " -> ", self.object.name, ":", self.object_map_lookup[id(func)], "[", func, "]")
        self:callback(func)
    end
    function Loader:listen()
        Debug:trace(self, "listen ", self.object.name, "[", id(self.object), "] ", "Frame: ", self.Frame)

        self.Frame:SetScript('OnEvent', function() self:dispatch(event) end)
    end
end)()

main()

-- @todo Scrollbar
-- @todo Fill with text
-- @todo Layout 
function Ledger:Panel(Frame)
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
    Debug:log("pages: ", table.getn(Page.pages))
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
