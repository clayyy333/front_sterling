return function(app)
    app.Config = {
        Name = "STERLING", Version = "0.1.0", GuiName = "SterlingFront",
        DefaultPage = "home", Width = 860, Height = 550,
        StorageFile = "sterling_preferences_v1.json",
    }
    return app.Config
end
