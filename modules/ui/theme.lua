return function(app)
    -- Original color palettes, mapped to the new front without loading old UI.
    local original=setmetatable({Settings={theme="Red"}},{__index=getfenv(0)})
    local factory,err=loadstring(app.ReadSource("modules/movements/ui/themes.lua"),"@sterling/palettes")
    assert(factory,err);factory()(original)
    local palettes={}
    for id,source in pairs(original.Themes)do
        palettes[id]={Background=source.primary,Surface=source.sidebar,Raised=source.tertiary,
            Line=source.stroke,Text=source.text,Muted=source.textDim,Accent=source.accent,
            AccentText=Color3.fromRGB(255,245,247),
            Selected=(id=="Light"or id=="FrostedGlass")and source.accent or source.stroke}
    end
    -- Keep the approved ruby design as the default red palette.
    palettes.Red={Background=Color3.fromRGB(16,16,20),Surface=Color3.fromRGB(23,23,30),
        Raised=Color3.fromRGB(29,29,37),Line=Color3.fromRGB(57,44,54),Text=Color3.fromRGB(242,237,240),
        Muted=Color3.fromRGB(166,156,170),Accent=Color3.fromRGB(220,53,75),
        AccentText=Color3.fromRGB(255,245,247),Selected=Color3.fromRGB(67,29,42)}
    local selected=palettes[app.Storage.Values.ColorTheme]and app.Storage.Values.ColorTheme or "Red"
    app.Storage.Values.ColorTheme=selected
    local theme={};for key,value in pairs(palettes[selected])do theme[key]=value end
    app.Theme=theme
    local registry=setmetatable({},{__mode="k"})
    local appearance={ThemeId=selected,Transparency=math.clamp(tonumber(app.Storage.Values.GUITransparency)or 0,0,.8)}
    app.Appearance=appearance
    local applying=false
    local function role(color,palette)
        for _,key in ipairs({"Text","Muted","Accent","Raised","Surface","Background","Line","Selected","AccentText"})do
            if color==palette[key]then return key end
        end
    end
    local function watch(object,entry,property)
        app:Connect(object:GetPropertyChangedSignal(property),function()
            if not applying then
                local key=role(object[property],theme)
                if key then entry.Roles[property]=key end
            end
        end)
    end
    function appearance:Register(object,properties)
        local entry={Colors={},Roles={}}
        for key,value in pairs(properties)do
            if key=="Color"or key:find("Color3",1,true)then entry.Colors[#entry.Colors+1]=key;entry.Roles[key]=role(value,theme);watch(object,entry,key) end
        end
        local base=properties.BackgroundTransparency or 0
        if properties.BackgroundColor3 and role(properties.BackgroundColor3,theme) and base<1
            and properties.Name~="SoftRed"and properties.Name~="SoftShade"then
            entry.BaseTransparency=base
            object.BackgroundTransparency=math.max(base,self.Transparency)
        end
        if #entry.Colors>0 or entry.BaseTransparency then registry[object]=entry end
    end
    function appearance:BindColor(object,property,key)
        local entry=registry[object]
        if not entry then entry={Colors={},Roles={}};registry[object]=entry end
        local found=false
        for _,existing in ipairs(entry.Colors)do if existing==property then found=true;break end end
        if not found then entry.Colors[#entry.Colors+1]=property;watch(object,entry,property)end
        entry.Roles[property]=key;object[property]=theme[key]
    end
    function appearance:SetTheme(id)
        if not palettes[id]then return false,"Tema no disponible."end
        applying=true
        for object,entry in pairs(registry)do
            if object.Parent then
                for _,property in ipairs(entry.Colors)do
                    local key=entry.Roles[property]
                    if key then object[property]=palettes[id][key];entry.Roles[property]=key end
                end
            else registry[object]=nil end
        end
        for key,value in pairs(palettes[id])do theme[key]=value end
        applying=false
        self.ThemeId=id;app.Storage.Values.ColorTheme=id;app.Storage:Save()
        return true
    end
    function appearance:SetTransparency(percent)
        self.Transparency=math.clamp(tonumber(percent)or 0,0,80)/100
        for object,entry in pairs(registry)do
            if object.Parent and entry.BaseTransparency then object.BackgroundTransparency=math.max(entry.BaseTransparency,self.Transparency)end
        end
        app.Storage.Values.GUITransparency=self.Transparency;app.Storage:Save()
        return true,self.Transparency*100
    end
    function appearance:GetThemes()
        local options={}
        for _,entry in ipairs({{"Red","Rojo rubí"},{"Dark","Oscuro"},{"Purple","Violeta"},{"Blue","Azul"},
            {"Green","Verde"},{"Light","Claro"},{"MaterialYou","Material You"},{"FrostedGlass","Cristal"},{"GTAMode","Rosa nocturno"}})do
            options[#options+1]={Value=entry[1],Label=entry[2]}
        end
        return options
    end
    return theme
end
