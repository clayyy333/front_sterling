return function(app)
    app.Features:Register({
        Id = "interface", Label = "Interfaz", Title = "Ajusta tu espacio.", Subtitle = "Una ventana que se adapta a ti.",
        Mount = function(context, parent)
            local ui = context.UI
            local card = ui:Section(parent, "Posición y tamaño", "Arrastra la barra superior para mover la ventana y la esquina inferior para cambiar su tamaño.")
            card.Size = UDim2.new(1, 0, 0, 198)
            local center = ui:Button(card, "Centrar ventana")
            center.Position = UDim2.new(0, 20, 0, 136);center.Size = UDim2.new(.5, -26, 0, 40)
            local reset = ui:Button(card, "Restablecer tamaño")
            reset.Position = UDim2.new(.5, 6, 0, 136);reset.Size = UDim2.new(.5, -26, 0, 40)
            context:Connect(center.Activated, function() context.Window:Center() end)
            context:Connect(reset.Activated, function() context.Window:ResetSize() end)
            local version = ui:Label(parent, "Sterling · " .. context.Config.Version, 12)
            version.TextColor3 = context.Theme.Muted;version.Size = UDim2.new(1, 0, 0, 24);version.LayoutOrder = 2
        end,
    })
    return true
end
