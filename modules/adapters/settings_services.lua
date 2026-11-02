return function(app)
    local audio={Enabled=app.Storage.Values.AmbientSound~=false}
    local context
    local function dispose()
        if context and context.AmbientSoundController then context.AmbientSoundController:Destroy()end
        context=nil
    end
    app:OnCleanup(dispose)
    function audio:SetEnabled(value)
        value=value==true
        if value then dispose()
        else
            if not context then
                local source=app.ReadSource("modules/movements/player/ambient_sound.lua")
                if not app.Alive then return false,"La GUI está cerrada."end
                local chunk,err=loadstring(source,"@sterling/ambient_sound");if not chunk then return false,err end
                context=setmetatable({Settings={ambientSound=false}},{__index=app.Legacy})
                local ok,problem=pcall(function()chunk()(context)end)
                if not ok then dispose();return false,tostring(problem)end
            end
            context.AmbientSoundController:SetEnabled(false)
        end
        self.Enabled=value;app.Storage.Values.AmbientSound=value;app.Storage:Save()
        return true
    end
    local antiAFK={Enabled=app.Storage.Values.AntiAFK==true}
    local antiContext
    local function disposeAntiAFK()
        if antiContext and antiContext.AntiAFKController then antiContext.AntiAFKController:Destroy()end
        antiContext=nil
    end
    app:OnCleanup(disposeAntiAFK)
    function antiAFK:SetEnabled(value)
        value=value==true
        if not app.Alive then return false,"La GUI está cerrada."end
        if value and not antiContext then
            local source=app.ReadSource("modules/movements/player/anti_afk.lua")
            if not app.Alive then return false,"La GUI está cerrada."end
            local chunk,err=loadstring(source,"@sterling/anti_afk");if not chunk then return false,err end
            antiContext=setmetatable({Settings={antiAFK=false}},{__index=app.Legacy})
            local ok,problem=pcall(function()chunk()(antiContext)end)
            if not ok then disposeAntiAFK();return false,tostring(problem)end
        end
        if antiContext then antiContext.AntiAFKController:SetEnabled(value)end
        self.Enabled=value;app.Storage.Values.AntiAFK=value;app.Storage:Save()
        return true
    end
    app.Flows.AntiAFK=antiAFK
    if antiAFK.Enabled then task.defer(function()if app.Alive then antiAFK:SetEnabled(true)end end)end
    app.Flows.Audio=audio
    if not audio.Enabled then task.defer(function()if app.Alive then audio:SetEnabled(false)end end)end
    return audio
end
