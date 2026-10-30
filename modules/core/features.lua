return function(app)
    local features = {ById = {}, Ordered = {}}
    function features:Register(definition)
        assert(type(definition) == "table" and type(definition.Id) == "string", "Sterling: feature needs an Id")
        assert(not self.ById[definition.Id], "Sterling: duplicate feature " .. definition.Id)
        assert(type(definition.Mount) == "function", "Sterling: feature needs a Mount function")
        self.ById[definition.Id] = definition
        self.Ordered[#self.Ordered + 1] = definition
    end
    app.Features = features
    return features
end
