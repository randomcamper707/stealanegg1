-- Final native-reference replacement layer.
-- The three disputed items are no longer redrawn from primitive parts.
-- This layer reuses the game's client-visible 3D assets and swaps them into
-- the existing inventory tool as soon as one of those three items is spawned.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RF=game:GetService('ReplicatedFirst')
local Lighting=game:GetService('Lighting')
local StarterPack=game:GetService('StarterPack')
local P=Players.LocalPlayer
if not P then return end

local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local old=RS:FindFirstChild('SAE_FinalReferenceModels')
if old then old:Destroy() end
local Folder=Instance.new('Folder')
Folder.Name='SAE_FinalReferenceModels'
Folder.Parent=RS

local TARGETS={
    ['Night Flame']={aliases={'Night Flame','Nightflame','NightFlame'},kind='Pet',size=17.5,offset=CFrame.new(0,2.1,-4.7)},
    ['Luminous Cthulhu']={aliases={'Luminous Cthulhu','LuminousCthulhu'},kind='Pet',size=18.5,offset=CFrame.new(0,2.2,-5.0)},
    ['Star']={aliases={'Star','Golden Star','Gold Star','Divine Star'},kind='Star',size=6.8,offset=CFrame.new(0,.35,-1.25)*CFrame.Angles(0,math.rad(180),0)}
}

local function norm(v)
    return tostring(v or ''):lower():gsub('[^%w]','')
end

local function containsEgg(o)
    local x=o
    while x and x~=game do
        if norm(x.Name):find('egg',1,true) then return true end
        x=x.Parent
    end
    return false
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

local function scoreName(o,want,target)
    local n=norm(o.Name)
    local score=0
    if want[n] then score=3000 end
    for alias in pairs(want) do
        if #alias>=4 and n:find(alias,1,true) then score=math.max(score,1700) end
    end
    for _,key in ipairs({'ItemName','DisplayName','PetName','Title','Type','Name'}) do
        local ok,v=pcall(function() return o:GetAttribute(key) end)
        if ok and v and want[norm(v)] then score=math.max(score,2600) end
    end
    if target~='Star' and containsEgg(o) then score=score-5000 end
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
    return math.min(parts,250)+meshes*100+textures*35
end

local function cloneAsModel(src,name)
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
    m:SetAttribute('SAE_NATIVE_REFERENCE',true)
    return m
end

local roots={RS,workspace,RF,Lighting,StarterPack}
local templates={}

local function resolveTarget(name,info)
    local want={}
    for _,a in ipairs(info.aliases) do want[norm(a)]=true end
    local best,bestScore=nil,-math.huge
    local seen={}

    for _,serviceRoot in ipairs(roots) do
        local list=serviceRoot:GetDescendants()
        for i,o in ipairs(list) do
            local root=candidateRoot(o)
            if root and root~=Folder and not root:IsDescendantOf(Folder) and not seen[root] and hasParts(root) and not (P.Character and root:IsDescendantOf(P.Character)) then
                seen[root]=true
                local score=math.max(scoreName(o,want,name),scoreName(root,want,name))
                if score>0 then
                    score=score+visualScore(root)+(serviceRoot==RS and 250 or 0)
                    if score>bestScore then best,bestScore=root,score end
                end
            end
            if i%2500==0 then task.wait() end
        end
    end

    if not best then
        warn('[SAE] Exact game model was not found for '..name)
        return nil
    end

    local model=cloneAsModel(best,name)
    if not model then return nil end
    model.Parent=Folder
    templates[name]=model
    print('[SAE] Exact game model selected for '..name)
    return model
end

for name,info in pairs(TARGETS) do
    resolveTarget(name,info)
end

local function allParts(m)
    local t={}
    for _,d in ipairs(m:GetDescendants()) do if d:IsA('BasePart') then table.insert(t,d) end end
    return t
end

local function fit(m,target)
    local ok,size=pcall(function() return m:GetExtentsSize() end)
    if ok then
        local mx=math.max(size.X,size.Y,size.Z)
        if mx>.01 then pcall(function() m:ScaleTo(target/mx) end) end
    end
end

local function placeTool(tool,model)
    local c=model:Clone()
    for _,d in ipairs(c:GetDescendants()) do
        if d:IsA('WeldConstraint') or d:IsA('Motor6D') then d:Destroy() end
    end
    local placed=workspace:FindFirstChild('SAE_V7_PLACED')
    if not placed then
        placed=Instance.new('Folder')
        placed.Name='SAE_V7_PLACED'
        placed.Parent=workspace
    end
    c.Parent=placed
    for _,p in ipairs(allParts(c)) do
        p.Anchored=true
        p.CanCollide=false
        p.CanQuery=true
    end
    local mouse=P:GetMouse()
    local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
    local pos=(mouse and mouse.Hit and mouse.Hit.Position) or (hrp and (hrp.Position+hrp.CFrame.LookVector*9)) or Vector3.zero
    local rayParams=RaycastParams.new()
    rayParams.FilterType=Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances={P.Character,placed}
    local ray=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rayParams)
    if ray then pos=ray.Position end
    c:PivotTo(CFrame.new(pos))
    local cf,sz=c:GetBoundingBox()
    c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))
    tool:Destroy()
end

local replacing={}
local function replaceTool(tool)
    if not tool or not tool:IsA('Tool') then return end
    local info=TARGETS[tool.Name]
    if not info or tool:GetAttribute('SAE_NATIVE_FINAL') then return end
    local template=templates[tool.Name]
    if not template then
        -- Do not replace with another guessed shape if the real asset is unavailable.
        return
    end
    if replacing[tool] then return end
    replacing[tool]=true

    task.defer(function()
        if not tool.Parent then replacing[tool]=nil return end
        local parent=tool.Parent
        local newTool=Instance.new('Tool')
        newTool.Name=tool.Name
        newTool.RequiresHandle=true
        newTool.CanBeDropped=false
        newTool:SetAttribute('SAE_V7_TOOL',true)
        newTool:SetAttribute('SAE_NATIVE_FINAL',true)

        local handle=Instance.new('Part')
        handle.Name='Handle'
        handle.Size=Vector3.new(.4,.4,.4)
        handle.Transparency=1
        handle.Anchored=false
        handle.CanCollide=false
        handle.CanTouch=false
        handle.CanQuery=false
        handle.Massless=true
        handle.Parent=newTool

        local model=template:Clone()
        fit(model,info.size)
        model.Parent=newTool
        model:PivotTo(handle.CFrame*info.offset)
        for _,p in ipairs(allParts(model)) do
            p.Anchored=false
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Massless=true
            local weld=Instance.new('WeldConstraint')
            weld.Part0=handle
            weld.Part1=p
            weld.Parent=handle
        end

        if info.kind=='Star' then
            newTool.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)
        else
            newTool.Activated:Connect(function()
                if newTool.Parent==P.Character then placeTool(newTool,model) end
            end)
        end

        tool:Destroy()
        newTool.Parent=parent
        replacing[tool]=nil
    end)
end

local function watch(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and TARGETS[child.Name] then
            task.wait()
            replaceTool(child)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') and TARGETS[child.Name] then replaceTool(child) end
    end
end

watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(char)
    task.wait(.2)
    watch(char)
end)
