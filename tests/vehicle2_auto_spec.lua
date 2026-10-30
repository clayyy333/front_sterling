local source=...
local callbacks, cleanups={},{}
local app={Alive=true,Flows={Volar={ConVehiculos2={}}},Legacy={}}
function app:OnCleanup(f)cleanups[#cleanups+1]=f end
function app:Connect(_,f)callbacks[#callbacks+1]=f end
local cars={}
local function engine()
    local e={Running=false,Starts=0}
    function e:SetCar(value)self.Car=value end
    function e:SetPlayer(value)self.Player=value end
    function e:GetCar()return self.Car end
    function e:GetPlayer()return self.Player end
    function e:GetCarOptions()return cars end
    function e:Start()self.Starts=self.Starts+1;self.Running=true;return true end
    return e
end
local delta,xeno=engine(),engine()
app.Legacy={CarFling2Delta=delta,CarFling2Xeno=xeno,RunService={Heartbeat={}},UpdateCarFling2Panel=function()end}
task={defer=function(f)f()end}
local auto=assert(load(source))()(app)
assert(auto.Mode==nil and delta.Starts==0 and xeno.Starts==0)
assert(not auto:SetMode('invalid'))
local target={};auto:SetPlayer(target);auto:SetMode('Delta')
assert(delta.Starts==0,'must wait for own spawned vehicle')
cars={{Name='first'}};callbacks[1](.25)
assert(delta.Starts==1 and delta.Car==cars[1]and xeno.Car==cars[1]and delta.Player==target,'automatic own-vehicle selection starts requested engine')
local nextCar={Name='next'};cars={nextCar};callbacks[1](.25)
assert(delta.Car~=nextCar,'active engine keeps its source selection')
delta.Running=false;callbacks[1](.25)
assert(delta.Car==nextCar and delta.Starts==2,'new spawn detected once previous engine stops')
delta.Running=false;auto:SetMode('Xeno')
assert(xeno.Starts==1,'Xeno uses its own copied engine')
app.Alive=false;for _,f in ipairs(cleanups)do f()end
assert(auto.Mode==nil and auto:TryStart()==nil,'closing disables automatic activation')
print('Sterling vehicles 2 automatic OK: dormant loading, spawn selection, engine choice, active source retention and cleanup')
