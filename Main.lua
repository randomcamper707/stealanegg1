-- Steal An Egg - FINAL loader
-- Exact game pet rigs + corrected held Star + final motion/size polish,
-- then the intact full control panel.

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
local POLISH='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/FinalPolish.lua?v='..nonce
local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/46ab3155cb1d2be20e048e4551a18dd0add0c9ec/ControlPanel.lua?v='..nonce

local petSource=fetch(PETS,'exact pet rigs')
if petSource then run(petSource,'exact pet rigs') end

local starSource=fetch(STAR,'held reference Star')
if starSource then run(starSource,'held reference Star') end

local polishSource=fetch(POLISH,'final pet/egg polish')
if polishSource then run(polishSource,'final pet/egg polish') end

-- Apply the spawner edits to the fetched source before compiling it.
local function replaceLiteral(source,oldText,newText)
    local first,last=source:find(oldText,1,true)
    if not first then return nil end
    return source:sub(1,first-1)..newText..source:sub(last+1)
end

local baseSource=fetch(BASE,'full control panel')
if baseSource then
    local edits={
        {"win.Size=UDim2.fromOffset(440,380)","win.Size=UDim2.fromOffset(350,320)"},
        {"win.Position=UDim2.new(.5,-220,.5,-190)","win.Position=UDim2.new(.5,-175,.5,-160)"},
        {"DIVINE ITEM SPAWNER · REFERENCE EGGS","ITEM SPAWNER"},
        {"label(head,'25% smaller • refined Unicorn, Night Flame, Sabertooth',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)",""}
    }
    local missing={}
    for _,edit in ipairs(edits) do
        local updated=replaceLiteral(baseSource,edit[1],edit[2])
        if updated then
            baseSource=updated
        else
            table.insert(missing,edit[1])
        end
    end
    if #missing==0 then
        run(baseSource,'full control panel')
    else
        warn('[SAE] Spawner source edits did not match; panel was not started.')
    end
end

env.SAE_FINAL_LOADING=nil