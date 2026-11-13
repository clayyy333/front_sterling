-- Etiquetas locales por eventos, con reconciliación ligera una vez por segundo.
return function(app)
    local players=app.Services.Players
    local core={Enabled=false}
    local entries,connections={},{}
    local function disconnect(list)
        for _,connection in ipairs(list)do connection:Disconnect()end
        table.clear(list)
    end
    local function remove(account)
        local entry=entries[account];if not entry then return end
        disconnect(entry.Connections)
        disconnect(entry.CharacterConnections)
        if entry.Tag then entry.Tag:Destroy()end
        entries[account]=nil
    end
    local function watch(account)
        if account==app.Player or entries[account]then return end
        local entry={Connections={},CharacterConnections={}};entries[account]=entry
        local function attach(character)
            disconnect(entry.CharacterConnections)
            if entry.Tag then entry.Tag:Destroy();entry.Tag=nil end
            entry.Character=character;entry.Refresh=nil
            local function create()
                if not core.Enabled or entries[account]~=entry or account.Character~=character then return end
                local head=character:FindFirstChild("Head")
                if entry.Tag and entry.Tag.Parent and entry.Tag.Adornee==head and head and head.Parent==character then return end
                if entry.Tag then entry.Tag:Destroy();entry.Tag=nil;entry.Display=nil end
                if not head or not head:IsA("BasePart")then return end
                local tag=Instance.new("BillboardGui")
                tag.Name="LaMadrinaNameTag";tag.Adornee=head
                -- PlayerGui elimina los LayerCollector al reaparecer si esta propiedad queda activa.
                tag.ResetOnSpawn=false
                tag.Size=UDim2.fromOffset(206,54);tag.StudsOffsetWorldSpace=Vector3.new(0,2.3,0)
                tag.MaxDistance=120;tag.AlwaysOnTop=false;tag.LightInfluence=0
                tag.Parent=app.PlayerGui;entry.Tag=tag
                local panel=Instance.new("Frame")
                panel.Size=UDim2.new(1,-12,1,-6);panel.Position=UDim2.fromOffset(6,3)
                panel.BackgroundColor3=Color3.fromRGB(15,15,22);panel.BackgroundTransparency=.18
                panel.BorderSizePixel=0;panel.Parent=tag
                local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=panel
                local border=Instance.new("UIStroke");border.Color=Color3.fromRGB(255,255,255)
                border.Transparency=.88;border.Thickness=1;border.Parent=panel
                local accent=Instance.new("Frame");accent.Size=UDim2.fromOffset(3,22)
                accent.Position=UDim2.new(0,10,.5,-11);accent.BorderSizePixel=0;accent.Parent=panel
                app.Appearance:BindColor(accent,"BackgroundColor3","Accent")
                local rounding=Instance.new("UICorner");rounding.CornerRadius=UDim.new(1,0);rounding.Parent=accent
                local function label(y,height,size,color,font)
                    local text=Instance.new("TextLabel")
                    text.Position=UDim2.fromOffset(21,y);text.Size=UDim2.new(1,-30,0,height)
                    text.BackgroundTransparency=1;text.TextColor3=color;text.Font=font;text.TextSize=size
                    text.TextXAlignment=Enum.TextXAlignment.Left;text.TextTruncate=Enum.TextTruncate.AtEnd
                    text.TextStrokeColor3=Color3.fromRGB(0,0,0);text.TextStrokeTransparency=.8
                    text.Parent=panel;return text
                end
                entry.Display=label(5,21,15,Color3.fromRGB(247,244,246),Enum.Font.GothamBold)
                entry.Display.Text=account.DisplayName
                label(26,16,11,Color3.fromRGB(185,182,192),Enum.Font.Gotham).Text="@"..account.Name
            end
            entry.Refresh=create
            entry.CharacterConnections[#entry.CharacterConnections+1]=character.ChildAdded:Connect(create)
            entry.CharacterConnections[#entry.CharacterConnections+1]=character.ChildRemoved:Connect(create)
            create()
        end
        entry.Reconcile=function()
            if account.Character~=entry.Character then
                if account.Character then attach(account.Character)end
            elseif entry.Refresh then entry.Refresh()end
        end
        entry.Connections[#entry.Connections+1]=account.CharacterAdded:Connect(attach)
        entry.Connections[#entry.Connections+1]=account.CharacterRemoving:Connect(function()
            disconnect(entry.CharacterConnections)
            entry.Character=nil;entry.Refresh=nil;entry.Display=nil
            if entry.Tag then entry.Tag:Destroy();entry.Tag=nil end
        end)
        entry.Connections[#entry.Connections+1]=account:GetPropertyChangedSignal("DisplayName"):Connect(function()
            if entry.Display and entry.Tag then entry.Display.Text=account.DisplayName end
        end)
        if account.Character then attach(account.Character)end
    end
    local function clear()
        disconnect(connections)
        for account,entry in pairs(entries)do
            remove(account)
        end
    end
    function core:SetEnabled(value)
        value=value==true
        if not app.Alive then return false,"La GUI está cerrada."end
        if self.Enabled~=value then
            self.Enabled=value;clear()
            if value then
                connections[#connections+1]=players.PlayerAdded:Connect(watch)
                connections[#connections+1]=players.PlayerRemoving:Connect(function(account)
                    remove(account)
                end)
                for _,account in ipairs(players:GetPlayers())do watch(account)end
                local elapsed=0
                connections[#connections+1]=game:GetService("RunService").Heartbeat:Connect(function(dt)
                    elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
                    if not self.Enabled or not app.Alive then return end
                    for _,account in ipairs(players:GetPlayers())do
                        watch(account)
                        local entry=entries[account]
                        if entry then entry.Reconcile()end
                    end
                end)
            end
        end
        app.Storage.Values.ShowPlayerNames=value;app.Storage:Save();return true
    end
    app.Flows.NameTags=core
    app:OnCleanup(function()core.Enabled=false;clear()end)
    if app.Storage.Values.ShowPlayerNames==true then core:SetEnabled(true)end
    return core
end
