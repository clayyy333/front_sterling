return function(app)
    app.Features:Register({
        Id = "ancla", Label = "Ancla", Title = "Ancla", Subtitle = "Estabilidad donde la necesitas.",
        Mount = function(context, parent)
            context.UI:Section(parent, "Ancla", "Ancla normal, AntiSeat, Heartbeat y regreso al punto guardado.")
            context.UI:Section(parent, "Test", "Ancla estática con regreso constante opcional y prevención de asientos integrada a 15 studs.").LayoutOrder = 2
            context.UI:Section(parent, "Muévete anclado 1.3", "Movimiento con protección de caídas y liberación de conexiones externas.").LayoutOrder = 3
        end,
    })
    return true
end
