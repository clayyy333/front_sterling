-- Small reusable controls. Every subpage owns and releases its listeners.
return function(app)
    local ui, theme = app.UI, app.Theme
    local statuses={}
    app.FlowChanged=function(section,message)
        if not message then return end
        for scope,label in pairs(statuses)do
            if not scope.Destroyed and app.Navigation.Selected==section then label.Text=tostring(message)end
        end
    end
    function ui:Scope()
        local scope={Destroyed=false,Connections={},Cleanups={}}
        function scope:Connect(signal, fn)
            local c=signal:Connect(function(...)
                if not self.Destroyed and app.Alive then
                    local ok,err=pcall(fn,...)
                    if not ok and self.OnError then self.OnError(tostring(err)) end
                end
            end)
            self.Connections[#self.Connections+1]=c;return c
        end
        function scope:Destroy()
            if self.Destroyed then return end
            self.Destroyed=true
            for _, c in ipairs(self.Connections) do c:Disconnect() end
            for _, fn in ipairs(self.Cleanups) do pcall(fn) end
        end
        return scope
    end
    function ui:Stack(parent)
        local frame=self:Create("Frame",{Size=UDim2.new(1,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},parent)
        self:Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},frame)
        return frame
    end
    function ui:Note(parent,text)
        local label=self:Label(parent,text,12);label.TextColor3=theme.Muted
        app.Appearance:BindColor(label,"TextColor3","Muted")
        label.Size=UDim2.new(1,-8,0,36);return label
    end
    function ui:Status(parent,scope)
        local label=self:Note(parent,"Listo.");label.Name="Status";label.LayoutOrder=999
        statuses[scope]=label
        scope.Cleanups[#scope.Cleanups+1]=function()statuses[scope]=nil end
        scope.OnError=function(message) label.Text=message end
        return label
    end
    function ui:Action(parent,scope,text,fn,accent)
        local button=self:Button(parent,text,accent)
        button.Size=UDim2.new(1,-2,0,36)
        local busy=false
        scope:Connect(button.Activated,function()
            if busy then return end
            busy=true
            task.spawn(function()
                local ok,err=pcall(fn)
                busy=false
                if not ok and not scope.Destroyed and scope.OnError then scope.OnError(tostring(err)) end
            end)
        end)
        return button
    end
    function ui:Watch(scope,fn)
        local elapsed=0
        scope:Connect(app.Legacy.RunService.Heartbeat,function(dt)
            elapsed=elapsed+dt
            if elapsed>=.2 then elapsed=0;fn() end
        end)
        fn()
    end
    function ui:Toggle(parent,scope,text,get,set)
        local button
        local function refresh()
            if not button or scope.Destroyed then return end
            local active=get()==true
            button.Text=text..(active and "  ·  Encendido" or "  ·  Apagado")
            button.BackgroundColor3=active and theme.Selected or theme.Raised
            button.TextColor3=active and theme.AccentText or theme.Text
        end
        button=self:Action(parent,scope,text,function()
            local ok,err=set(not get())
            if ok==false and scope.OnError then scope.OnError(err or "No se pudo activar.") end
            refresh()
        end)
        self:Watch(scope,refresh)
        return button
    end
    function ui:Number(parent,scope,title,value,setter)
        local row=self:Create("Frame",{Size=UDim2.new(1,-2,0,36),BackgroundTransparency=1},parent)
        local label=self:Label(row,title,12);label.Size=UDim2.new(.62,-12,1,0)
        local input=self:Round(self:Create("TextBox",{Name="Value",Size=UDim2.new(.38,0,1,0),
            Position=UDim2.fromScale(.62,0),Text=tostring(value),ClearTextOnFocus=false,Active=true,Selectable=true,
            Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=theme.Text,
            BackgroundColor3=theme.Raised,BorderSizePixel=0},row),8)
        scope:Connect(input.FocusLost,function()
            local number=tonumber(input.Text)
            if not number or number~=number or math.abs(number)==math.huge then
                input.Text=tostring(value);return
            end
            local ok,result=setter(number)
            if ok==false then
                input.Text=tostring(value)
                if scope.OnError then scope.OnError(result or "Valor no válido.") end
            else value=type(result)=="number" and result or number;input.Text=tostring(value) end
        end)
        return input
    end
    function ui:Range(parent,scope,title,value,minimum,maximum,setter,logarithmic,sliderOnly)
        local input=self:Number(parent,scope,title,value,setter)
        local row=input.Parent;row.Size=UDim2.new(1,-2,0,66)
        input.Size=UDim2.new(.38,0,0,32)
        if sliderOnly then
            input.Visible=false
            local valueLabel=self:Label(row,tostring(value).."%",12)
            valueLabel.Name="SliderValue";valueLabel.TextXAlignment=Enum.TextXAlignment.Right
            valueLabel.Position=UDim2.fromScale(.8,0);valueLabel.Size=UDim2.new(.2,-8,0,32)
            scope:Connect(input:GetPropertyChangedSignal("Text"),function()valueLabel.Text=input.Text.."%"end)
        end
        for _,child in ipairs(row:GetChildren())do if child:IsA("TextLabel")then child.Size=UDim2.new(.62,-12,0,32)end end
        local track=self:Round(self:Create("TextButton",{Name="Slider",Text="",Active=true,
            Position=UDim2.fromOffset(8,37),Size=UDim2.new(1,-16,0,24),BackgroundTransparency=1,BorderSizePixel=0},row),4)
        local line=self:Round(self:Create("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.fromOffset(0,10),BackgroundColor3=theme.Line,BorderSizePixel=0},track),2)
        local fill=self:Round(self:Create("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=theme.Accent,BorderSizePixel=0},line),2)
        local knob=self:Round(self:Create("Frame",{Size=UDim2.fromOffset(12,12),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=theme.Text,BorderSizePixel=0},track),6)
        local function position(n)
            n=math.clamp(n,minimum,maximum)
            local alpha=logarithmic and math.log(n/minimum)/math.log(maximum/minimum)or(n-minimum)/(maximum-minimum)
            fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5)
        end
        position(value)
        local pointer
        local function change(x)
            local alpha=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
            local n=logarithmic and minimum*(maximum/minimum)^alpha or minimum+(maximum-minimum)*alpha
            n=math.floor(n*100+.5)/100
            local ok,result=setter(n)
            if ok~=false then input.Text=tostring(type(result)=="number"and result or n);position(tonumber(input.Text))end
        end
        scope:Connect(track.InputBegan,function(event)
            if event.UserInputType==Enum.UserInputType.Touch or event.UserInputType==Enum.UserInputType.MouseButton1 then pointer=event;change(event.Position.X)end
        end)
        scope:Connect(app.Services.UserInputService.InputChanged,function(event)
            if pointer and(event==pointer or event.UserInputType==Enum.UserInputType.MouseMovement)then change(event.Position.X)end
        end)
        scope:Connect(app.Services.UserInputService.InputEnded,function(event)if event==pointer then pointer=nil end end)
        scope:Connect(input.FocusLost,function()local n=tonumber(input.Text);if n then position(n)end end)
        return input
    end
    function ui:Select(parent,scope,title,options,choose)
        local row=self:Create("Frame",{Size=UDim2.new(1,-2,0,38),BackgroundTransparency=1},parent)
        local button=self:Button(row,title);button.Size=UDim2.new(1,-42,1,0)
        button.TextXAlignment=Enum.TextXAlignment.Left
        self:Create("UIPadding",{PaddingLeft=UDim.new(0,12)},button)
        local refresh=self:Button(row,">");refresh.Position=UDim2.new(1,-36,0,0);refresh.Size=UDim2.fromOffset(36,38)
        local list=self:Create("ScrollingFrame",{Visible=false,Size=UDim2.new(1,-2,0,146),
            BackgroundColor3=theme.Surface,BorderSizePixel=0,ScrollBarThickness=3,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},parent)
        self:Create("UIListLayout",{Padding=UDim.new(0,4)},list)
        local choices
        scope.Cleanups[#scope.Cleanups+1]=function()if choices then choices:Destroy()end end
        local function populate()
            if choices then choices:Destroy() end
            choices=ui:Scope();choices.OnError=scope.OnError
            for _, child in ipairs(list:GetChildren()) do if child:IsA("GuiButton") or child:IsA("TextLabel") then child:Destroy() end end
            local items=options()
            if #items==0 then ui:Note(list,"No hay opciones disponibles. Usa > para actualizar.") end
            for _, item in ipairs(items) do
                local value=item.Value
                local option=ui:Action(list,choices,item.Label,function()
                    choose(value);button.Text=item.Label;list.Visible=false
                end)
                option.TextSize=12
            end
        end
        scope:Connect(button.Activated,function() list.Visible=not list.Visible;if list.Visible then populate() end end)
        scope:Connect(refresh.Activated,function()list.Visible=true;populate()end)
        return button
    end
    function ui:Players(parent,scope,title,choose,includeSelf)
        return self:Select(parent,scope,title,function()
            local options={}
            for _, p in ipairs(app.Services.Players:GetPlayers()) do
                if includeSelf or p~=app.Player then options[#options+1]={Label=p.DisplayName.."  (@"..p.Name..")",Value=p} end
            end
            table.sort(options,function(a,b)return a.Label:lower()<b.Label:lower()end)
            return options
        end,choose)
    end
    function ui:Workspace(parent,tabs,mount)
        parent.ScrollingEnabled=false;parent.AutomaticCanvasSize=Enum.AutomaticSize.None
        local root=self:Create("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},parent)
        local strip=self:Create("ScrollingFrame",{Name="Subnavigation",Size=UDim2.new(1,0,0,36),
            BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,
            ScrollingDirection=Enum.ScrollingDirection.X,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new()},root)
        self:Create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},strip)
        local body=self:Create("ScrollingFrame",{Name="Panel",Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,1,-44),
            BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},root)
        local owner=self:Scope();local active;local buttons={}
        owner.Cleanups[#owner.Cleanups+1]=function()if active then active:Destroy()end end
        app:OnCleanup(function()owner:Destroy()end)
        owner:Connect(root.Destroying,function()owner:Destroy()end)
        local function show(id)
            if active then active:Destroy() end
            for _, child in ipairs(body:GetChildren()) do child:Destroy() end
            body.ScrollingEnabled=true;body.AutomaticCanvasSize=Enum.AutomaticSize.Y
            body.CanvasPosition=Vector2.new(0,0)
            active=ui:Scope()
            for key, button in pairs(buttons) do
                button.BackgroundColor3=key==id and theme.Selected or theme.Raised
                button.TextColor3=key==id and theme.AccentText or theme.Muted
            end
            local ok,err=pcall(mount,id,body,active)
            if not ok then ui:Note(body,"No se pudo abrir: "..tostring(err)) end
        end
        for _, tab in ipairs(tabs) do
            local button=self:Button(strip,tab[2]);button.Size=UDim2.fromOffset(tab[3] or 114,32)
            button.TextSize=12;buttons[tab[1]]=button
            owner:Connect(button.Activated,function()show(tab[1])end)
        end
        show(tabs[1][1])
        return show
    end
end
