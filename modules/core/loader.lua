return function(read, environment)
    local function compile(path)
        local result, problem = loadstring(read(path), "@sterling/" .. path)
        assert(result, problem)
        return result
    end
    -- Show this tiny module before fetching the manifest or large catalogs.
    local splash = compile("modules/ui/loading.lua")()(environment)
    local previousLoading = environment.SterlingLoading
    if previousLoading then previousLoading.Cancelled=true;previousLoading:Destroy() end
    environment.SterlingLoading=splash
    local app
    local ok, problem = xpcall(function()
        local function check()
            assert(not splash.Cancelled and environment.SterlingLoading==splash, "Sterling: carga cancelada")
        end
        local function progress(value, text)
            check();splash:Update(value,text);check()
        end
        progress(0,"Leyendo módulos de Sterling…")
        local manifest=compile("modules/manifest.lua")()
        assert(type(manifest)=="table" and manifest.version==1,"Sterling: invalid manifest")
        local factories, sequence, legacy = {}, {}, {}
        local moduleCount=1
        for _, group in ipairs({"core","legacy","adapters","features"}) do moduleCount=moduleCount+#(manifest[group] or {}) end
        local catalogOrder=manifest.startupCatalogs or {}
        local total=moduleCount*2+#catalogOrder+1
        local completed=0
        local function report(text) progress(completed/total,text) end
        local catalogs={}
        for _, item in ipairs(catalogOrder) do
            report(item.label)
            local raw=compile(item.path)()
            assert(type(raw)=="string","Sterling: invalid catalog source")
            check()
            local decoded=game:GetService("HttpService"):JSONDecode(raw)
            assert(type(decoded)=="table" and type(decoded.data or decoded)=="table","Sterling: invalid catalog data")
            catalogs[item.id]={Raw=raw,Decoded=decoded}
            completed=completed+1;report(item.label.." · listo")
        end
        local function add(id, copied)
            assert(type(id)=="string" and id:match("^[%w_/-]+$") and not id:find("//",1,true),"Sterling: invalid module path")
            assert(not factories[id],"Sterling: duplicate module "..id)
            report("Cargando · "..id)
            local factory=compile("modules/"..id..".lua")()
            assert(type(factory)=="function","Sterling: expected module factory "..id)
            factories[id]=factory;sequence[#sequence+1]=id;legacy[id]=copied
            completed=completed+1;report("Cargado · "..id)
        end
        for _, id in ipairs(manifest.core) do add(id) end
        for _, id in ipairs(manifest.legacy or {}) do add(id,true) end
        for _, id in ipairs(manifest.adapters or {}) do add(id) end
        for _, id in ipairs(manifest.features) do add(id) end
        add(manifest.start)
        check()
        local previous=environment.SterlingApp
        if previous and type(previous.Destroy)=="function" then previous:Destroy() end
        check()
        app={ReadSource=read,Environment=environment,Manifest=manifest,Modules={},Alive=true,StartupCatalogs=catalogs,Loading=true}
        for _, id in ipairs(sequence) do
            report("Preparando · "..id)
            local context=legacy[id] and app.Legacy or app
            assert(context,"Sterling: missing copied-module context")
            app.Modules[id]=factories[id](context)
            completed=completed+1;report("Preparado · "..id)
        end
        progress(1,"Sterling está listo")
        splash:Yield(true);check()
        app.Loading=false
        if app.Window then app.Window.Gui.Enabled=true end
        environment.SterlingApp=app
    end,debug.traceback)
    if not ok then
        if app and app.Destroy then app:Destroy() end
        if splash.Cancelled then
            splash:Destroy()
            if environment.SterlingLoading==splash then environment.SterlingLoading=nil end
        else
            -- Keep its handle so the next execution also removes this error UI.
            splash:Fail()
        end
        error(problem,0)
    end
    if environment.SterlingLoading==splash then environment.SterlingLoading=nil end
    splash:Destroy()
    return app
end
