return function(app)
    local ui, theme, window = app.UI, app.Theme, app.Window
    local navigation = {Buttons = {}, Pages = {}, Selected = nil}
    function navigation:Show(id)
        local feature = app.Features.ById[id]
        if not feature or not self.Buttons[id] then return false end
        local page = self.Pages[id]
        if not page then
            page = ui:Create("ScrollingFrame", {
                Name = id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Active = true, Visible = false,
            }, window.Pages)
            ui:Create("UIListLayout", {Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder}, page)
            local ok, cleanup = pcall(feature.Mount, app, page)
            if not ok then page:Destroy();error(cleanup, 0) end
            if type(cleanup) == "function" then app:OnCleanup(cleanup) end
            self.Pages[id] = page
        end
        for key, value in pairs(self.Pages) do value.Visible = key == id end
        for key, button in pairs(self.Buttons) do
            button.BackgroundColor3 = key == id and theme.Selected or theme.Surface
            button.TextColor3 = key == id and theme.AccentText or theme.Muted
        end
        self.Selected = id
        window:SetTitle(feature.Title, feature.Subtitle)
        return true
    end
    function navigation:Reload(id)
        local page=self.Pages[id]
        if page then page:Destroy();self.Pages[id]=nil end
        return self:Show(id)
    end
    function navigation:Layout(compact)
        for _, button in pairs(self.Buttons) do
            button.Size = compact and UDim2.fromOffset(108, 34) or UDim2.new(1, -2, 0, 36)
        end
    end
    function navigation:Build()
        for index, feature in ipairs(app.Features.Ordered) do
            if not feature.Available or feature.Available(app) then
                local button = ui:Button(window.Nav, feature.Label or feature.Title)
                button.Name = feature.Id;button.LayoutOrder = index
                button.TextXAlignment=Enum.TextXAlignment.Left
                ui:Create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,8)},button)
                self.Buttons[feature.Id] = button
                app:Connect(button.Activated, function() self:Show(feature.Id) end)
            end
        end
        self:Layout(window.Compact)
    end
    window.OnLayout = function(compact) navigation:Layout(compact) end
    app.Navigation = navigation
    return navigation
end
