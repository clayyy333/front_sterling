return function(app)
    local ui, theme = {}, app.Theme
    function ui:Create(class, properties, parent)
        local object = Instance.new(class)
        for key, value in pairs(properties or {}) do object[key] = value end
        if class=="UIStroke" then object.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
        if class=="TextButton"or class=="TextLabel"or class=="TextBox"then object.TextStrokeTransparency=1 end
        object.Parent = parent
        if app.Appearance then app.Appearance:Register(object,properties or {})end
        return object
    end
    function ui:Round(object, radius)
        self:Create("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, object)
        return object
    end
    function ui:Label(parent, text, size)
        return self:Create("TextLabel", {
            BackgroundTransparency = 1, Text = text, TextColor3 = theme.Text,
            TextSize = size or 14, Font = Enum.Font.Gotham, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, parent)
    end
    function ui:Button(parent, text, accent)
        local button = self:Round(self:Create("TextButton", {
            Text = text, TextSize = 13, Font = Enum.Font.GothamMedium,
            TextColor3 = accent and theme.AccentText or theme.Text,
            BackgroundColor3 = accent and theme.Accent or theme.Raised,
            BorderSizePixel = 0, AutoButtonColor = true, Active = true,
        }, parent), 9)
        return button
    end
    function ui:Section(parent, title, subtitle)
        local card = self:Round(self:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 136), BackgroundColor3 = theme.Surface, BorderSizePixel = 0,
        }, parent), 12)
        self:Create("UIStroke", {Color=theme.Line, Thickness=1, Transparency=.5}, card)
        local heading = self:Label(card, title, 18)
        heading.Font = Enum.Font.GothamMedium;heading.Position = UDim2.fromOffset(20, 18)
        heading.Size = UDim2.new(1, -40, 0, 28)
        local detail = self:Label(card, subtitle, 13)
        detail.TextColor3 = theme.Muted;detail.TextYAlignment = Enum.TextYAlignment.Top
        detail.Position = UDim2.fromOffset(20, 56);detail.Size = UDim2.new(1, -40, 0, 60)
        return card
    end
    app.UI = ui
    return ui
end
