return function(app)
    app.Navigation:Build()
    if not app.Navigation:Show(app.Config.DefaultPage) then
        local first = app.Features.Ordered[1]
        assert(first and app.Navigation:Show(first.Id), "Sterling: no available page")
    end
    return true
end
