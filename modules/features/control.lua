return function(app)
    app.Features:Register({
        Id = "control", Label = "Control", Title = "Control", Subtitle = "Cámara y movimiento.",
        Mount = function(context, parent)
            context.UI:Section(parent, "Perspectiva de cámara", "Perspectiva orbital, selección de jugador y zoom.")
            context.UI:Section(parent, "Control de vuelo", "Vuelo con controles de teclado y táctiles, velocidad normal y sprint.").LayoutOrder = 2
            context.UI:Section(parent, "Control de velocidad", "Velocidad de movimiento, salto y restauración de los valores originales.").LayoutOrder = 3
        end,
    })
    return true
end
