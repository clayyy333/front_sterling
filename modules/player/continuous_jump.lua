return function(app)
    local controller={Enabled=false,Speed=60,Held=false}
    local input=app.Services.UserInputService
    local run=app.Legacy.RunService
    local keyboard,touch,external=false,nil,false
    local ownedRoot
    local touchConnections={}
    local bound=setmetatable({},{__mode="k"})
    local function release()
        controller.Held=false
        if ownedRoot and ownedRoot.Parent then
            local v=ownedRoot.AssemblyLinearVelocity
            if v.Y>0 then ownedRoot.AssemblyLinearVelocity=Vector3.new(v.X,0,v.Z)end
        end
        ownedRoot=nil
    end
    function controller:SetEnabled(v)
        self.Enabled=v==true
        if not self.Enabled then keyboard=false;touch=nil;external=false;release()end
        return true
    end
    function controller:SetHeld(v)external=v==true;if not external and not keyboard and not touch then release()end end
    function controller:SetSpeed(v)self.Speed=math.clamp(tonumber(v)or self.Speed,10,500);return self.Speed end
    local function bindButton(button)
        if bound[button] or button.Name~="JumpButton" or not button:IsA("GuiButton")then return end
        bound[button]=true
        touchConnections[#touchConnections+1]=button.InputBegan:Connect(function(event)
            if controller.Enabled and event.UserInputType==Enum.UserInputType.Touch then touch=event end
        end)
    end
    for _, child in ipairs(app.PlayerGui:GetDescendants())do bindButton(child)end
    app:Connect(app.PlayerGui.DescendantAdded,bindButton)
    app:Connect(input.InputBegan,function(event,processed)
        if controller.Enabled and not processed and not input:GetFocusedTextBox() and event.KeyCode==Enum.KeyCode.Space then keyboard=true end
    end)
    app:Connect(input.InputEnded,function(event)
        if event.KeyCode==Enum.KeyCode.Space then keyboard=false end
        if event==touch then touch=nil end
        if not keyboard and not touch and not external then release()end
    end)
    if input.WindowFocusReleased then app:Connect(input.WindowFocusReleased,function()keyboard=false;touch=nil;external=false;release()end)end
    app:Connect(app.Player.CharacterAdded,function()keyboard=false;touch=nil;external=false;ownedRoot=nil;controller.Held=false end)
    app:Connect(run.PreSimulation or run.Heartbeat,function()
        local flying=app.Legacy.FlightController and app.Legacy.FlightController.Flying
        if not controller.Enabled or not(keyboard or touch or external)or flying then
            if ownedRoot then release()end
            return
        end
        local char=app.Player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart then return end
        local velocity=root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity=Vector3.new(velocity.X,controller.Speed,velocity.Z)
        ownedRoot=root;controller.Held=true
    end)
    app:OnCleanup(function()
        controller:SetEnabled(false)
        for _,c in ipairs(touchConnections)do c:Disconnect()end
    end)
    app.Flows.Control.SaltoContinuo=controller
    return controller
end
