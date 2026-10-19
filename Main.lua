-- Steal An Egg - FINAL loader
-- Exact game pet rigs + corrected held Star, then the intact full control panel.

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

-- Clear flags left by earlier test versions.
env.SAE_V7=nil
env.SAE_MAIN_V7_LOADING=nil

local nonce=tostring(os.time())
local PETS='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/ExactPets.lua?v='..nonce
local STAR='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/ExactStar.lua?v='..nonce
local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/7eb4de5f692f28c297cbd4b6fceb973c540af700/ControlPanel.lua?v='..nonce

local petSource=fetch(PETS,'exact pet rigs')
if petSource then run(petSource,'exact pet rigs') end

local starSource=fetch(STAR,'exact held star')
if starSource then run(starSource,'exact held star') end

local baseSource=fetch(BASE,'full control panel')
if baseSource then run(baseSource,'full control panel') end

env.SAE_FINAL_LOADING=nil
