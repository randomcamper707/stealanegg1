-- SAE V6 - exact-model-first inventory + reference-faithful volumetric fallback
-- The supplied reference renders are only used if the actual 3D game model is unavailable.

local ENV=(getgenv and getgenv()) or _G
if ENV.SAE_V6 then return end
ENV.SAE_V6=true

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local TweenService=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local StarterPack=game:GetService('StarterPack')

local P=Players.LocalPlayer
local PG=P and (P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10))
local BP=P and (P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10))
if not P or not PG or not BP then ENV.SAE_V6=nil return end

for _,n in ipairs({'SAE_ITEMS_V6','SAE_ITEMS_V5','SAE_ITEMS_V4','SAE_ITEMS_V3'}) do
    local g=PG:FindFirstChild(n)
    if g then g:Destroy() end
end
for _,container in ipairs({BP,P.Character}) do
    if container then
        for _,x in ipairs(container:GetChildren()) do
            if x:IsA('Tool') and (x:GetAttribute('SAE_V6_TOOL') or x:GetAttribute('SAE_V5_TOOL') or x:GetAttribute('SAE_InventoryTool')) then
                x:Destroy()
            end
        end
    end
end
local oldPlaced=workspace:FindFirstChild('SAE_V6_PLACED') or workspace:FindFirstChild('SAE_V5_PLACED')
if oldPlaced then oldPlaced:Destroy() end
local Placed=Instance.new('Folder')
Placed.Name='SAE_V6_PLACED'
Placed.Parent=workspace

local C={
    bg=Color3.fromRGB(8,8,14), head=Color3.fromRGB(15,11,23), card=Color3.fromRGB(24,18,34),
    card2=Color3.fromRGB(37,25,50), border=Color3.fromRGB(84,57,110), p=Color3.fromRGB(142,51,236),
    p2=Color3.fromRGB(184,83,255), w=Color3.new(1,1,1), m=Color3.fromRGB(168,162,181),
    g=Color3.fromRGB(105,245,135), o=Color3.fromRGB(255,188,82), r=Color3.fromRGB(255,86,86)
}

local ITEMS={
    Eggs={
        {name='Unicorn Egg',key='unicorn_egg'},
        {name='Kitsune Egg',key='kitsune_egg'},
        {name='Night Flame Egg',key='night_flame_egg'},
        {name='Archangel Egg',key='archangel_egg'},
        {name='World Burner Egg',key='world_burner_egg'},
        {name='Aetheron Egg',key='aetheron_egg'},
        {name='Cthulhu Egg',key='cthulhu_egg'},
        {name='Luminous Cthulhu Egg',key='luminous_cthulhu_egg'},
        {name='Sabertooth Egg',key='sabertooth_egg'},
        {name='Skeletal Sabertooth Egg',key='skeletal_sabertooth_egg'},
        {name='Octophant Egg',key='octophant_egg'},
        {name='Mecha Scrambler Egg',key='mecha_scrambler_egg'},
    },
    Pets={
        {name='Unicorn',key='unicorn_pet'},
        {name='Kitsune',key='kitsune_pet'},
        {name='Night Flame',key='night_flame_pet'},
        {name='Archangel',key='archangel_pet'},
        {name='World Burner',key='world_burner_pet'},
        {name='Aetheron',key='aetheron_pet'},
        {name='Cthulhu',key='cthulhu_pet'},
        {name='Luminous Cthulhu',key='luminous_cthulhu_pet'},
        {name='Sabertooth',key='sabertooth_pet'},
        {name='Skeletal Sabertooth',key='skeletal_sabertooth_pet'},
        {name='Octophant',key='octophant_pet'},
        {name='Mecha Scrambler',key='mecha_scrambler_pet'},
    },
    Star={{name='Star',key='star'}},
}

local EXTRA_ALIASES={
    ['Night Flame']={'Night Flame','Nightflame','NightFlame'},
    ['Night Flame Egg']={'Night Flame Egg','Nightflame Egg','NightFlameEgg','NightflameEgg'},
    ['Archangel']={'Archangel','ArchAngel','Arch Angel'},
    ['Archangel Egg']={'Archangel Egg','ArchAngel Egg','Arch Angel Egg','ArchAngelEgg'},
    ['World Burner']={'World Burner','WorldBurner'},
    ['World Burner Egg']={'World Burner Egg','WorldBurner Egg','WorldBurnerEgg'},
    ['Luminous Cthulhu']={'Luminous Cthulhu','LuminousCthulhu'},
    ['Luminous Cthulhu Egg']={'Luminous Cthulhu Egg','LuminousCthulhu Egg','LuminousCthulhuEgg'},
    ['Skeletal Sabertooth']={'Skeletal Sabertooth','Skeletal Saber Tooth','SkeletalSabertooth'},
    ['Skeletal Sabertooth Egg']={'Skeletal Sabertooth Egg','Skeletal Saber Tooth Egg','SkeletalSabertoothEgg'},
    ['Mecha Scrambler']={'Mecha Scrambler','MechaScrambler'},
    ['Mecha Scrambler Egg']={'Mecha Scrambler Egg','MechaScrambler Egg','MechaScramblerEgg'},
    ['Star']={'Star','Golden Star','Gold Star','Divine Star'},
}

local function norm(x)
    return tostring(x or ''):lower():gsub('[^%w]','')
end

local function getEnvFunction(...)
    local names={...}
    for _,name in ipairs(names) do
        local fn
        pcall(function() fn=ENV[name] end)
        if type(fn)=='function' then return fn end
        pcall(function() fn=_G[name] end)
        if type(fn)=='function' then return fn end
    end
end

local GETINSTANCES=getEnvFunction('getinstances')
local GETNIL=getEnvFunction('getnilinstances')
local WRITEFILE=getEnvFunction('writefile')
local ISFILE=getEnvFunction('isfile')
local GETASSET=getEnvFunction('getcustomasset','getsynasset')

local function hasParts(o)
    if not o then return false end
    if o:IsA('BasePart') then return true end
    return o:FindFirstChildWhichIsA('BasePart',true)~=nil
end

local function allParts(o)
    local t={}
    if o:IsA('BasePart') then t[1]=o return t end
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA('BasePart') then t[#t+1]=d end
    end
    return t
end

local function getVisualContainer(o)
    if not o then return nil end
    if o:IsA('Tool') or o:IsA('Model') or o:IsA('Accessory') then return o end
    if o:IsA('BasePart') then
        local x=o
        while x and x~=game do
            if x:IsA('Tool') or x:IsA('Model') or x:IsA('Accessory') then return x end
            x=x.Parent
        end
        return o
    end
    local x=o.Parent
    local steps=0
    while x and x~=game and steps<8 do
        if x:IsA('Tool') or x:IsA('Model') or x:IsA('Accessory') then return x end
        x=x.Parent
        steps=steps+1
    end
end

local function contextHasWord(o,word)
    local x=o
    local steps=0
    while x and x~=game and steps<10 do
        if norm(x.Name):find(word,1,true) then return true end
        for _,k in ipairs({'Category','Type','Class','ItemType'}) do
            local ok,v=pcall(function() return x:GetAttribute(k) end)
            if ok and v and norm(v):find(word,1,true) then return true end
        end
        x=x.Parent
        steps=steps+1
    end
    return false
end

local function aliasesFor(category,name)
    local arr={}
    local seen={}
    local function add(v)
        local n=norm(v)
        if n~='' and not seen[n] then seen[n]=true arr[#arr+1]=v end
    end
    add(name)
    for _,v in ipairs(EXTRA_ALIASES[name] or {}) do add(v) end
    if category=='Eggs' then
        local base=name:gsub('%s+[Ee][Gg][Gg]$','')
        add(base)
        add(base..' Egg')
        add((base..'Egg'):gsub('%s',''))
    end
    return arr,seen
end

local sourceCache={}
local function candidateInstances()
    local out={}
    local used={}
    local function add(o)
        if typeof(o)=='Instance' and not used[o] then used[o]=true out[#out+1]=o end
    end
    if GETINSTANCES then
        local ok,list=pcall(GETINSTANCES)
        if ok and type(list)=='table' then for _,o in ipairs(list) do add(o) end end
    end
    if GETNIL then
        local ok,list=pcall(GETNIL)
        if ok and type(list)=='table' then for _,o in ipairs(list) do add(o) end end
    end
    if #out==0 then
        for _,root in ipairs({RS,workspace,Lighting,StarterPack}) do
            add(root)
            for _,o in ipairs(root:GetDescendants()) do add(o) end
        end
    end
    return out
end

local function matchSignal(o,want)
    if want[norm(o.Name)] then return 5000 end
    for _,k in ipairs({'ItemName','DisplayName','PetName','EggName','Name','Title','Type','Id','ID'}) do
        local ok,v=pcall(function() return o:GetAttribute(k) end)
        if ok and v and want[norm(v)] then return 4300 end
    end
    if o:IsA('StringValue') and want[norm(o.Value)] then return 4200 end
    return nil
end

local function findExact(category,name)
    local ck=category..'::'..name
    local cached=sourceCache[ck]
    if cached then
        local ok=pcall(function() return cached.ClassName end)
        if ok then return cached end
    end
    local _,want=aliasesFor(category,name)
    local list=candidateInstances()
    local best,bestScore=nil,-math.huge
    for i,o in ipairs(list) do
        if i%700==0 then task.wait() end
        if o and o~=game and not o:IsDescendantOf(Placed) and not (P.Character and o:IsDescendantOf(P.Character)) then
            if not (o:IsA('GuiObject') or o:IsA('Decal') or o:IsA('Texture') or o:IsA('SurfaceGui') or o:IsA('BillboardGui')) then
                local signal=matchSignal(o,want)
                if signal then
                    local v=getVisualContainer(o)
                    if v and hasParts(v) and not v:IsDescendantOf(Placed) then
                        local eggCtx=contextHasWord(v,'egg') or contextHasWord(o,'egg')
                        local valid=true
                        if category=='Pets' and eggCtx then valid=false end
                        if category=='Eggs' then
                            local direct=want[norm(v.Name)] or want[norm(o.Name)]
                            local full=norm(name)
                            local fullSeen=(norm(v.Name)==full or norm(o.Name)==full)
                            if not eggCtx and not fullSeen and direct then valid=false end
                        end
                        if valid then
                            local score=signal
                            if v:IsA('Tool') then score=score+350 elseif v:IsA('Model') then score=score+300 else score=score+120 end
                            if category=='Eggs' and eggCtx then score=score+900 end
                            if category=='Pets' and contextHasWord(v,'pet') then score=score+500 end
