-- Steal An Egg - Combined Main (Control Panel + V7 3D Inventory)
-- All functionality in one file. No external loads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local P = Players.LocalPlayer
if not P then return end
local PG = P:FindFirstChildOfClass("PlayerGui") or P:WaitForChild("PlayerGui",10)
if not PG then return end

local function arrlen(t)
    local n=0
    for _ in ipairs(t) do n=n+1 end
    return n
end

for _,guiName in ipairs({"SAE_BOOT_V9","SAE_BOOT_V8","SAE_BOOT_V7","SAE_BOOT_V6","SAE_BOOT_V5","SAE_FINAL_V9","SAE_FINAL_V8","SAE_FINAL_V7","SAE_FINAL_V6","SAE_FINAL_V5"}) do
    local old = PG:FindFirstChild(guiName)
    if old then old:Destroy() end
end
for _,n in ipairs({"SAE_LocalEggs","SAE_LocalNPCs","SAE_SafeZoneMarker"}) do
    local x = workspace:FindFirstChild(n)
    if x then x:Destroy() end
end
-- Earlier versions placed the morph under CurrentCamera. Remove every stale
-- display rig and undo the local invisibility they left on the real character.
local hadStaleMorph=false
while true do
    local old=workspace:FindFirstChild("SAE_MorphShell",true)
    if not old then break end
    old:Destroy()
    hadStaleMorph=true
end
if hadStaleMorph and P.Character then
    for _,part in ipairs(P.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier=0
        elseif (part:IsA("Decal") or part:IsA("Texture")) and part.Transparency==1 then
            part.Transparency=0
        end
    end
end

local CFG = {
    AnnouncementProfile = {Name=P.DisplayName, Username=P.Name, UserId=P.UserId},
    Remotes = {
        Morph=nil, Announcement=nil, GlobalAnnouncement=nil,
        Teleport=nil, Invite=nil, GiveAdmin=nil, GiveCoowner=nil, GiveVPS=nil,
        Boost=nil, ClearBoost=nil, Meteor=nil
    }
}

local EGGS = {
    "MIXED","Skeleton Horse","World Burner","Equinox egg","Aetheron egg",
    "Gorilla King egg","Nightflame egg","Eternal Lunar Dragon egg","Unicorn egg",
    "Nibbles #013 Egg","Experiment #001 Egg","Scorched Dragon egg","Drilla egg",
    "Void Dragon egg","Rifborn egg","Riftbeasts egg","Shattered Rift egg",
    "Pegasus","ArchAngel","Oni Tiger egg","Kitsune egg"
}
local PATTERNS = {"ORIGINAL 6x20","ONE TYPE PER ROW","SPLIT ROWS 3+3","PAIRS 2+2+2","MIRRORED ROWS","ALTERNATING ROWS","DIAGONAL SEQUENCE"}
local ALIAS = {
    ["Skeleton Horse"]={"Skeleton Horse","Skeleton Horse Egg","SkeletonHorse","SkeletonHorseEgg"},
    ["World Burner"]={"World Burner","World Burner Egg","WorldBurner","WorldBurnerEgg"},
    ["Equinox egg"]={"Equinox","Equinox Egg","EquinoxEgg"},
    ["Aetheron egg"]={"Aetheron","Aetheron Egg","AetheronEgg"},
    ["Gorilla King egg"]={"Gorilla King","Gorilla King Egg","GorillaKing","GorillaKingEgg","King Gorilla Egg","KingGorillaEgg"},
    ["Nightflame egg"]={"Nightflame","Nightflame Egg","NightflameEgg","Night Flame","Night Flame Egg","NightFlameEgg"},
    ["Eternal Lunar Dragon egg"]={"Eternal Lunar Dragon","Eternal Lunar Dragon Egg","EternalLunarDragonEgg"},
    ["Unicorn egg"]={"Unicorn","Unicorn Egg","UnicornEgg"},
    ["Nibbles #013 Egg"]={"Nibbles #013 Egg","Nibbles 013 Egg","Nibbles013","Nibbles013Egg"},
    ["Experiment #001 Egg"]={"Experiment #001 Egg","Experiment 001 Egg","Experiment001","Experiment001Egg"},
    ["Scorched Dragon egg"]={"Scorched Dragon","Scorched Dragon Egg","ScorchedDragonEgg"},
    ["Drilla egg"]={"Drilla","Drilla Egg","DrillaEgg"},
    ["Void Dragon egg"]={"Void Dragon","Void Dragon Egg","VoidDragonEgg"},
    ["Rifborn egg"]={"Rifborn","Rifborn Egg","RifbornEgg"},
    ["Riftbeasts egg"]={"Riftbeasts","Riftbeasts Egg","RiftBeasts","RiftbeastsEgg"},
    ["Shattered Rift egg"]={"Shattered Rift","Shattered Rift Egg","ShatteredRiftEgg"},
    ["Pegasus"]={"Pegasus","Pegasus Egg","PegasusEgg"},
    ["ArchAngel"]={"ArchAngel","Arch Angel","ArchAngel Egg","Arch Angel Egg","ArchAngelEgg"},
    ["Oni Tiger egg"]={"Oni Tiger","Oni Tiger Egg","OniTigerEgg"},
    ["Kitsune egg"]={"Kitsune","Kitsune Egg","KitsuneEgg"}
}

local C = {
    bg=Color3.fromRGB(8,8,14), head=Color3.fromRGB(15,11,23), card=Color3.fromRGB(24,18,34),
    card2=Color3.fromRGB(37,25,50), border=Color3.fromRGB(84,57,110), purple=Color3.fromRGB(142,51,236),
    purple2=Color3.fromRGB(184,83,255), white=Color3.fromRGB(255,255,255), muted=Color3.fromRGB(168,162,181),
    green=Color3.fromRGB(105,245,135), orange=Color3.fromRGB(255,188,82), red=Color3.fromRGB(255,60,60), blue=Color3.fromRGB(45,145,255)
}

local EggFolder=Instance.new("Folder"); EggFolder.Name="SAE_LocalEggs"; EggFolder.Parent=workspace

local function corner(o,r) local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,r or 8); x.Parent=o; return x end
local function stroke(o,a) local x=Instance.new("UIStroke"); x.Color=C.border; x.Thickness=1; x.Transparency=a or .2; x.Parent=o; return x end
local function grad(o) local x=Instance.new("UIGradient"); x.Color=ColorSequence.new(Color3.fromRGB(110,35,205),Color3.fromRGB(177,69,253)); x.Rotation=15; x.Parent=o end
local function label(par,t,p,s,z) local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Position=p; x.Size=s; x.Text=t or ""; x.TextColor3=C.white; x.Font=Enum.Font.GothamMedium; x.TextSize=z or 11; x.TextXAlignment=Enum.TextXAlignment.Left; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=par; return x end
local function button(par,t,p,s,dark)
    local x=Instance.new("TextButton")
    x.Position=p; x.Size=s
    x.BackgroundColor3=dark and C.card2 or C.purple
    x:SetAttribute("RestingColor",x.BackgroundColor3)
    x.BorderSizePixel=0; x.AutoButtonColor=false
    x.Text=t; x.TextColor3=C.white; x.TextTransparency=0
    x.Font=Enum.Font.GothamBold; x.TextSize=11
    x.Parent=par; corner(x,8)
    if not dark then grad(x) end
    local hovering=false
    local idleTransparency=x.BackgroundTransparency
    local animation
    local gradients={}
    local function restoreGradients()
        for gradient,enabled in pairs(gradients) do
            if gradient.Parent==x then gradient.Enabled=enabled end
        end
        gradients={}
    end
    local function paint()
        if animation then animation:Cancel() end
        animation=TweenService:Create(x,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            BackgroundColor3=hovering and (x:GetAttribute("HoverColor") or Color3.fromRGB(100,49,160)) or x:GetAttribute("RestingColor"),
            BackgroundTransparency=hovering and 0 or idleTransparency
        })
        animation.Completed:Connect(function(state)
            if state==Enum.PlaybackState.Completed and not hovering then restoreGradients() end
        end)
        animation:Play()
    end
    -- State changes use an attribute, separate from the animated background.
    x:GetAttributeChangedSignal("RestingColor"):Connect(function()
        if hovering then return end
        if animation then animation:Cancel() end
        restoreGradients()
        x.BackgroundColor3=x:GetAttribute("RestingColor")
    end)
    local function setHover(value)
        if hovering==value then return end
        if value then
            if not animation or animation.PlaybackState~=Enum.PlaybackState.Playing then
                idleTransparency=x.BackgroundTransparency
            end
            for _,child in ipairs(x:GetChildren()) do
                if child:IsA("UIGradient") then
                    if gradients[child]==nil then gradients[child]=child.Enabled end
                    child.Enabled=false
                end
            end
        end
        hovering=value
        paint()
    end
    x.MouseEnter:Connect(function() setHover(true) end)
    x.MouseLeave:Connect(function() setHover(false) end)
    local ancestor=x
    while ancestor and ancestor:IsA("GuiObject") do
        local watched=ancestor
        watched:GetPropertyChangedSignal("Visible"):Connect(function()
            if not watched.Visible then setHover(false) end
        end)
        ancestor=ancestor.Parent
    end
    return x
end
local function textbox(par,ph,p,s,txt) local x=Instance.new("TextBox"); x.Position=p; x.Size=s; x.BackgroundColor3=C.card2; x.BorderSizePixel=0; x.Text=txt or ""; x.PlaceholderText=ph or ""; x.PlaceholderColor3=C.muted; x.TextColor3=C.white; x.Font=Enum.Font.GothamMedium; x.TextSize=11; x.ClearTextOnFocus=false; x.Parent=par; corner(x,8); stroke(x,.45); return x end
local function card(par,p,s) local x=Instance.new("Frame"); x.Position=p; x.Size=s; x.BackgroundColor3=C.card; x.BorderSizePixel=0; x.Parent=par; corner(x,10); stroke(x,.55); return x end
local function section(par,t,y) local x=label(par,t,UDim2.fromOffset(8,y),UDim2.new(1,-16,0,17),9); x.TextColor3=C.muted; x.Font=Enum.Font.GothamBold; return x end
local function drag(handle,win)
    local on=false; local start; local pos
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=true; start=i.Position; pos=win.Position end end)
    UserInputService.InputChanged:Connect(function(i) if on and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-start; win.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=false end end)
end

-- User-approved Roblox verified glyph. Do not change.
local VERIFIED=utf8.char(0xE000)
local function verified(par,size)
    local h=Instance.new("Frame"); h.BackgroundTransparency=1; h.Size=UDim2.fromOffset(size+2,size+4); h.Parent=par
    local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Size=UDim2.fromScale(1,1); x.Position=UDim2.fromOffset(0,1); x.Text=VERIFIED; x.Font=Enum.Font.GothamBold; x.TextSize=size; x.TextColor3=C.white; x.TextXAlignment=Enum.TextXAlignment.Center; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=h
    return h
end

local function remote(path)
    if type(path)~="table" then return nil end
    local x=ReplicatedStorage
    for _,n in ipairs(path) do x=x:FindFirstChild(n); if not x then return nil end end
    if x:IsA("RemoteEvent") or x:IsA("RemoteFunction") then return x end
end
local function callRemote(key,...)
    local r=remote(CFG.Remotes[key]); if not r then return false end
    local a={...}
    return pcall(function() if r:IsA("RemoteEvent") then r:FireServer(table.unpack(a)) else r:InvokeServer(table.unpack(a)) end end)
end

local Gui=Instance.new("ScreenGui"); Gui.Name="SAE_FINAL_V9"; Gui.ResetOnSpawn=false; Gui.IgnoreGuiInset=false; Gui.DisplayOrder=700; Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; Gui.Parent=PG

local function window(name,title,sub,w,h,pos)
    local f=Instance.new("Frame"); f.Name=name; f.AnchorPoint=Vector2.new(.5,.5); f.Position=pos; f.Size=UDim2.fromOffset(w,h); f.BackgroundColor3=C.bg; f.BorderSizePixel=0; f.Parent=Gui; corner(f,13); stroke(f,.05)
    local hd=Instance.new("Frame"); hd.Size=UDim2.new(1,0,0,60); hd.BackgroundColor3=C.head; hd.BorderSizePixel=0; hd.Parent=f; corner(hd,13)
    local ac=Instance.new("Frame"); ac.Position=UDim2.new(0,10,1,-3); ac.Size=UDim2.new(1,-20,0,3); ac.BackgroundColor3=C.purple; ac.BorderSizePixel=0; ac.Parent=hd; corner(ac,99); grad(ac)
    local tt=label(hd,title,UDim2.fromOffset(14,7),UDim2.new(1,-55,0,24),14); tt.Font=Enum.Font.GothamBold
    local st=label(hd,sub,UDim2.fromOffset(14,30),UDim2.new(1,-55,0,17),9); st.TextColor3=C.muted
    local cl=button(hd,"X",UDim2.new(1,-40,0,10),UDim2.fromOffset(28,28),true); cl.TextSize=12; cl.MouseButton1Click:Connect(function() f.Visible=false end)
    if name=="ConsolePanel" then
        -- Dark terminal with restrained purple header accents.
        f.BackgroundColor3=Color3.fromRGB(12,12,12)
        hd.BackgroundColor3=Color3.fromRGB(23,19,29)
        hd.Size=UDim2.new(1,0,0,48)
        for _,child in ipairs(f:GetChildren()) do
            if child:IsA("UICorner") then child.CornerRadius=UDim.new(0,3) end
            if child:IsA("UIStroke") then child.Color=Color3.fromRGB(112,75,155); child.Transparency=.2 end
        end
        hd:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,3)
        for _,child in ipairs(ac:GetChildren()) do child:Destroy() end
        ac.Position=UDim2.new(0,0,1,-1); ac.Size=UDim2.new(1,0,0,1)
        ac.BackgroundColor3=Color3.fromRGB(128,78,184)
        tt.Position=UDim2.fromOffset(12,4); tt.Size=UDim2.new(1,-54,0,20)
        tt.Font=Enum.Font.Code; tt.TextSize=14; tt.TextColor3=Color3.fromRGB(235,235,235)
        st.Position=UDim2.fromOffset(12,25); st.Size=UDim2.new(1,-54,0,16)
        st.Font=Enum.Font.Code; st.TextSize=11; st.TextColor3=Color3.fromRGB(185,165,208)
        cl.Position=UDim2.new(1,-38,0,9); cl.Size=UDim2.fromOffset(26,26)
        cl.Font=Enum.Font.Code; cl.TextSize=14
        cl:SetAttribute("RestingColor",Color3.fromRGB(23,19,29))
        cl:SetAttribute("HoverColor",Color3.fromRGB(62,43,82))
        cl:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,2)
    end
    drag(hd,f); return f
end

-- Create every important panel immediately before any game scan.
local Main=window("MainPanel","DEVELOPER CONTROL PANEL","Main control panel",344,172,UDim2.new(.22,0,.52,0))
Main.BackgroundTransparency=.12
local Morph=window("MorphPanel","Avatar Morpher","Change your avatar's look",350,360,UDim2.new(.74,0,.28,0))
Morph.BackgroundTransparency=Main.BackgroundTransparency
local MorphColorsPage=window("MorphColorsPanel","OVERHEAD TEXT COLORS","Choose a text color",350,250,UDim2.new(.74,0,.36,0))
MorphColorsPage.BackgroundTransparency=Main.BackgroundTransparency
MorphColorsPage.Visible=false
MorphColorsPage:GetPropertyChangedSignal("Visible"):Connect(function()
    if not MorphColorsPage.Visible then Morph.Visible=true end
end)
local Console=window("ConsolePanel","SERVER CONSOLE","TAB opens or closes this window",690,380,UDim2.new(.5,0,.5,0)); Console.Visible=false
local GiftPanel=window("GiftPanel","Gift Panel","Choose a gift category",350,238,UDim2.new(.5,0,.5,0))
GiftPanel.Visible=false
GiftPanel.BackgroundTransparency=Main.BackgroundTransparency

-- Remove any overlay left by older versions.
local oldSnow=PG:FindFirstChild("SAE_SnowOverlay")
if oldSnow then oldSnow:Destroy() end

-- Permanent launchers so closed panels never disappear permanently.
local Launch=Instance.new("Frame"); Launch.Position=UDim2.new(0,12,.5,-170); Launch.Size=UDim2.fromOffset(106,105); Launch.BackgroundTransparency=1; Launch.Parent=Gui
local LL=Instance.new("UIListLayout"); LL.Padding=UDim.new(0,7); LL.Parent=Launch
local bAdmin=button(Launch,"ADMIN",UDim2.new(),UDim2.fromOffset(102,29),false)
local bMorph=button(Launch,"MORPH",UDim2.new(),UDim2.fromOffset(102,29),true)
local bGift=button(Launch,"GIFT PANEL",UDim2.new(),UDim2.fromOffset(102,29),true)
bAdmin.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)
bMorph.MouseButton1Click:Connect(function()
    if MorphColorsPage.Visible then
        MorphColorsPage.Visible=false
        Morph.Visible=true
    else
        Morph.Visible=not Morph.Visible
    end
end)
bGift.MouseButton1Click:Connect(function() Main.Visible=false; GiftPanel.Visible=not GiftPanel.Visible end)

section(GiftPanel,"GIFT CATEGORIES",64)
local giftStatus=label(GiftPanel,"Choose Eggs, Pets, or Stars.",UDim2.fromOffset(12,197),UDim2.new(1,-24,0,22),10)
giftStatus.TextColor3=C.muted
local giftCategoryButtons={}
local selectedGiftCategory=nil
local function selectGiftCategory(name)
    selectedGiftCategory=name
    for category,categoryButton in pairs(giftCategoryButtons) do
        local selected=category==name
        categoryButton:SetAttribute("RestingColor",selected and C.purple or C.card2)
    end
    giftStatus.Text=name.." category selected."
    giftStatus.TextColor3=C.white
end
for i,name in ipairs({"Eggs","Pets","Stars"}) do
    local categoryButton=button(GiftPanel,name,UDim2.fromOffset(12,82+(i-1)*36),UDim2.new(1,-24,0,30),true)
    categoryButton.TextSize=12
    giftCategoryButtons[name]=categoryButton
    categoryButton.MouseButton1Click:Connect(function() selectGiftCategory(name) end)
end

-- Centered announcement layer.
local Notify=Instance.new("Frame"); Notify.BackgroundTransparency=1; Notify.Size=UDim2.fromScale(1,1); Notify.Parent=Gui
local function nt(par,t,col,z,font) local x=label(par,t,UDim2.new(),UDim2.fromOffset(0,46),z); x.AutomaticSize=Enum.AutomaticSize.X; x.Font=font or Enum.Font.GothamBlack; x.TextColor3=col; x.TextStrokeTransparency=0; x.TextStrokeColor3=Color3.new(0,0,0); return x end
local function notice(uid,sender,before,red,after,font)
    local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.AutomaticSize=Enum.AutomaticSize.X; row.Size=UDim2.fromOffset(0,50); row.AnchorPoint=Vector2.new(.5,0); row.Position=UDim2.new(.5,0,0,-60); row.Parent=Notify
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal; l.HorizontalAlignment=Enum.HorizontalAlignment.Center; l.VerticalAlignment=Enum.VerticalAlignment.Center; l.Padding=UDim.new(0,4); l.Parent=row
    local im=Instance.new("ImageLabel"); im.BackgroundTransparency=1; im.Size=UDim2.fromOffset(40,40); im.Image="rbxthumb://type=AvatarHeadShot&id="..tostring(uid or P.UserId).."&w=150&h=150"; im.Parent=row
    nt(row,sender,C.blue,29,font); verified(row,26); if before~="" then nt(row,before,C.white,29,font) end; if red~="" then nt(row,red,C.red,29,font) end; if after~="" then nt(row,after,C.white,29,font) end
    TweenService:Create(row,TweenInfo.new(.25,Enum.EasingStyle.Quint),{Position=UDim2.new(.5,0,0,7)}):Play()
    task.delay(4,function() if row.Parent then local tw=TweenService:Create(row,TweenInfo.new(.2),{Position=UDim2.new(.5,0,0,-60)}); tw:Play(); tw.Completed:Wait(); if row.Parent then row:Destroy() end end end)
end

local function norm(s) return string.lower(tostring(s or "")):gsub("[^%w]","") end
local function rootOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart",true) or o:FindFirstChildWhichIsA("BasePart",true) end
end
local function pivot(o,cf) if o:IsA("Model") then o:PivotTo(cf) elseif o:IsA("BasePart") then o.CFrame=cf end end

local function groundHit(pos,ignore)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,250,0),Vector3.new(0,-1000,0),rp)
end

local function groundHitNear(pos,ignore)
    -- Short raycast around the active character height. This avoids choosing
    -- roofs/ceilings that a 250-stud-above ray can hit first.
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,10,0),Vector3.new(0,-80,0),rp)
end
local function groundObject(o,pos,yaw)
    -- Prefer the real raycast floor, but never throw an egg away just because
    -- the game's floor has CanQuery disabled or the executor misses the raycast.
    local hit=groundHitNear(pos,o)
    local groundY=hit and hit.Position.Y or pos.Y
    local rot=CFrame.Angles(0,math.rad(yaw or 0),0)

    local ok=pcall(function()
        -- Place high first so GetBoundingBox measures the final rotation cleanly.
        pivot(o,CFrame.new(pos.X,groundY+100,pos.Z)*rot)
        if o:IsA("Model") then
            local cf,sz=o:GetBoundingBox()
            local bottom=cf.Position.Y-sz.Y/2
            o:PivotTo(o:GetPivot()+Vector3.new(0,groundY-bottom+.05,0))
        else
            local bottom=o.Position.Y-o.Size.Y/2
            o.CFrame=o.CFrame+Vector3.new(0,groundY-bottom+.05,0)
        end
    end)
    return ok
end

local function createAvatar(uid)
    local m
    local ok=pcall(function() m=Players:CreateHumanoidModelFromUserIdAsync(uid) end)
    if ok and m then return m end
    local d=Players:GetHumanoidDescriptionFromUserId(uid)
    return Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15)
end
-- Egg resolver. Games often store egg visuals inside nested Models, Tools or Folders,
-- so resolve the matching visual instead of requiring the named object itself to be a Model.
local EggCache={}

local function eggTextMatches(value,want)
    local n=norm(value)
    if n=="" then return false end
    if want[n] then return true end
    -- Only allow the object's name to CONTAIN a configured alias.
    -- Do not do the reverse: a generic child named "Egg" must never match every egg type.
    for alias in pairs(want) do
        if #alias>=5 and #n>=#alias and n:find(alias,1,true) then return true end
    end
    return false
end

local function matchObj(o,want)
    if eggTextMatches(o.Name,want) then return true end
    for _,a in ipairs({"EggName","DisplayName","ItemName","Title","Type","PetName","Name"}) do
        local v=o:GetAttribute(a)
        if v~=nil and eggTextMatches(v,want) then return true end
    end
    if o:IsA("StringValue") and eggTextMatches(o.Value,want) then return true end
    return false
end

local function usableEggSource(o,container)
    if not o or o==EggFolder then return nil end
    if o:IsDescendantOf(EggFolder) then return nil end

    if o:IsA("Model") and o:FindFirstChildWhichIsA("BasePart",true) then return o end
    if o:IsA("BasePart") then
        local model=o:FindFirstAncestorOfClass("Model")
        if model and model~=P.Character and model:IsDescendantOf(container)
            and model:FindFirstChildWhichIsA("BasePart",true) then
            return model
        end
        return o
    end

    local cur=o.Parent
    while cur and cur~=container do
        if cur:IsA("Model") and cur~=P.Character and cur:FindFirstChildWhichIsA("BasePart",true) then
            return cur
        elseif cur:IsA("Tool") then
            local handle=cur:FindFirstChildWhichIsA("BasePart",true)
            if handle then return handle end
        end
        cur=cur.Parent
    end

    if o:IsA("Folder") or o:IsA("Tool") then
        local model=o:FindFirstChildWhichIsA("Model",true)
        if model and model:FindFirstChildWhichIsA("BasePart",true) then return model end
        local part=o:FindFirstChildWhichIsA("BasePart",true)
        if part then return part end
    end
    return nil
end

local function findEgg(name)
    local cached=EggCache[name]
    if cached and cached.Parent then return cached end

    local want={}
    for _,a in ipairs(ALIAS[name] or {name}) do want[norm(a)]=true end

    for _,container in ipairs({ReplicatedStorage,workspace}) do
        for _,o in ipairs(container:GetDescendants()) do
            if not o:IsDescendantOf(EggFolder) and matchObj(o,want) then
                local source=usableEggSource(o,container)
                if source then
                    EggCache[name]=source
                    return source
                end
            end
        end
    end
    return nil
end

-- Build a stripped visual template from the REAL egg object already replicated by the game.
-- Scripts, sounds, particles and interaction objects are removed once so large batches
-- can keep the original mesh/texture/decal appearance without cloning the heavy behavior.
local EggTemplateCache={}

local function stripEggTemplate(o)
    local remove={}
    for _,x in ipairs(o:GetDescendants()) do
        if x:IsA("Script") or x:IsA("LocalScript") or x:IsA("ModuleScript")
            or x:IsA("ProximityPrompt") or x:IsA("ClickDetector")
            or x:IsA("Humanoid") or x:IsA("Animator")
            or x:IsA("Sound") or x:IsA("ParticleEmitter")
            or x:IsA("Trail") or x:IsA("Beam")
            or x:IsA("BodyMover") or x:IsA("Constraint") then
            table.insert(remove,x)
        elseif x:IsA("BasePart") then
            x.Anchored=true
            x.CanCollide=false
            x.CanTouch=false
            x.CanQuery=true
            x.Massless=true
            x.CastShadow=false
        end
    end
    for _,x in ipairs(remove) do pcall(function() x:Destroy() end) end
end

local function templateInfo(name)
    local cached=EggTemplateCache[name]
    if cached~=nil then return cached or nil end

    local source=findEgg(name)
    if not source then
        EggTemplateCache[name]=false
        return nil
    end

    local ok,clone=pcall(function() return source:Clone() end)
    if not ok or not clone then
        EggTemplateCache[name]=false
        return nil
    end

    clone.Name=name
    stripEggTemplate(clone)

    local root=rootOf(clone)
    if not root then
        pcall(function() clone:Destroy() end)
        EggTemplateCache[name]=false
        return nil
    end

    local info={template=clone,bottomOffset=0,size=Vector3.new(4,4,4)}
    if clone:IsA("Model") then
        pcall(function() clone:PivotTo(CFrame.new()) end)
        local okBox,cf,sz=pcall(function()
            local c,z=clone:GetBoundingBox()
            return c,z
        end)
        if not okBox or not cf or not sz or sz.Magnitude<.1 or math.max(sz.X,sz.Y,sz.Z)>80 then
            pcall(function() clone:Destroy() end)
            EggTemplateCache[name]=false
            return nil
        end
        info.bottomOffset=cf.Position.Y-sz.Y/2
        info.size=sz
    else
        clone.CFrame=CFrame.new()
        if clone.Size.Magnitude<.1 or math.max(clone.Size.X,clone.Size.Y,clone.Size.Z)>80 then
            pcall(function() clone:Destroy() end)
            EggTemplateCache[name]=false
            return nil
        end
        info.bottomOffset=-clone.Size.Y/2
        info.size=clone.Size
    end

    clone.Parent=nil
    EggTemplateCache[name]=info
    return info
end

local function availableEggs()
    local a={}
    for i=2,arrlen(EGGS) do
        local name=EGGS[i]
        if templateInfo(name) then table.insert(a,name) end
    end
    return a
end

-- Safe-zone state is declared before map/layout code so GENERAL egg spawning
-- can always reserve a no-spawn band around the Safe Zone.
local SafeObj=nil
local SafePos=nil
local SafeName="Not locked"
local detectSafe=nil

-- Map-center detection. General egg spawning is anchored to the map frame.
local MapFloor=nil
local MapCF=nil
local MapSize=nil
local MapName="Not detected"
local MapMarker=nil

local function updateMapMarker()
    if MapMarker then MapMarker:Destroy(); MapMarker=nil end
    if not MapCF then return end
    local m=Instance.new("Part")
    m.Name="SAE_MapCenterMarker"
    m.Size=Vector3.new(5,.08,5)
    m.Anchored=true
    m.CanCollide=false
    m.CanTouch=false
    m.CanQuery=false
    m.Material=Enum.Material.Neon
    m.Color=Color3.fromRGB(170,80,255)
    m.Transparency=.72
    m.CFrame=CFrame.new(MapCF.Position+Vector3.new(0,.08,0))
    m.Parent=workspace
    MapMarker=m
end

local function reservedZoneName(value)
    local n=norm(value)
    return n:find("safezone",1,true)
        or n:find("eggdropoff",1,true)
        or n:find("deposit",1,true)
        or n:find("playerspawn",1,true)
        or n:find("spawnzone",1,true)
        or n:find("lobby",1,true)
        or n:find("playerbase",1,true)
        or n:find("homebase",1,true)
        or n:find("plot",1,true)
end

local function floorCandidateScore(o)
    if not o:IsA("BasePart") or not o.Anchored or not o.CanCollide or o.Transparency>=.98 then return -1 end
    local s=o.Size
    if s.X<20 or s.Z<20 then return -1 end
    local score=s.X*s.Z
    local aspect=math.max(s.X,s.Z)/math.max(1,math.min(s.X,s.Z))
    score=score*(1+math.min(2.5,math.max(0,aspect-1))*.28)
    if s.Y<=18 then score=score*1.5 end
    local n=norm(o.Name)
    if n:find("floor",1,true) or n:find("ground",1,true) or n:find("arena",1,true) or n:find("map",1,true) then score=score*1.8 end
    if n:find("wall",1,true) or n:find("roof",1,true) or n:find("ceiling",1,true) then score=score*.08 end
    -- Safe/spawn/base pieces can be large floors too. They are valid ground,
    -- but they must not win map detection over the actual arena.
    if reservedZoneName(n) then score=score*.08 end
    return score
end

local function detectMapCenter()
    local root=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    local playerPos=root and root.Position or Vector3.zero
    local nearHit=root and groundHitNear(root.Position,nil) or nil
    local playY=nearHit and nearHit.Position.Y or playerPos.Y

    local best=nil
    local bestScore=-math.huge
    local under=(nearHit and nearHit.Instance and nearHit.Instance:IsA("BasePart")) and nearHit.Instance or nil

    -- Scan every plausible floor. The old version gave the part directly under
    -- the player an unbeatable score, which meant standing in the Safe Zone
    -- could make the Safe Zone itself become "the map".
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o:IsDescendantOf(EggFolder) then
            local belongsToSafe=SafeObj and (o==SafeObj or (SafeObj:IsA("Model") and o:IsDescendantOf(SafeObj)))
            local base=belongsToSafe and -1 or floorCandidateScore(o)
            if base>=0 then
                local topY=o.CFrame:PointToWorldSpace(Vector3.new(0,o.Size.Y/2,0)).Y
                local vertical=math.abs(topY-playY)
                if vertical<=18 then
                    local horizontal=Vector3.new(o.Position.X-playerPos.X,0,o.Position.Z-playerPos.Z).Magnitude
                    local score=base-(vertical*800)-(math.max(0,horizontal-300)*65)

                    -- A normal arena floor beneath the player gets only a small
                    -- bonus. A Safe/Spawn/Plot floor beneath the player gets none.
                    if o==under and not reservedZoneName(o.Name) then
                        score=score*1.18
                    end

                    if horizontal<=600 and score>bestScore then
                        bestScore=score
                        best=o
                    end
                end
            end
        end
    end

    if not best then
        local pos=nearHit and nearHit.Position or (root and root.Position or Vector3.zero)
        MapFloor=nil
        MapCF=CFrame.new(pos)
        MapSize=Vector3.new(155,1,250)
        MapName="Fallback center"
        updateMapMarker()
        return true,MapName
    end

    MapFloor=best

    -- Align the spawn grid to the floor itself, not to the player's camera/facing.
    -- The LONGER floor axis is always treated as the row/depth direction. This
    -- keeps rows ruler-straight even if the player is standing at an angle.
    local topCenter=best.CFrame:PointToWorldSpace(Vector3.new(0,best.Size.Y/2,0))
    local look=Vector3.new(best.CFrame.LookVector.X,0,best.CFrame.LookVector.Z)
    local right=Vector3.new(best.CFrame.RightVector.X,0,best.CFrame.RightVector.Z)
    if look.Magnitude<.01 then look=Vector3.new(0,0,-1) else look=look.Unit end
    if right.Magnitude<.01 then right=Vector3.new(1,0,0) else right=right.Unit end

    local forward
    local width
    local depth
    if best.Size.Z>=best.Size.X then
        forward=look
        width=best.Size.X
        depth=best.Size.Z
    else
        forward=right
        width=best.Size.Z
        depth=best.Size.X
    end

    MapCF=CFrame.lookAt(topCenter,topCenter+forward)
    MapSize=Vector3.new(width,best.Size.Y,depth)
    MapName=best.Name
    updateMapMarker()
    return true,MapName
end

local function setMapCenterHere()
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not r then return false,"Character unavailable." end
    local hit=groundHitNear(r.Position,nil)
    local pos=hit and hit.Position or (r.Position-Vector3.new(0,3,0))
    MapFloor=nil
    MapCF=CFrame.new(pos)
    MapSize=Vector3.new(140,1,220)
    MapName="Manual map center"
    updateMapMarker()
    return true,MapName
end

local function getMapFrame()
    if MapFloor and MapFloor.Parent then
        local topCenter=MapFloor.CFrame:PointToWorldSpace(Vector3.new(0,MapFloor.Size.Y/2,0))
        local look=Vector3.new(MapFloor.CFrame.LookVector.X,0,MapFloor.CFrame.LookVector.Z)
        local right=Vector3.new(MapFloor.CFrame.RightVector.X,0,MapFloor.CFrame.RightVector.Z)
        if look.Magnitude<.01 then look=Vector3.new(0,0,-1) else look=look.Unit end
        if right.Magnitude<.01 then right=Vector3.new(1,0,0) else right=right.Unit end

        local forward
        local width
        local depth
        if MapFloor.Size.Z>=MapFloor.Size.X then
            forward=look
            width=MapFloor.Size.X
            depth=MapFloor.Size.Z
        else
            forward=right
            width=MapFloor.Size.Z
            depth=MapFloor.Size.X
        end

        MapCF=CFrame.lookAt(topCenter,topCenter+forward)
        MapSize=Vector3.new(width,MapFloor.Size.Y,depth)
    end
    if not MapCF then detectMapCenter() end
    return MapCF or CFrame.new(), MapSize or Vector3.new(155,1,250)
end

local COMPACT_SPAWN_BOUNDS=Vector3.new(155,1,250)

local function safeClearanceRadius()
    -- Hard minimum keeps GENERAL eggs out of the white Safe Zone even when the
    -- game's Safe Zone object has an unhelpful name or auto-detection misses it.
    local radius=70
    if SafeObj and SafeObj.Parent then
        if SafeObj:IsA("BasePart") then
            radius=math.max(radius,math.max(SafeObj.Size.X,SafeObj.Size.Z)*.5+18)
        elseif SafeObj:IsA("Model") then
            local ok,_,sz=pcall(function() return SafeObj:GetBoundingBox() end)
            if ok and sz then
                radius=math.max(radius,math.max(sz.X,sz.Z)*.5+18)
            end
        end
    end
    return math.clamp(radius,70,110)
end

local function playableGroundHit(pos,referenceY)
    local hit=groundHitNear(pos,nil)
    if not hit then return nil end
    if referenceY and math.abs(hit.Position.Y-referenceY)>16 then return nil end
    return hit
end

local function findPlayableSpawnFrame()
    local root=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil,nil end

    -- Always try to learn the Safe Zone, but do not depend on it. The player's
    -- current position is also treated as a hard no-spawn anchor because the
    -- user normally presses Spawn while standing in the Safe Zone.
    if not SafePos and detectSafe then pcall(function() detectSafe() end) end

    local under=groundHitNear(root.Position,nil)
    local groundY=under and under.Position.Y or (root.Position.Y-3)
    local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
    if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
    local right=Vector3.new(-forward.Z,0,forward.X)

    local dirs={
        forward,
        (forward+right).Unit,
        (forward-right).Unit,
        right,
        -right,
        (-forward+right).Unit,
        (-forward-right).Unit,
        -forward
    }

    local startDistance=safeClearanceRadius()
    local maxDistance=340
    local step=8
    local best=nil

    for index,dir in ipairs(dirs) do
        local first=nil
        local last=nil
        local valid=0
        local misses=0
        local floorVotes={}

        for d=startDistance,maxDistance,step do
            local probe=root.Position+dir*d
            local hit=playableGroundHit(Vector3.new(probe.X,root.Position.Y,probe.Z),groundY)
            if hit then
                if not first then first=d end
                last=d
                valid=valid+1
                misses=0
                floorVotes[hit.Instance]=(floorVotes[hit.Instance] or 0)+1
            elseif first then
                misses=misses+1
                if misses>=2 then break end
            end
        end

        if first and last and valid>=6 then
            local run=last-first
            local endPoint=root.Position+dir*last
            local safeAnchor=SafePos or root.Position
            local away=(Vector3.new(endPoint.X,0,endPoint.Z)-Vector3.new(safeAnchor.X,0,safeAnchor.Z)).Magnitude

            -- Prefer the direction the player is looking, but geometry/run length
            -- still wins when the actual arena clearly continues another way.
            local facingBonus=math.max(-1,math.min(1,dir:Dot(forward)))*22
            local score=run+away*.12+facingBonus

            local votedFloor=nil
            local votedCount=0
            for floorPart,n in pairs(floorVotes) do
                if n>votedCount then votedCount=n; votedFloor=floorPart end
            end

            if not best or score>best.score then
                best={dir=dir,first=first,last=last,score=score,floor=votedFloor}
            end
        end
    end

    if not best then return nil,nil end

    local dir=best.dir

    -- If the sampled play floor is a real rectangular floor piece, snap rows to
    -- its closest horizontal axis so rows stay perfectly straight, never wonky.
    if best.floor and best.floor:IsA("BasePart") then
        local look=Vector3.new(best.floor.CFrame.LookVector.X,0,best.floor.CFrame.LookVector.Z)
        local rgt=Vector3.new(best.floor.CFrame.RightVector.X,0,best.floor.CFrame.RightVector.Z)
        if look.Magnitude>.01 then look=look.Unit end
        if rgt.Magnitude>.01 then rgt=rgt.Unit end
        local axis=(math.abs(dir:Dot(look))>=math.abs(dir:Dot(rgt))) and look or rgt
        if axis.Magnitude>.01 then
            if axis:Dot(dir)<0 then axis=-axis end
            dir=axis
        end
    end

    -- Re-scan along the straightened direction so the near edge ALWAYS starts
    -- outside the Safe Zone and the far edge reaches the end of usable ground.
    local first=nil
    local last=nil
    local misses=0
    for d=startDistance,maxDistance,step do
        local probe=root.Position+dir*d
        local hit=playableGroundHit(Vector3.new(probe.X,root.Position.Y,probe.Z),groundY)
        if hit then
            if not first then first=d end
            last=d
            misses=0
        elseif first then
            misses=misses+1
            if misses>=2 then break end
        end
    end
    if not first or not last or (last-first)<45 then return nil,nil end

    -- Measure usable width at several points down the play area. Taking the
    -- narrowest sample prevents rows clipping into side walls while still using
    -- nearly all of the actual map width.
    local side=Vector3.new(-dir.Z,0,dir.X)
    local minHalfWidth=math.huge
    for _,frac in ipairs({.18,.38,.58,.78}) do
        local d=first+(last-first)*frac
        local centerProbe=root.Position+dir*d
        local left=0
        local rightWidth=0
        for s=6,100,6 do
            local p=centerProbe-side*s
            if playableGroundHit(Vector3.new(p.X,root.Position.Y,p.Z),groundY) then left=s else break end
        end
        for s=6,100,6 do
            local p=centerProbe+side*s
            if playableGroundHit(Vector3.new(p.X,root.Position.Y,p.Z),groundY) then rightWidth=s else break end
        end
        local half=math.min(left,rightWidth)
        if half>=18 then minHalfWidth=math.min(minHalfWidth,half) end
    end

    local width
    if minHalfWidth<math.huge then
        width=math.clamp(minHalfWidth*2,55,170)
    else
        width=155
    end

    local nearEdge=first+4
    local farEdge=last-4
    local depth=farEdge-nearEdge
    if depth<45 then return nil,nil end

    local centerDistance=(nearEdge+farEdge)/2
    local center=root.Position+dir*centerDistance
    center=Vector3.new(center.X,groundY,center.Z)

    return CFrame.lookAt(center,center+dir),Vector3.new(width,1,depth)
end

local function spawnAvoidAnchor(mapCF,mapBounds)
    -- Fallback exclusion used only if geometry sampling cannot identify the
    -- playable corridor. It still enforces a large Safe Zone/player buffer.
    local anchor=SafePos
    local clearance=safeClearanceRadius()

    if SafeObj and SafeObj.Parent then
        if SafeObj:IsA("BasePart") then
            anchor=SafeObj.Position
        elseif SafeObj:IsA("Model") then
            anchor=SafeObj:GetPivot().Position
        end
    end

    local root=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not anchor and root then anchor=root.Position end
    return anchor,clearance
end

local function visibleSpawnFrame(preferredCF,count,pattern,sizeValue)
    if preferredCF then
        return preferredCF,COMPACT_SPAWN_BOUNDS
    end

    -- GENERAL spawn path: determine the real playable ground beyond the Safe
    -- Zone first. This is intentionally independent of object names.
    local playCF,playBounds=findPlayableSpawnFrame()
    if playCF and playBounds then
        return playCF,playBounds
    end

    -- Geometry fallback: use detected map floor, but carve out a large band
    -- around the Safe Zone/player. Never silently fall back to the full map.
    if not SafePos and detectSafe then pcall(function() detectSafe() end) end
    if MapFloor and SafeObj and
        (MapFloor==SafeObj or (SafeObj:IsA("Model") and MapFloor:IsDescendantOf(SafeObj))) then
        MapFloor=nil
        MapCF=nil
        MapSize=nil
        detectMapCenter()
    end

    local mapCF,mapBounds=getMapFrame()
    if not mapCF then return CFrame.new(),COMPACT_SPAWN_BOUNDS end
    mapBounds=mapBounds or COMPACT_SPAWN_BOUNDS

    local anchor,clearance=spawnAvoidAnchor(mapCF,mapBounds)
    if anchor then
        local scale=math.clamp(tonumber(sizeValue) or 100,25,500)/100
        local edgeMargin=math.max(6,4+scale*1.5)
        local minZ=-mapBounds.Z/2+edgeMargin
        local maxZ= mapBounds.Z/2-edgeMargin
        local localAnchor=mapCF:PointToObjectSpace(anchor)
        local exMin=localAnchor.Z-clearance
        local exMax=localAnchor.Z+clearance

        local leftA=minZ
        local leftB=math.min(maxZ,exMin)
        local rightA=math.max(minZ,exMax)
        local rightB=maxZ
        local leftLen=math.max(0,leftB-leftA)
        local rightLen=math.max(0,rightB-rightA)

        local a,b
        if leftLen>=rightLen then a,b=leftA,leftB else a,b=rightA,rightB end
        if a and b and (b-a)>=45 then
            local centerZ=(a+b)/2
            local regionDepth=b-a
            return mapCF*CFrame.new(0,0,centerZ),Vector3.new(mapBounds.X,mapBounds.Y,regionDepth)
        end
    end

    -- Last resort: place the field in front of the player, beyond the hard
    -- no-spawn radius. This is safer than ever spawning on top of the Safe Zone.
    local root=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local dir=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
        if dir.Magnitude<.01 then dir=Vector3.new(0,0,-1) else dir=dir.Unit end
        local clearance=safeClearanceRadius()
        local depth=180
        local center=root.Position+dir*(clearance+depth/2)
        local hit=groundHitNear(center,nil)
        if hit then center=hit.Position else center=Vector3.new(center.X,root.Position.Y-3,center.Z) end
        return CFrame.lookAt(center,center+dir),Vector3.new(140,1,depth)
    end

    return mapCF,mapBounds
end

local function physicalLayout(count,sizeValue,baseCF,bounds,pattern,footprintX,footprintZ)
    local scale=math.clamp(sizeValue,25,500)/100
    local cols
    if pattern=="ORIGINAL 6x20" then
        cols=20
    elseif pattern=="ONE TYPE PER ROW" then
        cols=16
    elseif pattern=="SPLIT ROWS 3+3" then
        cols=18
    elseif pattern=="PAIRS 2+2+2" then
        cols=18
    elseif pattern=="MIRRORED ROWS" then
        cols=20
    elseif pattern=="ALTERNATING ROWS" then
        cols=16
    elseif pattern=="DIAGONAL SEQUENCE" then
        cols=20
    else
        cols=20
    end
    cols=math.min(cols,count)
    local rows=math.ceil(count/math.max(cols,1))

    -- Base spacing on the REAL visual footprint of the selected eggs. This gives
    -- a small visible air gap even when the egg scale changes or a larger egg type
    -- is mixed in, instead of guessing one spacing value for every model.
    local actualX=math.max(1,tonumber(footprintX) or (4*scale))
    local actualZ=math.max(1,tonumber(footprintZ) or (4*scale))
    local gapX=math.max(1.15,.65*scale)
    local gapZ=math.max(1.75,.9*scale)
    local naturalX=math.max(7.25,actualX+gapX)
    local naturalZ=math.max(9.0,actualZ+gapZ)
    local usableWidth=((bounds and bounds.X) or COMPACT_SPAWN_BOUNDS.X)*.985
    local usableDepth=((bounds and bounds.Z) or COMPACT_SPAWN_BOUNDS.Z)*.97

    local sx=naturalX
    local sz=naturalZ

    if cols>1 then
        local fitX=usableWidth/(cols-1)
        if fitX<naturalX then
            sx=fitX
        else
            sx=math.min(fitX,naturalX*1.12)
        end
    end

    if rows>1 then
        local fitZ=usableDepth/(rows-1)
        if fitZ<naturalZ then
            -- If a very large batch physically cannot keep the ideal gap,
            -- fitting inside the non-safe play area wins over spilling into it.
            sz=fitZ
        else
            -- Use more of the playable length, but cap expansion so row gaps
            -- remain deliberate rather than huge.
            sz=math.min(fitZ,naturalZ*1.55)
        end
    end

    return cols,rows,sx,sz
end
local function layoutPosition(index,count,sizeValue,baseCF,bounds,pattern,footprintX,footprintZ)
    local cols,rows,sx,sz=physicalLayout(count,sizeValue,baseCF,bounds,pattern,footprintX,footprintZ)
    local row=math.floor((index-1)/cols)
    local col=(index-1)%cols

    -- Centre an incomplete final row instead of leaving all of its empty space
    -- on one side of the map.
    local rowStart=row*cols
    local rowCols=math.min(cols,count-rowStart)
    local x=(col-(rowCols-1)/2)*sx
    local z=(row-(rows-1)/2)*sz
    local pos=(baseCF*CFrame.new(x,0,z)).Position
    return pos,row,col,cols,rows,sx,sz,rowCols
end

local function mixedEggFor(pattern,mix,row,col,index,cols)
    local n=arrlen(mix)
    if n==0 then return nil end
    local function at(i) return mix[(i%n)+1] end

    if pattern=="ORIGINAL 6x20" then
        -- 20 eggs across. Each row uses a six-type sequence and repeats it:
        -- A B C D E F A B C D E F ...
        return at(row*6+(col%6))
    elseif pattern=="ONE TYPE PER ROW" then
        -- AAAAA... / BBBBB... / CCCCC...
        return at(row)
    elseif pattern=="SPLIT ROWS 3+3" then
        -- Exactly AAA BBB AAA BBB ... across the row.
        -- The next row advances to the next pair of egg types.
        local half=math.floor((col%6)/3)
        return at(row*2+half)
    elseif pattern=="PAIRS 2+2+2" then
        -- Exactly AA BB CC AA BB CC ... across the row.
        -- The next row advances to the next trio of egg types.
        local pair=math.floor((col%6)/2)
        return at(row*3+pair)
    elseif pattern=="MIRRORED ROWS" then
        -- Row 1 runs left-to-right; row 2 is the exact reverse; repeat.
        local sequenceCol=(row%2==0) and col or (cols-1-col)
        return at(sequenceCol)
    elseif pattern=="ALTERNATING ROWS" then
        -- Full rows alternate A / B / A / B ...
        return at(row%2)
    elseif pattern=="DIAGONAL SEQUENCE" then
        -- Shift the sequence by one type on every new row.
        return at(row+col)
    end
    return at(index-1)
end

local EggState={}; local HeldEgg=nil
local Carry=Instance.new("Frame"); Carry.AnchorPoint=Vector2.new(.5,1); Carry.Position=UDim2.new(.5,0,1,-25); Carry.Size=UDim2.fromOffset(350,58); Carry.BackgroundColor3=C.bg; Carry.BorderSizePixel=0; Carry.Visible=false; Carry.Parent=Gui; corner(Carry,11); stroke(Carry,.05)
local CarryName=label(Carry,"",UDim2.fromOffset(15,8),UDim2.fromOffset(200,42),13); CarryName.Font=Enum.Font.GothamBold
local CarryDrop=button(Carry,"DROP EGG [X]",UDim2.new(1,-128,0,11),UDim2.fromOffset(115,36),false)
local function eggPhysics(o,anchored)
    local function f(p) p.Anchored=anchored; p.CanCollide=false; p.CanTouch=false; p.CanQuery=true; p.Massless=not anchored end
    if o:IsA("BasePart") then f(o) else for _,p in ipairs(o:GetDescendants()) do if p:IsA("BasePart") then f(p) end end end
end
local function scaleEgg(o,v) local f=math.clamp(v,25,500)/100; if o:IsA("Model") then pcall(function() o:ScaleTo(f) end) else o.Size=o.Size*f end; return f end
local function weldEgg(o)
    if not o:IsA("Model") then return end; local r=rootOf(o); if not r then return end
    for _,p in ipairs(o:GetDescendants()) do if p:IsA("BasePart") and p~=r and not p:FindFirstChild("SAE_Weld") then local w=Instance.new("WeldConstraint"); w.Name="SAE_Weld"; w.Part0=r; w.Part1=p; w.Parent=p end end
end
local function carryEgg(egg,carrier,key,model)
    local st=EggState[egg]
    if not st or st.carried or st.delivered then return false end
    st.carried=true
    st.claim=key
    st.carrier=key
    if st.prompt then st.prompt.Enabled=false end

    local visualHeight=4
    pcall(function()
        if egg:IsA("Model") then visualHeight=egg:GetExtentsSize().Y
        elseif egg:IsA("BasePart") then visualHeight=egg.Size.Y end
    end)
    local lift=.9+math.clamp(visualHeight*.10,0,1.4)

    eggPhysics(egg,true)
    pivot(egg,carrier.CFrame*CFrame.new(0,lift,-2.8))
    weldEgg(egg)
    local er=rootOf(egg)
    if not er then st.carried=false; st.claim=nil; return false end

    eggPhysics(egg,false)
    local w=Instance.new("WeldConstraint")
    w.Name="SAE_CarryWeld"
    w.Part0=carrier
    w.Part1=er
    w.Parent=er
    return true
end
local function dropEgg(egg,pos,delivered)
    if not egg or not egg.Parent then return end; local r=rootOf(egg); if r then local w=r:FindFirstChild("SAE_CarryWeld"); if w then w:Destroy() end end
    eggPhysics(egg,true); groundObject(egg,pos,math.random(0,359)); local st=EggState[egg]; if st then st.carried=false; st.carrier=nil; st.claim=nil; st.delivered=delivered==true; if st.prompt then st.prompt.Enabled=not st.delivered end end
end
local function dropHeld()
    if not HeldEgg or not HeldEgg.Parent then HeldEgg=nil; Carry.Visible=false; return end
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); if not r then return end; local e=HeldEgg; HeldEgg=nil; dropEgg(e,r.Position+r.CFrame.LookVector*6,false); Carry.Visible=false
end
CarryDrop.MouseButton1Click:Connect(dropHeld)
local EggByRoot={}
local PickupPrompt=Instance.new("ProximityPrompt")
PickupPrompt.Name="SAE_PickupPrompt"
PickupPrompt.ActionText="Pick Up Egg"
PickupPrompt.ObjectText="Egg"
PickupPrompt.KeyboardKeyCode=Enum.KeyCode.E
PickupPrompt.HoldDuration=.05
PickupPrompt.MaxActivationDistance=12
PickupPrompt.RequiresLineOfSight=false
PickupPrompt.Enabled=false

local function registerEgg(egg,name,scale)
    local r=rootOf(egg)
    if not r then return end
    EggState[egg]={name=name,scale=scale,prompt=nil,carried=false,delivered=false,claim=nil}
    EggByRoot[r]=egg
end

PickupPrompt.Triggered:Connect(function()
    local r=PickupPrompt.Parent
    local egg=r and EggByRoot[r] or nil
    if not egg or HeldEgg then return end
    local cr=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if cr and carryEgg(egg,cr,"PLAYER",P.Character) then
        HeldEgg=egg
        CarryName.Text="CARRYING: "..(EggState[egg] and EggState[egg].name or egg.Name)
        Carry.Visible=true
        PickupPrompt.Enabled=false
    end
end)

-- Only one live prompt is needed, even for 500 eggs. It follows the nearest egg.
task.spawn(function()
    while Gui.Parent do
        task.wait(.12)
        if HeldEgg then
            PickupPrompt.Enabled=false
        else
            local cr=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
            local nearest=nil
            local nearestRoot=nil
            local best=12
            if cr then
                for egg,st in pairs(EggState) do
                    if egg and egg.Parent and not st.carried and not st.delivered then
                        local r=rootOf(egg)
                        if r then
                            local d=(r.Position-cr.Position).Magnitude
                            if d<best then
                                best=d
                                nearest=egg
                                nearestRoot=r
                            end
                        end
                    end
                end
            end
            if nearest and nearestRoot then
                if PickupPrompt.Parent~=nearestRoot then PickupPrompt.Parent=nearestRoot end
                PickupPrompt.ObjectText=EggState[nearest].name or nearest.Name
                PickupPrompt.Enabled=true
            else
                PickupPrompt.Enabled=false
            end
        end
    end
end)

local function spawnEggs(name,count,size,pattern,customCF,batchTag)
    local mix=nil
    if name=="MIXED" then
        mix=availableEggs()
        if arrlen(mix)==0 then
            return false,"None of the configured egg visuals are replicated to this client."
        end
    elseif not templateInfo(name) then
        return false,name.." visual is not replicated to this client."
    end

    count=math.clamp(tonumber(count) or 1,1,500)
    size=math.clamp(tonumber(size) or 100,25,500)
    pattern=pattern or PATTERNS[1]

    -- Measure this batch before placing it. For MIXED we use the largest visual
    -- footprint in the available set so no larger egg silently closes the gap.
    local baseFootX=4
    local baseFootZ=4
    local function includeFootprint(eggName)
        local inf=eggName and templateInfo(eggName) or nil
        local sz=inf and inf.size or nil
        if sz then
            baseFootX=math.max(baseFootX,sz.X)
            baseFootZ=math.max(baseFootZ,sz.Z)
        end
    end
    if name=="MIXED" then
        for _,eggName in ipairs(mix) do includeFootprint(eggName) end
    else
        includeFootprint(name)
    end
    local visualScale=size/100
    local footprintX=baseFootX*visualScale
    local footprintZ=baseFootZ*visualScale

    local baseCF,bounds=visibleSpawnFrame(customCF,count,pattern,size)
    local centerHit=groundHitNear(baseCF.Position,nil)
    local baseY=centerHit and centerHit.Position.Y or baseCF.Position.Y
    local forward=Vector3.new(baseCF.LookVector.X,0,baseCF.LookVector.Z)
    if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
    baseCF=CFrame.lookAt(Vector3.new(baseCF.Position.X,baseY,baseCF.Position.Z),
        Vector3.new(baseCF.Position.X,baseY,baseCF.Position.Z)+forward)

    local made=0
    local lastCols=0
    local lastRows=0

    for i=1,count do
        local wanted,row,col,cols,rows,_,_,rowCols=layoutPosition(i,count,size,baseCF,bounds,pattern,footprintX,footprintZ)
        lastCols=cols
        lastRows=rows

        local en=name
        if name=="MIXED" then en=mixedEggFor(pattern,mix,row,col,i,rowCols or cols) end

        local info=en and templateInfo(en) or nil
        if info then
            local ok=pcall(function()
                local egg=info.template:Clone()
                egg.Name=en
                if batchTag then egg:SetAttribute("SAE_Batch",batchTag) end
                egg.Parent=EggFolder

                local scale=scaleEgg(egg,size)
                eggPhysics(egg,true)

                local y=baseY-(info.bottomOffset*scale)+.08
                local cf=CFrame.new(wanted.X,y,wanted.Z)
                pivot(egg,cf)

                registerEgg(egg,en,scale)
                made=made+1
            end)
        end

        if i%25==0 then task.wait() end
    end

    if made<=0 then
        return false,"The game egg visuals were found, but none could be cloned."
    end
    return true,made,lastCols,lastRows,0
end

local function clearSpawnedEggs(batchTag)
    local removed=0
    for _,e in ipairs(EggFolder:GetChildren()) do
        if (not batchTag) or e:GetAttribute("SAE_Batch")==batchTag then
            local r=rootOf(e)
            if r then
                if PickupPrompt.Parent==r then PickupPrompt.Enabled=false; PickupPrompt.Parent=nil end
                EggByRoot[r]=nil
            end
            EggState[e]=nil
            pcall(function() e:Destroy() end)
            removed=removed+1
        end
    end
    if HeldEgg and not HeldEgg.Parent then HeldEgg=nil; Carry.Visible=false end
    return removed
end

local function countBatch(tag)
    local n=0
    for _,e in ipairs(EggFolder:GetChildren()) do
        if e:GetAttribute("SAE_Batch")==tag then n=n+1 end
    end
    return n
end

-- Character tag.
local TagTextColor=Color3.fromRGB(245,245,250)
local RoleLabels={OWNER="Owner",["CO-OWNER"]="Co-Owner",ADMIN="Admin",["CONTENT CREATOR"]="Content Creator",DEVELOPER="Developer"}
local RoleIcons={OWNER="👑",["CO-OWNER"]="👑",ADMIN="⚙️",["CONTENT CREATOR"]="🎬",DEVELOPER="🔨"}
local Role="OWNER"; local Display=P.DisplayName; local Username=P.Name
local TagAdornee=nil
local TagShineTween=nil
local function setTagAdornee(part)
    TagAdornee=part
    local head=P.Character and P.Character:FindFirstChild("Head")
    local tag=head and head:FindFirstChild("SAE_Tag")
    if tag and tag:IsA("BillboardGui") then tag.Adornee=part or head end
end
local function applyTag()
    local ch=P.Character
    if not ch then return end
    local h=ch:FindFirstChildOfClass("Humanoid")
    local head=ch:FindFirstChild("Head")
    if h then
        h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        h.NameDisplayDistance=0
        h.HealthDisplayDistance=0
    end
    if not head then return end
    if TagShineTween then TagShineTween:Cancel(); TagShineTween=nil end
    local old=head:FindFirstChild("SAE_Tag")
    if old then old:Destroy() end
    local g=Instance.new("BillboardGui")
    g.Name="SAE_Tag"
    g.Size=UDim2.fromOffset(235,76)
    g.StudsOffsetWorldSpace=Vector3.new(0,2.2,0)
    g.Adornee=TagAdornee or head
    g.AlwaysOnTop=true
    g.Parent=head

    local roleText=RoleLabels[Role] or Role
    local roleHeader=Instance.new("Frame")
    roleHeader.BackgroundTransparency=1
    roleHeader.Size=UDim2.new(1,0,0,27)
    roleHeader.Parent=g
    local roleLayout=Instance.new("UIListLayout")
    roleLayout.FillDirection=Enum.FillDirection.Horizontal
    roleLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    roleLayout.VerticalAlignment=Enum.VerticalAlignment.Center
    roleLayout.Padding=UDim.new(0,3)
    roleLayout.Parent=roleHeader
    local icon=label(roleHeader,RoleIcons[Role] or "",UDim2.new(),UDim2.fromOffset(24,27),20)
    icon.LayoutOrder=1
    icon.Font=Enum.Font.GothamBlack
    icon.TextXAlignment=Enum.TextXAlignment.Center
    icon.TextColor3=C.white
    icon.TextStrokeTransparency=1
    local roleWidth=math.ceil(TextService:GetTextSize(roleText,20,Enum.Font.GothamBlack,Vector2.new(220,27)).X+2)
    local a=label(roleHeader,roleText,UDim2.new(),UDim2.fromOffset(math.min(205,roleWidth),27),20)
    a.LayoutOrder=2
    a.Font=Enum.Font.GothamBlack
    a.TextXAlignment=Enum.TextXAlignment.Left
    a.TextStrokeTransparency=0
    a.TextStrokeColor3=Color3.new(0,0,0)
    a.TextColor3=TagTextColor
    if RoleLabels[Role] then
        -- The text shine stays on the words; the emoji remains independent of the color picker.
        local shine=label(a,roleText,UDim2.new(),UDim2.new(1,0,1,0),20)
        shine.Font=a.Font
        shine.TextXAlignment=Enum.TextXAlignment.Left
        shine.TextColor3=C.white
        shine.TextStrokeTransparency=1
        local gradient=Instance.new("UIGradient")
        local edgeColor=TagTextColor:Lerp(Color3.new(0,0,0),.22)
        local shineMid=TagTextColor:Lerp(Color3.new(1,1,1),.28)
        local shinePeak=TagTextColor:Lerp(Color3.new(1,1,1),.88)
        gradient.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,edgeColor),
            ColorSequenceKeypoint.new(.42,shineMid),
            ColorSequenceKeypoint.new(.5,shinePeak),
            ColorSequenceKeypoint.new(.58,shineMid),
            ColorSequenceKeypoint.new(1,edgeColor)
        })
        gradient.Rotation=15
        gradient.Offset=Vector2.new(-1,0)
        gradient.Parent=shine
        TagShineTween=TweenService:Create(gradient,
            TweenInfo.new(2.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false,.8),
            {Offset=Vector2.new(1,0)})
        TagShineTween:Play()
    end

    local nameRow=Instance.new("Frame")
    nameRow.BackgroundTransparency=1
    nameRow.Position=UDim2.fromOffset(0,29)
    nameRow.Size=UDim2.new(1,0,0,22)
    nameRow.Parent=g
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Center
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,3)
    layout.Parent=nameRow
    local nameWidth=math.min(205,TextService:GetTextSize(Display,18,Enum.Font.GothamBold,Vector2.new(1000,22)).X+2)
    local b=label(nameRow,Display,UDim2.new(),UDim2.fromOffset(nameWidth,22),18)
    b.LayoutOrder=1
    b.Font=Enum.Font.GothamBold
    b.TextTruncate=Enum.TextTruncate.AtEnd
    b.TextStrokeTransparency=.1
    local badge=verified(nameRow,18)
    badge.LayoutOrder=2

    local c=label(g,"@"..Username:gsub("^@",""),UDim2.fromOffset(0,52),UDim2.new(1,0,0,18),14)
    c.TextXAlignment=Enum.TextXAlignment.Center
    c.Font=Enum.Font.GothamBold
    c.TextColor3=Color3.fromRGB(242,242,247)
    c.TextStrokeColor3=Color3.new(0,0,0)
    c.TextStrokeTransparency=.1
end

-- Role buttons control the overhead tag and reflect its selected state.
local RoleSelectors={}
local function setRole(role)
    Role=role
    applyTag()
    for _,selector in ipairs(RoleSelectors) do
        selector.owner:SetAttribute("RestingColor",role=="OWNER" and C.purple or C.card2)
        selector.coowner:SetAttribute("RestingColor",role=="CO-OWNER" and C.purple or C.card2)
        selector.admin:SetAttribute("RestingColor",role=="ADMIN" and C.purple or C.card2)
        if selector.creator then selector.creator:SetAttribute("RestingColor",role=="CONTENT CREATOR" and C.purple or C.card2) end
        if selector.developer then selector.developer:SetAttribute("RestingColor",role=="DEVELOPER" and C.purple or C.card2) end
        if selector.status then
            selector.status.Text=(RoleLabels[role] or role).." tag applied."
            selector.status.TextColor3=C.green
        end
    end
end
local function addRoleSelector(owner,coowner,admin,creator,developer,status)
    table.insert(RoleSelectors,{owner=owner,coowner=coowner,admin=admin,creator=creator,developer=developer,status=status})
    owner:SetAttribute("RestingColor",Role=="OWNER" and C.purple or C.card2)
    coowner:SetAttribute("RestingColor",Role=="CO-OWNER" and C.purple or C.card2)
    admin:SetAttribute("RestingColor",Role=="ADMIN" and C.purple or C.card2)
    if creator then creator:SetAttribute("RestingColor",Role=="CONTENT CREATOR" and C.purple or C.card2) end
    if developer then developer:SetAttribute("RestingColor",Role=="DEVELOPER" and C.purple or C.card2) end
    owner.MouseButton1Click:Connect(function() setRole("OWNER") end)
    coowner.MouseButton1Click:Connect(function() setRole("CO-OWNER") end)
    admin.MouseButton1Click:Connect(function() setRole("ADMIN") end)
    if creator then creator.MouseButton1Click:Connect(function() setRole("CONTENT CREATOR") end) end
    if developer then developer.MouseButton1Click:Connect(function() setRole("DEVELOPER") end) end
end

-- Client-side appearance. Keep the real character and its controls untouched.
local MorphShell=nil; local MorphConn=nil; local MorphAnim=nil; local Hidden={}
local MorphDescConn=nil
local MorphVisibilityBound=false
local MorphVisibilityStep="SAE_MorphVisibility_"..P.UserId
local function restoreChar()
    for o,v in pairs(Hidden) do
        if o and o.Parent then
            pcall(function()
                if o:IsA("BasePart") then o.LocalTransparencyModifier=v
                elseif o:IsA("Decal") or o:IsA("Texture") then o.Transparency=v end
            end)
        end
    end
    Hidden={}
end
local function keepHidden(o)
    if o:IsA("BasePart") then
        if Hidden[o]==nil then Hidden[o]=o.LocalTransparencyModifier end
        o.LocalTransparencyModifier=1
    elseif o:IsA("Decal") or o:IsA("Texture") then
        if Hidden[o]==nil then Hidden[o]=o.Transparency end
        o.Transparency=1
    end
end
local function hideChar(ch)
    restoreChar()
    for _,o in ipairs(ch:GetDescendants()) do keepHidden(o) end
    MorphDescConn=ch.DescendantAdded:Connect(function(o)
        if not MorphShell or P.Character~=ch then return end
        keepHidden(o)
        for _,child in ipairs(o:GetDescendants()) do keepHidden(child) end
    end)
    -- Other local scripts may make the real body visible again during
    -- interactions. Reapply the cosmetic hiding after render updates.
    RunService:BindToRenderStep(MorphVisibilityStep,Enum.RenderPriority.Last.Value+1,function()
        if not MorphShell or P.Character~=ch then return end
        for o in pairs(Hidden) do
            if o.Parent and o:IsDescendantOf(ch) then
                if o:IsA("BasePart") then
                    if o.LocalTransparencyModifier~=1 then o.LocalTransparencyModifier=1 end
                elseif o:IsA("Decal") or o:IsA("Texture") then
                    if o.Transparency~=1 then o.Transparency=1 end
                end
            end
        end
    end)
    MorphVisibilityBound=true
end
local function resetMorph()
    if MorphConn then MorphConn:Disconnect(); MorphConn=nil end
    if MorphVisibilityBound then
        RunService:UnbindFromRenderStep(MorphVisibilityStep)
        MorphVisibilityBound=false
    end
    if MorphDescConn then MorphDescConn:Disconnect(); MorphDescConn=nil end
    setTagAdornee(nil)
    if MorphShell then MorphShell:Destroy(); MorphShell=nil end
    MorphAnim=nil
    restoreChar()
end

local function connectedParts(root)
    local connected={[root]=true}
    for _,part in ipairs(root:GetConnectedParts(true)) do connected[part]=true end
    return connected
end

local function repairAvatarRig(model,root,humanoid)
    -- Client-created avatar models can omit accessory welds. Build the body
    -- joints first, then weld each loose handle by matching attachments.
    pcall(function() humanoid:BuildRigFromAttachments() end)
    local connected=connectedParts(root)
    local body={}
    for _,part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(body,part)
            if part~=root and not connected[part] then
                local joint=Instance.new("WeldConstraint")
                joint.Name="SAE_BodyFallback"
                joint.Part0=root; joint.Part1=part; joint.Parent=root
            end
        end
    end
    connected=connectedParts(root)
    for _,item in ipairs(model:GetChildren()) do
        if item:IsA("Accessory") then
            local handle=item:FindFirstChild("Handle")
            if not handle or not handle:IsA("BasePart") then return false end
            local bodyAttachment,handleAttachment
            for _,att in ipairs(handle:GetDescendants()) do
                if att:IsA("Attachment") and att.Parent:IsA("BasePart") then
                    for _,part in ipairs(body) do
                        local match=part:FindFirstChild(att.Name,true)
                        if match and match:IsA("Attachment") and match.Parent:IsA("BasePart") then
                            bodyAttachment=match; handleAttachment=att; break
                        end
                    end
                end
                if bodyAttachment then break end
            end
            if bodyAttachment then
                -- Match the two attachment frames even if a stale weld exists.
                for _,joint in ipairs(handle:GetChildren()) do
                    if joint:IsA("JointInstance") and
                        (joint.Name=="AccessoryWeld" or not joint.Part0 or not joint.Part1) then
                        joint:Destroy()
                    end
                end
                local joint=Instance.new("Weld")
                joint.Name="AccessoryWeld"
                joint.Part0=bodyAttachment.Parent
                joint.Part1=handleAttachment.Parent
                joint.C0=bodyAttachment.CFrame
                joint.C1=handleAttachment.CFrame
                handle.CFrame=joint.Part0.CFrame*joint.C0*joint.C1:Inverse()
                joint.Parent=handle
            elseif not connected[handle] then
                return false
            end
        end
    end
    connected=connectedParts(root)
    -- Keep extra pieces in a multi-part accessory attached to its handle.
    for _,item in ipairs(model:GetChildren()) do
        if item:IsA("Accessory") then
            local handle=item:FindFirstChild("Handle")
            for _,part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") and part~=handle and not connected[part] then
                    local joint=Instance.new("WeldConstraint")
                    joint.Name="SAE_AccessoryFallback"
                    joint.Part0=handle; joint.Part1=part; joint.Parent=handle
                end
            end
        end
    end
    connected=connectedParts(root)
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and not connected[part] then return false end
    end
    return true
end

local function doMorph(user)
    local uid
    if not pcall(function() uid=Players:GetUserIdFromNameAsync(user) end) then return false,"Username not found." end
    local model
    if not pcall(function() model=createAvatar(uid) end) or not model then return false,"Avatar could not be created." end

    local character=P.Character
    local realRoot=character and character:FindFirstChild("HumanoidRootPart")
    local realHumanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    if not realRoot or not realHumanoid or not root or not humanoid then
        model:Destroy()
        return false,"Character or avatar rig unavailable."
    end

    -- A visual pose copy needs the same body-part names as the player rig.
    if humanoid.RigType~=realHumanoid.RigType then
        local matched
        local ok=pcall(function()
            local description=Players:GetHumanoidDescriptionFromUserIdAsync(uid)
            matched=Players:CreateHumanoidModelFromDescriptionAsync(description,realHumanoid.RigType)
        end)
        model:Destroy()
        if not ok or not matched then return false,"This avatar rig could not be matched to your character." end
        model=matched
        root=model:FindFirstChild("HumanoidRootPart")
        humanoid=model:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then model:Destroy(); return false,"Matched avatar rig unavailable." end
    end

    local camera=workspace.CurrentCamera
    if not camera then model:Destroy(); return false,"Camera unavailable." end
    model.PrimaryPart=root
    model:PivotTo(realRoot.CFrame)
    model.Parent=camera
    local rigOk,assembled=pcall(function() return repairAvatarRig(model,root,humanoid) end)
    if not rigOk or not assembled or P.Character~=character then
        model:Destroy()
        return false,"Avatar parts could not be attached; your appearance was kept."
    end
    -- Remove any joint that accidentally points outside the cosmetic model.
    for _,joint in ipairs(model:GetDescendants()) do
        if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
            local p0,p1=joint.Part0,joint.Part1
            if (p0 and not p0:IsDescendantOf(model)) or (p1 and not p1:IsDescendantOf(model)) then
                joint:Destroy()
            end
        end
    end
    for part in pairs(connectedParts(root)) do
        if not part:IsDescendantOf(model) then
            model:Destroy()
            return false,"Avatar rig was not isolated; your appearance was kept."
        end
    end

    local bodyPairs={}
    local bodyMap={}
    for _,part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local realPart=character:FindFirstChild(part.Name)
            if not realPart or not realPart:IsA("BasePart") then
                model:Destroy()
                return false,"Avatar body could not match your character."
            end
            bodyMap[part]=realPart
            table.insert(bodyPairs,{visual=part,real=realPart})
        end
    end

    -- Preserve the target avatar's own joint offsets. Matching body-part
    -- centers directly leaves gaps when the two avatars have different sizes.
    local function jointFrames(joint)
        if joint:IsA("Motor6D") then
            return joint.Part0,joint.Part1,joint.C0,joint.C1
        elseif joint:IsA("AnimationConstraint") then
            local a0,a1=joint.Attachment0,joint.Attachment1
            if a0 and a1 then return a0.Parent,a1.Parent,a0.CFrame,a1.CFrame end
        end
    end
    local realJoints={}
    for _,joint in ipairs(character:GetDescendants()) do
        local p0,p1,c0,c1=jointFrames(joint)
        if p0 and p1 and p0:IsA("BasePart") and p1:IsA("BasePart")
            and character:FindFirstChild(p0.Name)==p0 and character:FindFirstChild(p1.Name)==p1 then
            realJoints[p0.Name.."|"..p1.Name]={c0=c0,c1=c1}
        end
    end
    local poseEdges={}
    for _,joint in ipairs(model:GetDescendants()) do
        local p0,p1,c0,c1=jointFrames(joint)
        if p0 and p1 and bodyMap[p0] and bodyMap[p1] then
            local real=realJoints[p0.Name.."|"..p1.Name]
            if not real then
                local reversed=realJoints[p1.Name.."|"..p0.Name]
                if reversed then real={c0=reversed.c1,c1=reversed.c0} end
            end
            if real then
                table.insert(poseEdges,{part0=p0,part1=p1,c0=c0,c1=c1,
                    realPart0=bodyMap[p0],realPart1=bodyMap[p1],
                    realC0=real.c0,realC1=real.c1})
            end
        end
    end
    local orderedPose={}
    local seen={[root]=true}
    -- Traverse from the root so every parent is positioned before its child.
    for _=1,#bodyPairs do
        local added=false
        for _,edge in ipairs(poseEdges) do
            if seen[edge.part0] ~= seen[edge.part1] then
                edge.forward=seen[edge.part0]
                seen[edge.part0]=true
                seen[edge.part1]=true
                table.insert(orderedPose,edge)
                added=true
            end
        end
        if not added then break end
    end
    for _,pair in ipairs(bodyPairs) do
        if not seen[pair.visual] then
            model:Destroy()
            return false,"Avatar body joints could not match your character."
        end
    end

    -- Capture where each accessory sits relative to its target body part.
    local accessories={}
    for _,item in ipairs(model:GetChildren()) do
        if item:IsA("Accessory") then
            local handle=item:FindFirstChild("Handle")
            if not handle or not handle:IsA("BasePart") then
                model:Destroy()
                return false,"Avatar accessory could not be displayed."
            end
            local attachedTo
            for _,joint in ipairs(handle:GetChildren()) do
                if joint:IsA("JointInstance") then
                    if joint.Part0==handle and bodyMap[joint.Part1] then attachedTo=joint.Part1; break end
                    if joint.Part1==handle and bodyMap[joint.Part0] then attachedTo=joint.Part0; break end
                end
            end
            attachedTo=attachedTo or root
            local info={handle=handle,body=attachedTo,offset=attachedTo.CFrame:ToObjectSpace(handle.CFrame),extras={}}
            for _,part in ipairs(item:GetDescendants()) do
                if part:IsA("BasePart") and part~=handle then
                    table.insert(info.extras,{part=part,offset=handle.CFrame:ToObjectSpace(part.CFrame)})
                end
            end
            table.insert(accessories,info)
        end
    end

    -- These are display parts only. No moving or welded assembly is added
    -- to the player's real character or simulated beside it.
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.Anchored=true
        end
    end
    pcall(function() humanoid.EvaluateStateMachine=false end)
    humanoid.AutoRotate=false
    humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    humanoid.NameDisplayDistance=0
    humanoid.HealthDisplayDistance=0

    -- HipHeight can stay the same even when an avatar's visible legs are
    -- shorter. Measure the actual leg bounds after the first copied pose.
    local function legBottom(rig,rigType)
        local names
        if rigType==Enum.HumanoidRigType.R15 then
            names={"LeftFoot","RightFoot","LeftLowerLeg","RightLowerLeg","LeftUpperLeg","RightUpperLeg"}
        else
            names={"Left Leg","Right Leg"}
        end
        local lowest
        for _,name in ipairs(names) do
            local part=rig:FindFirstChild(name)
            if part and part:IsA("BasePart") and part.Transparency<.95 then
                local cf,size=part.CFrame,part.Size
                local extent=(math.abs(cf.XVector.Y)*size.X
                    +math.abs(cf.YVector.Y)*size.Y
                    +math.abs(cf.ZVector.Y)*size.Z)/2
                local bottom=cf.Position.Y-extent
                lowest=lowest and math.min(lowest,bottom) or bottom
            end
        end
        return lowest
    end
    local visualHeightOffset=nil

    local function copyPose()
        for _,pair in ipairs(bodyPairs) do
            if not pair.visual.Parent or not pair.real.Parent then return false end
        end
        root.CFrame=realRoot.CFrame+Vector3.new(0,visualHeightOffset or 0,0)
        for _,edge in ipairs(orderedPose) do
            -- Recover the live joint pose from the real character, then apply
            -- that pose around the target avatar's shoulder/neck/hip offsets.
            local motion=edge.realC0:Inverse()*edge.realPart0.CFrame:Inverse()
                *edge.realPart1.CFrame*edge.realC1
            if edge.forward then
                edge.part1.CFrame=edge.part0.CFrame*edge.c0*motion*edge.c1:Inverse()
            else
                edge.part0.CFrame=edge.part1.CFrame*edge.c1*motion:Inverse()*edge.c0:Inverse()
            end
        end
        if visualHeightOffset==nil then
            local visualBottom=legBottom(model,humanoid.RigType)
            local realBottom=legBottom(character,realHumanoid.RigType)
            local floorY
            if realHumanoid.FloorMaterial~=Enum.Material.Air then
                local params=RaycastParams.new()
                params.FilterType=Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances={character,model,EggFolder}
                params.RespectCanCollide=true
                local hit=workspace:Raycast(realRoot.Position,Vector3.new(0,-12,0),params)
                if hit then floorY=hit.Position.Y end
            end
            if visualBottom and (floorY or realBottom) then
                visualHeightOffset=(floorY or realBottom)-visualBottom+.02
            else
                -- A rig without visible leg parts still gets a safe height.
                visualHeightOffset=(root.Size.Y-realRoot.Size.Y)/2
                    +humanoid.HipHeight-realHumanoid.HipHeight
            end
            local shift=Vector3.new(0,visualHeightOffset,0)
            for _,pair in ipairs(bodyPairs) do pair.visual.CFrame=pair.visual.CFrame+shift end
        end
        for _,info in ipairs(accessories) do
            info.handle.CFrame=info.body.CFrame*info.offset
            for _,extra in ipairs(info.extras) do
                extra.part.CFrame=info.handle.CFrame*extra.offset
            end
        end
        return true
    end
    if not copyPose() then model:Destroy(); return false,"Character changed during morph." end

    resetMorph()
    model.Name="SAE_MorphShell"
    MorphShell=model
    MorphConn=RunService.RenderStepped:Connect(function()
        if MorphShell~=model or not model:IsDescendantOf(workspace) or P.Character~=character or not copyPose() then
            resetMorph()
        end
    end)
    hideChar(character)
    setTagAdornee(model:FindFirstChild("Head"))
    return true,"Morphed into @"..user.." (local appearance)"
end

-- Safe-zone detection retained for the local egg placement helper.
local function objPos(o) if not o then return nil end; if o:IsA("BasePart") then return o.Position elseif o:IsA("Model") then return o:GetPivot().Position end end
detectSafe=function()
    local pr=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); local pp=pr and pr.Position or Vector3.zero; local best=nil; local score=-1e9
    for _,o in ipairs(workspace:GetDescendants()) do
        if (o:IsA("BasePart") or o:IsA("Model")) and not o:IsDescendantOf(EggFolder) then
            local n=norm(o.Name); local s=0; if n:find("eggdropoff",1,true) then s=7000 elseif n:find("safezone",1,true) then s=6500 elseif n:find("deposit",1,true) then s=6000 elseif n:find("collector",1,true) then s=5200 elseif n:find("playerbase",1,true) then s=4700 elseif n:find("homebase",1,true) then s=4500 elseif n:find("safe",1,true) then s=4000 elseif n:find("base",1,true) then s=2800 elseif n:find("plot",1,true) then s=2500 end
            if s>0 then local p=objPos(o); if p then s=s-(p-pp).Magnitude*.05 end; for _,a in ipairs({"Owner","OwnerName","Player","PlayerName","OwnerId","OwnerUserId","UserId"}) do local v=o:GetAttribute(a); if v and (tostring(v)==P.Name or tostring(v)==P.DisplayName or tonumber(v)==P.UserId) then s=s+5000 end end; if s>score then score=s; best=o end end
        end
    end
    if not best then return false,"Safe zone not auto-detected." end; SafeObj=best; SafePos=objPos(best); SafeName=best.Name; return true,SafeName
end

-- Reference-script style boost/event controls. Without a configured legitimate server remote,
-- these remain local control/announcement states rather than pretending to change the server.
local BOOST_NAMES={
    "PowerUpX2Rings","AdBoostXGrowth","MutationBoost","PowerUpMagnet","PlayerEggGrowthBoost","PowerUpFusion",
    "GrowthBoost","AdminTreadmill","PlayerSpeedBoost","x2Growth","MonsterEvent","PlayerEarningsBoost",
    "EggLuckBoost","BossSpeedBoost","GreatBloom","DragonEggEvent","EggSizeBoost","x2Luck","SpeedBoost",
    "DemonicEvent","EarningsBoost","Countdown","Luck"
}
local BoostState={}
for _,n in ipairs(BOOST_NAMES) do BoostState[n]=false end

local function announceBoost(name,on)
    BoostState[name]=on
    if on then
        callRemote("Boost",name,true)
        notice(P.UserId,Display,": activated",name:upper(),"")
    else
        callRemote("ClearBoost",name)
        notice(P.UserId,Display,": cleared",name:upper(),"")
    end
end

local MeteorFolder=nil
local MeteorToken=0
local function clearMeteor()
    MeteorToken=MeteorToken+1
    if MeteorFolder then MeteorFolder:Destroy(); MeteorFolder=nil end
end

local function findNamedModel(words)
    local wants={}
    for _,w in ipairs(words) do wants[norm(w)]=true end
    for _,container in ipairs({ReplicatedStorage,workspace}) do
        for _,o in ipairs(container:GetDescendants()) do
            if o:IsA("Model") and o:FindFirstChildWhichIsA("BasePart",true) and wants[norm(o.Name)] then return o end
        end
    end
    return nil
end

local function dropMeteorNow()
    if callRemote("Meteor",{Action="Drop"}) then return true,"Server meteor request sent." end
    clearMeteor()
    local cf,bounds=getMapFrame()
    local folder=Instance.new("Folder")
    folder.Name="SAE_MeteorEvent"
    folder.Parent=workspace
    MeteorFolder=folder

    local meteor=Instance.new("Part")
    meteor.Name="Drill Monster Meteor"
    meteor.Shape=Enum.PartType.Ball
    meteor.Size=Vector3.new(12,12,12)
    meteor.Material=Enum.Material.Neon
    meteor.Color=Color3.fromRGB(255,80,35)
    meteor.Anchored=true
    meteor.CanCollide=false
    meteor.Position=cf.Position+Vector3.new(0,90,0)
    meteor.Parent=folder
    local fire=Instance.new("ParticleEmitter")
    fire.Rate=80; fire.Lifetime=NumberRange.new(.35,.7); fire.Speed=NumberRange.new(4,9)
    fire.Color=ColorSequence.new(Color3.fromRGB(255,210,30),Color3.fromRGB(255,40,20))
    fire.Parent=meteor

    local hit=groundHit(cf.Position,nil)
    local ground=hit and hit.Position or cf.Position
    local tw=TweenService:Create(meteor,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=ground+Vector3.new(0,7,0)})
    tw:Play()
    task.spawn(function()
        tw.Completed:Wait()
        if not meteor.Parent then return end
        local burst=Instance.new("Explosion")
        burst.BlastPressure=0; burst.BlastRadius=0; burst.Position=ground; burst.Parent=workspace
        local monster=findNamedModel({"Drill Monster","DrillMonster"})
        if monster then
            for i=1,4 do
                local ok=pcall(function()
                    local c=monster:Clone(); c.Parent=folder; local a=(i-1)*math.pi/2; groundObject(c,ground+Vector3.new(math.cos(a)*16,0,math.sin(a)*16),0)
                end)
            end
        end
        spawnEggs("Drilla egg",10,100,"DIAGONAL SEQUENCE",CFrame.new(ground),"METEOR")
        meteor:Destroy()
    end)
    return true,"Meteor dropped at map center."
end

local function startMeteorCountdown(seconds,statusCallback)
    seconds=math.clamp(tonumber(seconds) or 50,1,600)
    MeteorToken=MeteorToken+1
    local token=MeteorToken
    task.spawn(function()
        for s=seconds,0,-1 do
            if token~=MeteorToken then return end
            if statusCallback then statusCallback(s) end
            if s==0 then break end
            task.wait(1)
        end
        if token==MeteorToken then dropMeteorNow() end
    end)
end

-- MAIN navigation and reference-style pages.
local Nav=Instance.new("Frame")
Nav.Position=UDim2.fromOffset(10,66)
Nav.Size=UDim2.new(1,-20,0,28)
Nav.BackgroundTransparency=1
Nav.Parent=Main
local BackBtn=button(Nav,"Back",UDim2.fromOffset(0,0),UDim2.fromOffset(60,27),true)
BackBtn:SetAttribute("RestingColor",C.purple)
BackBtn.BackgroundTransparency=.76
local backOutline=stroke(BackBtn,.68); backOutline.Color=C.purple2
local PageTitle=label(Nav,"",UDim2.fromOffset(70,0),UDim2.new(1,-70,0,27),13)
PageTitle.Font=Enum.Font.GothamBold

local AdminHost=Instance.new("Frame")
AdminHost.Position=UDim2.fromOffset(10,100)
AdminHost.Size=UDim2.new(1,-20,1,-110)
AdminHost.BackgroundTransparency=1
AdminHost.ClipsDescendants=true
AdminHost.Parent=Main
local AdminPages={}
local PageStack={}

local function newAdminPage(name,scrolling)
    local f
    if scrolling then
        f=Instance.new("ScrollingFrame")
        f.CanvasSize=UDim2.new()
        f.ScrollBarThickness=4
        f.ScrollBarImageColor3=C.purple
        f.ScrollingDirection=Enum.ScrollingDirection.Y
    else
        f=Instance.new("Frame")
    end
    f.Name=name
    f.Size=UDim2.fromScale(1,1)
    f.BackgroundTransparency=1
    f.BorderSizePixel=0
    f.Visible=false
    f.Parent=AdminHost
    AdminPages[name]=f
    return f
end

local function showAdminPage(name,push)
    if push~=false then
        local current=nil
        for n,p in pairs(AdminPages) do if p.Visible then current=n end end
        if current and current~=name then table.insert(PageStack,current) end
    end
    for n,p in pairs(AdminPages) do p.Visible=(n==name) end
    PageTitle.Text=name
    Nav.Visible=(name~="Home")
    -- Size each branch to its controls instead of leaving a tall empty window.
    local heights={
        Home=172,
        Announcements=336,
        Names=286, ["Avatar Name"]=330, ["Announcements Profile"]=384
    }
    Main.Size=UDim2.fromOffset(344,heights[name] or 398)
    local top=name=="Home" and 68 or 100
    AdminHost.Position=UDim2.fromOffset(10,top)
    AdminHost.Size=UDim2.new(1,-20,1,-top-10)
end

BackBtn.MouseButton1Click:Connect(function()
    local n=table.remove(PageStack)
    if n then showAdminPage(n,false) else showAdminPage("Home",false) end
end)

local HomePage=newAdminPage("Home",false)
local AnnouncePage=newAdminPage("Announcements",false)
local NamesPage=newAdminPage("Names",false)

local Builders={}

function Builders.Home()
-- HOME
local homeItems={
    {"Announce","Announcements"},
    {"Names","Names"},
    {"Gift Panel","Gift Panel"}
}
for i,item in ipairs(homeItems) do
    local row=math.floor((i-1)/2)
    local col=(i-1)%2
    local b=button(HomePage,item[1],UDim2.new(col*.5,4,0,row*46+4),UDim2.new(.5,-8,0,36),true)
    b.TextSize=11
    b:SetAttribute("RestingColor",C.purple)
    b.BackgroundTransparency=.76
    local outline=stroke(b,.72); outline.Color=C.purple2
    b.MouseEnter:Connect(function() outline.Transparency=.48 end)
    b.MouseLeave:Connect(function() outline.Transparency=.72 end)
    b.MouseButton1Click:Connect(function()
        if item[2]=="Gift Panel" then
            Main.Visible=false
            GiftPanel.Visible=true
        else
            showAdminPage(item[2],true)
        end
    end)
end

end
Builders.Home()
Builders.Home=nil
showAdminPage("Home",false)

-- shared slider helper
local function intSlider(parent,y,minv,maxv,step,initial,title,onChange)
    local titleLabel=label(parent,"",UDim2.fromOffset(8,y),UDim2.new(1,-16,0,20),10)
    titleLabel.Font=Enum.Font.GothamBold
    local bar=Instance.new("Frame")
    bar.Position=UDim2.fromOffset(10,y+28)
    bar.Size=UDim2.new(1,-20,0,9)
    bar.BackgroundColor3=C.card2
    bar.BorderSizePixel=0
    bar.Active=true
    bar.Parent=parent
    corner(bar,99)
    local fill=Instance.new("Frame"); fill.BackgroundColor3=C.purple; fill.BorderSizePixel=0; fill.Parent=bar; corner(fill,99)
    local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(17,17); knob.BackgroundColor3=C.white; knob.BorderSizePixel=0; knob.Parent=bar; corner(knob,99)
    local value=initial
    local dragging=false
    local function render()
        local frac=(value-minv)/(maxv-minv)
        fill.Size=UDim2.new(frac,0,1,0)
        knob.Position=UDim2.new(frac,0,.5,0)
        titleLabel.Text=title..": "..tostring(value)
        if onChange then onChange(value) end
    end
    local function update(x)
        local frac=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
        local raw=minv+(maxv-minv)*frac
        value=math.clamp(math.floor(raw/step+.5)*step,minv,maxv)
        render()
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    render()
    return function() return value end,titleLabel
end

function Builders.Announcements()
-- ANNOUNCEMENTS
section(AnnouncePage,"ANNOUNCEMENTS",4)
local annBox=textbox(AnnouncePage,"Type your announcement...",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,42),"")
local annSend=button(AnnouncePage,"Send announcement",UDim2.fromOffset(5,78),UDim2.new(1,-10,0,34),false)
local annGlobal=button(AnnouncePage,"Send global announcement",UDim2.fromOffset(5,118),UDim2.new(1,-10,0,32),true)
local annClear=button(AnnouncePage,"Clear announcement",UDim2.fromOffset(5,156),UDim2.new(1,-10,0,30),true)
local annStatus=label(AnnouncePage,"Uses the name and picture saved in Names.",UDim2.fromOffset(7,194),UDim2.new(1,-14,0,32),11); annStatus.TextWrapped=true; annStatus.TextColor3=C.muted
local function sendAnnouncement(global)
    local msg=annBox.Text
    if msg=="" then annStatus.Text="Type an announcement first."; annStatus.TextColor3=C.orange; return end
    callRemote(global and "GlobalAnnouncement" or "Announcement",msg)
    notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,global and ": sent a" or ": sent an",global and "GLOBAL ANNOUNCEMENT" or "ANNOUNCEMENT","- "..msg,Enum.Font.FredokaOne)
    annStatus.Text=global and "Global announcement displayed." or "Announcement shown."
    annStatus.TextColor3=C.green
end
annSend.MouseButton1Click:Connect(function() sendAnnouncement(false) end)
annGlobal.MouseButton1Click:Connect(function() sendAnnouncement(true) end)
annClear.MouseButton1Click:Connect(function() annBox.Text=""; annStatus.Text="Announcement cleared."; annStatus.TextColor3=C.muted end)
annBox.FocusLost:Connect(function(enter) if enter then sendAnnouncement(false) end end)

end
Builders.Announcements()
Builders.Announcements=nil

function Builders.Names()
-- Names is a menu; the original avatar controls remain on their own page.
local avatarNamesPage=newAdminPage("Avatar Name",false)
local announcementProfilePage=newAdminPage("Announcements Profile",false)
section(NamesPage,"NAME SETTINGS",4)
local avatarNamesBtn=button(NamesPage,"Avatar Name",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,34),true)
local avatarNamesHint=label(NamesPage,"Edit the name and label above your avatar.",UDim2.fromOffset(9,68),UDim2.new(1,-18,0,24),11)
avatarNamesHint.TextWrapped=true; avatarNamesHint.TextColor3=C.muted
local announcementProfileBtn=button(NamesPage,"Announcements Profile",UDim2.fromOffset(5,102),UDim2.new(1,-10,0,34),true)
local announcementProfileHint=label(NamesPage,"Set your announcement name and picture.",UDim2.fromOffset(9,142),UDim2.new(1,-18,0,28),11)
announcementProfileHint.TextWrapped=true; announcementProfileHint.TextColor3=C.muted
avatarNamesBtn.MouseButton1Click:Connect(function() showAdminPage("Avatar Name",true) end)
announcementProfileBtn.MouseButton1Click:Connect(function() showAdminPage("Announcements Profile",true) end)

section(avatarNamesPage,"CUSTOM DISPLAY NAME",4)
local displayInput=textbox(avatarNamesPage,"Display name",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,36),Display)
section(avatarNamesPage,"CUSTOM USERNAME LABEL",76)
local usernameInput=textbox(avatarNamesPage,"Username",UDim2.fromOffset(5,100),UDim2.new(1,-10,0,36),Username)
local applyNameBtn=button(avatarNamesPage,"Apply names",UDim2.fromOffset(5,146),UDim2.new(1,-10,0,34),false)
local nameStatus=label(avatarNamesPage,"Updates the name and label above your avatar.",UDim2.fromOffset(7,190),UDim2.new(1,-14,0,30),11); nameStatus.TextWrapped=true; nameStatus.TextColor3=C.muted
applyNameBtn.MouseButton1Click:Connect(function() if displayInput.Text~="" then Display=displayInput.Text end; if usernameInput.Text~="" then Username=usernameInput.Text:gsub("^@","") end; applyTag(); nameStatus.Text="Custom display updated."; nameStatus.TextColor3=C.green end)

-- Announcement identity is independent of the character's overhead identity.
local profile=CFG.AnnouncementProfile
section(announcementProfilePage,"ANNOUNCEMENT NAME",4)
local announcementNameInput=textbox(announcementProfilePage,"Name shown on announcements",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,36),profile.Name)
section(announcementProfilePage,"ANNOUNCEMENT PROFILE PICTURE",76)
local profilePreview=Instance.new("ImageLabel")
profilePreview.Position=UDim2.fromOffset(5,100)
profilePreview.Size=UDim2.fromOffset(64,64)
profilePreview.BackgroundColor3=C.card2
profilePreview.BorderSizePixel=0
profilePreview.Image="rbxthumb://type=AvatarHeadShot&id="..profile.UserId.."&w=150&h=150"
profilePreview.Parent=announcementProfilePage
corner(profilePreview,10)
local profilePictureInput=textbox(announcementProfilePage,"Username or user ID",UDim2.fromOffset(82,100),UDim2.new(1,-87,0,36),profile.Username)
local profilePictureHint=label(announcementProfilePage,"Use a Roblox username or user ID for the picture.",UDim2.fromOffset(84,142),UDim2.new(1,-89,0,36),11)
profilePictureHint.TextWrapped=true; profilePictureHint.TextColor3=C.muted
local applyProfileBtn=button(announcementProfilePage,"Apply announcement profile",UDim2.fromOffset(5,190),UDim2.new(1,-10,0,34),true)
local profileStatus=label(announcementProfilePage,"Applies to announcements and console notices.",UDim2.fromOffset(7,232),UDim2.new(1,-14,0,42),11)
profileStatus.TextWrapped=true; profileStatus.TextColor3=C.muted
local savingProfile=false
applyProfileBtn.MouseButton1Click:Connect(function()
    if savingProfile then return end
    local name=announcementNameInput.Text:gsub("^%s+",""):gsub("%s+$","")
    local source=profilePictureInput.Text:gsub("^%s+",""):gsub("%s+$",""):gsub("^@","")
    if name=="" then
        profileStatus.Text="Enter an announcement name."; profileStatus.TextColor3=C.orange; return
    end
    if source=="" then
        profileStatus.Text="Enter a username or user ID for the picture."; profileStatus.TextColor3=C.orange; return
    end
    savingProfile=true
    applyProfileBtn.Text="Looking up profile..."
    local userId,accountName
    local ok=pcall(function()
        if source:lower()==profile.Username:lower() or source==tostring(profile.UserId) then
            userId=profile.UserId; accountName=profile.Username
        elseif source:match("^%d+$") then
            userId=tonumber(source)
            if not userId or userId<1 or userId>9007199254740991 then error("Invalid user ID") end
            accountName=Players:GetNameFromUserIdAsync(userId)
        else
            userId=Players:GetUserIdFromNameAsync(source)
            accountName=source
        end
    end)
    savingProfile=false
    applyProfileBtn.Text="Apply announcement profile"
    if not ok or not userId or not accountName then
        profileStatus.Text="Account not found. Check the username or user ID."
        profileStatus.TextColor3=C.red
        return
    end
    profile.Name=name
    profile.UserId=userId
    profile.Username=accountName
    announcementNameInput.Text=name
    profilePictureInput.Text=accountName
    profilePreview.Image="rbxthumb://type=AvatarHeadShot&id="..userId.."&w=150&h=150"
    profileStatus.Text="Saved. New notices will use this name and picture."
    profileStatus.TextColor3=C.green
end)
end
Builders.Names()
Builders.Names=nil

-- Keep automatic map and safe-zone detection independent of navigation.
task.spawn(function()
    task.wait(.6)
    if detectSafe then pcall(function() detectSafe() end) end
    detectMapCenter()
end)

function Builders.Morph()
-- Compact morph controls; Reset returns both the character and this preview to the player's account.
local ownPreview="rbxthumb://type=AvatarHeadShot&id="..P.UserId.."&w=150&h=150"
local preview=Instance.new("ImageLabel"); preview.Position=UDim2.fromOffset(12,73); preview.Size=UDim2.fromOffset(78,78); preview.BackgroundColor3=C.card2; preview.BorderSizePixel=0; preview.Image=ownPreview; preview.Parent=Morph; corner(preview,10)
local morphLabel=label(Morph,"ROBLOX USERNAME",UDim2.fromOffset(102,76),UDim2.new(1,-114,0,18),10); morphLabel.TextColor3=C.muted; morphLabel.Font=Enum.Font.GothamBold
local morphInput=textbox(Morph,"Enter exact username",UDim2.fromOffset(102,101),UDim2.new(1,-114,0,43),"")
local morphBtn=button(Morph,"MORPH",UDim2.fromOffset(12,158),UDim2.new(.62,-18,0,37),true)
-- Larger, fully opaque label; shared button styling handles hover.
morphBtn.TextTransparency=0
morphBtn.TextStrokeTransparency=1
morphBtn.TextSize=13
morphBtn.TextScaled=false
local morphOutline=stroke(morphBtn,.3)
morphOutline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
local resetMorphBtn=button(Morph,"RESET",UDim2.new(.62,0,0,158),UDim2.new(.38,-12,0,37),true)
local roleLabel=label(Morph,"OVERHEAD ROLE",UDim2.fromOffset(12,203),UDim2.new(1,-24,0,16),9); roleLabel.TextColor3=C.muted; roleLabel.Font=Enum.Font.GothamBold
local morphOwnerRole=button(Morph,"👑 Owner",UDim2.fromOffset(12,224),UDim2.new(1/3,-12,0,30),true); morphOwnerRole.TextSize=9
local morphCoownerRole=button(Morph,"👑 Co-Owner",UDim2.new(1/3,6,0,224),UDim2.new(1/3,-12,0,30),true); morphCoownerRole.TextSize=9
local morphAdminRole=button(Morph,"⚙️ Admin",UDim2.new(2/3,0,0,224),UDim2.new(1/3,-12,0,30),true); morphAdminRole.TextSize=9
local morphCreatorRole=button(Morph,"🎬 Content Creator",UDim2.fromOffset(12,260),UDim2.new(.5,-18,0,30),true); morphCreatorRole.TextSize=9
local morphDeveloperRole=button(Morph,"🔨 Developer",UDim2.new(.5,6,0,260),UDim2.new(.5,-18,0,30),true); morphDeveloperRole.TextSize=9
local colorsButton=button(Morph,"COLORS",UDim2.fromOffset(12,300),UDim2.new(1,-24,0,30),true)
local morphStatus=label(Morph,"Changes your avatar appearance locally.",UDim2.fromOffset(12,337),UDim2.new(1,-24,0,18),10); morphStatus.TextWrapped=true; morphStatus.TextColor3=C.muted
addRoleSelector(morphOwnerRole,morphCoownerRole,morphAdminRole,morphCreatorRole,morphDeveloperRole,morphStatus)

local selectedColorLabel=label(MorphColorsPage,"Text color: White",UDim2.fromOffset(12,73),UDim2.new(1,-24,0,18),10); selectedColorLabel.TextColor3=C.muted
local tagColorOptions={
    {Name="White",Color=Color3.fromRGB(245,245,250)}, {Name="Gold",Color=Color3.fromRGB(255,205,75)},
    {Name="Orange",Color=Color3.fromRGB(255,145,55)}, {Name="Red",Color=Color3.fromRGB(245,70,75)},
    {Name="Pink",Color=Color3.fromRGB(246,95,160)}, {Name="Purple",Color=Color3.fromRGB(175,105,255)},
    {Name="Blue",Color=Color3.fromRGB(75,165,255)}, {Name="Green",Color=Color3.fromRGB(85,220,145)}
}
local tagColorButtons={}
local function refreshTagColorSelection()
    for _,entry in pairs(tagColorButtons) do
        local selected=entry.color==TagTextColor
        entry.stroke.Thickness=selected and 2 or 1
        entry.stroke.Transparency=selected and .05 or .65
    end
end
for i,option in ipairs(tagColorOptions) do
    local column=(i-1)%4
    local row=math.floor((i-1)/4)
    local swatch=Instance.new("TextButton")
    swatch.Position=UDim2.new(column/4,12,0,103+row*34)
    swatch.Size=UDim2.new(.25,-8,0,28)
    swatch.BackgroundColor3=option.Color
    swatch.BorderSizePixel=0
    swatch.AutoButtonColor=false
    swatch.Text=option.Name
    swatch.TextSize=9
    swatch.Font=Enum.Font.GothamBold
    local luminance=option.Color.R*.299+option.Color.G*.587+option.Color.B*.114
    swatch.TextColor3=luminance>.58 and C.bg or C.white
    swatch.Parent=MorphColorsPage
    corner(swatch,6)
    local outline=stroke(swatch,.65); outline.Color=C.white
    tagColorButtons[option.Name]={button=swatch,stroke=outline,color=option.Color}
    swatch.MouseButton1Click:Connect(function()
        TagTextColor=option.Color
        applyTag()
        selectedColorLabel.Text="Text color: "..option.Name
        refreshTagColorSelection()
    end)
end
local backToMorphButton=button(MorphColorsPage,"BACK",UDim2.fromOffset(12,185),UDim2.new(1,-24,0,30),true)
backToMorphButton.MouseButton1Click:Connect(function()
    MorphColorsPage.Visible=false
    Morph.Visible=true
end)
colorsButton.MouseButton1Click:Connect(function()
    Morph.Visible=false
    MorphColorsPage.Visible=true
end)
refreshTagColorSelection()
local previewRequest=0
local function selectOwnAvatar()
    previewRequest=previewRequest+1
    morphInput.Text=P.Name
    preview.Image=ownPreview
end
morphInput.FocusLost:Connect(function()
    local u=morphInput.Text:gsub("^%s+",""):gsub("%s+$","")
    previewRequest=previewRequest+1
    local request=previewRequest
    if u=="" then return end
    local id
    local ok=pcall(function() id=Players:GetUserIdFromNameAsync(u) end)
    if ok and request==previewRequest then
        preview.Image="rbxthumb://type=AvatarHeadShot&id="..id.."&w=150&h=150"
    end
end)
morphBtn.MouseButton1Click:Connect(function()
    local u=morphInput.Text:gsub("^%s+",""):gsub("%s+$","")
    if u=="" then morphStatus.Text="Enter a Roblox username."; morphStatus.TextColor3=C.orange; return end
    morphBtn.Text="LOADING..."
    local ok,msg=doMorph(u); morphStatus.Text=msg; morphStatus.TextColor3=ok and C.green or C.red
    morphBtn.Text="MORPH"
end)
resetMorphBtn.MouseButton1Click:Connect(function()
    resetMorph()
    selectOwnAvatar()
    morphStatus.Text="Original appearance restored."
    morphStatus.TextColor3=C.green
end)

end
Builders.Morph()
Builders.Morph=nil

function Builders.Console()
-- Green command text with muted shortcuts and placeholders.
local consoleText=C.green
local consoleMuted=Color3.fromRGB(155,155,155)
local out=Instance.new("ScrollingFrame")
out.Position=UDim2.fromOffset(12,56)
out.Size=UDim2.new(1,-24,1,-130)
out.BackgroundTransparency=1; out.BorderSizePixel=0
out.CanvasSize=UDim2.new()
out.ScrollBarThickness=3; out.ScrollBarImageColor3=Color3.fromRGB(90,90,90)
out.Parent=Console
local OL=Instance.new("UIListLayout")
OL.Padding=UDim.new(0,3); OL.SortOrder=Enum.SortOrder.LayoutOrder; OL.Parent=out
local entryCount=0
local function line(t,col)
    entryCount=entryCount+1
    local x=label(out,t,UDim2.new(),UDim2.new(1,-8,0,18),13)
    x.Font=Enum.Font.Code; x.TextColor3=col or consoleText
    x.TextWrapped=true; x.AutomaticSize=Enum.AutomaticSize.Y
    x.TextYAlignment=Enum.TextYAlignment.Top; x.LayoutOrder=entryCount
end
OL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    out.CanvasSize=UDim2.fromOffset(0,OL.AbsoluteContentSize.Y+6)
    out.CanvasPosition=Vector2.new(0,math.max(0,OL.AbsoluteContentSize.Y-out.AbsoluteSize.Y+6))
end)

local prompt=Instance.new("Frame")
prompt.Position=UDim2.new(0,12,1,-66); prompt.Size=UDim2.new(1,-24,0,28)
prompt.BackgroundTransparency=1; prompt.Parent=Console
local promptMark=label(prompt,">",UDim2.fromOffset(0,0),UDim2.fromOffset(20,28),14)
promptMark.Font=Enum.Font.Code; promptMark.TextColor3=consoleText
local ci=Instance.new("TextBox")
ci.Position=UDim2.fromOffset(22,0); ci.Size=UDim2.new(1,-22,1,0)
ci.BackgroundTransparency=1; ci.BorderSizePixel=0
ci.Text=""; ci.PlaceholderText="Enter a command..."
ci.PlaceholderColor3=consoleMuted; ci.TextColor3=consoleText
ci.Font=Enum.Font.Code; ci.TextSize=14
ci.ClearTextOnFocus=false; ci.TextXAlignment=Enum.TextXAlignment.Left
ci.Parent=prompt

local quick=Instance.new("ScrollingFrame")
quick.Position=UDim2.new(0,12,1,-30); quick.Size=UDim2.new(1,-24,0,22)
quick.BackgroundTransparency=1; quick.BorderSizePixel=0
quick.ScrollingDirection=Enum.ScrollingDirection.X; quick.CanvasSize=UDim2.new()
quick.ScrollBarThickness=2; quick.ScrollBarImageColor3=Color3.fromRGB(90,90,90)
quick.Parent=Console
local QL=Instance.new("UIListLayout")
QL.FillDirection=Enum.FillDirection.Horizontal; QL.Padding=UDim.new(0,4); QL.Parent=quick
QL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    quick.CanvasSize=UDim2.fromOffset(QL.AbsoluteContentSize.X,0)
end)
local function q(t)
    local width=math.ceil(TextService:GetTextSize(t,11,Enum.Font.Code,Vector2.new(1000,20)).X)+14
    local b=button(quick,t,UDim2.new(),UDim2.fromOffset(width,20),true)
    b.Font=Enum.Font.Code; b.TextSize=11; b.TextColor3=consoleMuted
    b:SetAttribute("RestingColor",Color3.fromRGB(12,12,12))
    b:SetAttribute("HoverColor",Color3.fromRGB(42,42,42))
    b.BackgroundTransparency=1
    b:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,2)
    return b
end
local qa=q("/announcement")
local qg=q("/globalAnnouncement")
local qt=q("/teleport")
local qi=q("/invite")
local qad=q("/giveadmin")
local qcow=q("/givecoowner")
local qv=q("/givevps")
local function findPlayer(s) s=string.lower(tostring(s)); for _,p in ipairs(Players:GetPlayers()) do if string.lower(p.Name)==s or string.lower(p.DisplayName)==s then return p end end; for _,p in ipairs(Players:GetPlayers()) do if string.sub(string.lower(p.Name),1,string.len(s))==s then return p end end end
local function command(raw)
    raw=tostring(raw or ""); if raw=="" then return end; line("> "..raw,consoleText); local cmd,rest=raw:match("^(%S+)%s*(.*)$"); cmd=string.lower(cmd or ""); rest=rest or ""
    if cmd=="/announcement" or cmd=="/globalannouncement" then if rest=="" then line("Enter a message.",C.red); return end; local global=cmd=="/globalannouncement"; callRemote(global and "GlobalAnnouncement" or "Announcement",rest); notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,global and ": sent a" or ": sent an",global and "GLOBAL ANNOUNCEMENT" or "ANNOUNCEMENT","- "..rest,Enum.Font.FredokaOne); line("Announcement shown."); return end
    if cmd=="/giveps" then cmd="/givevps" end; local acts={ ["/teleport"]={"Teleport","TELEPORT"}, ["/invite"]={"Invite","INVITE"}, ["/giveadmin"]={"GiveAdmin","ADMIN"}, ["/givecoowner"]={"GiveCoowner","CO-OWNER"}, ["/givevps"]={"GiveVPS","PRIVATE SERVER"} }; local a=acts[cmd]; if a then if rest=="" then line("Enter a player.",C.red); return end; local pl=findPlayer(rest); local target=pl and pl.DisplayName or rest; callRemote(a[1],rest); notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,": sent an",a[2],"to "..target); line(a[2].." -> "..target); return end; line("Unknown command. Choose a shortcut below.",C.red)
end
ci.FocusLost:Connect(function(enter)
    if enter then local t=ci.Text; ci.Text=""; command(t) end
end)
local function pre(t) ci.Text=t; ci:CaptureFocus() end
qa.MouseButton1Click:Connect(function() pre("/announcement ") end)
qg.MouseButton1Click:Connect(function() pre("/globalAnnouncement ") end)
qt.MouseButton1Click:Connect(function() pre("/teleport ") end)
qi.MouseButton1Click:Connect(function() pre("/invite ") end)
qad.MouseButton1Click:Connect(function() pre("/giveadmin ") end)
qcow.MouseButton1Click:Connect(function() pre("/givecoowner ") end)
qv.MouseButton1Click:Connect(function() pre("/givevps ") end)
line(P.Name.." has joined the server.")
line("Enter a command or choose a shortcut below.",consoleMuted)
end
Builders.Console()
Builders.Console=nil

-- Keep short descriptions legible; small text can make spaces look compressed.
for _,text in ipairs(Gui:GetDescendants()) do
    if text:IsA("TextLabel") and text.TextWrapped then
        text.TextSize=math.max(11,text.TextSize)
        text.LineHeight=1.1
        text.TextYAlignment=Enum.TextYAlignment.Top
        text.TextTransparency=0
    end
end

local lastTab=0
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.Tab then local now=os.clock(); if now-lastTab>.2 then lastTab=now; Console.Visible=not Console.Visible end; return end
    if input.KeyCode==Enum.KeyCode.X and HeldEgg and not UserInputService:GetFocusedTextBox() then dropHeld() end
end)
P.CharacterAdded:Connect(function() HeldEgg=nil; Carry.Visible=false; resetMorph(); task.wait(.5); applyTag() end)
applyTag()

-- ===== V7 TRUE 3D INVENTORY (inlined) =====
task.spawn(function()

-- SAE V7: sculpted solid egg models; references guide features, colors and materials.
local E=(getgenv and getgenv()) or _G
E.SAE_V7=true

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local P=Players.LocalPlayer
local PG=P and (P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10))
local BP=P and (P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10))
if not P or not PG or not BP then E.SAE_V7=nil return end

for _,n in ipairs({'SAE_ITEMS_V7','SAE_ITEMS_V6','SAE_ITEMS_V5','SAE_ITEMS_V4','SAE_ITEMS_V3'}) do local g=PG:FindFirstChild(n) if g then g:Destroy() end end
for _,holder in ipairs({BP,P.Character}) do if holder then for _,o in ipairs(holder:GetChildren()) do if o:IsA('Tool') and (o:GetAttribute('SAE_V6_TOOL') or o:GetAttribute('SAE_V5_TOOL') or o:GetAttribute('SAE_V7_TOOL')) then o:Destroy() end end end end
local oldPlaced=workspace:FindFirstChild('SAE_V7_PLACED') if oldPlaced then oldPlaced:Destroy() end
local Placed=Instance.new('Folder') Placed.Name='SAE_V7_PLACED' Placed.Parent=workspace

local Eggs={'Unicorn Egg','Kitsune Egg','Night Flame Egg','Archangel Egg','World Burner Egg','Aetheron Egg','Cthulhu Egg','Luminous Cthulhu Egg','Sabertooth Egg','Skeletal Sabertooth Egg','Octophant Egg','Mecha Scrambler Egg'}
local Pets={'Unicorn','Kitsune','Night Flame','Archangel','World Burner','Aetheron','Cthulhu','Luminous Cthulhu','Sabertooth','Skeletal Sabertooth','Octophant','Mecha Scrambler'}
local Aliases={
['Unicorn Egg']={'Unicorn Egg','UnicornEgg'},['Kitsune Egg']={'Kitsune Egg','KitsuneEgg'},['Night Flame Egg']={'Night Flame Egg','Nightflame Egg','NightFlameEgg'},['Archangel Egg']={'Archangel Egg','ArchAngel Egg','Arch Angel Egg','ArchAngelEgg'},['World Burner Egg']={'World Burner Egg','WorldBurnerEgg'},['Aetheron Egg']={'Aetheron Egg','AetheronEgg'},['Cthulhu Egg']={'Cthulhu Egg','CthulhuEgg'},['Luminous Cthulhu Egg']={'Luminous Cthulhu Egg','LuminousCthulhuEgg'},['Sabertooth Egg']={'Sabertooth Egg','SabertoothEgg'},['Skeletal Sabertooth Egg']={'Skeletal Sabertooth Egg','SkeletalSabertoothEgg','Skeletal Saber Tooth Egg'},['Octophant Egg']={'Octophant Egg','OctophantEgg'},['Mecha Scrambler Egg']={'Mecha Scrambler Egg','MechaScramblerEgg'},
['Unicorn']={'Unicorn'},['Kitsune']={'Kitsune'},['Night Flame']={'Night Flame','Nightflame','NightFlame'},['Archangel']={'Archangel','ArchAngel','Arch Angel'},['World Burner']={'World Burner','WorldBurner'},['Aetheron']={'Aetheron'},['Cthulhu']={'Cthulhu'},['Luminous Cthulhu']={'Luminous Cthulhu','LuminousCthulhu'},['Sabertooth']={'Sabertooth','Saber Tooth'},['Skeletal Sabertooth']={'Skeletal Sabertooth','SkeletalSabertooth','Skeletal Saber Tooth'},['Octophant']={'Octophant'},['Mecha Scrambler']={'Mecha Scrambler','MechaScrambler'},['Star']={'Star','Golden Star','Gold Star','Divine Star'}}

local function norm(v)return tostring(v or ''):lower():gsub('[^%w]','')end
local function rgb(r,g,b)return Color3.fromRGB(r,g,b)end
local MAT,NEON,METAL,WOOD=Enum.Material.SmoothPlastic,Enum.Material.Neon,Enum.Material.Metal,Enum.Material.WoodPlanks
local function part(m,n,s,c,cf,mat,tr)local p=Instance.new('Part')p.Name=n or'Part'p.Size=s p.Color=c p.CFrame=cf or CFrame.new()p.Material=mat or MAT p.Transparency=tr or 0 p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=m return p end
local function ball(m,n,s,c,cf,mat,tr)local p=part(m,n,s,c,cf,mat,tr)p.Shape=Enum.PartType.Ball return p end
local function cyl(m,n,s,c,cf,mat,tr)local p=part(m,n,s,c,cf,mat,tr)p.Shape=Enum.PartType.Cylinder return p end
local function wedge(m,n,s,c,cf,mat,tr)local p=Instance.new('WedgePart')p.Name=n or'Wedge'p.Size=s p.Color=c p.CFrame=cf or CFrame.new()p.Material=mat or MAT p.Transparency=tr or 0 p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true p.Parent=m return p end
local function allParts(m)local t={}for _,d in ipairs(m:GetDescendants())do if d:IsA('BasePart')then t[#t+1]=d end end return t end
local function finalize(m,root)root=root or m:FindFirstChildWhichIsA('BasePart',true)if not root then return m end m.PrimaryPart=root for _,p in ipairs(allParts(m))do p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true if p~=root then local w=Instance.new('WeldConstraint')w.Part0=root w.Part1=p w.Parent=root end end return m end
local function ring(m,cf,r,count,col)for i=1,count do local a=(i-1)*math.pi*2/count part(m,'Halo',Vector3.new(.22,.18,r*2*math.pi/count*.9),col,cf*CFrame.new(math.cos(a)*r,0,math.sin(a)*r)*CFrame.Angles(0,-a,0),NEON)end end
local function eye(m,x,y,z,c,s)return ball(m,'Eye',s or Vector3.new(.38,.48,.18),c or rgb(18,18,24),CFrame.new(x,y,z),MAT)end
local function wing(m,side,base,accent,scale,y,z)local x=scale*1.75*side wedge(m,'Wing',Vector3.new(scale*2.4,scale*3.3,.45),base,CFrame.new(x,y,z)*CFrame.Angles(0,math.rad(8*side),math.rad(-22*side)),MAT)wedge(m,'WingTip',Vector3.new(scale*1.7,scale*2.5,.38),accent,CFrame.new(x+side*scale*1.25,y+scale*.35,z+.05)*CFrame.Angles(0,math.rad(12*side),math.rad(-36*side)),MAT)wedge(m,'WingFeather',Vector3.new(scale*1.15,scale*2.1,.34),accent,CFrame.new(x+side*scale*.55,y-scale*.8,z-.03)*CFrame.Angles(0,0,math.rad(-18*side)),MAT)end
local function tentacle(m,x,y,z,c,len,a,mat)cyl(m,'Tentacle',Vector3.new(.48,len,.48),c,CFrame.new(x,y,z)*CFrame.Angles(0,0,math.rad(90+a)),mat or MAT)ball(m,'TentacleTip',Vector3.new(.52,.52,.52),c,CFrame.new(x+math.cos(math.rad(a))*len*.45,y+math.sin(math.rad(a))*len*.45,z),mat or MAT)end

-- Authored 3D egg designs. Primitive geometry and semantic features only.
local EGG_DESIGNS={
['Unicorn Egg']={palette={{236,169,193},{248,222,231},{73,224,226},{207,73,180},{237,77,108},{183,136,232},{255,235,153},{255,241,176},{239,203,111}},parts={{'ball','EggShell',{1.476383,1.986738,1.348795},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','PearlVein',{0.012759,0.409737,0.012759},2,{-0.360984,-0.759533,0.235625},{0.752326,-0.632404,0.184584,0.658792,0.722192,-0.210791,0,0.280185,0.959946},'plastic',0,0},{'box','PearlVein',{0.012759,0.468638,0.012759},2,{-0.517964,-0.392038,0.370196},{0.99229,-0.117022,0.040817,0.123936,0.936933,-0.326798,0,0.329337,0.944212},'plastic',0,0},{'box','PearlVein',{0.012759,0.516612,0.012759},2,{-0.512998,0.083628,0.455938},{0.9921,0.125381,-0.004163,-0.12545,0.991554,-0.032922,0,0.033184,0.999449},'plastic',0,0},{'box','PearlVein',{0.012759,0.408015,0.012759},2,{-0.451287,0.521085,0.375754},{0.987175,0.143741,0.069453,-0.159641,0.888854,0.42948,0,-0.43506,0.900401},'plastic',0,0},{'box','PearlVein',{0.012759,0.406362,0.012759},2,{-0.385236,-0.759533,-0.200688},{0.798777,-0.548463,-0.247274,0.601628,0.72819,0.328304,0,-0.411009,0.911631},'plastic',0,0},{'box','PearlVein',{0.012759,0.473295,0.012759},2,{-0.584466,-0.392038,-0.274392},{0.928511,-0.370985,0.015384,0.371304,0.927714,-0.038471,0,0.041433,0.999141},'plastic',0,0},{'box','PearlVein',{0.012759,0.515989,0.012759},2,{-0.667036,0.083628,-0.234025},{0.999792,0.020244,-0.002415,-0.020387,0.992753,-0.118435,0,0.118459,0.992959},'plastic',0,0},{'box','PearlVein',{0.012759,0.415024,0.012759},2,{-0.561775,0.521085,-0.216581},{0.875594,0.482082,0.030536,-0.483048,0.873842,0.05535,0,-0.063215,0.998},'plastic',0,0},{'box','PearlVein',{0.012759,0.397602,0.012759},2,{0.035369,-0.759533,-0.405254},{0.972596,0.177911,0.149682,-0.232502,0.744233,0.626147,0,-0.64379,0.765202},'plastic',0,0},{'box','PearlVein',{0.012759,0.469604,0.012759},2,{0.023952,-0.392038,-0.602122},{0.978038,-0.199254,-0.061144,0.208425,0.935006,0.286921,0,-0.293364,0.956001},'plastic',0,0},{'box','PearlVein',{0.012759,0.51645,0.012759},2,{-0.050805,0.083628,-0.653744},{0.994089,-0.108325,0.007257,0.108568,0.991866,-0.066447,0,0.066842,0.997764},'plastic',0,0},{'box','PearlVein',{0.012759,0.409704,0.012759},2,{-0.023546,0.521085,-0.558816},{0.95661,0.269616,-0.11047,-0.29137,0.885189,-0.36269,0,0.379141,0.925339},'plastic',0,0},{'box','PearlVein',{0.012759,0.412184,0.012759},2,{0.415131,-0.759533,-0.141848},{0.723104,0.685773,0.082682,-0.69074,0.717905,0.086556,0,-0.119701,0.99281},'plastic',0,0},{'box','PearlVein',{0.012759,0.469697,0.012759},2,{0.604711,-0.392038,-0.234544},{0.976692,0.205444,0.062175,-0.214646,0.93482,0.282912,0,-0.289663,0.957129},'plastic',0,0},{'box','PearlVein',{0.012759,0.516481,0.012759},2,{0.624093,0.083628,-0.318544},{0.993709,-0.111779,-0.006927,0.111994,0.991806,0.061463,0,-0.061852,0.998085},'plastic',0,0},{'box','PearlVein',{0.012759,0.409548,0.012759},2,{0.541873,0.521085,-0.255751},{0.959335,-0.260552,0.108574,0.282269,0.885528,-0.369005,0,0.384646,0.923064},'plastic',0,0},{'box','PearlVein',{0.012759,0.402192,0.012759},2,{0.315515,-0.759533,0.285359},{0.869392,0.418161,-0.263246,-0.494122,0.735741,-0.463173,0,0.532754,0.84627},'plastic',0,0},{'box','PearlVein',{0.012759,0.473269,0.012759},2,{0.487171,-0.392038,0.403877},{0.928841,0.370049,-0.017822,-0.370478,0.927766,-0.044683,0,0.048106,0.998842},'plastic',0,0},{'box','PearlVein',{0.012759,0.51598,0.012759},2,{0.578311,0.083628,0.384499},{0.999903,0.013852,0.001663,-0.013952,0.99277,0.119222,0,-0.119234,0.992866},'plastic',0,0},{'box','PearlVein',{0.012759,0.415068,0.012759},2,{0.481557,0.521085,0.342646},{0.875,-0.483431,-0.025876,0.484123,0.873749,0.046767,0,-0.053448,0.998571},'plastic',0,0},{'box','CrystalPrism',{0.264291,0.373197,0.255177},3,{-0.410106,0.779749,0.02734},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.132145,0.208494,0.132145},3,{-0.461938,1.064005,0.093413},{0.991365,0.131133,0,-0.131133,0.991365,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.208494,0.132145},3,{-0.330934,1.046676,0.093413},{0,0.131133,0.991365,0,0.991365,-0.131133,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.208494,0.132145},3,{-0.330934,1.046676,-0.038732},{-0.991365,0.131133,0,0.131133,0.991365,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.208494,0.132145},3,{-0.461938,1.064005,-0.038732},{0,0.131133,-0.991365,0,0.991365,0.131133,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.264291,0.509443,0.255177},4,{0.118475,0.868697,0.091135},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.132145,0.283475,0.132145},4,{0.066381,1.251274,0.157207},{0.995338,0.096447,0,-0.096447,0.995338,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.283475,0.132145},4,{0.19791,1.238528,0.157207},{0,0.096447,0.995338,0,0.995338,-0.096447,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.283475,0.132145},4,{0.19791,1.238528,0.025062},{-0.995338,0.096447,0,0.096447,0.995338,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.283475,0.132145},4,{0.066381,1.251274,0.025062},{0,0.096447,-0.995338,0,0.995338,0.096447,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.264291,0.402816,0.255177},5,{0.410106,0.76699,0.045567},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.132145,0.224767,0.132145},5,{0.358195,1.072491,0.11164},{0.992574,0.121639,0,-0.121639,0.992574,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.224767,0.132145},5,{0.489359,1.056417,0.11164},{0,0.121639,0.992574,0,0.992574,-0.121639,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.224767,0.132145},5,{0.489359,1.056417,-0.020505},{-0.992574,0.121639,0,0.121639,0.992574,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.224767,0.132145},5,{0.358195,1.072491,-0.020505},{0,0.121639,-0.992574,0,0.992574,0.121639,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.264291,0.302112,0.255177},6,{-0.02734,0.711945,-0.346312},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.132145,0.169542,0.132145},6,{-0.078878,0.945698,-0.280239},{0.986912,0.16126,0,-0.16126,0.986912,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.169542,0.132145},6,{0.051538,0.924388,-0.280239},{0,0.16126,0.986912,0,0.986912,-0.16126,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.169542,0.132145},6,{0.051538,0.924388,-0.412385},{-0.986912,0.16126,0,0.16126,0.986912,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.132145,0.169542,0.132145},6,{-0.078878,0.945698,-0.412385},{0,0.16126,-0.986912,0,0.986912,0.16126,1.0,0,0},'glass',0,0},{'box','IvoryHorn',{0.18227,0.335222,0.18227},7,{-0.373653,0.86578,-0.241507},{0.924678,-0.380609,0.010351,0.38075,0.924336,-0.025139,0,0.027186,0.99963},'plastic',0,0},{'box','IvoryHorn',{0.132145,0.332361,0.132145},7,{-0.505798,1.171082,-0.218723},{0.910366,-0.411306,0.045387,0.413803,0.904874,-0.099851,0,0.109682,0.993967},'plastic',0,0},{'box','IvoryHorn',{0.082021,0.325289,0.082021},7,{-0.633387,1.471827,-0.18227},{0.930408,-0.364216,0.041075,0.366525,0.924547,-0.104267,0,0.112066,0.993701},'plastic',0,0},{'corner','HornTip',{0.041011,0.50668,0.041011},8,{-0.687818,1.543653,-0.148257},{0.924678,-0.37772,0.047939,0.38075,0.91732,-0.116423,0,0.125907,0.992042},'plastic',0,0},{'corner','HornTip',{0.041011,0.50668,0.041011},8,{-0.649897,1.559268,-0.148257},{-0.047939,-0.37772,0.924678,0.116423,0.91732,0.38075,-0.992042,0.125907,0},'plastic',0,0},{'corner','HornTip',{0.041011,0.50668,0.041011},8,{-0.651863,1.564043,-0.188941},{-0.924678,-0.37772,-0.047939,-0.38075,0.91732,0.116423,0,0.125907,-0.992042},'plastic',0,0},{'corner','HornTip',{0.041011,0.50668,0.041011},8,{-0.689784,1.548428,-0.188941},{0.047939,-0.37772,-0.924678,-0.116423,0.91732,-0.38075,0.992042,0.125907,0},'plastic',0,0},{'box','HornSpiral',{0.20961,0.041011,0.18227},9,{-0.309858,0.710851,-0.246064},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.177713,0.041011,0.157663},9,{-0.40555,0.938688,-0.225559},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.145816,0.041011,0.133057},9,{-0.501241,1.166525,-0.205053},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.113918,0.041011,0.10845},9,{-0.596933,1.394362,-0.184548},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0}},bounds={1.543611,2.8,1.351767}},
['Kitsune Egg']={palette={{190,185,151},{202,197,164},{212,48,188},{34,35,40},{233,65,208},{235,62,207},{215,59,192},{244,224,224},{255,252,252}},parts={{'ball','EggShell',{2.006124,2.699599,1.832756},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.230455,-1.002872,0.579649},{-0.949027,-0.190424,0.251169,0,0.796872,0.604148,-0.315194,0.573353,-0.756254},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.583875,-1.003196,0.308641},{-0.534678,-0.529009,0.658991,0,0.779819,0.626005,-0.845056,0.334711,-0.416952},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.664104,-1.003318,-0.107218},{0.189725,-0.622651,0.759151,0,0.773194,0.634169,-0.981837,-0.120318,0.146695},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.43323,-1.003019,-0.472685},{0.793985,-0.373325,0.479808,0,0.789239,0.614086,-0.607937,-0.487575,0.626644},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0,-1.002815,-0.616774},{1.0,0,0,0,0.799734,0.600354,0,-0.600354,0.799734},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.43323,-1.003019,-0.472685},{0.793985,0.373325,-0.479808,0,0.789239,0.614086,0.607937,-0.487575,0.626644},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.664104,-1.003318,-0.107218},{0.189725,0.622651,-0.759151,0,0.773194,0.634169,0.981837,-0.120318,0.146695},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.583875,-1.003196,0.308641},{-0.534678,0.529009,-0.658991,0,0.779819,0.626005,0.845056,0.334711,-0.416952},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.230455,-1.002872,0.579649},{-0.949027,0.190424,-0.251169,0,0.796872,0.604148,0.315194,0.573353,-0.756254},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.322944,-0.461007,0.811934},{-0.949027,-0.076002,0.305893,0,0.970493,0.241129,-0.315194,0.228838,-0.921024},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.818356,-0.461204,0.432422},{-0.534678,-0.215001,0.817248,0,0.967093,0.254422,-0.845056,0.136034,-0.517083},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.930881,-0.461281,-0.150233},{0.189725,-0.254866,0.948181,0,0.965721,0.25958,-0.981837,-0.049249,0.183222},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.607146,-0.461095,-0.66217},{0.793985,-0.150212,0.589088,0,0.968994,0.247084,-0.607937,-0.196181,0.769367},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0,-0.460973,-0.863907},{1.0,0,0,0,0.971046,0.238894,0,-0.238894,0.971046},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.607146,-0.461095,-0.66217},{0.793985,0.150212,-0.589088,0,0.968994,0.247084,0.607937,-0.196181,0.769367},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.930881,-0.461281,-0.150233},{0.189725,0.254866,-0.948181,0,0.965721,0.25958,0.981837,-0.049249,0.183222},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.818356,-0.461204,0.432422},{-0.534678,0.215001,-0.817248,0,0.967093,0.254422,0.845056,0.136034,-0.517083},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.322944,-0.461007,0.811934},{-0.949027,0.076002,-0.305893,0,0.970493,0.241129,0.315194,0.228838,-0.921024},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.340197,0.187552,0.855248},{-0.949027,0.030101,0.313753,0,0.995429,-0.0955,-0.315194,-0.090632,-0.94469},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.862097,0.187634,0.455503},{-0.534678,0.085404,0.840729,0,0.99488,-0.101064,-0.845056,-0.054036,-0.53194},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.980646,0.187666,-0.158254},{0.189725,0.101361,0.976591,0,0.994657,-0.103236,-0.981837,0.019586,0.188712},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.639589,0.187588,-0.697502},{0.793985,0.059569,0.605012,0,0.995188,-0.097986,-0.607937,0.0778,0.790164},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0,0.187538,-0.90999},{1.0,0,0,0,0.995518,-0.094569,0,0.094569,0.995518},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.639589,0.187588,-0.697502},{0.793985,-0.059569,-0.605012,0,0.995188,-0.097986,0.607937,0.0778,0.790164},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.980646,0.187666,-0.158254},{0.189725,-0.101361,-0.976591,0,0.994657,-0.103236,0.981837,0.019586,0.188712},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.862097,0.187634,0.455503},{-0.534678,-0.085404,-0.840729,0,0.99488,-0.101064,0.845056,-0.054036,-0.53194},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.340197,0.187552,0.855248},{-0.949027,-0.030101,-0.313753,0,0.995429,-0.0955,0.315194,-0.090632,-0.94469},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.278317,0.792716,0.699875},{-0.949027,0.140047,0.282372,0,0.895868,-0.444321,-0.315194,-0.421673,-0.850203},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.705216,0.793023,0.372708},{-0.534678,0.392898,0.748165,0,0.885344,-0.464937,-0.845056,-0.248591,-0.473374},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.802156,0.793139,-0.129481},{0.189725,0.46421,0.865166,0,0.881171,-0.472798,-0.981837,0.089702,0.16718},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.52323,0.792854,-0.570759},{0.793985,0.275772,0.541791,0,0.891196,-0.453619,-0.607937,0.360167,0.707596},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0,0.792664,-0.744685},{1.0,0,0,0,0.897604,-0.440803,0,0.440803,0.897604},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.52323,0.792854,-0.570759},{0.793985,-0.275772,-0.541791,0,0.891196,-0.453619,0.607937,0.360167,0.707596},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.802156,0.793139,-0.129481},{0.189725,-0.46421,-0.865166,0,0.881171,-0.472798,0.981837,0.089702,0.16718},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.705216,0.793023,0.372708},{-0.534678,-0.392898,-0.748165,0,0.885344,-0.464937,0.845056,-0.248591,-0.473374},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.278317,0.792716,0.699875},{-0.949027,-0.140047,-0.282372,0,0.895868,-0.444321,0.315194,-0.421673,-0.850203},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.16195,1.192592,0.407471},{-0.949027,0.248663,0.193684,0,0.614493,-0.788923,-0.315194,-0.748709,-0.58317},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.410226,1.192839,0.216908},{-0.534678,0.680715,0.500747,0,0.592561,-0.805526,-0.845056,-0.430697,-0.316829},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.466555,1.192928,-0.075344},{0.189725,0.796802,0.573681,0,0.584294,-0.811542,-0.981837,0.15397,0.110855},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{-0.304419,1.192705,-0.332242},{0.793985,0.48426,0.367532,0,0.604556,-0.796562,-0.607937,0.632459,0.480009},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0,1.192548,-0.433587},{1.0,0,0,0,0.618271,-0.785965,0,0.785965,0.618271},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.304419,1.192705,-0.332242},{0.793985,-0.48426,-0.367532,0,0.604556,-0.796562,0.607937,0.632459,0.480009},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.466555,1.192928,-0.075344},{0.189725,-0.796802,-0.573681,0,0.584294,-0.811542,0.981837,0.15397,0.110855},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.410226,1.192839,0.216908},{-0.534678,-0.680715,-0.500747,0,0.592561,-0.805526,0.845056,-0.430697,-0.316829},'plastic',0,0},{'box','ShellEmboss',{0.24767,0.148602,0.043342},2,{0.16195,1.192592,0.407471},{-0.949027,-0.248663,-0.193684,0,0.614493,-0.788923,0.315194,-0.748709,-0.58317},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{-0.6698,0.327403,-0.658221},{0.761593,0.112019,0.6383,0,0.984947,-0.172854,-0.648055,0.131644,0.75013},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{-0.697861,0.507147,-0.575894},{0.702373,0.196147,0.68425,0,0.961284,-0.275561,-0.711809,0.193546,0.67518},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{-0.701078,0.677215,-0.484269},{0.636756,0.294277,0.712701,0,0.924307,-0.381649,-0.771066,0.243017,0.588558},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{-0.678067,0.834332,-0.388466},{0.565009,0.404813,0.718952,0,0.871367,-0.490632,-0.825085,0.277211,0.49233},'plastic',0,0},{'box','FoxEye',{0.371504,0.080493,0.074301},4,{-0.309587,-0.594407,-0.81731},{0.886409,-0.394655,-0.241922,0.406737,0.913545,0,0.221007,-0.098398,0.970296},'plastic',0,0},{'box','FoxTail',{0.371504,0.502409,0.371504},3,{-0.464381,-1.120705,0.148602},{0.27146,-0.96128,0.047445,0.96245,0.27113,-0.013382,0,0.049296,0.998784},'plastic',0,0},{'box','FoxTail',{0.304634,0.46681,0.304634},3,{-0.866844,-0.885419,0.136218},{0.72032,-0.689726,-0.073603,0.693642,0.716253,0.076434,0,-0.106112,0.994354},'plastic',0,0},{'box','FoxTail',{0.237763,0.528007,0.237763},3,{-1.108322,-0.470572,0.068109},{0.951034,-0.304892,-0.050744,0.309086,0.93813,0.156134,0,-0.164173,0.986432},'plastic',0,0},{'box','FoxTail',{0.170892,0.482479,0.170892},3,{-1.157856,0.012383,-0.018575},{0.991454,0.128332,0.023438,-0.130455,0.975321,0.178129,0,-0.179664,0.983728},'plastic',0,0},{'box','FoxTail',{0.104021,0.403367,0.104021},3,{-1.06498,0.439614,-0.061917},{0.951709,0.307003,0,-0.307003,0.951709,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.346738,0.222903,0.371504},5,{-0.705859,-1.052596,0.160985},{0.949092,0.201736,-0.241922,-0.207912,0.978148,0,0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.315779,0.222903,0.340546},5,{-1.027829,-0.718242,0.111451},{0.905849,0.347723,-0.241922,-0.358368,0.93358,0,0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.28482,0.222903,0.309587},5,{-1.188814,-0.222903,0.024767},{0.840301,0.485148,-0.241922,-0.5,0.866025,0,0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.253861,0.222903,0.278628},5,{-1.126897,0.24767,-0.061917},{0.754061,0.610627,-0.241922,-0.62932,0.777146,0,0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{-1.120094,0.565072,-0.006201},{0.984183,0.177119,-0.003486,-0.177153,0.983993,-0.019369,0,0.01968,0.999806},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{-1.022594,0.547522,-0.006201},{0.003486,0.177119,0.984183,0.019369,0.983993,-0.177153,-0.999806,0.01968,0},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{-1.022248,0.549441,-0.10525},{-0.984183,0.177119,0.003486,0.177153,0.983993,0.019369,0,0.01968,-0.999806},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{-1.119749,0.566991,-0.10525},{-0.003486,0.177119,-0.984183,-0.019369,0.983993,0.177153,0.999806,0.01968,0},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{0.6698,0.327403,-0.658221},{0.761593,-0.112019,-0.6383,0,0.984947,-0.172854,0.648055,0.131644,0.75013},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{0.697861,0.507147,-0.575894},{0.702373,-0.196147,-0.68425,0,0.961284,-0.275561,0.711809,0.193546,0.67518},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{0.701078,0.677215,-0.484269},{0.636756,-0.294277,-0.712701,0,0.924307,-0.381649,0.771066,0.243017,0.588558},'plastic',0,0},{'box','MagentaCheek',{0.321971,0.309587,0.055726},3,{0.678067,0.834332,-0.388466},{0.565009,-0.404813,-0.718952,0,0.871367,-0.490632,0.825085,0.277211,0.49233},'plastic',0,0},{'box','FoxEye',{0.371504,0.080493,0.074301},4,{0.309587,-0.594407,-0.81731},{0.886409,0.394655,0.241922,-0.406737,0.913545,0,-0.221007,-0.098398,0.970296},'plastic',0,0},{'box','FoxTail',{0.371504,0.502409,0.371504},3,{0.464381,-1.120705,0.148602},{0.27146,0.96128,-0.047445,-0.96245,0.27113,-0.013382,0,0.049296,0.998784},'plastic',0,0},{'box','FoxTail',{0.304634,0.46681,0.304634},3,{0.866844,-0.885419,0.136218},{0.72032,0.689726,0.073603,-0.693642,0.716253,0.076434,0,-0.106112,0.994354},'plastic',0,0},{'box','FoxTail',{0.237763,0.528007,0.237763},3,{1.108322,-0.470572,0.068109},{0.951034,0.304892,0.050744,-0.309086,0.93813,0.156134,0,-0.164173,0.986432},'plastic',0,0},{'box','FoxTail',{0.170892,0.482479,0.170892},3,{1.157856,0.012383,-0.018575},{0.991454,-0.128332,-0.023438,0.130455,0.975321,0.178129,0,-0.179664,0.983728},'plastic',0,0},{'box','FoxTail',{0.104021,0.403367,0.104021},3,{1.06498,0.439614,-0.061917},{0.951709,-0.307003,0,0.307003,0.951709,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.346738,0.222903,0.371504},5,{0.705859,-1.052596,0.160985},{0.949092,-0.201736,0.241922,0.207912,0.978148,0,-0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.315779,0.222903,0.340546},5,{1.027829,-0.718242,0.111451},{0.905849,-0.347723,0.241922,0.358368,0.93358,0,-0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.28482,0.222903,0.309587},5,{1.188814,-0.222903,0.024767},{0.840301,-0.485148,0.241922,0.5,0.866025,0,-0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.253861,0.222903,0.278628},5,{1.126897,0.24767,-0.061917},{0.754061,-0.610627,0.241922,0.62932,0.777146,0,-0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{1.022594,0.547522,-0.006201},{0.984183,-0.177119,0.003486,0.177153,0.983993,-0.019369,0,0.01968,0.999806},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{1.120094,0.565072,-0.006201},{-0.003486,-0.177119,0.984183,0.019369,0.983993,0.177153,-0.999806,0.01968,0},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{1.119749,0.566991,-0.10525},{-0.984183,-0.177119,-0.003486,-0.177153,0.983993,0.019369,0,0.01968,-0.999806},'plastic',0,0},{'corner','TailTip',{0.099068,0.629247,0.099068},6,{1.022248,0.549441,-0.10525},{0.003486,-0.177119,-0.984183,-0.019369,0.983993,-0.177153,0.999806,0.01968,0},'plastic',0,0},{'box','CrownPatch',{0.53249,0.123835,0.433422},3,{0,1.275499,-0.024767},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilBezel',{0.222903,0.222903,0.173369},7,{0,0.53249,-0.85446},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','ForeheadSigilGem',{0.156032,0.156032,0.185752},8,{0,0.53249,-0.965912},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilFacet',{0.066871,0.066871,0.043342},9,{-0.030959,0.563448,-1.071171},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0}},bounds={2.8,2.719877,2.014329}},
['Night Flame Egg']={palette={{91,53,20},{147,92,31},{126,78,25},{105,64,22},{197,127,30},{226,157,49},{42,91,19},{49,102,19},{56,113,19},{45,79,18},{107,183,36},{185,114,25},{250,139,13},{255,167,41}},parts={{'ball','EggShell',{1.414833,1.903911,1.292564},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0,-0.828808,0.328984},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{-0.179371,-0.828915,0.284988},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{-0.31083,-0.829137,0.164633},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{-0.359006,-0.829253,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{-0.31083,-0.829137,-0.164633},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{-0.179371,-0.828915,-0.284988},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{0,-0.828808,-0.328984},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.179371,-0.828915,-0.284988},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.31083,-0.829137,-0.164633},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{0.359006,-0.829253,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.31083,-0.829137,0.164633},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{0.179371,-0.828915,0.284988},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.151501,-0.547766,0.518242},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{-0.414195,-0.547977,0.379695},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.566235,-0.54821,0.139105},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.566235,-0.54821,-0.139105},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{-0.414195,-0.547977,-0.379695},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.151501,-0.547766,-0.518242},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{0.151501,-0.547766,-0.518242},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.414195,-0.547977,-0.379695},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.566235,-0.54821,-0.139105},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.566235,-0.54821,0.139105},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.414195,-0.547977,0.379695},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.151501,-0.547766,0.518242},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0,-0.165649,0.643472},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.351308,-0.165689,0.557551},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.609063,-0.165776,0.322269},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.703656,-0.165825,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.609063,-0.165776,-0.322269},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.351308,-0.165689,-0.557551},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0,-0.165649,-0.643472},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.351308,-0.165689,-0.557551},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.609063,-0.165776,-0.322269},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{0.703656,-0.165825,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{0.609063,-0.165776,0.322269},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.351308,-0.165689,0.557551},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.178344,0.246941,0.609864},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.487621,0.247046,0.446864},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.666679,0.247165,0.163733},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.666679,0.247165,-0.163733},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.487621,0.247046,-0.446864},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{-0.178344,0.246941,-0.609864},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.178344,0.246941,-0.609864},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.487621,0.247046,-0.446864},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.666679,0.247165,-0.163733},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{0.666679,0.247165,0.163733},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.487621,0.247046,0.446864},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.178344,0.246941,0.609864},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0,0.614047,0.502064},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{-0.273951,0.614173,0.434993},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{-0.474875,0.614444,0.251382},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.548574,0.61459,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},4,{-0.474875,0.614444,-0.251382},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{-0.273951,0.614173,-0.434993},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0,0.614047,-0.502064},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.273951,0.614173,-0.434993},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.474875,0.614444,-0.251382},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.548574,0.61459,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},2,{0.474875,0.614444,0.251382},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'wood',0,0},{'box','BarkPanel',{0.262006,0.244539,0.078602},3,{0.273951,0.614173,0.434993},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{-0.087196,0.845198,0.29852},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{-0.238313,0.845374,0.21863},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{-0.32567,0.845557,0.080062},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{-0.32567,0.845557,-0.080062},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{-0.238313,0.845374,-0.21863},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{-0.087196,0.845198,-0.29852},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},4,{0.087196,0.845198,-0.29852},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.238313,0.845374,-0.21863},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{0.32567,0.845557,-0.080062},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},3,{0.32567,0.845557,0.080062},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.238313,0.845374,0.21863},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'wood',0,0},{'box','BarkPanel',{0.200871,0.244539,0.078602},2,{0.087196,0.845198,0.29852},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'wood',0,0},{'wedge','GoldenPinion',{0.14847,0.44541,0.139737},5,{-0.720517,0.366809,0.017467},{-0.470588,-0.882353,0,0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.480841,0.139737},5,{-0.757634,0.471611,0.017467},{-0.23612,-0.971724,0,0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.541761,0.139737},5,{-0.794752,0.576414,0.017467},{-0.032241,-0.99948,0,0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.620711,0.139737},5,{-0.831869,0.681216,0.017467},{0.126632,-0.99195,0,0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.711716,0.139737},5,{-0.868987,0.786018,0.017467},{0.245422,-0.969416,0,0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.810727,0.139737},5,{-0.906105,0.890821,0.017467},{0.333947,-0.942592,0,0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.915148,0.139737},5,{-0.943222,0.995623,0.017467},{0.400819,-0.916157,0,0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.087335,0.485635,0.087335},6,{-0.71615,0.803486,0.069868},{0.611448,-0.791285,0,0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.087335,0.53124,0.087335},6,{-1.144093,1.074225,0.069868},{0.460317,-0.887755,0,0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{-0.524012,-0.724884,-0.462878},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{-0.582804,-0.515279,-0.462878},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},9,{-0.587543,-0.305674,-0.462878},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{-0.533872,-0.096069,-0.462878},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{-0.471136,0.113536,-0.462878},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},9,{-0.457014,0.323141,-0.462878},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{-0.50449,0.532746,-0.462878},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{-0.569915,0.742351,-0.462878},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.048034,0.55139,0.048034},10,{-0.524012,-0.528379,-0.40611},{0.96728,-0.253426,-0.012056,0.253713,0.966187,0.045963,0,-0.047517,0.99887},'wood',0,0},{'box','IvyVine',{0.048034,0.656992,0.048034},10,{-0.58078,0.065502,-0.397376},{0.999201,0.03988,-0.002657,-0.039968,0.996991,-0.066413,0,0.066466,0.997789},'wood',0,0},{'box','IvyVine',{0.048034,0.405428,0.048034},10,{-0.502178,0.58078,-0.336241},{0.9442,0.323123,-0.063857,-0.329372,0.926285,-0.183056,0,0.193874,0.981026},'wood',0,0},{'wedge','GoldenPinion',{0.14847,0.44541,0.139737},5,{0.720517,0.366809,0.017467},{-0.470588,0.882353,0,-0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.480841,0.139737},5,{0.757634,0.471611,0.017467},{-0.23612,0.971724,0,-0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.541761,0.139737},5,{0.794752,0.576414,0.017467},{-0.032241,0.99948,0,-0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.620711,0.139737},5,{0.831869,0.681216,0.017467},{0.126632,0.99195,0,-0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.711716,0.139737},5,{0.868987,0.786018,0.017467},{0.245422,0.969416,0,-0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.810727,0.139737},5,{0.906105,0.890821,0.017467},{0.333947,0.942592,0,-0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.14847,0.915148,0.139737},5,{0.943222,0.995623,0.017467},{0.400819,0.916157,0,-0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.087335,0.485635,0.087335},6,{0.71615,0.803486,0.069868},{0.611448,0.791285,0,-0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.087335,0.53124,0.087335},6,{1.144093,1.074225,0.069868},{0.460317,0.887755,0,-0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{0.524012,-0.724884,-0.462878},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{0.582804,-0.515279,-0.462878},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},9,{0.587543,-0.305674,-0.462878},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{0.533872,-0.096069,-0.462878},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{0.471136,0.113536,-0.462878},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},9,{0.457014,0.323141,-0.462878},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},7,{0.50449,0.532746,-0.462878},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.200871,0.262006,0.104802},8,{0.569915,0.742351,-0.462878},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.048034,0.55139,0.048034},10,{0.524012,-0.528379,-0.40611},{0.96728,0.253426,0.012056,-0.253713,0.966187,0.045963,0,-0.047517,0.99887},'wood',0,0},{'box','IvyVine',{0.048034,0.656992,0.048034},10,{0.58078,0.065502,-0.397376},{0.999201,-0.03988,0.002657,0.039968,0.996991,-0.066413,0,0.066466,0.997789},'wood',0,0},{'box','IvyVine',{0.048034,0.405428,0.048034},10,{0.502178,0.58078,-0.336241},{0.9442,-0.323123,0.063857,0.329372,0.926285,-0.183056,0,0.193874,0.981026},'wood',0,0},{'box','CrownBattlement',{0.157204,0.227072,0.218338},3,{-0.41921,0.890821,-0.087335},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.157204,0.227072,0.218338},3,{-0.139737,0.890821,-0.087335},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.157204,0.227072,0.218338},3,{0.139737,0.890821,-0.087335},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.157204,0.227072,0.218338},3,{0.41921,0.890821,-0.087335},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'corner','CrownEmerald',{0.104802,0.314407,0.104802},11,{-0.052401,1.100426,0.052401},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'corner','CrownEmerald',{0.104802,0.314407,0.104802},11,{0.052401,1.100426,0.052401},{0,0,1.0,0,1.0,0,-1.0,0,0},'plastic',0,0},{'corner','CrownEmerald',{0.104802,0.314407,0.104802},11,{0.052401,1.100426,-0.052401},{-1.0,0,0,0,1.0,0,0,0,-1.0},'plastic',0,0},{'corner','CrownEmerald',{0.104802,0.314407,0.104802},11,{-0.052401,1.100426,-0.052401},{0,0,-1.0,0,1.0,0,1.0,0,0},'plastic',0,0},{'box','EmberHeartBezel',{0.532746,0.532746,0.12227},12,{0,-0.043668,-0.71615},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','EmberHeartGem',{0.372922,0.372922,0.131003},13,{0,-0.043668,-0.794752},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','EmberHeartFacet',{0.159824,0.159824,0.030567},14,{-0.021834,-0.021834,-0.868987},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={2.8,2.209585,1.58409}},
['Archangel Egg']={palette={{213,153,39},{229,174,50},{191,130,25},{247,199,70},{243,242,230},{255,241,117},{255,234,104},{252,221,71}},parts={{'ball','EggShell',{1.199693,1.614401,1.096015},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{0,-0.702779,0.278959},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{-0.152096,-0.702869,0.241652},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{-0.263565,-0.703058,0.139599},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{-0.304415,-0.703156,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{-0.263565,-0.703058,-0.139599},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{-0.152096,-0.702869,-0.241652},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{0,-0.702779,-0.278959},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{0.152096,-0.702869,-0.241652},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{0.263565,-0.703058,-0.139599},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{0.304415,-0.703156,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{0.263565,-0.703058,0.139599},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{0.152096,-0.702869,0.241652},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.128463,-0.464472,0.439438},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{-0.351213,-0.464652,0.321959},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.480132,-0.464849,0.117953},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.480132,-0.464849,-0.117953},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.351213,-0.464652,-0.321959},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.128463,-0.464472,-0.439438},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.128463,-0.464472,-0.439438},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.351213,-0.464652,-0.321959},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.480132,-0.464849,-0.117953},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.480132,-0.464849,0.117953},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.351213,-0.464652,0.321959},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.128463,-0.464472,0.439438},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0,-0.14046,0.545625},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.297888,-0.140494,0.47277},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.516448,-0.140568,0.273265},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.596658,-0.140609,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.516448,-0.140568,-0.273265},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.297888,-0.140494,-0.47277},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0,-0.14046,-0.545625},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.297888,-0.140494,-0.47277},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.516448,-0.140568,-0.273265},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.596658,-0.140609,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.516448,-0.140568,0.273265},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.297888,-0.140494,0.47277},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.151225,0.209391,0.517128},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.413473,0.20948,0.378913},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{-0.565303,0.209581,0.138835},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.565303,0.209581,-0.138835},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.413473,0.20948,-0.378913},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.151225,0.209391,-0.517128},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{0.151225,0.209391,-0.517128},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.413473,0.20948,-0.378913},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.565303,0.209581,-0.138835},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.565303,0.209581,0.138835},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.413473,0.20948,0.378913},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.151225,0.209391,0.517128},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0,0.520675,0.42572},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{-0.232294,0.520781,0.368847},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.402665,0.521011,0.213157},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.465157,0.521135,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},3,{-0.402665,0.521011,-0.213157},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{-0.232294,0.520781,-0.368847},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0,0.520675,-0.42572},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.232294,0.520781,-0.368847},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.402665,0.521011,-0.213157},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},2,{0.465157,0.521135,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.402665,0.521011,0.213157},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'metal',0,0},{'box','GildedPlate',{0.222165,0.207354,0.06665},1,{0.232294,0.520781,0.368847},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{-0.073937,0.716676,0.253127},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{-0.202075,0.716826,0.185385},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{-0.276148,0.716981,0.067887},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{-0.276148,0.716981,-0.067887},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{-0.202075,0.716826,-0.185385},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{-0.073937,0.716676,-0.253127},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{0.073937,0.716676,-0.253127},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},3,{0.202075,0.716826,-0.185385},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{0.276148,0.716981,-0.067887},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{0.276148,0.716981,0.067887},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},2,{0.202075,0.716826,0.185385},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'metal',0,0},{'box','GildedPlate',{0.170327,0.207354,0.06665},1,{0.073937,0.716676,0.253127},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'metal',0,0},{'box','WingSpar',{0.103677,0.509098,0.103677},4,{-0.592441,0.596143,0.048136},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.103677,0.517433,0.103677},4,{-1.018258,0.825714,0.059244},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.140705,0.607252,0.103677},5,{-0.540602,0.359019,0.014811},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.437221,0.020735},4,{-0.545123,0.378916,-0.053129},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.140705,0.581861,0.103677},5,{-0.642163,0.410477,0.020101},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.41894,0.020735},4,{-0.64544,0.429996,-0.047664},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.140705,0.556471,0.103677},5,{-0.743725,0.461935,0.02539},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.400659,0.020735},4,{-0.745801,0.481014,-0.042206},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.140705,0.531081,0.103677},5,{-0.845286,0.513392,0.03068},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.382378,0.020735},4,{-0.846209,0.531972,-0.036754},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.140705,0.50569,0.103677},5,{-0.946847,0.56485,0.03597},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.364097,0.020735},4,{-0.946665,0.582873,-0.031309},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.140705,0.4803,0.103677},5,{-1.048409,0.616308,0.041259},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.345816,0.020735},4,{-1.047173,0.63372,-0.025872},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.140705,0.45491,0.103677},5,{-1.14997,0.667765,0.046549},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.327535,0.020735},4,{-1.147735,0.684515,-0.020442},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.140705,0.42952,0.103677},5,{-1.251531,0.719223,0.051839},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.309254,0.020735},4,{-1.248352,0.735263,-0.015019},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.496169,0.533197,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.629468,0.599846,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.762767,0.666496,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.896067,0.733145,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.103677,0.509098,0.103677},4,{0.592441,0.596143,0.048136},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.103677,0.517433,0.103677},4,{1.018258,0.825714,0.059244},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.140705,0.607252,0.103677},5,{0.540602,0.359019,0.014811},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.437221,0.020735},4,{0.545123,0.378916,-0.053129},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.140705,0.581861,0.103677},5,{0.642163,0.410477,0.020101},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.41894,0.020735},4,{0.64544,0.429996,-0.047664},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.140705,0.556471,0.103677},5,{0.743725,0.461935,0.02539},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.400659,0.020735},4,{0.745801,0.481014,-0.042206},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.140705,0.531081,0.103677},5,{0.845286,0.513392,0.03068},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.382378,0.020735},4,{0.846209,0.531972,-0.036754},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.140705,0.50569,0.103677},5,{0.946847,0.56485,0.03597},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.364097,0.020735},4,{0.946665,0.582873,-0.031309},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.140705,0.4803,0.103677},5,{1.048409,0.616308,0.041259},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.345816,0.020735},4,{1.047173,0.63372,-0.025872},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.140705,0.45491,0.103677},5,{1.14997,0.667765,0.046549},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.327535,0.020735},4,{1.147735,0.684515,-0.020442},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.140705,0.42952,0.103677},5,{1.251531,0.719223,0.051839},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.309254,0.020735},4,{1.248352,0.735263,-0.015019},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{0.496169,0.533197,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{0.629468,0.599846,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{0.762767,0.666496,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{0.896067,0.733145,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','HolyRuneStem',{0.055541,1.051582,0.055541},6,{0,0.037028,-0.570224},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','HolyRuneCross',{0.051839,0.503575,0.051839},6,{0,0.074055,-0.599846},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0},{'corner','RuneUpperPoint',{0.048136,0.187346,0.048136},7,{-0.024068,0.599641,-0.517769},{1.0,0,0,0,0.948683,-0.316228,0,0.316228,0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.048136,0.187346,0.048136},7,{0.024068,0.599641,-0.517769},{0,0,1.0,0.316228,0.948683,0,-0.948683,0.316228,0},'neon',0,0},{'corner','RuneUpperPoint',{0.048136,0.187346,0.048136},7,{0.024068,0.614863,-0.563435},{-1.0,0,0,0,0.948683,0.316228,0,0.316228,-0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.048136,0.187346,0.048136},7,{-0.024068,0.614863,-0.563435},{0,0,-1.0,-0.316228,0.948683,0,0.948683,0.316228,0},'neon',0,0},{'corner','RuneLowerPoint',{0.048136,0.212191,0.048136},7,{0.024068,-0.539951,-0.504792},{-1.0,0,0,0,-0.872506,0.488603,0,0.488603,0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.048136,0.212191,0.048136},7,{-0.024068,-0.539951,-0.504792},{0,0,-1.0,-0.488603,-0.872506,0,-0.872506,0.488603,0},'neon',0,0},{'corner','RuneLowerPoint',{0.048136,0.212191,0.048136},7,{-0.024068,-0.56347,-0.546791},{1.0,0,0,0,-0.872506,-0.488603,0,0.488603,-0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.048136,0.212191,0.048136},7,{0.024068,-0.56347,-0.546791},{0,0,1.0,0.488603,-0.872506,0,0.872506,0.488603,0},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.363967,1.036771,0.047917},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.339163,1.036771,0.140486},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.291246,1.036771,0.223481},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.223481,1.036771,0.291246},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.140486,1.036771,0.339163},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.047917,1.036771,0.363967},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.047917,1.036771,0.363967},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.140486,1.036771,0.339163},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.223481,1.036771,0.291246},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.291246,1.036771,0.223481},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.339163,1.036771,0.140486},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.363967,1.036771,0.047917},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.363967,1.036771,-0.047917},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.339163,1.036771,-0.140486},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.291246,1.036771,-0.223481},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.223481,1.036771,-0.291246},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.140486,1.036771,-0.339163},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{-0.047917,1.036771,-0.363967},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.047917,1.036771,-0.363967},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.140486,1.036771,-0.339163},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.223481,1.036771,-0.291246},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.291246,1.036771,-0.223481},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.339163,1.036771,-0.140486},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.035546,0.096661,0.035546},8,{0.363967,1.036771,-0.047917},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'ball','HaloDroplet',{0.033325,0.103677,0.033325},4,{-0.355464,0.955311,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.033325,0.103677,0.033325},4,{0.355464,0.955311,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.033325,0.103677,0.033325},4,{0,0.955311,0.355464},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.033325,0.103677,0.033325},4,{0,0.955311,-0.355464},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.06665,0.266598,0.06665},4,{-0.033325,1.155259,0.033325},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.06665,0.266598,0.06665},4,{0.033325,1.155259,0.033325},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'corner','HaloStar',{0.06665,0.266598,0.06665},4,{0.033325,1.155259,-0.033325},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'corner','HaloStar',{0.06665,0.266598,0.06665},4,{-0.033325,1.155259,-0.033325},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0}},bounds={2.8,2.095759,1.21917}},
['World Burner Egg']={palette={{53,16,25},{84,24,36},{49,14,23},{69,20,30},{33,17,23},{226,81,105},{38,17,24},{65,20,30},{32,15,21},{74,64,66}},parts={{'ball','EggShell',{1.358787,1.828491,1.241361},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{0,-0.795976,0.315952},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},3,{-0.172265,-0.796078,0.273698},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{-0.298517,-0.796292,0.158111},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{-0.344784,-0.796404,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{-0.298517,-0.796292,-0.158111},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{-0.172265,-0.796078,-0.273698},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0,-0.795976,-0.315952},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0.172265,-0.796078,-0.273698},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{0.298517,-0.796292,-0.158111},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{0.344784,-0.796404,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0.298517,-0.796292,0.158111},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{0.172265,-0.796078,0.273698},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.145499,-0.526067,0.497713},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.397788,-0.52627,0.364654},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.543804,-0.526493,0.133595},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.543804,-0.526493,-0.133595},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.397788,-0.52627,-0.364654},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.145499,-0.526067,-0.497713},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.145499,-0.526067,-0.497713},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.397788,-0.52627,-0.364654},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.543804,-0.526493,-0.133595},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.543804,-0.526493,0.133595},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.397788,-0.52627,0.364654},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.145499,-0.526067,0.497713},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0,-0.159087,0.617982},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.337391,-0.159125,0.535465},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.584936,-0.159209,0.309503},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.675782,-0.159256,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.584936,-0.159209,-0.309503},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.337391,-0.159125,-0.535465},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0,-0.159087,-0.617982},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.337391,-0.159125,-0.535465},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.584936,-0.159209,-0.309503},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.675782,-0.159256,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.584936,-0.159209,0.309503},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.337391,-0.159125,0.535465},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.171279,0.237159,0.585705},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.468305,0.23726,0.429162},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.640269,0.237374,0.157247},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.640269,0.237374,-0.157247},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.468305,0.23726,-0.429162},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.171279,0.237159,-0.585705},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.171279,0.237159,-0.585705},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.468305,0.23726,-0.429162},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.640269,0.237374,-0.157247},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.640269,0.237374,0.157247},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.468305,0.23726,0.429162},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.171279,0.237159,0.585705},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0,0.589722,0.482176},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.263099,0.589843,0.417761},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{-0.456063,0.590103,0.241424},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.526843,0.590244,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{-0.456063,0.590103,-0.241424},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{-0.263099,0.589843,-0.417761},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0,0.589722,-0.482176},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},4,{0.263099,0.589843,-0.417761},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.456063,0.590103,-0.241424},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.526843,0.590244,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},3,{0.456063,0.590103,0.241424},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'slate',0,0},{'box','ObsidianPlate',{0.251627,0.234852,0.075488},2,{0.263099,0.589843,0.417761},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{-0.083742,0.811717,0.286695},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},3,{-0.228873,0.811886,0.209969},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{-0.312769,0.812062,0.07689},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{-0.312769,0.812062,-0.07689},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{-0.228873,0.811886,-0.209969},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},3,{-0.083742,0.811717,-0.286695},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0.083742,0.811717,-0.286695},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},2,{0.228873,0.811886,-0.209969},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0.312769,0.812062,-0.07689},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},3,{0.312769,0.812062,0.07689},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},3,{0.228873,0.811886,0.209969},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'slate',0,0},{'box','ObsidianPlate',{0.192914,0.234852,0.075488},4,{0.083742,0.811717,0.286695},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'slate',0,0},{'box','DemonHorn',{0.134201,0.295119,0.134201},5,{-0.264209,0.83037,0.020969},{0.966705,-0.255789,-0.007273,0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.090586,0.228936,0.090586},5,{-0.285177,1.086191,0.016775},{0.989203,0.146549,0,-0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.04697,0.083033,0.04697},5,{-0.239046,1.228779,0.016775},{0.707107,0.707107,0,-0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.029357,0.212522,0.029357},6,{-0.251627,0.943602,-0.046132},{0.987441,-0.157867,0.006235,0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.029357,0.156917,0.029357},6,{-0.247433,1.123935,-0.037744},{0.963518,0.267261,-0.014306,-0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.117426,0.538571,0.117426},7,{-0.658424,0.549386,0.104845},{0.794358,-0.607376,0.00946,0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.117426,0.581955,0.117426},7,{-1.102966,0.838757,0.104845},{0.259457,-0.965654,-0.013919,0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.117426,0.771657,0.872307},8,{-0.922633,0.478092,0.125814},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{-0.746494,0.440348,0.046132},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{-0.972958,0.532611,0.046132},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{-1.199423,0.624874,0.046132},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.037744,0.207836,0.037744},6,{-0.847145,0.557774,0.020969},{0.686624,-0.726421,-0.02934,0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.037744,0.159364,0.037744},6,{-0.89747,0.704556,0.020969},{0.948683,0.315789,-0.016644,-0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','DemonHorn',{0.134201,0.295119,0.134201},5,{0.264209,0.83037,0.020969},{0.966705,0.255789,0.007273,-0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.090586,0.228936,0.090586},5,{0.285177,1.086191,0.016775},{0.989203,-0.146549,0,0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.04697,0.083033,0.04697},5,{0.239046,1.228779,0.016775},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.029357,0.212522,0.029357},6,{0.251627,0.943602,-0.046132},{0.987441,0.157867,-0.006235,-0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.029357,0.156917,0.029357},6,{0.247433,1.123935,-0.037744},{0.963518,-0.267261,0.014306,0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.117426,0.538571,0.117426},7,{0.658424,0.549386,0.104845},{0.794358,0.607376,-0.00946,-0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.117426,0.581955,0.117426},7,{1.102966,0.838757,0.104845},{0.259457,0.965654,0.013919,-0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.117426,0.771657,0.872307},8,{0.922633,0.478092,0.125814},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{0.746494,0.440348,0.046132},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{0.972958,0.532611,0.046132},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.037744,0.618011,0.037744},9,{1.199423,0.624874,0.046132},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.037744,0.207836,0.037744},6,{0.847145,0.557774,0.020969},{0.686624,0.726421,0.02934,-0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.037744,0.159364,0.037744},6,{0.89747,0.704556,0.020969},{0.948683,-0.315789,0.016644,0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.511642,-0.142589,-0.578742},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.480786,-0.030709,-0.578742},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.39194,0.067677,-0.578742},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.255821,0.140701,-0.578742},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.088846,0.179557,-0.578742},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.088846,0.179557,-0.578742},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.255821,0.140701,-0.578742},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.39194,0.067677,-0.578742},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.480786,-0.030709,-0.578742},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.511642,-0.142589,-0.578742},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.480786,-0.254469,-0.578742},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.39194,-0.352854,-0.578742},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.255821,-0.425879,-0.578742},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.088846,-0.464734,-0.578742},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.088846,-0.464734,-0.578742},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.255821,-0.425879,-0.578742},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.39194,-0.352854,-0.578742},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.480786,-0.254469,-0.578742},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.511642,-0.142589,0.578742},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.480786,-0.030709,0.578742},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.39194,0.067677,0.578742},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.255821,0.140701,0.578742},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.088846,0.179557,0.578742},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.088846,0.179557,0.578742},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.255821,0.140701,0.578742},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.39194,0.067677,0.578742},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.480786,-0.030709,0.578742},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.511642,-0.142589,0.578742},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.480786,-0.254469,0.578742},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.39194,-0.352854,0.578742},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.255821,-0.425879,0.578742},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{-0.088846,-0.464734,0.578742},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.088846,-0.464734,0.578742},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.255821,-0.425879,0.578742},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.39194,-0.352854,0.578742},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.184527,0.083876,0.109038},10,{0.480786,-0.254469,0.578742},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','BurnerSigil',{0.054519,0.629068,0.054519},6,{0,-0.130007,-0.671006},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerSigil',{0.054519,0.335503,0.054519},6,{0,-0.117426,-0.679393},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0}},bounds={2.8,2.188988,1.37875}},
['Aetheron Egg']={palette={{174,133,51},{224,184,74},{104,22,27},{219,170,42},{226,223,187},{174,28,38},{112,16,25},{225,170,32},{140,20,29},{255,216,46},{232,224,188},{255,232,113},{248,220,96},{99,30,25}},parts={{'ball','EggShell',{1.199693,1.614401,1.096015},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.101295,-0.622002,0.346831},{-0.971386,-0.149502,0.18455,0,0.777029,0.629464,-0.237507,0.611453,-0.754795},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.147502,-0.277103,0.504656},{-0.971386,-0.057041,0.230556,0,0.970732,0.240166,-0.237507,0.233294,-0.942955},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.154498,0.140646,0.528533},{-0.971386,0.028265,0.23582,0,0.992894,-0.119006,-0.237507,-0.115601,-0.964483},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.120517,0.521436,0.412512},{-0.971386,0.117673,0.206308,0,0.868637,-0.495449,-0.237507,-0.481272,-0.843782},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.066792,0.737074,0.228822},{-0.971386,0.195853,0.134355,0,0.56569,-0.824618,-0.237507,-0.801022,-0.549503},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.276914,-0.622215,0.254085},{-0.738685,-0.434001,0.51574,0,0.765135,0.64387,-0.67405,0.475617,-0.565194},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.403324,-0.277233,0.369806},{-0.738685,-0.167781,0.652835,0,0.968525,0.248915,-0.67405,0.18387,-0.715436},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.422461,0.140713,0.387313},{-0.738685,0.083281,0.668886,0,0.992338,-0.123553,-0.67405,-0.091267,-0.733026},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.329499,0.521648,0.302243},{-0.738685,0.343592,0.579904,0,0.860327,-0.509742,-0.67405,-0.376539,-0.635511},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.182544,0.73722,0.167581},{-0.738685,0.562469,0.371447,0,0.551068,-0.834461,-0.67405,-0.616404,-0.407066},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.378522,-0.622444,0.093075},{-0.281747,-0.632603,0.72141,0,0.751869,0.659312,-0.959489,0.185759,-0.211837},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.55147,-0.277378,0.135511},{-0.281747,-0.248214,0.926827,0,0.965959,0.258694,-0.959489,0.072886,-0.272156},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.577653,0.140789,0.141931},{-0.281747,0.123451,0.951514,0,0.991688,-0.128664,-0.959489,-0.036251,-0.279405},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.450464,0.521879,0.110734},{-0.281747,0.504066,0.816416,0,0.850887,-0.525349,-0.959489,-0.148015,-0.239735},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.249452,0.737371,0.061366},{-0.281747,0.810446,0.513611,0,0.535296,-0.844664,-0.959489,-0.237982,-0.150818},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.378522,-0.622444,-0.093075},{0.281747,-0.632603,0.72141,0,0.751869,0.659312,-0.959489,-0.185759,0.211837},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.55147,-0.277378,-0.135511},{0.281747,-0.248214,0.926827,0,0.965959,0.258694,-0.959489,-0.072886,0.272156},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.577653,0.140789,-0.141931},{0.281747,0.123451,0.951514,0,0.991688,-0.128664,-0.959489,0.036251,0.279405},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.450464,0.521879,-0.110734},{0.281747,0.504066,0.816416,0,0.850887,-0.525349,-0.959489,0.148015,0.239735},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.249452,0.737371,-0.061366},{0.281747,0.810446,0.513611,0,0.535296,-0.844664,-0.959489,0.237982,0.150818},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.276914,-0.622215,-0.254085},{0.738685,-0.434001,0.51574,0,0.765135,0.64387,-0.67405,-0.475617,0.565194},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.403324,-0.277233,-0.369806},{0.738685,-0.167781,0.652835,0,0.968525,0.248915,-0.67405,-0.18387,0.715436},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.422461,0.140713,-0.387313},{0.738685,0.083281,0.668886,0,0.992338,-0.123553,-0.67405,0.091267,0.733026},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.329499,0.521648,-0.302243},{0.738685,0.343592,0.579904,0,0.860327,-0.509742,-0.67405,0.376539,0.635511},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.182544,0.73722,-0.167581},{0.738685,0.562469,0.371447,0,0.551068,-0.834461,-0.67405,0.616404,0.407066},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.101295,-0.622002,-0.346831},{0.971386,-0.149502,0.18455,0,0.777029,0.629464,-0.237507,-0.611453,0.754795},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.147502,-0.277103,-0.504656},{0.971386,-0.057041,0.230556,0,0.970732,0.240166,-0.237507,-0.233294,0.942955},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.154498,0.140646,-0.528533},{0.971386,0.028265,0.23582,0,0.992894,-0.119006,-0.237507,0.115601,0.964483},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.120517,0.521436,-0.412512},{0.971386,0.117673,0.206308,0,0.868637,-0.495449,-0.237507,0.481272,0.843782},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},2,{-0.066792,0.737074,-0.228822},{0.971386,0.195853,0.134355,0,0.56569,-0.824618,-0.237507,0.801022,0.549503},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.101295,-0.622002,-0.346831},{0.971386,0.149502,-0.18455,0,0.777029,0.629464,0.237507,-0.611453,0.754795},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.147502,-0.277103,-0.504656},{0.971386,0.057041,-0.230556,0,0.970732,0.240166,0.237507,-0.233294,0.942955},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.154498,0.140646,-0.528533},{0.971386,-0.028265,-0.23582,0,0.992894,-0.119006,0.237507,0.115601,0.964483},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.120517,0.521436,-0.412512},{0.971386,-0.117673,-0.206308,0,0.868637,-0.495449,0.237507,0.481272,0.843782},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.066792,0.737074,-0.228822},{0.971386,-0.195853,-0.134355,0,0.56569,-0.824618,0.237507,0.801022,0.549503},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.276914,-0.622215,-0.254085},{0.738685,0.434001,-0.51574,0,0.765135,0.64387,0.67405,-0.475617,0.565194},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.403324,-0.277233,-0.369806},{0.738685,0.167781,-0.652835,0,0.968525,0.248915,0.67405,-0.18387,0.715436},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.422461,0.140713,-0.387313},{0.738685,-0.083281,-0.668886,0,0.992338,-0.123553,0.67405,0.091267,0.733026},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.329499,0.521648,-0.302243},{0.738685,-0.343592,-0.579904,0,0.860327,-0.509742,0.67405,0.376539,0.635511},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.182544,0.73722,-0.167581},{0.738685,-0.562469,-0.371447,0,0.551068,-0.834461,0.67405,0.616404,0.407066},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.378522,-0.622444,-0.093075},{0.281747,0.632603,-0.72141,0,0.751869,0.659312,0.959489,-0.185759,0.211837},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.55147,-0.277378,-0.135511},{0.281747,0.248214,-0.926827,0,0.965959,0.258694,0.959489,-0.072886,0.272156},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.577653,0.140789,-0.141931},{0.281747,-0.123451,-0.951514,0,0.991688,-0.128664,0.959489,0.036251,0.279405},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.450464,0.521879,-0.110734},{0.281747,-0.504066,-0.816416,0,0.850887,-0.525349,0.959489,0.148015,0.239735},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.249452,0.737371,-0.061366},{0.281747,-0.810446,-0.513611,0,0.535296,-0.844664,0.959489,0.237982,0.150818},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.378522,-0.622444,0.093075},{-0.281747,0.632603,-0.72141,0,0.751869,0.659312,0.959489,0.185759,-0.211837},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.55147,-0.277378,0.135511},{-0.281747,0.248214,-0.926827,0,0.965959,0.258694,0.959489,0.072886,-0.272156},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.577653,0.140789,0.141931},{-0.281747,-0.123451,-0.951514,0,0.991688,-0.128664,0.959489,-0.036251,-0.279405},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.450464,0.521879,0.110734},{-0.281747,-0.504066,-0.816416,0,0.850887,-0.525349,0.959489,-0.148015,-0.239735},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.249452,0.737371,0.061366},{-0.281747,-0.810446,-0.513611,0,0.535296,-0.844664,0.959489,-0.237982,-0.150818},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.276914,-0.622215,0.254085},{-0.738685,0.434001,-0.51574,0,0.765135,0.64387,0.67405,0.475617,-0.565194},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.403324,-0.277233,0.369806},{-0.738685,0.167781,-0.652835,0,0.968525,0.248915,0.67405,0.18387,-0.715436},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.422461,0.140713,0.387313},{-0.738685,-0.083281,-0.668886,0,0.992338,-0.123553,0.67405,-0.091267,-0.733026},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.329499,0.521648,0.302243},{-0.738685,-0.343592,-0.579904,0,0.860327,-0.509742,0.67405,-0.376539,-0.635511},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.182544,0.73722,0.167581},{-0.738685,-0.562469,-0.371447,0,0.551068,-0.834461,0.67405,-0.616404,-0.407066},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.101295,-0.622002,0.346831},{-0.971386,0.149502,-0.18455,0,0.777029,0.629464,0.237507,0.611453,-0.754795},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.147502,-0.277103,0.504656},{-0.971386,0.057041,-0.230556,0,0.970732,0.240166,0.237507,0.233294,-0.942955},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.154498,0.140646,0.528533},{-0.971386,-0.028265,-0.23582,0,0.992894,-0.119006,0.237507,-0.115601,-0.964483},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.120517,0.521436,0.412512},{-0.971386,-0.117673,-0.206308,0,0.868637,-0.495449,0.237507,-0.481272,-0.843782},'metal',0,0},{'box','DualArmor',{0.207354,0.21476,0.06665},3,{0.066792,0.737074,0.228822},{-0.971386,-0.195853,-0.134355,0,0.56569,-0.824618,0.237507,-0.801022,-0.549503},'metal',0,0},{'box','WingSpar',{0.103677,0.509098,0.103677},4,{-0.592441,0.596143,0.048136},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.103677,0.517433,0.103677},4,{-1.018258,0.825714,0.059244},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.140705,0.607252,0.103677},5,{-0.540602,0.359019,0.014811},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.437221,0.020735},4,{-0.545123,0.378916,-0.053129},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.140705,0.581861,0.103677},5,{-0.642163,0.410477,0.020101},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.41894,0.020735},4,{-0.64544,0.429996,-0.047664},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.140705,0.556471,0.103677},5,{-0.743725,0.461935,0.02539},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.400659,0.020735},4,{-0.745801,0.481014,-0.042206},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.140705,0.531081,0.103677},5,{-0.845286,0.513392,0.03068},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.382378,0.020735},4,{-0.846209,0.531972,-0.036754},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.140705,0.50569,0.103677},5,{-0.946847,0.56485,0.03597},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.364097,0.020735},4,{-0.946665,0.582873,-0.031309},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.140705,0.4803,0.103677},5,{-1.048409,0.616308,0.041259},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.345816,0.020735},4,{-1.047173,0.63372,-0.025872},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.140705,0.45491,0.103677},5,{-1.14997,0.667765,0.046549},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.327535,0.020735},4,{-1.147735,0.684515,-0.020442},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.140705,0.42952,0.103677},5,{-1.251531,0.719223,0.051839},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.309254,0.020735},4,{-1.248352,0.735263,-0.015019},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.496169,0.533197,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.629468,0.599846,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.762767,0.666496,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},4,{-0.896067,0.733145,-0.059244},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.103677,0.509098,0.103677},6,{0.592441,0.596143,0.048136},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.103677,0.517433,0.103677},6,{1.018258,0.825714,0.059244},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.140705,0.607252,0.103677},7,{0.540602,0.359019,0.014811},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.437221,0.020735},6,{0.545123,0.378916,-0.053129},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.140705,0.581861,0.103677},7,{0.642163,0.410477,0.020101},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.41894,0.020735},6,{0.64544,0.429996,-0.047664},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.140705,0.556471,0.103677},7,{0.743725,0.461935,0.02539},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.400659,0.020735},6,{0.745801,0.481014,-0.042206},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.140705,0.531081,0.103677},7,{0.845286,0.513392,0.03068},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.382378,0.020735},6,{0.846209,0.531972,-0.036754},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.140705,0.50569,0.103677},7,{0.946847,0.56485,0.03597},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.364097,0.020735},6,{0.946665,0.582873,-0.031309},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.140705,0.4803,0.103677},7,{1.048409,0.616308,0.041259},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.345816,0.020735},6,{1.047173,0.63372,-0.025872},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.140705,0.45491,0.103677},7,{1.14997,0.667765,0.046549},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.327535,0.020735},6,{1.147735,0.684515,-0.020442},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.140705,0.42952,0.103677},7,{1.251531,0.719223,0.051839},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.020735,0.309254,0.020735},6,{1.248352,0.735263,-0.015019},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},6,{0.496169,0.533197,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},6,{0.629468,0.599846,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},6,{0.762767,0.666496,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.14811,0.29622,0.118488},6,{0.896067,0.733145,-0.059244},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.103677,0.347112,0.103677},8,{-0.340653,0.673901,0.062947},{0.768221,-0.640039,0.013658,0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.069982,0.367824,0.069982},8,{-0.529494,0.973824,0.062947},{0.906183,-0.4228,-0.008514,0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.036287,0.230643,0.036287},8,{-0.61836,1.255234,0.059244},{0.99535,-0.096324,0,0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.103677,0.347112,0.103677},9,{0.340653,0.673901,0.062947},{0.768221,0.640039,-0.013658,-0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.069982,0.367824,0.069982},9,{0.529494,0.973824,0.062947},{0.906183,0.4228,0.008514,-0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.036287,0.230643,0.036287},9,{0.61836,1.255234,0.059244},{0.99535,0.096324,0,-0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.276615,1.044177,-0.022827},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.257764,1.044177,0.047525},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.221347,1.044177,0.110601},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.169846,1.044177,0.162103},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.106769,1.044177,0.19852},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.036417,1.044177,0.217371},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.036417,1.044177,0.217371},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.106769,1.044177,0.19852},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.169846,1.044177,0.162103},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.221347,1.044177,0.110601},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.257764,1.044177,0.047525},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.276615,1.044177,-0.022827},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.276615,1.044177,-0.095661},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.257764,1.044177,-0.166013},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.221347,1.044177,-0.22909},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.169846,1.044177,-0.280591},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.106769,1.044177,-0.317008},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{-0.036417,1.044177,-0.335859},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.036417,1.044177,-0.335859},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.106769,1.044177,-0.317008},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.169846,1.044177,-0.280591},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.221347,1.044177,-0.22909},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.257764,1.044177,-0.166013},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.033325,0.073463,0.033325},10,{0.276615,1.044177,-0.095661},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'box','IvorySigil',{0.140705,0.888661,0.074055},11,{0,0.037028,-0.585035},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','RadiantSigil',{0.042952,0.881256,0.042952},12,{0,0.070352,-0.636874},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.04073,0.325168,0.04073},13,{0,-0.185138,-0.607252},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.04073,0.325168,0.04073},13,{0,0.081461,-0.607252},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.04073,0.325168,0.04073},13,{0,0.318437,-0.607252},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'corner','BasePoint',{0.137002,0.414709,0.137002},14,{0.068501,-0.829417,0.068501},{-1.0,0,0,0,-1.0,0,0,0,1.0},'metal',0,0},{'corner','BasePoint',{0.137002,0.414709,0.137002},14,{-0.068501,-0.829417,0.068501},{0,0,-1.0,0,-1.0,0,-1.0,0,0},'metal',0,0},{'corner','BasePoint',{0.137002,0.414709,0.137002},14,{-0.068501,-0.829417,-0.068501},{1.0,0,0,0,-1.0,0,0,0,-1.0},'metal',0,0},{'corner','BasePoint',{0.137002,0.414709,0.137002},14,{0.068501,-0.829417,-0.068501},{0,0,1.0,0,-1.0,0,1.0,0,0},'metal',0,0}},bounds={2.8,2.408538,1.256062}},
['Cthulhu Egg']={palette={{15,64,29},{15,61,27},{31,91,39},{23,78,35},{36,53,66},{92,135,65},{113,139,42},{105,240,50},{62,124,32},{5,29,12},{4,32,12}},parts={{'ball','EggShell',{1.682638,2.26429,1.537225},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0,-0.985687,0.391256},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.213323,-0.985814,0.338931},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.369665,-0.986079,0.195795},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.426959,-0.986217,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.369665,-0.986079,-0.195795},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.213323,-0.985814,-0.338931},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0,-0.985687,-0.391256},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.213323,-0.985814,-0.338931},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.369665,-0.986079,-0.195795},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.426959,-0.986217,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.369665,-0.986079,0.195795},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.213323,-0.985814,0.338931},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.180177,-0.651449,0.616337},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.492596,-0.651701,0.451565},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.673413,-0.651977,0.165436},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.673413,-0.651977,-0.165436},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.492596,-0.651701,-0.451565},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.180177,-0.651449,-0.616337},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.180177,-0.651449,-0.616337},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.492596,-0.651701,-0.451565},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.673413,-0.651977,-0.165436},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.673413,-0.651977,0.165436},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.492596,-0.651701,0.451565},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.180177,-0.651449,0.616337},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0,-0.197004,0.765271},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.417805,-0.197051,0.663086},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.724348,-0.197155,0.383269},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.836847,-0.197213,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.724348,-0.197155,-0.383269},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.417805,-0.197051,-0.663086},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0,-0.197004,-0.765271},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.417805,-0.197051,-0.663086},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.724348,-0.197155,-0.383269},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.836847,-0.197213,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.724348,-0.197155,0.383269},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.417805,-0.197051,0.663086},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.212102,0.293683,0.725301},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.57992,0.293808,0.531447},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.79287,0.293949,0.194724},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.79287,0.293949,-0.194724},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.57992,0.293808,-0.531447},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.212102,0.293683,-0.725301},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.212102,0.293683,-0.725301},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.57992,0.293808,-0.531447},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.79287,0.293949,-0.194724},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.79287,0.293949,0.194724},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.57992,0.293808,0.531447},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.212102,0.293683,0.725301},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0,0.730276,0.597097},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.325806,0.730426,0.517329},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.564761,0.730748,0.298964},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.65241,0.730922,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.564761,0.730748,-0.298964},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.325806,0.730426,-0.517329},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0,0.730276,-0.597097},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.325806,0.730426,-0.517329},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.564761,0.730748,-0.298964},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.65241,0.730922,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.564761,0.730748,0.298964},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.325806,0.730426,0.517329},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.103701,1.00518,0.355025},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.283422,1.005389,0.260013},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{-0.387313,1.005608,0.095216},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.387313,1.005608,-0.095216},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.283422,1.005389,-0.260013},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{-0.103701,1.00518,-0.355025},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.103701,1.00518,-0.355025},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.283422,1.005389,-0.260013},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.387313,1.005608,-0.095216},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.387313,1.005608,0.095216},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.283422,1.005389,0.260013},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.103701,1.00518,0.355025},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'slate',0,0},{'box','CurledTentacle',{0.166186,0.373486,0.166186},5,{-0.534913,-0.893252,-0.571266},{0.483077,-0.80649,-0.340897,0.875578,0.44496,0.188081,0,-0.38934,0.921094},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{-0.685519,-0.810159,-0.643973},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.157877,0.459602,0.157877},5,{-0.753032,-0.592039,-0.618006},{0.955286,-0.29379,0.033411,0.295684,0.949168,-0.107944,0,0.112996,0.993595},'plastic',0,0},{'ball','CurledTentacleJoint',{0.157877,0.157877,0.157877},5,{-0.820546,-0.37392,-0.592039},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.149568,0.516625,0.149568},5,{-0.804966,-0.119447,-0.550493},{0.998131,0.060314,-0.009829,-0.06111,0.985136,-0.160538,0,0.160839,0.986981},'plastic',0,0},{'ball','CurledTentacleJoint',{0.149568,0.149568,0.149568},5,{-0.789386,0.135026,-0.508946},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.141258,0.529108,0.141258},5,{-0.690712,0.379113,-0.482979},{0.92711,0.372979,-0.036786,-0.374789,0.922633,-0.090998,0,0.098152,0.995171},'plastic',0,0},{'ball','CurledTentacleJoint',{0.141258,0.141258,0.141258},5,{-0.592039,0.623199,-0.457013},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.132949,0.494431,0.132949},5,{-0.514139,0.830932,-0.347953},{0.936329,0.315109,-0.154899,-0.351123,0.840292,-0.413065,0,0.441153,0.897432},'plastic',0,0},{'ball','CurledTentacleJoint',{0.132949,0.132949,0.132949},5,{-0.436239,1.038665,-0.238893},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.39195,0.12464},5,{-0.560879,1.184078,-0.197346},{0.759257,-0.635999,0.137967,0.650791,0.741999,-0.160962,0,0.212,0.97727},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{-0.685519,1.329492,-0.1558},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.116331,0.265012,0.116331},5,{-0.804966,1.272365,-0.150606},{-0.431455,-0.901441,0.035357,0.902134,-0.431124,0.01691,0,0.039193,0.999232},'plastic',0,0},{'ball','CurledTentacleJoint',{0.116331,0.116331,0.116331},5,{-0.924412,1.215238,-0.145413},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.108021,0.226372,0.108021},5,{-0.908832,1.106179,-0.17138},{-0.989949,0.137649,0.032444,-0.141421,-0.963546,-0.22711,0,-0.229416,0.973329},'plastic',0,0},{'ball','CurledTentacleJoint',{0.108021,0.108021,0.108021},5,{-0.893252,0.997119,-0.197346},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.099712,0.21057,0.099712},5,{-0.794579,0.971152,-0.223313},{-0.254493,0.937201,0.238511,-0.967075,-0.246632,-0.062766,0,-0.246632,0.969109},'plastic',0,0},{'ball','CurledTentacleJoint',{0.099712,0.099712,0.099712},5,{-0.695906,0.945185,-0.24928},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.384306,-0.976345,-0.594117},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.685519,-0.810159,-0.73953},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.820546,-0.37392,-0.687596},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.789386,0.135026,-0.604503},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.592039,0.623199,-0.55257},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.436239,1.038665,-0.33445},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.865326,-0.339648,0.171308},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.822401,-0.233765,0.171308},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.827698,-0.231618,0.057198},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.870624,-0.337501,0.057198},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.890082,0.186452,0.171325},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.839991,0.28914,0.171325},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.844489,0.291334,0.057181},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.89458,0.188646,0.057181},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.913863,0.712404,0.171337},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.858377,0.81228,0.171337},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.862254,0.814434,0.05717},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.917741,0.714558,0.05717},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.238893,0.259666,0.238893},8,{-0.436239,1.017892,-0.467399},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.166186,0.373486,0.166186},5,{0.534913,-0.893252,-0.571266},{0.483077,0.80649,0.340897,-0.875578,0.44496,0.188081,0,-0.38934,0.921094},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{0.685519,-0.810159,-0.643973},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.157877,0.459602,0.157877},5,{0.753032,-0.592039,-0.618006},{0.955286,0.29379,-0.033411,-0.295684,0.949168,-0.107944,0,0.112996,0.993595},'plastic',0,0},{'ball','CurledTentacleJoint',{0.157877,0.157877,0.157877},5,{0.820546,-0.37392,-0.592039},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.149568,0.516625,0.149568},5,{0.804966,-0.119447,-0.550493},{0.998131,-0.060314,0.009829,0.06111,0.985136,-0.160538,0,0.160839,0.986981},'plastic',0,0},{'ball','CurledTentacleJoint',{0.149568,0.149568,0.149568},5,{0.789386,0.135026,-0.508946},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.141258,0.529108,0.141258},5,{0.690712,0.379113,-0.482979},{0.92711,-0.372979,0.036786,0.374789,0.922633,-0.090998,0,0.098152,0.995171},'plastic',0,0},{'ball','CurledTentacleJoint',{0.141258,0.141258,0.141258},5,{0.592039,0.623199,-0.457013},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.132949,0.494431,0.132949},5,{0.514139,0.830932,-0.347953},{0.936329,-0.315109,0.154899,0.351123,0.840292,-0.413065,0,0.441153,0.897432},'plastic',0,0},{'ball','CurledTentacleJoint',{0.132949,0.132949,0.132949},5,{0.436239,1.038665,-0.238893},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.39195,0.12464},5,{0.560879,1.184078,-0.197346},{0.759257,0.635999,-0.137967,-0.650791,0.741999,-0.160962,0,0.212,0.97727},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{0.685519,1.329492,-0.1558},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.116331,0.265012,0.116331},5,{0.804966,1.272365,-0.150606},{-0.431455,0.901441,-0.035357,-0.902134,-0.431124,0.01691,0,0.039193,0.999232},'plastic',0,0},{'ball','CurledTentacleJoint',{0.116331,0.116331,0.116331},5,{0.924412,1.215238,-0.145413},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.108021,0.226372,0.108021},5,{0.908832,1.106179,-0.17138},{-0.989949,-0.137649,-0.032444,0.141421,-0.963546,-0.22711,0,-0.229416,0.973329},'plastic',0,0},{'ball','CurledTentacleJoint',{0.108021,0.108021,0.108021},5,{0.893252,0.997119,-0.197346},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.099712,0.21057,0.099712},5,{0.794579,0.971152,-0.223313},{-0.254493,-0.937201,-0.238511,0.967075,-0.246632,-0.062766,0,-0.246632,0.969109},'plastic',0,0},{'ball','CurledTentacleJoint',{0.099712,0.099712,0.099712},5,{0.695906,0.945185,-0.24928},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.384306,-0.976345,-0.594117},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.685519,-0.810159,-0.73953},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.820546,-0.37392,-0.687596},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.789386,0.135026,-0.604503},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.592039,0.623199,-0.55257},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.436239,1.038665,-0.33445},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.822401,-0.233765,0.171308},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.865326,-0.339648,0.171308},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.870624,-0.337501,0.057198},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.827698,-0.231618,0.057198},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.839991,0.28914,0.171325},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.890082,0.186452,0.171325},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.89458,0.188646,0.057181},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.844489,0.291334,0.057181},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.858377,0.81228,0.171337},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.913863,0.712404,0.171337},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.917741,0.714558,0.05717},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.862254,0.814434,0.05717},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.238893,0.259666,0.238893},8,{0.436239,1.017892,-0.467399},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.013305,1.268666,0.1736},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.211684,1.227823,0.1736},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.215201,1.244904,-0.028187},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.016822,1.285747,-0.028187},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{0.654359,1.007505,0.145413},10,{0,-0.103867,-0.785231},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.043624,0.326643,0.043624},8,{-0.083093,-0.524526,-0.903639},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.043624,0.530126,0.043624},8,{-0.176573,-0.119447,-0.914025},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.043624,0.409977,0.043624},8,{-0.09348,0.32718,-0.898446},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.043624,0.40093,0.043624},8,{0.083093,0.32718,-0.898446},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.043624,0.529821,0.043624},8,{0.160993,-0.119447,-0.914025},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.043624,0.321483,0.043624},8,{0.0779,-0.524526,-0.903639},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.114253,0.664746,0.114253},11,{0,-0.083093,-0.893252},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.436239,-0.571266,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.436239,0.051933,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.353146,0.612813,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.342917,0.036353},8,{-0.2337,1.261978,-0.103867},{0.817806,-0.575493,0,0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.222284,0.036353},8,{-0.26486,1.490485,-0.103867},{0.794358,0.60745,0,-0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.147622,0.036353},8,{-0.14022,1.532031,-0.103867},{-0.633238,0.773957,0,-0.773957,-0.633238,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.436239,-0.571266,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.436239,0.051933,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.353146,0.612813,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.342917,0.036353},8,{0.2337,1.261978,-0.103867},{0.817806,0.575493,0,-0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.222284,0.036353},8,{0.26486,1.490485,-0.103867},{0.794358,-0.60745,0,0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.036353,0.147622,0.036353},8,{0.14022,1.532031,-0.103867},{-0.633238,-0.773957,0,0.773957,-0.633238,0,0,0,1.0},'neon',0,0}},bounds={2.362244,2.8,1.782662}},
['Luminous Cthulhu Egg']={palette={{10,71,82},{9,65,76},{21,105,111},{16,91,101},{47,41,91},{63,135,159},{57,166,172},{98,228,255},{29,127,136},{4,23,44},{2,16,31}},parts={{'ball','EggShell',{1.682638,2.26429,1.537225},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0,-0.985687,0.391256},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.213323,-0.985814,0.338931},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.369665,-0.986079,0.195795},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.426959,-0.986217,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.369665,-0.986079,-0.195795},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.213323,-0.985814,-0.338931},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0,-0.985687,-0.391256},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.213323,-0.985814,-0.338931},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.369665,-0.986079,-0.195795},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.426959,-0.986217,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.369665,-0.986079,0.195795},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.213323,-0.985814,0.338931},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.180177,-0.651449,0.616337},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.492596,-0.651701,0.451565},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.673413,-0.651977,0.165436},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.673413,-0.651977,-0.165436},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.492596,-0.651701,-0.451565},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.180177,-0.651449,-0.616337},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.180177,-0.651449,-0.616337},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.492596,-0.651701,-0.451565},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.673413,-0.651977,-0.165436},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.673413,-0.651977,0.165436},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.492596,-0.651701,0.451565},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.180177,-0.651449,0.616337},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0,-0.197004,0.765271},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.417805,-0.197051,0.663086},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.724348,-0.197155,0.383269},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.836847,-0.197213,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.724348,-0.197155,-0.383269},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.417805,-0.197051,-0.663086},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0,-0.197004,-0.765271},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.417805,-0.197051,-0.663086},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.724348,-0.197155,-0.383269},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.836847,-0.197213,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.724348,-0.197155,0.383269},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.417805,-0.197051,0.663086},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.212102,0.293683,0.725301},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.57992,0.293808,0.531447},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.79287,0.293949,0.194724},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.79287,0.293949,-0.194724},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.57992,0.293808,-0.531447},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.212102,0.293683,-0.725301},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.212102,0.293683,-0.725301},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.57992,0.293808,-0.531447},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.79287,0.293949,-0.194724},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.79287,0.293949,0.194724},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.57992,0.293808,0.531447},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.212102,0.293683,0.725301},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0,0.730276,0.597097},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.325806,0.730426,0.517329},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.564761,0.730748,0.298964},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{-0.65241,0.730922,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{-0.564761,0.730748,-0.298964},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{-0.325806,0.730426,-0.517329},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0,0.730276,-0.597097},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.325806,0.730426,-0.517329},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},2,{0.564761,0.730748,-0.298964},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.65241,0.730922,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},4,{0.564761,0.730748,0.298964},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'slate',0,0},{'box','CarvedStone',{0.3116,0.290826,0.09348},3,{0.325806,0.730426,0.517329},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.103701,1.00518,0.355025},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.283422,1.005389,0.260013},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{-0.387313,1.005608,0.095216},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{-0.387313,1.005608,-0.095216},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{-0.283422,1.005389,-0.260013},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{-0.103701,1.00518,-0.355025},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.103701,1.00518,-0.355025},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},3,{0.283422,1.005389,-0.260013},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.387313,1.005608,-0.095216},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.387313,1.005608,0.095216},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},4,{0.283422,1.005389,0.260013},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'slate',0,0},{'box','CarvedStone',{0.238893,0.290826,0.09348},2,{0.103701,1.00518,0.355025},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'slate',0,0},{'box','CurledTentacle',{0.166186,0.373486,0.166186},5,{-0.534913,-0.893252,-0.571266},{0.483077,-0.80649,-0.340897,0.875578,0.44496,0.188081,0,-0.38934,0.921094},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{-0.685519,-0.810159,-0.643973},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.157877,0.459602,0.157877},5,{-0.753032,-0.592039,-0.618006},{0.955286,-0.29379,0.033411,0.295684,0.949168,-0.107944,0,0.112996,0.993595},'plastic',0,0},{'ball','CurledTentacleJoint',{0.157877,0.157877,0.157877},5,{-0.820546,-0.37392,-0.592039},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.149568,0.516625,0.149568},5,{-0.804966,-0.119447,-0.550493},{0.998131,0.060314,-0.009829,-0.06111,0.985136,-0.160538,0,0.160839,0.986981},'plastic',0,0},{'ball','CurledTentacleJoint',{0.149568,0.149568,0.149568},5,{-0.789386,0.135026,-0.508946},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.141258,0.529108,0.141258},5,{-0.690712,0.379113,-0.482979},{0.92711,0.372979,-0.036786,-0.374789,0.922633,-0.090998,0,0.098152,0.995171},'plastic',0,0},{'ball','CurledTentacleJoint',{0.141258,0.141258,0.141258},5,{-0.592039,0.623199,-0.457013},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.132949,0.494431,0.132949},5,{-0.514139,0.830932,-0.347953},{0.936329,0.315109,-0.154899,-0.351123,0.840292,-0.413065,0,0.441153,0.897432},'plastic',0,0},{'ball','CurledTentacleJoint',{0.132949,0.132949,0.132949},5,{-0.436239,1.038665,-0.238893},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.39195,0.12464},5,{-0.560879,1.184078,-0.197346},{0.759257,-0.635999,0.137967,0.650791,0.741999,-0.160962,0,0.212,0.97727},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{-0.685519,1.329492,-0.1558},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.116331,0.265012,0.116331},5,{-0.804966,1.272365,-0.150606},{-0.431455,-0.901441,0.035357,0.902134,-0.431124,0.01691,0,0.039193,0.999232},'plastic',0,0},{'ball','CurledTentacleJoint',{0.116331,0.116331,0.116331},5,{-0.924412,1.215238,-0.145413},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.108021,0.226372,0.108021},5,{-0.908832,1.106179,-0.17138},{-0.989949,0.137649,0.032444,-0.141421,-0.963546,-0.22711,0,-0.229416,0.973329},'plastic',0,0},{'ball','CurledTentacleJoint',{0.108021,0.108021,0.108021},5,{-0.893252,0.997119,-0.197346},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.099712,0.21057,0.099712},5,{-0.794579,0.971152,-0.223313},{-0.254493,0.937201,0.238511,-0.967075,-0.246632,-0.062766,0,-0.246632,0.969109},'plastic',0,0},{'ball','CurledTentacleJoint',{0.099712,0.099712,0.099712},5,{-0.695906,0.945185,-0.24928},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.384306,-0.976345,-0.594117},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.685519,-0.810159,-0.73953},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.820546,-0.37392,-0.687596},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.789386,0.135026,-0.604503},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.592039,0.623199,-0.55257},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{-0.436239,1.038665,-0.33445},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.865326,-0.339648,0.171308},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.822401,-0.233765,0.171308},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.827698,-0.231618,0.057198},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{-0.870624,-0.337501,0.057198},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.890082,0.186452,0.171325},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.839991,0.28914,0.171325},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.844489,0.291334,0.057181},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{-0.89458,0.188646,0.057181},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.913863,0.712404,0.171337},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.858377,0.81228,0.171337},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.862254,0.814434,0.05717},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{-0.917741,0.714558,0.05717},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.238893,0.259666,0.238893},8,{-0.436239,1.017892,-0.467399},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.166186,0.373486,0.166186},5,{0.534913,-0.893252,-0.571266},{0.483077,0.80649,0.340897,-0.875578,0.44496,0.188081,0,-0.38934,0.921094},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{0.685519,-0.810159,-0.643973},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.157877,0.459602,0.157877},5,{0.753032,-0.592039,-0.618006},{0.955286,0.29379,-0.033411,-0.295684,0.949168,-0.107944,0,0.112996,0.993595},'plastic',0,0},{'ball','CurledTentacleJoint',{0.157877,0.157877,0.157877},5,{0.820546,-0.37392,-0.592039},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.149568,0.516625,0.149568},5,{0.804966,-0.119447,-0.550493},{0.998131,-0.060314,0.009829,0.06111,0.985136,-0.160538,0,0.160839,0.986981},'plastic',0,0},{'ball','CurledTentacleJoint',{0.149568,0.149568,0.149568},5,{0.789386,0.135026,-0.508946},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.141258,0.529108,0.141258},5,{0.690712,0.379113,-0.482979},{0.92711,-0.372979,0.036786,0.374789,0.922633,-0.090998,0,0.098152,0.995171},'plastic',0,0},{'ball','CurledTentacleJoint',{0.141258,0.141258,0.141258},5,{0.592039,0.623199,-0.457013},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.132949,0.494431,0.132949},5,{0.514139,0.830932,-0.347953},{0.936329,-0.315109,0.154899,0.351123,0.840292,-0.413065,0,0.441153,0.897432},'plastic',0,0},{'ball','CurledTentacleJoint',{0.132949,0.132949,0.132949},5,{0.436239,1.038665,-0.238893},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.39195,0.12464},5,{0.560879,1.184078,-0.197346},{0.759257,0.635999,-0.137967,-0.650791,0.741999,-0.160962,0,0.212,0.97727},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{0.685519,1.329492,-0.1558},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.116331,0.265012,0.116331},5,{0.804966,1.272365,-0.150606},{-0.431455,0.901441,-0.035357,-0.902134,-0.431124,0.01691,0,0.039193,0.999232},'plastic',0,0},{'ball','CurledTentacleJoint',{0.116331,0.116331,0.116331},5,{0.924412,1.215238,-0.145413},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.108021,0.226372,0.108021},5,{0.908832,1.106179,-0.17138},{-0.989949,-0.137649,-0.032444,0.141421,-0.963546,-0.22711,0,-0.229416,0.973329},'plastic',0,0},{'ball','CurledTentacleJoint',{0.108021,0.108021,0.108021},5,{0.893252,0.997119,-0.197346},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.099712,0.21057,0.099712},5,{0.794579,0.971152,-0.223313},{-0.254493,-0.937201,-0.238511,0.967075,-0.246632,-0.062766,0,-0.246632,0.969109},'plastic',0,0},{'ball','CurledTentacleJoint',{0.099712,0.099712,0.099712},5,{0.695906,0.945185,-0.24928},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.384306,-0.976345,-0.594117},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.685519,-0.810159,-0.73953},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.820546,-0.37392,-0.687596},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.789386,0.135026,-0.604503},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.592039,0.623199,-0.55257},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.025967,0.09348,0.09348},6,{0.436239,1.038665,-0.33445},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.822401,-0.233765,0.171308},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.865326,-0.339648,0.171308},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.870624,-0.337501,0.057198},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.114253,0.415206,0.114253},7,{0.827698,-0.231618,0.057198},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.839991,0.28914,0.171325},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.890082,0.186452,0.171325},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.89458,0.188646,0.057181},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.114253,0.474273,0.114253},7,{0.844489,0.291334,0.057181},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.858377,0.81228,0.171337},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.913863,0.712404,0.171337},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.917741,0.714558,0.05717},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.114253,0.535089,0.114253},7,{0.862254,0.814434,0.05717},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.238893,0.259666,0.238893},8,{0.436239,1.017892,-0.467399},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.013305,1.268666,0.1736},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.211684,1.227823,0.1736},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.215201,1.244904,-0.028187},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.20254,0.723794,0.20254},9,{0.016822,1.285747,-0.028187},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{0.654359,1.007505,0.145413},10,{0,-0.103867,-0.785231},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.043624,0.326643,0.043624},8,{-0.083093,-0.524526,-0.903639},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.043624,0.530126,0.043624},8,{-0.176573,-0.119447,-0.914025},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.043624,0.409977,0.043624},8,{-0.09348,0.32718,-0.898446},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.043624,0.40093,0.043624},8,{0.083093,0.32718,-0.898446},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.043624,0.529821,0.043624},8,{0.160993,-0.119447,-0.914025},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.043624,0.321483,0.043624},8,{0.0779,-0.524526,-0.903639},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.114253,0.664746,0.114253},11,{0,-0.083093,-0.893252},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.436239,-0.571266,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.436239,0.051933,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{-0.353146,0.612813,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.436239,-0.571266,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.436239,0.051933,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.0779,0.0779,0.036353},8,{0.353146,0.612813,-0.747839},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={2.362244,2.8,1.782662}},
['Sabertooth Egg']={palette={{36,30,28},{139,39,17},{45,39,34},{193,65,15},{224,92,16},{89,32,23},{232,224,188},{91,42,14},{255,193,16}},parts={{'ball','EggShell',{1.732533,2.331433,1.582808},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{0,-1.014916,0.402857},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},3,{-0.219648,-1.015047,0.348982},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},3,{-0.380626,-1.015319,0.201601},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},4,{-0.43962,-1.015461,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{-0.380626,-1.015319,-0.201601},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{-0.219648,-1.015047,-0.348982},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{0,-1.014916,-0.402857},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{0.219648,-1.015047,-0.348982},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},6,{0.380626,-1.015319,-0.201601},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{0.43962,-1.015461,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},6,{0.380626,-1.015319,0.201601},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},6,{0.219648,-1.015047,0.348982},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{-0.18552,-0.670766,0.634613},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.507203,-0.671025,0.464956},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{-0.693382,-0.67131,0.170341},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{-0.693382,-0.67131,-0.170341},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{-0.507203,-0.671025,-0.464956},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{-0.18552,-0.670766,-0.634613},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.18552,-0.670766,-0.634613},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.507203,-0.671025,-0.464956},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0.693382,-0.67131,-0.170341},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{0.693382,-0.67131,0.170341},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{0.507203,-0.671025,0.464956},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0.18552,-0.670766,0.634613},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0,-0.202846,0.787963},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{-0.430194,-0.202894,0.682749},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.745827,-0.203001,0.394634},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.861662,-0.203061,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.745827,-0.203001,-0.394634},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{-0.430194,-0.202894,-0.682749},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0,-0.202846,-0.787963},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{0.430194,-0.202894,-0.682749},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{0.745827,-0.203001,-0.394634},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.861662,-0.203061,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{0.745827,-0.203001,0.394634},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{0.430194,-0.202894,0.682749},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{-0.218391,0.302391,0.746808},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{-0.597116,0.30252,0.547206},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{-0.816381,0.302665,0.200499},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{-0.816381,0.302665,-0.200499},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.597116,0.30252,-0.547206},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{-0.218391,0.302391,-0.746808},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0.218391,0.302391,-0.746808},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0.597116,0.30252,-0.547206},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.816381,0.302665,-0.200499},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{0.816381,0.302665,0.200499},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{0.597116,0.30252,0.547206},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{0.218391,0.302391,0.746808},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0,0.751931,0.614803},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{-0.335467,0.752085,0.53267},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{-0.581507,0.752417,0.30783},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{-0.671755,0.752596,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{-0.581507,0.752417,-0.30783},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},4,{-0.335467,0.752085,-0.53267},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},6,{0,0.751931,-0.614803},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.335467,0.752085,-0.53267},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},3,{0.581507,0.752417,-0.30783},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},5,{0.671755,0.752596,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{0.581507,0.752417,0.30783},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'slate',0,0},{'box','VolcanicPlate',{0.320839,0.29945,0.096252},2,{0.335467,0.752085,0.53267},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{-0.106776,1.034986,0.365553},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{-0.291827,1.035202,0.267723},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},5,{-0.398798,1.035427,0.098039},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{-0.398798,1.035427,-0.098039},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{-0.291827,1.035202,-0.267723},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},4,{-0.106776,1.034986,-0.365553},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},6,{0.106776,1.034986,-0.365553},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{0.291827,1.035202,-0.267723},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},3,{0.398798,1.035427,-0.098039},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},3,{0.398798,1.035427,0.098039},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},2,{0.291827,1.035202,0.267723},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'slate',0,0},{'box','VolcanicPlate',{0.245977,0.29945,0.096252},6,{0.106776,1.034986,0.365553},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'slate',0,0},{'corner','LavaCrown',{0.117641,0.58876,0.117641},5,{-0.058821,1.144977,-0.494956},{1.0,0,0,0,0.985315,0.170748,0,-0.170748,0.985315},'slate',0,0},{'corner','LavaCrown',{0.117641,0.58876,0.117641},5,{0.058821,1.144977,-0.494956},{0,0,1.0,-0.170748,0.985315,0,-0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.58876,0.117641},5,{0.058821,1.12489,-0.61087},{-1.0,0,0,0,0.985315,-0.170748,0,-0.170748,-0.985315},'slate',0,0},{'corner','LavaCrown',{0.117641,0.58876,0.117641},5,{-0.058821,1.12489,-0.61087},{0,0,-1.0,0.170748,0.985315,0,0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.73464,0.117641},5,{-0.451804,1.207093,-0.36506},{0.993346,-0.114536,-0.012073,0.11517,0.987873,0.10413,0,-0.104827,0.99449},'slate',0,0},{'corner','LavaCrown',{0.117641,0.73464,0.117641},5,{-0.334946,1.220642,-0.36506},{0.012073,-0.114536,0.993346,-0.10413,0.987873,0.11517,-0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.73464,0.117641},5,{-0.333526,1.208392,-0.482053},{-0.993346,-0.114536,0.012073,-0.11517,0.987873,-0.10413,0,-0.104827,-0.99449},'slate',0,0},{'corner','LavaCrown',{0.117641,0.73464,0.117641},5,{-0.450384,1.194843,-0.482053},{-0.012073,-0.114536,-0.993346,0.10413,0.987873,-0.11517,0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.778263,0.117641},4,{-0.659824,1.220089,-0.037207},{0.986179,-0.165643,-0.003716,0.165685,0.985931,0.02212,0,-0.02243,0.999748},'slate',0,0},{'corner','LavaCrown',{0.117641,0.778263,0.117641},4,{-0.543809,1.23958,-0.037207},{0.003716,-0.165643,0.986179,-0.02212,0.985931,0.165685,-0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.778263,0.117641},4,{-0.543371,1.236978,-0.154818},{-0.986179,-0.165643,0.003716,-0.165685,0.985931,-0.02212,0,-0.02243,-0.999748},'slate',0,0},{'corner','LavaCrown',{0.117641,0.778263,0.117641},4,{-0.659387,1.217487,-0.154818},{-0.003716,-0.165643,-0.986179,0.02212,0.985931,-0.165685,0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.731807,0.117641},4,{-0.586516,1.192364,0.335138},{0.987871,-0.154911,0.010665,0.155278,0.985538,-0.067853,0,0.068686,0.997638},'slate',0,0},{'corner','LavaCrown',{0.117641,0.731807,0.117641},4,{-0.470302,1.210631,0.335138},{-0.010665,-0.154911,0.987871,0.067853,0.985538,0.155278,-0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.731807,0.117641},4,{-0.471556,1.218613,0.217775},{-0.987871,-0.154911,-0.010665,-0.155278,0.985538,0.067853,0,0.068686,-0.997638},'slate',0,0},{'corner','LavaCrown',{0.117641,0.731807,0.117641},4,{-0.58777,1.200346,0.217775},{0.010665,-0.154911,-0.987871,-0.067853,0.985538,-0.155278,0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.728522,0.117641},5,{-0.267167,1.19411,0.577892},{0.998078,-0.061455,0.008037,0.061978,0.989651,-0.12942,0,0.129669,0.991557},'slate',0,0},{'corner','LavaCrown',{0.117641,0.728522,0.117641},5,{-0.149752,1.201401,0.577892},{-0.008037,-0.061455,0.998078,0.12942,0.989651,0.061978,-0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.728522,0.117641},5,{-0.150698,1.216626,0.461244},{-0.998078,-0.061455,-0.008037,-0.061978,0.989651,0.12942,0,0.129669,-0.991557},'slate',0,0},{'corner','LavaCrown',{0.117641,0.728522,0.117641},5,{-0.268113,1.209335,0.461244},{0.008037,-0.061455,-0.998078,-0.12942,0.989651,-0.061978,0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.665391,0.117641},4,{0.14968,1.169108,0.577793},{0.997687,0.067286,-0.00965,-0.067974,0.987581,-0.141644,0,0.141972,0.989871},'slate',0,0},{'corner','LavaCrown',{0.117641,0.665391,0.117641},4,{0.267049,1.161111,0.577793},{0.00965,0.067286,0.997687,0.141644,0.987581,-0.067974,-0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.665391,0.117641},4,{0.268185,1.177774,0.461344},{-0.997687,0.067286,0.00965,0.067974,0.987581,0.141644,0,0.141972,-0.989871},'slate',0,0},{'corner','LavaCrown',{0.117641,0.665391,0.117641},4,{0.150816,1.185771,0.461344},{-0.00965,0.067286,-0.997687,-0.141644,0.987581,0.067974,0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.720543,0.117641},4,{0.470304,1.204998,0.335134},{0.987484,0.157332,-0.011002,-0.157717,0.985079,-0.068887,0,0.06976,0.997564},'slate',0,0},{'corner','LavaCrown',{0.117641,0.720543,0.117641},4,{0.586473,1.186444,0.335134},{0.011002,0.157332,0.987484,0.068887,0.985079,-0.157717,-0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.720543,0.117641},4,{0.587768,1.194548,0.217779},{-0.987484,0.157332,0.011002,0.157717,0.985079,0.068887,0,0.06976,-0.997564},'slate',0,0},{'corner','LavaCrown',{0.117641,0.720543,0.117641},4,{0.471599,1.213102,0.217779},{-0.011002,0.157332,-0.987484,-0.068887,0.985079,0.157717,0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.657563,0.117641},2,{0.544226,1.180227,-0.037213},{0.980581,0.196048,0.005206,-0.196117,0.980235,0.026032,0,-0.026548,0.999648},'slate',0,0},{'corner','LavaCrown',{0.117641,0.657563,0.117641},2,{0.659582,1.157156,-0.037213},{-0.005206,0.196048,0.980581,-0.026032,0.980235,-0.196117,-0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.657563,0.117641},2,{0.65897,1.154093,-0.154812},{-0.980581,0.196048,-0.005206,0.196117,0.980235,-0.026032,0,-0.026548,-0.999648},'slate',0,0},{'corner','LavaCrown',{0.117641,0.657563,0.117641},2,{0.543613,1.177165,-0.154812},{0.005206,0.196048,-0.980581,0.026032,0.980235,0.196117,0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.625787,0.117641},4,{0.335367,1.16767,-0.365183},{0.990779,0.134459,0.016673,-0.135488,0.983248,0.121927,0,-0.123061,0.992399},'slate',0,0},{'corner','LavaCrown',{0.117641,0.625787,0.117641},4,{0.451924,1.151731,-0.365183},{-0.016673,0.134459,0.990779,-0.121927,0.983248,-0.135488,-0.992399,-0.123061,0},'slate',0,0},{'corner','LavaCrown',{0.117641,0.625787,0.117641},4,{0.449962,1.137388,-0.48193},{-0.990779,0.134459,-0.016673,0.135488,0.983248,-0.121927,0,-0.123061,-0.992399},'slate',0,0},{'corner','LavaCrown',{0.117641,0.625787,0.117641},4,{0.333406,1.153327,-0.48193},{0.016673,0.134459,-0.990779,0.121927,0.983248,0.135488,0.992399,-0.123061,0},'slate',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{-0.86339,0.749456,-0.347284},{0.888218,-0.446223,-0.109336,0.459423,0.862698,0.211383,0,-0.237986,0.971269},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{-0.716153,0.825613,-0.347284},{0.109336,-0.446223,0.888218,-0.211383,0.862698,0.459423,-0.971269,-0.237986,0},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{-0.698028,0.790573,-0.508288},{-0.888218,-0.446223,0.109336,-0.459423,0.862698,-0.211383,0,-0.237986,-0.971269},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{-0.845266,0.714416,-0.508288},{-0.109336,-0.446223,-0.888218,0.211383,0.862698,-0.459423,0.971269,-0.237986,0},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{-0.688337,-0.844113,-0.434176},{-0.931243,-0.342376,-0.124762,0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{-0.802869,-0.799296,-0.434176},{0.124762,-0.342376,-0.931243,0.318835,-0.874961,0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{-0.787524,-0.760083,-0.549731},{0.931243,-0.342376,0.124762,-0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{-0.672992,-0.8049,-0.549731},{-0.124762,-0.342376,0.931243,-0.318835,-0.874961,-0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.096252,0.470564,0.470564},8,{-0.695152,0.064168,-0.524038},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.085557,0.320839,0.320839},9,{-0.737931,0.064168,-0.588206},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'neon',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{0.716153,0.825613,-0.347284},{0.888218,0.446223,0.109336,-0.459423,0.862698,0.211383,0,-0.237986,0.971269},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{0.86339,0.749456,-0.347284},{-0.109336,0.446223,0.888218,-0.211383,0.862698,-0.459423,-0.971269,-0.237986,0},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{0.845266,0.714416,-0.508288},{-0.888218,0.446223,-0.109336,0.459423,0.862698,-0.211383,0,-0.237986,-0.971269},'sandstone',0,0},{'corner','IvoryHorn',{0.165767,0.719011,0.165767},7,{0.698028,0.790573,-0.508288},{0.109336,0.446223,-0.888218,0.211383,0.862698,0.459423,0.971269,-0.237986,0},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{0.802869,-0.799296,-0.434176},{-0.931243,0.342376,0.124762,-0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{0.688337,-0.844113,-0.434176},{-0.124762,0.342376,-0.931243,0.318835,-0.874961,-0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{0.672992,-0.8049,-0.549731},{0.931243,0.342376,-0.124762,0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.122988,0.562258,0.122988},7,{0.787524,-0.760083,-0.549731},{0.124762,0.342376,0.931243,-0.318835,-0.874961,0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.096252,0.470564,0.470564},8,{0.695152,0.064168,-0.524038},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.085557,0.320839,0.320839},9,{0.737931,0.064168,-0.588206},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'neon',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},2,{0.192504,-0.802098,-0.791404},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},4,{-0.192504,-0.545427,-0.791404},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},5,{0.192504,-0.288755,-0.791404},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},2,{-0.192504,-0.032084,-0.791404},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},4,{0.192504,0.224588,-0.791404},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},5,{-0.192504,0.481259,-0.791404},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.320839,0.342229,0.149725},2,{0.192504,0.737931,-0.791404},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0}},bounds={2.212981,2.8,1.723229}},
['Skeletal Sabertooth Egg']={palette={{49,35,23},{158,128,85},{197,168,118},{178,148,100},{190,162,112},{198,171,123},{49,29,12},{255,181,16},{225,204,155},{201,174,125},{39,26,18},{255,172,13}},parts={{'ball','EggShell',{2.080734,2.8,1.900917},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0,-1.218892,0.483823},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.263793,-1.219049,0.419119},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.457124,-1.219376,0.242118},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.527974,-1.219547,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.457124,-1.219376,-0.242118},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{-0.263793,-1.219049,-0.419119},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0,-1.218892,-0.483823},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0.263793,-1.219049,-0.419119},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0.457124,-1.219376,-0.242118},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0.527974,-1.219547,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{0.457124,-1.219376,0.242118},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{0.263793,-1.219049,0.419119},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.222805,-0.805576,0.762156},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.609139,-0.805887,0.558402},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.832737,-0.806229,0.204576},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.832737,-0.806229,-0.204576},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.609139,-0.805887,-0.558402},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.222805,-0.805576,-0.762156},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.222805,-0.805576,-0.762156},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.609139,-0.805887,-0.558402},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.832737,-0.806229,-0.204576},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.832737,-0.806229,0.204576},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.609139,-0.805887,0.558402},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.222805,-0.805576,0.762156},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{0,-0.243613,0.946327},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.516653,-0.243671,0.819966},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.895722,-0.2438,0.473947},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-1.034837,-0.243871,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.895722,-0.2438,-0.473947},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.516653,-0.243671,-0.819966},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0,-0.243613,-0.946327},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.516653,-0.243671,-0.819966},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.895722,-0.2438,-0.473947},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{1.034837,-0.243871,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{0.895722,-0.2438,0.473947},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.516653,-0.243671,0.819966},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.262283,0.363165,0.896901},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.717123,0.36332,0.657183},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.980456,0.363494,0.240794},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.980456,0.363494,-0.240794},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.717123,0.36332,-0.657183},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.262283,0.363165,-0.896901},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.262283,0.363165,-0.896901},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{0.717123,0.36332,-0.657183},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.980456,0.363494,-0.240794},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.980456,0.363494,0.240794},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.717123,0.36332,0.657183},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.262283,0.363165,0.896901},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{0,0.903052,0.738364},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.402888,0.903237,0.639725},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.698378,0.903636,0.369697},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{-0.806764,0.903851,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{-0.698378,0.903636,-0.369697},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{-0.402888,0.903237,-0.639725},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0,0.903052,-0.738364},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.402888,0.903237,-0.639725},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.698378,0.903636,-0.369697},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},4,{0.806764,0.903851,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},2,{0.698378,0.903636,0.369697},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'sandstone',0,0},{'box','BonePlate',{0.385321,0.359633,0.115596},3,{0.402888,0.903237,0.639725},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{-0.128236,1.242996,0.439021},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.350477,1.243255,0.32153},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.478948,1.243525,0.117743},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{-0.478948,1.243525,-0.117743},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{-0.350477,1.243255,-0.32153},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},3,{-0.128236,1.242996,-0.439021},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{0.128236,1.242996,-0.439021},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{0.350477,1.243255,-0.32153},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0.478948,1.243525,-0.117743},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{0.478948,1.243525,0.117743},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},4,{0.350477,1.243255,0.32153},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'sandstone',0,0},{'box','BonePlate',{0.295413,0.359633,0.115596},2,{0.128236,1.242996,0.439021},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.105049,-0.747971,0.115377},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.023281,-0.632752,0.115377},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.014217,-0.639185,-0.025469},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.095985,-0.754404,-0.025469},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.105049,-0.195677,0.115377},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.023281,-0.080459,0.115377},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.014217,-0.086892,-0.025469},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.095985,-0.20211,-0.025469},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.105049,0.356617,0.115377},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.023281,0.471835,0.115377},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.014217,0.465402,-0.025469},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.095985,0.350183,-0.025469},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.105049,0.90891,0.115377},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.023281,1.024129,0.115377},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.014217,1.017695,-0.025469},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{-1.095985,0.902477,-0.025469},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{0.693578,0.295413,0.333945},6,{-0.321101,0.60367,-0.924771},{0.936608,0.304322,-0.173648,-0.309017,0.951057,0,0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.513761,0.231193,0.166972},7,{-0.346789,0.385321,-1.001835},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.385321,0.122018,0.115596},8,{-0.359633,0.398165,-1.104587},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.256881,0.394837,0.256881},4,{-0.616514,0,-0.905505},{-0.980581,-0.19518,-0.019139,0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.256881,0.630929,0.256881},4,{-0.63578,-0.500917,-0.86055},{-0.998053,0.061072,-0.012699,-0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.256881,0.436508,0.256881},4,{-0.494495,-0.969725,-0.712844},{-0.796162,0.559065,-0.231455,-0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{-0.211827,-0.417421,-1.034045},{-0.998581,0.053182,0.002832,-0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{-0.352911,-0.424945,-1.034045},{-0.002832,0.053182,-0.998581,0.053107,-0.997168,-0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{-0.353311,-0.417442,-1.175129},{0.998581,0.053182,-0.002832,0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{-0.212227,-0.409917,-1.175129},{0.002832,0.053182,0.998581,-0.053107,-0.997168,0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.023281,-0.632752,0.115377},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.105049,-0.747971,0.115377},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.095985,-0.754404,-0.025469},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.014217,-0.639185,-0.025469},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.023281,-0.080459,0.115377},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.105049,-0.195677,0.115377},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.095985,-0.20211,-0.025469},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.014217,-0.086892,-0.025469},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.023281,0.471835,0.115377},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.105049,0.356617,0.115377},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.095985,0.350183,-0.025469},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.014217,0.465402,-0.025469},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.023281,1.024129,0.115377},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.105049,0.90891,0.115377},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.095985,0.902477,-0.025469},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.141284,0.48976,0.141284},5,{1.014217,1.017695,-0.025469},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{0.693578,0.295413,0.333945},6,{0.321101,0.60367,-0.924771},{0.936608,-0.304322,0.173648,0.309017,0.951057,0,-0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.513761,0.231193,0.166972},7,{0.346789,0.385321,-1.001835},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.385321,0.122018,0.115596},8,{0.359633,0.398165,-1.104587},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.256881,0.394837,0.256881},4,{0.616514,0,-0.905505},{-0.980581,0.19518,0.019139,-0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.256881,0.630929,0.256881},4,{0.63578,-0.500917,-0.86055},{-0.998053,-0.061072,0.012699,0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.256881,0.436508,0.256881},4,{0.494495,-0.969725,-0.712844},{-0.796162,-0.559065,0.231455,0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{0.352911,-0.424945,-1.034045},{-0.998581,-0.053182,-0.002832,0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{0.211827,-0.417421,-1.034045},{0.002832,-0.053182,-0.998581,0.053107,-0.997168,0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{0.212227,-0.409917,-1.175129},{0.998581,-0.053182,0.002832,-0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.141284,0.966039,0.141284},9,{0.353311,-0.417442,-1.175129},{-0.002832,-0.053182,0.998581,-0.053107,-0.997168,-0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'wedge','NoseBridge',{0.359633,0.411009,0.295413},10,{0,0.205505,-0.976147},{-1.0,0,0,0,-1.0,0,0,0,1.0},'sandstone',0,0},{'box','NasalCavity',{0.205505,0.179817,0.102752},11,{0,-0.025688,-1.143119},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','LowerJaw',{0.231193,0.744954,0.231193},4,{0,-1.078899,-0.706422},{0,1.0,0,-1.0,0,0,0,0,1.0},'sandstone',0,0},{'corner','InnerEmber',{0.089908,0.490602,0.089908},12,{-0.024685,-0.762874,-0.861816},{0.996729,0.07854,0.019042,-0.080816,0.968666,0.234851,0,-0.235621,0.971845},'neon',0,0},{'corner','InnerEmber',{0.089908,0.490602,0.089908},12,{0.064929,-0.77014,-0.861816},{-0.019042,0.07854,0.996729,-0.234851,0.968666,-0.080816,-0.971845,-0.235621,0},'neon',0,0},{'corner','InnerEmber',{0.089908,0.490602,0.089908},12,{0.063217,-0.791255,-0.949193},{-0.996729,0.07854,-0.019042,0.080816,0.968666,-0.234851,0,-0.235621,-0.971845},'neon',0,0},{'corner','InnerEmber',{0.089908,0.490602,0.089908},12,{-0.026397,-0.783989,-0.949193},{0.019042,0.07854,-0.996729,0.234851,0.968666,0.080816,0.971845,-0.235621,0},'neon',0,0}},bounds={2.699097,2.8,2.300553}},
['Octophant Egg']={palette={{29,30,26},{151,150,116},{169,168,134},{138,137,103},{12,15,10},{166,165,131},{81,81,62},{181,255,37},{10,13,9},{78,78,64}},parts={{'ball','EggShell',{1.687494,2.168109,1.55933},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0,-1.013558,0.402319},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.219355,-1.013689,0.348515},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.380117,-1.013961,0.201331},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{-0.439032,-1.014103,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.380117,-1.013961,-0.201331},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.219355,-1.013689,-0.348515},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0,-1.013558,-0.402319},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.219355,-1.013689,-0.348515},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.380117,-1.013961,-0.201331},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.439032,-1.014103,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.380117,-1.013961,0.201331},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.219355,-1.013689,0.348515},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.185272,-0.669869,0.633764},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.506524,-0.670128,0.464334},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.692455,-0.670412,0.170113},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.692455,-0.670412,-0.170113},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.506524,-0.670128,-0.464334},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.185272,-0.669869,-0.633764},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.185272,-0.669869,-0.633764},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.506524,-0.670128,-0.464334},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.692455,-0.670412,-0.170113},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.692455,-0.670412,0.170113},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.506524,-0.670128,0.464334},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.185272,-0.669869,0.633764},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0,-0.202574,0.78691},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.429618,-0.202623,0.681836},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.74483,-0.20273,0.394107},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.860509,-0.202789,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.74483,-0.20273,-0.394107},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.429618,-0.202623,-0.681836},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0,-0.202574,-0.78691},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.429618,-0.202623,-0.681836},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.74483,-0.20273,-0.394107},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.860509,-0.202789,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.74483,-0.20273,0.394107},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.429618,-0.202623,0.681836},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.218099,0.301987,0.74581},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.596317,0.302116,0.546474},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.815289,0.302261,0.20023},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.815289,0.302261,-0.20023},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.596317,0.302116,-0.546474},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.218099,0.301987,-0.74581},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.218099,0.301987,-0.74581},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.596317,0.302116,-0.546474},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.815289,0.302261,-0.20023},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.815289,0.302261,0.20023},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.596317,0.302116,0.546474},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.218099,0.301987,0.74581},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0,0.750925,0.61398},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.335018,0.751079,0.531957},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.58073,0.75141,0.307418},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.670857,0.751589,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.58073,0.75141,-0.307418},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.335018,0.751079,-0.531957},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0,0.750925,-0.61398},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.335018,0.751079,-0.531957},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.58073,0.75141,-0.307418},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.670857,0.751589,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.58073,0.75141,0.307418},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'concrete',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.335018,0.751079,0.531957},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.106633,1.033602,0.365064},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.291436,1.033817,0.267365},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.398265,1.034042,0.097908},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.398265,1.034042,-0.097908},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.291436,1.033817,-0.267365},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.106633,1.033602,-0.365064},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0.106633,1.033602,-0.365064},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.291436,1.033817,-0.267365},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.398265,1.034042,-0.097908},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0.398265,1.034042,0.097908},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.291436,1.033817,0.267365},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'concrete',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.106633,1.033602,0.365064},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'concrete',0,0},{'box','CoilRecess',{0.811706,1.591371,0.128164},5,{0,-0.021361,-0.811706},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.377758,0.202927},2,{-0.560718,-0.763644,-0.688882},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.202927,1.206879,0.202927},2,{-0.662181,-0.00534,-0.726263},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.202927,0.385825,0.202927},2,{-0.555378,0.752964,-0.683542},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.128164,1.089395,0.811706},2,{-0.833067,-0.021361,0.053402},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.144185,0.555378,0.32041},8,{-0.907829,0.277689,0.160205},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.512656,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.384492,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.256328,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.128164,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.377758,0.202927},2,{0.560718,-0.763644,-0.688882},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.202927,1.206879,0.202927},2,{0.662181,-0.00534,-0.726263},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.202927,0.385825,0.202927},2,{0.555378,0.752964,-0.683542},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.128164,1.089395,0.811706},2,{0.833067,-0.021361,0.053402},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.144185,0.555378,0.32041},8,{0.907829,0.277689,0.160205},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.512656,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.384492,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.256328,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.128164,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.606109,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.451244,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.296379,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.141515,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.01335,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.168215,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.32308,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.477945,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.63281,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{0.971911,0.202927,0.192246},2,{0,-0.961231,-0.683542},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{-0.32041,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0.32041,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{0.971911,0.202927,0.192246},2,{0,0.961231,-0.683542},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{-0.32041,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0.32041,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.170885,0.61946,0.61946},1,{0,1.174838,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.29905,0.29905,0.29905},8,{0,1.377764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.085443,0.491296,0.491296},2,{0,1.55933,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.128164,0.058742,0.128164},8,{0,1.623412,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{-0.234968,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{0,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{0.234968,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={1.986544,2.8,1.809037}},
['Mecha Scrambler Egg']={palette={{29,30,26},{49,50,45},{67,68,63},{36,37,32},{12,15,10},{64,65,60},{117,120,95},{231,248,70},{10,13,9},{78,78,64}},parts={{'ball','EggShell',{1.687494,2.168109,1.55933},1,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0,-1.013558,0.402319},{-1.0,0,0,0,0.649484,0.760375,0,0.760375,-0.649484},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.219355,-1.013689,0.348515},{-0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,0.678743,-0.567499},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.380117,-1.013961,0.201331},{-0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,0.417765,-0.333695},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{-0.439032,-1.014103,0},{0,-0.788723,0.614749,0,0.614749,0.788723,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.380117,-1.013961,-0.201331},{0.534678,-0.660276,0.527404,0,0.624106,0.78134,-0.845056,-0.417765,0.333695},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.219355,-1.013689,-0.348515},{0.88473,-0.357583,0.298977,0,0.641438,0.767175,-0.466104,-0.678743,0.567499},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0,-1.013558,-0.402319},{1.0,0,0,0,0.649484,0.760375,0,-0.760375,0.649484},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.219355,-1.013689,-0.348515},{0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,-0.678743,0.567499},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.380117,-1.013961,-0.201331},{0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,-0.417765,0.333695},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.439032,-1.014103,0},{0,0.788723,-0.614749,0,0.614749,0.788723,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.380117,-1.013961,0.201331},{-0.534678,0.660276,-0.527404,0,0.624106,0.78134,0.845056,0.417765,-0.333695},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.219355,-1.013689,0.348515},{-0.88473,0.357583,-0.298977,0,0.641438,0.767175,0.466104,0.678743,-0.567499},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.185272,-0.669869,0.633764},{-0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,0.417469,-0.877103},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.506524,-0.670128,0.464334},{-0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,0.327394,-0.66217},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.692455,-0.670412,0.170113},{-0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,0.129041,-0.250459},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.692455,-0.670412,-0.170113},{0.281747,-0.439447,0.852939,0,0.888951,0.458002,-0.959489,-0.129041,0.250459},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.506524,-0.670128,-0.464334},{0.738685,-0.298747,0.60423,0,0.896417,0.443211,-0.67405,-0.327394,0.66217},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.185272,-0.669869,-0.633764},{0.971386,-0.102073,0.214455,0,0.90294,0.429767,-0.237507,-0.417469,0.877103},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.185272,-0.669869,-0.633764},{0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,-0.417469,0.877103},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.506524,-0.670128,-0.464334},{0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,-0.327394,0.66217},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.692455,-0.670412,-0.170113},{0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,-0.129041,0.250459},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.692455,-0.670412,0.170113},{-0.281747,0.439447,-0.852939,0,0.888951,0.458002,0.959489,0.129041,-0.250459},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.506524,-0.670128,0.464334},{-0.738685,0.298747,-0.60423,0,0.896417,0.443211,0.67405,0.327394,-0.66217},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.185272,-0.669869,0.633764},{-0.971386,0.102073,-0.214455,0,0.90294,0.429767,0.237507,0.417469,-0.877103},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0,-0.202574,0.78691},{-1.0,0,0,0,0.992972,0.118346,0,0.118346,-0.992972},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.429618,-0.202623,0.681836},{-0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,0.106933,-0.878244},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.74483,-0.20273,0.394107},{-0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,0.067598,-0.530387},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.860509,-0.202789,0},{0,-0.129513,0.991578,0,0.991578,0.129513,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.74483,-0.20273,-0.394107},{0.534678,-0.106838,0.838275,0,0.991976,0.126427,-0.845056,-0.067598,0.530387},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.429618,-0.202623,-0.681836},{0.88473,-0.056336,0.462687,0,0.992669,0.120865,-0.466104,-0.106933,0.878244},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0,-0.202574,-0.78691},{1.0,0,0,0,0.992972,0.118346,0,-0.118346,0.992972},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.429618,-0.202623,-0.681836},{0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,-0.106933,0.878244},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.74483,-0.20273,-0.394107},{0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,-0.067598,0.530387},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.860509,-0.202789,0},{0,0.129513,-0.991578,0,0.991578,0.129513,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.74483,-0.20273,0.394107},{-0.534678,0.106838,-0.838275,0,0.991976,0.126427,0.845056,0.067598,-0.530387},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.429618,-0.202623,0.681836},{-0.88473,0.056336,-0.462687,0,0.992669,0.120865,0.466104,0.106933,-0.878244},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.218099,0.301987,0.74581},{-0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,-0.174062,-0.955663},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.596317,0.302116,0.546474},{-0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,-0.137325,-0.725809},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.815289,0.302261,0.20023},{-0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,-0.0545,-0.276426},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.815289,0.302261,-0.20023},{0.281747,0.185598,0.941367,0,0.981113,-0.193434,-0.959489,0.0545,0.276426},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.596317,0.302116,-0.546474},{0.738685,0.125309,0.6623,0,0.982568,-0.185904,-0.67405,0.137325,0.725809},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{-0.218099,0.301987,-0.74581},{0.971386,0.042559,0.233663,0,0.983815,-0.17919,-0.237507,0.174062,0.955663},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.218099,0.301987,-0.74581},{0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,0.174062,0.955663},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.596317,0.302116,-0.546474},{0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,0.137325,0.725809},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.815289,0.302261,-0.20023},{0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,0.0545,0.276426},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.815289,0.302261,0.20023},{-0.281747,-0.185598,-0.941367,0,0.981113,-0.193434,0.959489,-0.0545,-0.276426},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.596317,0.302116,0.546474},{-0.738685,-0.125309,-0.6623,0,0.982568,-0.185904,0.67405,-0.137325,-0.725809},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.218099,0.301987,0.74581},{-0.971386,-0.042559,-0.233663,0,0.983815,-0.17919,0.237507,-0.174062,-0.955663},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0,0.750925,0.61398},{-1.0,0,0,0,0.869835,-0.493343,0,-0.493343,-0.869835},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.335018,0.751079,0.531957},{-0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,-0.443552,-0.765512},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.58073,0.75141,0.307418},{-0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,-0.277273,-0.457165},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{-0.670857,0.751589,0},{0,0.527893,0.849311,0,0.849311,-0.527893,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.58073,0.75141,-0.307418},{0.534678,0.438229,0.722548,0,0.855029,-0.51858,-0.845056,0.277273,0.457165},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{-0.335018,0.751079,-0.531957},{0.88473,0.233677,0.403296,0,0.865249,-0.501342,-0.466104,0.443552,0.765512},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0,0.750925,-0.61398},{1.0,0,0,0,0.869835,-0.493343,0,0.493343,0.869835},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.335018,0.751079,-0.531957},{0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,0.443552,0.765512},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},2,{0.58073,0.75141,-0.307418},{0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,0.277273,0.457165},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.670857,0.751589,0},{0,-0.527893,-0.849311,0,0.849311,-0.527893,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},3,{0.58073,0.75141,0.307418},{-0.534678,-0.438229,-0.722548,0,0.855029,-0.51858,0.845056,-0.277273,-0.457165},'metal',0,0},{'box','ArmorPlate',{0.32041,0.29905,0.096123},4,{0.335018,0.751079,0.531957},{-0.88473,-0.233677,-0.403296,0,0.865249,-0.501342,0.466104,-0.443552,-0.765512},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.106633,1.033602,0.365064},{-0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,-0.765117,-0.598487},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.291436,1.033817,0.267365},{-0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,-0.590095,-0.444347},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.398265,1.034042,0.097908},{-0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,-0.228363,-0.16502},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.398265,1.034042,-0.097908},{0.281747,0.777689,0.561977,0,0.585704,-0.810525,-0.959489,0.228363,0.16502},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{-0.291436,1.033817,-0.267365},{0.738685,0.538461,0.405467,0,0.601538,-0.798844,-0.67405,0.590095,0.444347},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{-0.106633,1.033602,-0.365064},{0.971386,0.187074,0.146332,0,0.616117,-0.787655,-0.237507,0.765117,0.598487},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0.106633,1.033602,-0.365064},{0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,0.765117,0.598487},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.291436,1.033817,-0.267365},{0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,0.590095,0.444347},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.398265,1.034042,-0.097908},{0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,0.228363,0.16502},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},4,{0.398265,1.034042,0.097908},{-0.281747,-0.777689,-0.561977,0,0.585704,-0.810525,0.959489,-0.228363,-0.16502},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},3,{0.291436,1.033817,0.267365},{-0.738685,-0.538461,-0.405467,0,0.601538,-0.798844,0.67405,-0.590095,-0.444347},'metal',0,0},{'box','ArmorPlate',{0.245648,0.29905,0.096123},2,{0.106633,1.033602,0.365064},{-0.971386,-0.187074,-0.146332,0,0.616117,-0.787655,0.237507,-0.765117,-0.598487},'metal',0,0},{'box','CoilRecess',{0.811706,1.591371,0.128164},5,{0,-0.021361,-0.811706},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.377758,0.202927},2,{-0.560718,-0.763644,-0.688882},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.202927,1.206879,0.202927},2,{-0.662181,-0.00534,-0.726263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.385825,0.202927},2,{-0.555378,0.752964,-0.683542},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,-0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,-0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{-0.640821,0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{-0.640821,0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.128164,1.089395,0.811706},2,{-0.833067,-0.021361,0.053402},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.144185,0.555378,0.32041},8,{-0.907829,0.277689,0.160205},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.512656,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.384492,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.256328,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{-0.907829,-0.128164,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.377758,0.202927},2,{0.560718,-0.763644,-0.688882},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.202927,1.206879,0.202927},2,{0.662181,-0.00534,-0.726263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.202927,0.385825,0.202927},2,{0.555378,0.752964,-0.683542},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,-0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,-0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.138844,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.138844,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.416533,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.416533,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.288369,0.138844,0.234968},6,{0.640821,0.694222,-0.779665},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.029905,0.074762,0.074762},7,{0.640821,0.694222,-0.913169},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.128164,1.089395,0.811706},2,{0.833067,-0.021361,0.053402},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.144185,0.555378,0.32041},8,{0.907829,0.277689,0.160205},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.512656,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.384492,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.256328,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.170885,0.058742,0.331091},9,{0.907829,-0.128164,-0.192246},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.606109,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.451244,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.296379,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,0.141515,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.01335,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.168215,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.32308,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.477945,-0.92919},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.048062,0.494795,0.048062},8,{0,-0.63281,-0.92919},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{0.971911,0.202927,0.192246},2,{0,-0.961231,-0.683542},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{-0.32041,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0.32041,-0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{0.971911,0.202927,0.192246},2,{0,0.961231,-0.683542},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{-0.32041,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.026701,0.061946,0.061946},10,{0.32041,0.961231,-0.801026},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.170885,0.61946,0.61946},1,{0,1.174838,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.29905,0.29905,0.29905},8,{0,1.377764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.085443,0.491296,0.491296},2,{0,1.55933,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.128164,0.058742,0.128164},8,{0,1.623412,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{-0.234968,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{0,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.117484,0.106803,0.042721},8,{0.234968,-1.073374,-0.587419},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={1.986544,2.8,1.809037}},
}

local EGG_MATERIALS={
    plastic=Enum.Material.SmoothPlastic,metal=Enum.Material.Metal,
    wood=Enum.Material.Wood,slate=Enum.Material.Slate,
    sandstone=Enum.Material.Sandstone,concrete=Enum.Material.Concrete,
    glass=Enum.Material.Glass,neon=Enum.Material.Neon,
}

local function buildSculptedEgg(name)
    local design=EGG_DESIGNS[name]
    if not design then return nil end
    local m=Instance.new('Model')
    m.Name=name
    local root=part(m,'Core',Vector3.new(.025,.025,.025),rgb(255,255,255),CFrame.new(),MAT,1)
    m.PrimaryPart=root
    for i,item in ipairs(design.parts) do
        -- kind, semantic name, size, palette index, position, orientation,
        -- material, transparency, reflectance. No textures or image surfaces.
        local size,color,pos,r=item[3],design.palette[item[4]],item[5],item[6]
        local cf=CFrame.new(pos[1],pos[2],pos[3],
            r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9])
        local material=EGG_MATERIALS[item[7]] or MAT
        local s=Vector3.new(size[1],size[2],size[3])
        local c=rgb(color[1],color[2],color[3])
        local p
        if item[1]=='corner' then
            p=Instance.new('CornerWedgePart')
            p.Name=item[2] p.Size=s p.Color=c p.CFrame=cf
            p.Material=material p.Transparency=item[8] or 0
            p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false
            p.Massless=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
            p.Parent=m
        elseif item[1]=='wedge' then
            p=wedge(m,item[2],s,c,cf,material,item[8])
        elseif item[1]=='ball' then
            p=ball(m,item[2],s,c,cf,material,item[8])
        elseif item[1]=='cylinder' then
            p=cyl(m,item[2],s,c,cf,material,item[8])
        else
            p=part(m,item[2],s,c,cf,material,item[8])
        end
        p.Reflectance=item[9] or 0
        p.CastShadow=material~=NEON
        if i%40==0 then task.wait() end
    end
    m:SetAttribute('SAE_REFERENCE_DETAIL','Sculpted3D')
    m:SetAttribute('SAE_APPEARANCE','Native 3D features; no image projection')
    return finalize(m,root)
end

local function nightPet()local m=Instance.new('Model')m.Name='Night Flame'local body,dark,blue,glow=rgb(36,41,54),rgb(23,27,38),rgb(35,92,170),rgb(185,255,248)local r=ball(m,'Torso',Vector3.new(4.6,6.1,3.2),body,CFrame.new(),Enum.Material.Slate)ball(m,'Head',Vector3.new(3,2.8,2.7),dark,CFrame.new(0,3.85,-.25),Enum.Material.Slate)wedge(m,'HornL',Vector3.new(.8,2,.7),blue,CFrame.new(-.95,5.35,-.1),METAL)wedge(m,'HornR',Vector3.new(.8,2,.7),blue,CFrame.new(.95,5.35,-.1)*CFrame.Angles(0,math.rad(180),0),METAL)eye(m,-.55,4.15,-1.55,glow,Vector3.new(.42,.28,.18))eye(m,.55,4.15,-1.55,glow,Vector3.new(.42,.28,.18))for ai,y in ipairs({1.7,.2,-1.3})do local spread=3.05+(ai-1)*.15 for _,sx in ipairs({-1,1})do part(m,'Arm',Vector3.new(3.4,.9,.95),body,CFrame.new(sx*spread,y,-.05)*CFrame.Angles(0,0,math.rad(sx*(ai==2 and 8 or(ai==1 and-16 or 18)))),Enum.Material.Slate)ball(m,'Hand',Vector3.new(1.15,1.25,1),dark,CFrame.new(sx*(spread+1.75),y,-.1),Enum.Material.Slate)end end for _,sx in ipairs({-1,1})do part(m,'Leg',Vector3.new(1.45,3.5,1.5),body,CFrame.new(sx*1.25,-4.2,0),Enum.Material.Slate)ball(m,'Foot',Vector3.new(1.8,.9,2.2),dark,CFrame.new(sx*1.25,-6,-.45),Enum.Material.Slate)end part(m,'ChestV',Vector3.new(.34,2.7,.22),glow,CFrame.new(0,.55,-1.72),NEON)for _,sx in ipairs({-1,1})do part(m,'ChestBranch',Vector3.new(.25,1.7,.2),glow,CFrame.new(sx*.6,1.05,-1.72)*CFrame.Angles(0,0,math.rad(sx*40)),NEON)end return finalize(m,r)end
local function luminousPet()local m=Instance.new('Model')m.Name='Luminous Cthulhu'local body,dark,ice,cyan=rgb(20,43,91),rgb(17,31,72),rgb(194,242,255),rgb(81,217,255)local r=ball(m,'Torso',Vector3.new(5.4,6.2,3.6),body,CFrame.new(),Enum.Material.Slate)ball(m,'Head',Vector3.new(3.6,3.2,3.1),dark,CFrame.new(0,3.7,-.25),Enum.Material.Slate)eye(m,-.55,4.05,-1.65,ice,Vector3.new(.48,.3,.18))eye(m,.55,4.05,-1.65,ice,Vector3.new(.48,.3,.18))for i=-2,2 do tentacle(m,i*.5,2.65,-1.4,body,2.6,-90+i*10,Enum.Material.Slate)end for _,sx in ipairs({-1,1})do wing(m,sx,dark,ice,1.65,.7,.6)part(m,'UpperArm',Vector3.new(1.65,4,1.65),body,CFrame.new(sx*3.05,-.15,0),Enum.Material.Slate)ball(m,'Fist',Vector3.new(2,2,1.85),ice,CFrame.new(sx*3.5,-2.25,-.25),Enum.Material.Ice)part(m,'Leg',Vector3.new(1.75,3.7,1.8),body,CFrame.new(sx*1.45,-4.25,0),Enum.Material.Slate)ball(m,'Foot',Vector3.new(2,1,2.25),ice,CFrame.new(sx*1.45,-6.1,-.45),Enum.Material.Ice)end for _,p in ipairs({{-2.25,1.3,-1},{2.25,1.3,-1},{-2.7,-1.2,-.9},{2.7,-1.2,-.9}})do for j=1,3 do wedge(m,'IceCrystal',Vector3.new(.38,.9+.22*j,.38),j==2 and cyan or ice,CFrame.new(p[1]+(j-2)*.32,p[2]+.25*j,p[3]),Enum.Material.Ice)end end return finalize(m,r)end
local function star()local m=Instance.new('Model')m.Name='Star'local gold,edge,dark=rgb(255,208,22),rgb(239,165,10),rgb(25,20,18)local r=ball(m,'Center',Vector3.new(4.5,4.5,1.25),gold,CFrame.new(),MAT)for i=0,4 do local a=math.rad(-90+i*72)local x,y=math.cos(a)*3.25,math.sin(a)*3.25 wedge(m,'Point',Vector3.new(2.75,4.7,1.15),gold,CFrame.new(x,y,0)*CFrame.Angles(0,0,a+math.rad(90)),MAT)wedge(m,'BackEdge',Vector3.new(2.55,4.4,.3),edge,CFrame.new(x,y,.68)*CFrame.Angles(0,0,a+math.rad(90)),MAT)end for _,s in ipairs({{-1.25,1.45},{0,1.65},{1.15,1.15},{-2,.55},{-.8,.55},{.45,.6},{1.8,.45},{-1.55,-.65},{-.35,-.5},{.9,-.55},{1.65,-.95},{-.95,-1.65},{.25,-1.6}})do part(m,'Stud',Vector3.new(.52,.52,.22),rgb(255,221,43),CFrame.new(s[1],s[2],-.72),MAT)end eye(m,-.9,.15,-.78,dark,Vector3.new(.82,1.05,.3))eye(m,.9,.15,-.78,dark,Vector3.new(.82,1.05,.3))ball(m,'BlushL',Vector3.new(.65,.32,.14),rgb(255,133,97),CFrame.new(-1.75,-.55,-.83),NEON)ball(m,'BlushR',Vector3.new(.65,.32,.14),rgb(255,133,97),CFrame.new(1.75,-.55,-.83),NEON)return finalize(m,r)end

local function refEgg(name) return function() return buildSculptedEgg(name) end end
local Built={['Unicorn Egg']=refEgg('Unicorn Egg'),['Kitsune Egg']=refEgg('Kitsune Egg'),['Night Flame Egg']=refEgg('Night Flame Egg'),['Archangel Egg']=refEgg('Archangel Egg'),['World Burner Egg']=refEgg('World Burner Egg'),['Aetheron Egg']=refEgg('Aetheron Egg'),['Cthulhu Egg']=refEgg('Cthulhu Egg'),['Luminous Cthulhu Egg']=refEgg('Luminous Cthulhu Egg'),['Sabertooth Egg']=refEgg('Sabertooth Egg'),['Skeletal Sabertooth Egg']=refEgg('Skeletal Sabertooth Egg'),['Octophant Egg']=refEgg('Octophant Egg'),['Mecha Scrambler Egg']=refEgg('Mecha Scrambler Egg'),['Night Flame']=nightPet,['Luminous Cthulhu']=luminousPet,['Star']=star}

local cache={}
local function badPet(o)local x=o while x and x~=workspace and x~=RS do if norm(x.Name):find('egg',1,true)then return true end x=x.Parent end return false end
local function hit(o,want)if want[norm(o.Name)]then return 1000 end local n=norm(o.Name)for a in pairs(want)do if #a>=5 and n:find(a,1,true)then return 420 end end for _,k in ipairs({'ItemName','DisplayName','PetName','EggName','Title','Type'})do local ok,v=pcall(function()return o:GetAttribute(k)end)if ok and v and want[norm(v)]then return 850 end end return 0 end
local function source(cat,name)local key=cat..'|'..name if cache[key]and cache[key].Parent then return cache[key]end local want={}for _,a in ipairs(Aliases[name]or{name})do want[norm(a)]=true end local best,bs=nil,-1 local function scan(o,bonus)if not(o:IsA('Model')or o:IsA('Tool'))then return end if P.Character and o:IsDescendantOf(P.Character)then return end if o:IsDescendantOf(Placed)then return end if cat=='Pets'and badPet(o)then return end local h=hit(o,want)if h<=0 then return end local count=0 for _,d in ipairs(o:GetDescendants())do if d:IsA('BasePart')then count+=1 end end if count<1 then return end local sc=h+bonus+math.min(count,100)if sc>bs then best,bs=o,sc end end for _,r in ipairs({{RS,220},{workspace,80}})do local list=r[1]:GetDescendants()for i,o in ipairs(list)do scan(o,r[2])if i%1500==0 then task.wait()end end end if type(getnilinstances)=='function'then local ok,list=pcall(getnilinstances)if ok then for i,o in ipairs(list)do if typeof(o)=='Instance'then scan(o,120)end if i%1500==0 then task.wait()end end end end cache[key]=best return best end
local function clone(src,name)if not src then return nil end local ok,c=pcall(function()return src:Clone()end)if not ok or not c then return nil end local m=c if c:IsA('Tool')then m=Instance.new('Model')m.Name=name for _,q in ipairs(c:GetChildren())do if not(q:IsA('Script')or q:IsA('LocalScript')or q:IsA('ModuleScript'))then q.Parent=m end end c:Destroy()end if not m:IsA('Model')then return nil end local kill={}for _,d in ipairs(m:GetDescendants())do if d:IsA('Script')or d:IsA('LocalScript')or d:IsA('ModuleScript')or d:IsA('Humanoid')or d:IsA('Animator')or d:IsA('ProximityPrompt')or d:IsA('ClickDetector')or d:IsA('SurfaceGui')or d:IsA('BillboardGui')then kill[#kill+1]=d end end for _,d in ipairs(kill)do d:Destroy()end if not m:FindFirstChildWhichIsA('BasePart',true)then m:Destroy()return nil end m.Name=name return m end
local function fit(m,target)local ok,s=pcall(function()return m:GetExtentsSize()end)if ok then local mx=math.max(s.X,s.Y,s.Z)if mx>.01 then pcall(function()m:ScaleTo(target/mx)end)end end end
local function model(cat,name)if cat=='Eggs' and EGG_DESIGNS[name] then local m=buildSculptedEgg(name) if m then return m,false end end local src=source(cat,name)if src then local m=clone(src,name)if m then fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,true end end local f=Built[name]if f then local m=f()fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,false end return nil,false end
local function weld(t,m,off)m.Parent=t m:PivotTo(t.Handle.CFrame*off)if m:GetAttribute('SAE_REFERENCE_DETAIL') and m.PrimaryPart then local w=Instance.new('WeldConstraint')w.Part0=t.Handle w.Part1=m.PrimaryPart w.Parent=t.Handle else for _,p in ipairs(allParts(m))do p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true local w=Instance.new('WeldConstraint')w.Part0=t.Handle w.Part1=p w.Parent=t.Handle end end end
local function place(t,m)local c=m:Clone()for _,d in ipairs(c:GetDescendants())do if d:IsA('WeldConstraint')or d:IsA('Motor6D')then d:Destroy()end end c.Parent=Placed for _,p in ipairs(allParts(c))do p.Anchored=true p.CanCollide=false p.CanQuery=true end local mouse=P:GetMouse()local pos=mouse and mouse.Hit and mouse.Hit.Position local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')pos=pos or(hrp and(hrp.Position+hrp.CFrame.LookVector*9))or Vector3.zero local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={P.Character,Placed}local ray=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rp)if ray then pos=ray.Position end c:PivotTo(CFrame.new(pos))local cf,sz=c:GetBoundingBox()c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))t:Destroy()end
local function spawnTool(cat,name)local m,exact=model(cat,name)if not m then return false,'No 3D model available'end local t=Instance.new('Tool')t.Name=name t.RequiresHandle=true t.CanBeDropped=false t:SetAttribute('SAE_V7_TOOL',true)t:SetAttribute('SAE_ID',Http:GenerateGUID(false))local h=part(t,'Handle',Vector3.new(.45,.45,.45),Color3.new(),CFrame.new(),MAT,1)h.CanQuery=false if cat=='Eggs'then t.Grip=CFrame.new(0,-.1,-.25)*CFrame.Angles(math.rad(-12),math.rad(180),0)weld(t,m,CFrame.new(0,.45,-.75)*CFrame.Angles(0,math.rad(180),0))elseif cat=='Star'then t.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)weld(t,m,CFrame.new(0,.5,-1.55)*CFrame.Angles(0,math.rad(180),0))else weld(t,m,CFrame.new(0,2,-4.4))t.Activated:Connect(function()if t.Parent==P.Character then place(t,m)end end)end t.Parent=BP return true,(cat=='Eggs' and '3D reference model') or (exact and 'Exact loaded 3D model' or 'True 3D reference build')end

local C={bg=rgb(8,8,14),head=rgb(15,11,23),card=rgb(24,18,34),card2=rgb(37,25,50),border=rgb(84,57,110),p=rgb(142,51,236),p2=rgb(184,83,255),w=Color3.new(1,1,1),m=rgb(168,162,181),g=rgb(105,245,135),o=rgb(255,188,82),r=rgb(255,90,90)}
local function corner(o,r)local x=Instance.new('UICorner')x.CornerRadius=UDim.new(0,r or 8)x.Parent=o end
local function stroke(o,a)local x=Instance.new('UIStroke')x.Color=C.border x.Transparency=a or .35 x.Parent=o end
local function label(p,t,pos,size,z,col)local x=Instance.new('TextLabel')x.BackgroundTransparency=1 x.Position=pos x.Size=size x.Text=t x.TextColor3=col or C.w x.Font=Enum.Font.GothamMedium x.TextSize=z or 11 x.TextXAlignment=Enum.TextXAlignment.Left x.Parent=p return x end
local function button(p,t,pos,size)local x=Instance.new('TextButton')x.Position=pos x.Size=size x.BackgroundColor3=C.p x.BorderSizePixel=0 x.Text=t x.TextColor3=C.w x.Font=Enum.Font.GothamBold x.TextSize=11 x.Parent=p corner(x,8)return x end
local gui=Instance.new('ScreenGui')gui.Name='SAE_ITEMS_V7'gui.ResetOnSpawn=false gui.DisplayOrder=730 gui.Parent=PG
local launcher=button(gui,'ITEMS',UDim2.new(0,12,.5,-20),UDim2.fromOffset(74,38))
local win=Instance.new('Frame')win.Size=UDim2.fromOffset(560,470)win.Position=UDim2.new(.5,-280,.5,-235)win.BackgroundColor3=C.bg win.BorderSizePixel=0 win.Visible=false win.Parent=gui corner(win,13)stroke(win,.1)
local head=Instance.new('Frame')head.Size=UDim2.new(1,0,0,62)head.BackgroundColor3=C.head head.BorderSizePixel=0 head.Parent=win corner(head,13)
local title=label(head,'DIVINE ITEM SPAWNER · SCULPTED EGGS',UDim2.fromOffset(16,8),UDim2.new(1,-70,0,24),15)title.Font=Enum.Font.GothamBold
label(head,'Solid 3D details • hand-sized eggs',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
local close=button(head,'X',UDim2.new(1,-43,0,13),UDim2.fromOffset(28,28))close.BackgroundColor3=C.card2
launcher.MouseButton1Click:Connect(function()win.Visible=not win.Visible end)close.MouseButton1Click:Connect(function()win.Visible=false end)
local dragging=false local dragStart local startPos
head.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=win.Position end end)
UIS.InputChanged:Connect(function(i)if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)end end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
local tabs=Instance.new('Frame')tabs.BackgroundTransparency=1 tabs.Position=UDim2.fromOffset(14,72)tabs.Size=UDim2.new(1,-28,0,38)tabs.Parent=win
local content=Instance.new('ScrollingFrame')content.Position=UDim2.fromOffset(14,118)content.Size=UDim2.new(1,-28,1,-190)content.BackgroundColor3=C.card content.BorderSizePixel=0 content.ScrollBarThickness=5 content.CanvasSize=UDim2.fromOffset(0,0)content.Parent=win corner(content,10)stroke(content,.5)
local grid=Instance.new('UIGridLayout')grid.CellSize=UDim2.new(.5,-9,0,42)grid.CellPadding=UDim2.fromOffset(8,8)grid.SortOrder=Enum.SortOrder.LayoutOrder grid.Parent=content
local pad=Instance.new('UIPadding')pad.PaddingTop=UDim.new(0,8)pad.PaddingLeft=UDim.new(0,8)pad.PaddingRight=UDim.new(0,8)pad.Parent=content
grid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()content.CanvasSize=UDim2.fromOffset(0,grid.AbsoluteContentSize.Y+16)end)
local status=label(win,'Select an item',UDim2.new(0,16,1,-61),UDim2.new(1,-32,0,18),10,C.m)
local cat,sel='Eggs',nil local tabButtons={}
local function paint()for n,b in pairs(tabButtons)do b.BackgroundColor3=(n==cat)and C.p or C.card2 end end
local function render()for _,c in ipairs(content:GetChildren())do if c:IsA('TextButton')then c:Destroy()end end local list=cat=='Eggs'and Eggs or cat=='Pets'and Pets or{'Star'}for i,name in ipairs(list)do local b=button(content,name,UDim2.new(),UDim2.new())b.LayoutOrder=i b.BackgroundColor3=(sel==name and C.p2 or C.card2)b.MouseButton1Click:Connect(function()sel=name status.Text='Selected: '..name status.TextColor3=C.w render()end)end end
for i,n in ipairs({'Eggs','Pets','Star'})do local b=button(tabs,n:upper(),UDim2.new((i-1)/3,4,0,0),UDim2.new(1/3,-8,1,0))tabButtons[n]=b b.MouseButton1Click:Connect(function()cat=n sel=nil paint()render()status.Text='Select an item' status.TextColor3=C.m end)end
paint()render()
local spawn=button(win,'SPAWN SELECTED',UDim2.new(1,-176,1,-67),UDim2.fromOffset(160,34))
local spawning = false
spawn.MouseButton1Click:Connect(function()
    if spawning then return end
    if not sel then status.Text='Select an item first' status.TextColor3=C.o return end
    local selectedCat, selectedName = cat, sel
    spawning = true
    spawn.Text = 'BUILDING...'
    status.Text = 'Building '..selectedName..'...'
    status.TextColor3 = C.m
    task.spawn(function()
        local success, ok, msg = pcall(spawnTool, selectedCat, selectedName)
        if not success then msg=ok ok=false end
        spawning = false
        spawn.Text = 'SPAWN SELECTED'
        status.Text = (ok and 'Spawned: ' or 'Failed: ')..selectedName..' • '..tostring(msg)
        status.TextColor3 = ok and C.g or C.r
    end)
end)
RS.DescendantAdded:Connect(function()cache={}end)P.CharacterAdded:Connect(function()task.wait(.5)cache={}end)
print('[SAE] V7 true-3D inventory loaded: no stacked image fallbacks.')

end)