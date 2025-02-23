function bind(obj, fn)
    return function(...)
        Debug:trace(obj, "bind: event:", event, " arg1: ", arg1)
        local args = {arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10}
        if table.getn(args) == 0 then
            args = {"CUSTOM_EVENT"}
        else
            arg = table.prepend(args, arg)
        end
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


    function Frame:SetDropdown(label, data, fn)
        Debug:trace("Frame:SetDropdown Frame label: ", label, " id: ", Frame, " fn: ", fn)


        

        -- Initialize the dropdown menu
        local function Initialize()
            Debug:trace("Frame:SetDropDown:Initialize self: ", self)

            for i, val in ipairs(data) do
                local info = {
                    text = val,
                    value = tostring(i),
                    arg1 = tostring(i),
                    arg2 = fn
                }
                info.func = self.SetValue
                UIDropDownMenu_AddButton(info)
            end

            self.Label = label
            function Frame:SetSize(width, height)
                Debug:trace("Frame:SetWidth self: ", self, " width:", width)
                if width then
                    UIDropDownMenu_SetWidth(width, self)
                end
            end
            
            if fn then
                Debug:trace("Frame:SetDropdown[",self.Label,"]: self.Callback: ", fn)
                self.Callback = fn
            end
        end
        self.Initialize = Initialize


        UIDropDownMenu_SetText(self.Label, self)
        UIDropDownMenu_Initialize(self, Frame.Initialize)
        
        self.SetValue = function(...)
            local value
            if type(arg[1]) ~= "table" then
                value = arg[1]
                fn = arg[2]
            else
                value = arg[2]
                fn = arg[3]
            end
            UIDropDownMenu_SetText(value, Frame)
            UIDropDownMenu_SetSelectedValue(Frame, value)

            Debug:trace("Frame:SetValue: this: ", this, " Frame: ", Frame, " callback: ", self.Callback, " Data: ", data, " Value: ", value, " self:", self, " foo: ", foo, " bar: ", bar, " foobar: ", foobar)

            Debug:trace("Frame:SetValue:Callback: fn: ", self.Callback, " value:", value)
            self.Callback(value)
            return self
        end
        
        return Frame
    end

    return Frame
end
