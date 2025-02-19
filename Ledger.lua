-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

-- Own code
local Debug
local Dispatcher, Ledger, Money
local Date
local LedgerDB

local main = function ()
    local money, ledger

    local event = Dispatcher:new()

    ledger = Ledger:new(event)
    money = Money:new()

    event:bind(ledger)
    event:bind(money)


    event:on("PLAYER_LOGIN", money.enable)
    event:on("PLAYER_LOGIN", ledger.enable)
    event:on("PLAYER_LOGOUT", ledger.disable)

    event:on("ADDON_LOADED", ledger.init_db)
    event:on("ADDON_LOADED", ledger.CreateFrames)

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
    Debug:trace(self, "args: ", Debug:unpack(arg))
    local money = GetMoney()
    local difference = money - self.money
    if difference ~= 0 then
        local action = (difference > 0) and "Gained" or "Lost"
        print(self, "track ", action, " ", math.abs(difference), " copper")
    end
    self.money = money
end


Ledger = {
    name = "Ledger",
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "",
}

function Ledger:new(dispatcher)
    Ledger.__index = Ledger
    local instance = {
        event = dispatcher,
        name = self.name,

        day = Date:getDay(),
        month = Date:getMonth(),
        year = Date:getYear(),

        Frame = nil,
        Title = nil, DragTitle = nil, TitleDate = nil, Icon = nil, DragIcon = nil, CloseButton = nil,
        BackgroundTL = nil, BackgroundTR = nil, BackgroundBL = nil, BackgroundBR = nil,

        ScrollContainer = nil, ScrollFrame = nil, ScrollBar = nil, ContentFrame = nil,

        PrevButton = nil, NextButton = nil,
        DayDropdown = nil, MonthDropdown = nil,
    }

    setmetatable(instance, Ledger)
    Debug:trace(Ledger, "new: ", instance, " Dispatcher: ")
    return instance
end

function Ledger:initDB(Frame)
    Debug:trace(self, "load Frame: ", Frame)

    if not LedgerDB then
        LedgerDB = {}
    end
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


function Ledger:ScrollBar_Update()
    -- Fix the off-by-one error
    local maxScroll = math.max(0, self.newHeight - self.ScrollFrame:GetHeight() - 350) -- @todo: magic number "350"?? prevents overscroll
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
    self.ContentFrame.numLines = self.numLines + 1
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
        self.day = Date:getDays(self.month, self.year)  -- Wrap around if going below 1
    end
    self.event:dispatch("DATE_CHANGED")
end
function Ledger:NextDay(...)
    Debug:trace(self, "NextDay: day:", self.day)
    self.day = self.day + 1
    if self.day > Date:getDays(self.month, self.year) then
        self.day = 1  -- Wrap around if going above 31
    end
    self.event:dispatch("DATE_CHANGED")
end


function Ledger:CreateFrames()
    self.LedgerFrame = Frame:CreateFrame("Frame", "LedgerFrame", UIParent)
    self.LedgerFrame:SetWidth(384)
    self.LedgerFrame:SetHeight(512)
    self.LedgerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    self.LedgerFrame:SetMovable(true)

    self.BackgroundTL = LedgerFrame:Texture("BackgroundTL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopLeft]])
    self.BackgroundTL:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 0, 0)
    self.BackgroundTR = LedgerFrame:Texture("BackgroundTR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopRight]])
    self.BackgroundTR:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", 0, 0)
    self.BackgroundBL = LedgerFrame:Texture("BackgroundBL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomLeft]])
    self.BackgroundBL:SetPoint("BOTTOMLEFT", self.Frame, "BOTTOMLEFT", 0, 0)
    self.BackgroundBR = LedgerFrame:Texture("BackgroundBR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomRight]])
    self.BackgroundBR:SetPoint("BOTTOMRIGHT", self.Frame, "BOTTOMRIGHT", 0, 0)

    self.CloseButton = self.Frame:CreateFrame("Button", nil, self.Frame, "UIPanelCloseButton")
    self.CloseButton:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -30, -8)

    self.Title = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Title:SetText("Ledger")
    self.Title:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 80, -18)

    self.TitleDate = self.Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.TitleDate:SetText("Sunday 16/2")
    self.TitleDate:SetPoint("TOP", self.Frame, "TOP", -0, -18)

    self.DragTitle = self.Frame:CreateFrame("Frame")
    self.DragTitle:SetSize(265, 28)
    self.DragTitle:SetPoint("TOP", self.Frame, "TOP", 5, -10)
    self.DragTitle:EnableMouse(true)
    self.DragTitle:SetScript("OnMouseDown", function() self.Frame:StartMoving() end)
    self.DragTitle:SetScript("OnMouseUp", function() self.Frame:StopMovingOrSizing() end)
    self.DragTitle:Debug()

    self.Icon = self.Frame:Texture('Icon', 'BACKGROUND', 58, 58, [[Interface\Spellbook\Spellbook-Icon]])
    self.Icon:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 10, -8)

    self.DragIcon = self.Frame:CreateFrame("Frame")
    self.DragIcon:SetPoint("TOP", Icon, "TOP", 0, 0) 
    self.DragIcon:SetSize(58, 58) 
    self.DragIcon:EnableMouse(true)
    self.DragIcon:SetScript("OnMouseDown", function() self.Frame:StartMoving() end)
    self.DragIcon:SetScript("OnMouseUp", function() self.Frame:StopMovingOrSizing() end)
    self.DragIcon:Debug()

    self.CreateNavigation()
    self.CreateScrollContainer()
end

function Ledger:CreateNavigation()
    self.PrevButton = self.Frame:CreateFrame("Button", "PrevDayButton")
    self.PrevButton:SetSize(28, 28)
    self.PrevButton:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 91, -40)
    self.PrevButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    self.PrevButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])

    self.NextButton = self.Frame:CreateFrame("Button", "NextDayButton")
    self.NextButton:SetSize(28, 28)
    self.NextButton:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", -44, -40)
    self.NextButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    self.NextButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])

    self.DayDropdown = self.Frame:CreateFrame("Frame", "DayDropdown", self.Frame, "UIDropDownMenuTemplate")
    self.DayDropdown:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 100, -40)

    self.MonthDropdown = self.Frame:CreateFrame("Frame", "MonthDropdown", self.Frame, "UIDropDownMenuTemplate")
    self.MonthDropdown:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 180, -40)


    self.DayDropdown:SetDropdown("Day", 48, Date:getDays(self.year))
    self.MonthDropdown:SetDropdown("Month", 100, Date:getMonthNames())

    self.NextButton:SetScript("OnClick", function () 
        Debug:trace(self, "NextButton:SetScript:OnClick")
        self.event:dispatch("BUTTON_NEXT_ONCLICK") 
    end)

    self.PrevButton:SetScript("OnClick", function () 
        Debug:trace(self, "PrevButton:SetScript:OnClick")
        self.event:dispatch("BUTTON_PREV_ONCLICK") 
    end)

end
function Ledger:CreateScrollContainer()
    self.ScrollContainer = LedgerFrame:CreateFrame("Frame", "LedgerScrollContainer")
    self.ScrollContainer:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 22, -80)
    self.ScrollContainer:SetPoint("BOTTOMRIGHT", self.Frame, "BOTTOMRIGHT", -65, 80)

    self.ScrollFrame = self.ScrollContainer:CreateFrame("ScrollFrame", "LedgerScrollFrame")
    self.ScrollFrame:SetAllPoints(self.ScrollContainer)
    self.ScrollFrame:EnableMouseWheel(true)
    self.ScrollFrame:SetHeight(0)

    self.ScrollBar = self.ScrollContainer:CreateFrame("Slider", "LedgerScrollBar", self.ScrollContainer, "UIPanelScrollBarTemplate")
    self.ScrollBar:SetPoint("TOPLEFT", self.ScrollContainer, "TOPRIGHT", 4, -11)
    self.ScrollBar:SetPoint("BOTTOMLEFT", self.ScrollContainer, "BOTTOMRIGHT", 4, 19)
    self.ScrollBar:SetMinMaxValues(1, 200)
    self.ScrollBar:SetValueStep(1)
    self.ScrollBar:SetWidth(16)
    self.ScrollBar:SetScript("OnValueChanged", function() self.ScrollFrame:SetVerticalScroll(arg1) end)

    self.ContentFrame = self.ScrollFrame:CreateFrame("Frame", "LedgerContentFrame")
    self.ContentFrame:SetWidth(354)
    self.ContentFrame:SetHeight(0)  -- initial height; expands as lines are added.
    self.ContentFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPRIGHT", 6, -22)
    self.ContentFrame:SetPoint("BOTTOMLEFT", self.ScrollFrame, "BOTTOMRIGHT", 4, 20)
    self.ScrollFrame:SetScrollChild(self.ContentFrame)
    self.ScrollBar:SetValue(0)

    self.ScrollFrame:SetScript("OnMouseWheel", function()
        local current = self.ScrollBar:GetValue()
        local newVal = current - (arg1 * 20)  -- adjust the multiplier for scroll speed
        if newVal < 0 then
            newVal = 0
        end
        self.ScrollBar:SetValue(newVal)
    end)

end

function Ledger:AddText(text)
    local numLines = self.ContentFrame.numLines or 0
    local yOffset = -self.numLines * 20  -- adjust vertical spacing as needed

    local line = self.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    line:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", 0, yOffset)
    line:SetText(text)
    self.event:dispatch("CONTENT_UPDATE")
end


local Date = {
    days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"},
    months = {
        January = 31, 
        February = 28, 
        March = 31, 
        April = 30,
        May = 31,
        June = 30, 
        July = 31,
        August = 31,
        September = 30,
        October = 31,
        November = 30,
        December = 31
    },
}
function Date:numDaysInMonth(month, year)
    local numDays = self.months[month] or Debug:error("Month not found.")

    if month == "February" and self:isLeapYear(year) then
        numDays = numDays + 1
    end
    return numDays
end
function Date:getYear()
    return 2025
end
function Date:getMonth()
    return 2
end
function Date:isLeapYear(year)
    return (math.mod(year, 4) == 0 and (math.mod(year, 100) ~= 0 or math.mod(year, 400) == 0))
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

    local value
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
    ERROR="ERROR",
    INFO="INFO",
    TRACE="TRACE",
    LOG_COLOR="ffd700"
}
function Debug:unpack(_, sep)
    if type(_) ~= "table" or not table.getn(_) then
        return
    end
    local args = {}
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

function Debug:print(_, level, ...)
    if type(_) == "table" and not _.DEBUG then
        return
    end

    local color
    color = "|cff" .. Debug.LOG_COLOR
    if type(_) == "table" and _.LOG_COLOR and _.LOG_COLOR ~= "" then
        color = "|cff" .. _.LOG_COLOR
    end

    local msg = color

    msg = msg .. "[".. level .."] "

    if type(_) == "string" then
        msg = msg .. _
    elseif type(_) == "table" and _.name then 
        msg = msg .. _.name .."[" .. id(_) .."]:"
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
function Debug:error(caller, ...)
    local args
    if type(caller) ~= "object" then
        args = table.prepend({caller}, arg)
        caller = {}
    end
    caller.DEBUG_COLOR = "FF2400"
    caller.DEBUG = true
    self:print(caller, Debug.ERROR, unpack(args))
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
    Debug:trace(self, "bind ", obj.name, "[", id(obj), "]")
    
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
        Debug:error(self, "No object found for callback ", callback_id)
        return
    end
    
    Debug:trace(self, "hook ", target_obj.name, "[", id(target_obj), "] ", 
        event, " -> ", target_obj.name, ":", obj_data.object_map_lookup[callback_id])
    
end
function Dispatcher:on(event, callback)
    local callback_id = id(callback)
    local target_obj, obj_data = self:target(callback)
    
    if not target_obj then
        Debug:error(self, "No object found for callback ", callback_id)
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
            Debug:error(self, "trigger in ", obj.name, ":", fn_name, " - ", err)
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
    Debug:error("main: ", err)
end)
