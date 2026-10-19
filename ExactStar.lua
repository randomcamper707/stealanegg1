-- Final held Star replacement for Steal An Egg
-- Prefer a real visible game Star asset; otherwise build the supplied chunky tan reference in 3D.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local StarterPack=game:GetService('StarterPack')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local function norm(v)return tostring(v or ''):lower():gsub('[^%w]','')end
local NAMES={star=true,mountstar=true,shootingstar=true,divinestar=true,goldenstar=true,goldstar=true,staritem=true}

local function allParts(o)
    local t={}
    if o:IsA('BasePart') then t[#t+1]=o end
    for _,d in ipairs(o:GetDescendants()) do if d:IsA('BasePart') then t[#t+1]=d end end
    return t
end

local function cleanClone(src)
    local ok,c=pcall(function()return src:Clone()end)
    if not ok or not c then return nil end
    local m
    if c:IsA('Model') then m=c
    elseif c:IsA('Tool') or c:IsA('Folder') then
        m=Instance.new('Model')
        for _,x in ipairs(c:GetChildren())do
            if not x:IsA('Script') and not x:IsA('LocalScript') and not x:IsA('ModuleScript') then x.Parent=m end
        end
        c:Destroy()
    elseif c:IsA('BasePart') then
        m=Instance.new('Model') c.Parent=m
    else c:Destroy() return nil end
    local kill={}
    for _,d in ipairs(m:GetDescendants())do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript') or d:IsA('Humanoid')
            or d:IsA('Animator') or d:IsA('BillboardGui') or d:IsA('SurfaceGui')
            or d:IsA('ProximityPrompt') or d:IsA('ClickDetector') then kill[#kill+1]=d
        elseif d:IsA('BasePart') then
            d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
        end
    end
    for _,d in ipairs(kill)do d:Destroy()end
    local root=m.PrimaryPart or m:FindFirstChildWhichIsA('BasePart',true)
    if not root then m:Destroy() return nil end
    m.PrimaryPart=root m.Name='Star'
    return m
end

local function findNativeStar()
    local best,bestScore=nil,-math.huge
    local seen={}
    local function consider(o,bonus)
        if not o or (P.Character and o:IsDescendantOf(P.Character)) or o:IsDescendantOf(BP) then return end
        local root=o
        if o:IsA('BasePart') then root=o:FindFirstAncestorOfClass('Model') or o:FindFirstAncestorOfClass('Tool') or o end
        if not (root:IsA('Model') or root:IsA('Tool') or root:IsA('Folder') or root:IsA('BasePart')) or seen[root] then return end
        seen[root]=true
        local score=0
        if NAMES[norm(o.Name)] or NAMES[norm(root.Name)] then score=2600 end
        for _,key in ipairs({'DisplayName','ItemName','Title','Type','Name'})do
            local ok,v=pcall(function()return o:GetAttribute(key)end)
            if ok and v and NAMES[norm(v)] then score=math.max(score,2400) end
        end
        if score==0 then return end
        local visible,gold,mesh=0,0,0
        for _,p in ipairs(allParts(root))do
            if p.Transparency<.9 then
                visible=visible+1
                if p.Color.R>.5 and p.Color.G>.35 and p.Color.B<.65 then gold=gold+1 end
            end
            if p:IsA('MeshPart') then mesh=mesh+1 end
        end
        if visible==0 then return end
        local full=norm(root:GetFullName())
        if full:find('gui',1,true) or full:find('icon',1,true) or full:find('vfx',1,true) or full:find('effect',1,true) then score=score-1800 end
        score=score+(bonus or 0)+visible*3+gold*30+mesh*90+(root:IsA('Tool') and 500 or 0)
        if score>bestScore then best,bestScore=root,score end
    end
    for _,set in ipairs({{StarterPack,800},{RS,500},{workspace,0}})do
        local list=set[1]:GetDescendants()
        for i,o in ipairs(list)do consider(o,set[2]) if i%3500==0 then task.wait()end end
    end
    if type(getinstances)=='function' then
        local ok,list=pcall(getinstances)
        if ok and type(list)=='table' then for i,o in ipairs(list)do if typeof(o)=='Instance' then consider(o,150)end if i%5000==0 then task.wait()end end end
    end
    if type(getnilinstances)=='function' then
        local ok,list=pcall(getnilinstances)
        if ok and type(list)=='table' then for i,o in ipairs(list)do if typeof(o)=='Instance' then consider(o,250)end if i%5000==0 then task.wait()end end end
    end
    if best and bestScore>2300 then return cleanClone(best) end
end

local function part(m,name,size,color,cf,shape)
    local p=Instance.new('Part')
    p.Name=name p.Size=size p.Color=color p.CFrame=cf or CFrame.new()
    p.Material=Enum.Material.SmoothPlastic p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
    p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
    if shape then p.Shape=shape end
    p.Parent=m return p
end

local function wedge(m,name,size,color,cf)
    local p=Instance.new('WedgePart')
    p.Name=name p.Size=size p.Color=color p.CFrame=cf p.Material=Enum.Material.SmoothPlastic
    p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Parent=m
    return p
end

local function line(m,a,b,width,color,z)
    local mid=(a+b)/2
    local d=b-a
    return part(m,'Mouth',Vector3.new(width,width,d.Magnitude),color,CFrame.lookAt(Vector3.new(mid.X,mid.Y,z),Vector3.new(b.X,b.Y,z)))
end

local function referenceStar()
    local m=Instance.new('Model') m.Name='Star'
    local tan=Color3.fromRGB(184,161,101)
    local raised=Color3.fromRGB(198,176,112)
    local dark=Color3.fromRGB(27,25,22)
    local white=Color3.fromRGB(250,250,248)
    local depth=.9
    local root=part(m,'Core',Vector3.new(2.85,2.75,depth),tan,CFrame.new())

    -- Five broad points: chunky proportions from the supplied reference, not the old thin star.
    for i=0,4 do
        local a=math.rad(90-i*72)
        local x,y=math.cos(a)*2.05,math.sin(a)*2.05
        wedge(m,'StarPoint',Vector3.new(2.35,3.15,depth),tan,
            CFrame.new(x,y,0)*CFrame.Angles(0,(i==1 or i==2) and math.rad(180) or 0,a-math.rad(90)))
    end

    local faceZ=-(depth/2+.11)
    local studs={
        {-1.05,1.65},{.1,1.82},{1.05,1.22},{-1.72,.9},{-.64,.88},{.43,.9},{1.55,.68},
        {-1.98,.02},{-1.02,.1},{.02,.27},{1.03,.1},{1.96,.02},{-1.48,-.77},{-.55,-.72},
        {.57,-.76},{1.48,-.8},{-.72,-1.56},{.42,-1.63}
    }
    for _,s in ipairs(studs)do part(m,'RaisedStud',Vector3.new(.57,.36,.22),raised,CFrame.new(s[1],s[2],faceZ))end

    part(m,'EyeL',Vector3.new(.7,1.0,.24),dark,CFrame.new(-.82,.12,faceZ-.14),Enum.PartType.Ball)
    part(m,'EyeR',Vector3.new(.7,1.0,.24),dark,CFrame.new(.82,.12,faceZ-.14),Enum.PartType.Ball)
    part(m,'EyeHighlightL',Vector3.new(.18,.18,.12),white,CFrame.new(-.69,.43,faceZ-.27),Enum.PartType.Ball)
    part(m,'EyeHighlightR',Vector3.new(.18,.18,.12),white,CFrame.new(.95,.43,faceZ-.27),Enum.PartType.Ball)

    local mouth={Vector2.new(-.42,-.52),Vector2.new(-.2,-.74),Vector2.new(0,-.58),Vector2.new(.2,-.74),Vector2.new(.42,-.52)}
    for i=1,#mouth-1 do line(m,mouth[i],mouth[i+1],.10,dark,faceZ-.18) end

    m.PrimaryPart=root
    for _,p in ipairs(allParts(m))do
        if p~=root then local w=Instance.new('WeldConstraint') w.Part0=root w.Part1=p w.Parent=root end
    end
    m:SetAttribute('SAE_REFERENCE_STAR',true)
    return m
end

local template=findNativeStar()
if template then
    print('[SAE] Native visible Star model selected.')
else
    template=referenceStar()
    print('[SAE] Using reference-matched solid 3D Star fallback.')
end
template.Parent=nil

local function fit(m,target)
    local ok,sz=pcall(function()return m:GetExtentsSize()end)
    if ok and sz then local mx=math.max(sz.X,sz.Y,sz.Z) if mx>.01 then pcall(function()m:ScaleTo(target/mx)end)end end
end

local busy={}
local function replace(tool)
    if not tool or not tool:IsA('Tool') or tool.Name~='Star' or tool:GetAttribute('SAE_EXACT_STAR_FINAL') or busy[tool] then return end
    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name='Star' new.RequiresHandle=true new.CanBeDropped=false new.TextureId=tool.TextureId or ''
        new:SetAttribute('SAE_V7_TOOL',true) new:SetAttribute('SAE_EXACT_STAR_FINAL',true)
        local h=part(new,'Handle',Vector3.new(.4,.4,.4),Color3.new(),CFrame.new())
        h.Transparency=1
        local model=template:Clone() fit(model,7.1) model.Parent=new
        model:PivotTo(h.CFrame*CFrame.new(-.28,.48,-1.32)*CFrame.Angles(0,math.rad(180),0))
        local root=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart',true)
        if not root then new:Destroy() busy[tool]=nil return end
        for _,p in ipairs(allParts(model))do p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true end
        local w=Instance.new('WeldConstraint') w.Part0=h w.Part1=root w.Parent=h
        new.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)
        tool:Destroy() new.Parent=parent busy[tool]=nil
    end)
end

local function watch(container)
    if not container then return end
    container.ChildAdded:Connect(function(c)if c:IsA('Tool') and c.Name=='Star' then task.wait() replace(c) end end)
    for _,c in ipairs(container:GetChildren())do if c:IsA('Tool') and c.Name=='Star' then replace(c) end end
end
watch(BP) watch(P.Character)
P.CharacterAdded:Connect(function(c)task.wait(.2)watch(c)end)
