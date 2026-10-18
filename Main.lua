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
['Unicorn Egg']={palette={{244,181,205},{255,229,239},{56,221,229},{211,65,185},{246,79,117},{176,123,237},{255,239,175},{226,187,86}},parts={{'box','EggShell',{0.230685,0.206952,0.538571},1,{-0.115342,-1.138235,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.722569},1,{0.115342,-1.138235,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.538571},1,{0.346028,-1.138235,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.79883},1,{-0.576712,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.251525},1,{-0.346028,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.424925},1,{-0.115342,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.424925},1,{0.115342,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.251525},1,{0.346028,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.79883},1,{0.576712,-0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{-0.576712,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{-0.346028,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{-0.115342,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.685994},1,{0.115342,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{0.346028,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{0.576712,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{0.807397,-0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{-0.576712,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{-0.346028,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{-0.115342,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.685994},1,{0.115342,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{0.346028,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{0.576712,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{0.807397,-0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{-0.576712,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{-0.346028,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{-0.115342,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.685994},1,{0.115342,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{0.346028,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{0.576712,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{0.807397,-0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{-0.576712,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{-0.346028,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{-0.115342,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.685994},1,{0.115342,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.615712},1,{0.346028,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.383614},1,{0.576712,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.868419},1,{0.807397,-0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.79883},1,{-0.346028,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.251525},1,{-0.115342,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.424925},1,{0.115342,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.424925},1,{0.346028,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.251525},1,{0.576712,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.79883},1,{0.807397,0.103476,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.722569},1,{-0.346028,0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.103741},1,{-0.115342,0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.204281},1,{0.115342,0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.103741},1,{0.346028,0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.722569},1,{0.576712,0.310428,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.722569},1,{-0.576712,0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.103741},1,{-0.346028,0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.204281},1,{-0.115342,0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,1.103741},1,{0.115342,0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.722569},1,{0.346028,0.51738,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.417175},1,{-0.576712,0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.417175},1,{-0.346028,0.724331,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.417175},1,{-0.807397,0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.417175},1,{-0.576712,0.931284,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.230685,0.206952,0.264941},1,{-0.807397,1.138235,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','PearlVein',{0.015949,0.367777,0.015949},2,{-0.49842,-0.565495,0.440385},{0.988562,-0.150812,-0.000256,0.150812,0.988561,0.001676,0,-0.001695,0.999999},'plastic',0,0},{'box','PearlVein',{0.015949,0.523416,0.015949},2,{-0.392476,-0.159361,0.423054},{0.859064,0.510785,0.033286,-0.511868,0.857246,0.055864,0,-0.065029,0.997883},'plastic',0,0},{'box','PearlVein',{0.015949,0.517193,0.015949},2,{-0.375694,0.294878,0.387124},{0.891387,-0.452029,-0.033146,0.453243,0.889,0.065188,0,-0.073131,0.997322},'plastic',0,0},{'box','PearlVein',{0.015949,0.366294,0.015949},2,{-0.556512,-0.565495,-0.439529},{0.992568,0.121689,0.000283,-0.121689,0.992566,0.00231,0,-0.002327,0.999997},'plastic',0,0},{'box','PearlVein',{0.015949,0.477904,0.015949},2,{-0.453952,-0.159361,-0.422004},{0.941544,0.335938,-0.02531,-0.33689,0.938883,-0.070736,0,0.075128,0.997174},'plastic',0,0},{'box','PearlVein',{0.015949,0.530948,0.015949},2,{-0.505011,0.294878,-0.384611},{0.8683,-0.494707,0.036324,0.496039,0.865969,-0.063584,0,0.073228,0.997315},'plastic',0,0},{'box','PearlVein',{0.015949,0.375105,0.015949},2,{0.161496,-0.565495,-0.85096},{0.969249,0.246083,-1.4e-05,-0.246083,0.969249,-5.5e-05,0,5.6e-05,1.0},'plastic',0,0},{'box','PearlVein',{0.015949,0.4673,0.015949},2,{0.208939,-0.159361,-0.785692},{0.999983,0.00552,-0.001606,-0.005749,0.960189,-0.279291,0,0.279295,0.960205},'plastic',0,0},{'box','PearlVein',{0.015949,0.61121,0.015949},2,{0.016579,0.294878,-0.665266},{0.764817,-0.633663,0.116303,0.644247,0.752252,-0.138069,0,0.180525,0.98357},'plastic',0,0},{'box','PearlVein',{0.015949,0.365199,0.015949},2,{0.826701,-0.565495,-0.43856},{0.995545,0.094286,-0.00028,-0.094287,0.995541,-0.00296,0,0.002974,0.999996},'plastic',0,0},{'box','PearlVein',{0.015949,0.450717,0.015949},2,{0.830707,-0.159361,-0.421283},{0.998271,-0.058614,0.004364,0.058777,0.995515,-0.074127,0,0.074255,0.997239},'plastic',0,0},{'box','PearlVein',{0.015949,0.654968,0.015949},2,{0.585029,0.294878,-0.385765},{0.703153,-0.709868,0.040785,0.711039,0.701995,-0.040333,0,0.05736,0.998354},'plastic',0,0},{'box','PearlVein',{0.015949,0.450414,0.015949},2,{0.669393,-0.565495,0.569729},{0.984876,-0.142004,0.099271,0.173263,0.807192,-0.564288,0,0.572953,0.819588},'plastic',0,0},{'box','PearlVein',{0.015949,0.546915,0.015949},2,{0.692039,-0.159361,0.55226},{0.971613,0.199761,0.126744,-0.236577,0.820412,0.520534,0,-0.535742,0.844382},'plastic',0,0},{'box','PearlVein',{0.015949,0.613733,0.015949},2,{0.544316,0.294878,0.386476},{0.750643,-0.659403,-0.041514,0.660708,0.74916,0.047165,0,-0.062833,0.998024},'plastic',0,0},{'box','CrystalPrism',{0.330364,0.466496,0.318971},3,{-0.512633,0.974686,0.034175},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.165181,0.260618,0.165181},3,{-0.577423,1.330006,0.116766},{0.991365,0.131133,0,-0.131133,0.991365,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.260618,0.165181},3,{-0.413668,1.308345,0.116766},{0,0.131133,0.991365,0,0.991365,-0.131133,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.260618,0.165181},3,{-0.413668,1.308345,-0.048415},{-0.991365,0.131133,0,0.131133,0.991365,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.260618,0.165181},3,{-0.577423,1.330006,-0.048415},{0,0.131133,-0.991365,0,0.991365,0.131133,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.330364,0.636804,0.318971},4,{0.148094,1.085871,0.113919},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.165181,0.354344,0.165181},4,{0.082976,1.564093,0.196509},{0.995338,0.096447,0,-0.096447,0.995338,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.354344,0.165181},4,{0.247388,1.54816,0.196509},{0,0.096447,0.995338,0,0.995338,-0.096447,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.354344,0.165181},4,{0.247388,1.54816,0.031328},{-0.995338,0.096447,0,0.096447,0.995338,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.354344,0.165181},4,{0.082976,1.564093,0.031328},{0,0.096447,-0.995338,0,0.995338,0.096447,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.330364,0.50352,0.318971},5,{0.512633,0.958737,0.056959},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.165181,0.280959,0.165181},5,{0.447744,1.340614,0.13955},{0.992574,0.121639,0,-0.121639,0.992574,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.280959,0.165181},5,{0.611699,1.320521,0.13955},{0,0.121639,0.992574,0,0.992574,-0.121639,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.280959,0.165181},5,{0.611699,1.320521,-0.025631},{-0.992574,0.121639,0,0.121639,0.992574,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.280959,0.165181},5,{0.447744,1.340614,-0.025631},{0,0.121639,-0.992574,0,0.992574,0.121639,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.330364,0.37764,0.318971},6,{-0.034175,0.889931,-0.43289},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.165181,0.211927,0.165181},6,{-0.098598,1.182122,-0.350299},{0.986912,0.16126,0,-0.16126,0.986912,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.211927,0.165181},6,{0.064422,1.155485,-0.350299},{0,0.16126,0.986912,0,0.986912,-0.16126,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.211927,0.165181},6,{0.064422,1.155485,-0.515481},{-0.986912,0.16126,0,0.16126,0.986912,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.165181,0.211927,0.165181},6,{-0.098598,1.182122,-0.515481},{0,0.16126,-0.986912,0,0.986912,0.16126,1.0,0,0},'glass',0,0},{'box','IvoryHorn',{0.227837,0.419027,0.227837},7,{-0.467066,1.082225,-0.301884},{0.924678,-0.380609,0.010351,0.38075,0.924336,-0.025139,0,0.027186,0.99963},'plastic',0,0},{'box','IvoryHorn',{0.165181,0.415451,0.165181},7,{-0.632247,1.463853,-0.273404},{0.910366,-0.411306,0.045387,0.413803,0.904874,-0.099851,0,0.109682,0.993967},'plastic',0,0},{'box','IvoryHorn',{0.102526,0.406611,0.102526},7,{-0.791734,1.839784,-0.227837},{0.930408,-0.364216,0.041075,0.366525,0.924547,-0.104267,0,0.112066,0.993701},'plastic',0,0},{'corner','HornTip',{0.051264,0.63335,0.051264},7,{-0.859773,1.929566,-0.185321},{0.924678,-0.37772,0.047939,0.38075,0.91732,-0.116423,0,0.125907,0.992042},'plastic',0,0},{'corner','HornTip',{0.051264,0.63335,0.051264},7,{-0.812371,1.949085,-0.185321},{-0.047939,-0.37772,0.924678,0.116423,0.91732,0.38075,-0.992042,0.125907,0},'plastic',0,0},{'corner','HornTip',{0.051264,0.63335,0.051264},7,{-0.814829,1.955054,-0.236176},{-0.924678,-0.37772,-0.047939,-0.38075,0.91732,0.116423,0,0.125907,-0.992042},'plastic',0,0},{'corner','HornTip',{0.051264,0.63335,0.051264},7,{-0.86223,1.935535,-0.236176},{0.047939,-0.37772,-0.924678,-0.116423,0.91732,-0.38075,0.992042,0.125907,0},'plastic',0,0},{'box','HornSpiral',{0.262012,0.051264,0.227837},8,{-0.387323,0.888564,-0.30758},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.222141,0.051264,0.197079},8,{-0.506938,1.17336,-0.281949},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.18227,0.051264,0.166321},8,{-0.626551,1.458156,-0.256316},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.142398,0.051264,0.135563},8,{-0.746166,1.742953,-0.230685},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0}},bounds={1.929514,3.5,1.701942}},
['Kitsune Egg']={palette={{194,186,154},{135,126,94},{222,48,196},{27,28,35},{240,74,216},{223,48,194},{255,235,246}},parts={{'box','EggShell',{0.227969,0.281209,0.690746},1,{-0.683906,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.08219},1,{-0.455937,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.232129},1,{-0.227969,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.232129},1,{0,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.08219},1,{0.227969,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.690746},1,{0.455937,-1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.907817},1,{-1.139844,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.487329},1,{-0.911875,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.803651},1,{-0.683906,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.986748},1,{-0.455937,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.072237},1,{-0.227969,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.072237},1,{0,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.986748},1,{0.227969,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.803651},1,{0.455937,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.487329},1,{0.683906,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.907817},1,{0.911875,-1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-1.139844,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{-0.911875,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{-0.683906,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{-0.455937,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{-0.227969,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.290945},1,{0,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{0.227969,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{0.455937,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{0.683906,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{0.911875,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{1.139844,-0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-1.139844,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{-0.911875,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{-0.683906,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{-0.455937,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{-0.227969,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.290945},1,{0,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{0.227969,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{0.455937,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{0.683906,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{0.911875,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{1.139844,-0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-1.139844,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{-0.911875,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{-0.683906,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{-0.455937,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{-0.227969,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.290945},1,{0,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{0.227969,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{0.455937,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{0.683906,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{0.911875,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{1.139844,-0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-1.139844,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{-0.911875,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{-0.683906,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{-0.455937,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{-0.227969,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.290945},1,{0,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{0.227969,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{0.455937,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{0.683906,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{0.911875,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{1.139844,-0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-1.139844,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{-0.911875,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{-0.683906,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{-0.455937,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{-0.227969,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.290945},1,{0,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.252759},1,{0.227969,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,2.134109},1,{0.455937,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.920133},1,{0.683906,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.572386},1,{0.911875,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{1.139844,0.140604,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.806617},1,{-0.911875,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.300631},1,{-0.683906,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.544555},1,{-0.455937,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.653074},1,{-0.227969,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.653074},1,{0,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.544555},1,{0.227969,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.300631},1,{0.455937,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.806617},1,{0.683906,0.421813,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.75092},1,{-0.683906,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.196406},1,{-0.455937,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.397103},1,{-0.227969,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.457874},1,{0,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.397103},1,{0.227969,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.196406},1,{0.455937,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.75092},1,{0.683906,0.703021,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.690746},1,{-0.683906,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.08219},1,{-0.455937,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.232129},1,{-0.227969,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.232129},1,{0,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.08219},1,{0.227969,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.690746},1,{0.455937,0.984229,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.624803},1,{-0.455937,1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{-0.227969,1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,1.041339},1,{0,1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.954403},1,{0.227969,1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.624803},1,{0.455937,1.265437,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.551025},1,{-0.455937,1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.806617},1,{-0.227969,1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.806617},1,{0,1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.227969,0.281209,0.551025},1,{0.227969,1.546645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.407747,-1.253871,1.037769},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.486388,-1.32198,1.020595},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-1.006155,-1.253871,0.53123},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.061968,-1.32198,0.473229},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-1.218587,-1.253871,-0.384538},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.195891,-1.32198,-0.461765},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.887125,-1.253871,-0.732355},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.81523,-1.32198,-0.768551},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.194477,-1.253871,-1.063981},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.113984,-1.32198,-1.063981},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.515366,-1.253871,-0.804747},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.587261,-1.32198,-0.768551},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.945227,-1.253871,-0.538991},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.967923,-1.32198,-0.461765},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.88981,-1.253871,0.415227},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.833999,-1.32198,0.473229},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.337058,-1.253871,1.003421},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.258419,-1.32198,1.020595},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.33041,-0.577074,1.111449},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.409049,-0.645182,1.094275},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.984961,-0.577074,0.863514},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.040774,-0.645182,0.805513},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-1.21012,-0.577074,-0.40783},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.187425,-0.645182,-0.485058},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.842013,-0.577074,-0.948757},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.770118,-0.645182,-0.984954},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.080493,-0.577074,-1.173335},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0,-0.645182,-1.173335},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.698222,-0.577074,-1.02115},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.770118,-0.645182,-0.984954},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{1.16473,-0.577074,-0.562284},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{1.187425,-0.645182,-0.485058},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{1.096585,-0.577074,0.747511},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{1.040774,-0.645182,0.805513},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.487689,-0.577074,1.077102},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.409049,-0.645182,1.094275},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.33041,0.23482,1.111449},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.409049,0.16671,1.094275},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.984961,0.23482,0.863514},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.040774,0.16671,0.805513},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-1.21012,0.23482,-0.40783},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-1.187425,0.16671,-0.485058},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.842013,0.23482,-0.948757},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.770118,0.16671,-0.984954},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.080493,0.23482,-1.173335},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0,0.16671,-1.173335},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.698222,0.23482,-1.02115},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.770118,0.16671,-0.984954},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{1.16473,0.23482,-0.562284},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{1.187425,0.16671,-0.485058},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{1.096585,0.23482,0.747511},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{1.040774,0.16671,0.805513},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.487689,0.23482,1.077102},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.409049,0.16671,1.094275},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.261165,0.99174,0.660459},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.339804,0.923631,0.643285},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.634994,0.99174,0.422694},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.690805,0.923631,0.364693},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.796517,0.99174,-0.276002},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.773821,0.923631,-0.353229},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.611639,0.99174,-0.529786},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.539744,0.923631,-0.565983},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.194477,0.99174,-0.643927},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.113984,0.923631,-0.643927},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.23988,0.99174,-0.602179},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.311775,0.923631,-0.565983},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.523158,0.99174,-0.430456},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.545853,0.923631,-0.353229},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.518648,0.99174,0.306691},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.462836,0.923631,0.364693},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.190475,0.99174,0.626112},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.111835,0.923631,0.643285},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.187872,1.489753,0.447704},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.266513,1.421644,0.43053},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.449412,1.489753,0.352832},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.505224,1.421644,0.294831},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.585483,1.489753,-0.206141},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.562786,1.421644,-0.283369},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.473895,1.489753,-0.264203},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.402,1.421644,-0.300399},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{-0.194477,1.489753,-0.431171},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{-0.113984,1.421644,-0.431171},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.102136,1.489753,-0.336595},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.174031,1.421644,-0.300399},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.312123,1.489753,-0.360595},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.334817,1.421644,-0.283369},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.333066,1.489753,0.23683},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.277255,1.421644,0.294831},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.024767,0.162534,0.027863},2,{0.117182,1.489753,0.413356},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.170272,0.024767,0.027863},2,{0.038544,1.421644,0.43053},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{-0.712172,0.408183,-0.674631},{0.872689,0,0.488277,0,1.0,0,-0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{-0.572823,0.632055,-0.62139},{0.832165,0,0.554528,0,1.0,0,-0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{-0.64476,0.843625,-0.36717},{0.782307,0,0.622894,0,1.0,0,-0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{-0.678469,1.038775,-0.365471},{0.721315,0,0.692607,0,1.0,0,-0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.131575,0.913282,0.557256},3,{-0.650133,0.433422,-0.743191},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.131575,0.541778,0.386984},3,{-0.882324,0.743009,-0.496185},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.417942,0.185753,0.116095},3,{-0.47986,1.176431,-0.35884},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.495339,0.139314,0.100616},4,{-0.386984,-0.743009,-1.152191},{0.913545,-0.406737,0,0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.46438,0.640095,0.46438},3,{-0.580476,-1.400881,-0.881096},{0.27146,-0.943133,-0.19186,0.96245,0.266012,0.054114,0,-0.199346,0.979929},'plastic',0,0},{'box','FoxTail',{0.380793,0.638479,0.380793},3,{-1.083555,-1.106774,-0.811664},{0.72032,-0.630347,0.289485,0.693642,0.654591,-0.300619,0,0.417341,0.90875},'plastic',0,0},{'box','FoxTail',{0.297204,0.520346,0.297204},3,{-1.385403,-0.657873,-0.678432},{0.922194,-0.386727,0,0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.213615,0.547277,0.213615},3,{-1.44732,-0.147054,-0.678432},{0.989949,0.141421,0,-0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.130026,0.266317,0.130026},3,{-1.331225,0.23219,-0.678432},{0.813733,0.581238,0,-0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.433422,0.278629,0.46438},5,{-0.882324,-1.315745,-0.944896},{0.949092,0.201736,-0.241922,-0.207912,0.978148,0,0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.394724,0.278629,0.425683},5,{-1.284786,-0.897803,-0.678432},{0.905849,0.347723,-0.241922,-0.358368,0.93358,0,0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.356025,0.278629,0.386984},5,{-1.486017,-0.417942,-0.678432},{0.840301,0.485148,-0.241922,-0.5,0.866025,0,0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.317326,0.278629,0.348285},5,{-1.408621,0.123835,-0.678432},{0.754061,0.610627,-0.241922,-0.62932,0.777146,0,0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.123835,0.492996,0.123835},3,{-1.401495,0.363066,-0.572855},{0.957826,0.282587,-0.052091,-0.287348,0.941956,-0.173638,0,0.181283,0.983431},'plastic',0,0},{'corner','TailTip',{0.123835,0.492996,0.123835},3,{-1.282884,0.327483,-0.572855},{0.052091,0.282587,0.957826,0.173638,0.941956,-0.287348,-0.983431,0.181283,0},'plastic',0,0},{'corner','TailTip',{0.123835,0.492996,0.123835},3,{-1.276433,0.348985,-0.694639},{-0.957826,0.282587,0.052091,0.287348,0.941956,0.173638,0,0.181283,-0.983431},'plastic',0,0},{'corner','TailTip',{0.123835,0.492996,0.123835},3,{-1.395045,0.384569,-0.694639},{-0.052091,0.282587,-0.957826,-0.173638,0.941956,0.287348,0.983431,0.181283,0},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{0.484204,0.408183,-0.674631},{0.872689,0,-0.488277,0,1.0,0,0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{0.572823,0.632055,-0.62139},{0.832165,0,-0.554528,0,1.0,0,0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{0.416791,0.843625,-0.36717},{0.782307,0,-0.622894,0,1.0,0,0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.402464,0.386984,0.069657},3,{0.4505,1.038775,-0.365471},{0.721315,0,-0.692607,0,1.0,0,0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.131575,0.913282,0.557256},3,{0.650133,0.433422,-0.496185},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.131575,0.541778,0.386984},3,{0.882324,0.743009,-0.468336},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.417942,0.185753,0.116095},3,{0.47986,1.176431,-0.35884},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.495339,0.139314,0.100616},4,{0.386984,-0.743009,-1.152191},{0.913545,0.406737,0,-0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.46438,0.633279,0.46438},3,{0.580476,-1.400881,-0.698734},{0.27146,0.953285,-0.132505,-0.96245,0.268875,-0.037373,0,0.137675,0.990478},'plastic',0,0},{'box','FoxTail',{0.380793,0.580685,0.380793},3,{1.083555,-1.106774,-0.666786},{0.72032,0.693083,0.027823,-0.693642,0.71974,0.028893,0,-0.040112,0.999195},'plastic',0,0},{'box','FoxTail',{0.297204,0.520346,0.297204},3,{1.385403,-0.657873,-0.678432},{0.922194,0.386727,0,-0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.213615,0.547277,0.213615},3,{1.44732,-0.147054,-0.678432},{0.989949,-0.141421,0,0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.130026,0.266317,0.130026},3,{1.331225,0.23219,-0.678432},{0.813733,-0.581238,0,0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.433422,0.278629,0.46438},5,{0.882324,-1.315745,-0.65514},{0.949092,-0.201736,0.241922,0.207912,0.978148,0,-0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.394724,0.278629,0.425683},5,{1.284786,-0.897803,-0.678432},{0.905849,-0.347723,0.241922,0.358368,0.93358,0,-0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.356025,0.278629,0.386984},5,{1.486017,-0.417942,-0.678432},{0.840301,-0.485148,0.241922,0.5,0.866025,0,-0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.317326,0.278629,0.348285},5,{1.408621,0.123835,-0.678432},{0.754061,-0.610627,0.241922,0.62932,0.777146,0,-0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.123835,0.485075,0.123835},3,{1.280226,0.336341,-0.608807},{0.957826,-0.287202,0.00917,0.287348,0.957338,-0.030565,0,0.031911,0.999491},'plastic',0,0},{'corner','TailTip',{0.123835,0.485075,0.123835},3,{1.398837,0.371925,-0.608807},{-0.00917,-0.287202,0.957826,0.030565,0.957338,0.287348,-0.999491,0.031911,0},'plastic',0,0},{'corner','TailTip',{0.123835,0.485075,0.123835},3,{1.397703,0.37571,-0.732579},{-0.957826,-0.287202,-0.00917,-0.287348,0.957338,0.030565,0,0.031911,-0.999491},'plastic',0,0},{'corner','TailTip',{0.123835,0.485075,0.123835},3,{1.27909,0.340126,-0.732579},{0.00917,-0.287202,-0.957826,-0.030565,0.957338,-0.287348,0.999491,0.031911,0},'plastic',0,0},{'box','CrownPatch',{0.665613,0.154794,0.541778},3,{0,1.594374,-0.030959},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CrownFrontPatch',{0.665613,0.154794,0.092876},3,{0,1.486017,-0.457486},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilBezel',{0.356025,0.356025,0.216711},6,{0,0.665613,-0.837292},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','ForeheadSigilGem',{0.249217,0.249217,0.23219},7,{0,0.665613,-0.976606},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilFacet',{0.106807,0.106807,0.054177},7,{-0.038699,0.70431,-1.108181},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0}},bounds={3.5,3.409304,2.37395}},
['Night Flame Egg']={palette={{82,46,18},{159,103,35},{143,88,29},{115,66,21},{213,140,31},{224,159,44},{46,106,23},{61,125,28},{77,143,35},{35,79,18},{126,78,25},{107,183,36},{204,128,27},{255,143,12},{255,195,48}},parts={{'box','EggShell',{0.147379,0.198324,0.448116},1,{-0.368446,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.702063},1,{-0.221068,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.799334},1,{-0.073689,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.799334},1,{0.073689,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.702063},1,{0.221068,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.448116},1,{0.368446,-1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.487154},1,{-0.368446,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.776159},1,{-0.221068,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.906359},1,{-0.073689,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.945784},1,{0.073689,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.906359},1,{0.221068,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.776159},1,{0.368446,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.487154},1,{0.515825,-0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{-0.515825,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{-0.368446,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.221068,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.073689,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{0.073689,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{0.221068,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{0.368446,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{0.515825,-0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{-0.515825,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{-0.368446,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.221068,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.073689,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{0.073689,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{0.221068,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{0.368446,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{0.515825,-0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{-0.515825,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{-0.368446,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.221068,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.073689,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{0.073689,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{0.221068,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{0.368446,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{0.515825,-0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{-0.515825,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{-0.368446,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.221068,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.073689,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{0.073689,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{0.221068,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{0.368446,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{0.515825,-0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.557081},1,{-0.663202,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.906359},1,{-0.515825,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.089308},1,{-0.368446,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.185603},1,{-0.221068,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.216007},1,{-0.073689,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.185603},1,{0.073689,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.089308},1,{0.221068,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.906359},1,{0.368446,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.557081},1,{0.515825,0.099163,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.58894},1,{-0.663202,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.964892},1,{-0.515825,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.170104},1,{-0.368446,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.288886},1,{-0.221068,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.344348},1,{-0.073689,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.344348},1,{0.073689,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.288886},1,{0.221068,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.170104},1,{0.368446,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.964892},1,{0.515825,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.58894},1,{0.663202,0.297486,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.619161},1,{-0.810581,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.020074},1,{-0.663202,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.245671},1,{-0.515825,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.384486},1,{-0.368446,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.46146},1,{-0.221068,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.486233},1,{-0.073689,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.46146},1,{0.073689,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.384486},1,{0.221068,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.245671},1,{0.368446,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.020074},1,{0.515825,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.619161},1,{0.663202,0.49581,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.647975},1,{-0.810581,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.663202,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.316909},1,{-0.515825,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.473898},1,{-0.368446,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.56986},1,{-0.221068,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.615705},1,{-0.073689,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.615705},1,{0.073689,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.56986},1,{0.221068,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.473898},1,{0.368446,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.316909},1,{0.515825,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{0.663202,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.647975},1,{0.810581,0.694134,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{-0.810581,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{-0.663202,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.515825,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.368446,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.072419},1,{-0.221068,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,1.002018},1,{-0.073689,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.843774},1,{0.073689,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.523286},1,{0.221068,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.30212},1,{0.515825,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.405336},1,{0.663202,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.30212},1,{0.810581,0.892459,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.148624},1,{-0.810581,1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.148624},1,{-0.073689,1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.234021},1,{0.663202,1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.147379,0.198324,0.234021},1,{0.810581,1.090782,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0,-1.030523,0.419317},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{-0.214236,-1.030523,0.369599},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{-0.374086,-1.030523,0.237683},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{-0.435258,-1.030523,-0.224057},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{-0.374086,-1.030523,-0.237683},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{-0.214236,-1.030523,-0.369599},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{0,-1.030523,-0.419317},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.214236,-1.030523,-0.369599},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.374086,-1.030523,-0.237683},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{0.435258,-1.030523,-0.224057},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.374086,-1.030523,0.237683},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{0.214236,-1.030523,0.369599},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.146543,-0.682524,0.55561},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{-0.401949,-0.682524,0.438738},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.553204,-0.682524,0.269656},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.553204,-0.682524,-0.269656},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{-0.401949,-0.682524,-0.438738},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.146543,-0.682524,-0.55561},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{0.146543,-0.682524,-0.55561},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.401949,-0.682524,-0.438738},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.553204,-0.682524,-0.269656},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.553204,-0.682524,0.269656},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.401949,-0.682524,0.438738},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.146543,-0.682524,0.55561},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0,-0.206631,0.55586},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.283504,-0.206631,0.519576},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.494061,-0.206631,0.275269},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.573794,-0.206631,-0.261644},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.494061,-0.206631,-0.275269},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.283504,-0.206631,-0.519576},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0,-0.206631,-0.55586},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.283504,-0.206631,-0.519576},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.494061,-0.206631,-0.275269},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{0.573794,-0.206631,-0.261644},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{0.494061,-0.206631,0.275269},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.283504,-0.206631,0.519576},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.182397,0.30798,0.663845},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.499908,0.30798,0.499296},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.687019,0.30798,0.302482},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.687019,0.30798,-0.302482},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.499908,0.30798,-0.499296},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{-0.182397,0.30798,-0.663845},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.182397,0.30798,-0.663845},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.499908,0.30798,-0.499296},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.687019,0.30798,-0.302482},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{0.687019,0.30798,0.302482},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.499908,0.30798,0.499296},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.182397,0.30798,0.663845},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0,0.764881,0.827503},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{-0.422039,0.764881,0.755518},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{-0.734012,0.764881,0.549834},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.850865,0.764881,-0.323987},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},4,{-0.734012,0.764881,-0.549834},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{-0.422039,0.764881,-0.755518},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0,0.764881,-0.827503},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.422039,0.764881,-0.755518},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.734012,0.764881,-0.549834},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.850865,0.764881,-0.323987},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},2,{0.734012,0.764881,0.549834},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.327508,0.305674,0.098253},3,{0.422039,0.764881,0.755518},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{-0.218254,1.050659,0.55561},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{-0.597867,1.050659,0.517859},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{-0.820834,1.050659,0.082325},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{-0.820834,1.050659,-0.082325},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{-0.597867,1.050659,-0.517859},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{-0.218254,1.050659,-0.55561},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},4,{0.218254,1.050659,-0.281045},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.597867,1.050659,-0.16791},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{0.820834,1.050659,-0.125024},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},3,{0.820834,1.050659,0.125024},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.597867,1.050659,0.16791},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.251089,0.305674,0.098253},2,{0.218254,1.050659,0.281045},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'wedge','GoldenPinion',{0.185587,0.556762,0.174671},5,{-0.900646,0.458511,0.021834},{-0.470588,-0.882353,0,0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.601051,0.174671},5,{-0.947043,0.589514,0.021834},{-0.23612,-0.971724,0,0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.677201,0.174671},5,{-0.99344,0.720517,0.021834},{-0.032241,-0.99948,0,0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.775889,0.174671},5,{-1.039836,0.85152,0.021834},{0.126632,-0.99195,0,0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.889645,0.174671},5,{-1.086234,0.982522,0.021834},{0.245422,-0.969416,0,0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,1.013409,0.174671},5,{-1.132631,1.113526,0.021834},{0.333947,-0.942592,0,0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,1.143935,0.174671},5,{-1.179028,1.244529,0.021834},{0.400819,-0.916157,0,0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.109169,0.607044,0.109169},6,{-0.895187,1.004358,0.087335},{0.611448,-0.791285,0,0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.109169,0.66405,0.109169},6,{-1.430116,1.342781,0.087335},{0.460317,-0.887755,0,0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{-0.655015,-0.906105,-0.603895},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{-0.728505,-0.644099,-0.667212},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},9,{-0.734429,-0.382093,-0.667212},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{-0.66734,-0.120086,-0.667212},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{-0.58892,0.14192,-0.723805},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},9,{-0.571267,0.403926,-0.861733},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{-0.630613,0.665933,-0.938855},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{-0.712394,0.927939,-0.55289},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.060042,0.701869,0.060042},10,{-0.655015,-0.660474,-0.577107},{0.96728,-0.248865,-0.049358,0.253713,0.948799,0.188176,0,-0.194541,0.980894},'wood',0,0},{'box','IvyVine',{0.060042,0.842196,0.060042},10,{-0.725975,0.081878,-0.742639},{0.999201,0.038887,0.009231,-0.039968,0.972184,0.230784,0,-0.230969,0.972961},'wood',0,0},{'box','IvyVine',{0.060042,0.585287,0.060042},10,{-0.627722,0.725975,-0.685478},{0.9442,0.279784,-0.173802,-0.329372,0.802046,-0.498233,0,0.527677,0.849445},'wood',0,0},{'wedge','GoldenPinion',{0.185587,0.556762,0.174671},5,{0.900646,0.458511,0.021834},{-0.470588,0.882353,0,-0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.601051,0.174671},5,{0.947043,0.589514,0.021834},{-0.23612,0.971724,0,-0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.677201,0.174671},5,{0.99344,0.720517,0.021834},{-0.032241,0.99948,0,-0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.775889,0.174671},5,{1.039836,0.85152,0.021834},{0.126632,0.99195,0,-0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,0.889645,0.174671},5,{1.086234,0.982522,0.021834},{0.245422,0.969416,0,-0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,1.013409,0.174671},5,{1.132631,1.113526,0.021834},{0.333947,0.942592,0,-0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.185587,1.143935,0.174671},5,{1.179028,1.244529,0.021834},{0.400819,0.916157,0,-0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.109169,0.607044,0.109169},6,{0.895187,1.004358,0.087335},{0.611448,0.791285,0,-0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.109169,0.66405,0.109169},6,{1.430116,1.342781,0.087335},{0.460317,0.887755,0,-0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{0.655015,-0.906105,-0.603895},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{0.728505,-0.644099,-0.667212},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},9,{0.734429,-0.382093,-0.667212},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{0.66734,-0.120086,-0.667212},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{0.58892,0.14192,-0.723805},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},9,{0.571267,0.403926,-0.861733},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},7,{0.630613,0.665933,-0.938855},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.251089,0.327508,0.131003},8,{0.712394,0.927939,-0.55289},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.060042,0.701869,0.060042},10,{0.655015,-0.660474,-0.577107},{0.96728,0.248865,0.049358,-0.253713,0.948799,0.188176,0,-0.194541,0.980894},'wood',0,0},{'box','IvyVine',{0.060042,0.842196,0.060042},10,{0.725975,0.081878,-0.742639},{0.999201,-0.038887,-0.009231,0.039968,0.972184,0.230784,0,-0.230969,0.972961},'wood',0,0},{'box','IvyVine',{0.060042,0.585287,0.060042},10,{0.627722,0.725975,-0.685478},{0.9442,-0.279784,0.173802,0.329372,0.802046,-0.498233,0,0.527677,0.849445},'wood',0,0},{'box','CrownBattlement',{0.196505,0.28384,0.272923},11,{-0.524012,1.113526,-0.109169},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.196505,0.28384,0.272923},11,{-0.174671,1.113526,-0.109169},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.196505,0.28384,0.272923},11,{0.174671,1.113526,-0.109169},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.196505,0.28384,0.272923},11,{0.524012,1.113526,-0.109169},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'corner','CrownEmerald',{0.131003,0.393009,0.131003},12,{-0.065501,1.375532,0.065501},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'corner','CrownEmerald',{0.131003,0.393009,0.131003},12,{0.065501,1.375532,0.065501},{0,0,1.0,0,1.0,0,-1.0,0,0},'plastic',0,0},{'corner','CrownEmerald',{0.131003,0.393009,0.131003},12,{0.065501,1.375532,-0.065501},{-1.0,0,0,0,1.0,0,0,0,-1.0},'plastic',0,0},{'corner','CrownEmerald',{0.131003,0.393009,0.131003},12,{-0.065501,1.375532,-0.065501},{0,0,-1.0,0,1.0,0,1.0,0,0},'plastic',0,0},{'box','EmberHeartBezel',{0.665933,0.665933,0.152838},13,{0,-0.054585,-0.895187},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','EmberHeartGem',{0.466152,0.466152,0.163754},14,{0,-0.054585,-0.99344},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','EmberHeartFacet',{0.19978,0.19978,0.038209},15,{-0.027292,-0.027292,-1.086234},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={3.5,2.761981,1.981968}},
['Archangel Egg']={palette={{207,144,29},{241,185,52},{191,121,20},{225,163,38},{246,195,62},{248,245,229},{255,237,112},{255,224,78}},parts={{'box','EggShell',{0.124967,0.224223,0.379975},1,{-0.31242,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.595306},1,{-0.187453,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.677786},1,{-0.062484,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.677786},1,{0.062484,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.595306},1,{0.187453,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.379975},1,{0.31242,-0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.443715},1,{-0.437387,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.715469},1,{-0.31242,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.84965},1,{-0.187453,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{-0.062484,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{0.062484,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.84965},1,{0.187453,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.715469},1,{0.31242,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.443715},1,{0.437387,-0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.499385},1,{-0.687324,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.81817},1,{-0.562356,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.992177},1,{-0.437387,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.092898},1,{-0.31242,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.139925},1,{-0.187453,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.139925},1,{-0.062484,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.092898},1,{0.062484,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.992177},1,{0.187453,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.81817},1,{0.31242,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.499385},1,{0.437387,-0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{-0.687324,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.86496},1,{-0.562356,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.056254},1,{-0.437387,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.17396},1,{-0.31242,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.239229},1,{-0.187453,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.260235},1,{-0.062484,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.239229},1,{0.062484,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.17396},1,{0.187453,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.056254},1,{0.31242,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.86496},1,{0.437387,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{0.562356,-0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{-0.687324,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.86496},1,{-0.562356,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.056254},1,{-0.437387,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.17396},1,{-0.31242,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.239229},1,{-0.187453,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.260235},1,{-0.062484,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.239229},1,{0.062484,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.17396},1,{0.187453,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.056254},1,{0.31242,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.86496},1,{0.437387,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{0.562356,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.549443},1,{-0.687324,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{-0.562356,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.116659},1,{-0.437387,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.249776},1,{-0.31242,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.331145},1,{-0.187453,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.370019},1,{-0.062484,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.370019},1,{0.062484,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.331145},1,{0.187453,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.249776},1,{0.31242,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.116659},1,{0.437387,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{0.562356,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.549443},1,{0.687324,0.224223,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.549443},1,{-0.687324,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{-0.562356,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.116659},1,{-0.437387,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.249776},1,{-0.31242,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.331145},1,{-0.187453,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.370019},1,{-0.062484,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.370019},1,{0.062484,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.331145},1,{0.187453,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.249776},1,{0.31242,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,1.116659},1,{0.437387,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.909345},1,{0.562356,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.549443},1,{0.687324,0.448445,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.3437},1,{-0.31242,0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{-0.187453,0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.572834},1,{-0.062484,0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.525011},1,{0.062484,0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.3437},1,{0.187453,0.672667,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.198435},1,{-0.062484,0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.124967,0.224223,0.198435},1,{0.062484,0.89689,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{0,-0.87382,0.355555},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{-0.181659,-0.87382,0.313397},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{-0.317202,-0.87382,0.201541},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{-0.369073,-0.87382,-0.189987},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{-0.317202,-0.87382,-0.201541},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{-0.181659,-0.87382,-0.313397},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{0,-0.87382,-0.355555},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{0.181659,-0.87382,-0.313397},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{0.317202,-0.87382,-0.201541},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{0.369073,-0.87382,-0.189987},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{0.317202,-0.87382,0.201541},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{0.181659,-0.87382,0.313397},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.124259,-0.578739,0.471124},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.340828,-0.578739,0.372022},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.469082,-0.578739,0.228653},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.469082,-0.578739,-0.228653},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.340828,-0.578739,-0.372022},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.124259,-0.578739,-0.471124},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.124259,-0.578739,-0.471124},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.340828,-0.578739,-0.372022},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.469082,-0.578739,-0.228653},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.469082,-0.578739,0.228653},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.340828,-0.578739,0.372022},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.124259,-0.578739,0.471124},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.062484,-0.175211,0.64678},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.39098,-0.175211,0.543871},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.634016,-0.175211,0.444034},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.725231,-0.175211,-0.262505},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.634016,-0.175211,-0.444034},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.39098,-0.175211,-0.543871},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.062484,-0.175211,-0.64678},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.266012,-0.175211,-0.543871},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.509047,-0.175211,-0.444034},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.600263,-0.175211,-0.262505},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.509047,-0.175211,0.444034},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.266012,-0.175211,0.543871},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.185065,0.261149,0.682024},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.506955,0.261149,0.572618},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.696018,0.261149,0.281516},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.696018,0.261149,-0.281516},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.506955,0.261149,-0.572618},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.185065,0.261149,-0.682024},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{0.185065,0.261149,-0.682024},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.506955,0.261149,-0.572618},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.696018,0.261149,-0.281516},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.696018,0.261149,0.281516},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.506955,0.261149,0.572618},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.185065,0.261149,0.682024},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.062484,0.648572,0.303079},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.214775,0.648572,0.27825},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.32882,0.648572,0.183404},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.372821,0.648572,-0.17185},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},3,{-0.32882,0.648572,-0.183404},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{-0.214775,0.648572,-0.27825},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{-0.062484,0.648572,-0.303079},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.089807,0.648572,-0.27825},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.203852,0.648572,-0.183404},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},2,{0.247854,0.648572,-0.17185},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.203852,0.648572,0.183404},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.277706,0.259192,0.083312},4,{0.089807,0.648572,0.27825},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{-0.033049,0.890895,0.115669},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{-0.091636,0.890895,0.113505},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{-0.128681,0.890895,0.106012},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{-0.128681,0.890895,-0.106012},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{-0.091636,0.890895,-0.113505},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{-0.033049,0.890895,-0.115669},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{0.033049,0.890895,-0.115669},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},3,{0.091636,0.890895,-0.113505},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{0.128681,0.890895,-0.106012},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{0.128681,0.890895,0.106012},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},2,{0.091636,0.890895,0.113505},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.212909,0.259192,0.083312},4,{0.033049,0.890895,0.115669},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','WingSpar',{0.129596,0.636373,0.129596},5,{-0.740551,0.745179,0.06017},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.129596,0.646791,0.129596},5,{-1.272823,1.032142,0.074055},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.175881,0.759065,0.129596},6,{-0.675752,0.448774,0.018514},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.546526,0.025919},5,{-0.681404,0.473645,-0.066411},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.175881,0.727326,0.129596},6,{-0.802704,0.513096,0.025126},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.523675,0.025919},5,{-0.8068,0.537495,-0.05958},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.175881,0.695589,0.129596},6,{-0.929656,0.577419,0.031738},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.500824,0.025919},5,{-0.932251,0.601267,-0.052757},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.175881,0.663851,0.129596},6,{-1.056607,0.64174,0.03835},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.477973,0.025919},5,{-1.057761,0.664965,-0.045943},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.175881,0.632112,0.129596},6,{-1.183559,0.706062,0.044963},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.455121,0.025919},5,{-1.183331,0.728591,-0.039136},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.175881,0.600375,0.129596},6,{-1.310511,0.770385,0.051574},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.43227,0.025919},5,{-1.308966,0.79215,-0.03234},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.175881,0.568638,0.129596},6,{-1.437462,0.834706,0.058186},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.409419,0.025919},5,{-1.434669,0.855644,-0.025552},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.175881,0.5369,0.129596},6,{-1.564414,0.899029,0.064799},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.386567,0.025919},5,{-1.56044,0.919079,-0.018774},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{-0.620211,0.666496,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{-0.786835,0.749807,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{-0.953459,0.83312,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{-1.120084,0.916431,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.129596,0.636373,0.129596},5,{0.740551,0.745179,0.06017},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.129596,0.646791,0.129596},5,{1.272823,1.032142,0.074055},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.175881,0.759065,0.129596},6,{0.675752,0.448774,0.018514},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.546526,0.025919},5,{0.681404,0.473645,-0.066411},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.175881,0.727326,0.129596},6,{0.802704,0.513096,0.025126},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.523675,0.025919},5,{0.8068,0.537495,-0.05958},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.175881,0.695589,0.129596},6,{0.929656,0.577419,0.031738},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.500824,0.025919},5,{0.932251,0.601267,-0.052757},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.175881,0.663851,0.129596},6,{1.056607,0.64174,0.03835},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.477973,0.025919},5,{1.057761,0.664965,-0.045943},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.175881,0.632112,0.129596},6,{1.183559,0.706062,0.044963},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.455121,0.025919},5,{1.183331,0.728591,-0.039136},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.175881,0.600375,0.129596},6,{1.310511,0.770385,0.051574},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.43227,0.025919},5,{1.308966,0.79215,-0.03234},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.175881,0.568638,0.129596},6,{1.437462,0.834706,0.058186},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.409419,0.025919},5,{1.434669,0.855644,-0.025552},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.175881,0.5369,0.129596},6,{1.564414,0.899029,0.064799},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.386567,0.025919},5,{1.56044,0.919079,-0.018774},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{0.620211,0.666496,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{0.786835,0.749807,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{0.953459,0.83312,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},5,{1.120084,0.916431,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','HolyRuneStem',{0.069426,1.314477,0.069426},7,{0,0.046285,-0.71278},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','HolyRuneCross',{0.064799,0.629469,0.064799},7,{0,0.092569,-0.749807},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0},{'corner','RuneUpperPoint',{0.06017,0.234183,0.06017},7,{-0.030085,0.749551,-0.647211},{1.0,0,0,0,0.948683,-0.316228,0,0.316228,0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.06017,0.234183,0.06017},7,{0.030085,0.749551,-0.647211},{0,0,1.0,0.316228,0.948683,0,-0.948683,0.316228,0},'neon',0,0},{'corner','RuneUpperPoint',{0.06017,0.234183,0.06017},7,{0.030085,0.768579,-0.704294},{-1.0,0,0,0,0.948683,0.316228,0,0.316228,-0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.06017,0.234183,0.06017},7,{-0.030085,0.768579,-0.704294},{0,0,-1.0,-0.316228,0.948683,0,0.948683,0.316228,0},'neon',0,0},{'corner','RuneLowerPoint',{0.06017,0.265239,0.06017},7,{0.030085,-0.674939,-0.63099},{-1.0,0,0,0,-0.872506,0.488603,0,0.488603,0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.06017,0.265239,0.06017},7,{-0.030085,-0.674939,-0.63099},{0,0,-1.0,-0.488603,-0.872506,0,-0.872506,0.488603,0},'neon',0,0},{'corner','RuneLowerPoint',{0.06017,0.265239,0.06017},7,{-0.030085,-0.704338,-0.683489},{1.0,0,0,0,-0.872506,-0.488603,0,0.488603,-0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.06017,0.265239,0.06017},7,{0.030085,-0.704338,-0.683489},{0,0,1.0,0.488603,-0.872506,0,0.872506,0.488603,0},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.454959,1.295964,0.059896},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.423954,1.295964,0.175607},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.364058,1.295964,0.279351},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.279351,1.295964,0.364058},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.175607,1.295964,0.423954},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.059896,1.295964,0.454959},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.059896,1.295964,0.454959},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.175607,1.295964,0.423954},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.279351,1.295964,0.364058},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.364058,1.295964,0.279351},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.423954,1.295964,0.175607},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.454959,1.295964,0.059896},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.454959,1.295964,-0.059896},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.423954,1.295964,-0.175607},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.364058,1.295964,-0.279351},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.279351,1.295964,-0.364058},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.175607,1.295964,-0.423954},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{-0.059896,1.295964,-0.454959},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.059896,1.295964,-0.454959},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.175607,1.295964,-0.423954},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.279351,1.295964,-0.364058},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.364058,1.295964,-0.279351},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.423954,1.295964,-0.175607},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.044432,0.120826,0.044432},8,{0.454959,1.295964,-0.059896},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'ball','HaloDroplet',{0.041656,0.129596,0.041656},5,{-0.44433,1.194139,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.041656,0.129596,0.041656},5,{0.44433,1.194139,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.041656,0.129596,0.041656},5,{0,1.194139,0.44433},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.041656,0.129596,0.041656},5,{0,1.194139,-0.44433},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.083312,0.333248,0.083312},5,{-0.041656,1.444074,0.041656},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.083312,0.333248,0.083312},5,{0.041656,1.444074,0.041656},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'corner','HaloStar',{0.083312,0.333248,0.083312},5,{0.041656,1.444074,-0.041656},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'corner','HaloStar',{0.083312,0.333248,0.083312},5,{-0.041656,1.444074,-0.041656},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0}},bounds={3.5,2.619699,1.527399}},
['World Burner Egg']={palette={{49,14,25},{101,29,43},{53,15,27},{78,22,36},{33,17,23},{239,88,117},{38,17,24},{82,21,37},{32,15,21},{91,79,85}},parts={{'box','EggShell',{0.14154,0.285701,0.389279},1,{-0.21231,-0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.594634},1,{-0.07077,-0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.648799},1,{0.07077,-0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.594634},1,{0.21231,-0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{0.353851,-0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.142736},1,{-0.495391,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{-0.21231,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.594634},1,{-0.07077,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.648799},1,{0.07077,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.594634},1,{0.21231,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{0.353851,-0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.502557},1,{-0.495391,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.810349},1,{-0.353851,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.962324},1,{-0.21231,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{-0.07077,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{0.07077,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.962324},1,{0.21231,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.810349},1,{0.353851,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.502557},1,{0.495391,-0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.56561},1,{-0.636931,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.92667},1,{-0.495391,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.123752},1,{-0.353851,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.237829},1,{-0.21231,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.291092},1,{-0.07077,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.291092},1,{0.07077,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.237829},1,{0.21231,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.123752},1,{0.353851,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.92667},1,{0.495391,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.56561},1,{0.636931,-0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.622306},1,{-0.778471,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{-0.636931,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.264741},1,{-0.495391,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.415511},1,{-0.353851,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.507671},1,{-0.21231,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.551701},1,{-0.07077,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.551701},1,{0.07077,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.507671},1,{0.21231,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.415511},1,{0.353851,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.264741},1,{0.495391,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{0.636931,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.622306},1,{0.778471,0.142851,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.622306},1,{-0.778471,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{-0.636931,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.264741},1,{-0.495391,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.415511},1,{-0.353851,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.507671},1,{-0.21231,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.551701},1,{-0.07077,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.551701},1,{0.07077,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.507671},1,{0.21231,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.415511},1,{0.353851,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.264741},1,{0.495391,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,1.029936},1,{0.636931,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.622306},1,{0.778471,0.428553,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.430364},1,{-0.778471,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.674251},1,{-0.636931,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.767669},1,{-0.495391,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.767669},1,{-0.353851,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.674251},1,{-0.21231,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.430364},1,{-0.07077,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.142736},1,{0.21231,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{0.495391,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{0.636931,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{0.778471,0.714254,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{-0.778471,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{-0.636931,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{-0.495391,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{-0.07077,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{0.07077,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{0.21231,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{0.495391,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.389279},1,{0.636931,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.14154,0.285701,0.290151},1,{0.778471,0.999956,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{0.07077,-0.9897,0.343271},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},3,{-0.101718,-0.9897,0.315149},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{-0.230886,-0.9897,0.207725},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{-0.280721,-0.9897,-0.19464},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{-0.230886,-0.9897,-0.207725},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{-0.101718,-0.9897,-0.315149},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.07077,-0.9897,-0.343271},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.243258,-0.9897,-0.315149},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{0.372426,-0.9897,-0.207725},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{0.422261,-0.9897,-0.19464},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.372426,-0.9897,0.207725},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{0.243258,-0.9897,0.315149},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.194289,-0.655488,0.213272},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.409756,-0.655488,0.08755},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.537802,-0.655488,0.079064},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.537802,-0.655488,-0.079064},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.409756,-0.655488,-0.08755},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.194289,-0.655488,-0.213272},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.052749,-0.655488,-0.343033},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.268216,-0.655488,-0.3135},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.396263,-0.655488,-0.202335},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.396263,-0.655488,0.202335},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.268216,-0.655488,0.3135},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.052749,-0.655488,0.343033},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0,-0.198446,0.664419},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.338797,-0.198446,0.579709},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.589713,-0.198446,0.29589},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.684111,-0.198446,-0.282805},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.589713,-0.198446,-0.29589},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.338797,-0.198446,-0.579709},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0,-0.198446,-0.664419},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.338797,-0.198446,-0.579709},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.589713,-0.198446,-0.29589},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.684111,-0.198446,-0.282805},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.589713,-0.198446,0.29589},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.338797,-0.198446,0.579709},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.209608,0.29578,0.772469},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.574184,0.29578,0.648554},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.788318,0.29578,0.318849},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.788318,0.29578,-0.318849},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.574184,0.29578,-0.648554},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.209608,0.29578,-0.772469},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.209608,0.29578,-0.772469},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.574184,0.29578,-0.648554},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.788318,0.29578,-0.318849},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.788318,0.29578,0.318849},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.574184,0.29578,0.648554},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.209608,0.29578,0.772469},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0,0.734583,0.234054},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.405321,0.734583,0.401666},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{-0.704936,0.734583,0.350211},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.817159,0.734583,-0.215182},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{-0.704936,0.734583,-0.350211},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{-0.405321,0.734583,-0.401666},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0,0.734583,-0.794722},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},4,{0.405321,0.734583,-0.725589},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.704936,0.734583,-0.207725},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.817159,0.734583,-0.145076},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},3,{0.704936,0.734583,0.207725},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.314534,0.293565,0.09436},2,{0.405321,0.734583,0.725589},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{-0.209608,1.009039,0.355759},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},3,{-0.574184,1.009039,0.161259},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{-0.788318,1.009039,0.152771},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{-0.788318,1.009039,-0.152771},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{-0.574184,1.009039,-0.161259},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},3,{-0.209608,1.009039,-0.355759},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.209608,1.009039,-0.163709},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},2,{0.574184,1.009039,-0.161259},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.788318,1.009039,-0.152771},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},3,{0.788318,1.009039,0.152771},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},3,{0.574184,1.009039,0.161259},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.241143,0.293565,0.09436},4,{0.209608,1.009039,0.163709},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','DemonHorn',{0.167751,0.368899,0.167751},5,{-0.330261,1.037963,0.026211},{0.966705,-0.255789,-0.007273,0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.113232,0.28617,0.113232},5,{-0.356471,1.357739,0.020969},{0.989203,0.146549,0,-0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.058713,0.103791,0.058713},5,{-0.298808,1.535974,0.020969},{0.707107,0.707107,0,-0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.036696,0.265652,0.036696},6,{-0.314534,1.179503,-0.057665},{0.987441,-0.157867,0.006235,0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.036696,0.196146,0.036696},6,{-0.309291,1.404919,-0.04718},{0.963518,0.267261,-0.014306,-0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.146783,0.673214,0.146783},7,{-0.82303,0.686733,0.131056},{0.794358,-0.607376,0.00946,0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.146783,0.727444,0.146783},7,{-1.378707,1.048446,0.131056},{0.259457,-0.965654,-0.013919,0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.146783,0.964571,1.090384},8,{-1.153291,0.597615,0.157268},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{-0.933118,0.550435,0.057665},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{-1.216198,0.665764,0.057665},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{-1.499279,0.781093,0.057665},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.04718,0.259795,0.04718},6,{-1.058931,0.697218,0.026211},{0.686624,-0.726421,-0.02934,0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.04718,0.199205,0.04718},6,{-1.121838,0.880695,0.026211},{0.948683,0.315789,-0.016644,-0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','DemonHorn',{0.167751,0.368899,0.167751},5,{0.330261,1.037963,0.026211},{0.966705,0.255789,0.007273,-0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.113232,0.28617,0.113232},5,{0.356471,1.357739,0.020969},{0.989203,-0.146549,0,0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.058713,0.103791,0.058713},5,{0.298808,1.535974,0.020969},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.036696,0.265652,0.036696},6,{0.314534,1.179503,-0.057665},{0.987441,0.157867,-0.006235,-0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.036696,0.196146,0.036696},6,{0.309291,1.404919,-0.04718},{0.963518,-0.267261,0.014306,0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.146783,0.673214,0.146783},7,{0.82303,0.686733,0.131056},{0.794358,0.607376,-0.00946,-0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.146783,0.727444,0.146783},7,{1.378707,1.048446,0.131056},{0.259457,0.965654,0.013919,-0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.146783,0.964571,1.090384},8,{1.153291,0.597615,0.157268},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{0.933118,0.550435,0.057665},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{1.216198,0.665764,0.057665},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.04718,0.772514,0.04718},9,{1.499279,0.781093,0.057665},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.04718,0.259795,0.04718},6,{1.058931,0.697218,0.026211},{0.686624,0.726421,0.02934,-0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.04718,0.199205,0.04718},6,{1.121838,0.880695,0.026211},{0.948683,-0.315789,0.016644,0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.639553,-0.178236,-0.901664},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.600982,-0.038386,-0.901664},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.489925,0.084596,-0.901664},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.319776,0.175876,-0.901664},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.111057,0.224446,-0.901664},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.111057,0.224446,-0.901664},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.319776,0.175876,-0.901664},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.489925,0.084596,-0.901664},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.600982,-0.038386,-0.901664},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.639553,-0.178236,-0.901664},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.600982,-0.318086,-0.901664},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.489925,-0.441068,-0.901664},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.319776,-0.532349,-0.901664},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.111057,-0.580917,-0.901664},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.111057,-0.580917,-0.901664},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.319776,-0.532349,-0.901664},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.489925,-0.441068,-0.901664},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.600982,-0.318086,-0.901664},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.639553,-0.178236,0.901664},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.600982,-0.038386,0.901664},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.489925,0.084596,0.901664},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.319776,0.175876,0.901664},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.111057,0.224446,0.901664},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.111057,0.224446,0.901664},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.319776,0.175876,0.901664},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.489925,0.084596,0.901664},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.600982,-0.038386,0.901664},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.639553,-0.178236,0.901664},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.600982,-0.318086,0.901664},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.489925,-0.441068,0.901664},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.319776,-0.532349,0.901664},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{-0.111057,-0.580917,0.901664},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.111057,-0.580917,0.901664},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.319776,-0.532349,0.901664},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.489925,-0.441068,0.901664},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.230659,0.104845,0.136297},10,{0.600982,-0.318086,0.901664},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','BurnerSigil',{0.068149,0.786335,0.068149},6,{0,-0.162509,-0.838758},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerSigil',{0.068149,0.419379,0.068149},6,{0,-0.146783,-0.849241},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0}},bounds={3.5,2.736235,1.939626}},
['Aetheron Egg']={palette={{203,151,43},{239,192,65},{119,18,33},{232,175,36},{244,233,186},{136,20,37},{94,14,27},{255,226,82},{245,234,190},{99,30,25}},parts={{'box','EggShell',{0.124967,0.183455,0.198435},1,{-0.562356,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{-0.437387,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{-0.062484,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.062484,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.437387,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.562356,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.443715},1,{-0.687324,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.715469},1,{-0.562356,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.84965},1,{-0.437387,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.31242,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.187453,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.84965},1,{-0.062484,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.715469},1,{0.062484,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.443715},1,{0.187453,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{0.437387,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.3437},1,{0.562356,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{0.687324,-0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,-0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,-0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,-0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,0.183455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{-0.687324,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{-0.562356,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{-0.437387,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{-0.31242,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{-0.187453,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{-0.062484,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.370019},1,{0.062484,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.331145},1,{0.187453,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.249776},1,{0.31242,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,1.116659},1,{0.437387,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.909345},1,{0.562356,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.549443},1,{0.687324,0.366909,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.687324,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.3437},1,{-0.562356,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.437387,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.413076},1,{-0.187453,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.658136},1,{-0.062484,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.768537},1,{0.062484,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.801967},1,{0.187453,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.768537},1,{0.31242,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.658136},1,{0.437387,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.413076},1,{0.562356,0.550364,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.687324,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.3437},1,{-0.562356,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.437387,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.126024},1,{0.187453,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.437387,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.562356,0.733819,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.687324,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.3437},1,{-0.562356,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.256179},1,{-0.437387,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.437387,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.124967,0.183455,0.198435},1,{0.562356,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,-0.772939,0.472951},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,-0.345099,0.683851},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,0.175211,0.683851},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.232641,0.648572,0.224818},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.232641,0.914465,0.224818},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,-0.772939,0.4407},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,-0.345099,0.574205},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,0.175211,0.574205},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.52886,0.648572,0.187725},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.52886,0.914465,0.187725},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,-0.772939,0.229407},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,-0.345099,0.282271},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,0.175211,0.282271},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.703459,0.648572,0.135639},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.703459,0.914465,0.135639},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,-0.772939,-0.229407},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,-0.345099,-0.282271},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.697708,0.175211,-0.282271},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.703459,0.648572,-0.135639},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.703459,0.914465,-0.135639},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,-0.772939,-0.4407},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,-0.345099,-0.574205},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.507908,0.175211,-0.574205},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.52886,0.648572,-0.187725},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.52886,0.914465,-0.187725},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,-0.772939,-0.472951},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,-0.345099,-0.683851},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.18536,0.175211,-0.683851},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.232641,0.648572,-0.224818},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},2,{-0.232641,0.914465,-0.224818},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,-0.772939,-0.240136},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,-0.345099,-0.683851},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,0.175211,-0.683851},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.107674,0.648572,-0.402548},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.107674,0.914465,-0.081291},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,-0.772939,-0.143965},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,-0.345099,-0.574205},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,0.175211,-0.574205},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.403892,0.648572,-0.115094},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.403892,0.914465,-0.115094},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,-0.772939,-0.135639},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,-0.345099,-0.282271},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,0.175211,-0.282271},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.57849,0.648572,-0.106768},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.57849,0.914465,-0.106768},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,-0.772939,0.135639},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,-0.345099,0.282271},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.697708,0.175211,0.282271},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.57849,0.648572,0.106768},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.57849,0.914465,0.106768},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,-0.772939,0.143965},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,-0.345099,0.574205},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.507908,0.175211,0.574205},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.403892,0.648572,0.115094},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.403892,0.914465,0.115094},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,-0.772939,0.240136},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,-0.345099,0.683851},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.18536,0.175211,0.683851},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.107674,0.648572,0.402548},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.259192,0.26845,0.083312},3,{0.107674,0.914465,0.081291},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','WingSpar',{0.129596,0.636373,0.129596},4,{-0.740551,0.745179,0.06017},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.129596,0.646791,0.129596},4,{-1.272823,1.032142,0.074055},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.175881,0.759065,0.129596},5,{-0.675752,0.448774,0.018514},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.546526,0.025919},4,{-0.681404,0.473645,-0.066411},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.175881,0.727326,0.129596},5,{-0.802704,0.513096,0.025126},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.523675,0.025919},4,{-0.8068,0.537495,-0.05958},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.175881,0.695589,0.129596},5,{-0.929656,0.577419,0.031738},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.500824,0.025919},4,{-0.932251,0.601267,-0.052757},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.175881,0.663851,0.129596},5,{-1.056607,0.64174,0.03835},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.477973,0.025919},4,{-1.057761,0.664965,-0.045943},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.175881,0.632112,0.129596},5,{-1.183559,0.706062,0.044963},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.455121,0.025919},4,{-1.183331,0.728591,-0.039136},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.175881,0.600375,0.129596},5,{-1.310511,0.770385,0.051574},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.43227,0.025919},4,{-1.308966,0.79215,-0.03234},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.175881,0.568638,0.129596},5,{-1.437462,0.834706,0.058186},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.409419,0.025919},4,{-1.434669,0.855644,-0.025552},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.175881,0.5369,0.129596},5,{-1.564414,0.899029,0.064799},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.386567,0.025919},4,{-1.56044,0.919079,-0.018774},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},4,{-0.620211,0.666496,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},4,{-0.786835,0.749807,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},4,{-0.953459,0.83312,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},4,{-1.120084,0.916431,-0.074055},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.129596,0.636373,0.129596},6,{0.740551,0.745179,0.06017},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.129596,0.646791,0.129596},6,{1.272823,1.032142,0.074055},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.175881,0.759065,0.129596},7,{0.675752,0.448774,0.018514},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.546526,0.025919},6,{0.681404,0.473645,-0.066411},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.175881,0.727326,0.129596},7,{0.802704,0.513096,0.025126},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.523675,0.025919},6,{0.8068,0.537495,-0.05958},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.175881,0.695589,0.129596},7,{0.929656,0.577419,0.031738},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.500824,0.025919},6,{0.932251,0.601267,-0.052757},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.175881,0.663851,0.129596},7,{1.056607,0.64174,0.03835},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.477973,0.025919},6,{1.057761,0.664965,-0.045943},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.175881,0.632112,0.129596},7,{1.183559,0.706062,0.044963},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.455121,0.025919},6,{1.183331,0.728591,-0.039136},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.175881,0.600375,0.129596},7,{1.310511,0.770385,0.051574},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.43227,0.025919},6,{1.308966,0.79215,-0.03234},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.175881,0.568638,0.129596},7,{1.437462,0.834706,0.058186},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.409419,0.025919},6,{1.434669,0.855644,-0.025552},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.175881,0.5369,0.129596},7,{1.564414,0.899029,0.064799},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.025919,0.386567,0.025919},6,{1.56044,0.919079,-0.018774},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},6,{0.620211,0.666496,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},6,{0.786835,0.749807,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},6,{0.953459,0.83312,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.185137,0.370275,0.14811},6,{1.120084,0.916431,-0.074055},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.129596,0.43389,0.129596},4,{-0.425816,0.842376,0.078684},{0.768221,-0.640039,0.013658,0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.087477,0.45978,0.087477},4,{-0.661868,1.21728,0.078684},{0.906183,-0.4228,-0.008514,0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.045359,0.288304,0.045359},4,{-0.77295,1.569042,0.074055},{0.99535,-0.096324,0,0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.129596,0.43389,0.129596},6,{0.425816,0.842376,0.078684},{0.768221,0.640039,-0.013658,-0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.087477,0.45978,0.087477},6,{0.661868,1.21728,0.078684},{0.906183,0.4228,0.008514,-0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.045359,0.288304,0.045359},6,{0.77295,1.569042,0.074055},{0.99535,0.096324,0,-0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.345769,1.305221,-0.028534},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.322205,1.305221,0.059406},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.276684,1.305221,0.138251},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.212307,1.305221,0.202629},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.133461,1.305221,0.24815},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.045521,1.305221,0.271714},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.045521,1.305221,0.271714},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.133461,1.305221,0.24815},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.212307,1.305221,0.202629},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.276684,1.305221,0.138251},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.322205,1.305221,0.059406},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.345769,1.305221,-0.028534},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.345769,1.305221,-0.119576},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.322205,1.305221,-0.207516},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.276684,1.305221,-0.286362},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.212307,1.305221,-0.350739},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.133461,1.305221,-0.39626},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{-0.045521,1.305221,-0.419824},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.045521,1.305221,-0.419824},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.133461,1.305221,-0.39626},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.212307,1.305221,-0.350739},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.276684,1.305221,-0.286362},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.322205,1.305221,-0.207516},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.041656,0.091829,0.041656},8,{0.345769,1.305221,-0.119576},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'box','IvorySigil',{0.175881,1.110826,0.092569},9,{0,0.046285,-0.731294},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','RadiantSigil',{0.05369,1.10157,0.05369},8,{0,0.08794,-0.796093},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.050912,0.40646,0.050912},8,{0,-0.231423,-0.759065},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.050912,0.40646,0.050912},8,{0,0.101826,-0.759065},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.050912,0.40646,0.050912},8,{0,0.398046,-0.759065},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'corner','BasePoint',{0.171253,0.518386,0.171253},10,{0.085626,-1.036771,0.085626},{-1.0,0,0,0,-1.0,0,0,0,1.0},'metal',0,0},{'corner','BasePoint',{0.171253,0.518386,0.171253},10,{-0.085626,-1.036771,0.085626},{0,0,-1.0,0,-1.0,0,-1.0,0,0},'metal',0,0},{'corner','BasePoint',{0.171253,0.518386,0.171253},10,{-0.085626,-1.036771,-0.085626},{1.0,0,0,0,-1.0,0,0,0,-1.0},'metal',0,0},{'corner','BasePoint',{0.171253,0.518386,0.171253},10,{0.085626,-1.036771,-0.085626},{0,0,1.0,0,-1.0,0,1.0,0,0},'metal',0,0}},bounds={3.5,3.010673,1.568488}},
['Cthulhu Egg']={palette={{11,59,26},{14,66,28},{35,108,49},{25,89,40},{33,48,69},{108,147,70},{113,139,42},{112,255,47},{62,124,32},{5,29,12},{4,32,12}},parts={{'box','EggShell',{0.191209,0.235864,0.720244},1,{-0.764835,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{-0.573626,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{-0.382417,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{-0.191209,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.572161},1,{0,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{0.191209,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{0.382417,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{0.573626,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.720244},1,{0.764835,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{-0.956044,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{-0.764835,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{-0.573626,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{-0.382417,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{-0.191209,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.921531},1,{0,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{0.191209,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{0.382417,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{0.573626,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{0.764835,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{0.956044,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{-0.956044,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{-0.764835,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{-0.573626,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{-0.382417,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{-0.191209,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.921531},1,{0,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{0.191209,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{0.382417,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{0.573626,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{0.764835,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{0.956044,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{-0.956044,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{-0.764835,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{-0.573626,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{-0.382417,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{-0.191209,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.921531},1,{0,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{0.191209,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{0.382417,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{0.573626,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{0.764835,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{0.956044,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{-0.956044,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{-0.764835,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{-0.573626,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{-0.382417,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{-0.191209,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.921531},1,{0,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{0.191209,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{0.382417,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{0.573626,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{0.764835,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{0.956044,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{-0.956044,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{-0.764835,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{-0.573626,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{-0.382417,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{-0.191209,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.921531},1,{0,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.889502},1,{0.191209,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.789985},1,{0.382417,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.610513},1,{0.573626,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.31884},1,{0.764835,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.800505},1,{0.956044,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{-0.956044,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{-0.764835,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{-0.573626,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{-0.382417,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{-0.191209,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{0,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{0.191209,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{0.382417,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{0.573626,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{0.764835,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.720244},1,{-0.764835,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{-0.573626,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{-0.382417,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{-0.191209,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.572161},1,{0,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{0.191209,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{0.382417,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{0.573626,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.720244},1,{0.764835,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.720244},1,{-0.764835,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{-0.573626,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{-0.382417,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{-0.191209,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.572161},1,{0,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.532851},1,{0.191209,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.408352},1,{0.382417,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.17182},1,{0.573626,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.720244},1,{0.764835,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{-0.764835,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{-0.573626,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{-0.382417,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{-0.191209,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{0,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{0.191209,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{0.382417,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{0.573626,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{0.764835,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{0.956044,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{-0.764835,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{-0.573626,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{-0.382417,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{-0.191209,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{0,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.73809},1,{0.191209,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.666385},1,{0.382417,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.512814},1,{0.573626,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,1.247498},1,{0.764835,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.761432},1,{0.956044,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.302562},1,{-0.191209,1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.191209,0.235864,0.302562},1,{0,1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0,-1.225584,0.809451},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.412056,-1.225584,0.726259},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.717292,-1.225584,0.376326},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.832184,-1.225584,-0.360121},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.717292,-1.225584,-0.376326},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.412056,-1.225584,-0.726259},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0,-1.225584,-0.809451},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.412056,-1.225584,-0.726259},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.717292,-1.225584,-0.376326},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.832184,-1.225584,-0.360121},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.717292,-1.225584,0.376326},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.412056,-1.225584,0.726259},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.259565,-0.811715,0.967825},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.711034,-0.811715,0.67946},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.976205,-0.811715,0.409782},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.976205,-0.811715,-0.409782},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.711034,-0.811715,-0.67946},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.259565,-0.811715,-0.967825},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.259565,-0.811715,-0.967825},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.711034,-0.811715,-0.67946},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.976205,-0.811715,-0.409782},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.976205,-0.811715,0.409782},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.711034,-0.811715,0.67946},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.259565,-0.811715,0.967825},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0,-0.245744,0.984135},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.501925,-0.245744,0.827339},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.872949,-0.245744,0.675624},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-1.01192,-0.245744,-0.400253},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.872949,-0.245744,-0.675624},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.501925,-0.245744,-0.827339},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0,-0.245744,-0.984135},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.501925,-0.245744,-0.827339},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.872949,-0.245744,-0.675624},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{1.01192,-0.245744,-0.400253},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.872949,-0.245744,0.675624},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.501925,-0.245744,0.827339},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.213046,0.366276,0.789499},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.583941,0.366276,0.60595},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.802593,0.366276,0.369651},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.802593,0.366276,-0.369651},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.583941,0.366276,-0.60595},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.213046,0.366276,-0.789499},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.213046,0.366276,-0.789499},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.583941,0.366276,-0.60595},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.802593,0.366276,-0.369651},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.802593,0.366276,0.369651},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.583941,0.366276,0.60595},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.213046,0.366276,0.789499},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.095605,0.909661,0.892415},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.361386,0.909661,0.778489},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.699516,0.909661,0.39692},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.826448,0.909661,-0.380716},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.699516,0.909661,-0.39692},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.361386,0.909661,-0.778489},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.095605,0.909661,-0.892415},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.552595,0.909661,-0.778489},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.890725,0.909661,-0.39692},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{1.017656,0.909661,-0.380716},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.890725,0.909661,0.39692},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.552595,0.909661,0.778489},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.145834,1.249531,0.174355},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.234721,1.249531,0.171321},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{-0.290555,1.249531,0.160811},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.290555,1.249531,-0.160811},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.234721,1.249531,-0.171321},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{-0.145834,1.249531,-0.174355},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{-0.045376,1.249531,-0.174355},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.043513,1.249531,-0.171321},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.099346,1.249531,-0.160811},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.099346,1.249531,0.160811},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.043513,1.249531,0.171321},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.045376,1.249531,0.174355},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.207732,0.464146,0.207732},5,{-0.668641,-1.116565,-0.990272},{0.483077,-0.811201,-0.329529,0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.856899,-1.012699,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.197346,0.570824,0.197346},5,{-0.94129,-0.740049,-1.077615},{0.955286,-0.295684,0,0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.197346,0.197346,0.197346},5,{-1.025683,-0.4674,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.18696,0.64394,0.18696},5,{-1.006207,-0.149309,-1.031755},{0.998131,0.060487,-0.008704,-0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.18696,0.18696,0.18696},5,{-0.986733,0.168783,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.176572,0.658191,0.176572},5,{-0.86339,0.473891,-0.985895},{0.92711,0.374789,0,-0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.176572,0.176572,0.176572},5,{-0.740049,0.778999,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.166186,0.907094,0.166186},5,{-0.642674,1.038665,-0.627012},{0.936329,0.214696,-0.277836,-0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{-0.545299,1.298331,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.478801,0.1558},5,{-0.701099,1.480097,-0.268131},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-0.856899,1.661865,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.145414,0.331011,0.145414},5,{-1.006207,1.590456,-0.268131},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.145414,0.145414,0.145414},5,{-1.155515,1.519048,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.135026,0.275417,0.135026},5,{-1.13604,1.382724,-0.268131},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.135026,0.135026,0.135026},5,{-1.116565,1.246399,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.255081,0.12464},5,{-0.993224,1.21394,-0.268131},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{-0.869883,1.181481,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.480382,-1.220431,-1.022377},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.856899,-1.012699,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-1.025683,-0.4674,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.986733,0.168783,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.740049,0.778999,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.545299,1.298331,-0.387578},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.081657,-0.42456,0.214135},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.028001,-0.292206,0.214135},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.034623,-0.289523,0.071497},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.08828,-0.421876,0.071497},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.112602,0.233065,0.214156},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.049989,0.361425,0.214156},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.055611,0.364167,0.071476},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.118225,0.235808,0.071476},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.142329,0.890505,0.214171},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.072971,1.01535,0.214171},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.077817,1.018042,0.071462},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.147176,0.893198,0.071462},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.298616,0.324582,0.298616},8,{-0.545299,1.272365,-0.359015},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.207732,0.464146,0.207732},5,{0.668641,-1.116565,-0.990272},{0.483077,0.811201,0.329529,-0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.856899,-1.012699,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.197346,0.570824,0.197346},5,{0.94129,-0.740049,-1.077615},{0.955286,0.295684,0,-0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.197346,0.197346,0.197346},5,{1.025683,-0.4674,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.18696,0.64394,0.18696},5,{1.006207,-0.149309,-1.031755},{0.998131,-0.060487,0.008704,0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.18696,0.18696,0.18696},5,{0.986733,0.168783,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.176572,0.658191,0.176572},5,{0.86339,0.473891,-0.985895},{0.92711,-0.374789,0,0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.176572,0.176572,0.176572},5,{0.740049,0.778999,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.166186,0.907094,0.166186},5,{0.642674,1.038665,-0.627012},{0.936329,-0.214696,0.277836,0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{0.545299,1.298331,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.478801,0.1558},5,{0.701099,1.480097,-0.268131},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{0.856899,1.661865,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.145414,0.331011,0.145414},5,{1.006207,1.590456,-0.268131},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.145414,0.145414,0.145414},5,{1.155515,1.519048,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.135026,0.275417,0.135026},5,{1.13604,1.382724,-0.268131},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.135026,0.135026,0.135026},5,{1.116565,1.246399,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.255081,0.12464},5,{0.993224,1.21394,-0.268131},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{0.869883,1.181481,-0.268131},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.480382,-1.220431,-1.022377},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.856899,-1.012699,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{1.025683,-0.4674,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.986733,0.168783,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.740049,0.778999,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.545299,1.298331,-0.387578},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.028001,-0.292206,0.214135},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.081657,-0.42456,0.214135},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.08828,-0.421876,0.071497},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.034623,-0.289523,0.071497},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.049989,0.361425,0.214156},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.112602,0.233065,0.214156},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.118225,0.235808,0.071476},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.055611,0.364167,0.071476},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.072971,1.01535,0.214171},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.142329,0.890505,0.214171},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.147176,0.893198,0.071462},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.077817,1.018042,0.071462},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.298616,0.324582,0.298616},8,{0.545299,1.272365,-0.359015},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},9,{0.016631,1.585832,0.217},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},9,{0.264605,1.534779,0.217},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},9,{0.269001,1.55613,-0.035234},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},9,{0.021028,1.607184,-0.035234},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{0.817949,1.259381,0.181766},10,{0,-0.129834,-0.981539},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.05453,0.408304,0.05453},8,{-0.103866,-0.655658,-1.129549},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.05453,0.662658,0.05453},8,{-0.220716,-0.149309,-1.142531},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.05453,0.512471,0.05453},8,{-0.11685,0.408975,-1.123058},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.05453,0.501162,0.05453},8,{0.103866,0.408975,-1.123058},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.05453,0.662276,0.05453},8,{0.201241,-0.149309,-1.142531},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.05453,0.401854,0.05453},8,{0.097375,-0.655658,-1.129549},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.142816,0.830932,0.142816},11,{0,-0.103866,-1.116565},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.545299,-0.714083,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.545299,0.064916,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.441433,0.766016,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.428646,0.045441},8,{-0.292125,1.577473,-0.129834},{0.817806,-0.575493,0,0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.277855,0.045441},8,{-0.331075,1.863106,-0.129834},{0.794358,0.60745,0,-0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.184528,0.045441},8,{-0.175275,1.915039,-0.129834},{-0.633238,0.773957,0,-0.773957,-0.633238,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.545299,-0.714083,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.545299,0.064916,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.441433,0.766016,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.428646,0.045441},8,{0.292125,1.577473,-0.129834},{0.817806,0.575493,0,-0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.277855,0.045441},8,{0.331075,1.863106,-0.129834},{0.794358,-0.60745,0,0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.045441,0.184528,0.045441},8,{0.175275,1.915039,-0.129834},{-0.633238,-0.773957,0,0.773957,-0.633238,0,0,0,1.0},'neon',0,0}},bounds={2.952805,3.5,2.269714}},
['Luminous Cthulhu Egg']={palette={{8,72,85},{8,76,91},{24,125,134},{14,104,118},{64,42,111},{85,176,194},{39,154,173},{78,225,255},{4,23,44},{2,16,31}},parts={{'box','EggShell',{0.21033,0.235864,0.796259},1,{-0.946484,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{-0.736154,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{-0.525824,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{-0.315495,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.73809},1,{-0.105165,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{0.105165,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{0.315495,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{0.525824,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.796259},1,{0.736154,-1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.796259},1,{-0.946484,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{-0.736154,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{-0.525824,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{-0.315495,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.73809},1,{-0.105165,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{0.105165,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{0.315495,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{0.525824,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.796259},1,{0.736154,-1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{-0.946484,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{-0.736154,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{-0.525824,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{-0.315495,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{-0.105165,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{0.105165,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{0.315495,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{0.525824,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{0.736154,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{0.946484,-0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{-0.946484,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{-0.736154,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{-0.525824,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{-0.315495,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{-0.105165,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{0.105165,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{0.315495,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{0.525824,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{0.736154,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{0.946484,-0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{-0.946484,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{-0.736154,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{-0.525824,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{-0.315495,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{-0.105165,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{0.105165,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{0.315495,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{0.525824,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{0.736154,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{0.946484,-0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{-0.946484,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{-0.736154,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{-0.525824,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{-0.315495,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{-0.105165,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{0.105165,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{0.315495,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{0.525824,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{0.736154,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{0.946484,-0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{-0.946484,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{-0.736154,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{-0.525824,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{-0.315495,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{-0.105165,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.921531},1,{0.105165,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.842257},1,{0.315495,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.672478},1,{0.525824,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.379161},1,{0.736154,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.841795},1,{0.946484,0.117931,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.747955},1,{-0.736154,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.206041},1,{-0.525824,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.432225},1,{-0.315495,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.532851},1,{-0.105165,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.532851},1,{0.105165,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.432225},1,{0.315495,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.206041},1,{0.525824,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.747955},1,{0.736154,0.353795,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.747955},1,{-0.736154,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.206041},1,{-0.525824,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.432225},1,{-0.315495,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.532851},1,{-0.105165,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.532851},1,{0.105165,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.432225},1,{0.315495,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.206041},1,{0.525824,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.747955},1,{0.736154,0.589659,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.796259},1,{-0.736154,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{-0.525824,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{-0.315495,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{-0.105165,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.73809},1,{0.105165,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.694631},1,{0.315495,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.556993},1,{0.525824,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,1.295496},1,{0.736154,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.796259},1,{0.946484,0.825522,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.334495},1,{-0.736154,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.334495},1,{-0.525824,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.334495},1,{-0.105165,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.334495},1,{0.105165,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.431833},1,{0.525824,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.579364},1,{0.736154,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.431833},1,{0.946484,1.061386,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.21033,0.235864,0.212434},1,{0.105165,1.29725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.105165,-1.225584,0.892415},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.557661,-1.225584,0.800579},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-0.892502,-1.225584,0.414334},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{-1.01823,-1.225584,-0.39813},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.892502,-1.225584,-0.414334},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.557661,-1.225584,-0.800579},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{-0.105165,-1.225584,-0.892415},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.347332,-1.225584,-0.800579},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.682174,-1.225584,-0.414334},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.8079,-1.225584,-0.39813},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.682174,-1.225584,0.414334},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.347332,-1.225584,0.800579},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.259565,-0.811715,0.944202},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.711034,-0.811715,0.70962},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.976205,-0.811715,0.430427},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.976205,-0.811715,-0.430427},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.711034,-0.811715,-0.70962},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.259565,-0.811715,-0.944202},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.259565,-0.811715,-0.944202},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.711034,-0.811715,-0.70962},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.976205,-0.811715,-0.430427},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.976205,-0.811715,0.430427},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.711034,-0.811715,0.70962},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.259565,-0.811715,0.944202},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0,-0.245744,0.984135},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.501925,-0.245744,0.858321},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.872949,-0.245744,0.437103},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-1.01192,-0.245744,-0.420898},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.872949,-0.245744,-0.437103},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.501925,-0.245744,-0.858321},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0,-0.245744,-0.984135},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.501925,-0.245744,-0.858321},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.872949,-0.245744,-0.437103},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{1.01192,-0.245744,-0.420898},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.872949,-0.245744,0.437103},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.501925,-0.245744,0.858321},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.208394,0.366276,0.789499},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.571233,0.366276,0.62306},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.785231,0.366276,0.383508},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.785231,0.366276,-0.383508},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.571233,0.366276,-0.62306},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.208394,0.366276,-0.789499},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.208394,0.366276,-0.789499},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.571233,0.366276,-0.62306},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.785231,0.366276,-0.383508},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.785231,0.366276,0.383508},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.571233,0.366276,0.62306},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.208394,0.366276,0.789499},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.105165,0.909661,0.892415},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.347332,0.909661,0.800579},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.682174,0.909661,0.414334},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{-0.8079,0.909661,-0.39813},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{-0.682174,0.909661,-0.414334},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{-0.347332,0.909661,-0.800579},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.105165,0.909661,-0.892415},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.557661,0.909661,-0.800579},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},2,{0.892502,0.909661,-0.414334},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{1.01823,0.909661,-0.39813},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},4,{0.892502,0.909661,0.414334},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.3895,0.363532,0.11685},3,{0.557661,0.909661,0.800579},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.07587,1.249531,0.12929},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.02324,1.249531,0.126256},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{-0.01166,1.249531,0.115746},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{-0.01166,1.249531,-0.115746},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.02324,1.249531,-0.126256},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.07587,1.249531,-0.12929},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.13446,1.249531,-0.12929},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},3,{0.18709,1.249531,-0.126256},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.22199,1.249531,-0.115746},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.22199,1.249531,0.115746},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},4,{0.18709,1.249531,0.126256},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.298616,0.363532,0.11685},2,{0.13446,1.249531,0.12929},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.207732,0.43002,0.207732},5,{-0.668641,-1.116565,-0.964165},{0.483077,-0.875578,0,0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.856899,-1.012699,-0.964165},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.197346,0.581987,0.197346},5,{-0.94129,-0.740049,-1.02089},{0.955286,-0.290011,-0.057639,0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.197346,0.197346,0.197346},5,{-1.025683,-0.4674,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.18696,0.637374,0.18696},5,{-1.006207,-0.149309,-1.077615},{0.998131,0.06111,0,-0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.18696,0.18696,0.18696},5,{-0.986733,0.168783,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.176572,0.664551,0.176572},5,{-0.86339,0.473891,-1.031755},{0.92711,0.371202,-0.051728,-0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.176572,0.176572,0.176572},5,{-0.740049,0.778999,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.166186,0.943155,0.166186},5,{-0.642674,1.038665,-0.604481},{0.936329,0.206488,-0.28399,-0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{-0.545299,1.298331,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.478801,0.1558},5,{-0.701099,1.480097,-0.223066},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-0.856899,1.661865,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.145414,0.331011,0.145414},5,{-1.006207,1.590456,-0.223066},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.145414,0.145414,0.145414},5,{-1.155515,1.519048,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.135026,0.275417,0.135026},5,{-1.13604,1.382724,-0.223066},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.135026,0.135026,0.135026},5,{-1.116565,1.246399,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.255081,0.12464},5,{-0.993224,1.21394,-0.223066},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{-0.869883,1.181481,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.480382,-1.220431,-1.083611},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.856899,-1.012699,-1.083611},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-1.025683,-0.4674,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.986733,0.168783,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.740049,0.778999,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{-0.545299,1.298331,-0.342512},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.081657,-0.42456,0.214135},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.028001,-0.292206,0.214135},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.034623,-0.289523,0.071497},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{-1.08828,-0.421876,0.071497},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.112602,0.233065,0.214156},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.049989,0.361425,0.214156},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.055611,0.364167,0.071476},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{-1.118225,0.235808,0.071476},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.142329,0.890505,0.214171},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.072971,1.01535,0.214171},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.077817,1.018042,0.071462},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{-1.147176,0.893198,0.071462},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.298616,0.324582,0.298616},8,{-0.545299,1.272365,-0.31395},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.207732,0.43002,0.207732},5,{0.668641,-1.116565,-0.964165},{0.483077,0.875578,0,-0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.856899,-1.012699,-0.964165},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.197346,0.581987,0.197346},5,{0.94129,-0.740049,-1.02089},{0.955286,0.290011,0.057639,-0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.197346,0.197346,0.197346},5,{1.025683,-0.4674,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.18696,0.637374,0.18696},5,{1.006207,-0.149309,-1.077615},{0.998131,-0.06111,0,0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.18696,0.18696,0.18696},5,{0.986733,0.168783,-1.077615},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.176572,0.664551,0.176572},5,{0.86339,0.473891,-1.031755},{0.92711,-0.371202,0.051728,0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.176572,0.176572,0.176572},5,{0.740049,0.778999,-0.985895},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.166186,0.943155,0.166186},5,{0.642674,1.038665,-0.604481},{0.936329,-0.206488,0.28399,0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.166186,0.166186,0.166186},5,{0.545299,1.298331,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.478801,0.1558},5,{0.701099,1.480097,-0.223066},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{0.856899,1.661865,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.145414,0.331011,0.145414},5,{1.006207,1.590456,-0.223066},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.145414,0.145414,0.145414},5,{1.155515,1.519048,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.135026,0.275417,0.135026},5,{1.13604,1.382724,-0.223066},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.135026,0.135026,0.135026},5,{1.116565,1.246399,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.12464,0.255081,0.12464},5,{0.993224,1.21394,-0.223066},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.12464,0.12464,0.12464},5,{0.869883,1.181481,-0.223066},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.480382,-1.220431,-1.083611},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.856899,-1.012699,-1.083611},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{1.025683,-0.4674,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.986733,0.168783,-1.197061},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.740049,0.778999,-1.105341},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.032459,0.11685,0.11685},6,{0.545299,1.298331,-0.342512},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.028001,-0.292206,0.214135},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.081657,-0.42456,0.214135},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.08828,-0.421876,0.071497},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.142816,0.519008,0.142816},7,{1.034623,-0.289523,0.071497},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.049989,0.361425,0.214156},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.112602,0.233065,0.214156},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.118225,0.235808,0.071476},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.142816,0.592841,0.142816},7,{1.055611,0.364167,0.071476},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.072971,1.01535,0.214171},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.142329,0.890505,0.214171},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.147176,0.893198,0.071462},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.142816,0.668861,0.142816},7,{1.077817,1.018042,0.071462},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.298616,0.324582,0.298616},8,{0.545299,1.272365,-0.31395},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},7,{0.016631,1.585832,0.217},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},7,{0.264605,1.534779,0.217},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},7,{0.269001,1.55613,-0.035234},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.253175,0.904743,0.253175},7,{0.021028,1.607184,-0.035234},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{0.817949,1.259381,0.181766},9,{0,-0.129834,-0.981539},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.05453,0.408304,0.05453},8,{-0.103866,-0.655658,-1.129549},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.05453,0.662658,0.05453},8,{-0.220716,-0.149309,-1.142531},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.05453,0.512471,0.05453},8,{-0.11685,0.408975,-1.123058},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.05453,0.501162,0.05453},8,{0.103866,0.408975,-1.123058},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.05453,0.662276,0.05453},8,{0.201241,-0.149309,-1.142531},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.05453,0.401854,0.05453},8,{0.097375,-0.655658,-1.129549},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.142816,0.830932,0.142816},10,{0,-0.103866,-1.116565},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.545299,-0.714083,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.545299,0.064916,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{-0.441433,0.766016,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.545299,-0.714083,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.545299,0.064916,-1.090599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.097375,0.097375,0.045441},8,{0.441433,0.766016,-0.998879},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={2.952805,3.5,2.255851}},
['Sabertooth Egg']={palette={{32,27,25},{169,43,17},{49,42,35},{219,68,13},{242,104,18},{105,33,23},{238,221,171},{91,42,14},{255,197,17}},parts={{'box','EggShell',{0.196879,0.242857,0.596542},1,{-0.590636,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.934604},1,{-0.393757,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.064092},1,{-0.196879,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.064092},1,{0,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.934604},1,{0.196879,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.596542},1,{0.393757,-1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.696612},1,{-0.590636,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.123254},1,{-0.393757,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.333911},1,{-0.196879,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.42763},1,{0,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.42763},1,{0.196879,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.333911},1,{0.393757,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.123254},1,{0.590636,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.696612},1,{0.787515,-1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.784011},1,{-0.984394,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.28449},1,{-0.787515,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.557673},1,{-0.590636,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.715798},1,{-0.393757,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.789629},1,{-0.196879,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.789629},1,{0,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.715798},1,{0.196879,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.557673},1,{0.393757,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.28449},1,{0.590636,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.784011},1,{0.787515,-0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,-0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,-0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,-0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,0.121429,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,0.364286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.984394,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{-0.787515,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{-0.590636,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{-0.393757,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{-0.196879,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.97851},1,{0,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.945533},1,{0.196879,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.843063},1,{0.393757,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.658269},1,{0.590636,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.357947},1,{0.787515,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.984394,0.607144,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.784011},1,{-0.984394,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.28449},1,{-0.787515,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.557673},1,{-0.590636,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.715798},1,{-0.393757,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.789629},1,{-0.196879,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.789629},1,{0,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.715798},1,{0.196879,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.557673},1,{0.393757,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,1.28449},1,{0.590636,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.784011},1,{0.787515,0.850001,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.539594},1,{-0.393757,1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.196879,1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.899323},1,{0,1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.196879,1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.539594},1,{0.393757,1.092859,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.539594},1,{-0.393757,1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{-0.196879,1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.899323},1,{0,1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.824242},1,{0.196879,1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.196879,0.242857,0.539594},1,{0.393757,1.335716,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{-0.098439,-1.261925,0.556109},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},3,{-0.383915,-1.261925,0.490039},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},3,{-0.596594,-1.261925,0.314956},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},4,{-0.6777,-1.261925,-0.298271},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{-0.596594,-1.261925,-0.314956},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{-0.383915,-1.261925,-0.490039},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{-0.098439,-1.261925,-0.556109},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{0.187036,-1.261925,-0.490039},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},6,{0.399715,-1.261925,-0.314956},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{0.480821,-1.261925,-0.298271},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},6,{0.399715,-1.261925,0.314956},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},6,{0.187036,-1.261925,0.490039},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{-0.341752,-0.835784,0.881656},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-0.765126,-0.835784,0.662879},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{-1.014211,-0.835784,0.401818},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{-1.014211,-0.835784,-0.401818},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{-0.765126,-0.835784,-0.662879},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{-0.341752,-0.835784,-0.881656},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0.144874,-0.835784,-0.881656},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0.568248,-0.835784,-0.662879},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{0.817332,-0.835784,-0.401818},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{0.817332,-0.835784,0.401818},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{0.568248,-0.835784,0.662879},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{0.144874,-0.835784,0.881656},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0,-0.253031,1.013317},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{-0.516807,-0.253031,0.851871},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-0.898834,-0.253031,0.695659},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-1.041926,-0.253031,-0.412121},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-0.898834,-0.253031,-0.695659},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{-0.516807,-0.253031,-0.851871},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0,-0.253031,-1.013317},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{0.516807,-0.253031,-0.851871},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{0.898834,-0.253031,-0.695659},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{1.041926,-0.253031,-0.412121},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{0.898834,-0.253031,0.695659},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{0.516807,-0.253031,0.851871},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{-0.267261,0.377137,0.996524},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{-0.732118,0.377137,0.699608},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{-1.005151,0.377137,0.421934},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{-1.005151,0.377137,-0.421934},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-0.732118,0.377137,-0.699608},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{-0.267261,0.377137,-0.996524},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{0.267261,0.377137,-0.996524},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{0.732118,0.377137,-0.699608},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{1.005151,0.377137,-0.421934},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{1.005151,0.377137,0.421934},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{0.732118,0.377137,0.699608},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{0.267261,0.377137,0.996524},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{-0.098439,0.936635,0.918878},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{-0.568981,0.936635,0.801574},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{-0.917137,0.936635,0.40869},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{-1.047832,0.936635,-0.392005},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{-0.917137,0.936635,-0.40869},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},4,{-0.568981,0.936635,-0.801574},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},6,{-0.098439,0.936635,-0.918878},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0.372103,0.936635,-0.801574},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},3,{0.720259,0.936635,-0.40869},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},5,{0.850954,0.936635,-0.392005},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{0.720259,0.936635,0.40869},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.401049,0.374312,0.120315},2,{0.372103,0.936635,0.801574},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{-0.123566,1.286582,0.435879},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{-0.339534,1.286582,0.29043},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},5,{-0.468871,1.286582,0.279609},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{-0.468871,1.286582,-0.279609},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{-0.339534,1.286582,-0.29043},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},4,{-0.123566,1.286582,-0.435879},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},6,{0.123566,1.286582,-0.435879},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{0.339534,1.286582,-0.29043},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},3,{0.468871,1.286582,-0.279609},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},3,{0.468871,1.286582,0.279609},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},2,{0.339534,1.286582,0.29043},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.307471,0.374312,0.120315},6,{0.123566,1.286582,0.435879},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'corner','LavaCrown',{0.147051,0.73595,0.147051},5,{-0.073526,1.431221,-0.618695},{1.0,0,0,0,0.985315,0.170748,0,-0.170748,0.985315},'slate',0,0},{'corner','LavaCrown',{0.147051,0.73595,0.147051},5,{0.073526,1.431221,-0.618695},{0,0,1.0,-0.170748,0.985315,0,-0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.73595,0.147051},5,{0.073526,1.406112,-0.763588},{-1.0,0,0,0,0.985315,-0.170748,0,-0.170748,-0.985315},'slate',0,0},{'corner','LavaCrown',{0.147051,0.73595,0.147051},5,{-0.073526,1.406112,-0.763588},{0,0,-1.0,0.170748,0.985315,0,0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.9183,0.147051},5,{-0.564755,1.508866,-0.456325},{0.993346,-0.114536,-0.012073,0.11517,0.987873,0.10413,0,-0.104827,0.99449},'slate',0,0},{'corner','LavaCrown',{0.147051,0.9183,0.147051},5,{-0.418683,1.525802,-0.456325},{0.012073,-0.114536,0.993346,-0.10413,0.987873,0.11517,-0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.9183,0.147051},5,{-0.416907,1.51049,-0.602566},{-0.993346,-0.114536,0.012073,-0.11517,0.987873,-0.10413,0,-0.104827,-0.99449},'slate',0,0},{'corner','LavaCrown',{0.147051,0.9183,0.147051},5,{-0.56298,1.493554,-0.602566},{-0.012073,-0.114536,-0.993346,0.10413,0.987873,-0.11517,0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.972829,0.147051},4,{-0.82478,1.525111,-0.046509},{0.986179,-0.165643,-0.003716,0.165685,0.985931,0.02212,0,-0.02243,0.999748},'slate',0,0},{'corner','LavaCrown',{0.147051,0.972829,0.147051},4,{-0.679761,1.549475,-0.046509},{0.003716,-0.165643,0.986179,-0.02212,0.985931,0.165685,-0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.972829,0.147051},4,{-0.679214,1.546222,-0.193523},{-0.986179,-0.165643,0.003716,-0.165685,0.985931,-0.02212,0,-0.02243,-0.999748},'slate',0,0},{'corner','LavaCrown',{0.147051,0.972829,0.147051},4,{-0.824234,1.521859,-0.193523},{-0.003716,-0.165643,-0.986179,0.02212,0.985931,-0.165685,0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.914759,0.147051},4,{-0.733145,1.490455,0.418922},{0.987871,-0.154911,0.010665,0.155278,0.985538,-0.067853,0,0.068686,0.997638},'slate',0,0},{'corner','LavaCrown',{0.147051,0.914759,0.147051},4,{-0.587878,1.513289,0.418922},{-0.010665,-0.154911,0.987871,0.067853,0.985538,0.155278,-0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.914759,0.147051},4,{-0.589445,1.523266,0.272219},{-0.987871,-0.154911,-0.010665,-0.155278,0.985538,0.067853,0,0.068686,-0.997638},'slate',0,0},{'corner','LavaCrown',{0.147051,0.914759,0.147051},4,{-0.734712,1.500432,0.272219},{0.010665,-0.154911,-0.987871,-0.067853,0.985538,-0.155278,0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.910652,0.147051},5,{-0.333959,1.492638,0.722365},{0.998078,-0.061455,0.008037,0.061978,0.989651,-0.12942,0,0.129669,0.991557},'slate',0,0},{'corner','LavaCrown',{0.147051,0.910652,0.147051},5,{-0.18719,1.501751,0.722365},{-0.008037,-0.061455,0.998078,0.12942,0.989651,0.061978,-0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.910652,0.147051},5,{-0.188372,1.520782,0.576555},{-0.998078,-0.061455,-0.008037,-0.061978,0.989651,0.12942,0,0.129669,-0.991557},'slate',0,0},{'corner','LavaCrown',{0.147051,0.910652,0.147051},5,{-0.335141,1.511669,0.576555},{0.008037,-0.061455,-0.998078,-0.12942,0.989651,-0.061978,0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.831739,0.147051},4,{0.1871,1.461385,0.722241},{0.997687,0.067286,-0.00965,-0.067974,0.987581,-0.141644,0,0.141972,0.989871},'slate',0,0},{'corner','LavaCrown',{0.147051,0.831739,0.147051},4,{0.333811,1.451389,0.722241},{0.00965,0.067286,0.997687,0.141644,0.987581,-0.067974,-0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.831739,0.147051},4,{0.335231,1.472218,0.57668},{-0.997687,0.067286,0.00965,0.067974,0.987581,0.141644,0,0.141972,-0.989871},'slate',0,0},{'corner','LavaCrown',{0.147051,0.831739,0.147051},4,{0.18852,1.482214,0.57668},{-0.00965,0.067286,-0.997687,-0.141644,0.987581,0.067974,0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.900679,0.147051},4,{0.58788,1.506247,0.418917},{0.987484,0.157332,-0.011002,-0.157717,0.985079,-0.068887,0,0.06976,0.997564},'slate',0,0},{'corner','LavaCrown',{0.147051,0.900679,0.147051},4,{0.733091,1.483055,0.418917},{0.011002,0.157332,0.987484,0.068887,0.985079,-0.157717,-0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.900679,0.147051},4,{0.73471,1.493185,0.272224},{-0.987484,0.157332,0.011002,0.157717,0.985079,0.068887,0,0.06976,-0.997564},'slate',0,0},{'corner','LavaCrown',{0.147051,0.900679,0.147051},4,{0.589499,1.516377,0.272224},{-0.011002,0.157332,-0.987484,-0.068887,0.985079,0.157717,0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.821954,0.147051},2,{0.680283,1.475284,-0.046516},{0.980581,0.196048,0.005206,-0.196117,0.980235,0.026032,0,-0.026548,0.999648},'slate',0,0},{'corner','LavaCrown',{0.147051,0.821954,0.147051},2,{0.824477,1.446445,-0.046516},{-0.005206,0.196048,0.980581,-0.026032,0.980235,-0.196117,-0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.821954,0.147051},2,{0.823712,1.442616,-0.193515},{-0.980581,0.196048,-0.005206,0.196117,0.980235,-0.026032,0,-0.026548,-0.999648},'slate',0,0},{'corner','LavaCrown',{0.147051,0.821954,0.147051},2,{0.679516,1.471456,-0.193515},{0.005206,0.196048,-0.980581,0.026032,0.980235,0.196117,0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.782234,0.147051},4,{0.419209,1.459588,-0.456479},{0.990779,0.134459,0.016673,-0.135488,0.983248,0.121927,0,-0.123061,0.992399},'slate',0,0},{'corner','LavaCrown',{0.147051,0.782234,0.147051},4,{0.564905,1.439664,-0.456479},{-0.016673,0.134459,0.990779,-0.121927,0.983248,-0.135488,-0.992399,-0.123061,0},'slate',0,0},{'corner','LavaCrown',{0.147051,0.782234,0.147051},4,{0.562453,1.421735,-0.602413},{-0.990779,0.134459,-0.016673,0.135488,0.983248,-0.121927,0,-0.123061,-0.992399},'slate',0,0},{'corner','LavaCrown',{0.147051,0.782234,0.147051},4,{0.416758,1.441659,-0.602413},{0.016673,0.134459,-0.990779,0.121927,0.983248,0.135488,0.992399,-0.123061,0},'slate',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{-1.198666,0.933767,-0.928651},{0.875578,-0.469574,-0.11342,0.483077,0.851103,0.205574,0,-0.234787,0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{-1.017239,1.033865,-0.928651},{0.11342,-0.469574,0.875578,-0.205574,0.851103,0.483077,-0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{-0.993736,0.991269,-1.130068},{-0.875578,-0.469574,0.11342,-0.483077,0.851103,-0.205574,0,-0.234787,-0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{-1.175164,0.891171,-1.130068},{-0.11342,-0.469574,-0.875578,0.205574,0.851103,-0.483077,0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{-0.860421,-1.055141,-1.010611},{-0.931243,-0.342376,-0.124762,0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{-1.003586,-0.99912,-1.010611},{0.124762,-0.342376,-0.931243,0.318835,-0.874961,0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{-0.984405,-0.950104,-1.155055},{0.931243,-0.342376,0.124762,-0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{-0.84124,-1.006125,-1.155055},{-0.124762,-0.342376,0.931243,-0.318835,-0.874961,-0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.120315,0.588205,0.588205},8,{-0.86894,0.08021,-1.042728},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.106946,0.401049,0.401049},9,{-0.922414,0.08021,-1.136306},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'neon',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{1.017239,1.033865,-0.928651},{0.875578,0.469574,0.11342,-0.483077,0.851103,0.205574,0,-0.234787,0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{1.198666,0.933767,-0.928651},{-0.11342,0.469574,0.875578,-0.205574,0.851103,-0.483077,-0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{1.175164,0.891171,-1.130068},{-0.875578,0.469574,-0.11342,0.483077,0.851103,-0.205574,0,-0.234787,-0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.207209,0.911009,0.207209},7,{0.993736,0.991269,-1.130068},{0.11342,0.469574,-0.875578,0.205574,0.851103,0.483077,0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{1.003586,-0.99912,-1.010611},{-0.931243,0.342376,0.124762,-0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{0.860421,-1.055141,-1.010611},{-0.124762,0.342376,-0.931243,0.318835,-0.874961,-0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{0.84124,-1.006125,-1.155055},{0.931243,0.342376,-0.124762,0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.153735,0.702823,0.153735},7,{0.984405,-0.950104,-1.155055},{0.124762,0.342376,0.931243,-0.318835,-0.874961,0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.120315,0.588205,0.588205},8,{0.86894,0.08021,-1.042728},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.106946,0.401049,0.401049},9,{0.922414,0.08021,-1.136306},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'neon',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},2,{0.24063,-1.002622,-0.989255},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},4,{-0.24063,-0.681784,-0.989255},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},5,{0.24063,-0.360944,-0.989255},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},2,{-0.24063,-0.040105,-0.989255},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},4,{0.24063,0.280735,-0.989255},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},5,{-0.24063,0.601574,-0.989255},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.401049,0.427786,0.187156},2,{0.24063,0.922414,-0.989255},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0}},bounds={3.030046,3.5,2.43534}},
['Skeletal Sabertooth Egg']={palette={{57,37,23},{166,135,91},{211,184,136},{191,161,110},{185,153,103},{202,172,121},{49,29,12},{255,185,16},{237,218,171},{39,26,18}},parts={{'box','EggShell',{0.215516,0.290015,0.712379},1,{-0.53879,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.135001},1,{-0.323274,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.325396},1,{-0.107758,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.383049},1,{0.107758,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.325396},1,{0.323274,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.135001},1,{0.53879,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.712379},1,{0.754306,-1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.861224},1,{-0.969823,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.410991},1,{-0.754306,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.711079},1,{-0.53879,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.884777},1,{-0.323274,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.96588},1,{-0.107758,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.96588},1,{0.107758,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.884777},1,{0.323274,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.711079},1,{0.53879,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.410991},1,{0.754306,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.861224},1,{0.969823,-1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{-1.185337,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{-0.969823,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{-0.754306,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{-0.53879,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{-0.323274,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{-0.107758,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{0.107758,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{0.323274,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{0.53879,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{0.754306,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{0.969823,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{1.185337,-1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{-1.185337,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{-0.969823,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{-0.754306,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{-0.53879,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{-0.323274,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.173363},1,{-0.107758,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{0.107758,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{0.323274,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{0.53879,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{0.754306,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{0.969823,-0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{-1.185337,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{-0.969823,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{-0.754306,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{-0.53879,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{-0.323274,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.173363},1,{-0.107758,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{0.107758,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{0.323274,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{0.53879,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{0.754306,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{0.969823,-0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{-1.185337,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{-0.969823,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{-0.754306,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{-0.53879,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{-0.323274,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.173363},1,{-0.107758,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.137136},1,{0.107758,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.024576},1,{0.323274,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.821582},1,{0.53879,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.491684},1,{0.754306,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.905417},1,{0.969823,-0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{-1.185337,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{-0.969823,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{-0.754306,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{-0.53879,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{-0.323274,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{-0.107758,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{0.107758,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{0.323274,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{0.53879,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{0.754306,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{0.969823,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{1.185337,0.145008,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{-1.185337,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{-0.969823,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{-0.754306,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{-0.53879,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{-0.323274,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{-0.107758,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{0.107758,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{0.323274,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{0.53879,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{0.754306,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{0.969823,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{1.185337,0.435022,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{-1.185337,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{-0.969823,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{-0.754306,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{-0.53879,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{-0.323274,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{-0.107758,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.362694},1,{0.107758,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.295654},1,{0.323274,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,2.155325},1,{0.53879,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.925756},1,{0.754306,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{0.969823,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.947553},1,{1.185337,0.725039,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.861224},1,{-1.185337,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.410991},1,{-0.969823,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.711079},1,{-0.754306,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.884777},1,{-0.53879,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.96588},1,{-0.323274,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.96588},1,{-0.107758,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.884777},1,{0.107758,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.711079},1,{0.323274,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.410991},1,{0.53879,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.861224},1,{0.754306,1.015054,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.765217},1,{-0.754306,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.233876},1,{-0.53879,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.46528},1,{-0.323274,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{-0.107758,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.56823},1,{0.107758,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.46528},1,{0.323274,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,1.233876},1,{0.53879,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.765217},1,{0.754306,1.305069,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.441799},1,{-0.323274,1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.592735},1,{-0.107758,1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.215516,0.290015,0.441799},1,{0.107758,1.595084,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.107758,-1.506964,0.72026},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.256171,-1.506964,0.594653},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.527001,-1.506964,0.376114},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.630025,-1.506964,-0.35619},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.527001,-1.506964,-0.376114},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{-0.256171,-1.506964,-0.594653},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.107758,-1.506964,-0.72026},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.471688,-1.506964,-0.594653},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.742518,-1.506964,-0.376114},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.845541,-1.506964,-0.35619},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{0.742518,-1.506964,0.376114},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{0.471688,-1.506964,0.594653},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.319159,-0.998076,1.176198},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.87428,-0.998076,0.987519},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-1.20033,-0.998076,0.485494},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-1.20033,-0.998076,-0.485494},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-0.87428,-0.998076,-0.987519},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-0.319159,-0.998076,-1.176198},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.319159,-0.998076,-1.176198},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.87428,-0.998076,-0.987519},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{1.20033,-0.998076,-0.485494},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{1.20033,-0.998076,0.485494},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.87428,-0.998076,0.987519},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.319159,-0.998076,1.176198},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.107758,-0.302164,1.115416},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-0.674272,-0.302164,0.937944},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-1.093405,-0.302164,0.765766},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-1.250711,-0.302164,-0.452709},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-1.093405,-0.302164,-0.765766},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.674272,-0.302164,-0.937944},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-0.107758,-0.302164,-1.115416},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.458756,-0.302164,-0.937944},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.877889,-0.302164,-0.765766},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{1.035195,-0.302164,-0.452709},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{0.877889,-0.302164,0.765766},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.458756,-0.302164,0.937944},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-0.319159,0.450369,1.176198},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.87428,0.450369,0.987519},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-1.20033,0.450369,0.485494},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-1.20033,0.450369,-0.485494},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.87428,0.450369,-0.987519},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-0.319159,0.450369,-1.176198},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.319159,0.450369,-1.176198},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{0.87428,0.450369,-0.987519},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{1.20033,0.450369,-0.485494},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{1.20033,0.450369,0.485494},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.87428,0.450369,0.987519},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.319159,0.450369,1.176198},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.215516,1.11851,1.011675},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-0.731385,1.11851,0.882692},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-1.113441,1.11851,0.450536},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{-1.257176,1.11851,-0.430613},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-1.113441,1.11851,-0.450536},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{-0.731385,1.11851,-0.882692},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{-0.215516,1.11851,-1.011675},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.300353,1.11851,-0.882692},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.682409,1.11851,-0.450536},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},4,{0.826145,1.11851,-0.430613},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},2,{0.682409,1.11851,0.450536},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.478925,0.446996,0.143678},3,{0.300353,1.11851,0.882692},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{-0.190969,1.53641,0.324739},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.337416,1.53641,0.24554},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.427519,1.53641,0.232616},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{-0.427519,1.53641,-0.232616},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{-0.337416,1.53641,-0.24554},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},3,{-0.190969,1.53641,-0.324739},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{-0.024547,1.53641,-0.324739},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{0.1219,1.53641,-0.24554},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{0.212003,1.53641,-0.232616},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{0.212003,1.53641,0.232616},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},4,{0.1219,1.53641,0.24554},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.367175,0.446996,0.143678},2,{-0.024547,1.53641,0.324739},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.373491,-0.92967,0.143405},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.27186,-0.786463,0.143405},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.260593,-0.794457,-0.031656},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.362224,-0.937666,-0.031656},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.373491,-0.243211,0.143405},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.27186,-0.100004,0.143405},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.260593,-0.108,-0.031656},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.362224,-0.251208,-0.031656},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.373491,0.443246,0.143405},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.27186,0.586455,0.143405},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.260593,0.578459,-0.031656},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.362224,0.435251,-0.031656},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.373491,1.129705,0.143405},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.27186,1.272912,0.143405},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.260593,1.264916,-0.031656},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{-1.362224,1.121709,-0.031656},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{0.862064,0.367175,0.415068},6,{-0.399104,0.750315,-1.149419},{0.936608,0.304322,-0.173648,-0.309017,0.951057,0,0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.638566,0.287355,0.207534},7,{-0.431033,0.478925,-1.245204},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.478925,0.15166,0.143678},8,{-0.446996,0.494889,-1.372916},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.319282,0.490751,0.319282},5,{-0.766279,0,-1.125473},{-0.980581,-0.19518,-0.019139,0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.319282,0.784195,0.319282},5,{-0.790225,-0.622601,-1.069597},{-0.998053,0.061072,-0.012699,-0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.319282,0.542546,0.319282},5,{-0.61462,-1.205293,-0.88601},{-0.796162,0.559065,-0.231455,-0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{-0.263284,-0.518821,-1.285238},{-0.998581,0.053182,0.002832,-0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{-0.438641,-0.528174,-1.285238},{-0.002832,0.053182,-0.998581,0.053107,-0.997168,-0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{-0.439138,-0.518848,-1.460595},{0.998581,0.053182,-0.002832,0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{-0.263781,-0.509496,-1.460595},{0.002832,0.053182,0.998581,-0.053107,-0.997168,0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.27186,-0.786463,0.143405},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.373491,-0.92967,0.143405},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.362224,-0.937666,-0.031656},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.260593,-0.794457,-0.031656},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.27186,-0.100004,0.143405},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.373491,-0.243211,0.143405},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.362224,-0.251208,-0.031656},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.260593,-0.108,-0.031656},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.27186,0.586455,0.143405},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.373491,0.443246,0.143405},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.362224,0.435251,-0.031656},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.260593,0.578459,-0.031656},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.27186,1.272912,0.143405},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.373491,1.129705,0.143405},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.362224,1.121709,-0.031656},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.175605,0.608735,0.175605},5,{1.260593,1.264916,-0.031656},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{0.862064,0.367175,0.415068},6,{0.399104,0.750315,-1.149419},{0.936608,-0.304322,0.173648,0.309017,0.951057,0,-0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.638566,0.287355,0.207534},7,{0.431033,0.478925,-1.245204},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.478925,0.15166,0.143678},8,{0.446996,0.494889,-1.372916},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.319282,0.490751,0.319282},5,{0.766279,0,-1.125473},{-0.980581,0.19518,0.019139,-0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.319282,0.784195,0.319282},5,{0.790225,-0.622601,-1.069597},{-0.998053,-0.061072,0.012699,0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.319282,0.542546,0.319282},5,{0.61462,-1.205293,-0.88601},{-0.796162,-0.559065,0.231455,0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{0.438641,-0.528174,-1.285238},{-0.998581,-0.053182,-0.002832,0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{0.263284,-0.518821,-1.285238},{0.002832,-0.053182,-0.998581,0.053107,-0.997168,0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{0.263781,-0.509496,-1.460595},{0.998581,-0.053182,0.002832,-0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.175605,1.200711,0.175605},9,{0.439138,-0.518848,-1.460595},{-0.002832,-0.053182,0.998581,-0.053107,-0.997168,-0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'wedge','NoseBridge',{0.446996,0.510852,0.367175},6,{0,0.255426,-1.213275},{-1.0,0,0,0,-1.0,0,0,0,1.0},'sandstone',0,0},{'box','NasalCavity',{0.255426,0.223498,0.127714},10,{0,-0.031929,-1.420809},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','LowerJaw',{0.287355,0.92592,0.287355},5,{0,-1.340989,-0.878027},{0,1.0,0,-1.0,0,0,0,0,1.0},'sandstone',0,0},{'corner','InnerEmber',{0.111749,0.60978,0.111749},8,{-0.030681,-0.948194,-1.071171},{0.996729,0.07854,0.019042,-0.080816,0.968666,0.234851,0,-0.235621,0.971845},'neon',0,0},{'corner','InnerEmber',{0.111749,0.60978,0.111749},8,{0.080702,-0.957224,-1.071171},{-0.019042,0.07854,0.996729,-0.234851,0.968666,-0.080816,-0.971845,-0.235621,0},'neon',0,0},{'corner','InnerEmber',{0.111749,0.60978,0.111749},8,{0.078574,-0.983469,-1.179774},{-0.996729,0.07854,-0.019042,0.080816,0.968666,-0.234851,0,-0.235621,-0.971845},'neon',0,0},{'corner','InnerEmber',{0.111749,0.60978,0.111749},8,{-0.03281,-0.974437,-1.179774},{0.019042,0.07854,-0.996729,0.234851,0.968666,0.080816,0.971845,-0.235621,0},'neon',0,0}},bounds={3.354769,3.5,2.865337}},
['Octophant Egg']={palette={{30,34,26},{157,156,119},{194,189,150},{12,15,10},{199,194,156},{101,103,77},{183,255,35},{10,13,9},{29,30,26},{181,255,37}},parts={{'box','EggShell',{0.193171,0.227505,0.64359},1,{-0.579512,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.025402},1,{-0.386341,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.197412},1,{-0.193171,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.249497},1,{0,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.197412},1,{0.193171,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.025402},1,{0.386341,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.64359},1,{0.579512,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.778062},1,{-0.965855,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.274743},1,{-0.772684,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.545853},1,{-0.579512,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.702779},1,{-0.386341,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.77605},1,{-0.193171,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.77605},1,{0,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.702779},1,{0.193171,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.545853},1,{0.386341,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.274743},1,{0.579512,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.778062},1,{0.772684,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.778062},1,{-0.965855,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.274743},1,{-0.772684,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.545853},1,{-0.579512,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.702779},1,{-0.386341,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.77605},1,{-0.193171,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.77605},1,{0,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.702779},1,{0.193171,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.545853},1,{0.386341,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.274743},1,{0.579512,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.778062},1,{0.772684,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{-0.965855,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{-0.772684,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{-0.579512,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{-0.386341,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{-0.193171,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.963496},1,{0,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.93077},1,{0.193171,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.829078},1,{0.386341,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.645686},1,{0.579512,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,1.347644},1,{0.772684,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.817989},1,{0.965855,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.399137},1,{-0.193171,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.535499},1,{0,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.399137},1,{0.193171,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.399137},1,{-0.193171,1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.535499},1,{0,1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.193171,0.227505,0.399137},1,{0.193171,1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0,-1.182154,0.648956},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.32569,-1.182154,0.535575},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.56783,-1.182154,0.33858},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.65974,-1.182154,-0.321795},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.56783,-1.182154,-0.33858},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.32569,-1.182154,-0.535575},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0,-1.182154,-0.648956},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.32569,-1.182154,-0.535575},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.56783,-1.182154,-0.33858},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.65974,-1.182154,-0.321795},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.56783,-1.182154,0.33858},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.32569,-1.182154,0.535575},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.33541,-0.782951,0.87529},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.751025,-0.782951,0.658129},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.995656,-0.782951,0.398903},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.995656,-0.782951,-0.398903},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.751025,-0.782951,-0.658129},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.33541,-0.782951,-0.87529},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.14224,-0.782951,-0.87529},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.557854,-0.782951,-0.658129},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.802485,-0.782951,-0.398903},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.802485,-0.782951,0.398903},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.557854,-0.782951,0.658129},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.14224,-0.782951,0.87529},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0,-0.237035,1.005956},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.50727,-0.237035,0.845716},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.882337,-0.237035,0.690606},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-1.022901,-0.237035,-0.408994},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.882337,-0.237035,-0.690606},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.50727,-0.237035,-0.845716},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0,-0.237035,-1.005956},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.50727,-0.237035,-0.845716},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.882337,-0.237035,-0.690606},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{1.022901,-0.237035,-0.408994},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.882337,-0.237035,0.690606},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.50727,-0.237035,0.845716},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.262324,0.353296,0.989285},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.718638,0.353296,0.694579},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.986767,0.353296,0.418865},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.986767,0.353296,-0.418865},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.718638,0.353296,-0.694579},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.262324,0.353296,-0.989285},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.262324,0.353296,-0.989285},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.718638,0.353296,-0.694579},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.986767,0.353296,-0.418865},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.986767,0.353296,0.418865},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.718638,0.353296,0.694579},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.262324,0.353296,0.989285},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0,0.877426,1.005956},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.50727,0.877426,0.845716},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.882337,0.877426,0.690606},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-1.022901,0.877426,-0.408994},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.882337,0.877426,-0.690606},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.50727,0.877426,-0.845716},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0,0.877426,-1.005956},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.50727,0.877426,-0.845716},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.882337,0.877426,-0.690606},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{1.022901,0.877426,-0.408994},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.882337,0.877426,0.690606},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.50727,0.877426,0.845716},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.074338,1.205254,0.29165},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.20505,1.205254,0.220326},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.285194,1.205254,0.20944},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.285194,1.205254,-0.20944},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.20505,1.205254,-0.220326},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.074338,1.205254,-0.29165},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.074338,1.205254,-0.29165},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.20505,1.205254,-0.220326},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.285194,1.205254,-0.20944},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.285194,1.205254,0.20944},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.20505,1.205254,0.220326},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.074338,1.205254,0.29165},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','CoilRecess',{1.022094,2.003843,0.161384},4,{0,-0.026897,-1.022094},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.47567,0.255524},2,{-0.706051,-0.961575,-0.867435},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.255524,1.519693,0.255524},2,{-0.833814,-0.006724,-0.914505},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.255524,0.485828,0.255524},2,{-0.699327,0.948126,-0.860711},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,-0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,-0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,-0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,-0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,-0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,-0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{-0.806916,0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{-0.806916,0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.161384,1.371758,1.022094},2,{-1.048991,-0.026897,0.067242},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.181556,0.699327,0.403459},7,{-1.143131,0.349664,0.201729},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{-1.143131,-0.645534,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{-1.143131,-0.48415,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{-1.143131,-0.322766,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{-1.143131,-0.161384,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.47567,0.255524},2,{0.706051,-0.961575,-0.867435},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.255524,1.519693,0.255524},2,{0.833814,-0.006724,-0.914505},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.255524,0.485828,0.255524},2,{0.699327,0.948126,-0.860711},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,-0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,-0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,-0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,-0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,-0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,-0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},5,{0.806916,0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},6,{0.806916,0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.161384,1.371758,1.022094},2,{1.048991,-0.026897,0.067242},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.181556,0.699327,0.403459},7,{1.143131,0.349664,0.201729},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{1.143131,-0.645534,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{1.143131,-0.48415,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{1.143131,-0.322766,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},8,{1.143131,-0.161384,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,0.763209,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,0.568204,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,0.373199,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,0.178194,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,-0.016811,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,-0.211815,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,-0.40682,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,-0.601825,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},7,{0,-0.79683,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{1.223824,0.255524,0.242075},2,{0,-1.210375,-0.860711},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{-0.403459,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{0,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{0.403459,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{1.223824,0.255524,0.242075},2,{0,1.210375,-0.860711},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{-0.403459,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{0,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},6,{0.403459,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.215177,0.780019,0.780019},9,{0,1.479346,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.376561,0.376561,0.376561},7,{0,1.73487,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.107589,0.618636,0.618636},2,{0,1.963496,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.161384,0.073967,0.161384},10,{0,2.044189,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},7,{-0.295869,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},7,{0,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},7,{0.295869,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={2.501441,3.5,2.281346}},
['Mecha Scrambler Egg']={palette={{21,23,21},{55,58,53},{66,70,62},{43,46,41},{12,15,10},{76,80,71},{137,142,122},{236,250,56},{10,13,9},{29,30,26},{231,248,70}},parts={{'box','EggShell',{0.177074,0.227505,0.592016},1,{-0.619756,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.943234},1,{-0.442684,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.101459},1,{-0.26561,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.149371},1,{-0.088536,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.101459},1,{0.088536,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.943234},1,{0.26561,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.592016},1,{0.442684,-1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{-0.973904,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{-0.79683,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{-0.619756,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{-0.442684,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{-0.26561,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.806154},1,{-0.088536,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{0.088536,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{0.26561,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{0.442684,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{0.619756,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{0.79683,-1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{-0.973904,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{-0.79683,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{-0.619756,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{-0.442684,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{-0.26561,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.806154},1,{-0.088536,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{0.088536,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{0.26561,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{0.442684,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{0.619756,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{0.79683,-0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,-0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,-0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,-0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,0.113753,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,0.341259,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{-0.973904,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{-0.79683,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{-0.619756,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{-0.442684,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{-0.26561,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{-0.088536,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.963496},1,{0.088536,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.907784},1,{0.26561,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.791165},1,{0.442684,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.600382},1,{0.619756,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.303264},1,{0.79683,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.787455},1,{0.973904,0.568764,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{-0.79683,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{-0.619756,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{-0.442684,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{-0.26561,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{-0.088536,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.806154},1,{0.088536,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.77605},1,{0.26561,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.682506},1,{0.442684,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.513811},1,{0.619756,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,1.239651},1,{0.79683,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.75244},1,{0.973904,0.79627,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.367152},1,{-0.26561,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.492587},1,{-0.088536,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.367152},1,{0.088536,1.023775,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.284395},1,{-0.088536,1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.177074,0.227505,0.284395},1,{0.088536,1.251281,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.088536,-1.182154,0.598892},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.387746,-1.182154,0.49449},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.610501,-1.182154,0.312794},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{-0.695315,-1.182154,-0.296009},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{-0.610501,-1.182154,-0.312794},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.387746,-1.182154,-0.49449},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{-0.088536,-1.182154,-0.598892},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.210672,-1.182154,-0.49449},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.433429,-1.182154,-0.312794},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.518243,-1.182154,-0.296009},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.433429,-1.182154,0.312794},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.210672,-1.182154,0.49449},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.32932,-0.782951,0.911925},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.748326,-0.782951,0.640584},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.994915,-0.782951,0.386091},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.994915,-0.782951,-0.386091},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.748326,-0.782951,-0.640584},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.32932,-0.782951,-0.911925},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.152246,-0.782951,-0.911925},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.571253,-0.782951,-0.640584},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.817843,-0.782951,-0.386091},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.817843,-0.782951,0.386091},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.571253,-0.782951,0.640584},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.152246,-0.782951,0.911925},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0,-0.237035,1.005956},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.50727,-0.237035,0.918456},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.882337,-0.237035,0.668418},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-1.022901,-0.237035,-0.393728},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.882337,-0.237035,-0.668418},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.50727,-0.237035,-0.918456},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0,-0.237035,-1.005956},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.50727,-0.237035,-0.918456},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.882337,-0.237035,-0.668418},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{1.022901,-0.237035,-0.393728},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.882337,-0.237035,0.668418},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.50727,-0.237035,0.918456},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.262324,0.353296,0.977792},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.718638,0.353296,0.820949},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.986767,0.353296,0.403599},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.986767,0.353296,-0.403599},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.718638,0.353296,-0.820949},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{-0.262324,0.353296,-0.977792},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.262324,0.353296,-0.977792},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.718638,0.353296,-0.820949},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.986767,0.353296,-0.403599},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.986767,0.353296,0.403599},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.718638,0.353296,0.820949},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.262324,0.353296,0.977792},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.088536,0.877426,0.927285},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.377121,0.877426,0.779779},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.721726,0.877426,0.63661},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{-0.85114,0.877426,-0.37622},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.721726,0.877426,-0.63661},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{-0.377121,0.877426,-0.779779},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.088536,0.877426,-0.927285},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.554195,0.877426,-0.779779},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},2,{0.8988,0.877426,-0.63661},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{1.028214,0.877426,-0.37622},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},3,{0.8988,0.877426,0.63661},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.403459,0.376561,0.121037},4,{0.554195,0.877426,0.779779},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.046923,1.205254,0.166099},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{-0.130151,1.205254,0.162955},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{-0.182881,1.205254,0.152069},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.182881,1.205254,-0.152069},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{-0.130151,1.205254,-0.162955},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{-0.046923,1.205254,-0.166099},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{0.046923,1.205254,-0.166099},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.130151,1.205254,-0.162955},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.182881,1.205254,-0.152069},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},4,{0.182881,1.205254,0.152069},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},3,{0.130151,1.205254,0.162955},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.309318,0.376561,0.121037},2,{0.046923,1.205254,0.166099},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','CoilRecess',{1.022094,2.003843,0.161384},5,{0,-0.026897,-1.022094},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.47567,0.255524},2,{-0.706051,-0.961575,-0.867435},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.255524,1.519693,0.255524},2,{-0.833814,-0.006724,-0.914505},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.485828,0.255524},2,{-0.699327,0.948126,-0.860711},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,-0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,-0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,-0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,-0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,-0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,-0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{-0.806916,0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{-0.806916,0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.161384,1.371758,1.022094},2,{-1.048991,-0.026897,0.067242},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.181556,0.699327,0.403459},8,{-1.143131,0.349664,0.201729},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{-1.143131,-0.645534,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{-1.143131,-0.48415,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{-1.143131,-0.322766,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{-1.143131,-0.161384,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.47567,0.255524},2,{0.706051,-0.961575,-0.867435},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.255524,1.519693,0.255524},2,{0.833814,-0.006724,-0.914505},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.255524,0.485828,0.255524},2,{0.699327,0.948126,-0.860711},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,-0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,-0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,-0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,-0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,-0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,-0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,0.174833,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,0.174833,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,0.524496,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,0.524496,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.363113,0.174833,0.295869},6,{0.806916,0.87416,-0.981749},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.037656,0.09414,0.09414},7,{0.806916,0.87416,-1.149856},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.161384,1.371758,1.022094},2,{1.048991,-0.026897,0.067242},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.181556,0.699327,0.403459},8,{1.143131,0.349664,0.201729},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{1.143131,-0.645534,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{1.143131,-0.48415,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{1.143131,-0.322766,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.215177,0.073967,0.416906},9,{1.143131,-0.161384,-0.242075},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,0.763209,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,0.568204,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,0.373199,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,0.178194,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,-0.016811,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,-0.211815,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,-0.40682,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,-0.601825,-1.170029},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.060519,0.623042,0.060519},8,{0,-0.79683,-1.170029},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{1.223824,0.255524,0.242075},2,{0,-1.210375,-0.860711},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{-0.403459,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{0,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{0.403459,-1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{1.223824,0.255524,0.242075},2,{0,1.210375,-0.860711},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{-0.403459,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{0,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.033621,0.078003,0.078003},7,{0.403459,1.210375,-1.008645},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.215177,0.780019,0.780019},10,{0,1.479346,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.376561,0.376561,0.376561},8,{0,1.73487,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.107589,0.618636,0.618636},2,{0,1.963496,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.161384,0.073967,0.161384},11,{0,2.044189,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},8,{-0.295869,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},8,{0,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.147935,0.134486,0.053795},8,{0.295869,-1.351585,-0.739674},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={2.501441,3.5,2.269852}},
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
local title=label(head,'DIVINE ITEM SPAWNER · REFERENCE EGGS',UDim2.fromOffset(16,8),UDim2.new(1,-70,0,24),15)title.Font=Enum.Font.GothamBold
label(head,'25% larger • richer reference colors',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
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