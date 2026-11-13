-- Optional Metro Life presence. Loaded after the main GUI, outside the splash.
return function(app)
    local state={Status="disabled"}
    if game.GameId~=4540138978 or not app.Alive or app.Loading then return state end
    local function report(message)
        state.LastError=message
        if state.ReportedError~=message then
            state.ReportedError=message
            warn("Sterling presence: "..message)
        end
    end
    local function resolve(env)
        if type(env)~="table"then return end
        for _,key in ipairs({"request","http_request","httprequest"})do
            if type(env[key])=="function"then return env[key]end
        end
        for _,key in ipairs({"syn","http"})do
            if type(env[key])=="table"and type(env[key].request)=="function"then return env[key].request end
        end
    end
    local requestFn=resolve(app.Environment)
    if not requestFn and type(getgenv)=="function"then
        local ok,env=pcall(getgenv);if ok then requestFn=resolve(env)end
    end
    if not requestFn and type(getfenv)=="function"then
        local ok,env=pcall(getfenv,0);if ok then requestFn=resolve(env)end
    end
    requestFn=requestFn or resolve({request=request,http_request=http_request,httprequest=httprequest,syn=syn,http=http})
    if not requestFn then state.Status="request_unavailable";report("No hay una funcion HTTP compatible en el ejecutor.");return state end
    local http=app.Services.HttpService
    local token,closed=nil,false
    local base="https://strikechat-api.onrender.com"
    local function call(path,body,sessionToken)
        local headers={["Content-Type"]="application/json",["X-Client-Key"]="159357"}
        if sessionToken then headers.Authorization="Bearer "..sessionToken end
        local ok,response=pcall(function()
            return requestFn({Url=base.."/api/v1/sessions/"..path,Method="POST",
                Headers=headers,Body=http:JSONEncode(body),Timeout=8})
        end)
        if not ok or type(response)~="table" then
            report("Fallo de transporte en sessions/"..path);return nil
        end
        local status=tonumber(response.StatusCode or response.Status or response.status_code)or 0
        state.LastHttpStatus=status
        if status<200 or status>=300 then
            report("HTTP "..status.." en sessions/"..path);return nil,status
        end
        local decoded,value=pcall(function()return http:JSONDecode(response.Body or response.body or "{}")end)
        return decoded and type(value)=="table" and value or {},status
    end
    local function finish(sessionToken)
        if sessionToken then call("end",{},sessionToken)end
    end
    app:OnCleanup(function()
        closed=true
        local old=token;token=nil
        state.Status="closed"
        if old then task.spawn(function()finish(old)end)end
    end)
    task.spawn(function()
        local retry=5
        while app.Alive and not closed and game.GameId==4540138978 do
            if not token then
                state.Status="connecting"
                local p=app.Player
                local result=call("start",{user_id=p.UserId,username=p.Name,display_name=p.DisplayName,
                    game_id=game.GameId,place_id=game.PlaceId,job_id=game.JobId,
                    game_name="Metro Life",script_version="script_sterling"})
                if result and type(result.session_token)=="string" then
                    if closed or not app.Alive then finish(result.session_token);return end
                    token=result.session_token;retry=5;state.Status="online";state.LastError=nil
                    print("Sterling presence: sesion script_sterling registrada en Metro Life.")
                else
                    state.Status="retrying"
                end
            else
                local result,status=call("heartbeat",{},token)
                if closed or not app.Alive then return end
                if status==401 or status==404 then token=nil end
                state.Status=result and "online" or "retrying"
            end
            local delay=token and 30 or retry
            if not token then retry=math.min(retry*2,120)end
            local deadline=os.clock()+delay
            repeat task.wait(1)until closed or not app.Alive or os.clock()>=deadline
        end
    end)
    return state
end
