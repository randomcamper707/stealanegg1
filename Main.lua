-- Steal An Egg - stable V7 loader
-- Loads the restored full control panel, then the true-3D inventory build.

local env=(getgenv and getgenv()) or _G
if env.SAE_MAIN_V7_LOADING then
    warn('[SAE] Script is already loading.')
    return
end
env.SAE_MAIN_V7_LOADING=true

local function run(url,label)
    local ok,err=pcall(function()
        local source=game:HttpGet(url)
        local fn,compileErr=loadstring(source)
        if not fn then error(compileErr or ('Could not compile '..label)) end
        fn()
    end)
    if not ok then warn('[SAE] '..label..' failed: '..tostring(err)) end
    return ok
end

local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/351b1775b242d3ed6e4f124f820a5f6d39a26f2d/Main.lua'
local ADDON='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/AddonV7.lua?v='..tostring(os.time())

run(BASE,'control panel')
task.wait(.05)
env.SAE_V7=nil
run(ADDON,'V7 true-3D inventory')
env.SAE_MAIN_V7_LOADING=nil