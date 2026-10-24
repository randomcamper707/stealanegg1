-- Steal An Egg - exact reference hotbar icon patch
-- Loads the current final build, then replaces guessed/white hotbar textures
-- with the exact item renders the user originally supplied.

local BASE_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/FinalFix.lua?v='..tostring(os.time())
local okBase,baseSource=pcall(function() return game:HttpGet(BASE_URL) end)
if not okBase or type(baseSource)~='string' then
    warn('[SAE] Could not download FinalFix.lua: '..tostring(baseSource))
    return
end
local baseFn,baseErr=loadstring(baseSource)
if not baseFn then
    warn('[SAE] FinalFix.lua compile error: '..tostring(baseErr))
    return
end
local ranBase,runErr=pcall(baseFn)
if not ranBase then
    warn('[SAE] FinalFix.lua runtime error: '..tostring(runErr))
    return
end

local Players=game:GetService('Players')
local P=Players.LocalPlayer
if not P then return end
local PG=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not PG or not BP then return end

-- This historical commit is the build where the user's exact supplied renders
-- were preserved as embedded PNGs. We read only that image table.
local REF_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/6f14a6070a1207346018d4283037d2bc539c0b1d/Main.lua?v='..tostring(os.time())
local okRef,refSource=pcall(function() return game:HttpGet(REF_URL) end)
if not okRef or type(refSource)~='string' then
    warn('[SAE] Could not download exact item references: '..tostring(refSource))
    return
end

local IMAGE_KEY={
    ['Unicorn Egg']='unicorn_egg',
    ['Unicorn']='unicorn_pet',
    ['Kitsune Egg']='kitsune_egg',
    ['Kitsune']='kitsune_pet',
    ['Night Flame Egg']='night_flame_egg',
    ['Night Flame']='night_flame_pet',
    ['Archangel Egg']='archangel_egg',
    ['Archangel']='archangel_pet',
    ['World Burner Egg']='world_burner_egg',
    ['World Burner']='world_burner_pet',
    ['Aetheron Egg']='aetheron_egg',
    ['Aetheron']='aetheron_pet',
    ['Cthulhu Egg']='cthulhu_egg',
    ['Cthulhu']='cthulhu_pet',
    ['Luminous Cthulhu Egg']='luminous_cthulhu_egg',
    ['Luminous Cthulhu']='luminous_cthulhu_pet',
    ['Sabertooth Egg']='sabertooth_egg',
    ['Sabertooth']='sabertooth_pet',
    ['Skeletal Sabertooth Egg']='skeletal_sabertooth_egg',
    ['Skeletal Sabertooth']='skeletal_sabertooth_pet',
    ['Octophant Egg']='octophant_egg',
    ['Octophant']='octophant_pet',
    ['Mecha Scrambler Egg']='mecha_scrambler_egg',
    ['Mecha Scrambler']='mecha_scrambler_pet',
    ['Star']='star',
}

local B64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function pureBase64Decode(data)
    data=data:gsub('[^'..B64..'=]','')
    return (data:gsub('.',function(x)
        if x=='=' then return '' end
        local r,f='',(B64:find(x,1,true)-1)
        for i=6,1,-1 do
            r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0')
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
        if #x~=8 then return '' end
        local c=0
        for i=1,8 do
            c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0)
        end
        return string.char(c)
    end))
end

local function decode64(data)
    local raw=nil
    pcall(function()
        if crypt and crypt.base64 and crypt.base64.decode then
            raw=crypt.base64.decode(data)
        elseif syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then
            raw=syn.crypt.base64.decode(data)
        end
    end)
    if type(raw)~='string' or #raw<100 then
        local ok,v=pcall(pureBase64Decode,data)
        if ok then raw=v end
    end
    return raw
end

local function escapePattern(s)
    return (s:gsub('(%W)','%%%1'))
end

local encodedCache={}
local function exactEncoded(name)
    if encodedCache[name]~=nil then return encodedCache[name] or nil end
    local key=IMAGE_KEY[name]
    if not key then encodedCache[name]=false return nil end
    local pat='%["'..escapePattern(key)..'"%]=%{w=%d+,h=%d+,data=%[%[([%s%S]-)%]%]%}'
    local data=refSource:match(pat)
    if type(data)~='string' or #data<100 then
        warn('[SAE] Exact reference image missing for '..name)
        encodedCache[name]=false
        return nil
    end
    encodedCache[name]=data
    return data
end

local assetCache={}
local function exactAsset(name)
    if assetCache[name]~=nil then return assetCache[name] or nil end
    local data=exactEncoded(name)
    if not data then assetCache[name]=false return nil end
    if type(writefile)~='function' then
        warn('[SAE] writefile unavailable; cannot install exact hotbar image for '..name)
        assetCache[name]=false
        return nil
    end
    local raw=decode64(data)
    if type(raw)~='string' or #raw<100 then
        warn('[SAE] Could not decode exact hotbar image for '..name)
        assetCache[name]=false
        return nil
    end

    local safe=name:gsub('[^%w]+','_')
    local path='SAE_exact_icon_'..safe..'.png'
    local okWrite=pcall(function() writefile(path,raw) end)
    if not okWrite then assetCache[name]=false return nil end

    local asset=nil
    pcall(function()
        if type(getcustomasset)=='function' then
            asset=getcustomasset(path)
        elseif type(getsynasset)=='function' then
            asset=getsynasset(path)
        end
    end)
    if type(asset)~='string' or asset=='' then
        warn('[SAE] Custom asset API unavailable for '..name)
        assetCache[name]=false
        return nil
    end
    assetCache[name]=asset
    return asset
end

local function norm(s)
    return tostring(s or ''):lower():gsub('[^%w]','')
end

-- Patch the game's visible hotbar image too, not only Tool.TextureId.
local function patchVisibleSlot(name,asset)
    if not asset or not PG then return end
    local want=norm(name)

    -- First try a slot that contains the item's text/name.
    for _,obj in ipairs(PG:GetDescendants()) do
        if obj:IsA('TextLabel') or obj:IsA('TextButton') then
            if norm(obj.Text)==want then
                local holder=obj.Parent
                for depth=1,4 do
                    if not holder then break end
                    for _,d in ipairs(holder:GetDescendants()) do
                        if d:IsA('ImageLabel') or d:IsA('ImageButton') then
                            local dn=norm(d.Name)
                            if dn:find('icon',1,true) or dn:find('image',1,true) or dn:find('item',1,true) or d.Image=='' then
                                d.Image=asset
                                return
                            end
                        end
                    end
                    holder=holder.Parent
                end
            end
        end
    end
end

local function applyExact(tool)
    if not tool or not tool:IsA('Tool') then return end
    if not IMAGE_KEY[tool.Name] then return end

    local asset=exactAsset(tool.Name)
    if not asset then return end

    pcall(function()
        tool.TextureId=asset
        tool:SetAttribute('SAE_EXACT_REFERENCE_ICON',asset)
    end)

    task.defer(function()
        task.wait(.1)
        patchVisibleSlot(tool.Name,asset)
    end)
end

local function bind(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and IMAGE_KEY[child.Name] then
            task.defer(function()
                task.wait(.05)
                applyExact(child)
            end)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') and IMAGE_KEY[child.Name] then
            applyExact(child)
        end
    end
end

bind(BP)
bind(P.Character)
P.CharacterAdded:Connect(function(char)
    task.wait(.1)
    bind(char)
end)

-- Replacement layers can swap Tools for a short period after spawning/equipping.
-- Reapply the exact reference after those replacements finish.
task.spawn(function()
    for _=1,24 do
        task.wait(.25)
        for _,holder in ipairs({BP,P.Character}) do
            if holder then
                for _,tool in ipairs(holder:GetChildren()) do
                    if tool:IsA('Tool') and IMAGE_KEY[tool.Name] then
                        applyExact(tool)
                    end
                end
            end
        end
    end
end)

print('[SAE] Exact supplied hotbar references installed for all eggs, pets and Star.')
