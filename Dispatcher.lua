local eventPrefixMap = {
    ACTION = true,
    ADDON = true,        -- ADDON_LOADED, ADDON_UNLOADED
    AREA = true,         -- AREA_SPIRIT_HEALER_IN_RANGE, AREA_SPIRIT_HEALER_OUT_OF_RANGE
    AUCTION = true,      -- AUCTION_HOUSE_SHOW, AUCTION_ITEM_LIST_UPDATE
    BAG = true,          -- BAG_UPDATE, BAG_CLOSED
    BANK = true,         -- BANKFRAME_OPENED, BANKFRAME_CLOSED
    BATTLEFIELD = true,  -- BATTLEFIELD_MGR_STATE_CHANGE, etc.
    CHANNEL = true,      -- CHANNEL_INVITE_REQUEST, CHANNEL_ROSTER_UPDATE
    CHAT = true,         -- CHAT_MSG_SAY, CHAT_MSG_GUILD, etc.
    CINEMATIC = true,    -- CINEMATIC_START, CINEMATIC_STOP
    COMBAT = true,       -- COMBAT_LOG_EVENT, COMBAT_TEXT_UPDATE
    CORPSE = true,       -- CORPSE_IN_RANGE, CORPSE_OUT_OF_RANGE
    FRIEND = true,       -- FRIENDLIST_UPDATE
    GAMETIME = true,     -- GAMETIME_UPDATE
    GOSSIP = true,       -- GOSSIP_SHOW, GOSSIP_CLOSED
    GROUP = true,        -- GROUP_JOINED, GROUP_ROSTER_UPDATE
    GUILD = true,        -- GUILD_ROSTER_UPDATE
    IGNORE = true,       -- IGNORELIST_UPDATE
    ITEM = true,         -- ITEM_LOCK_CHANGED
    KNOWN = true,        -- KNOWN_CURRENCY_TYPES_UPDATE
    LEARNED = true,      -- LEARNED_SPELL_IN_TAB
    LFG = true,          -- LFG_UPDATE (Not used much in Vanilla, but existed)
    LOOT = true,         -- LOOT_OPENED, LOOT_CLOSED
    MAIL = true,         -- MAIL_INBOX_UPDATE, MAIL_SHOW
    MAP = true,          -- MINIMAP_UPDATE_ZOOM, WORLD_MAP_UPDATE
    MERCHANT = true,     -- MERCHANT_SHOW, MERCHANT_CLOSED
    MIRROR = true,       -- MIRROR_TIMER_START, MIRROR_TIMER_STOP
    MONEY = true,        -- PLAYER_MONEY
    MOUNT = true,        -- MOUNTED_STATE_CHANGED
    MOVIE = true,        -- MOVIE_PLAYING, MOVIE_STOP
    NAMEPLATE = true,    -- NAMEPLATE_UNIT_ADDED, NAMEPLATE_UNIT_REMOVED
    PARTY = true,        -- PARTY_LEADER_CHANGED, PARTY_MEMBER_DISABLE
    PET = true,          -- PET_ATTACK_START, PET_ATTACK_STOP
    PLAYER = true,       -- PLAYER_ENTERING_WORLD, PLAYER_ALIVE
    QUEST = true,        -- QUEST_LOG_UPDATE, QUEST_FINISHED
    RAID = true,         -- RAID_ROSTER_UPDATE
    SKILL = true,        -- SKILL_LINES_CHANGED
    SOUND = true,        -- SOUNDKIT_FINISHED
    SPELL = true,        -- SPELLS_CHANGED
    SYSTEM = true,       -- SYSTEM_MESSAGE
    TALENT = true,       -- TALENTS_INVOLUNTARILY_RESET
    TAXI = true,         -- TAXIMAP_OPENED, TAXIMAP_CLOSED
    TRADE = true,        -- TRADE_REQUEST, TRADE_CLOSED
    TRAINER = true,      -- TRAINER_SHOW, TRAINER_UPDATE
    UI = true,           -- UI_ERROR_MESSAGE
    UNIT = true,         -- UNIT_HEALTH, UNIT_MANA
    UPDATE = true,       -- UPDATE_INSTANCE_INFO, UPDATE_MOUSEOVER_UNIT
    VARIABLES = true,    -- VARIABLES_LOADED
    VEHICLE = true,      -- VEHICLE_UPDATE
    VOICE = true,        -- VOICE_START, VOICE_STOP
    WEATHER = true,      -- WEATHER_UPDATE
    WORLD = true,        -- WORLD_MAP_UPDATE
    ZONE = true,         -- ZONE_CHANGED, ZONE_CHANGED_NEW_AREA
}

local function getPrefix(event)
    local _, _, prefix = string.find(event, "^(.-)_?([^_]*)$")
    return prefix
end

local function isFrameEvent(prefix)
    return eventPrefixMap[prefix] or false
end

local TYPE_EVENT_FRAME = "FRAME_EVENT"
local TYPE_EVENT_CUSTOM = "CUSTOM_EVENT"

local Event = {
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "7DF9FF",
}
Event.__index = Event

function Event:new(name)
    local instance = {
        name = name,
        eventType = (isFrameEvent(getPrefix(name)) and TYPE_EVENT_FRAME or TYPE_EVENT_CUSTOM),
        callback = nil
    }
    assert(instance.eventType == TYPE_EVENT_CUSTOM or instance.eventType == TYPE_EVENT_FRAME,
    string.format("Event %s is not a type of %s %s", name, TYPE_EVENT_FRAME, TYPE_EVENT_CUSTOM))

    setmetatable(instance, Event)
    Debug:trace(instance, "new: type: ", instance.eventType)
    return instance
end
function Event:__eq(other)
    if type(other) == "table" and getmetatable(other) == Event then
        return self.name == other.name
    end
    return false
end
setmetatable(Event, { __eq = Event.__eq })
function Event:equals(value)
    return self.name == value
end


Dispatcher = {
    name = "Dispatcher",
    DEBUG = true,
    LOG_LEVEL = "TRACE",
    LOG_COLOR = "7DF9FF",
}
Dispatcher.__index = Dispatcher

function Dispatcher:new()
    local instance = {
        name = self.name,
        Frame = CreateFrame("Frame", "FRAME_"..string.upper(self.name), UIParent),
        objects = {},
        hooks = {},
    }
    setmetatable(instance, Dispatcher)
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
function Dispatcher:on(event_name, callback)
    local callback_id = id(callback)
    local target_obj, obj_data = self:target(callback)
    
    if not target_obj then
        Debug:error(self, "No object found for callback ", callback_id)
        return
    end

    local eventType
    local eventPrefix = getPrefix(event_name)
    local objEvent = Event:new(event_name)

    if isFrameEvent(eventPrefix) then
        Debug:trace(self, eventPrefix, " on ", target_obj.name, "[", id(target_obj), "] ", 
        event_name, " -> ", target_obj.name, ":", obj_data.object_map_lookup[callback_id])

        self.Frame:RegisterEvent(event_name)
    else
        Debug:trace(self, "CUSTOM_EVENT: on ", target_obj.name, "[", id(target_obj), "] ", 
        event_name, " -> ", target_obj.name, ":", obj_data.object_map_lookup[callback_id])
    end
    
    if not obj_data.events[event_name] then
        obj_data.events[event_name] = {}
    end

    table.insert(obj_data.events[event_name], callback)
end

function Dispatcher:dispatch(custom_event, ...)
    local e
    if type(event) == "string" then
        -- e = event
        arg = table.prepend({custom_event}, arg)
    else
        e = custom_event
        Debug:trace(self, "!!custom event: ", e)
    end
    
    Debug:trace(self, "dispatch: event: ", event, " e: ", e, " args: ", Debug:unpack(arg))

    for obj, obj_data in pairs(self.objects) do
        local handlers = obj_data.events[event] or obj_data.events[e]
        if handlers then
            if event == "ADDON_LOADED" then
                if arg[1] == obj.name then
                    self:trigger(obj, obj_data, handlers)
                end
            else
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
            Debug:error(obj, err)
        end
    end
end

function Dispatcher:listen()
    Debug:trace(self, "listen on frame ", self.Frame)

    self.Frame:SetScript("OnEvent", bind(self, self.dispatch))

    -- function()
    --     Debug:trace(self, "Event name: ", event, " type: ", type(event) ," arg1: ", arg1)
    --     self:dispatch(event)
    -- end
end

