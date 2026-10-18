-- Steal An Egg - stable V6 loader
-- Loads the restored full control panel, then the exact-model/reference-faithful inventory build.

local env=(getgenv and getgenv()) or _G
if env.SAE_MAIN_V6_LOADING then
    warn('[SAE] Script is already loading.')
    return
end
env.SAE_MAIN_V6_LOADING=true

local function fetch(url,label)
    local ok,res=pcall(function() return game:HttpGet(url) end)
    if not ok then
        warn('[SAE] Failed to download '..label..': '..tostring(res))
        return nil
    end
    return res
end

local function execute(source,label)
    local fn,compileErr=loadstring(source)
    if not fn then
        warn('[SAE] Could not compile '..label..': '..tostring(compileErr))
        return false
    end
    local ok,err=pcall(fn)
    if not ok then warn('[SAE] '..label..' failed: '..tostring(err)) end
    return ok
end

local BASE='https://raw.githubusercontent.com/randomcamper707/stealanegg1/351b1775b242d3ed6e4f124f820a5f6d39a26f2d/Main.lua'
local ROOT='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/'
local stamp=tostring(os.time())

local baseSource=fetch(BASE,'control panel')
if baseSource then execute(baseSource,'control panel') end

task.wait(.05)

-- Allow rerunning the newest inventory build in the same server.
env.SAE_V6=nil
local chunks={}
for i=1,3 do
    local part=fetch(ROOT..'AddonV6_'..i..'.lua?v='..stamp..'_'..i,'inventory part '..i)
    if not part then
        env.SAE_MAIN_V6_LOADING=nil
        return
    end
    chunks[#chunks+1]=part
end
execute(table.concat(chunks,'\n'),'V6 inventory')

env.SAE_MAIN_V6_LOADING=nil
