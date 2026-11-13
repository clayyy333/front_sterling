local source=...
local queued,calls,cleanup={}, {},nil
task={spawn=function(f)queued[#queued+1]=coroutine.create(f)end,
    wait=function()coroutine.yield()end}
game={GameId=1,PlaceId=12985361032,JobId="test-job"}
local app={Alive=true,Loading=false,Environment={},
    Services={HttpService={JSONEncode=function(_,v)return v end,JSONDecode=function(_,v)return v end}},
    Config={Version="0.2.0"},Player={UserId=1,Name="Test",DisplayName="Test"},
    OnCleanup=function(_,f)cleanup=f end}
local factory=assert(load(source))()
assert(factory(app).Status=="disabled" and #queued==0)
game.GameId=4540138978;app.Loading=true
assert(factory(app).Status=="disabled" and #queued==0)
app.Loading=false
app.Environment.request=function(opts)
    calls[#calls+1]=opts
    return {StatusCode=200,Body={session_token="test-token"}}
end
local state=factory(app)
assert(#calls==0 and #queued==1)
local worker=table.remove(queued,1)
assert(coroutine.resume(worker))
assert(#calls==1 and calls[1].Url:match("/sessions/start$"))
assert(calls[1].Body.script_version=="script_sterling")
assert(calls[1].Body.game_id==4540138978)
cleanup();assert(state.Status=="closed")
assert(coroutine.resume(table.remove(queued,1)))
assert(#calls==2 and calls[2].Url:match("/sessions/end$"))
assert(coroutine.resume(worker));assert(#calls==2)
-- Closing while registration is in flight must end the returned session.
queued={};calls={};app.Alive=true
app.Environment.request=function(opts)
    calls[#calls+1]=opts
    if opts.Url:match("/start$")then cleanup()end
    return {StatusCode=200,Body={session_token="late-token"}}
end
factory(app)
assert(coroutine.resume(table.remove(queued,1)))
assert(#calls==2 and calls[2].Headers.Authorization=="Bearer late-token")
print("Presence OK: Metro/loading gates, asynchronous start, source, cleanup and late response")
-- Executor APIs may exist only in getgenv; ignore non-function placeholders.
queued={};calls={};app.Environment={request=true};warn=function()end
getgenv=function()return {http_request=function(opts)
    calls[#calls+1]=opts
    return {StatusCode=403,Body={}}
end}end
local failed=factory(app)
assert(coroutine.resume(table.remove(queued,1)))
assert(#calls==1 and failed.LastHttpStatus==403)
assert(failed.LastError=="HTTP 403 en sessions/start")
cleanup()
getgenv=nil
