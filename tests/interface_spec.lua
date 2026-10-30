local sources = ...
loadstring = load
getfenv = function() return _G end
setfenv = function(_, context) debug.setupvalue(debug.getinfo(2, "f").func, 1, context) end
table.clear = table.clear or function(t) for key in pairs(t) do t[key] = nil end end
local vector3 = {};vector3.__index = function(a, key)
    if key == "Magnitude" then return math.sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) end
end
Vector3 = {new = function(x, y, z) return setmetatable({X=x,Y=y,Z=z}, vector3) end}
Vector3.zero = Vector3.new(0, 0, 0)
task = {spawn = function(callback) callback() end, defer = function(callback) callback() end}
local signals = {}
local function signal()
    local callbacks = {}
    local s = {}
    function s:Connect(callback)
        local connection = {Callback = callback}
        function connection:Disconnect() self.Callback = nil end
        callbacks[#callbacks + 1] = connection
        return connection
    end
    function s:Fire(...)
        for _, connection in ipairs(callbacks) do if connection.Callback then connection.Callback(...) end end
    end
    function s:Wait() return 1/60 end
    function s:Count()
        local total = 0
        for _, connection in ipairs(callbacks) do if connection.Callback then total = total + 1 end end
        return total
    end
    signals[#signals + 1] = s
    return s
end
local vector = {};vector.__index = vector
local function v(x, y) return setmetatable({X = x, Y = y}, vector) end
vector.__sub = function(a, b) return v(a.X - b.X, a.Y - b.Y) end
Vector2 = {new = v}
UDim = {new = function(scale, offset) return {Scale = scale, Offset = offset} end}
UDim2 = {new = function(xs, xo, ys, yo) return {X = UDim.new(xs, xo), Y = UDim.new(ys, yo)} end}
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
math.clamp = function(n, low, high) return math.max(low, math.min(high, n)) end
Color3 = {fromRGB = function(...) return {...} end}
Enum = {
    KeyCode = {W=1,S=2,A=3,D=4,Space=5,LeftControl=6,C=7,LeftShift=8},
    Font = {Gotham = 1, GothamBold = 2, GothamMedium = 3},
    TextXAlignment = {Left = 1}, TextYAlignment = {Top = 1},
    AutomaticSize = {X = 1, Y = 2}, SortOrder = {LayoutOrder = 1},
    ZIndexBehavior = {Sibling = 1}, ScrollingDirection = {X = 1, Y = 2},
    FillDirection = {Horizontal = 1, Vertical = 2},
    UserInputType = {MouseButton1 = 1, Touch = 2, MouseMovement = 3},
}
local object = {}
local function new(class)
    return setmetatable({_values = {ClassName = class, Visible = true}, _children = {}, _signals = {}}, object)
end
function object.__index(self, key)
    if object[key] then return object[key] end
    if key == "AbsoluteSize" then
        if self.ClassName == "ScreenGui" or self.ClassName == "PlayerGui" then return workspace.CurrentCamera.ViewportSize end
        local parent = self.Parent and self.Parent.AbsoluteSize or v(0, 0)
        local size = self.Size or UDim2.fromOffset(0, 0)
        return v(size.X.Scale * parent.X + size.X.Offset, size.Y.Scale * parent.Y + size.Y.Offset)
    end
    if key == "AbsolutePosition" then return v(0, 0) end
    if key == "Activated" or key == "InputBegan" or key == "DescendantAdded" then
        if not self._signals[key] then self._signals[key] = signal() end
        return self._signals[key]
    end
    return self._values[key]
end
function object.__newindex(self, key, value)
    self._values[key] = value
    if key == "Parent" and value then value._children[#value._children + 1] = self end
end
function object:GetPropertyChangedSignal(name)
    if not self._signals[name] then self._signals[name] = signal() end
    return self._signals[name]
end
function object:GetChildren()
    local result = {}
    for _, child in ipairs(self._children) do if child.Parent == self then result[#result + 1] = child end end
    return result
end
function object:FindFirstChild(name)
    for _, child in ipairs(self:GetChildren()) do if child.Name == name then return child end end
end
function object:FindFirstChildOfClass(class)
    for _, child in ipairs(self:GetChildren()) do if child.ClassName == class then return child end end
end
function object:IsA(class) return self.ClassName == class end
typeof = function(value) return type(value) == 'table' and value.ClassName and 'Instance' or type(value) end
function object:Destroy()
    for _, child in ipairs(self:GetChildren()) do child:Destroy() end
    self.Parent = nil;self.Destroyed = true
end
Instance = {new = new}
local playerGui = new("PlayerGui")
local originalGui = new("ScreenGui");originalGui.Parent = playerGui
local camera = new("Camera");camera.ViewportSize = v(1280, 800)
workspace = new("Workspace");workspace.CurrentCamera = camera
local input = {InputChanged = signal(), InputEnded = signal(), InputBegan=signal(), TouchStarted=signal(), TouchMoved=signal(), TouchEnded=signal()}
local player = {Name="Tester", UserId=1, DisplayName = "Tester", CharacterAdded=signal(), WaitForChild = function() return playerGui end}
local runService = {Heartbeat=signal(),RenderStepped=signal(),Stepped=signal(),PostSimulation=signal()}
local renderBindings = {OriginalBinding=function()end,__WF_V3_RESTORE=function()end,__VR7_CONTACT_ADJUSTABLE_RESTORE=function()end}
function runService:BindToRenderStep(name, _, callback) renderBindings[name] = callback end
function runService:UnbindFromRenderStep(name) renderBindings[name] = nil end
local writes = 0
local services = {
    Players = {LocalPlayer = player, PlayerRemoving=signal()}, UserInputService = input, RunService=runService,Workspace=workspace,
    HttpService = {JSONDecode = function(_, value)
        if value:find('"bundledItems"',1,true) then return {data={{id=2,name='Pack',bundledItems={}}}} end
        if value:find('"keyword"',1,true) then return {data={{id=1,name='Emote'}}} end
        error("no saved file")
    end, JSONEncode = function() return "preferences" end},
}
game = {GetService = function(_, name) return services[name] end}
local environment = {SterlingSource = {LocalRoot = "front_sterling"}}
environment.__VR7_CONTACT_ADJUSTABLE_CLEANUP=function()error('original GUI must remain untouched')end
environment.__VR7_CONTACT_FLING_CLEANUP=environment.__VR7_CONTACT_ADJUSTABLE_CLEANUP
getgenv = function() return environment end
readfile = function(path)
    local relative = path:gsub("^front_sterling/", "")
    assert(sources[relative], "not found: " .. path)
    return sources[relative]
end
writefile = function(path) assert(path == "sterling_preferences_v1.json");writes = writes + 1 end
local app = assert(load(sources["main.lua"]))()
assert(app.Window.Gui.Enabled and not app.Loading and not playerGui:FindFirstChild('SterlingLoading'))
assert(app.Flows.Movimientos.CatalogsReady and app.StartupCatalogs['data/emotes'].Decoded.data[1].name=='Emote')
assert(app.Flows.Movimientos and not app.Flows.Movimientos.Loaded, "movement playback stays dormant during startup")
assert(app.Navigation:Show("movimientos") and not app.Flows.Movimientos.Loaded, "layout preview does not load catalogs")
app.Navigation:Show("home")
assert(app.Flows.Control.PerspectivaCamara == app.Legacy.SpectatorController and not app.Flows.Control.PerspectivaCamara:IsActive())
assert(app.Flows.Control.Vuelo == app.Legacy.FlightController and not app.Flows.Control.Vuelo:IsFlying())
assert(app.Flows.Control.Velocidad == app.Legacy.MovementControlController and not app.Flows.Control.Velocidad.WalkSpeedEnabled)
assert(app.Navigation.Selected == "home" and app.Window.Frame.AbsoluteSize.X == 860)
assert(app.Flows.Volar.SinObjetivo==app.Legacy.Fling2AutoController and app.Flows.Volar.EficienteCorto:IsShortDisplacementEnabled())
assert(app.Flows.Volar.PorContacto==app.Legacy.AdjustableContactFlingController and app.Flows.Ancla.Normal==app.Legacy.AnchorCore)
assert(app.Flows.Volar.ConVehiculos2.Delta==app.Legacy.CarFling2Delta and app.Flows.Volar.ConVehiculos2.Xeno==app.Legacy.CarFling2Xeno)
assert(app.Flows.Volar.ConVehiculos2.Automatico.Mode==nil,'vehicle automation starts disabled')
assert(app.Flows.Ancla.Test==app.Legacy.StaticNoclipAnchorCore and not app.Flows.Ancla.Test.Running,'complete Test anchor registered but inactive')
assert(not app.Flows.Ancla.Test.ConstantReturn and app.Flows.Ancla.Test:SetConstantReturn(true),'companion setting accessible')
app.Flows.Ancla.Test:SetConstantReturn(false)
assert(app.Flows.Ancla.MueveteV13==app.Legacy.MobileAnchorV13Core and app.Flows.Ancla.MueveteV13.Version=='1.3'and not app.Flows.Ancla.MueveteV13.Running)
assert(app.Legacy.MobileAnchorCore==nil and app.Legacy.MobileAnchorV11Core==nil,'only mobile version 1.3 loaded')
assert(not app.Flows.Volar.SinObjetivo.Running and not app.Flows.Volar.PorContacto.Running and not app.Flows.Ancla.Normal.AnclaEnabled,'loading never starts a flow')
local targetPlayer = new('Player')
assert(app.Flows.Volar.EficienteCorto:SetTarget(targetPlayer) and app.Flows.Volar.EficienteCorto:GetTarget()==targetPlayer,'copied provider dependencies resolve target players')
local testCharacter = new('Model')
local testRoot = new('Part');testRoot.Name='HumanoidRootPart';testRoot.Parent=testCharacter
local walking = Vector3.new(16,0,0)
testRoot.Velocity=walking;testRoot.AssemblyLinearVelocity=walking;testRoot.CanCollide=true
player.Character=testCharacter
assert(app.Flows.Volar.PorContacto:Start())
runService.PostSimulation:Fire()
assert(testRoot.Velocity.X==100000,'copied contact emits its original pulse through Sterling context')
renderBindings['Sterling::__VR7_CONTACT_ADJUSTABLE_RESTORE']()
assert(testRoot.Velocity==walking,'scoped render binding restores the original walking speed')
app.Flows.Volar.PorContacto:Stop();assert(testRoot.CanCollide)
player.Character=nil
assert(renderBindings['Sterling::__WF_V3_RESTORE']and renderBindings['Sterling::__VR7_CONTACT_ADJUSTABLE_RESTORE']and renderBindings.OriginalBinding,'render bindings isolated from original GUI')
assert(app.Navigation:Show('volar')and app.Navigation:Show('ancla'),'both requested sections mounted')
assert(not app.Navigation.Pages.interface, "pages should mount lazily")
assert(app.Navigation:Show("interface") and app.Navigation.Pages.interface)
local function find(parent, name)
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then return child end
        local nested = find(child, name);if nested then return nested end
    end
end
local grip = find(app.Window.Gui, "Resize")
local pointer = {UserInputType = Enum.UserInputType.Touch, Position = v(0, 0)}
grip.InputBegan:Fire(pointer)
pointer.Position = v(-100, -50);input.InputChanged:Fire(pointer);input.InputEnded:Fire(pointer)
assert(app.Window.Frame.AbsoluteSize.X == 760 and writes == 1, "touch resizing saves only on release")
camera.ViewportSize = v(400, 700);camera:GetPropertyChangedSignal("ViewportSize"):Fire()
assert(app.Window.Compact and app.Window.Frame.AbsoluteSize.X == 376)
assert(app.Navigation.Buttons.home.Size.X.Offset == 124, "compact navigation must fit horizontally")
local first = app
app = assert(load(sources["main.lua"]))()
assert(not first.Alive and first.Window.Gui.Destroyed and app.Alive and not originalGui.Destroyed)
app:Destroy()
assert(app.Window.Gui.Destroyed and environment.SterlingApp == nil)
local count=0;for _ in pairs(renderBindings)do count=count+1 end
assert(count==3 and renderBindings.OriginalBinding and renderBindings.__WF_V3_RESTORE and renderBindings.__VR7_CONTACT_ADJUSTABLE_RESTORE,'close removes only Sterling render bindings')
for _, s in ipairs(signals) do assert(s:Count() == 0, "close/reload must disconnect every listener") end
print("Sterling interface OK: full local entry, lazy pages, touch resize, preference save, responsive layout, isolated reload and cleanup")
