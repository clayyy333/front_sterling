return function(app)
    app.Features:Register({
        Id = "movimientos", Label = "Movimientos", Title = "Movimientos",
        Subtitle = "Emotes, animaciones y tus selecciones.",
        Mount = function(context, parent)
            for index, item in ipairs({
                {"Emotes", "Catálogo completo, búsqueda y reproducción."},
                {"Animaciones", "Paquetes, mezcla por estado y combinaciones guardadas."},
                {"Favoritos y recientes", "Selecciones e historial con almacenamiento independiente."},
                {"Amigos", "Seguimiento de emotes visibles de amigos del servidor."},
                {"Atajos", "Asignación de teclas para reproducir emotes."},
                {"Ajustes", "Preferencias originales de Movimientos."},
                {"HUD y combos", "Fuentes copiadas para distribuir sus controles en el nuevo diseño."},
            }) do context.UI:Section(parent, item[1], item[2]).LayoutOrder = index end
        end,
    })
    return true
end
