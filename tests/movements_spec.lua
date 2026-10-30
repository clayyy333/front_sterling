local sources = ...
loadstring = load
getfenv = function() return _G end
setfenv = function(_, context) debug.setupvalue(debug.getinfo(2, "f").func, 1, context) end
math.clamp = function(n, low, high) return math.max(low, math.min(high, n)) end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
Enum = {HumanoidRigType={R6=6,R15=15}}
local signals = {}
local function signal()
    local s = {connections={}}
    function s:Connect(callback)
        local c = {callback=callback}
        function c:Disconnect() self.callback=nil end
        self.connections[#self.connections+1]=c
        return c
    end
    function s:Fire(...)
        for _, c in ipairs(self.connections) do if c.callback then c.callback(...) end end
    end
    signals[#signals+1]=s
    return s
end
local runtime = {}
local humanoid = {RigType=15}
local character = {FindFirstChildOfClass=function() return humanoid end, WaitForChild=function() return humanoid end}
local player = {UserId=1,Character=character,CharacterAdded=signal(),CharacterRemoving=signal()}
local input = {InputBegan=signal(),GetFocusedTextBox=function()return nil end}
local players = {PlayerRemoving=signal()}
local run = {Heartbeat=signal()}
game = {GetService=function()return {}end}
Instance = {new=function()
    local folder = {Destroying=signal()}
    function folder:Destroy() self.Destroying:Fire();self.Parent=nil end
    return folder
end}
task = {defer=function(fn)fn()end,spawn=function(fn)fn()end}
local writes, reads = 0, 0
writefile = function(path) assert(path=='SterlingMovements_Data_1.json');writes=writes+1 end
local cleanups = {}
local app = {
    StartupCatalogs={
        ['data/emotes']={Raw='prepared-emotes',Decoded={data={{id=1,name='Emote'},{id=1,name='Duplicate'}}}},
        ['data/animations']={Raw='prepared-animations',Decoded={data={{id=2,name='Pack',bundledItems={}}}}},
    },
    Alive=true, Player=player, PlayerGui={}, Flows={},
    Services={UserInputService=input,HttpService={
        JSONDecode=function(_, value)
            assert(value~='prepared-emotes' and value~='prepared-animations','prepared catalogs must not be decoded twice')
            if value:find('"bundledItems"',1,true) then return {data={{id=2,name='Pack',bundledItems={}}}} end
            return {data={{id=1,name='Emote'},{id=1,name='Duplicate'}}}
        end,
        JSONEncode=function()return '{}'end,
    }},
    Legacy=setmetatable({player=player,Players=players,RunService=run,UserInputService=input,
        _genv=function()return runtime end,print=function()end}, {__index=_G}),
    ReadSource=function(path) assert(not path:find("/data/",1,true),"prepared catalogs must not be fetched twice");reads=reads+1;return assert(sources[path]) end,
    OnCleanup=function(_, fn) cleanups[#cleanups+1]=fn end,
}
local package = assert(load(sources['modules/adapters/movements.lua']))()(app)
assert(package.CatalogsReady and not package.Loaded and reads==0, 'no startup catalog load')
humanoid.RigType=6
assert(not package:EnsureLoaded() and reads==0, 'R6 rejection leaves GUI and sources alone')
humanoid.RigType=15
local ok, context = package:EnsureLoaded()
assert(ok, context)
assert(#context.Emotes==1 and #context.AnimationPacks==1, 'original loaders and deduplication')
assert(context.EmotesById[1].name=='Emote')
assert(context.ToggleFavorite(1) and context.IsFavorite(1))
context.AddToRecent(1);assert(context.RecentEmotes[1]==1 and writes==2)
context.SetKeybind(1,'Emote','K')
assert(context.GetKeybind(1).key=='K')
local played
context.PlayEmote=function(id)played=id end
input.InputBegan:Fire({KeyCode={Name='K'}},false)
assert(played==1,'keyboard uses copied keybind storage')
local loadedReads=reads
assert(package:EnsureLoaded() and reads==loadedReads,'loaded once')
app.Alive=false
for index=#cleanups,1,-1 do cleanups[index]() end
assert(not package.Loaded and not package:EnsureLoaded())
for _, s in ipairs(signals) do
    for _, c in ipairs(s.connections) do assert(not c.callback,'movement listeners released') end
end
print('Sterling movements OK: lazy load, R15 guard, original catalog/state engines, favorites, recent, keybinds and cleanup')
