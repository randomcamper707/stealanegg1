-- Steal An Egg - stable V7 loader
-- Loads the restored full control panel, then the true-3D inventory build.

local env=(getgenv and getgenv()) or _G
if env.SAE_MAIN_V7_LOADING then
    warn('[SAE] Script is already loading.')
    return
end
env.SAE_MAIN_V7_LOADING=true

local function fetch(url,label)
    local ok,res=pcall(function() return game:HttpGet(url) end)
    if not ok then warn('[SAE] Failed to download '..label..': '..tostring(res)) return nil end
    return res
end
local function execute(source,label)
    local fn,compileErr=loadstring(source)
    if not fn then warn('[SAE] Could not compile '..label..': '..tostring(compileErr)) return false end
    local ok,err=pcall(fn)
    if not ok then warn('[SAE] '..label..' failed: '..tostring(err)) end
    return ok
end

local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/351b1775b242d3ed6e4f124f820a5f6d39a26f2d/Main.lua'
local ADDON='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/AddonV7.lua?v='..tostring(os.time())

local baseSource=fetch(BASE,'control panel')
if baseSource then execute(baseSource,'control panel') end

task.wait(.05)
env.SAE_V7=nil
local addon=fetch(ADDON,'V7 true-3D inventory')
if addon then
    -- Normalize four missing separators from the minified source before compilation.
    addon=addon:gsub("'Select an item'status","'Select an item' status")
    addon=addon:gsub("'Select an item first'status","'Select an item first' status")
    addon=addon:gsub("'%.%.%.'status","'...' status")
    addon=addon:gsub("tostring%(msg%)status","tostring(msg) status")
    execute(addon,'V7 true-3D inventory')
end

env.SAE_MAIN_V7_LOADING=nil