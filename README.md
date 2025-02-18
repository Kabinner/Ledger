<p align="center">
    <img style="float: left" src="https://github.com/user-attachments/assets/8d0131a4-1061-42b2-a3ab-0409113afbcd" width="25%" height="25%">
    <img style="float: left" src="https://github.com/user-attachments/assets/d3852943-d71e-4c3c-83c6-9fa6d261d178" width="50%" height="50%">
</p>

```lua

-- Own code
local Debug
local Dispatcher, Ledger, Money
local main = function ()
    local money, ledger

    local event = Dispatcher:new()

    ledger = Ledger:new(event)
    money = Money:new()

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
}

function Ledger:new(dispatcher)
    Ledger.__index = Ledger
    local instance = {
        name = self.name,
        event = dispatcher,

        day = 1,

        LedgerFrame = nil,
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
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "39FF14",
}
function Money:new()
    Money.__index = Money
    local instance = {
        name = self.name,
        money = 0,
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

    LedgerFrame = Frame:CreateFrame("Frame", "LedgerFrame", UIParent)
    LedgerFrame:SetWidth(384)
    LedgerFrame:SetHeight(512)
    LedgerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    LedgerFrame:SetMovable(true)

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

    local this = self
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
```
