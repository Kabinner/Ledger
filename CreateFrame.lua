function bind(obj, fn)
    return function(...)
        local args = {arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10}
        arg = table.prepend(args, arg)
        return fn(obj, unpack(arg))
    end
end

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
