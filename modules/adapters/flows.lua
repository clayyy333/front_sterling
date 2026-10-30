-- Public integration surface for future controls; engines remain unchanged.
return function(app)
    local context = app.Legacy
    context.Fling2EfficientCore:SetShortDisplacementEnabled(true)
    app.Flows = {
        Volar = {
            SinObjetivo = context.Fling2AutoController,
            EficienteCorto = context.Fling2EfficientCore,
            PorContacto = context.AdjustableContactFlingController,
            ConVehiculos2 = {Delta = context.CarFling2Delta, Xeno = context.CarFling2Xeno},
        },
        Control = {PerspectivaCamara = context.SpectatorController, Vuelo = context.FlightController, Velocidad = context.MovementControlController},
        Ancla = {Normal = context.AnchorCore, Regreso = context.AnchorForceReturn, Test = context.StaticNoclipAnchorCore, MueveteV13 = context.MobileAnchorV13Core},
    }
    return app.Flows
end
