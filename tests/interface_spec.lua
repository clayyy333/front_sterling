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
task = {spawn = function(callback) callback() end, defer = function(callback) callback() end, delay=function(_,callback)callback()end, wait=function()return 0 end}
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
NumberSequence={new=function(v)return v end}
NumberSequenceKeypoint={new=function(t,v)return {Time=t,Value=v}end}
ColorSequence={new=function(v)return v end}
ColorSequenceKeypoint={new=function(t,v)return {Time=t,Value=v}end}
Color3 = {fromRGB = function(...) return {...} end}
TweenInfo={new=function(...)return {...}end}
Enum = {
    EasingStyle={Linear=1,Sine=2},EasingDirection={InOut=1},
    KeyCode = {W=1,S=2,A=3,D=4,Space=5,LeftControl=6,C=7,LeftShift=8},
    Font = {Gotham = 1, GothamBold = 2, GothamMedium = 3, Garamond=4},
    ScaleType={Crop=1}, TextXAlignment = {Left = 1,Right=2}, TextYAlignment = {Top = 1},
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
    if key == "Activated" or key == "InputBegan" or key == "DescendantAdded" or key=="Destroying" or key=="FocusLost" then
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
function object:GetDescendants()
    local result={}
    local function visit(root)
        for _, child in ipairs(root:GetChildren())do result[#result+1]=child;visit(child)end
    end
    visit(self);return result
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
function object:IsA(class)
    if class=='GuiObject'then return self.ClassName=='Frame'or self.ClassName=='ScrollingFrame'or self.ClassName=='TextButton'or self.ClassName=='TextLabel'or self.ClassName=='ImageLabel'or self.ClassName=='TextBox' end
    if class=='GuiButton'then return self.ClassName=='TextButton'or self.ClassName=='ImageButton'end
    return self.ClassName==class
end
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
local tweens={}
local tweenService={Create=function(_,object,info,goal)
    local tween={Object=object,Info=info,Goal=goal}
    function tween:Play()self.Playing=true end
    function tween:Pause()self.Playing=false;self.Paused=true end
    function tween:Cancel()self.Playing=false;self.Cancelled=true end
    tweens[#tweens+1]=tween;return tween
end}
local writes = 0
local services = {TweenService=tweenService,
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
    if relative=='modules/manifest.lua'then
        local splash=playerGui:FindFirstChild('SterlingLoading')
        local named={}
        for _,part in ipairs(splash:GetDescendants())do if part.Name then named[part.Name]=part end end
        assert(named.LowerShade.Size.Y.Scale==1 and named.LowerShade:FindFirstChildOfClass('UICorner'),'bottom shading must respect all rounded corners')
        assert(named.Brand.Position.Y.Offset>named.LoadingCard.Size.Y.Offset*(named.LoadingCard.Size.X.Offset>500 and .6 or .45),'title sits below the portrait')
        assert(named.Brand.Position.Y.Offset+named.Brand.Size.Y.Offset<named.Subtitle.Position.Y.Offset,'title/subtitle do not overlap')
        assert(named.Subtitle.Position.Y.Offset+named.Subtitle.Size.Y.Offset<named.LoadingCard.Size.Y.Offset-48,'names clear the loading footer')
        assert(not named.OuterRim and named.BrandDepth,'no perimeter outline; top/bottom light washes remain')
        assert(not named.LightBloom1 and named.TopWash and named.BottomWash,'rotating outline replaced by horizontal light washes')
        assert(named.TopWash.Position.Y.Scale==0 and named.BottomWash.Position.Y.Scale==1,'lights stay at top and bottom')
        assert(named.TopWash.BackgroundTransparency==1,'wash holder does not draw a rectangle')
        assert(#named.TopWash:GetChildren()==32,'contiguous feathering rows have no gaps or strokes')
        assert(tweens[#tweens].Playing and tweens[#tweens].Goal.Position and not tweens[#tweens].Goal.Rotation,'only horizontal motion')
    end
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
assert(app.Navigation.Selected == "home" and app.Window.Frame.AbsoluteSize.X == 760)
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
local function textButton(root,prefix)
    for _, child in ipairs(root:GetDescendants())do
        if child.ClassName=='TextButton'and type(child.Text)=='string'and child.Text:sub(1,#prefix)==prefix then return child end
    end
    error('missing button: '..prefix)
end
app.Navigation:Show('control')
local panel=app.Navigation.Pages.control
textButton(panel,'Vuelo').Activated:Fire()
local flight=app.Flows.Control.Vuelo
local baseStart,baseStop=flight.Start,flight.Stop
flight.Start=function(self)self.Flying=true;return true end
flight.Stop=function(self)self.Flying=false end
textButton(panel,'Activar vuelo').Activated:Fire()
assert(flight.Flying,'flight button calls the registered controller')
textButton(panel,'Activar vuelo').Activated:Fire();assert(not flight.Flying)
flight.Start,flight.Stop=baseStart,baseStop
textButton(panel,'Salto continuo').Activated:Fire()
textButton(panel,'Salto continuo  ').Activated:Fire()
assert(app.Flows.Control.SaltoContinuo.Enabled,'continuous jump toggle connected')
app.Flows.Control.SaltoContinuo:SetEnabled(false)
local movement=app.Flows.Movimientos
local oldEnsure,oldContext=movement.EnsureLoaded,movement.Context
local played,favorites=0,{}
local fake={Settings={showHUD=true},Emotes={{id=11,name='Saludo'},{id=12,name='Baile'}},AnimationPacks={},EmotesById={},
    IsFavorite=function(id)return favorites[id]==true end,
    ToggleFavorite=function(id)favorites[id]=not favorites[id];return favorites[id]end,
    PlayEmote=function(id)played=id end,StartCombo=function()end,StopEmote=function()end}
movement.EnsureLoaded=function()return true,fake end
app.Navigation:Reload('movimientos')
local catalog=app.Navigation.Pages.movimientos
assert(find(catalog,'CatalogGrid'),'real catalog replaces informational cards')
find(catalog,'Play').Activated:Fire();assert(played==11,'thumbnail starts selected emote')
textButton(catalog,'☆').Activated:Fire();assert(favorites[11],'favorite control wired')
local search=find(catalog,'CatalogSearch');search.Text='Baile';search:GetPropertyChangedSignal('Text'):Fire()
find(catalog,'Play').Activated:Fire();assert(played==12,'search filters playable items')
movement.EnsureLoaded,movement.Context=oldEnsure,oldContext
app.Navigation:Reload('movimientos')
for _, page in pairs(app.Navigation.Pages)do
    for _, item in ipairs(page:GetDescendants())do
        assert(not(type(item.Text)=='string'and item.Text:find('No se pudo abrir:',1,true)),item.Text)
    end
end
local lights=find(app.Window.Gui,'WindowEdgeLights')
assert(lights and not find(app.Window.Gui,'WindowShadow'),'main window uses soft top/bottom light instead of solid shadow layers')
assert(find(app.Window.Gui,'Header').BackgroundTransparency==1 and find(app.Window.Gui,'Sidebar').BackgroundTransparency==1,'header/sidebar cannot square off outer corners')
assert(find(app.Window.Gui,'BodySurface'):FindFirstChildOfClass('UICorner'),'content surface respects rounded lower corners')
app.Window.Gui:GetPropertyChangedSignal('Enabled'):Fire()
assert(lights.Visible and tweens[#tweens].Playing and tweens[#tweens].Info[1]==2.6,'main light motion uses the adjusted duration')
app.Window.Frame.Visible=false;app.Window.Frame:GetPropertyChangedSignal('Visible'):Fire()
assert(not lights.Visible and tweens[#tweens].Paused,'minimize pauses light animations')
app.Window.Frame.Visible=true;app.Window.Frame:GetPropertyChangedSignal('Visible'):Fire()
assert(lights.Visible and tweens[#tweens].Playing,'restore resumes lights')
local grip = find(app.Window.Gui, "Resize")
local pointer = {UserInputType = Enum.UserInputType.Touch, Position = v(0, 0)}
grip.InputBegan:Fire(pointer)
pointer.Position = v(-100, -50);input.InputChanged:Fire(pointer);input.InputEnded:Fire(pointer)
assert(app.Window.Frame.AbsoluteSize.X == 660 and writes == 1, "touch resizing saves only on release")
camera.ViewportSize = v(400, 700);camera:GetPropertyChangedSignal("ViewportSize"):Fire()
assert(app.Window.Compact and app.Window.Frame.AbsoluteSize.X == 376)
assert(app.Navigation.Buttons.home.Size.X.Offset == 108, "compact navigation must fit horizontally")
local first = app
app = assert(load(sources["main.lua"]))()
assert(not first.Alive and first.Window.Gui.Destroyed and app.Alive and not originalGui.Destroyed)
app:Destroy()
assert(app.Window.Gui.Destroyed and environment.SterlingApp == nil)
local count=0;for _ in pairs(renderBindings)do count=count+1 end
assert(count==3 and renderBindings.OriginalBinding and renderBindings.__WF_V3_RESTORE and renderBindings.__VR7_CONTACT_ADJUSTABLE_RESTORE,'close removes only Sterling render bindings')
for _, s in ipairs(signals) do assert(s:Count() == 0, "close/reload must disconnect every listener") end
for _,tween in ipairs(tweens)do assert(tween.Cancelled,'loader tweens must stop on close')end
print("Sterling interface OK: full local entry, lazy pages, touch resize, preference save, responsive layout, isolated reload and cleanup")
