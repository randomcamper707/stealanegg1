-- Steal An Egg - stable V5 loader
-- Loads the restored full control panel from a pinned commit, then the current 3D inventory add-on.

local env=(getgenv and getgenv()) or _G
if env.SAE_MAIN_V5_LOADING then
    warn('[SAE] Script is already loading.')
    return
end
env.SAE_MAIN_V5_LOADING=true

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
local ADDON='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/AddonV5.lua?v='..tostring(os.time())

run(BASE,'control panel')
task.wait(.05)
run(ADDON,'3D inventory')

env.SAE_MAIN_V5_LOADING=nil
