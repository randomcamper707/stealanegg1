from pathlib import Path
import re

p = Path('Main.lua')
s = p.read_text(encoding='utf-8')

block = re.search(
    r"local EXACT_STAR_SOURCE=\[============\[\n.*?local EMBEDDED_REFERENCE_B64=\[========\[\n(.*?)\n\]========\].*?\n\]============\]\n\nlocal FINAL_POLISH_SOURCE",
    s,
    re.S,
)
if not block:
    raise SystemExit('EXACT_STAR_SOURCE block not found')

b64 = block.group(1)

prefix = r'''local EXACT_STAR_SOURCE=[============[
-- Final held Star system.
-- Priority: clone a genuine client-replicated 3D Star if one exists.
-- Otherwise render the exact supplied Star reference image locked to the right hand.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local StarterPack=game:GetService('StarterPack')
local P=Players.LocalPlayer
if not P then return end
local PG=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not PG or not BP then return end

local EMBEDDED_REFERENCE_B64=[========[
'''

suffix = r'''
]========]

local B64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function pureBase64Decode(data)
    data=data:gsub('[^'..B64..'=]','')
    return (data:gsub('.',function(x)
        if x=='=' then return '' end
        local r,f='',(B64:find(x,1,true)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
        if #x~=8 then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local RAW_BYTES
pcall(function()
    if crypt and crypt.base64 and crypt.base64.decode then
        RAW_BYTES=crypt.base64.decode(EMBEDDED_REFERENCE_B64)
    elseif syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then
        RAW_BYTES=syn.crypt.base64.decode(EMBEDDED_REFERENCE_B64)
    end
end)
if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 then
    local ok,v=pcall(pureBase64Decode,EMBEDDED_REFERENCE_B64)
    if ok then RAW_BYTES=v end
end

local function makeCustomAsset()
    if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 or type(writefile)~='function' then return nil end
    local loader=getcustomasset or getsynasset
    if not loader and syn then loader=syn.getcustomasset or syn.getsynasset end
    if type(loader)~='function' then return nil end
    local file='sae_exact_star_reference.png'
    local okWrite=pcall(function() writefile(file,RAW_BYTES) end)
    if not okWrite then return nil end
    local ok,a=pcall(function() return loader(file) end)
    if ok and type(a)=='string' and a~='' then return a end
end
local CUSTOM_ASSET=makeCustomAsset()

local DRAWING_SUPPORTED=false
local function newDrawingImage()
    if not Drawing or type(Drawing.new)~='function' or type(RAW_BYTES)~='string' or #RAW_BYTES<1000 then return nil end
    local ok,img=pcall(function()
        local d=Drawing.new('Image')
        d.Data=RAW_BYTES
        d.Size=Vector2.new(230,195)
        d.Position=Vector2.new(0,0)
        d.Transparency=1
        d.Visible=false
        return d
    end)
    if ok and img then return img end
end

do
    local test=newDrawingImage()
    if test then
        DRAWING_SUPPORTED=true
        pcall(function() test.Visible=false test:Remove() end)
    end
end

local function cleanClone(src)
    local c=src:Clone()
    local model
    if c:IsA('Model') then
        model=c
    elseif c:IsA('Tool') then
        model=Instance.new('Model')
        model.Name='Star'
        for _,ch in ipairs(c:GetChildren()) do ch.Parent=model end
        c:Destroy()
    elseif c:IsA('BasePart') then
        model=Instance.new('Model')
        model.Name='Star'
        c.Parent=model
    else
        c:Destroy()
        return nil
    end
    local parts={}
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript') or d:IsA('Humanoid')
            or d:IsA('BillboardGui') or d:IsA('SurfaceGui') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector') then
            pcall(function() d:Destroy() end)
        elseif d:IsA('BasePart') then
            d.Anchored=false
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=false
            d.Massless=true
            parts[#parts+1]=d
        end
    end
    if #parts==0 then model:Destroy() return nil end
    model.PrimaryPart=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart',true)
    model.Name='Star'
    return model
end

local function norm(s)
    return tostring(s or ''):lower():gsub('[^%w]','')
end

local function nativeScore(x)
    if not (x:IsA('Model') or x:IsA('Tool') or x:IsA('MeshPart') or x:IsA('Part')) then return -math.huge end
    if x:IsDescendantOf(P) then return -math.huge end
    if x:GetAttribute('SAE_V7_TOOL') or x:GetAttribute('SAE_EXACT_STAR_OVERLAY') then return -math.huge end
    local n=norm(x.Name)
    if n~='star' and n~='staritem' and n~='heldstar' and n~='goldstar' then return -math.huge end
    local ancestry=norm(x.Parent and x.Parent.Name)
    if ancestry:find('egg',1,true) or ancestry:find('gui',1,true) or ancestry:find('icon',1,true) then return -math.huge end
    local score=(n=='star' and 100 or 60)
    if x:IsA('MeshPart') then score=score+90 end
    local meshCount=0
    local partCount=0
    for _,d in ipairs(x:GetDescendants()) do
        if d:IsA('MeshPart') then meshCount=meshCount+1 end
        if d:IsA('BasePart') then partCount=partCount+1 end
    end
    score=score+math.min(meshCount,12)*18+math.min(partCount,30)
    if x:IsDescendantOf(RS) then score=score+50 end
    return score
end

local function findNativeStar()
    local best,bestScore=nil,-math.huge
    local function consider(x)
        local sc=nativeScore(x)
        if sc>bestScore then best,bestScore=x,sc end
    end
    for _,root in ipairs({RS,Lighting,StarterPack,workspace}) do
        consider(root)
        for _,x in ipairs(root:GetDescendants()) do consider(x) end
    end
    if type(getinstances)=='function' then
        local ok,list=pcall(getinstances)
        if ok and type(list)=='table' then
            for _,x in ipairs(list) do if typeof(x)=='Instance' then consider(x) end end
        end
    end
    if type(getnilinstances)=='function' then
        local ok,list=pcall(getnilinstances)
        if ok and type(list)=='table' then
            for _,x in ipairs(list) do if typeof(x)=='Instance' then consider(x) end end
        end
    end
    if best and bestScore>=100 then
        local ok,c=pcall(cleanClone,best)
        if ok then return c end
    end
end

local NATIVE_TEMPLATE=findNativeStar()
if NATIVE_TEMPLATE then NATIVE_TEMPLATE.Parent=nil end

local function fitModel(model,target)
    local ok,sz=pcall(function() return model:GetExtentsSize() end)
    if not ok or not sz then return end
    local mx=math.max(sz.X,sz.Y,sz.Z)
    if mx>.01 then pcall(function() model:ScaleTo(target/mx) end) end
end

local busy={}
local live={}

local function destroyOverlay(tool)
    local st=live[tool]
    if not st then return end
    if st.conn then pcall(function() st.conn:Disconnect() end) end
    if st.gui and st.gui.Parent then pcall(function() st.gui:Destroy() end) end
    if st.drawing then pcall(function() st.drawing.Visible=false st.drawing:Remove() end) end
    live[tool]=nil
end

local function handScreenGeometry(char)
    local cam=workspace.CurrentCamera
    local hand=char and (char:FindFirstChild('RightHand') or char:FindFirstChild('Right Arm'))
    local hrp=char and char:FindFirstChild('HumanoidRootPart')
    if not cam or not hand or not hrp then return nil end

    -- Reference: the hand grips the lower-left/centre of the Star and the Star sits beside the face.
    local gripWorld=hand.Position + hrp.CFrame.UpVector*.62 + hrp.CFrame.LookVector*.10
    local p,on=cam:WorldToViewportPoint(gripWorld)
    if not on or p.Z<=0 then return nil end

    local top=cam:WorldToViewportPoint(gripWorld+hrp.CFrame.UpVector*3.65)
    local h=math.clamp(math.abs(top.Y-p.Y),150,310)
    local w=h*(112/95)
    return p,w,h
end

local function startOverlay(tool)
    destroyOverlay(tool)

    local gui,img,drawing
    if CUSTOM_ASSET then
        gui=Instance.new('ScreenGui')
        gui.Name='SAE_HELD_STAR'
        gui.ResetOnSpawn=false
        gui.IgnoreGuiInset=true
        gui.DisplayOrder=1000000
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.Parent=PG

        img=Instance.new('ImageLabel')
        img.Name='Star'
        img.BackgroundTransparency=1
        img.AnchorPoint=Vector2.new(.34,.79)
        img.Image=CUSTOM_ASSET
        img.ScaleType=Enum.ScaleType.Fit
        img.ResampleMode=Enum.ResamplerMode.Default
        img.ClipsDescendants=false
        img.ZIndex=100
        img.Parent=gui
    elseif DRAWING_SUPPORTED then
        drawing=newDrawingImage()
        if not drawing then return false end
    else
        return false
    end

    local st={gui=gui,img=img,drawing=drawing,conn=nil}
    live[tool]=st
    st.conn=RunService.RenderStepped:Connect(function()
        if not tool.Parent or tool.Parent~=P.Character then destroyOverlay(tool) return end
        local g,w,h=handScreenGeometry(P.Character)
        if not g then
            if img then img.Visible=false end
            if drawing then drawing.Visible=false end
            return
        end
        local t=os.clock()
        local pulse=1+math.sin(t*2.0)*.01
        w=w*pulse
        h=h*pulse
        local rot=-2.5+math.sin(t*1.6)*.55

        if img then
            img.Size=UDim2.fromOffset(math.floor(w),math.floor(h))
            img.Position=UDim2.fromOffset(g.X,g.Y)
            img.Rotation=rot
            img.Visible=true
        elseif drawing then
            -- Drawing images cannot rotate, but use the exact supplied pixels and track the hand.
            drawing.Size=Vector2.new(w,h)
            drawing.Position=Vector2.new(g.X-w*.34,g.Y-h*.79)
            drawing.Transparency=1
            drawing.Visible=true
        end
    end)
    return true
end

local function attachNative(new,handle)
    if not NATIVE_TEMPLATE then return false end
    local model=NATIVE_TEMPLATE:Clone()
    fitModel(model,4.35)
    model.Parent=new
    local root=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart',true)
    if not root then model:Destroy() return false end
    model.PrimaryPart=root
    model:PivotTo(handle.CFrame*CFrame.new(-.55,.92,-.12)*CFrame.Angles(0,math.rad(180),math.rad(-3)))
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA('BasePart') then
            d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
            if d~=root then
                local w=Instance.new('WeldConstraint')
                w.Part0=root w.Part1=d w.Parent=root
            end
        end
    end
    local hw=Instance.new('WeldConstraint')
    hw.Part0=handle hw.Part1=root hw.Parent=handle
    return true
end

local function replace(tool)
    if not tool or not tool:IsA('Tool') or tool.Name~='Star' or tool:GetAttribute('SAE_EXACT_STAR_OVERLAY') or busy[tool] then return end

    -- Never replace a visible existing Star with an invisible tool if this executor cannot render the supplied reference.
    if not NATIVE_TEMPLATE and not CUSTOM_ASSET and not DRAWING_SUPPORTED then
        warn('[SAE] Exact Star renderer unavailable; keeping existing Star tool instead of making it invisible.')
        return
    end

    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name='Star'
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new.Grip=CFrame.new()
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_STAR_OVERLAY',true)

        local h=Instance.new('Part')
        h.Name='Handle'
        h.Size=Vector3.new(.35,.35,.35)
        h.Transparency=1
        h.CanCollide=false h.CanTouch=false h.CanQuery=false h.Massless=true
        h.Parent=new

        local usingNative=attachNative(new,h)
        if not usingNative then
            new.Equipped:Connect(function()
                task.defer(function()
                    if not startOverlay(new) then
                        warn('[SAE] Star reference could not be rendered by this executor.')
                    end
                end)
            end)
            new.Unequipped:Connect(function() destroyOverlay(new) end)
            new.AncestryChanged:Connect(function(_,par) if not par then destroyOverlay(new) end end)
        end

        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(c)
    if not c then return end
    c.ChildAdded:Connect(function(x)
        if x:IsA('Tool') and x.Name=='Star' then task.wait() replace(x) end
    end)
    for _,x in ipairs(c:GetChildren()) do
        if x:IsA('Tool') and x.Name=='Star' then replace(x) end
    end
end
watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(c) task.wait(.2) watch(c) end)
]============]

local FINAL_POLISH_SOURCE'''

new_block = prefix + b64 + suffix
s = s[:block.start()] + new_block + s[block.end():]

old_pos = "frame.Position=UDim2.new(.5,0,1,-32)"
new_pos = "frame.Position=UDim2.new(.5,0,1,-164) -- three notification rows higher"
if old_pos not in s:
    raise SystemExit('inventory notification position not found')
s = s.replace(old_pos, new_pos, 1)

p.write_text(s, encoding='utf-8')
print('Patched exact Star renderer and raised inventory notification.')
