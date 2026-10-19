-- Exact pet replacement layer for Steal An Egg
-- Uses the game's own replicated pet rig templates rather than redrawing them.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local DEF={
    ['Night Flame']={category='Godzilla',size=18,offset=CFrame.new(0,2.15,-4.85)},
    ['Luminous Cthulhu']={category='Depths Cthulhu',size=19,offset=CFrame.new(0,2.25,-5.15)}
}

local function allParts(m)
    local out={}
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('BasePart') then out[#out+1]=d end
    end
    return out
end

local function prepare(m,name)
    if not m or not m:IsA('Model') then return nil end
    local remove={}
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript')
            or d:IsA('Humanoid') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector')
            or d:IsA('BillboardGui') or d:IsA('SurfaceGui') then
            remove[#remove+1]=d
        elseif d:IsA('BasePart') then
            d.Anchored=false
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=false
            d.Massless=true
        end
    end
    for _,d in ipairs(remove) do pcall(function() d:Destroy() end) end
    local root=m.PrimaryPart or m:FindFirstChild('HumanoidRootPart',true)
        or m:FindFirstChild('Segment1',true) or m:FindFirstChildWhichIsA('BasePart',true)
    if not root then m:Destroy() return nil end
    m.PrimaryPart=root
    m.Name=name
    return m
end

local Factory=nil
pcall(function()
    Factory=require(RS:WaitForChild('Shared',5):WaitForChild('Modules',5):WaitForChild('AssetRigFactory',5))
end)

local templates={}
local function buildExact(name,info)
    if type(Factory)=='table' and type(Factory.Build)=='function' then
        local ok,rig=pcall(function()
            return Factory.Build({Category=info.category,Mutations={},Scale=1},true)
        end)
        if ok and typeof(rig)=='Instance' and rig:IsA('Model') then
            return prepare(rig,name)
        end
    end
    local models=RS:FindFirstChild('AssetModels')
    local src=models and models:FindFirstChild(info.category)
    if src and src:IsA('Model') then
        local ok,rig=pcall(function() return src:Clone() end)
        if ok then return prepare(rig,name) end
    end
end

for name,info in pairs(DEF) do
    local rig=buildExact(name,info)
    if rig then
        rig.Parent=nil
        templates[name]=rig
        print('[SAE] Exact game rig ready: '..name..' ('..info.category..')')
    else
        warn('[SAE] Exact replicated rig unavailable: '..name..' / '..info.category)
    end
end

local function fit(m,target)
    local ok,sz=pcall(function() return m:GetExtentsSize() end)
    if ok and sz then
        local mx=math.max(sz.X,sz.Y,sz.Z)
        if mx>.01 then pcall(function() m:ScaleTo(target/mx) end) end
    end
end

local function placeTool(tool,model)
    local c=model:Clone()
    local folder=workspace:FindFirstChild('SAE_V7_PLACED')
    if not folder then
        folder=Instance.new('Folder')
        folder.Name='SAE_V7_PLACED'
        folder.Parent=workspace
    end
    c.Parent=folder
    for _,p in ipairs(allParts(c)) do
        p.Anchored=true
        p.CanCollide=false
        p.CanTouch=false
        p.CanQuery=true
    end
    local mouse=P:GetMouse()
    local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
    local pos=(mouse and mouse.Hit and mouse.Hit.Position)
        or (hrp and (hrp.Position+hrp.CFrame.LookVector*9)) or Vector3.zero
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={P.Character,folder}
    local hit=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rp)
    if hit then pos=hit.Position end
    c:PivotTo(CFrame.new(pos))
    local cf,sz=c:GetBoundingBox()
    c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))
    tool:Destroy()
end

local busy={}
local function replace(tool)
    if not tool or not tool:IsA('Tool') then return end
    local info=DEF[tool.Name]
    if not info or tool:GetAttribute('SAE_EXACT_PET_FINAL') or busy[tool] then return end
    local template=templates[tool.Name]
    if not template then return end
    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name=tool.Name
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_PET_FINAL',true)

        local handle=Instance.new('Part')
        handle.Name='Handle'
        handle.Size=Vector3.new(.4,.4,.4)
        handle.Transparency=1
        handle.Anchored=false
        handle.CanCollide=false
        handle.CanTouch=false
        handle.CanQuery=false
        handle.Massless=true
        handle.Parent=new

        local model=template:Clone()
        fit(model,info.size)
        model.Parent=new
        model:PivotTo(handle.CFrame*info.offset)
        local root=model.PrimaryPart or model:FindFirstChild('HumanoidRootPart',true)
            or model:FindFirstChildWhichIsA('BasePart',true)
        if not root then new:Destroy() busy[tool]=nil return end
        model.PrimaryPart=root
        for _,p in ipairs(allParts(model)) do
            p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
        end
        local weld=Instance.new('WeldConstraint')
        weld.Part0=handle
        weld.Part1=root
        weld.Parent=handle

        new.Activated:Connect(function()
            if new.Parent==P.Character then placeTool(new,model) end
        end)

        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and DEF[child.Name] then task.wait() replace(child) end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') and DEF[child.Name] then replace(child) end
    end
end

watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(char) task.wait(.2) watch(char) end)
