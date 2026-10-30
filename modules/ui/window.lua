return function(app)
    local ui, theme, input = app.UI, app.Theme, app.Services.UserInputService
    local gui = ui:Create("ScreenGui", {
        Name = app.Config.GuiName, ResetOnSpawn = false, DisplayOrder = 60, Enabled = not app.Loading,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, app.PlayerGui)
    app:OnCleanup(function() gui:Destroy() end)
    local window = ui:Round(ui:Create("Frame", {
        Name = "Window", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
        BackgroundColor3 = theme.Background, BorderSizePixel = 0, ClipsDescendants = true,
    }, gui), 16)
    ui:Create("UIStroke", {Color = theme.Line, Thickness = 1}, window)
    -- Soft, static shadow layers: no texture download or animation loop.
    local shadows = {}
    for index = 3, 1, -1 do
        shadows[#shadows+1] = ui:Round(ui:Create("Frame", {
            Name="WindowShadow", AnchorPoint=Vector2.new(.5,.5), BorderSizePixel=0,
            BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=.89+index*.02,
            ZIndex=1,
        }, gui),16+index*4)
    end
    window.ZIndex=2
    local function updateShadows()
        for index, shadow in ipairs(shadows) do
            local spread=(4-index)*8
            shadow.Position=UDim2.new(window.Position.X.Scale,window.Position.X.Offset,
                window.Position.Y.Scale,window.Position.Y.Offset+5)
            shadow.Size=UDim2.new(window.Size.X.Scale,window.Size.X.Offset+spread,
                window.Size.Y.Scale,window.Size.Y.Offset+spread)
            shadow.Visible=window.Visible
        end
    end
    app:Connect(window:GetPropertyChangedSignal("Position"),updateShadows)
    app:Connect(window:GetPropertyChangedSignal("Size"),updateShadows)
    app:Connect(window:GetPropertyChangedSignal("Visible"),updateShadows)
    local header = ui:Create("Frame", {
        Name = "Header", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0, Active = true,
    }, window)
    local monogram = ui:Button(header, "S", true)
    monogram.Size = UDim2.fromOffset(30, 30);monogram.Position = UDim2.fromOffset(14, 12)
    monogram.Active = false;monogram.AutoButtonColor = false
    local name = ui:Label(header, app.Config.Name, 14)
    name.Font = Enum.Font.GothamBold;name.Position = UDim2.fromOffset(56, 11);name.Size = UDim2.new(1, -170, 0, 30)
    local minimize = ui:Button(header, "—")
    minimize.Position = UDim2.new(1, -88, 0, 11);minimize.Size = UDim2.fromOffset(32, 32)
    local close = ui:Button(header, "×")
    close.TextSize = 23;close.Position = UDim2.new(1, -48, 0, 11);close.Size = UDim2.fromOffset(32, 32)
    local sidebar = ui:Create("Frame", {Name = "Sidebar", BackgroundColor3 = theme.Surface, BorderSizePixel = 0}, window)
    local navigation = ui:Create("ScrollingFrame", {
        Name = "Navigation", BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Active = true,
    }, sidebar)
    local navLayout = ui:Create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, navigation)
    local body = ui:Create("Frame", {Name = "Content", BackgroundTransparency = 1}, window)
    local heading = ui:Label(body, "", 20)
    heading.Font = Enum.Font.GothamBold;heading.Size = UDim2.new(1, 0, 0, 34)
    local subtitle = ui:Label(body, "", 12)
    subtitle.Position = UDim2.fromOffset(0, 30);subtitle.Size = UDim2.new(1, 0, 0, 22);subtitle.TextColor3 = theme.Muted
    local pages = ui:Create("Frame", {
        Name = "Pages", Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -58), BackgroundTransparency = 1,
    }, body)
    local grip = ui:Create("TextButton", {
        Name = "Resize", Text = "◢", TextSize = 16, TextColor3 = theme.Muted,
        BackgroundTransparency = 1, Position = UDim2.new(1, -26, 1, -26), Size = UDim2.fromOffset(24, 24), ZIndex = 20,
    }, window)
    local launcher = ui:Button(gui, "S", true)
    launcher.Name = "Launcher";launcher.Size = UDim2.fromOffset(44, 44)
    launcher.Position = UDim2.new(0, 16, .5, -22);launcher.Visible = false;launcher.ZIndex = 30
    local controller = {Gui = gui, Frame = window, Nav = navigation, Pages = pages, Compact = false}
    app.Window = controller
    local width, height
    local function viewport()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(960, 640)
    end
    function controller:Layout(w, h)
        local view = viewport()
        width = math.clamp(w, math.min(320, view.X - 24), math.max(1, view.X - 24))
        height = math.clamp(h, math.min(260, view.Y - 48), math.max(1, view.Y - 48))
        window.Size = UDim2.fromOffset(width, height)
        self.Compact = width < 620
        if self.Compact then
            sidebar.Position = UDim2.fromOffset(0, 48);sidebar.Size = UDim2.new(1, 0, 0, 52)
            navigation.Position = UDim2.fromOffset(12, 6);navigation.Size = UDim2.new(1, -24, 1, -12)
            navigation.AutomaticCanvasSize = Enum.AutomaticSize.X;navigation.ScrollingDirection = Enum.ScrollingDirection.X
            navLayout.FillDirection = Enum.FillDirection.Horizontal
            body.Position = UDim2.fromOffset(14, 106);body.Size = UDim2.new(1, -28, 1, -126)
            heading.TextSize = 19
        else
            sidebar.Position = UDim2.fromOffset(0, 48);sidebar.Size = UDim2.new(0, 152, 1, -48)
            navigation.Position = UDim2.fromOffset(12, 20);navigation.Size = UDim2.new(1, -24, 1, -40)
            navigation.AutomaticCanvasSize = Enum.AutomaticSize.Y;navigation.ScrollingDirection = Enum.ScrollingDirection.Y
            navLayout.FillDirection = Enum.FillDirection.Vertical
            body.Position = UDim2.fromOffset(174, 64);body.Size = UDim2.new(1, -194, 1, -84)
            heading.TextSize = 19
        end
        if self.OnLayout then self.OnLayout(self.Compact) end
    end
    function controller:Center() window.Position = UDim2.fromScale(.5, .5) end
    function controller:SetTitle(title, detail)
        local hasTitle=title~=nil and title~=""
        heading.Text=title or "";heading.Visible=hasTitle
        subtitle.Text=detail or ""
        subtitle.Position=UDim2.fromOffset(0,hasTitle and 30 or 0)
        subtitle.TextSize=hasTitle and 12 or 14
        subtitle.TextColor3=hasTitle and theme.Muted or theme.Text
        local offset=hasTitle and 58 or 38
        pages.Position=UDim2.fromOffset(0,offset);pages.Size=UDim2.new(1,0,1,-offset)
    end
    function controller:ResetSize()
        self:Layout(app.Config.Width, app.Config.Height);self:Center()
        app.Storage.Values.Width = width;app.Storage.Values.Height = height;app.Storage:Save()
    end
    local gesture
    local function pointer(event)
        return event.UserInputType == Enum.UserInputType.MouseButton1 or event.UserInputType == Enum.UserInputType.Touch
    end
    app:Connect(header.InputBegan, function(event)
        if not pointer(event) or event.Position.X > header.AbsolutePosition.X + header.AbsoluteSize.X - 96 then return end
        gesture = {Kind = "drag", Input = event, Start = event.Position, Position = window.Position}
    end)
    app:Connect(grip.InputBegan, function(event)
        if pointer(event) then gesture = {Kind = "resize", Input = event, Start = event.Position, Width = width, Height = height} end
    end)
    app:Connect(input.InputChanged, function(event)
        if not gesture or not(event == gesture.Input or event.UserInputType == Enum.UserInputType.MouseMovement) then return end
        local delta = event.Position - gesture.Start
        if gesture.Kind == "resize" then
            controller:Layout(gesture.Width + delta.X, gesture.Height + delta.Y)
        else
            local view = viewport()
            local position = gesture.Position
            local x = position.X.Scale * view.X + position.X.Offset + delta.X
            local y = position.Y.Scale * view.Y + position.Y.Offset + delta.Y
            window.Position = UDim2.fromOffset(math.clamp(x, width / 2, view.X - width / 2), math.clamp(y, height / 2, view.Y - height / 2))
        end
    end)
    app:Connect(input.InputEnded, function(event)
        if not gesture or event ~= gesture.Input then return end
        if gesture.Kind == "resize" then
            app.Storage.Values.Width = width;app.Storage.Values.Height = height;app.Storage:Save()
        end
        gesture = nil
    end)
    app:Connect(minimize.Activated, function() gesture = nil;window.Visible = false;launcher.Visible = true end)
    app:Connect(launcher.Activated, function() window.Visible = true;launcher.Visible = false end)
    app:Connect(close.Activated, function() app:Destroy() end)
    local cameraConnection
    local function bindCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection = nil end
        if workspace.CurrentCamera then
            cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                controller:Layout(width, height);controller:Center()
            end)
        end
        controller:Layout(width or app.Storage.Values.Width, height or app.Storage.Values.Height)
    end
    app:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)
    app:OnCleanup(function() if cameraConnection then cameraConnection:Disconnect() end end)
    bindCamera()
    updateShadows()
    app.Legacy.gui=gui
    return controller
end
