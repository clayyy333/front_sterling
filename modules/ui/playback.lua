return function(app)
    local ui,theme=app.UI,app.Theme
    local scope=ui:Scope()
    app:OnCleanup(function()scope:Destroy()end)
    local dock=ui:Round(ui:Create("Frame",{Name="Playback",Visible=false,Size=UDim2.new(.86,0,0,76),
        AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-12),BackgroundColor3=theme.Surface,BorderSizePixel=0,ZIndex=50},app.Window.Gui),12)
    ui:Create("UISizeConstraint",{MaxSize=Vector2.new(420,76)},dock)
    ui:Create("UIStroke",{Color=theme.Accent,Thickness=1,Transparency=.5},dock)
    local title=ui:Label(dock,"",12);title.Position=UDim2.fromOffset(14,8);title.Size=UDim2.new(1,-126,0,22)
    local pause=ui:Button(dock,"Ⅱ");pause.Position=UDim2.new(1,-98,0,8);pause.Size=UDim2.fromOffset(38,28)
    local stop=ui:Button(dock,"■");stop.Position=UDim2.new(1,-52,0,8);stop.Size=UDim2.fromOffset(38,28)
    local last,paused
    local function context()return app.Flows.Movimientos.Context end
    scope:Connect(pause.Activated,function()
        local c=context();if not c or not c.currentAnimTrack then return end
        paused=not paused;c.currentAnimTrack:AdjustSpeed(paused and 0 or c.Settings.speed)
        pause.Text=paused and "▶"or"Ⅱ"
    end)
    scope:Connect(stop.Activated,function()
        local c=context();if not c then return end
        c.isComboActive=false;c._comboLoopEnabled=false;c.ComboQueue={};c.StopEmote(false)
    end)
    for index,speed in ipairs({.1,.5,1,1.5,2})do
        local button=ui:Button(dock,tostring(speed).."×")
        button.Position=UDim2.new((index-1)*.16,12,0,42);button.Size=UDim2.new(.15,-7,0,26);button.TextSize=11
        scope:Connect(button.Activated,function()
            local c=context();if not c then return end
            c.Settings.speed=speed;c.ApplySpeedToAllTracks();c.SaveLocalData();paused=false;pause.Text="Ⅱ"
        end)
    end
    local copy=ui:Button(dock,"ID");copy.Position=UDim2.new(.8,8,0,42);copy.Size=UDim2.new(.2,-20,0,26);copy.TextSize=11
    scope:Connect(copy.Activated,function()
        local c=context();local item=c and c._genv().lastVexroEmote
        local clipboard=app.Environment.setclipboard or setclipboard
        if clipboard and item then clipboard(tostring(item.id));copy.Text="✓"end
    end)
    ui:Watch(scope,function()
        local c=context();local track=c and c.currentAnimTrack
        dock.Visible=track~=nil and track.IsPlaying and c.Settings.showHUD~=false
        if track~=last then last=track;paused=false;pause.Text="Ⅱ";copy.Text="ID"end
        local item=c and c._genv().lastVexroEmote
        title.Text=item and item.name or "Reproducción"
    end)
end
