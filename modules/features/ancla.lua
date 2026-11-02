return function(app)
    local ui,flows=app.UI,app.Flows.Ancla
    app.Features:Register({Id="ancla",Label="Ancla",Title="Ancla",Subtitle="Estabilidad y movimiento.",
        Mount=function(_,parent)
            ui:Workspace(parent,{{"normal","Normal",90},{"test","Test",76},{"mobile","Caminar anclado",144},{"automatic","Automática",110}},function(id,body,scope)
                local stack=ui:Stack(body)
                local status=ui:Status(stack,scope)
                local function isolate(except)
                    if except~="automatic" and flows.Automatica.Mode then flows.Automatica:Stop() end
                    if except~="test" and flows.Test.Running then flows.Test:Stop() end
                    if except~="mobile" and flows.MueveteV13.Running then flows.MueveteV13:Stop() end
                    if except~="normal" then
                        flows.Normal:SetHeartbeat(false);flows.Normal:SetAntiSeat(false);flows.Normal:SetAncla(false)
                    end
                end
                if id=="normal" then
                    ui:Note(stack,"Ancla normal con AntiSeat y Heartbeat integrados.")
                    ui:Toggle(stack,scope,"Activar Ancla",function()
                        return flows.Normal.AnclaEnabled and flows.Normal.AntiSeatEnabled and flows.Normal.HeartbeatEnabled
                    end,function(v)
                        if v then
                            isolate("normal")
                            local ok,err=flows.Normal:SetAncla(true)
                            if ok==false then return false,err end
                            flows.Normal:SetAntiSeat(true);flows.Normal:SetHeartbeat(true)
                        else
                            flows.Normal:SetHeartbeat(false);flows.Normal:SetAntiSeat(false);flows.Normal:SetAncla(false)
                        end
                        return true
                    end)
                    ui:Action(stack,scope,"Forzar regreso",function()
                        local ok,err=flows.Regreso:Force();status.Text=err or (ok and "Regresando…" or "No hay checkpoint.")
                    end)
                elseif id=="test" then
                    ui:Note(stack,"Ancla estática con prevención de asientos integrada.")
                    ui:Toggle(stack,scope,"Activar Test",function()return flows.Test.Running end,function(v)
                        if v then isolate("test");return flows.Test:Start()else flows.Test:Stop();return true end
                    end)
                    ui:Toggle(stack,scope,"Regreso constante",function()return flows.Test.ConstantReturn end,function(v)return flows.Test:SetConstantReturn(v)end)
                elseif id=="automatic" then
                    ui:Note(stack,"Activa Ancla, AntiSeat y Heartbeat y mantiene tu patín automáticamente.")
                    for _,mode in ipairs({"delta","xeno"})do
                        local selectedMode=mode
                        ui:Toggle(stack,scope,"Ancla con asiento "..(mode=="delta"and "Delta"or "Xeno"),function()
                            return flows.Automatica.Mode==selectedMode
                        end,function(v)
                            if flows.Automatica.Busy then return false,"Hay una operación en curso."end
                            if v then
                                if flows.Automatica.Mode and flows.Automatica.Mode~=selectedMode then return false,"Desactiva primero el otro modo."end
                                isolate("automatic")
                                return flows.Automatica:Start(selectedMode)
                            end
                            return flows.Automatica:Stop()
                        end)
                    end
                else
                    ui:Note(stack,"Versión 1.3 · movimiento, protección de caídas y liberación de asientos.")
                    ui:Toggle(stack,scope,"Caminar anclado",function()return flows.MueveteV13.Running end,function(v)
                        if v then isolate("mobile");return flows.MueveteV13:Start()else flows.MueveteV13:Stop();return true end
                    end)
                    ui:Action(stack,scope,"Actualizar referencia segura",function()
                        flows.MueveteV13:ResetFallProtectionReference();status.Text="Referencia actualizada."
                    end)

                end
                ui:Watch(scope,function()
                    if id=="automatic"then
                        local mode=flows.Automatica.Mode
                        local engine=mode=="delta"and app.Legacy.AutoSkateDelta or mode=="xeno"and app.Legacy.AutoSkateXeno
                        status.Text=(engine and engine.Status)or flows.Automatica.Status
                        return
                    end
                    local active=id=="normal" and flows.Normal.AnclaEnabled or id=="test" and flows.Test.Running or id=="mobile" and flows.MueveteV13.Running
                    if status.Text=="Listo." or status.Text=="Activo" or status.Text=="Desactivado" then status.Text=active and "Activo" or "Desactivado"end
                end)
            end)
        end})
end
