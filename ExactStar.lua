-- Final held Star replacement for Steal An Egg
-- Uses the supplied chunky tan reference and manually follows the player's hand
-- so the Star is always visible instead of relying on Tool grip orientation.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local function allParts(o)
    local t={}
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA('BasePart') then t[#t+1]=d end
    end
    return t
end

local function part(m,name,size,color,cf,shape)
    local p=Instance.new('Part')
    p.Name=name
    p.Size=size
    p.Color=color
    p.CFrame=cf or CFrame.new()
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Massless=true
    if shape then p.Shape=shape end
    p.Parent=m
    return p
end

local function wedge(m,name,size,color,cf)
    local p=Instance.new('WedgePart')
    p.Name=name
    p.Size=size
    p.Color=color
    p.CFrame=cf
    p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Massless=true
    p.Parent=m
    return p
end

local function line(m,a,b,width,color,z)
    local mid=(a+b)/2
    local d=b-a
    return part(m,'Mouth',Vector3.new(width,width,d.Magnitude),color,CFrame.lookAt(Vector3.new(mid.X,mid.Y,z),Vector3.new(b.X,b.Y,z)))
end

local function referenceStar()
    local m=Instance.new('Model')
    m.Name='Star'

    local tan=Color3.fromRGB(191,166,99)
    local raised=Color3.fromRGB(205,183,116)
    local dark=Color3.fromRGB(31,29,24)
    local white=Color3.fromRGB(252,252,248)
    local depth=.82

    local root=part(m,'Core',Vector3.new(2.75,2.75,depth),tan,CFrame.new())

    for i=0,4 do
        local a=math.rad(90-i*72)
        local x,y=math.cos(a)*1.88,math.sin(a)*1.88
        wedge(m,'StarPoint',Vector3.new(2.28,3.06,depth),tan,
            CFrame.new(x,y,0)*CFrame.Angles(0,(i==1 or i==2) and math.rad(180) or 0,a-math.rad(90)))
    end

    local faceZ=-(depth/2+.105)
    local studs={
        {-1.00,1.55},{.05,1.70},{1.02,1.17},
        {-1.62,.82},{-.62,.83},{.38,.84},{1.47,.62},
        {-1.87,.02},{-.94,.08},{.00,.22},{.94,.08},{1.85,.01},
        {-1.42,-.69},{-.52,-.66},{.54,-.69},{1.39,-.73},
        {-.70,-1.46},{.38,-1.50}
    }
    for _,s in ipairs(studs) do
        part(m,'RaisedStud',Vector3.new(.53,.34,.20),raised,CFrame.new(s[1],s[2],faceZ))
    end

    part(m,'EyeL',Vector3.new(.63,.88,.22),dark,CFrame.new(-.79,.14,faceZ-.13),Enum.PartType.Ball)
    part(m,'EyeR',Vector3.new(.63,.88,.22),dark,CFrame.new(.79,.14,faceZ-.13),Enum.PartType.Ball)
    part(m,'EyeHighlightL',Vector3.new(.16,.16,.10),white,CFrame.new(-.66,.40,faceZ-.25),Enum.PartType.Ball)
    part(m,'EyeHighlightR',Vector3.new(.16,.16,.10),white,CFrame.new(.92,.40,faceZ-.25),Enum.PartType.Ball)

    local mouth={
        Vector2.new(-.38,-.46),Vector2.new(-.18,-.66),
        Vector2.new(0,-.53),Vector2.new(.18,-.66),Vector2.new(.38,-.46)
    }
    for i=1,#mouth-1 do
        line(m,mouth[i],mouth[i+1],.095,dark,faceZ-.17)
    end

    m.PrimaryPart=root
    m:SetAttribute('SAE_REFERENCE_STAR',true)
    return m
end

local template=referenceStar()
template.Parent=nil

local function fit(m,target)
    local ok,sz=pcall(function() return m:GetExtentsSize() end)
    if ok and sz then
        local mx=math.max(sz.X,sz.Y,sz.Z)
        if mx>.01 then pcall(function() m:ScaleTo(target/mx) end) end
    end
end

local busy={}
local liveConnections={}

local function disconnect(tool)
    local c=liveConnections[tool]
    if c then pcall(function() c:Disconnect() end) end
    liveConnections[tool]=nil
end

local function attachVisual(tool,model)
    disconnect(tool)

    local function update()
        if not tool.Parent or tool.Parent~=P.Character or not model.Parent then return end
        local ch=P.Character
        if not ch then return end
        local hand=ch:FindFirstChild('RightHand') or ch:FindFirstChild('Right Arm')
        local hrp=ch:FindFirstChild('HumanoidRootPart')
        if not hand or not hrp then return end

        local pos=hand.Position
            +hrp.CFrame.UpVector*1.45
            +hrp.CFrame.RightVector*.08
            +hrp.CFrame.LookVector*.18

        local cf=CFrame.lookAt(pos,pos+hrp.CFrame.LookVector,hrp.CFrame.UpVector)
            *CFrame.Angles(0,0,math.rad(-5))
        model:PivotTo(cf)
    end

    local function start()
        update()
        disconnect(tool)
        liveConnections[tool]=RunService.RenderStepped:Connect(update)
    end

    tool.Equipped:Connect(start)
    tool.Unequipped:Connect(function() disconnect(tool) end)
    tool.Destroying:Connect(function() disconnect(tool) end)

    -- Covers the case where the replacement happens while the original Star is already equipped.
    task.defer(function()
        if tool.Parent==P.Character then start() end
    end)
end

local function replace(tool)
    if not tool or not tool:IsA('Tool') or tool.Name~='Star'
        or tool:GetAttribute('SAE_EXACT_STAR_FINAL') or busy[tool] then return end

    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent

        local new=Instance.new('Tool')
        new.Name='Star'
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_STAR_FINAL',true)

        local h=Instance.new('Part')
        h.Name='Handle'
        h.Size=Vector3.new(.4,.4,.4)
        h.Transparency=1
        h.Anchored=false
        h.CanCollide=false
        h.CanTouch=false
        h.CanQuery=false
        h.Massless=true
        h.Parent=new

        local model=template:Clone()
        fit(model,5.8)
        model.Parent=new
        for _,p in ipairs(allParts(model)) do
            p.Anchored=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Massless=true
        end

        new.Grip=CFrame.new()
        attachVisual(new,model)

        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(container)
    if not container then return end
    container.ChildAdded:Connect(function(c)
        if c:IsA('Tool') and c.Name=='Star' then task.wait() replace(c) end
    end)
    for _,c in ipairs(container:GetChildren()) do
        if c:IsA('Tool') and c.Name=='Star' then replace(c) end
    end
end

watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(c) task.wait(.2) watch(c) end)
print('[SAE] Reference Star hand placement ready.')