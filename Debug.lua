
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
    if not sep then
        sep = " "
    end

    local args = {}
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
        msg = msg .. _.name .. "[" .. id(_) .."]:"
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

    if type(caller) ~= "table" then
        arg = table.prepend({caller}, arg)
        caller = {}
    end

    local _color = caller.LOG_COLOR
    local _debug = caller.DEBUG

    caller.LOG_COLOR = "FF2400"
    caller.DEBUG = true

    if string.find(arg[1], "Interface\\AddOns") then
        arg[1] = string.sub(arg[1], string.find(arg[1], "\\[^\\]*$") + 1)
    end
    self:print(caller, Debug.ERROR, unpack(arg))

    caller.LOG_COLOR = _color
    caller.DEBUG = _debug
end
