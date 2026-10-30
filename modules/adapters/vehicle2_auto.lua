-- Automatic selection logic from ui/fling_car2.lua, separated from its buttons.
return function(app)
    local context = app.Legacy
    local delta, xeno = context.CarFling2Delta, context.CarFling2Xeno
    local auto = {Mode = nil, Starting = false, LastError = nil}
    local elapsed = 0
    local function refresh(message)
        auto.LastError = message
        context.UpdateCarFling2Panel(message)
    end
    function auto:TryStart()
        if not app.Alive or self.Starting or delta.Running or xeno.Running then return end
        local selected = self.Mode == "Delta" and delta or self.Mode == "Xeno" and xeno or nil
        if not selected or not selected:GetCar() or not selected:GetPlayer() then return end
        self.Starting = true
        local ok, problem = selected:Start()
        self.Starting = false
        refresh(ok and nil or problem)
        return ok, problem
    end
    function auto:SetMode(mode)
        if mode ~= nil and mode ~= "Delta" and mode ~= "Xeno" then return false end
        self.Mode = mode
        refresh()
        self:TryStart()
        return true
    end
    function auto:SetPlayer(target)
        delta:SetPlayer(target);xeno:SetPlayer(target)
        refresh()
        task.defer(function() self:TryStart() end)
    end
    function auto:SetCar(car)
        delta:SetCar(car);xeno:SetCar(car)
        refresh()
    end
    app:Connect(context.RunService.Heartbeat, function(dt)
        if not auto.Mode then elapsed = 0;return end
        elapsed = elapsed + dt
        if elapsed < .25 then return end
        elapsed = 0
        if delta.Running or xeno.Running then return end
        local cars = delta:GetCarOptions()
        local detected = #cars > 0 and cars[#cars] or nil
        if delta:GetCar() ~= detected or xeno:GetCar() ~= detected then
            delta:SetCar(detected);xeno:SetCar(detected)
            refresh()
            task.defer(function() auto:TryStart() end)
        end
    end)
    app:OnCleanup(function() auto.Mode = nil end)
    app.Flows.Volar.ConVehiculos2.Automatico = auto
    return auto
end
