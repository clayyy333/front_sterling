-- Same soft top/bottom wash as the loading screen; no solid shadow frames.
return function(app)
    function app.UI:EdgeLights(parent,target,duration)
        local ui=self
        local root=ui:Create("Frame",{Name="WindowEdgeLights",BackgroundTransparency=1,BorderSizePixel=0,
            AnchorPoint=target.AnchorPoint,Position=target.Position,Size=target.Size,Visible=false,ZIndex=1},parent)
        local fade=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.87),
            NumberSequenceKeypoint.new(.35,.25),NumberSequenceKeypoint.new(.5,0),
            NumberSequenceKeypoint.new(.65,.25),NumberSequenceKeypoint.new(.85,.87),NumberSequenceKeypoint.new(1,1)})
        local tweens={}
        for index,name in ipairs({"TopWash","BottomWash"})do
            local y=index==1 and 0 or 1
            local start=index==1 and .22 or .78
            local finish=index==1 and .78 or .22
            local wash=ui:Create("Frame",{Name=name,BackgroundTransparency=1,BorderSizePixel=0,
                Size=UDim2.new(.84,0,0,48),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(start,y)},root)
            for row=0,47 do
                local distance=row+.5-24
                local strip=ui:Create("Frame",{Name="SoftRed",BorderSizePixel=0,Size=UDim2.new(1,0,0,1),
                    Position=UDim2.fromOffset(0,row),BackgroundColor3=Color3.fromRGB(210,24,59),
                    BackgroundTransparency=1-.48*math.exp(-((distance/10)^2))},wash)
                ui:Create("UIGradient",{Transparency=fade},strip)
            end
            tweens[index]=game:GetService("TweenService"):Create(wash,
                TweenInfo.new(duration or 2.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
                {Position=UDim2.fromScale(finish,y)})
        end
        local active=false
        local function update()
            root.Position=target.Position;root.Size=target.Size
            local visible=target.Visible and parent.Enabled
            root.Visible=visible
            if visible~=active then
                active=visible
                for _,tween in ipairs(tweens)do if active then tween:Play()else tween:Pause()end end
            end
        end
        app:Connect(target:GetPropertyChangedSignal("Position"),update)
        app:Connect(target:GetPropertyChangedSignal("Size"),update)
        app:Connect(target:GetPropertyChangedSignal("Visible"),update)
        app:Connect(parent:GetPropertyChangedSignal("Enabled"),update)
        app:OnCleanup(function()for _,tween in ipairs(tweens)do tween:Cancel()end;root:Destroy()end)
        update()
        return root
    end
end
