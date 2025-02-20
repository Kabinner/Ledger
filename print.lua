function print(_, ...)
    local msg = ""

    if type(_) == "nil" then
        DEFAULT_CHAT_FRAME:AddMessage("nil");
    elseif type(_) == "table" then
        if _.name then
            msg = _.name .. ": "
        else
            msg = id(_)
        end
    else
        arg = table.prepend({_}, arg)
    end

    local value
    for idx = 1,table.getn(arg) do
        if idx ~= "n" then
            value = arg[idx]
        
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
