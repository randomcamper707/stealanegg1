-- Steal An Egg - native reference asset resolver
-- Reuses client-visible game models instead of redrawing the three final references.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RF=game:GetService('ReplicatedFirst')
local Lighting=game:GetService('Lighting')
local StarterPack=game:GetService('StarterPack')
local P=Players.LocalPlayer

local old=RS:FindFirstChild('SAE_ExactReferenceModels')
if old then old:Destroy() end
local Out=Instance.new('Folder')
Out.Name='SAE_ExactReferenceModels'
Out.Parent=RS

local TARGETS={
    ['Night Flame']={'Night Flame','Nightflame','NightFlame'},
    ['Luminous Cthulhu']={'Luminous Cthulhu','LuminousCthulhu'},
    ['Star']={'Star','Golden Star','Gold Star','Divine Star'}
}

local function norm(v)
    return tostring(v or ''):lower():gsub('[^%w]','')
end

local function candidateRoot(o)
    if not o then return nil end
    if o:IsA('Model') or o:IsA('Tool') or o:IsA('Folder') then return o end
    if o:IsA('BasePart') then
        local x=o.Parent
        while x and x~=game do
            if x:IsA('Model') or x:IsA('Tool') then return x end
            x=x.Parent
        end
        return o
    end
end

local function hasParts(o)
    return o:IsA('BasePart') or o:FindFirstChildWhichIsA('BasePart',true)~=nil
end

local function underEgg(o)
    local x=o
    while x and x~=game do
        if norm(x.Name):find('egg',1,true) then return true end
        x=x.Parent
    end
    return false
end

local function nameScore(o,want,target)
    local n=norm(o.Name)
    local score=0
    if want[n] then score=3000 end
    for a in pairs(want) do
        if #a>=5 and n:find(a,1,true) then score=math.max(score,1800) end
    end
    for _,key in ipairs({'ItemName','DisplayName','PetName','Title','Type','Name'}) do
        local ok,v=pcall(function() return o:GetAttribute(key) end)
        if ok and v and want[norm(v)] then score=math.max(score,2600) end
    end
    if target~='Star' and underEgg(o) then score=score-5000 end
    return score
end

local function visualScore(root)
    local parts,meshes,textures=0,0,0
    if root:IsA('BasePart') then parts=1 end
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA('BasePart') then
            parts=parts+1
            if d:IsA('MeshPart') then
                meshes=meshes+1
                if d.TextureID~='' then textures=textures+1 end
            end
        elseif d:IsA('SpecialMesh') then
            meshes=meshes+1
            if d.TextureId~='' then textures=textures+1 end
        elseif d:IsA('SurfaceAppearance') or d:IsA('Decal') or d:IsA('Texture') then
            textures=textures+1
        end
    end
    return math.min(parts,250)+meshes*90+textures*30
end

local function cloneModel(src,name)
    local ok,c=pcall(function() return src:Clone() end)
    if not ok or not c then return nil end
    local m
    if c:IsA('Model') then
        m=c
    elseif c:IsA('Tool') or c:IsA('Folder') then
        m=Instance.new('Model')
        for _,child in ipairs(c:GetChildren()) do child.Parent=m end
        c:Destroy()
    elseif c:IsA('BasePart') then
        m=Instance.new('Model')
        c.Parent=m
    else
        c:Destroy()
        return nil
    end
    local remove={}
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript') or d:IsA('Humanoid') or d:IsA('Animator') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector') or d:IsA('BillboardGui') or d:IsA('SurfaceGui') then
            table.insert(remove,d)
        elseif d:IsA('BasePart') then
            d.Anchored=false
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=false
            d.Massless=true
        end
    end
    for _,d in ipairs(remove) do pcall(function() d:Destroy() end) end
    if not m:FindFirstChildWhichIsA('BasePart',true) then m:Destroy() return nil end
    m.Name=name
    m:SetAttribute('SAE_EXACT_SOURCE',true)
    return m
end

local roots={RS,workspace,RF,Lighting,StarterPack}

for target,aliases in pairs(TARGETS) do
    local want={}
    for _,a in ipairs(aliases) do want[norm(a)]=true end
    local best,bestScore=nil,-math.huge
    local seen={}
    for _,rootService in ipairs(roots) do
        local list=rootService:GetDescendants()
        for i,o in ipairs(list) do
            local root=candidateRoot(o)
            if root and not seen[root] and root~=Out and not root:IsDescendantOf(Out) and hasParts(root) and not (P and P.Character and root:IsDescendantOf(P.Character)) then
                seen[root]=true
                local score=math.max(nameScore(o,want,target),nameScore(root,want,target))
                if score>0 then
                    score=score+visualScore(root)+(rootService==RS and 250 or 0)
                    if score>bestScore then best,bestScore=root,score end
                end
            end
            if i%2500==0 then task.wait() end
        end
    end
    if best then
        local m=cloneModel(best,target)
        if m then
            m.Parent=Out
            print('[SAE] Native reference selected: '..target)
        end
    else
        warn('[SAE] Native reference not found: '..target)
    end
end
