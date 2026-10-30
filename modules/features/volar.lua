return function(app)
    app.Features:Register({
        Id = "volar", Label = "Volar", Title = "Volar", Subtitle = "Elige cómo quieres moverte.",
        Mount = function(context, parent)
            local ui = context.UI
            ui:Section(parent, "Sin objetivo", "Recorrido automático de jugadores.").LayoutOrder = 1
            ui:Section(parent, "Eficiente corto", "Flujo corto con selección de jugador.").LayoutOrder = 2
            ui:Section(parent, "Por contacto", "Pulsos de contacto y valores ajustables.").LayoutOrder = 3
            ui:Section(parent, "Con vehículos 2", "Versiones Delta y Xeno, con selección de vehículo y activación automática.").LayoutOrder = 4
        end,
    })
    return true
end
