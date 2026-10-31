-- Movement engines have their own state; reuse catalogs prepared by the loader.
return function(app)
    local prepared = app.StartupCatalogs or {}
    local package = {Loaded = false, Loading = false, Context = nil,
        CatalogsReady = prepared["data/emotes"] ~= nil and prepared["data/animations"] ~= nil}
    local context
    local function dispose()
        if not context then return end
        context.isComboActive = false
        context._comboLoopEnabled = false
        if context.LocalEmoteFollow then pcall(context.LocalEmoteFollow.Destroy) end
        if context.StopEmote then pcall(context.StopEmote, false) end
        if context.SterlingDestroyAnimationPacks then pcall(context.SterlingDestroyAnimationPacks) end
        for _, key in ipairs({"_heartbeatConn", "_sterlingEmoteRemovingConn", "_sterlingEmoteAddedConn", "_sterlingAnimationAddedConn"}) do
            if context[key] then context[key]:Disconnect() end
        end
        if context.gui then context.gui:Destroy() end
        package.Loaded, package.Context = false, nil
        context = nil
    end
    app:OnCleanup(dispose)

    function package:EnsureLoaded()
        if not app.Alive then return false, "Sterling está cerrado." end
        if self.Loaded then return true, self.Context end
        if self.Loading then return false, "Movimientos está cargando." end
        local character = app.Player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false, "Espera a que aparezca tu personaje." end
        if humanoid.RigType == Enum.HumanoidRigType.R6 then return false, "Los emotes requieren R15." end
        self.Loading = true
        local ok, problem = pcall(function()
            local factories = {}
            local function compile(id)
                if not factories[id] then
                    if prepared[id] then factories[id]=prepared[id].Raw;return factories[id] end
                    local source = app.ReadSource("modules/movements/" .. id .. ".lua")
                    local chunk, err = loadstring(source, "@sterling/movements/" .. id)
                    assert(chunk, err)
                    factories[id] = chunk()
                end
                return factories[id]
            end
            local order = {"core/storage", "core/utilities", "ui/translations", "player/catalogs",
                "core/load_state", "player/animation_packs", "core/favorites", "player/emotes",
                "player/combos", "player/friend_follow"}
            for _, id in ipairs(order) do assert(type(compile(id)) == "function", "Invalid movement module: " .. id) end
            -- Fetch both catalogs before opening connections or changing state.
            local catalogs = { ["data/emotes"] = compile("data/emotes"), ["data/animations"] = compile("data/animations") }
            assert(type(catalogs["data/emotes"]) == "string" and type(catalogs["data/animations"]) == "string", "Invalid catalogs")
            assert(app.Alive, "Sterling está cerrado.")
            local http = app.Services.HttpService
            local scopedHttp = setmetatable({JSONDecode=function(_, raw)
                for _, entry in pairs(prepared) do
                    if entry.Raw==raw then return entry.Decoded end
                end
                return http:JSONDecode(raw)
            end}, {__index=function(_, key)
                local value=http[key]
                if type(value)=="function" then return function(_, ...) return value(http, ...) end end
                return value
            end})
            context = setmetatable({
                player = app.Player, selectedLang = "ES", HttpService = scopedHttp,
                TweenService = game:GetService("TweenService"), tick = tick,
                readfile = readfile, writefile = writefile, isfile = isfile,
                debugLog = function() end,
                Notify = function(title, message)
                    if app.Alive and app.FlowChanged then app.FlowChanged("movimientos", tostring(title or "") .. " " .. tostring(message or "")) end
                end,
                loadModule = function(id) assert(catalogs[id], "Unknown movement catalog");return catalogs[id] end,
            }, {__index = app.Legacy})
            -- This is only a lifetime signal for the copied friend-follow engine.
            context.gui = Instance.new("Folder")
            context.gui.Name = "SterlingMovementLifetime"
            context.gui.Parent = app.PlayerGui
            compile("core/storage")(context)
            context.LoadData()
            for index = 2, #order do compile(order[index])(context) end
            assert(app.Alive, "Sterling está cerrado.")
            -- Reuse the original keybind storage and playback functions.
            local keyConnection = app.Services.UserInputService.InputBegan:Connect(function(input, processed)
                if not app.Alive or processed or app.Services.UserInputService:GetFocusedTextBox() then return end
                local key = input.KeyCode and input.KeyCode.Name
                if not key then return end
                for id, entry in pairs(context.KeybindsSet) do
                    if type(entry)=="table" and tostring(entry.key):lower()==key:lower() then context.PlayEmote(id, entry.name);break end
                end
            end)
            app:OnCleanup(function() keyConnection:Disconnect() end)
            self.Context, self.Loaded = context, true
        end)
        self.Loading = false
        if not ok then dispose();return false, tostring(problem) end
        return true, self.Context
    end
    -- Load the saved outfit without requiring a visit to Movimientos first.
    function package:RestoreOnOpen()
        if self.StartupRestoreConnected then return end
        self.StartupRestoreConnected=true
        local function restore(character)
            task.defer(function()
                if not app.Alive or self.Loaded or self.Loading or not character then return end
                local humanoid=character:FindFirstChildOfClass("Humanoid")or character:WaitForChild("Humanoid",10)
                if not humanoid or not app.Alive or app.Player.Character~=character or self.Loaded or self.Loading then return end
                local ok,problem=self:EnsureLoaded()
                self.StartupRestoreError=not ok and tostring(problem)or nil
            end)
        end
        local added=app.Player.CharacterAdded:Connect(restore)
        app:OnCleanup(function()added:Disconnect()end)
        restore(app.Player.Character)
    end
    app.Flows.Movimientos = package
    return package
end
