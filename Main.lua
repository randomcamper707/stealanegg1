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

local baseSource=fetch(BASE,'full control panel')
if baseSource then run(baseSource,'full control panel') end

-- Keep the divine item spawner compact and give it a clean, short title.
-- The control panel builds this GUI asynchronously, so wait for it to appear.
task.spawn(function()
    local player=game:GetService('Players').LocalPlayer
    local playerGui=player and player:WaitForChild('PlayerGui',10)
    if not playerGui then return end
    for _=1,100 do
        local itemsGui=playerGui:FindFirstChild('SAE_ITEMS_V7')
        local content=itemsGui and itemsGui:FindFirstChildWhichIsA('ScrollingFrame',true)
        local window=content and content.Parent
        if window and window:IsA('Frame') then
            window.Name='ItemSpawnerWindow'
            window.Size=UDim2.fromOffset(350,320)
            window.Position=UDim2.new(.5,-175,.5,-160)
            for _,descendant in ipairs(window:GetDescendants()) do
                if descendant:IsA('TextLabel') then
                    if descendant.Text=='DIVINE ITEM SPAWNER · REFERENCE EGGS' then
                        descendant.Text='ITEM SPAWNER'
                    elseif descendant.Text=='25% smaller • refined Unicorn, Night Flame, Sabertooth' then
                        descendant:Destroy()
                    end
                end
            end
            return
        end
        task.wait(.1)
    end
end)

env.SAE_FINAL_LOADING=nil