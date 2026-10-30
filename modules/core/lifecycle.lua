return function(app)
    local cleanups = {}
    function app:OnCleanup(callback)
        if not self.Alive then callback();return end
        cleanups[#cleanups + 1] = callback
    end
    function app:Connect(signal, callback)
        local connection = signal:Connect(function(...)
            if self.Alive then callback(...) end
        end)
        self:OnCleanup(function() connection:Disconnect() end)
        return connection
    end
    function app:Destroy()
        if not self.Alive then return end
        self.Alive = false
        for index = #cleanups, 1, -1 do pcall(cleanups[index]) end
        cleanups = {}
        if self.Environment.SterlingApp == self then self.Environment.SterlingApp = nil end
    end
    return true
end
