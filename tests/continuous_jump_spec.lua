local source=...
local connections={}
local function signal()
    local s={}
    function s:Connect(fn)
        local c={fn=fn};function c:Disconnect()self.fn=nil end
        connections[#connections+1]=c
        self[#self+1]=c;return c
    end
    function s:Fire(...)for _,c in ipairs(self)do if c.fn then c.fn(...)end end end
    return s
end
Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end}
Enum={KeyCode={Space=1},UserInputType={Touch=2,MouseButton1=3}}
math.clamp=function(n,a,b)return math.max(a,math.min(b,n))end
local input={InputBegan=signal(),InputEnded=signal(),WindowFocusReleased=signal(),GetFocusedTextBox=function()end}
local step=signal()
local root={Parent=true,Anchored=false,AssemblyLinearVelocity=Vector3.new(4,0,6)}
local hum={Health=100}
local char={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return hum end}
local button={Name='JumpButton',InputBegan=signal(),IsA=function(_,name)return name=='GuiButton'end}
local app={Player={Character=char,CharacterAdded=signal()},PlayerGui={GetDescendants=function()return {button}end,DescendantAdded=signal()},
    Services={UserInputService=input},Legacy={RunService={PreSimulation=step},FlightController={Flying=false}},Flows={Control={}}}
local cleanups={}
function app:Connect(s,fn)local c=s:Connect(fn);cleanups[#cleanups+1]=function()c:Disconnect()end;return c end
function app:OnCleanup(fn)cleanups[#cleanups+1]=fn end
local c=assert(load(source))()(app)
local space={KeyCode=1}
input.InputBegan:Fire(space,false);step:Fire();assert(root.AssemblyLinearVelocity.Y==0)
c:SetEnabled(true);input.InputBegan:Fire(space,false);step:Fire()
assert(root.AssemblyLinearVelocity.Y==60 and root.AssemblyLinearVelocity.X==4 and c.Held)
input.InputEnded:Fire(space);assert(root.AssemblyLinearVelocity.Y==0 and not c.Held)
root.AssemblyLinearVelocity=Vector3.new(4,-10,6);step:Fire();assert(root.AssemblyLinearVelocity.Y==-10,'gravity remains free after release')
local touch={UserInputType=2}
button.InputBegan:Fire(touch);step:Fire();assert(c.Held and root.AssemblyLinearVelocity.Y==60,'native mobile jump button')
input.InputEnded:Fire(touch);assert(not c.Held and root.AssemblyLinearVelocity.Y==0)
root.Anchored=true;c:SetHeld(true);step:Fire();assert(not c.Held)
root.Anchored=false;step:Fire();assert(c.Held)
input.WindowFocusReleased:Fire();assert(not c.Held and root.AssemblyLinearVelocity.Y==0)
for i=#cleanups,1,-1 do cleanups[i]()end
for _,connection in ipairs(connections)do assert(not connection.fn)end
print('Sterling continuous jump OK: keyboard/touch hold, release/gravity, anchored guard, focus loss and cleanup')
