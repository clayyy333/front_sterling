return function(app)
    app.Features:Register({Id="settings",Label="Ajustes",Title="Ajustes",Subtitle="Reproducción y preferencias.",
        Mount=function(_,parent)
            local ui=app.UI
            local scope=ui:Scope()
            app:OnCleanup(function()scope:Destroy()end)
            local loading=ui:Note(parent,"Cargando ajustes...")
            task.defer(function()
                local ok,c=app.Flows.Movimientos:EnsureLoaded()
                if scope.Destroyed or not app.Alive then return end
                loading:Destroy()
                local stack=ui:Stack(parent)
                if not ok then
                    ui:Note(stack,c)
                    ui:Action(stack,scope,"Reintentar",function()app.Navigation:Reload("settings")end)
                    return
                end
                local status=ui:Status(stack,scope)
                ui:Number(stack,scope,"Velocidad del emote",c.Settings.speed,function(n)
                    c.Settings.speed=math.clamp(n,0,10)
                    c.ApplySpeedToAllTracks();c.SaveLocalData();return true,c.Settings.speed
                end)
                for _,setting in ipairs({{"loopEmote","Repetir emote"},{"stopOnWalk","Detener al caminar"},
                    {"showHUD","Mostrar reproductor"},{"notifications","Notificaciones"}})do
                    ui:Toggle(stack,scope,setting[2],function()return c.Settings[setting[1]]end,function(v)
                        c.Settings[setting[1]]=v;c.SaveLocalData();return true
                    end)
                end
                ui:Action(stack,scope,"Restaurar animaciones originales",function()
                    c.RemoveAnimationPacks();status.Text="Animaciones restauradas."
                end)
                ui:Action(stack,scope,"Detener reproducción",function()
                    c.isComboActive=false;c._comboLoopEnabled=false;c.ComboQueue={};c.StopEmote(false)
                    status.Text="Reproducción detenida."
                end)
            end)
        end})
end
