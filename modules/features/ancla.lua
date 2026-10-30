return function(app)
    local ui,flows=app.UI,app.Flows.Ancla
    app.Features:Register({Id="ancla",Label="Ancla",Title="Ancla",Subtitle="Estabilidad y movimiento.",
        Mount=function(_,parent)
            ui:Workspace(parent,{{"normal","Normal",90},{"test","Test",76},{"mobile","Muévete 1.3",112}},function(id,body,scope)
                local stack=ui:Stack(body)
                local status=ui:Status(stack,scope)
                local function isolate(except)
                    if except~="test" and flows.Test.Running then flows.Test:Stop() end
                    if except~="mobile" and flows.MueveteV13.Running then flows.MueveteV13:Stop() end
                    if except~="normal" then
                        flows.Normal:SetHeartbeat(false);flows.Normal:SetAntiSeat(false);flows.Normal:SetAncla(false)
                    end
                end
                if id=="normal" then
                    ui:Note(stack,"Tres controles independientes para el ancla normal.")
                    for _,spec in ipairs({{"Ancla","AnclaEnabled","SetAncla"},{"AntiSeat","AntiSeatEnabled","SetAntiSeat"},{"Heartbeat","HeartbeatEnabled","SetHeartbeat"}})do
                        ui:Toggle(stack,scope,spec[1],function()return flows.Normal[spec[2]]end,function(v)
                            if v then isolate("normal")end
                            return flows.Normal[spec[3]](flows.Normal,v)
                        end)
                    end
                    ui:Action(stack,scope,"Forzar regreso",function()
                        local ok,err=flows.Regreso:Force();status.Text=err or (ok and "Regresando…" or "No hay checkpoint.")
                    end)
                elseif id=="test" then
                    ui:Note(stack,"Ancla estática con prevención de asientos integrada.")
                    ui:Toggle(stack,scope,"Activar Test",function()return flows.Test.Running end,function(v)
                        if v then isolate("test");return flows.Test:Start()else flows.Test:Stop();return true end
                    end)
                    ui:Toggle(stack,scope,"Regreso constante",function()return flows.Test.ConstantReturn end,function(v)return flows.Test:SetConstantReturn(v)end)
                else
                    ui:Note(stack,"Versión 1.3 · movimiento, protección de caídas y liberación de asientos.")
                    ui:Toggle(stack,scope,"Muévete anclado 1.3",function()return flows.MueveteV13.Running end,function(v)
                        if v then isolate("mobile");return flows.MueveteV13:Start()else flows.MueveteV13:Stop();return true end
                    end)
                    ui:Action(stack,scope,"Actualizar referencia segura",function()
                        flows.MueveteV13:ResetFallProtectionReference();status.Text="Referencia actualizada."
                    end)
                    if app.Legacy.ExperimentalFlingCore:IsAuthorized()then
                        ui:Action(stack,scope,"Copiar diagnóstico",function()
                            local copy=app.Environment.setclipboard or setclipboard
                            if copy then copy(flows.MueveteV13:GetDiagnosticReport());status.Text="Diagnóstico copiado."else status.Text="El ejecutor no permite copiar."end
                        end)
                    end
                end
                ui:Watch(scope,function()
                    local active=id=="normal" and flows.Normal.AnclaEnabled or id=="test" and flows.Test.Running or id=="mobile" and flows.MueveteV13.Running
                    if status.Text=="Listo." or status.Text=="Activo" or status.Text=="Desactivado" then status.Text=active and "Activo" or "Desactivado"end
                end)
            end)
        end})
end
