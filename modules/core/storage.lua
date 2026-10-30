return function(app)
    local environment = app.Environment
    local storage = {Values = type(environment.SterlingPreferences) == "table" and environment.SterlingPreferences or {}}
    local file = app.Config.StorageFile
    local decode = app.Services.HttpService
    if type(readfile) == "function" then
        local ok, result = pcall(function() return decode:JSONDecode(readfile(file)) end)
        if ok and type(result) == "table" and result.version == 1 and type(result.preferences) == "table" then
            storage.Values = result.preferences
        end
    end
    if storage.Values.LayoutRevision ~= 2 then
        storage.Values.Width,storage.Values.Height=app.Config.Width,app.Config.Height
        storage.Values.LayoutRevision=2
    end
    local function validSize(value)
        return type(value) == "number" and value == value and value >= 280 and value <= 4096
    end
    if not validSize(storage.Values.Width) then storage.Values.Width = app.Config.Width end
    if not validSize(storage.Values.Height) then storage.Values.Height = app.Config.Height end
    function storage:Save()
        environment.SterlingPreferences = self.Values
        if type(writefile) ~= "function" then return false end
        return pcall(function()
            writefile(file, decode:JSONEncode({version = 1, preferences = self.Values}))
        end)
    end
    app.Storage = storage
    return storage
end
