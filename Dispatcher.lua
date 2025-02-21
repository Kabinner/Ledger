
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
    setmetatable(instance, Dispatcher)
    Dispatcher.__index = Dispatcher
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

