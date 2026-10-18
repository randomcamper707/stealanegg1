                            if norm(v.Name)==norm(name) then score=score+1500 end
                            local pc=#allParts(v)
                            score=score+math.min(pc,80)
                            if score>bestScore then bestScore=score best=v end
                        end
                    end
                end
            end
        end
    end
    if best then sourceCache[ck]=best end
    return best
end

local function stripScripts(o)
    local kill={}
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript') or d:IsA('Humanoid') or d:IsA('Animator') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector') then
            kill[#kill+1]=d
        end
    end
    for _,d in ipairs(kill) do pcall(function() d:Destroy() end) end
end

local function wrapVisual(c,name)
    if not c then return nil end
    if c:IsA('Model') then c.Name=name return c end
    local m=Instance.new('Model')
    m.Name=name
    if c:IsA('Tool') or c:IsA('Accessory') or c:IsA('Folder') then
        for _,q in ipairs(c:GetChildren()) do q.Parent=m end
        c:Destroy()
    else
        c.Parent=m
    end
    if not hasParts(m) then m:Destroy() return nil end
    return m
end

local function cloneExact(src,name)
    if not src then return nil end
    local ok,c=pcall(function() return src:Clone() end)
    if not ok or not c then return nil end
    stripScripts(c)
    c=wrapVisual(c,name)
    if not c then return nil end
    c:SetAttribute('SAE_V6_EXACT',true)
    return c
end

local function modelSize(m)
    local ok,s=pcall(function() return m:GetExtentsSize() end)
    if ok and s then return s end
    return Vector3.new(4,4,4)
end

local function fitModel(m,target)
    local s=modelSize(m)
    local mx=math.max(s.X,s.Y,s.Z)
    if mx>.01 then
        local f=math.clamp(target/mx,.08,8)
        pcall(function() m:ScaleTo(f) end)
    end
end

local REF_SOURCE_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/6f14a6070a1207346018d4283037d2bc539c0b1d/Main.lua'
local refSource=nil
local refInfoCache={}

local function getRefInfo(key)
    if refInfoCache[key] then return refInfoCache[key] end
    if not refSource then
        local ok,s=pcall(function() return game:HttpGet(REF_SOURCE_URL) end)
        if not ok or type(s)~='string' then return nil end
        refSource=s
    end
    local needle='["'..key..'"]={w='
    local a=refSource:find(needle,1,true)
    if not a then return nil end
    local ds=refSource:find('data=[[',a,true)
    if not ds then return nil end
    local de=refSource:find(']]}',ds+7,true)
    if not de then return nil end
    local header=refSource:sub(a,ds-1)
    local w,h=header:match('w=(%d+),h=(%d+)')
    local data=refSource:sub(ds+7,de-1)
    if not w or not h or data=='' then return nil end
    local info={w=tonumber(w),h=tonumber(h),data=data}
    refInfoCache[key]=info
    return info
end

local B64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local BLOOK={}
for i=1,#B64 do BLOOK[B64:sub(i,i)]=i-1 end
local function decode64(data)
    data=tostring(data or ''):gsub('%s','')
    local out={}
    local oi=0
    local i=1
    while i<=#data do
        local a=BLOOK[data:sub(i,i)] or 0
        local b=BLOOK[data:sub(i+1,i+1)] or 0
        local c3=data:sub(i+2,i+2)
        local c4=data:sub(i+3,i+3)
        local c=BLOOK[c3] or 0
        local d=BLOOK[c4] or 0
        local n=a*262144+b*4096+c*64+d
        oi=oi+1 out[oi]=string.char(math.floor(n/65536)%256)
        if c3~='=' and c3~='' then oi=oi+1 out[oi]=string.char(math.floor(n/256)%256) end
        if c4~='=' and c4~='' then oi=oi+1 out[oi]=string.char(n%256) end
        i=i+4
        if i%65536==1 then task.wait() end
    end
    return table.concat(out)
end

local assetCache={}
local function refAsset(item)
    if assetCache[item.key] then return assetCache[item.key] end
    if not WRITEFILE or not GETASSET then return nil end
    local info=getRefInfo(item.key)
    if not info then return nil end
    local fn='SAE_V6_'..item.key..'.png'
    local exists=false
    if ISFILE then pcall(function() exists=ISFILE(fn) end) end
    if not exists then
        local ok=pcall(function() WRITEFILE(fn,decode64(info.data)) end)
        if not ok then return nil end
    end
    local ok,a=pcall(function() return GETASSET(fn) end)
    if ok and a and tostring(a)~='' then assetCache[item.key]=a return a end
end

local function surfaceImage(part,face,asset,w,h)
    local sg=Instance.new('SurfaceGui')
    sg.Name='ReferenceFace'
    sg.Adornee=part
    sg.Face=face
    sg.AlwaysOnTop=false
    sg.LightInfluence=0
    sg.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
    sg.CanvasSize=Vector2.new(w,h)
    sg.Parent=part
    local im=Instance.new('ImageLabel')
    im.BackgroundTransparency=1
    im.Size=UDim2.fromScale(1,1)
    im.Image=asset
    im.ScaleType=Enum.ScaleType.Fit
    im.Parent=sg
end

local function makeReferenceVolume(category,item)
    local asset=refAsset(item)
    local info=getRefInfo(item.key)
    if not asset or not info then return nil end
    local targetH=category=='Pets' and 16 or category=='Eggs' and 10.5 or 6
    local aspect=math.clamp(info.w/info.h,.35,2.8)
    local width=targetH*aspect
    local depth=category=='Pets' and math.max(1.9,width*.16) or category=='Eggs' and math.max(1.35,width*.18) or .95
    local m=Instance.new('Model')
    m.Name=item.name
    m:SetAttribute('SAE_V6_REFERENCE_SHELL',true)
    local root=Instance.new('Part')
    root.Name='Root'
    root.Size=Vector3.new(.12,.12,.12)
    root.Transparency=1
    root.Anchored=true
    root.CanCollide=false
    root.CanTouch=false
    root.CanQuery=false
    root.Massless=true
    root.Parent=m
    m.PrimaryPart=root
    local layers=7
    for i=1,layers do
        local z=-depth/2+(i-1)*(depth/(layers-1))
        local p=Instance.new('Part')
        p.Name='ReferenceLayer'
        p.Size=Vector3.new(width,targetH,.035)
        p.Transparency=1
        p.Anchored=true
        p.CanCollide=false
        p.CanTouch=false
        p.CanQuery=false
        p.Massless=true
        p.CFrame=CFrame.new(0,0,z)
        p.Parent=m
        surfaceImage(p,Enum.NormalId.Front,asset,info.w,info.h)
        surfaceImage(p,Enum.NormalId.Back,asset,info.w,info.h)
    end
    for _,ang in ipairs({-22,22}) do
        local p=Instance.new('Part')
        p.Name='ReferenceDepthLayer'
        p.Size=Vector3.new(width,targetH,.035)
        p.Transparency=1
        p.Anchored=true
        p.CanCollide=false
        p.CanTouch=false
        p.CanQuery=false
        p.Massless=true
        p.CFrame=CFrame.Angles(0,math.rad(ang),0)
        p.Parent=m
        surfaceImage(p,Enum.NormalId.Front,asset,info.w,info.h)
        surfaceImage(p,Enum.NormalId.Back,asset,info.w,info.h)
    end
    return m
end

local function weldModel(m,root)
    for _,q in ipairs(allParts(m)) do
        q.Anchored=false
        q.CanCollide=false
        q.CanTouch=false
        q.CanQuery=false
        q.Massless=true
        if q~=root then
            local w=Instance.new('WeldConstraint')
            w.Name='SAE_V6_INTERNAL'
            w.Part0=root
            w.Part1=q
            w.Parent=root
        end
    end
end

local function centerModelAt(m,target)
    m:PivotTo(target)
    local ok,cf=pcall(function() local b=m:GetBoundingBox() return b end)
    if ok and cf then
        local delta=target.Position-cf.Position
        m:PivotTo(m:GetPivot()+delta)
    end
end

local heldByKey={}
local function destroyHeld(tool)
    local key=tool and tool:GetAttribute('SAE_V6_ID')
    if key and heldByKey[key] then
        pcall(function() heldByKey[key]:Destroy() end)
        heldByKey[key]=nil
    end
end

local function buildVisual(category,item)
    if category=='Star' then
