-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

-- Own code
local Ledger, Money
local Debug, Loader

local main = function ()
    Ledger = {
        name = "Ledger",
        DEBUG = true,
        LOG_LEVEL = "TRACE",
        LOG_COLOR = "",
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

        self:UI(Frame)
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
        money = 0,
        DEBUG = true,
        LOG_LEVEL = "TRACE",
        LOG_COLOR = "39FF14",
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

-- Lua fixes
function id(_)
    return string.sub(tostring(_), -8)
end
function len(_)
    if type(_) == "table" and _["n"] then
        return table.getn(_)
    end
end

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

function table.prepend(source, target)
    -- copy of target
    local copy = {}

    for idx = 1,table.getn(source) do
        if idx ~= "n" then
            copy[idx] = source[idx]
        end
    end

    for idx = 1,table.getn(target) do
        if idx ~= "n" then
            copy[idx+table.getn(source)] = target[idx]
        end
    end
    table.setn(copy, table.getn(source) + table.getn(target))

    return copy
end

-- WoW print.
function print(_, ...)
    local msg = ""
    local args = arg

    if type(_) == "table" then
        if _.name then
            msg = _.name .. ": "
        else
            msg = id(_)
        end
    elseif type(_) == "string" then
        args = table.prepend({_}, args)
    end

    for idx = 1,table.getn(args) do
        if idx ~= "n" then
            value = args[idx]
        
            if not value then
                msg = msg .. "nil"
            elseif type(value) == "table" or type(value) == "function" then
                msg = msg .. id(value)
            elseif type(value) == "boolean" or type(value) == "number" then
                msg = msg .. tostring(value)
            else
                msg = msg .. value
            end
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(msg);
end

-- API Hooks
local _CreateFrame = CreateFrame
CreateFrame = function(...)
    local Frame = _CreateFrame(unpack(arg))

    function Frame:CreateFrame(type, name, parent, ...)
        local parent
        if not parent then
            parent = self
        end
        return CreateFrame(type, name, parent, unpack(arg))
    end

    function Frame:Texture(name, type, width, height, texture, ...)
        local Texture = self:CreateTexture(name, type)
        Texture:SetTexture(texture)
        if width then
            Texture:SetWidth(width)
        end
        if height then
            Texture:SetHeight(height)
        end
        return Texture
    end

    function Frame:SetSize(width, height)
        if width then
            self:SetWidth(width)
        end
        if height then
            self:SetHeight(height)
        end
    end

    function Frame:Debug()
        Frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",  -- Optional, background texture
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",  -- Optional, border texture
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        Frame:SetBackdropColor(0, 0, 1, 0.5)  -- Set background to blue with some transparency
        Frame:SetBackdropBorderColor(1, 0, 0, 1)  -- Set border to red
    end


    function Frame:Dropdown(label, width, data)
            -- Initialize the dropdown menu
        local function Initialize()
    
            for i, val in ipairs(data) do
                local info = {
                    text = val,
                    value = i,
                    arg1 = i
                }
                info.func = function(value)
                    UIDropDownMenu_SetText(data[value], Frame)
                end
                UIDropDownMenu_AddButton(info)
            end
        end
    
        UIDropDownMenu_Initialize(self, Initialize)
        UIDropDownMenu_SetWidth(width, self)
        UIDropDownMenu_SetText(label, self)
    
        return Frame
    end

    return Frame
end

-- Debug
Debug = {
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
    color = "|cffffd700"
    if caller.LOG_COLOR and caller.LOG_COLOR ~= "" then
        color = "|cff" .. caller.LOG_COLOR
    end

    self:print(caller, Debug.INFO, color, unpack(arg))
end
function Debug:trace(caller, ...)
    if not caller or caller.LOG_LEVEL ~= self.TRACE then
        return
    end
    color = "|cffffd700"
    if caller.LOG_COLOR and caller.LOG_COLOR ~= "" then
        color = "|cff" .. caller.LOG_COLOR
    end
    self:print(caller, Debug.TRACE, color, unpack(arg))
end


-- Loader lib
Loader = {
    name = "Loader",
    DEBUG = true,
    LOG_LEVEL="TRACE",
    LOG_COLOR="7DF9FF",
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

main()

-- UI
function Ledger:UI(Frame)
    local LedgerFrame
    local Title, DragTitle, TitleDate, Icon, DragIcon, CloseButton
    local BackgroundTL, BackgroundTR, BackgroundBL, BackgroundBR
    local ScrollContainer, ScrollFrame, ScrollBar, ContentFrame
    local PrevButton, NextButton
    local DayDropdown, MonthDropdown

    local day, month, year
    local days = {1,2,3,4,6,7,9,10,11,15,20,21,22,25,26,27,28}
    local monthNames = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

    LedgerFrame = CreateFrame("Frame", "LedgerFrame", UIParent)
    LedgerFrame:SetWidth(384)
    LedgerFrame:SetHeight(512)
    LedgerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    LedgerFrame:SetMovable(true)
    LedgerFrame:EnableMouse(true)
    LedgerFrame:RegisterForDrag("LeftButton")



    -- Function to update the day display or any other UI elements
    function UpdateDateDisplay()
        -- This function will update the date displayed on the UI
        -- You can add code to recalculate the positions of day buttons or any other UI elements
        print("Current Day: " .. day)
    end
    function PrevDay()
        -- Decrease day by 1 (you may want to wrap around to previous month if needed)
        day = day - 1
        if day < 1 then
            day = 31  -- Wrap around if going below 1
        end
        -- Update the displayed day (recalculate positions or other elements)
        UpdateDateDisplay()
    end
    function NextDay()
        -- Increase day by 1 (you may want to wrap around to next month if needed)
        day = day + 1
        if day > 31 then
            day = 1  -- Wrap around if going above 31
        end
        -- Update the displayed day (recalculate positions or other elements)
        UpdateDateDisplay()
    end
    local function AddLine(text)
        local numLines = ContentFrame.numLines or 0
        local yOffset = -numLines * 20  -- adjust vertical spacing as needed

        local line = ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        line:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, yOffset)
        line:SetText(text)

        ContentFrame.numLines = numLines + 1
        local newHeight = ContentFrame.numLines * 20

        ContentFrame:SetHeight(newHeight)

        -- Fix the off-by-one error
        local maxScroll = math.max(0, newHeight - ScrollFrame:GetHeight() - 350) -- @todo: magic number "350"?? prevents overscroll

        -- Apply new scroll limits
        ScrollBar:SetMinMaxValues(0, maxScroll)

        -- Hide scrollbar if not needed
        if maxScroll <= 0 then
            ScrollBar:Hide()
            ScrollBar:SetValue(0)  -- Reset scroll position
        else
            ScrollBar:Show()
        end
    end
    local function GetDaysInMonth(month)
        local daysInMonth = {
            31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
        }
        return daysInMonth[month]
    end


    Title = LedgerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Title:SetText("Ledger")
    Title:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 80, -18)

    TitleDate = LedgerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    TitleDate:SetText("Sunday 16/2")
    TitleDate:SetPoint("TOP", LedgerFrame, "TOP", -0, -18)

    DragTitle = LedgerFrame:CreateFrame("Frame")
    DragTitle:SetSize(265, 28)
    DragTitle:SetPoint("TOP", LedgerFrame, "TOP", 5, -10)
    DragTitle:EnableMouse(true)
    DragTitle:SetScript("OnMouseDown", function() LedgerFrame:StartMoving() end)
    DragTitle:SetScript("OnMouseUp", function() LedgerFrame:StopMovingOrSizing() end)
    DragTitle:Debug()

    Icon = LedgerFrame:Texture('Icon', 'BACKGROUND', 58, 58, [[Interface\Spellbook\Spellbook-Icon]])
    Icon:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 10, -8)

    DragIcon = LedgerFrame:CreateFrame("Frame")
    DragIcon:SetPoint("TOP", Icon, "TOP", 0, 0) 
    DragIcon:SetSize(58, 58) 
    DragIcon:EnableMouse(true)
    DragIcon:SetScript("OnMouseDown", function() LedgerFrame:StartMoving() end)
    DragIcon:SetScript("OnMouseUp", function() LedgerFrame:StopMovingOrSizing() end)
    DragIcon:Debug()

    BackgroundTL = LedgerFrame:Texture("BackgroundTL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopLeft]])
    BackgroundTL:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 0, 0)
    BackgroundTR = LedgerFrame:Texture("BackgroundTR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopRight]])
    BackgroundTR:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", 0, 0)
    BackgroundBL = LedgerFrame:Texture("BackgroundBL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomLeft]])
    BackgroundBL:SetPoint("BOTTOMLEFT", LedgerFrame, "BOTTOMLEFT", 0, 0)
    BackgroundBR = LedgerFrame:Texture("BackgroundBR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomRight]])
    BackgroundBR:SetPoint("BOTTOMRIGHT", LedgerFrame, "BOTTOMRIGHT", 0, 0)

    CloseButton = LedgerFrame:CreateFrame("Button", nil, LedgerFrame, "UIPanelCloseButton")
    CloseButton:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", -30, -8)

    PrevButton = LedgerFrame:CreateFrame("Button", "PrevDayButton")
    PrevButton:SetSize(28, 28)
    PrevButton:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 91, -40)
    PrevButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    PrevButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])
    PrevButton:SetScript("OnClick", PrevDay)

    NextButton = LedgerFrame:CreateFrame("Button", "NextDayButton")
    NextButton:SetSize(28, 28)
    NextButton:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", -44, -40)
    NextButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    NextButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    NextButton:SetScript("OnClick", NextDay)

    -- Dropdown
    DayDropdown = LedgerFrame:CreateFrame("Frame", "DayDropdown", LedgerFrame, "UIDropDownMenuTemplate")
    DayDropdown:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 100, -40)
    DayDropdown:Dropdown("Day", 60, days)

    MonthDropdown = LedgerFrame:CreateFrame("Frame", "MonthDropdown", LedgerFrame, "UIDropDownMenuTemplate")
    MonthDropdown:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 180, -40)
    MonthDropdown:Dropdown("Month", 100, monthNames)



    -- Scroll
    ScrollContainer = LedgerFrame:CreateFrame("Frame", "LedgerScrollContainer")
    ScrollContainer:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 22, -80)
    ScrollContainer:SetPoint("BOTTOMRIGHT", LedgerFrame, "BOTTOMRIGHT", -65, 80)

    ScrollFrame = ScrollContainer:CreateFrame("ScrollFrame", "LedgerScrollFrame")
    ScrollFrame:SetAllPoints(ScrollContainer)
    ScrollFrame:EnableMouseWheel(true)
    ScrollFrame:SetHeight(0)
    ScrollFrame:SetScript("OnMouseWheel", function()
        local current = ScrollBar:GetValue()
        local newVal = current - (arg1 * 20)  -- adjust the multiplier for scroll speed
        if newVal < 0 then
            newVal = 0
        end
        ScrollBar:SetValue(newVal)
    end)

    ScrollBar = ScrollContainer:CreateFrame("Slider", "LedgerScrollBar", ScrollContainer, "UIPanelScrollBarTemplate")
    ScrollBar:SetPoint("TOPLEFT", ScrollContainer, "TOPRIGHT", 4, -11)
    ScrollBar:SetPoint("BOTTOMLEFT", ScrollContainer, "BOTTOMRIGHT", 4, 19)
    ScrollBar:SetMinMaxValues(1, 200)
    ScrollBar:SetValueStep(1)
    ScrollBar:SetWidth(16)
    ScrollBar:SetScript("OnValueChanged", function()
        ScrollFrame:SetVerticalScroll(arg1)
    end)

    ContentFrame = ScrollFrame:CreateFrame("Frame", "LedgerContentFrame")
    ContentFrame:SetWidth(354)
    ContentFrame:SetHeight(0)  -- initial height; expands as lines are added.
    ContentFrame:SetPoint("TOPLEFT", ScrollFrame, "TOPRIGHT", 6, -22)
    ContentFrame:SetPoint("BOTTOMLEFT", ScrollFrame, "BOTTOMRIGHT", 4, 20)
    ScrollFrame:SetScrollChild(ContentFrame)
    ScrollBar:SetValue(0)

    AddLine([[Mail "Test" from Kabinner +30c]])
    AddLine([[Mail "Test" from Kabinner +1s]])
    AddLine([[Mail "Test" from Kabinner +50c]])
    AddLine([[Mail "Test" to Kabgilder -30c]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Third Entry]])
    AddLine([[Foo Entry]])
    AddLine([[Last Entry]])
    return LedgerFrame
end