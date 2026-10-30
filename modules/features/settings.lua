return function(app)
    app.Features:Register({Id="settings",Label="Ajustes",Title="Ajustes",Subtitle="Apariencia, sonido y reproducción.",
        Mount=function(_,parent)
            local ui=app.UI;local scope=ui:Scope()
            app:OnCleanup(function()scope:Destroy()end)
            local stack=ui:Stack(parent)
            local status=ui:Status(stack,scope)
            local function section(text)
                local heading=ui:Note(stack,text);heading.Font=Enum.Font.GothamBold;heading.TextColor3=app.Theme.Text
                app.Appearance:BindColor(heading,"TextColor3","Text")
                heading.Size=UDim2.new(1,0,0,24)
            end
            section("Apariencia")
            local label="Color de la GUI"
            for _,entry in ipairs(app.Appearance:GetThemes())do if entry.Value==app.Appearance.ThemeId then label="Color · "..entry.Label end end
            ui:Select(stack,scope,label,function()return app.Appearance:GetThemes()end,function(id)
                local ok,err=app.Appearance:SetTheme(id);status.Text=ok and "Color aplicado y guardado."or err
            end)
            ui:Range(stack,scope,"Transparencia de la GUI (%)",app.Appearance.Transparency*100,0,80,function(n)
                return app.Appearance:SetTransparency(n)
            end,false,true)
            section("Sonido")
            ui:Toggle(stack,scope,"Sonido de ambiente",function()return app.Flows.Audio.Enabled end,function(v)
                return app.Flows.Audio:SetEnabled(v)
            end)
            local hint=ui:Note(stack,"Ambiente de día y noche, igual que en la GUI anterior.");hint.Size=UDim2.new(1,0,0,28)
            section("Reproducción")
            local loading=ui:Note(stack,"Cargando preferencias...")
            task.defer(function()
                local ok,c=app.Flows.Movimientos:EnsureLoaded()
                if scope.Destroyed or not app.Alive then return end
                loading:Destroy()
                if not ok then
                    ui:Note(stack,c)
                    ui:Action(stack,scope,"Reintentar",function()app.Navigation:Reload("settings")end)
                    return
                end
                ui:Range(stack,scope,"Velocidad de emote",c.Settings.speed,0,3,function(n)
                    c.Settings.speed=math.clamp(n,0,10);c.ApplySpeedToAllTracks();c.SaveLocalData()
                    return true,c.Settings.speed
                end)
                for _,setting in ipairs({{"loopEmote","Repetir emote"},{"stopOnWalk","Detener al caminar"},
                    {"showHUD","Mostrar barra de reproducción"}})do
                    ui:Toggle(stack,scope,setting[2],function()return c.Settings[setting[1]]end,function(v)
                        c.Settings[setting[1]]=v
                        if setting[1]=="loopEmote"and c.currentAnimTrack then c.currentAnimTrack.Looped=v end
                        c.SaveLocalData();return true
                    end)
                end
            end)
        end})
end
