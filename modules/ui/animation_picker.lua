-- Reuses the original per-state selection and saved-combination APIs.
return function(app)
    function app.UI:AnimationPicker(owner,context,status)
        local ui,theme=self,app.Theme
        local modal,scope
        local states={{"Idle","Reposo"},{"Walk","Caminar"},{"Run","Correr"},{"Jump","Saltar"},
            {"Fall","Caer"},{"Climb","Trepar"},{"Swim","Nadar"}}
        local function close()
            if scope then scope:Destroy();scope=nil end
            if modal then modal:Destroy();modal=nil end
        end
        owner.Cleanups[#owner.Cleanups+1]=close
        local function open(title)
            close();scope=ui:Scope();scope.OnError=owner.OnError
            modal=ui:Create("TextButton",{Name="AnimationPicker",Text="",Size=UDim2.fromScale(1,1),
                BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=.35,BorderSizePixel=0,Active=true,ZIndex=100},app.Window.Gui)
            local panel=ui:Round(ui:Create("Frame",{Name="PickerPanel",Size=UDim2.new(.9,0,.9,0),
                AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=theme.Surface,
                BorderSizePixel=0,Active=true,ZIndex=101},modal),14)
            ui:Create("UISizeConstraint",{MaxSize=Vector2.new(420,460)},panel)
            local heading=ui:Label(panel,title,16);heading.Font=Enum.Font.GothamBold
            heading.Size=UDim2.new(1,-66,0,40);heading.Position=UDim2.fromOffset(16,7)
            local exit=ui:Button(panel,"×");exit.Position=UDim2.new(1,-42,0,9);exit.Size=UDim2.fromOffset(32,32)
            scope:Connect(exit.Activated,close);scope:Connect(modal.Activated,close)
            local list=ui:Create("ScrollingFrame",{Size=UDim2.new(1,-28,1,-64),Position=UDim2.fromOffset(14,54),
                BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},panel)
            ui:Create("UIListLayout",{Padding=UDim.new(0,8)},list)
            return list
        end
        local picker={}
        function picker:OpenPack(pack)
            local list=open(pack.name)
            ui:Action(list,scope,"Equipar todo el paquete",function()
                if context.EquipAnimationPack(pack)then status.Text="Paquete equipado: "..pack.name;close()
                else status.Text="No se pudo equipar el paquete."end
            end,true)
            ui:Note(list,"O elige una parte para mezclarla con otros paquetes:")
            for _,entry in ipairs(states)do
                if pack.bundleId or pack[entry[1]]then
                    ui:Action(list,scope,entry[2],function()
                        if context.EquipAnimationPart(pack,entry[1])then
                            status.Text=entry[2].." · "..pack.name;close()
                        else status.Text="Esta parte no está disponible."end
                    end)
                end
            end
        end
        function picker:OpenCurrent()
            local list=open("Mi mezcla actual")
            local selected=context.Settings.animationPackSelection or {}
            for _,entry in ipairs(states)do
                local current=selected[entry[1]]
                local note=ui:Note(list,entry[2]..": "..(current and current.name or "Original"))
                note.TextColor3=theme.Text
            end
            ui:Action(list,scope,"Guardar esta mezcla",function()
                if self:Save()then close()else ui:Note(list,status.Text)end
            end,true)
            ui:Action(list,scope,"Restaurar animaciones originales",function()
                context.RemoveAnimationPacks();status.Text="Animaciones restauradas.";close()
            end)
        end
        function picker:Save()
            local ok=context.SaveAnimationCombination()
            status.Text=ok and "Combinación guardada." or
                "No se pudo guardar: revisa tu selección, duplicados o el límite de 3."
            return ok
        end
        function picker:OpenSaved()
            local list=open("Combinaciones guardadas")
            local saved=context.GetSavedAnimationCombinations()
            if #saved==0 then ui:Note(list,"Todavía no has guardado ninguna mezcla.")end
            for index,profile in ipairs(saved)do
                ui:Action(list,scope,"Aplicar · "..profile.name,function()
                    if context.ApplyAnimationCombination(index)then status.Text="Combinación aplicada: "..profile.name;close()
                    else status.Text="No se pudo aplicar la combinación."end
                end,true)
                ui:Action(list,scope,"Eliminar · "..profile.name,function()
                    context.DeleteAnimationCombination(index);status.Text="Combinación eliminada.";self:OpenSaved()
                end)
            end
            ui:Note(list,"Puedes guardar hasta 3 combinaciones, igual que en la GUI anterior.")
        end
        return picker
    end
end
