-- Dependency adapter for unchanged module copies. Never imports the old GUI.
return function(app)
    local globals = getfenv(0)
    local permitted = {}
    for _, key in ipairs({
        "assert", "error", "ipairs", "next", "pairs", "pcall", "print", "select", "tonumber", "tostring", "type", "typeof", "unpack", "warn", "xpcall",
        "setfenv", "getfenv", "setmetatable", "getmetatable", "rawget", "rawset",
        "math", "os", "string", "table", "coroutine", "utf8", "bit32", "task",
        "Enum", "Vector2", "Vector3", "CFrame", "Instance", "Color3", "UDim", "UDim2", "RaycastParams", "OverlapParams",
        "identifyexecutor", "getexecutorname", "sethiddenproperty", "setsimulationradius",
    }) do permitted[key] = true end
    local context = setmetatable({}, {__index = function(_, key)
        if permitted[key] then return globals[key] or app.Environment[key] end
    end})
    local runtime = {}
    local bindings = {}
    local service = game:GetService("RunService")
    local scopedRunService = setmetatable({}, {__index = function(_, key)
        local value = service[key]
        if type(value) == "function" then return function(_, ...) return value(service, ...) end end
        return value
    end})
    function scopedRunService:BindToRenderStep(name, priority, callback)
        bindings[name] = true
        return service:BindToRenderStep("Sterling::" .. name, priority, callback)
    end
    function scopedRunService:UnbindFromRenderStep(name)
        bindings[name] = nil
        return service:UnbindFromRenderStep("Sterling::" .. name)
    end
    context.game = setmetatable({GetService = function(_, name)
        if name == "RunService" then return scopedRunService end
        return game:GetService(name)
    end}, {__index = function(_, key)
        local value = game[key]
        if type(value) == "function" then return function(_, ...) return value(game, ...) end end
        return value
    end})
    context.workspace = workspace
    context.Players = app.Services.Players
    context.RunService = scopedRunService
    context.UserInputService = app.Services.UserInputService
    context.playerGui = app.PlayerGui
    context.player = app.Player
    context.isES = true
    context.getgenv = function() return runtime end
    context._genv = context.getgenv
    context._G = runtime
    context.Settings = app.Storage.Values
    context.SaveLocalData = function() return app.Storage:Save() end
    -- Same owner dependency used by the copied adjustable contact module.
    local owners = {
        [11739864999] = "psychoo778", [11743514302] = "ksablanca0", [11747901934] = "psycho777oo",
        [11797966007] = "psychoop77", [11866242235] = "dldl3341",
    }
    context.ExperimentalFlingCore = {IsAuthorized = function()
        return owners[app.Player.UserId] == string.lower(app.Player.Name)
    end}
    local function changed(section, message)
        if app.Alive and app.FlowChanged then app.FlowChanged(section, message) end
    end
    context.UpdateCameraControlPanel = function(message) changed("control", message) end
    context.UpdateCinematicCameraPanel = context.UpdateCameraControlPanel
    context.UpdateFlightControlPanel = context.UpdateCameraControlPanel
    context.UpdateMovementControlPanel = context.UpdateCameraControlPanel
    context.UpdateAnchorPanel = function(message) changed("ancla", message) end
    context.UpdateMoveAnchoredPanel = context.UpdateAnchorPanel
    context.UpdateFling2Panel = function(message) changed("volar", message) end
    context.UpdateContactFlingPanel = function(message) changed("volar", message) end
    context.UpdateAdjustableContactFlingPanel = context.UpdateContactFlingPanel
    context.UpdateCarFling2Panel = function(message) changed("volar", message) end
    app.Legacy = context
    app:OnCleanup(function()
        -- Disconnect observers before stopping so they cannot start another cycle.
        for _, name in ipairs({"_sterlingMovementCharacterAddedConn", "_fling2EfficientPlayerRemovingConn", "_fling2EfficientCharacterAddedConn", "_carFling2DeltaPlayerRemovingConn", "_carFling2DeltaMonitorConn", "_carFling2XenoPlayerRemovingConn", "_carFling2XenoMonitorConn"}) do
            local connection = rawget(context, name)
            if connection then connection:Disconnect() end
        end
        for _, name in ipairs({"SpectatorController", "FlightController", "MovementControlController", "XenoFlingReplicationAssist", "FlingReturnGuard", "AnchorForceReturn", "MobileAnchorV13Core", "StaticNoclipAnchorCore", "AnchorCore", "AdjustableContactFlingController", "ContactFlingController"}) do
            local controller = rawget(context, name)
            if name == "SpectatorController" and controller and not controller.Active then controller.Stop = function() end end
            if name == "FlightController" and controller and not controller.Flying then controller.Stop = function() end end
            if controller and controller.Destroy then pcall(controller.Destroy, controller) end
        end
        for _, name in ipairs({"CarFling2Delta", "CarFling2Xeno"}) do
            local engine = rawget(context, name)
            if engine then
                if engine.Running then engine:Stop() end
                while engine.Stopping do service.Heartbeat:Wait() end
            end
        end
        local automatic, efficient = context.Fling2AutoController, context.Fling2EfficientCore
        if automatic then automatic.Running = false;automatic.CurrentTarget = nil end
        if efficient and efficient.Running then efficient:Stop() end
        -- Finish an existing original Stop before a replacement app can start.
        if efficient then
            while efficient.Stopping do service.Heartbeat:Wait() end
        end
        for name in pairs(bindings) do service:UnbindFromRenderStep("Sterling::" .. name) end
        table.clear(bindings)
    end)
    return context
end
