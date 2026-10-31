local source=...
local pending={}
task={defer=function(fn)pending[#pending+1]=fn end}
local function flush()
    while #pending>0 do table.remove(pending,1)()end
end
local function signal()
    local handlers={};local event={}
    function event:Connect(fn)
        local link={Active=true};function link:Disconnect()self.Active=false end
        handlers[#handlers+1]={link,fn};return link
    end
    function event:Fire(value)for _,item in ipairs(handlers)do if item[1].Active then item[2](value)end end end
    function event:Count()local n=0;for _,item in ipairs(handlers)do if item[1].Active then n=n+1 end end;return n end
    return event
end
local function makeApp(character)
    local cleanups={}
    local app={Alive=true,Flows={},Player={Character=character,CharacterAdded=signal()}}
    function app:OnCleanup(fn)cleanups[#cleanups+1]=fn end
    function app:Destroy()self.Alive=false;for _,fn in ipairs(cleanups)do fn()end end
    assert(load(source))()(app)
    local movement=app.Flows.Movimientos
    local calls=0
    movement.EnsureLoaded=function(self)calls=calls+1;self.Loaded=true;return true,{}end
    return app,movement,function()return calls end
end
local ready={FindFirstChildOfClass=function()return {}end}
local app,movement,calls=makeApp(ready)
movement:RestoreOnOpen();assert(calls()==0,'startup restoration never blocks the opening call')
flush();assert(calls()==1 and movement.Loaded,'saved animation engine initializes without opening Movimientos')
movement:RestoreOnOpen();app.Player.CharacterAdded:Fire(ready);flush()
assert(calls()==1 and app.Player.CharacterAdded:Count()==1,'startup initialization is not duplicated')
app:Destroy();assert(app.Player.CharacterAdded:Count()==0,'startup observer is disconnected on close')
app,movement,calls=makeApp(nil)
movement:RestoreOnOpen();flush();assert(calls()==0,'wait for an available character')
local delayed={FindFirstChildOfClass=function()return nil end}
function delayed:WaitForChild(name,timeout)assert(name=='Humanoid'and timeout==10);return {}end
app.Player.Character=delayed;app.Player.CharacterAdded:Fire(delayed);flush();assert(calls()==1,'late humanoid initializes and restores')
app:Destroy()
app,movement,calls=makeApp(ready)
movement:RestoreOnOpen();app:Destroy();flush();assert(calls()==0,'pending work cannot restore after GUI close')
print('Sterling animation startup restore OK: background initialization, delayed character, deduplication and cleanup')
