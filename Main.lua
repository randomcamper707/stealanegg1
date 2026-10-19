-- Steal An Egg - FINAL loader
-- Loads the final reference-based 3D overrides first, then the last intact full build.

local env=(getgenv and getgenv()) or _G
if env.SAE_FINAL_LOADING then return end
env.SAE_FINAL_LOADING=true

local function fetch(url,label)
    local ok,res=pcall(function()
        return game:HttpGet(url,true)
    end)
    if not ok or type(res)~='string' or #res<16 then
        warn('[SAE] Failed to download '..label..': '..tostring(res))
        return nil
    end
    return res
end

local function run(source,label)
    local fn,compileErr=loadstring(source)
    if not fn then
        warn('[SAE] Could not compile '..label..': '..tostring(compileErr))
        return false
    end
    local ok,err=pcall(fn)
    if not ok then
        warn('[SAE] '..label..' failed: '..tostring(err))
        return false
    end
    return true
end

-- Clear stale session flags from older test builds.
env.SAE_V7=nil
env.SAE_MAIN_V7_LOADING=nil

local nonce=tostring(os.time())
local PATCH='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/ReferenceModels.lua?v='..nonce
local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/e598304740acb4afd2213969f47b5a884bb09668/ControlPanel.lua?v='..nonce

local patchSource=fetch(PATCH,'final reference models')
if patchSource then
    run(patchSource,'final reference models')
end

local baseSource=fetch(BASE,'full control panel')
if baseSource then
    run(baseSource,'full control panel')
end

env.SAE_FINAL_LOADING=nil
