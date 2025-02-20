-- Isolate this file.
local _G = getfenv(0)
_G = setmetatable({_G = _G}, {__index = _G})
setfenv(1, _G)

-- Own code
local Ledger, Money
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

    event:on("VARIABLES_LOADED", ledger.init_db)
    event:on("ADDON_LOADED", ledger.CreateFrames)

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
    Debug:trace(instance, "new: Dispatcher: ", dispatcher)
    return instance
end

function Ledger:init_db(Frame)
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



function Ledger:AddText(text)
    local numLines = self.ContentFrame.numLines or 0
    local yOffset = -self.numLines * 20  -- adjust vertical spacing as needed

    local line = self.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    line:SetPoint("TOPLEFT", self.ContentFrame, "TOPLEFT", 0, yOffset)
    line:SetText(text)
    self.event:dispatch("CONTENT_UPDATE")
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
    Debug:trace(self, "PrevDay: day:", self.day, " args: ", Debug:unpack(arg))
    self.day = self.day - 1
    if self.day < 1 then
        self.day = Date:numDaysInMonth(self.month, self.year)  -- Wrap around if going below 1
    end
    self.event:dispatch("DATE_CHANGED")
end
function Ledger:NextDay(...)
    Debug:trace(self, "NextDay: day:", self.day, " args: ", Debug:unpack(arg))
    self.day = self.day + 1
    if self.day > Date:numDaysInMonth(self.month, self.year) then
        self.day = 1  -- Wrap around if going above 31
    end
    self.event:dispatch("DATE_CHANGED")
end


function Ledger:CreateFrames(Frame)
    Debug:trace(self, "CreateFrames: Frame: ", Frame)

    self.LedgerFrame = Frame:CreateFrame("Frame", "LedgerFrame", UIParent)
    self.LedgerFrame:SetSize(384, 512)
    self.LedgerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    self.LedgerFrame:SetMovable(true)

    self.BackgroundTL = LedgerFrame:Texture("BackgroundTL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopLeft]])
    self.BackgroundTL:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 0, 0)
    self.BackgroundTR = LedgerFrame:Texture("BackgroundTR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-TopRight]])
    self.BackgroundTR:SetPoint("TOPRIGHT", self.LedgerFrame, "TOPRIGHT", 0, 0)
    self.BackgroundBL = LedgerFrame:Texture("BackgroundBL", "ARTWORK", 256, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomLeft]])
    self.BackgroundBL:SetPoint("BOTTOMLEFT", self.LedgerFrame, "BOTTOMLEFT", 0, 0)
    self.BackgroundBR = LedgerFrame:Texture("BackgroundBR", "ARTWORK", 128, 256, [[Interface\PaperDollInfoFrame\UI-Character-General-BottomRight]])
    self.BackgroundBR:SetPoint("BOTTOMRIGHT", self.LedgerFrame, "BOTTOMRIGHT", 0, 0)

    self.CloseButton = self.LedgerFrame:CreateFrame("Button", nil, self.LedgerFrame, "UIPanelCloseButton")
    self.CloseButton:SetPoint("TOPRIGHT", self.LedgerFrame, "TOPRIGHT", -30, -8)

    self.Title = self.LedgerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.Title:SetText("Ledger")
    self.Title:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 80, -18)

    self.TitleDate = self.LedgerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.TitleDate:SetText("Sunday 16/2")
    self.TitleDate:SetPoint("TOP", self.LedgerFrame, "TOP", -0, -18)

    self.DragTitle = self.LedgerFrame:CreateFrame("Frame")
    self.DragTitle:SetSize(265, 28)
    self.DragTitle:SetPoint("TOP", self.LedgerFrame, "TOP", 5, -10)
    self.DragTitle:EnableMouse(true)
    self.DragTitle:SetScript("OnMouseDown", function() self.LedgerFrame:StartMoving() end)
    self.DragTitle:SetScript("OnMouseUp", function() self.LedgerFrame:StopMovingOrSizing() end)
    self.DragTitle:Debug()

    self.Icon = self.LedgerFrame:Texture('Icon', 'BACKGROUND', 58, 58, [[Interface\Spellbook\Spellbook-Icon]])
    self.Icon:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 10, -8)

    self.DragIcon = self.LedgerFrame:CreateFrame("Frame")
    self.DragIcon:SetPoint("TOP", Icon, "TOP", 0, 0) 
    self.DragIcon:SetSize(58, 58) 
    self.DragIcon:EnableMouse(true)
    self.DragIcon:SetScript("OnMouseDown", function() self.LedgerFrame:StartMoving() end)
    self.DragIcon:SetScript("OnMouseUp", function() self.LedgerFrame:StopMovingOrSizing() end)
    self.DragIcon:Debug()

    self:CreateNavigation()
    self:CreateScrollContainer()
end

function Ledger:CreateNavigation()
    self.PrevButton = self.LedgerFrame:CreateFrame("Button", "PrevDayButton")
    self.PrevButton:SetSize(28, 28)
    self.PrevButton:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 91, -40)
    self.PrevButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Up]])
    self.PrevButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-PrevPage-Down]])

    self.NextButton = self.LedgerFrame:CreateFrame("Button", "NextDayButton")
    self.NextButton:SetSize(28, 28)
    self.NextButton:SetPoint("TOPRIGHT", self.LedgerFrame, "TOPRIGHT", -44, -40)
    self.NextButton:SetNormalTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Up]])
    self.NextButton:SetPushedTexture([[Interface\Buttons\UI-SpellbookIcon-NextPage-Down]])

    self.DayDropdown = self.LedgerFrame:CreateFrame("Frame", "DayDropdown", self.LedgerFrame, "UIDropDownMenuTemplate")
    self.DayDropdown:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 100, -40)

    self.MonthDropdown = self.LedgerFrame:CreateFrame("Frame", "MonthDropdown", self.LedgerFrame, "UIDropDownMenuTemplate")
    self.MonthDropdown:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 180, -40)


    self.DayDropdown:SetDropdown("Day", 48, Date:getDaysInMonth(self.month, self.year))
    self.MonthDropdown:SetDropdown("Month", 100, Date:getMonthNames())

    self.NextButton:SetScript("OnClick", bind(self, Ledger.NextDay)) 
    self.PrevButton:SetScript("OnClick", bind(self, Ledger.PrevDay))

end
function Ledger:CreateScrollContainer()
    self.ScrollContainer = LedgerFrame:CreateFrame("Frame", "LedgerScrollContainer")
    self.ScrollContainer:SetPoint("TOPLEFT", self.LedgerFrame, "TOPLEFT", 22, -80)
    self.ScrollContainer:SetPoint("BOTTOMRIGHT", self.LedgerFrame, "BOTTOMRIGHT", -65, 80)

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


Date = {
    day_names = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"},
    months = {
        {name = "January", days = 31},
        {name = "February", days = 28},
        {name = "March", days = 31},
        {name = "April", days = 30},
        {name = "May", days = 31},
        {name = "June", days = 30},
        {name = "July", days = 31},
        {name = "August", days = 31},
        {name = "September", days = 30},
        {name = "October", days = 31},
        {name = "November", days = 30},
        {name = "December", days = 31}
    }
}
function range(start, stop)
    local t = {}
    for i = start, stop do
        table.insert(t, i)
    end
    return t
end
function Date:getMonthNames()
    local monthNames = {}
    for i = 1, table.getn(self.months) do
        table.insert(monthNames, self.months[i].name)
    end
    return monthNames
end
function Date:getDaysInMonth(month, year)
    local numDays = self.months[month].days or error("Month not found.")
    if month == "February" and self:isLeapYear(year) then
        numDays = numDays + 1
    end

    return range(1, numDays)
end

function Date:numDaysInMonth(month, year)
    local numDays = self.months[month].days or error("Month not found.")

    if month == 2 and self:isLeapYear(year) then
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
function Date:getDay()
    return 1
end
function Date:isLeapYear(year)
    return (math.mod(year, 4) == 0 and (math.mod(year, 100) ~= 0 or math.mod(year, 400) == 0))
end

xpcall(main, function (err)
    Debug:error("main: ", err)
end)
