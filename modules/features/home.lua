return function(app)
    app.Features:Register({Id="home",Label="Inicio",Title="",Subtitle="Bienvenido, "..app.Player.DisplayName,
        Mount=function(_,parent)
            local ui=app.UI;local stack=ui:Stack(parent);local scope=ui:Scope()
            app:OnCleanup(function()scope:Destroy()end)
            ui:Note(stack,"Todo listo. Elige una sección para empezar.")
            for _,item in ipairs({{"Movimientos · emotes y animaciones","movimientos"},{"Volar","volar"},{"Ancla","ancla"},{"Control de Personaje","control"}})do
                ui:Action(stack,scope,item[1],function()app.Navigation:Show(item[2])end)
            end
        end})
end
