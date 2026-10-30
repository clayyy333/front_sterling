-- Stable entry point: presentation and features live in modules/.
local environment = type(getgenv) == "function" and getgenv() or _G
local source = environment.SterlingSource or {}
local baseUrl = source.BaseUrl or "https://raw.githubusercontent.com/clayyy333/front_sterling/main/"
local revision = tostring(source.Revision or os.time())
local function read(path)
    if source.LocalRoot then return readfile(source.LocalRoot .. "/" .. path) end
    return game:HttpGet(baseUrl .. path .. "?v=" .. revision)
end
local loader, problem = loadstring(read("modules/core/loader.lua"), "@sterling/loader")
assert(loader, problem)
return loader()(read, environment)
