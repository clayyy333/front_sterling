return function(app)
    local ui,f=app.UI,app.Flows.Volar
    app.Features:Register({Id="volar",Label="Volar",Title="Volar",Subtitle="Selecciona un modo y ajusta sus controles.",
        Mount=function(_,parent)
            ui:Workspace(parent,{{"auto","Sin objetivo",110},{"short","Eficiente corto",124},{"contact","Por contacto",116},{"cars","Vehículos 2",108}},function(id,body,scope)
                local stack=ui:Stack(body);local status=ui:Status(stack,scope)
                if id=="auto"then
                    ui:Note(stack,"Recorrido automático de jugadores con el flujo eficiente corto.")
                    ui:Toggle(stack,scope,"Sin objetivo",function()return f.SinObjetivo.Running end,function(v)
                        if v then return f.SinObjetivo:Start()else f.SinObjetivo:Stop();return true end
                    end)
                    ui:Action(stack,scope,"Forzar regreso",function()f.SinObjetivo:ForceReturn()end)
                elseif id=="short"then
                    local c=f.EficienteCorto
                    ui:Players(stack,scope,"Seleccionar jugador",function(p)c:SetTarget(p)end)
                    ui:Toggle(stack,scope,"Eficiente corto",function()return c.Running end,function(v)
                        if v then
                            if f.SinObjetivo.Running then f.SinObjetivo:Stop()end
                            c:SetShortDisplacementEnabled(true);return c:Start()
                        else c:Stop();return true end
                    end)
                    ui:Number(stack,scope,"Contacto (segundos)",c.ShortContactTime or .2,function(n)c:SetShortContactTime(n);return true,c.ShortContactTime end)
                    ui:Number(stack,scope,"Intervalo de regreso",c.ShortHomeInterval or .1,function(n)c:SetShortHomeInterval(n);return true,c.ShortHomeInterval end)
                    ui:Number(stack,scope,"Altura de contacto",c.ShortContactHeight or 1.5,function(n)c:SetShortContactHeight(n);return true,c.ShortContactHeight end)
                    ui:Action(stack,scope,"Forzar regreso",function()c:ForceReturn()end)
                elseif id=="contact"then
                    local c=f.PorContacto
                    ui:Toggle(stack,scope,"Por contacto",function()return c.Running end,function(v)
                        if v then return c:Start()else c:Stop();return true end
                    end)
                    ui:Range(stack,scope,"Intensidad general",c.Intensity,100000,c.MaxIntensity,function(n)c:SetIntensity(n);return true,c.Intensity end,true)
                    for _,axis in ipairs({"X","Y","Z"})do
                        ui:Number(stack,scope,"Velocidad · eje "..axis,c.Axes[axis],function(n)c:SetAxis(axis,n);return true,c.Axes[axis]end)
                    end
                    if c:CanTunePulse()then
                        for _,spec in ipairs({{"Duration","Duración del pulso"},{"BurstOn","Ráfaga activa"},{"BurstOff","Pausa entre ráfagas"}})do
                            ui:Number(stack,scope,spec[2],c.Pulse[spec[1]],function(n)return c:SetPulseParameter(spec[1],n)end)
                        end
                    end
                else
                    local cars=f.ConVehiculos2
                    local mode="Delta"
                    local function engine()return cars[mode]end
                    ui:Select(stack,scope,"Ejecutor · Delta",function()return {{Label="Delta",Value="Delta"},{Label="Xeno",Value="Xeno"}}end,function(v)
                        if engine().Running then engine():Stop()end
                        mode=v
                        if cars.Automatico.Mode then cars.Automatico:SetMode(v)end
                    end)
                    ui:Players(stack,scope,"Jugador objetivo",function(p)cars.Automatico:SetPlayer(p)end)
                    ui:Select(stack,scope,"Seleccionar mi vehículo",function()
                        local options={}
                        for _,car in ipairs(engine():GetCarOptions())do options[#options+1]={Label=car.Name,Value=car}end
                        return options
                    end,function(car)cars.Automatico:SetCar(car)end)
                    ui:Toggle(stack,scope,"Vehículos 2",function()return engine().Running end,function(v)
                        if v then return engine():Start()else engine():Stop();return true end
                    end)
                    ui:Toggle(stack,scope,"Activación automática",function()return cars.Automatico.Mode~=nil end,function(v)
                        return cars.Automatico:SetMode(v and mode or nil)
                    end)
                    ui:Note(stack,"Con automático activo, elige o genera tu vehículo en la GUI del juego.")
                    ui:Watch(scope,function()status.Text=cars.Automatico.LastError or (engine().Running and "Activo · "..mode or "Esperando selección · "..mode)end)
                end
            end)
        end})
end
