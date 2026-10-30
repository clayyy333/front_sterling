return function(app)
    local ui,flows=app.UI,app.Flows.Control
    app.Features:Register({Id="control",Label="Control",Title="Control",Subtitle="Cámara, vuelo y movimiento.",
        Mount=function(_,parent)
            ui:Workspace(parent,{{"camera","Cámara",86},{"flight","Vuelo",76},{"speed","Velocidad",92},{"jump","Salto infinito",122}},function(id,body,scope)
                local stack=ui:Stack(body);local status=ui:Status(stack,scope)
                if id=="camera"then
                    local c=flows.PerspectivaCamara
                    ui:Players(stack,scope,"Elegir jugador observado",function(p)c:SetTarget(p)end)
                    ui:Toggle(stack,scope,"Perspectiva orbital",function()return c:IsActive()end,function(v)
                        if v then return c:Start()else c:Stop();return true end
                    end)
                    ui:Number(stack,scope,"Distancia de cámara",c:GetZoom(),function(n)return true,c:SetZoom(n)end)
                    ui:Note(stack,"PC: clic derecho para girar, rueda para zoom. En móvil: arrastra la pantalla.")
                elseif id=="flight"then
                    local c=flows.Vuelo
                    ui:Toggle(stack,scope,"Activar vuelo",function()return c:IsFlying()end,function(v)
                        if v then return c:Start()else c:Stop();return true end
                    end)
                    ui:Range(stack,scope,"Velocidad normal",c:GetNormalSpeed(),20,300,function(n)return true,c:SetNormalSpeed(n)end)
                    ui:Range(stack,scope,"Velocidad sprint",c:GetSprintSpeed(),100,1000,function(n)return true,c:SetSprintSpeed(n)end)
                    ui:Toggle(stack,scope,"Sprint",function()return c.SprintExternal end,function(v)c:SetSprint(v);return true end)
                    ui:Action(stack,scope,"Frenar",function()c:FastStop()end)
                    for _,spec in ipairs({{"Subir","Up"},{"Bajar","Down"}})do
                        local button=ui:Button(stack,"Mantener · "..spec[1]);button.Size=UDim2.new(1,-2,0,36)
                        local pointer
                        scope:Connect(button.InputBegan,function(event)
                            if event.UserInputType==Enum.UserInputType.Touch or event.UserInputType==Enum.UserInputType.MouseButton1 then pointer=event;c:SetMobileDirection(spec[2],true)end
                        end)
                        scope:Connect(app.Services.UserInputService.InputEnded,function(event)
                            if event==pointer then pointer=nil;c:SetMobileDirection(spec[2],false)end
                        end)
                    end
                    scope.Cleanups[#scope.Cleanups+1]=function()c:ClearMobileInput()end
                    ui:Note(stack,"WASD para moverte, espacio para subir, Ctrl para bajar. En móvil usa el joystick.")
                elseif id=="speed"then
                    local c=flows.Velocidad
                    local defaults=c:GetDefaults()or{}
                    ui:Number(stack,scope,"Velocidad al caminar",c.DesiredWalkSpeed or defaults.WalkSpeed or 16,function(n)return c:SetWalkSpeed(n)end)
                    ui:Number(stack,scope,"Fuerza del salto",defaults.JumpPower or 50,function(n)return c:SetJump(n)end)
                    ui:Action(stack,scope,"Restaurar velocidad",function()local _,msg=c:RestoreWalkSpeed();status.Text="Velocidad: "..tostring(msg)end)
                    ui:Action(stack,scope,"Restaurar salto",function()c:RestoreJump();status.Text="Salto restaurado."end)
                    ui:Players(stack,scope,"Destino de teletransporte",function(p)c:SetTarget(p)end)
                    ui:Action(stack,scope,"Ir al jugador",function()local _,msg=c:Teleport();status.Text=msg end)
                else
                    local c=flows.SaltoContinuo
                    ui:Note(stack,"Mantén pulsado el salto para elevarte. Al soltar, vuelves a caer.")
                    ui:Toggle(stack,scope,"Salto infinito",function()return c.Enabled end,function(v)return c:SetEnabled(v)end)
                    ui:Range(stack,scope,"Velocidad de ascenso",c.Speed,10,500,function(n)return true,c:SetSpeed(n)end)
                    local hold=ui:Button(stack,"Mantener para subir",true);hold.Size=UDim2.new(1,-2,0,40)
                    local pointer
                    scope:Connect(hold.InputBegan,function(event)
                        if event.UserInputType==Enum.UserInputType.Touch or event.UserInputType==Enum.UserInputType.MouseButton1 then pointer=event;c:SetHeld(true)end
                    end)
                    scope:Connect(app.Services.UserInputService.InputEnded,function(event)if event==pointer then pointer=nil;c:SetHeld(false)end end)
                    scope.Cleanups[#scope.Cleanups+1]=function()c:SetHeld(false)end
                end
            end)
        end})
end
