return function(app)
    app.Services = {}
    for _, name in ipairs({"Players", "UserInputService", "HttpService"}) do
        app.Services[name] = game:GetService(name)
    end
    app.Player = app.Services.Players.LocalPlayer
    app.PlayerGui = app.Player:WaitForChild("PlayerGui", 10)
    assert(app.PlayerGui, "Sterling: PlayerGui unavailable")
    return app.Services
end
