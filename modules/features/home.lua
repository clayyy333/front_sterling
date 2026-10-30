return function(app)
    app.Features:Register({
        Id = "home", Label = "Inicio", Title = "Todo en su lugar.",
        Subtitle = "Bienvenido, " .. app.Player.DisplayName,
        Mount = function(context, parent)
            local ui, theme = context.UI, context.Theme
            local welcome = ui:Section(parent, "Tu espacio Sterling", "Una nueva forma de organizar lo que usas, con los controles siempre a mano.")
            welcome.LayoutOrder = 1
            local tag = ui:Label(welcome, "S T E R L I N G", 11)
            tag.TextColor3 = theme.Accent;tag.Size = UDim2.new(1, -40, 0, 18);tag.Position = UDim2.fromOffset(20, 110)
            welcome.Size = UDim2.new(1, 0, 0, 150)
            local empty = ui:Section(parent, "Tu panel está listo", "Las funciones que elijas aparecerán aquí. Puedes mover, ajustar o minimizar esta ventana.")
            empty.LayoutOrder = 2
        end,
    })
    return true
end
