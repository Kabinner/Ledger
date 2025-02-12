```lua
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
    self:UI(Frame)
end

function Ledger:enable(Frame)
    print(self, "Enable. Frame: ", Frame)

    Frame:Texture("BACKGROUND", [[Interface\Spellbook\Spellbook-Icon]], 58, 58, {SetPoint={"TOPLEFT", 10, -8}})

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
```
