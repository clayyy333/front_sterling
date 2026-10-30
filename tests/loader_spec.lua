local loaderSource, lifecycleSource, featuresSource = ...
loadstring = load
local loader = assert(load(loaderSource))()
local function manifest(features)
    return 'return {version=1,core={"core/lifecycle","core/features"},features={' .. features .. '},start="core/start"}'
end
local sources = {
    ["modules/ui/loading.lua"] = [[return function(env)
        local s={Cancelled=false,Destroyed=false,Value=0,Updates={}}
        function s:Update(value,text)
            assert(value>=self.Value);self.Value=value;self.Updates[#self.Updates+1]=text
            if env.CancelAt and text==env.CancelAt then self.Cancelled=true end
        end
        function s:Yield() end
        function s:Fail() self.Failed=true end
        function s:Destroy() self.Destroyed=true end
        env.LastSplash=s
        return s
    end]],
    ["modules/manifest.lua"] = manifest('"features/example"'),
    ["modules/core/lifecycle.lua"] = lifecycleSource,
    ["modules/core/features.lua"] = featuresSource,
    ["modules/features/example.lua"] = [[return function(app)
        app.Features:Register({Id="example",Mount=function()end})
        app:OnCleanup(function()app.Cleaned=true end)
        return {Independent=true}
    end]],
    ["modules/core/start.lua"] = [[return function(app)
        assert(app.Features.ById.example)
        app.Started=true
        return true
    end]],
}
local function read(path) assert(sources[path], path);return sources[path] end
local untouched = 0
local environment = {VexroEmotesCleanup = function() untouched = untouched + 1 end}
local app = loader(read, environment)
assert(environment.LastSplash.Destroyed and environment.LastSplash.Value==1)
assert(app.Started and app.Alive and app.Modules["features/example"].Independent)
assert(environment.SterlingApp == app and untouched == 0, "old GUI cleanup must never be invoked")
local disconnected = 0
local callback
app:Connect({Connect = function(_, fn)
    callback = fn
    return {Disconnect = function() disconnected = disconnected + 1 end}
end}, function() app.Observed = true end)
callback();assert(app.Observed)
sources["modules/features/example.lua"] = "syntax error ???"
assert(not pcall(loader, read, environment))
assert(app.Alive and environment.SterlingApp == app, "bad new source must preserve running instance")
sources["modules/features/example.lua"] = [[return function(app)
    app.Features:Register({Id="example",Mount=function()end})
    return true
end]]
local replacement = loader(read, environment)
assert(not app.Alive and app.Cleaned and disconnected == 1 and replacement.Alive)
app.Observed = false;callback();assert(not app.Observed, "closed instance callbacks must be inert")
assert(environment.SterlingApp == replacement and untouched == 0)
sources["modules/manifest.lua"] = manifest('"features/example","features/example"')
assert(not pcall(loader, read, environment) and replacement.Alive, "duplicate modules rejected before shutdown")
sources["modules/manifest.lua"] = manifest('"features/example"')
sources["modules/core/start.lua"] = [[return function(app)
    app:OnCleanup(function()app.Environment.FailedCleaned=true end)
    error("startup failure")
end]]
assert(not pcall(loader, read, environment) and environment.FailedCleaned and environment.SterlingApp == nil, "partial startup cleans up")
local failedSplash=environment.LastSplash
assert(failedSplash.Failed and failedSplash.Value<1)
sources['modules/core/start.lua']='return function(app) app.Started=true end'
local baseManifest=manifest('"features/example"')
sources['modules/manifest.lua']=baseManifest:gsub('version=1,',[[version=1,startupCatalogs={
    {id='data/emotes',path='modules/data/emotes.lua',label='EMOTES'},
    {id='data/animations',path='modules/data/animations.lua',label='ANIMATIONS'}},]])
sources['modules/data/emotes.lua']="return 'emotes'"
sources['modules/data/animations.lua']="return 'animations'"
local decoded={}
game={GetService=function()return {JSONDecode=function(_,raw)decoded[#decoded+1]=raw;return {data={}}end}end}
local order={}
local function stagedRead(path)
    order[#order+1]=path
    if path=='modules/data/emotes.lua' then assert(environment.LastSplash and not environment.LastSplash.Destroyed) end
    return read(path)
end
app=loader(stagedRead,environment)
assert(failedSplash.Destroyed and decoded[1]=='emotes' and decoded[2]=='animations')
assert(order[1]=='modules/ui/loading.lua' and order[2]=='modules/manifest.lua' and order[3]=='modules/data/emotes.lua' and order[4]=='modules/data/animations.lua')
assert(app.StartupCatalogs['data/emotes'].Raw=='emotes' and environment.LastSplash.Value==1)
environment.CancelAt='EMOTES'
assert(not pcall(loader,stagedRead,environment) and app.Alive,'cancelled preparation preserves previous instance')
assert(environment.LastSplash.Destroyed and environment.LastSplash.Value<1)
environment.CancelAt=nil
app:Destroy()
print("Sterling loader OK: isolated context, registration, atomic compilation, reload, disconnects and failed startup cleanup")
