-- First visible module; independent of catalogs and the application theme.
return function(environment)
    local parent=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui",10)
    assert(parent,"Sterling: PlayerGui unavailable")
    local run=game:GetService("RunService")
    local function create(class, properties, owner)
        local object=Instance.new(class)
        for key,value in pairs(properties) do object[key]=value end
        object.Parent=owner;return object
    end
    local function round(object,radius)
        create("UICorner",{CornerRadius=UDim.new(0,radius)},object);return object
    end
    local gui=create("ScreenGui",{Name="SterlingLoading",ResetOnSpawn=false,IgnoreGuiInset=true,
        DisplayOrder=1000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    local overlay=create("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(8,8,12),BackgroundTransparency=.12},gui)
    local card=round(create("Frame",{Name="LoadingCard",Size=UDim2.new(.88,0,0,280),
        AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(20,20,27)},overlay),18)
    create("UISizeConstraint",{MaxSize=Vector2.new(420,280)},card)
    create("UIStroke",{Color=Color3.fromRGB(86,38,49),Thickness=1},card)
    local badge=round(create("Frame",{Size=UDim2.fromOffset(66,66),AnchorPoint=Vector2.new(.5,0),
        Position=UDim2.new(.5,0,0,28),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(111,31,47)},card),18)
    local symbol=create("TextLabel",{Text="S",Font=Enum.Font.GothamBold,TextSize=36,
        TextColor3=Color3.fromRGB(255,230,234),BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},badge)
    local image=(environment.SterlingSource or {}).IntroImage
    if image and tostring(image)~="" then
        image=tostring(image);if image:match("^%d+$") then image="rbxassetid://"..image end
        local art=create("ImageLabel",{Name="PresentationImage",Image=image,BackgroundTransparency=1,
            Size=UDim2.fromScale(1,1),ZIndex=2},badge)
        symbol.ZIndex=1
    end
    local function label(name,text,size,y,height)
        return create("TextLabel",{Name=name,Text=text,Font=Enum.Font.GothamMedium,TextSize=size,
            TextColor3=Color3.fromRGB(240,236,240),BackgroundTransparency=1,
            Position=UDim2.fromOffset(24,y),Size=UDim2.new(1,-48,0,height),TextWrapped=true},card)
    end
    local title=label("Brand","S T E R L I N G",19,112,26);title.Font=Enum.Font.GothamBold
    local status=label("Stage","Preparando la carga…",12,154,34);status.TextColor3=Color3.fromRGB(171,161,173)
    local track=round(create("Frame",{Position=UDim2.fromOffset(24,208),Size=UDim2.new(1,-48,0,6),
        BackgroundColor3=Color3.fromRGB(45,37,46),BorderSizePixel=0,ClipsDescendants=true},card),3)
    local fill=round(create("Frame",{Name="Progress",Size=UDim2.fromScale(0,1),
        BackgroundColor3=Color3.fromRGB(220,53,75),BorderSizePixel=0},track),3)
    local percent=label("Percent","0%",11,224,20)
    local close=create("TextButton",{Text="×",Font=Enum.Font.GothamMedium,TextSize=23,
        TextColor3=Color3.fromRGB(171,161,173),Size=UDim2.fromOffset(34,34),
        Position=UDim2.new(1,-42,0,8),BackgroundTransparency=1},card)
    local controller={Cancelled=false,Destroyed=false,Value=0}
    local connection=close.Activated:Connect(function() controller.Cancelled=true;controller:Destroy() end)
    local lastYield=os.clock()
    function controller:Yield(force)
        if force or os.clock()-lastYield>=.008 then run.RenderStepped:Wait();lastYield=os.clock() end
    end
    function controller:Update(value,text)
        if self.Destroyed then return end
        self.Value=math.max(self.Value,math.clamp(value,0,1))
        fill.Size=UDim2.fromScale(self.Value,1)
        percent.Text=tostring(math.floor(self.Value*100)).."%";status.Text=text or status.Text
        self:Yield()
    end
    function controller:Fail()
        if self.Destroyed then return end
        status.Text="No se pudo completar la carga. Cierra y vuelve a ejecutar Sterling."
        percent.Text="Carga interrumpida";status.TextColor3=Color3.fromRGB(245,139,153)
    end
    function controller:Destroy()
        if self.Destroyed then return end
        self.Destroyed=true;connection:Disconnect();gui:Destroy()
    end
    -- RenderStepped resumes before drawing; the second frame lets the first
    -- presentation actually reach the display before synchronous JSON work.
    controller:Yield(true)
    controller:Yield(true)
    return controller
end
