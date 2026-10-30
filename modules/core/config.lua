return function(app)
    app.Config = {
        Name = "STERLING", Version = "0.2.0", GuiName = "SterlingFront",
        DefaultPage = "home", Width = 760, Height = 490,
        StorageFile = "sterling_preferences_v1.json",
    }
    return app.Config
end
