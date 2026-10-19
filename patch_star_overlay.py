from pathlib import Path
import re
p=Path('Main.lua')
s=p.read_text(encoding='utf-8')
start=s.index("local EXACT_STAR_SOURCE=[============[")
end=s.index("\n]============]\n\nlocal FINAL_POLISH_SOURCE", start)
old=s[start:end]
m=re.search(r"local EMBEDDED_REFERENCE_B64=\[========\[\n(.*?)\n\]========\]", old, re.S)
if not m:
    raise SystemExit('embedded star reference not found')
b64=m.group(1)
new=r'''local EXACT_STAR_SOURCE=[============[
-- Exact held Star visual. Uses the supplied Star reference as a PlayerGui overlay
-- locked to the equipped right hand, so it cannot disappear because of Billboard/SurfaceGui behaviour.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local P=Players.LocalPlayer
if not P then return end
local PG=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not PG or not BP then return end

local EMBEDDED_REFERENCE_B64=[========[
__B64__
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
    if crypt and crypt.base64 and crypt.base64.decode then RAW_BYTES=crypt.base64.decode(EMBEDDED_REFERENCE_B64)
    elseif syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then RAW_BYTES=syn.crypt.base64.decode(EMBEDDED_REFERENCE_B64) end
end)
if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 then
    local ok,v=pcall(pureBase64Decode,EMBEDDED_REFERENCE_B64)
    if ok then RAW_BYTES=v end
end

local function customAsset()
    if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 or type(writefile)~='function' then return nil end
    local loader=getcustomasset or getsynasset
    if not loader and syn then loader=syn.getcustomasset or syn.getsynasset end
    if type(loader)~='function' then return nil end
    local file='sae_exact_star_reference.png'
    if not pcall(function() writefile(file,RAW_BYTES) end) then return nil end
    local ok,a=pcall(function() return loader(file) end)
    if ok and type(a)=='string' and a~='' then return a end
end
local ASSET=customAsset()

local busy={}
local live={}
local function destroyOverlay(tool)
    local st=live[tool]
    if not st then return end
    if st.conn then st.conn:Disconnect() end
    if st.gui and st.gui.Parent then st.gui:Destroy() end
    live[tool]=nil
end

local function startOverlay(tool)
    destroyOverlay(tool)
    if not ASSET then return end
    local gui=Instance.new('ScreenGui')
    gui.Name='SAE_HELD_STAR'
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    gui.DisplayOrder=905
    gui.Parent=PG

    local img=Instance.new('ImageLabel')
    img.Name='Star'
    img.BackgroundTransparency=1
    img.AnchorPoint=Vector2.new(.44,.79)
    img.Size=UDim2.fromOffset(245,208)
    img.Image=ASSET
    img.ScaleType=Enum.ScaleType.Fit
    img.ResampleMode=Enum.ResamplerMode.Default
    img.ClipsDescendants=false
    img.Parent=gui

    local st={gui=gui,img=img,conn=nil}
    live[tool]=st
    st.conn=RunService.RenderStepped:Connect(function()
        if not tool.Parent or tool.Parent~=P.Character or not gui.Parent then destroyOverlay(tool) return end
        local char=P.Character
        local cam=workspace.CurrentCamera
        local hand=char and (char:FindFirstChild('RightHand') or char:FindFirstChild('Right Arm'))
        local hrp=char and char:FindFirstChild('HumanoidRootPart')
        if not cam or not hand or not hrp then img.Visible=false return end
        local world=hand.Position + hrp.CFrame.UpVector*.72 - hrp.CFrame.RightVector*.08 + hrp.CFrame.LookVector*.12
        local v,on=cam:WorldToViewportPoint(world)
        if not on or v.Z<=0 then img.Visible=false return end
        local t=os.clock()
        local pulse=1+math.sin(t*2.0)*.012
        local w=math.floor(245*pulse)
        local h=math.floor(208*pulse)
        img.Size=UDim2.fromOffset(w,h)
        img.Position=UDim2.fromOffset(v.X,v.Y)
        img.Rotation=-3+math.sin(t*1.7)*.8
        img.Visible=true
    end)
end

local function replace(tool)
    if not tool or not tool:IsA('Tool') or tool.Name~='Star' or tool:GetAttribute('SAE_EXACT_STAR_OVERLAY') or busy[tool] then return end
    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name='Star'
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_STAR_OVERLAY',true)
        local h=Instance.new('Part')
        h.Name='Handle'; h.Size=Vector3.new(.35,.35,.35); h.Transparency=1
        h.CanCollide=false; h.CanTouch=false; h.CanQuery=false; h.Massless=true; h.Parent=new
        new.Equipped:Connect(function() task.defer(function() startOverlay(new) end) end)
        new.Unequipped:Connect(function() destroyOverlay(new) end)
        new.AncestryChanged:Connect(function(_,par) if not par then destroyOverlay(new) end end)
        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(c)
    if not c then return end
    c.ChildAdded:Connect(function(x) if x:IsA('Tool') and x.Name=='Star' then task.wait() replace(x) end end)
    for _,x in ipairs(c:GetChildren()) do if x:IsA('Tool') and x.Name=='Star' then replace(x) end end
end
watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(c) task.wait(.2) watch(c) end)
]============]'''.replace('__B64__',b64)
s=s[:start]+new+s[end+len('\n]============]'):]
p.write_text(s,encoding='utf-8')
