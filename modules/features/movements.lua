return function(app)
    local ui, theme, package=app.UI,app.Theme,app.Flows.Movimientos
    local tabs={{"emotes","Emotes",84},{"animations","Animaciones",108},{"favorites","Favoritos",94},
        {"recent","Recientes",92},{"friends","Amigos",82},{"keybinds","Atajos",76},{"settings","Ajustes",80}}
    local combo={}
    local function stop(c)
        c.isComboActive=false;c._comboLoopEnabled=false;c.ComboQueue={};c.StopEmote(false)
    end
    local function play(c,item)
        if item.isAnimationPack then c.EquipAnimationPack(item) else c.PlayEmote(item.id,item.name) end
    end
    app.Features:Register({Id="movimientos",Label="Movimientos",Title="Movimientos",Subtitle="Encuentra tu próximo movimiento.",
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
                    if id=="settings" then
                        ui:Number(content,scope,"Velocidad del emote",c.Settings.speed,function(n)
                            c.Settings.speed=math.clamp(n,0,10);c.ApplySpeedToAllTracks();c.SaveLocalData();return true,c.Settings.speed
                        end)
                        for _, setting in ipairs({{"loopEmote","Repetir emote"},{"stopOnWalk","Detener al caminar"},{"showHUD","Mostrar reproductor"},{"notifications","Notificaciones"}}) do
                            ui:Toggle(content,scope,setting[2],function()return c.Settings[setting[1]]end,function(v)c.Settings[setting[1]]=v;c.SaveLocalData();return true end)
                        end
                        ui:Action(content,scope,"Restaurar animaciones originales",function()c.RemoveAnimationPacks();status.Text="Animaciones restauradas."end)
                        ui:Action(content,scope,"Detener reproducción",function()stop(c);status.Text="Reproducción detenida."end)
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
                    local tools=ui:Create("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,LayoutOrder=-10},content)
                    local search=ui:Round(ui:Create("TextBox",{Name="CatalogSearch",Active=true,Selectable=true,Size=UDim2.new(1,-142,1,0),Text="",PlaceholderText="Buscar por nombre o ID…",ClearTextOnFocus=false,
                        Font=Enum.Font.Gotham,TextSize=12,TextColor3=theme.Text,BackgroundColor3=theme.Raised,BorderSizePixel=0},tools),8)
                    ui:Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)},search)
                    local previous=ui:Button(tools,"‹");previous.Position=UDim2.new(1,-134,0,0);previous.Size=UDim2.fromOffset(30,36)
                    local pageText=ui:Label(tools,"1 / 1",11);pageText.Position=UDim2.new(1,-102,0,0);pageText.Size=UDim2.fromOffset(68,36)
                    local next=ui:Button(tools,"›");next.Position=UDim2.new(1,-30,0,0);next.Size=UDim2.fromOffset(30,36)
                    local count=ui:Note(content,"");count.Size=UDim2.new(1,0,0,18);count.LayoutOrder=-9
                    local animationState="Completo"
                    if id=="animations"then
                        local choose=ui:Select(content,scope,"Aplicar paquete completo",function()
                            local result={}
                            for _,entry in ipairs({{"Completo","Paquete completo"},{"Idle","En reposo"},{"Walk","Caminar"},{"Run","Correr"},{"Jump","Saltar"},{"Fall","Caer"},{"Climb","Trepar"},{"Swim","Nadar"}})do
                                result[#result+1]={Value=entry[1],Label=entry[2]}
                            end
                            return result
                        end,function(v)animationState=v end)
                        choose.Parent.LayoutOrder=-8
                        ui:Action(content,scope,"Guardar combinación actual",function()
                            status.Text=c.SaveAnimationCombination()and "Combinación guardada."or"No se pudo guardar. Comprueba tu selección y el límite de 3."
                        end)
                        ui:Select(content,scope,"Aplicar combinación guardada",function()
                            local result={}
                            for index,profile in ipairs(c.GetSavedAnimationCombinations())do result[#result+1]={Value=index,Label=profile.name}end
                            return result
                        end,function(index)c.ApplyAnimationCombination(index)end)
                        ui:Action(content,scope,"Restaurar animaciones originales",function()c.RemoveAnimationPacks();status.Text="Animaciones restauradas."end)
                    end
                    local grid=ui:Create("Frame",{Name="CatalogGrid",Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,LayoutOrder=-8},content)
                    local layout=ui:Create("UIGridLayout",{CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder},grid)
                    local items,page,version={},1,0
                    local cardsScope
                    scope.Cleanups[#scope.Cleanups+1]=function()if cardsScope then cardsScope:Destroy()end end
                    local function draw()
                        if scope.Destroyed then return end
                        if cardsScope then cardsScope:Destroy()end;cardsScope=ui:Scope();cardsScope.OnError=scope.OnError
                        for _,child in ipairs(grid:GetChildren()) do if child:IsA("GuiObject") then child:Destroy()end end
                        local columns=math.clamp(math.floor(math.max(180,body.AbsoluteSize.X)/112),2,6)
                        local perPage=columns*3
                        local pages=math.max(1,math.ceil(#items/perPage));page=math.clamp(page,1,pages)
                        pageText.Text=page.." / "..pages;count.Text=#items.." resultados"
                        layout.CellSize=UDim2.new(1/columns,-8,0,142)
                        local first=(page-1)*perPage+1
                        local visible=math.min(perPage,#items-first+1)
                        grid.Size=UDim2.new(1,0,0,math.ceil(math.max(0,visible)/columns)*150)
                        for index=first,math.min(#items,first+perPage-1) do
                            local item=items[index]
                            local tile=ui:Round(ui:Create("Frame",{Name="CatalogItem",BackgroundColor3=theme.Surface,BorderSizePixel=0,LayoutOrder=index},grid),10)
                            ui:Create("UIStroke",{Color=theme.Line,Transparency=.45,Thickness=1},tile)
                            local button=ui:Create("TextButton",{Name="Play",Active=true,Text="",Size=UDim2.new(1,0,1,-28),BackgroundTransparency=1},tile)
                            ui:Create("ImageLabel",{Size=UDim2.new(1,-18,0,76),Position=UDim2.fromOffset(9,6),BackgroundTransparency=1,
                                Image="rbxthumb://type="..(item.isAnimationPack and "BundleThumbnail" or "Asset").."&id="..tostring(item.bundleId or item.id).."&w=150&h=150"},button)
                            local name=ui:Label(button,item.name,11);name.Position=UDim2.fromOffset(7,84);name.Size=UDim2.new(1,-14,0,28)
                            cardsScope:Connect(button.Activated,function()
                                if item.isAnimationPack and animationState~="Completo"then c.EquipAnimationPart(item,animationState)else play(c,item)end
                                status.Text=item.name
                            end)
                            local fav=ui:Create("TextButton",{Text=c.IsFavorite(item.bundleId or item.id) and "★" or "☆",Size=UDim2.fromOffset(30,26),
                                Position=UDim2.new(1,-34,1,-28),BackgroundTransparency=1,TextColor3=theme.Accent,TextSize=20},tile)
                            cardsScope:Connect(fav.Activated,function()
                                local added=c.ToggleFavorite(item.bundleId or item.id);fav.Text=added and "★" or "☆"
                            end)
                            if not item.isAnimationPack then
                                local add=ui:Create("TextButton",{Text="+ combo",Font=Enum.Font.Gotham,TextSize=10,TextColor3=theme.Muted,
                                    Size=UDim2.new(1,-36,0,26),Position=UDim2.new(0,3,1,-28),BackgroundTransparency=1},tile)
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
                    scope:Connect(previous.Activated,function()page=math.max(1,page-1);draw()end)
                    scope:Connect(next.Activated,function()page=page+1;draw()end)
                    scope:Connect(body:GetPropertyChangedSignal("AbsoluteSize"),draw)
                    ui:Action(content,scope,"Reproducir combo",function()
                        if #combo==0 then status.Text="Añade hasta 3 emotes con + combo.";return end
                        c.StartCombo(combo);status.Text="Combo en reproducción."
                    end,true)
                    ui:Action(content,scope,"Vaciar combo",function()combo={};status.Text="Combo vacío."end)
                    ui:Action(content,scope,"Detener",function()stop(c);status.Text="Reproducción detenida."end)
                    filter()
                end)
            end)
        end,
    })
end
