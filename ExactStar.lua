-- Final held Star replacement for Steal An Egg.
-- The visible front is taken directly from the supplied Star reference instead of
-- redrawing the eyes, mouth, studs, proportions, or colour by hand.
-- A solid tan backing provides real 3D thickness while the exact reference face
-- is shown on the front. Designed for the Real PC executor used by both testers.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local REFERENCE_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/StarReference.b64?v='..tostring(os.time())
local LOCAL_FILE='sae_exact_star_reference.png'

local function pureBase64Decode(data)
    local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data=tostring(data or ''):gsub('[^'..alphabet..'=]','')
    return (data:gsub('.',function(x)
        if x=='=' then return '' end
        local p=alphabet:find(x,1,true)
        if not p then return '' end
        local f=p-1
        local r=''
        for i=6,1,-1 do
            r=r..((f%2^i-f%2^(i-1)>0) and '1' or '0')
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
        if #x~=8 then return '' end
        local c=0
        for i=1,8 do
            if x:sub(i,i)=='1' then c=c+2^(8-i) end
        end
        return string.char(c)
    end))
end

local function getReferenceAsset()
    local assetLoader=getcustomasset or getsynasset
    if type(assetLoader)~='function' or type(writefile)~='function' then
        warn('[SAE] Exact Star reference requires writefile + getcustomasset support.')
        return nil
    end

    local ok,b64=pcall(function()
        return game:HttpGet(REFERENCE_URL,true)
    end)
    if not ok or type(b64)~='string' or #b64<1000 then
        warn('[SAE] Could not download exact Star reference.')
        return nil
    end

    local decoder=base64_decode or base64decode
    if not decoder and type(base64)=='table' then decoder=base64.decode end
    if not decoder and type(crypt)=='table' and type(crypt.base64)=='table' then decoder=crypt.base64.decode end

    local bytes
    local decoded=pcall(function()
        bytes=(type(decoder)=='function') and decoder(b64) or pureBase64Decode(b64)
    end)
    if not decoded or type(bytes)~='string' or #bytes<1000 then
        warn('[SAE] Could not decode exact Star reference.')
        return nil
    end

    local wrote=pcall(function() writefile(LOCAL_FILE,bytes) end)
    if not wrote then
        warn('[SAE] Could not prepare exact Star reference file.')
        return nil
    end

    local loaded,asset=pcall(function() return assetLoader(LOCAL_FILE) end)
    if not loaded or type(asset)~='string' or asset=='' then
        warn('[SAE] Could not load exact Star reference as a custom asset.')
        return nil
    end
    return asset
end

local REFERENCE_ASSET=getReferenceAsset()

local function allParts(o)
    local t={}
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA('BasePart') then t[#t+1]=d end
    end
    return t
end

local function part(m,name,size,color,cf,transparency)
    local p=Instance.new('Part')
    p.Name=name
    p.Size=size
    p.Color=color
    p.CFrame=cf or CFrame.new()
    p.Transparency=transparency or 0
    p.Material=Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Massless=true
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

local function makeReferenceStar()
    local m=Instance.new('Model')
    m.Name='Star'

    -- The backing is deliberately plain. All visible face/stud artwork comes
    -- from the user's supplied reference image rather than a recreated design.
    local tan=Color3.fromRGB(190,166,104)
    local depth=.72
    local root=part(m,'Core',Vector3.new(2.65,2.55,depth),tan,CFrame.new())

    for i=0,4 do
        local a=math.rad(90-i*72)
        local x,y=math.cos(a)*1.76,math.sin(a)*1.76
        wedge(m,'SolidStarPoint',Vector3.new(2.18,2.9,depth),tan,
            CFrame.new(x,y,.03)*CFrame.Angles(0,(i==1 or i==2) and math.rad(180) or 0,a-math.rad(90)))
    end

    -- 112x95 reference => 1.178947 aspect ratio. This keeps its exact proportions.
    local width=5.95
    local height=width*(95/112)
    local face=part(m,'ExactReferenceFace',Vector3.new(width,height,.035),Color3.new(1,1,1),CFrame.new(0,0,-depth/2-.035),1)

    if REFERENCE_ASSET then
        local gui=Instance.new('SurfaceGui')
        gui.Name='ExactStarReference'
        gui.Face=Enum.NormalId.Front
        gui.AlwaysOnTop=false
        gui.LightInfluence=0
        gui.Brightness=1
        gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
        gui.CanvasSize=Vector2.new(112,95)
        gui.Adornee=face
        gui.Parent=face

        local image=Instance.new('ImageLabel')
        image.Name='ReferenceImage'
        image.BackgroundTransparency=1
        image.Size=UDim2.fromScale(1,1)
        image.Position=UDim2.fromScale(0,0)
        image.Image=REFERENCE_ASSET
        image.ScaleType=Enum.ScaleType.Fit
        image.ResampleMode=Enum.ResamplerMode.Pixelated
        image.Parent=gui
    else
        -- Keep the solid body visible rather than substituting another invented face.
        face.Transparency=1
    end

    m.PrimaryPart=root
    m:SetAttribute('SAE_REFERENCE_STAR',true)
    m:SetAttribute('SAE_EXACT_IMAGE_FACE',REFERENCE_ASSET~=nil)
    return m
end

local template=makeReferenceStar()
template.Parent=nil

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

        -- Match the supplied holding reference: large Star raised beside the face,
        -- with the lower-left area overlapping the player's hand.
        local pos=hand.Position
            +hrp.CFrame.UpVector*1.45
            +hrp.CFrame.RightVector*.04
            +hrp.CFrame.LookVector*.12

        local cf=CFrame.lookAt(pos,pos+hrp.CFrame.LookVector,hrp.CFrame.UpVector)
            *CFrame.Angles(0,0,math.rad(-3))
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
        h.Size=Vector3.new(.35,.35,.35)
        h.Transparency=1
        h.Anchored=false
        h.CanCollide=false
        h.CanTouch=false
        h.CanQuery=false
        h.Massless=true
        h.Parent=new

        local model=template:Clone()
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
print('[SAE] Exact supplied Star reference ready in hand.')