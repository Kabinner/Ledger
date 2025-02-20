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
