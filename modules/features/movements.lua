return function(app)
    local ui, theme, package=app.UI,app.Theme,app.Flows.Movimientos
    local tabs={{"emotes","Emotes",80},{"animations","Animaciones",104},{"favorites","Favoritos",90},
        {"recent","Recientes",88},{"friends","Amigos",78},{"keybinds","Atajos",68}}
    local combo={}
    local function stop(c)
        c.isComboActive=false;c._comboLoopEnabled=false;c.ComboQueue={};c.StopEmote(false)
    end
    local function play(c,item)
        if item.isAnimationPack then c.EquipAnimationPack(item) else c.PlayEmote(item.id,item.name) end
    end
    app.Features:Register({Id="movimientos",Label="Movimientos",Title="Movimientos",Subtitle="",
        Mount=function(_,parent)
            ui:Workspace(parent,tabs,function(id,body,scope)
                local waitLabel=ui:Note(body,"Preparando tu catálogo…")
                task.defer(function()
                    local ok,c=package:EnsureLoaded()
                    if scope.Destroyed or not app.Alive then return end
                    waitLabel:Destroy()
                    if not ok then
                        ui:Note(body,c)
                        ui:Action(body,scope,"Reintentar",function()app.Navigation:Reload("movimientos")end)
                        return
                    end
                    local content=ui:Stack(body)
                    local status=ui:Status(content,scope)
                    if id=="friends" then
                        local selected
                        ui:Players(content,scope,"Elegir amigo del servidor",function(p)selected=p end)
                        ui:Action(content,scope,"Seguir sus emotes",function()
                            local result=c.LocalEmoteFollow.Start(selected)
                            status.Text=c.LocalEmoteFollow.GetStatus()
                            if not result then status.Text=c.LocalEmoteFollow.GetStatus() end
                        end,true)
                        ui:Action(content,scope,"Detener seguimiento",function()c.LocalEmoteFollow.Stop();status.Text=c.LocalEmoteFollow.GetStatus()end)
                        ui:Watch(scope,function()status.Text=c.LocalEmoteFollow.GetStatus()end)
                        return
                    end
                    if id=="keybinds" then
                        local emoteId,key
                        ui:Number(content,scope,"ID del emote",0,function(n)emoteId=math.floor(n);return true,emoteId end)
                        local entry=ui:Create("TextBox",{Size=UDim2.new(1,0,0,36),PlaceholderText="Tecla · ejemplo: K o F",Text="",ClearTextOnFocus=false,
                            Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=theme.Text,BackgroundColor3=theme.Raised,BorderSizePixel=0},content)
                        ui:Round(entry,8)
                        scope:Connect(entry.FocusLost,function()key=entry.Text:upper():gsub("%s+","")end)
                        ui:Action(content,scope,"Guardar atajo",function()
                            local emote=emoteId and c.EmotesById[emoteId]
                            if not emote or not key or key=="" then status.Text="Escribe un ID del catálogo y una tecla.";return end
                            c.SetKeybind(emoteId,emote.name,key);status.Text="Atajo guardado: "..key
                        end,true)
                        for emoteId,record in pairs(c.KeybindsSet) do
                            ui:Action(content,scope,record.key.."  ·  "..record.name.."  ×",function()c.RemoveKeybind(emoteId);status.Text="Atajo eliminado."end)
                        end
                        return
                    end
                    -- Keep search, paging and saved controls outside the catalog scroll.
                    content:Destroy()
                    body.ScrollingEnabled=false;body.AutomaticCanvasSize=Enum.AutomaticSize.None
                    body.CanvasPosition=Vector2.new(0,0)
                    content=ui:Create("Frame",{Name="CatalogLayout",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},body)
                    status=ui:Status(content,scope)
                    status.Position=UDim2.new(0,0,1,id=="animations"and -24 or -62)
                    status.Size=UDim2.new(1,-4,0,20);status.TextSize=11
                    status.Text="";status.Visible=false;status.ZIndex=10
                    status.BackgroundColor3=theme.Surface;status.BackgroundTransparency=.08
                    ui:Round(status,6)
                    local messageVersion=0
                    scope:Connect(status:GetPropertyChangedSignal("Text"),function()
                        messageVersion=messageVersion+1;local token=messageVersion
                        status.Visible=status.Text~=""
                        if status.Visible then
                            task.delay(3,function()
                                if not scope.Destroyed and token==messageVersion then status.Text=""end
                            end)
                        end
                    end)
                    local tools=ui:Create("Frame",{Size=UDim2.new(1,-4,0,32),BackgroundTransparency=1},content)
                    local search=ui:Round(ui:Create("TextBox",{Name="CatalogSearch",Active=true,Selectable=true,Size=UDim2.new(1,-142,1,0),Text="",PlaceholderText="Buscar por nombre o ID…",ClearTextOnFocus=false,
                        Font=Enum.Font.Gotham,TextSize=12,TextColor3=theme.Text,BackgroundColor3=theme.Raised,BorderSizePixel=0},tools),8)
                    ui:Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)},search)
                    local previous=ui:Button(tools,"‹");previous.Name="PreviousPage";previous.Position=UDim2.new(1,-134,0,0);previous.Size=UDim2.fromOffset(30,32)
                    local pageText=ui:Label(tools,"1 / 1",11);pageText.Name="PageNumber";pageText.Position=UDim2.new(1,-102,0,0);pageText.Size=UDim2.fromOffset(68,32)
                    local next=ui:Button(tools,"›");next.Name="NextPage";next.Position=UDim2.new(1,-30,0,0);next.Size=UDim2.fromOffset(30,32)
                    local animationPicker=ui:AnimationPicker(scope,c,status)
                    if id=="animations"then
                        local actions=ui:Create("Frame",{Name="AnimationTools",Size=UDim2.new(1,-4,0,30),Position=UDim2.fromOffset(0,40),BackgroundTransparency=1},content)
                        local save=ui:Action(actions,scope,"Guardar animaciones puestas",function()animationPicker:Save()end)
                        save.Size=UDim2.new(.68,-6,1,0);save.TextSize=11
                        local saved=ui:Action(actions,scope,"Guardadas",function()animationPicker:OpenSaved()end)
                        saved.Position=UDim2.fromScale(.68,0);saved.Size=UDim2.new(.32,0,1,0);saved.TextSize=11
                    end
                    local gridTop=id=="animations"and 80 or 42
                    local footer=id=="animations"and 6 or 42
                    local viewport=ui:Create("ScrollingFrame",{Name="CatalogViewport",Position=UDim2.fromOffset(0,gridTop),
                        Size=UDim2.new(1,0,1,-gridTop-footer),BackgroundTransparency=1,BorderSizePixel=0,
                        ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},content)
                    local grid=ui:Create("Frame",{Name="CatalogGrid",Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-10,0,0),BackgroundTransparency=1},viewport)
                    local mobile=app.Services.UserInputService.TouchEnabled
                    local gap=mobile and 4 or 6
                    local layout=ui:Create("UIGridLayout",{CellPadding=UDim2.fromOffset(gap,gap),SortOrder=Enum.SortOrder.LayoutOrder},grid)
                    local items,page,version,maxPages={},1,0,1
                    local cardsScope
                    scope.Cleanups[#scope.Cleanups+1]=function()if cardsScope then cardsScope:Destroy()end end
                    local function draw()
                        if scope.Destroyed then return end
                        if cardsScope then cardsScope:Destroy()end;cardsScope=ui:Scope();cardsScope.OnError=scope.OnError
                        for _,child in ipairs(grid:GetChildren()) do if child:IsA("GuiObject") then child:Destroy()end end
                        -- Match the original catalog's device-specific card width and spacing.
                        local width=math.max(1,viewport.AbsoluteSize.X-10)
                        local columns=math.max(1,math.floor(width/((mobile and 55 or 75)+gap)))
                        local cardWidth=(width-gap*(columns-1))/columns
                        local nameHeight=26
                        local footerHeight=24
                        local cardHeight=cardWidth+nameHeight+footerHeight+4
                        local available=math.max(1,viewport.AbsoluteSize.Y-4)
                        local rowHeight=cardHeight+gap
                        local rows=math.max(1,math.floor((available+gap)/rowHeight))
                        local perPage=columns*rows
                        maxPages=math.max(1,math.ceil(#items/perPage));page=math.clamp(page,1,maxPages)
                        pageText.Text=page.." / "..maxPages
                        previous.TextColor3=page>1 and theme.Text or theme.Muted
                        next.TextColor3=page<maxPages and theme.Text or theme.Muted
                        layout.CellSize=UDim2.fromOffset(cardWidth,cardHeight)
                        local first=(page-1)*perPage+1
                        local visible=math.min(perPage,#items-first+1)
                        grid.Size=UDim2.new(1,-10,0,math.max(0,math.ceil(math.max(0,visible)/columns)*rowHeight-gap))
                        viewport.CanvasPosition=Vector2.new(0,0)
                        local imageHeight=cardWidth-(mobile and 4 or 6)
                        for index=first,math.min(#items,first+perPage-1) do
                            local item=items[index]
                            local tile=ui:Round(ui:Create("Frame",{Name="CatalogItem",BackgroundColor3=theme.Surface,BorderSizePixel=0,LayoutOrder=index},grid),10)
                            ui:Create("UIStroke",{Color=theme.Line,Transparency=.45,Thickness=1},tile)
                            local button=ui:Create("TextButton",{Name="Play",Active=true,Text="",BorderSizePixel=0,Size=UDim2.new(1,0,1,-footerHeight),BackgroundTransparency=1},tile)
                            ui:Create("ImageLabel",{Size=UDim2.new(1,-(mobile and 4 or 6),0,imageHeight),Position=UDim2.fromOffset(mobile and 2 or 3,mobile and 2 or 3),BackgroundTransparency=1,
                                Image="rbxthumb://type="..(item.isAnimationPack and "BundleThumbnail" or "Asset").."&id="..tostring(item.bundleId or item.id).."&w=150&h=150"},button)
                            local name=ui:Label(button,item.name,10)
                            name.Name="ItemName";name.Position=UDim2.fromOffset(4,cardWidth+1);name.Size=UDim2.new(1,-8,0,nameHeight)
                            name.TextYAlignment=Enum.TextYAlignment.Top;name.TextTruncate=Enum.TextTruncate.AtEnd
                            name.ClipsDescendants=true
                            cardsScope:Connect(button.Activated,function()
                                if item.isAnimationPack then animationPicker:OpenPack(item)else play(c,item)end
                                status.Text=item.name
                            end)
                            local fav=ui:Create("TextButton",{Name="Favorite",Font=Enum.Font.Gotham,TextWrapped=false,Text=c.IsFavorite(item.bundleId or item.id) and "★" or "☆",Size=UDim2.fromOffset(22,22),
                                Position=UDim2.new(1,-25,1,-footerHeight),BackgroundTransparency=1,BorderSizePixel=0,TextColor3=theme.Accent,TextSize=14},tile)
                            cardsScope:Connect(fav.Activated,function()
                                local added=c.ToggleFavorite(item.bundleId or item.id);fav.Text=added and "★" or "☆"
                            end)
                            if id=="emotes" and not item.isAnimationPack then
                                local add=ui:Create("TextButton",{Name="AddToCombo",TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,Text="+ combo",Font=Enum.Font.Gotham,TextSize=8,TextColor3=theme.Muted,
                                    Size=UDim2.new(1,-29,0,22),Position=UDim2.new(0,3,1,-footerHeight),BackgroundTransparency=1,BorderSizePixel=0},tile)
                                cardsScope:Connect(add.Activated,function()
                                    if #combo>=3 then status.Text="El combo ya tiene 3 emotes.";return end
                                    combo[#combo+1]=item;status.Text="Combo: "..#combo.." / 3 · "..item.name
                                end)
                            end
                        end
                    end
                    local function filter()
                        version=version+1;local token=version
                        task.delay(.15,function()
                            if scope.Destroyed or token~=version then return end
                            local query=search.Text:lower();local result={};local source
                            if id=="animations" then source=c.AnimationPacks
                            elseif id=="favorites" or id=="recent" then
                                source={}
                                for _, key in ipairs(id=="favorites" and c.Favorites or c.RecentEmotes) do
                                    local item=c.EmotesById[tonumber(key)]
                                    if not item then for _,pack in ipairs(c.AnimationPacks)do if tonumber(pack.bundleId)==tonumber(key)then item=pack;break end end end
                                    if item then source[#source+1]=item end
                                end
                            else source=c.Emotes end
                            for index,item in ipairs(source) do
                                if query=="" or item.name:lower():find(query,1,true) or tostring(item.bundleId or item.id):find(query,1,true) then result[#result+1]=item end
                                if index%1500==0 then task.wait();if scope.Destroyed or token~=version then return end end
                            end
                            items=result;page=1;draw()
                        end)
                    end
                    scope:Connect(search:GetPropertyChangedSignal("Text"),filter)
                    scope:Connect(previous.Activated,function()if page>1 then page=page-1;draw()end end)
                    scope:Connect(next.Activated,function()if page<maxPages then page=page+1;draw()end end)
                    scope:Connect(viewport:GetPropertyChangedSignal("AbsoluteSize"),draw)
                    if id~="animations"then
                        local footer=ui:Create("Frame",{Position=UDim2.new(0,0,1,-36),Size=UDim2.new(1,-4,0,30),BackgroundTransparency=1},content)
                        if id=="emotes"then
                            local run=ui:Action(footer,scope,"Reproducir combo",function()
                                if #combo==0 then status.Text="Añade hasta 3 emotes con + combo.";return end
                                c.StartCombo(combo);status.Text="Combo en reproducción."
                            end,true)
                            run.Size=UDim2.new(.42,-6,1,0);run.TextSize=11
                            local clear=ui:Action(footer,scope,"Vaciar combo",function()combo={};status.Text="Combo vacío."end)
                            clear.Position=UDim2.fromScale(.42,0);clear.Size=UDim2.new(.36,-6,1,0);clear.TextSize=11
                        end
                        local halt=ui:Action(footer,scope,"Detener",function()stop(c);status.Text="Reproducción detenida."end)
                        halt.Position=UDim2.fromScale(id=="emotes"and .78 or 0,0)
                        halt.Size=UDim2.new(id=="emotes"and .22 or 1,0,1,0);halt.TextSize=11
                    end
                    filter()
                end)
            end)
        end,
    })
end
