-- First visible module; independent of catalogs and the application theme.
return function(environment)
    local parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui",10)
    assert(parent,"Sterling: PlayerGui unavailable")
    local run=game:GetService("RunService")
    local function create(class,properties,owner)
        local object=Instance.new(class)
        for key,value in pairs(properties)do object[key]=value end
        object.Parent=owner;return object
    end
    local function round(object,radius)
        create("UICorner",{CornerRadius=UDim.new(0,radius)},object);return object
    end
    local gui=create("ScreenGui",{Name="SterlingLoading",ResetOnSpawn=false,IgnoreGuiInset=true,
        DisplayOrder=1000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    local overlay=create("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(8,8,12),BackgroundTransparency=.25},gui)
    local tweenService=game:GetService("TweenService")
    local borderTweens={}
    -- Two horizontal light washes, not a glowing outline. Contiguous one-pixel
    -- rows fade vertically; their gradients fade horizontally, with no gaps,
    -- strokes or white peaks. Only the two holders animate.
    local lights=create("Frame",{Name="EdgeLights",AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},overlay)
    local horizontalFade=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.87),
        NumberSequenceKeypoint.new(.35,.25),NumberSequenceKeypoint.new(.5,0),
        NumberSequenceKeypoint.new(.65,.25),NumberSequenceKeypoint.new(.85,.87),
        NumberSequenceKeypoint.new(1,1)})
    for index,name in ipairs({"TopWash","BottomWash"})do
        local y=index==1 and 0 or 1
        local start=index==1 and .22 or .78
        local finish=index==1 and .78 or .22
        local wash=create("Frame",{Name=name,Size=UDim2.new(.68,0,0,32),AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromScale(start,y),BackgroundTransparency=1,BorderSizePixel=0},lights)
        for row=0,31 do
            local distance=row+.5-16
            local opacity=.34*math.exp(-((distance/6.5)^2))
            local strip=create("Frame",{Name="SoftRed",Size=UDim2.new(1,0,0,1),Position=UDim2.fromOffset(0,row),
                BackgroundColor3=Color3.fromRGB(210,24,59),BackgroundTransparency=1-opacity,BorderSizePixel=0},wash)
            create("UIGradient",{Transparency=horizontalFade},strip)
        end
        local tween=tweenService:Create(wash,TweenInfo.new(2.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {Position=UDim2.fromScale(finish,y)})
        borderTweens[#borderTweens+1]=tween;tween:Play()
    end
    local card=round(create("Frame",{Name="LoadingCard",ZIndex=2,AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.5),BorderSizePixel=0,ClipsDescendants=true,
        BackgroundColor3=Color3.fromRGB(20,16,23)},overlay),18)
    local image=tostring((environment.SterlingSource or {}).IntroImage or "125472021271676")
    if image:match("^%d+$")then image="rbxassetid://"..image end
    round(create("ImageLabel",{Name="PresentationImage",Image=image,BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop,ZIndex=1},card),18)
    local lowerShade=round(create("Frame",{Name="LowerShade",Size=UDim2.fromScale(1,1),
        BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0,ZIndex=3},card),18)
    create("UIGradient",{Rotation=90,Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.65,1),
        NumberSequenceKeypoint.new(.82,.82),NumberSequenceKeypoint.new(1,.35)})},lowerShade)
    local function label(name,text,size,position,height)
        return create("TextLabel",{Name=name,Text=text,Font=Enum.Font.GothamMedium,TextSize=size,
            TextColor3=Color3.fromRGB(255,240,246),BackgroundTransparency=1,Position=position,
            Size=UDim2.new(1,-44,0,height),TextWrapped=true,ZIndex=4},card)
    end
    local shadow=label("BrandShadow","STEFFANIA",50,UDim2.new(0,22,.39,2),62)
    shadow.Font=Enum.Font.Garamond;shadow.TextColor3=Color3.fromRGB(0,0,0);shadow.TextTransparency=.12
    shadow.TextStrokeColor3=Color3.fromRGB(0,0,0);shadow.TextStrokeTransparency=.45
    local depth=label("BrandDepth","STEFFANIA",50,UDim2.fromOffset(22,0),62)
    depth.Font=Enum.Font.Garamond;depth.TextColor3=Color3.fromRGB(83,36,57);depth.TextTransparency=.12
    local title=label("Brand","STEFFANIA",50,UDim2.new(0,22,.39,0),62)
    title.Font=Enum.Font.Garamond
    title.TextColor3=Color3.fromRGB(255,235,244)
    title.TextStrokeColor3=Color3.fromRGB(27,10,22);title.TextStrokeTransparency=.35
    local subtitle=label("Subtitle","La madrina sterling",14,UDim2.new(0,22,.55,0),24)
    subtitle.TextColor3=Color3.fromRGB(242,202,215)
    subtitle.TextStrokeColor3=Color3.fromRGB(8,4,10);subtitle.TextStrokeTransparency=.4
    local status=label("Stage","Cargando...",12,UDim2.new(0,22,1,-48),22)
    status.TextXAlignment=Enum.TextXAlignment.Left;status.Size=UDim2.new(1,-118,0,22)
    local track=round(create("Frame",{Name="ProgressTrack",Position=UDim2.new(0,22,1,-16),
        Size=UDim2.new(1,-44,0,4),BackgroundColor3=Color3.fromRGB(24,24,24),
        BackgroundTransparency=0,BorderSizePixel=0,ClipsDescendants=true,ZIndex=4},card),3)
    create("UIStroke",{Color=Color3.fromRGB(48,48,48),Thickness=1,Transparency=.6},track)
    local fill=round(create("Frame",{Name="Progress",Size=UDim2.fromScale(0,1),
        BackgroundColor3=Color3.fromRGB(225,65,99),BorderSizePixel=0,ZIndex=5},track),3)
    local percent=label("Percent","0%",11,UDim2.new(1,-84,1,-48),22)
    percent.Size=UDim2.fromOffset(62,22);percent.TextXAlignment=Enum.TextXAlignment.Right
    local close=create("TextButton",{Name="CloseLoading",Text="×",Font=Enum.Font.GothamMedium,TextSize=24,
        TextColor3=Color3.fromRGB(255,232,241),Size=UDim2.fromOffset(34,34),
        Position=UDim2.new(1,-44,0,10),BackgroundTransparency=1,ZIndex=6},card)
    local controller={Cancelled=false,Destroyed=false,Value=0}
    local connections={}
    connections[#connections+1]=close.Activated:Connect(function()controller.Cancelled=true;controller:Destroy()end)
    local function layout()
        local camera=workspace.CurrentCamera
        local view=camera and camera.ViewportSize or Vector2.new(960,640)
        local width=math.min(780,view.X*.88,view.Y*.8*16/9)
        card.Size=UDim2.fromOffset(width,math.min(math.max(width*9/16,220),view.Y*.8))
        local height=card.Size.Y.Offset
        lights.Size=UDim2.fromOffset(width,height)
        local size=math.clamp(math.floor(width*.058),24,44)
        title.TextSize=size;shadow.TextSize=size;depth.TextSize=size
        local titleHeight=math.floor(size*1.2)
        local subtitleHeight=18
        local top=height-60-titleHeight-subtitleHeight-3
        title.Size=UDim2.new(1,-44,0,titleHeight);shadow.Size=title.Size;depth.Size=title.Size
        title.Position=UDim2.fromOffset(22,top)
        shadow.Position=UDim2.fromOffset(23,top+4)
        depth.Position=UDim2.fromOffset(22,top+2)
        subtitle.Position=UDim2.fromOffset(22,top+titleHeight+3)
        subtitle.Size=UDim2.new(1,-44,0,subtitleHeight)
        subtitle.TextSize=width<450 and 11 or 13
    end
    local cameraConnection
    local function cameraChanged()
        if cameraConnection then cameraConnection:Disconnect()end
        if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)end
        layout()
    end
    connections[#connections+1]=workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged)
    cameraChanged()
    local lastYield=os.clock()
    function controller:Yield(force)
        if force or os.clock()-lastYield>=.008 then run.RenderStepped:Wait();lastYield=os.clock()end
    end
    function controller:Update(value)
        if self.Destroyed then return end
        self.Value=math.max(self.Value,math.clamp(value,0,1))
        fill.Size=UDim2.fromScale(self.Value,1)
        percent.Text=tostring(math.floor(self.Value*100)).."%"
        status.Text="Cargando...";self:Yield()
    end
    function controller:Fail()
        if self.Destroyed then return end
        status.Text="No se pudo completar la carga. Vuelve a ejecutar."
        percent.Text="Error";status.TextColor3=Color3.fromRGB(255,167,191)
    end
    function controller:Destroy()
        if self.Destroyed then return end
        self.Destroyed=true
        for _,tween in ipairs(borderTweens)do tween:Cancel()end
        for _,connection in ipairs(connections)do connection:Disconnect()end
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        gui:Destroy()
    end
    -- Let the presentation reach the display before synchronous catalog work.
    controller:Yield(true);controller:Yield(true)
    return controller
end
