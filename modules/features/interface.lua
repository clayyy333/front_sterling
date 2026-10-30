return function(app)
    app.Features:Register({Id="interface",Label="Interfaz",Title="Interfaz",Subtitle="Tu espacio, a tu medida.",
        Mount=function(_,parent)
            local ui=app.UI;local stack=ui:Stack(parent);local scope=ui:Scope()
            app:OnCleanup(function()scope:Destroy()end)
            ui:Note(stack,"Mueve la ventana desde la cabecera. Arrastra su esquina inferior para cambiar el tamaño.")
            ui:Action(stack,scope,"Centrar ventana",function()app.Window:Center()end)
            ui:Action(stack,scope,"Restablecer tamaño",function()app.Window:ResetSize()end)
            ui:Note(stack,"Tema predeterminado · Rubí oscuro")
        end})
end
