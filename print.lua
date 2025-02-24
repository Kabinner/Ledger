function print(_, msg, ...)

    local args = {}
    if type(_) == "nil" then
        DEFAULT_CHAT_FRAME:AddMessage("nil");
    elseif type(_) == "table" then
        if _.name then
            table.insert(args, string.format("%s: ", _.name))
        else
            table.insert(args, id(_))
        end
    else
        args = table.prepend({_}, arg)
    end

    local value
    for idx in arg do
        if idx ~= "n" then
            value = arg[idx]
        
            if type(value) == "nil" then
                value = "nil"
            elseif type(value) == "table" or type(value) == "function" then
                value= id(value)
            elseif type(value) == "boolean" or type(value) == "number" then
                value = tostring(value)
            end

            table.insert(args, value)
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(string.format(msg, args));
end
