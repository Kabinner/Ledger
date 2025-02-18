-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

-- Own code
local Debug
local Dispatcher, Ledger, Money

local main = function ()

    local event = Dispatcher:new()

    ledger = Ledger:new(event)
    money = Money:new()

    Debug:trace("Event.add: ", event)
    event:bind(ledger)
    event:bind(money)

    event:on("ADDON_LOADED", ledger.load)
    event:on("PLAYER_LOGIN", ledger.enable)
    event:on("PLAYER_LOGOUT", ledger.disable)
    event:on("PLAYER_LOGIN", money.enable)

    event:on("BUTTON_NEXT_ONCLICK", ledger.NextDay)
    event:on("BUTTON_PREV_ONCLICK", ledger.PrevDay)
    event:on("DATE_CHANGED", ledger.Update)

    event:on("PLAYER_MONEY", money.track)

    event:hook(RepairAllItems, money.track)
    event:hook(UseContainerItem, money.track)
    event:hook(PickupMerchantItem, money.track)
    event:hook(SendMail, money.track)
    event:hook(PlaceAuctionBid, money.track)
    event:hook(PickupPlayerMoney, money.track)
    event:listen()

end


Ledger = {
    name = "Ledger",
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "",
    day = 1,
    Title = nil, DragTitle = nil, TitleDate = nil, Icon = nil, DragIcon = nil, CloseButton = nil,
    BackgroundTL = nil, BackgroundTR = nil, BackgroundBL = nil, BackgroundBR = nil,
    ScrollContainer = nil, ScrollFrame = nil, ScrollBar = nil, ContentFrame = nil,
    PrevButton = nil, NextButton = nil,
    DayDropdown = nil, MonthDropdown = nil,
}

function Ledger:new(dispatcher)
    Ledger.__index = Ledger
    local instance = {
        name = self.name,
        day = self.day,
        event = dispatcher,
        LedgerFrame = nil,
    }
    setmetatable(instance, Ledger)
    Debug:trace(Ledger, "new: ", instance, " Dispatcher: ")
    return instance
end

function Ledger:load(Frame)
    Debug:trace(self, "load Frame: ", Frame)

    self:UI(Frame)
end

function Ledger:enable(Frame)
    Debug:trace(self, "Enable. Frame: ", Frame)

    SLASH_LEDGER1 = "/ledger"
    SlashCmdList["LEDGER"] = function(msg)
        Debug:log(self, "/ledger command.")
    end
end
function Ledger:disable()
end
local function AddText(text)
    local numLines = self.ContentFrame.numLines or 0
    local yOffset = -numLines * 20  -- adjust vertical spacing as needed

    local line = ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    line:SetPoint("TOPLEFT", ContentFrame, "TOPLEFT", 0, yOffset)
    line:SetText(text)
    self.event:dispatch("CONTENT_UPDATE")
end
function Ledger:ScrollBar_Update()
    -- Fix the off-by-one error
    local maxScroll = math.max(0, newHeight - self.ScrollFrame:GetHeight() - 350) -- @todo: magic number "350"?? prevents overscroll
    -- Apply new scroll limits
    self.ScrollBar:SetMinMaxValues(0, maxScroll)
    -- Hide scrollbar if not needed
    if maxScroll <= 0 then
        self.ScrollBar:Hide()
        self.ScrollBar:SetValue(0)  -- Reset scroll position
    else
        self.ScrollBar:Show()
    end
end
function Ledger:Content_Update()
    self.ContentFrame.numLines = numLines + 1
    local newHeight = self.ContentFrame.numLines * 20
    self.ContentFrame:SetHeight(newHeight)
end
function Ledger:Update()
    -- self.Content_Update()
    -- self.ScrollBar_Update()

    Debug:trace(self, " UpdateDateDisplay: ", "Current Day: ", self.day)

end
function Ledger:PrevDay(...)
    Debug:trace(self, "PrevDay: day:", self.day)
    self.day = self.day - 1
    if self.day < 1 then
        self.day = 31  -- Wrap around if going below 1
    end
    self.event:dispatch("DATE_CHANGED")
end
function Ledger:NextDay(...)
    Debug:trace(self, "NextDay: day:", self.day)
    self.day = self.day + 1
    if self.day > 31 then
        self.day = 1  -- Wrap around if going above 31
    end
    self.event:dispatch("DATE_CHANGED")
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
    local instance = {
        money = self.money
    }
    setmetatable(instance, Money)
    Debug:trace(Money, "new")
    return instance
end

function Money:enable(Frame)
    self.money = GetMoney()
    Debug:trace(self, "Enable. Money: ", self.money, " copper Frame:", Frame)
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

-- Lua fixes
function id(_)
    return string.sub(tostring(_), -8)
end
function len(_)
    if type(_) == "table" and _["n"] then
        return table.getn(_)
    end
end

function string.unpack(_, sep)
    if type(_) ~= "table" or not table.getn(_) then
        return
    end
    args = {}
    if not sep then
        sep = " "
    end
    for idx = 1,table.getn(_) do
        if idx ~= "n" then
            args[idx] = tostring(_[idx]) .. sep
        end
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
        
            if type(value) == "nil" then
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
-- @todo Add '/r' for developing
-- SLASH_DEV1 = "/r"
-- SlashCmdList["DEV"] = function(msg)
--     Debug:log(self, "reload command.")
-- end

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
        local Texture = self:CreateTexture(name, type, unpack(arg))
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


    function Frame:SetDropdown(label, width, data)
            -- Initialize the dropdown menu
        local function Initialize()
    
            for i, val in ipairs(data) do
                local info = {
                    text = val,
                    value = i,
                    arg1 = i,
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
    LOG_COLOR="ffd700"
}
function Debug:print(_, level, ...)
    if type(_) == "table" and not _.DEBUG then
        return
    end

    local msg = ""
    if type(_) == "string" then
        msg = _
    end

    if type(_) == "table" and _.name then 
        color = "|cff" .. Debug.LOG_COLOR
        if _.LOG_COLOR and _.LOG_COLOR ~= "" then
            color = "|cff" .. _.LOG_COLOR
        end

        msg =  color .. "[".. level .."] ".. _.name .."[" .. id(_) .."]:"
    end
    print(msg, unpack(arg))

end
function Debug:log(caller, ...)

    self:print(caller, Debug.INFO, unpack(arg))
end
function Debug:trace(caller, ...)
    if not caller or type(caller) == 'table' and caller.LOG_LEVEL ~= self.TRACE then
        return
    end
    self:print(caller, Debug.TRACE, unpack(arg))
end


Dispatcher = {
    name = "Dispatcher",
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "7DF9FF",
}

function Dispatcher:new()
    local instance = {
        name = self.name,
        Frame = CreateFrame("Frame", "FRAME_"..string.upper(self.name), UIParent),
        objects = {},
        hooks = {},
    }
    setmetatable(instance, self)
    self.__index = self
    Debug:trace(instance, "new")
    return instance
end

function Dispatcher:bind(obj)
    Debug:trace(self, "add ", obj.name, "[", id(obj), "]")
    
    local obj_data = {
        object = obj,
        object_map = {},
        object_map_reversed = {},
        object_map_lookup = {},
        events = {},
    }
    
    local obj_index = getmetatable(obj).__index
    for fn_name, fn in pairs(obj_index) do
        if fn_name ~= "new" and type(fn) == "function" then
            Debug:trace(self, "map: ", obj.name, "[", id(obj), "] ", obj.name, ".", fn_name)
            local fn_id = id(fn)
            obj_data.object_map[fn_name] = fn
            obj_data.object_map_reversed[fn_id] = fn
            obj_data.object_map_lookup[fn_id] = fn_name
        end
    end
    
    self.objects[obj] = obj_data
    Debug:trace(self, "added ", obj.name, "[", id(obj), "]")
end

function Dispatcher:target(callback)
    local callback_id = id(callback)

    local target_obj
    for obj, data in pairs(self.objects) do
        if data.object_map_reversed[callback_id] then
            target_obj = obj
            return target_obj, data
        end
    end
end

function Dispatcher:hook(fn, callback)

    local callback_id = id(callback)
    local target_obj, obj_data = self:target(callback)
    Debug:trace(self, "hook: ", fn, " -> ", target_obj.name, ":", callback_id)
    
    if not target_obj then
        Debug:trace(self, "ERROR: No object found for callback ", callback_id)
        return
    end
    
    Debug:trace(self, "hook ", target_obj.name, "[", id(target_obj), "] ", 
        event, " -> ", target_obj.name, ":", obj_data.object_map_lookup[callback_id])
    
end
function Dispatcher:on(event, callback)
    local callback_id = id(callback)
    local target_obj, obj_data = self:target(callback)
    
    if not target_obj then
        Debug:trace(self, "ERROR: No object found for callback ", callback_id)
        return
    end
    
    Debug:trace(self, "on ", target_obj.name, "[", id(target_obj), "] ", 
        event, " -> ", target_obj.name, ":", obj_data.object_map_lookup[callback_id])
    
    self.Frame:RegisterEvent(event)
    
    if not obj_data.events[event] then
        obj_data.events[event] = {}
    end
    table.insert(obj_data.events[event], callback)
end

function Dispatcher:dispatch(e)
    for obj, obj_data in pairs(self.objects) do
        if event then
            e = event
        end
        local handlers = obj_data.events[e]
        if handlers then
            if e == "ADDON_LOADED" then
                if arg1 == obj.name then
                    Debug:trace(self, "dispatch: e: ", e, " event: ", event, " obj: ", obj, " args: ", arg1)
                    self:trigger(obj, obj_data, handlers)
                end
            else
                Debug:trace(self, "dispatch: e: ", e, " event: ", event, " obj: ", obj, " args: ", arg1)
                self:trigger(obj, obj_data, handlers)
            end
        end
    end
end

function Dispatcher:trigger(obj, obj_data, handlers, ...)
    for _, callback in ipairs(handlers) do
        local fn_id = id(callback)
        local fn_name = obj_data.object_map_lookup[fn_id] or "unknown"
        Debug:trace(self, "trigger ", obj.name, ":", fn_name, 
            "[", fn_id, "] for ", obj.name, "[", id(obj), "]")
        
        local success, err = pcall(function()
            obj_data.object_map_reversed[fn_id](obj, self.Frame, unpack(arg))
        end)
        
        if not success then
            Debug:trace(self, "ERROR in ", obj.name, ":", fn_name, " - ", err)
        end
    end
end

function Dispatcher:listen()
    Debug:trace(self, "listen on frame ", self.Frame)

    local event
    self.Frame:SetScript("OnEvent", function()
        Debug:trace(self, "Event name: ", event, " type: ", type(event) ," arg1: ", arg1)
        self:dispatch(event)
    end)
end


xpcall(main, function (err)
    print(err)
end)

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

    LedgerFrame = Frame:CreateFrame("Frame", "LedgerFrame", UIParent)
    LedgerFrame:SetWidth(384)
    LedgerFrame:SetHeight(512)
    LedgerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    LedgerFrame:SetMovable(true)

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
    PrevButton:SetScript("OnClick", function () 
        Debug:trace(self, "PrevButton:SetScript:OnClick")
        self.event:dispatch("BUTTON_PREV_ONCLICK") 
    end)

    NextButton = LedgerFrame:CreateFrame("Button", "NextDayButton")
    NextButton:SetSize(28, 28)
    NextButton:SetPoint("TOPRIGHT", LedgerFrame, "TOPRIGHT", -44, -40)
    NextButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    NextButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])
    NextButton:SetScript("OnClick", function () 
        Debug:trace(self, "NextButton:SetScript:OnClick")
        self.event:dispatch("BUTTON_NEXT_ONCLICK") 
    end)

    -- Dropdown
    DayDropdown = LedgerFrame:CreateFrame("Frame", "DayDropdown", LedgerFrame, "UIDropDownMenuTemplate")
    DayDropdown:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 100, -40)
    DayDropdown:SetDropdown("Day", 48, days)

    MonthDropdown = LedgerFrame:CreateFrame("Frame", "MonthDropdown", LedgerFrame, "UIDropDownMenuTemplate")
    MonthDropdown:SetPoint("TOPLEFT", LedgerFrame, "TOPLEFT", 180, -40)
    MonthDropdown:SetDropdown("Month", 100, monthNames)



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
    Debug:trace(self, "UI: initialized Frame: ", Frame)
    return LedgerFrame
end