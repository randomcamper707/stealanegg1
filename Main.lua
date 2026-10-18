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

-- SAE V7: eggs are solid 3D voxel models matched to the reference images (not flat pictures)
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

-- 64-sample reference surfaces baked from the supplied JPGs; no external assets.
local VOX={
['Unicorn Egg']={41,64,1.86666667,2.8,1.63333333,{{255,255,255,0},{254,246,229,0},{254,250,142,0},{253,242,132,0},{254,232,243,0},{253,210,221,0},{254,185,194,0},{245,237,197,0},{241,218,217,0},{238,205,214,0},{240,186,195,0},{214,202,200,0},{211,184,194,0},{115,210,202,0},{242,163,167,0},{244,148,154,0},{244,134,160,0},{245,129,136,0},{240,114,158,0},{241,106,119,0},{249,84,118,0},{194,162,166,0},{193,143,157,0},{191,113,171,0},{189,85,161,0},{139,135,138,0},{92,125,113,0},{105,93,119,0},{192,74,103,0},{78,63,68,0},{57,57,55,0},{47,37,39,0},{28,30,29,0},{19,18,19,0},{10,8,8,0},{2,2,3,0},{0,9,6,0},{0,0,1,0},{0,0,0,0}},{93149216768,93686087681,91538604034,71942815747,59594784772,42146480133,94222958720,94491394177,86438330498,69526896771,60131655812,43757092997,24966611078,93954523392,96102007041,92612346114,69258461443,58252607748,44562399493,26308788486,24966611207,93686088064,95833571713,94491394434,86706766211,69258461572,58789478789,44562399622,25771917703,111402828289,113281876482,92612346371,86440428036,69258461701,59594785286,61742268935,42414916104,112476570242,111134392963,86438331013,91538604678,78922138247,60668527240,59326349961,128851133186,130461745923,109792215812,103618216709,110865957639,96102007560,78116832009,42146480906,128045826946,129388004227,129119568772,121066521477,120798069639,109792215944,78922138505,60131656586,128582697987,130461746180,126972085253,137977938950,138248471559,120800166920,94222959625,78922138634,42414916619,110865958019,113281877124,127240520837,120798069894,108986909833,96102007946,78116832395,42683352204,95028266244,112208135429,125898343686,137977939207,121068602632,103618200841,92880782602,95028266251,77848397068,58789479693,93954524548,113281877381,128314262918,120798070151,121068602761,103618200970,110060651915,96102008204,77311526285,94759831045,113283974662,125898343943,120798070280,121066522122,128851133964,112476571149,76774655502,77043091077,144151955079,137977939592,138246391433,137977939595,144151955084,130461746829,113281877646,76774655631,93686089477,130461746950,163210872583,155426260744,172606146314,178511693581,163479308046,146836309775,110865958672,93686122259,75969349398,146031003526,182001354631,178780129160,189517547401,206965868426,224145721228,206697416589,213139867534,199181223823,180390741904,163210872722,164016179091,164821485460,147641616277,146567874454,144688826263,198107482119,215287351304,211797690377,223877285898,241325590539,258505492492,249110218767,249915525136,231930349585,232735655954,233540962323,230319736852,213139867669,216361093142,215018915863,196228433944,162674001946,146031003675,129119569948,111402829853,214213609607,232735656072,241325590665,258237024394,275685329035,292865198220,310045067405,292596762766,298770778255,302260471952,299039213715,295549552788,278369683605,283469957270,267900700823,250720831640,232198785177,215287351450,199181224091,180927613084,147641616541,111402829982,230588172551,250720831752,282664651017,292596762890,310045067531,327227033868,344406919437,361586772239,366416513296,369100867857,367758690578,364275337491,347089176853,333398952215,317829695768,285080570137,267900700954,248304912667,213676738844,180927613213,129388005662,93686090015,215287351688,250720831881,280517167498,292596763019,361316239760,380912028049,381448898962,364273240469,347091257751,329911388568,318098131353,283201522074,263068862875,245888993692,196765305245,164821485982,111939701151,179585436168,215555787273,249110219274,275685329419,292865198604,310045067789,327224936974,344404822543,361316239889,364269029906,316219083289,297428601370,280248732187,263068863004,228709124637,197302176286,164821486111,111671265824,180659178121,215018916490,241325591179,275685329548,292865198733,310045067918,327224937103,344404806288,361584675473,363732159122,364271127191,347089160856,331519904409,314608487066,280248732316,245888993949,228709124766,197570611871,164821486240,129119570593,94759832226,77579963043,59594787492,146299439881,180659178250,206965852939,258237025036,275685329677,292865198862,310045068047,327233325840,344411097873,361590967058,361316240147,364269046548,381450996502,368295562008,348968209177,331788356378,314608470812,280248732445,245888994078,230856608543,198107482912,164821486369,128582699810,95296703267,77579963172,111134395273,147641617290,197033741195,223877286796,258505460621,275691621262,292867296143,361586772883,364269030292,381450996629,385475431319,366148094872,348968225690,331788340124,314608470941,280248732574,263068863391,231125044128,214482045857,157305293730,128045829027,96102009764,42414918565,129119570954,182001355787,230051302412,241057156109,381448899604,384670125078,383327980567,366148095002,348968209436,331788340253,314608471070,297428601887,263068863520,245352123425,190591290402,160794954787,112476572708,77579963429,145225698442,181732920459,231127141516,258239122573,310049262735,378764545171,380912028820,398628768917,401313123478,400507817111,399970946200,400507817113,383327980698,348968209565,331788340382,314608471199,297428602016,279711861921,224951028898,190591290531,162405567652,113281879205,76774657190,181196049675,361316240657,383059512594,382522641683,397018156308,395139108117,417150848278,417687686425,400507850010,383327948061,366148078878,348968209695,331788340512,296891731233,260384509218,224951029027,195154693412,164016180517,128851135782,145494134154,198912789899,231393480076,259579202957,292865199502,344138468752,361584676241,383327948178,400509914515,399702510996,413661154709,434330717590,434869652889,417687719322,400507817373,383327948190,366148079007,348968209824,331251469729,298233908642,263874170275,226024770980,196765306277,180927614374,93686091273,146836311562,198644354571,247499607564,275148459533,292596764174,327224937999,382522641937,400507817490,417687686676,434599120405,434330684950,451510554135,434330684952,434867588634,417687703069,400507817503,383327948320,366953385505,332593647138,315413777955,278101249572,247768043045,215287352870,59326353032,113013444233,147641618058,197033741963,244009946764,311118810766,326956502671,361584676496,400507817617,417687703186,434867572372,452047425174,452852747927,453121216153,435941314205,418761445023,401313124001,366953385634,349777710755,315415875236,282664652453,266558525094,111671267080,146031005449,195960000266,243473075979,277832814348,310313504525,327493373710,361047805711,381717335824,417687686929,434867572498,452047441684,469227294486,470032617239,470301085465,453121167133,435941314334,418761428768,398360334113,384137449250,300112957221,267095396134,146031005576,196765306761,223340416906,413929590672,434867556241,452047441810,469227310996,486407163798,487212486551,487480938393,470301052828,453121167262,435941314463,414734897057,332599938980,300381392805,266558525350,197570613256,248304914441,274880024586,431914766352,451510554641,469227294738,486407163923,485870293012,487480905749,504660774934,504392355863,504662888473,487480922139,470301052957,453123264543,435672862752,415271768097,366957580323,300649828389,266021654566,128314265733,180390744198,215018918023,250720833672,282933088393,485333422225,487480905874,504660807827,521840644246,521572225175,504660791451,487480905885,470301036702,452856926368,431648428193,401313124514,301186699429,284277362854,282127782055,163210875141,215287353606,265484783879,299844522248,333130518793,481038455056,501439549713,521840693522,539020513558,538752078103,521572258072,504392356124,487212470558,471110537503,398364528930,316487520549,282664653095,162942439813,214482047366,257700155783,292059894152,327493374345,362926854538,430574686604,464936522126,481038455183,499292082576,521572209042,521840644499,517814112660,533922353557,533653901719,534725546392,516471951770,501173227932,484263874974,432453734817,364002693539,346556486052,312196747685,283738395046,283469959591,281859346856,163210875397,214752580102,258773897735,293135733256,328567116297,361855209994,396217045515,447754555917,482116391439,500365808144,499296260625,518619419154,522645950995,517547774484,532578062872,452315861536,282664653350,285080572455,282945671720,162942440069,257700156039,327493374601,431650525836,499298357904,517814112914,521572209299,533651804821,533920256662,533664387736,515398193817,516480324250,501173211804,501450035869,470032601759,449899942560,431650525857,397286593186,362926854819,277298041510,283472056999,163479311109,214482047750,258778092295,293402071816,328567116553,362928952074,449098830605,465200763662,516471968530,534993982229,535530853142,533920240407,516480324377,516480324379,483997537054,464934425375,447758750496,398362432290,364013179683,346822824740,312460989221,163210875781,213968245638,294482105224,328835552137,397288690571,466542941070,483458569103,516474049427,535801402261,533658096535,500634243996,314881102757,277839106982,283212010407,163502380037,329372423177,361855210506,431918961676,466274505742,499294163985,516474033170,501175309340,465202861087,431921058849,400780448802,349238744100,259044430983,328835552393,396212851851,449631507597,466542941326,499560502416,516740371603,516471936148,535801386133,535532950678,327766005001,362926855434,397286593803,449094636813,467079812366,483722810639,500634260752,516740371730,516471936275,516748760340,516742468890,484261778718,464932328735,448029283616,346820728100,312460989733,260116075911,294746346888,363197388170,397823464843,431109461388,449365169549,465200764302,482380633487,500634244496,499562599825,516471936402,516746663315,535535048085,535805580694,533922338199,516740371865,516744566171,501443745180,503859664285,465202861471,398362432930,349238744484,314876908965,278109640102,283469960616,260384511495,398901401099,432183203340,466542941710,482649069071,499828938256,516744566290,533920241176,517814130201,486683989534,431646332449,315157927461,283746784808,259314964103,293672605320,328032343689,362392082058,433256945292,450436814477,467616683662,484796552847,501982713488,500634244753,535264532119,516740388505,466276603551,431914768033,400786740898,366416516771,349515568804,282664654503,433527478028,450705250061,467885119246,485064988431,499560503057,535264515861,516740372249,517017212698,503863858972,504132294429,432185300769,364000597795,282937284391,295820089224,330177730441,364537468810,399165642635,452584298381,468424087438,485333424015,499828938641,517008840594,536342452118,534188693399,517015099289,465471297439,448291428256,366420711331,261462448135,330450360329,364805904394,399434078219,434064349196,451778992141,484796553231,501976422417,519158388754,517008824339,536338257941,536338257943,534192871448,433259042849,278638123046,296088524936,365074339978,399165642891,451242121357,467885119630,485064988815,502244874384,517008808083,519158388884,486946134174,467616684191,450436815008,281590913190,283738396839,283469961384,365342775562,399704611083,434599123212,451510556941,468421990670,485333424399,502781745424,519424727314,519156291859,536604596501,534188677399,467885119775,450705250592,433525381409,366684952867,283469961510,285080574247,282933090600,215289452934,265484786055,299576088968,330983037321,364808001930,417419254156,451779008909,468421990799,485601859984,502513293713,502244874642,519693162900,521303775637,519424727446,519156291991,519424727448,501976455577,484796553628,469495732637,452584298910,434062268831,399702514081,366416517538,332325214627,297965476260,266021656997,233540966822,231930354087,162674006533,267900705287,301457234440,334204262921,381987871243,416882383372,434062252557,451778992654,468958878223,485601860113,502781778450,504123906582,502781745687,485064989209,484796570138,467885120028,452584299037,435404429854,417419254303,400239385120,365342775841,332325214754,297965476387,266021657124,233540966949,180659182118,265484786311,317024393865,347357600394,416345512588,433525381773,434062252686,451244219023,468958861968,486138763921,485601860244,486138731157,486944037526,485601876631,467885136537,450705250971,452584299164,435135994525,401044691614,383059516063,365879646880,331519908513,297965476514,266021657251,216361097892,180659182245,283738397448,318098135817,351115696906,364805905163,398897208076,416345512717,433793817358,451244219152,468958927633,485601860374,468422007575,450705267481,433793817371,416345512732,401044691741,383864822558,349505084191,330983037728,296623299361,266021657378,216361098019,163479313188,283201526664,319440313225,336620182410,369637743499,402655304588,416077077389,416345512846,434062252943,451242122129,468421991314,468958911379,451242138519,434062269337,416882383771,401044691868,383864822685,349505084318,332325215135,297965476768,266021657505,216361098146,180659182499,282127784969,300381395978,336620182539,351921003532,365342776333,381985774606,399434079247,416882400272,434062285842,434599156757,417419254808,400239402009,383059516443,365342776348,349505084445,315145346078,280785607711,266021657632,233540967457,180659182626,266021657739,285080575116,300918267021,316487523470,330983038095,347626036368,365342776465,382522711186,383059532951,366148082841,348699794586,330983038108,297965477021,263605738654,248841788575,216361098400,180659182753,196228439307,214482050316,232467225869,250720836878,284006833423,299844525328,315145346321,330714602770,330983054611,348162940181,330983038232,331519909145,314340039962,297428606235,279980301596,263605738781,231393484062,199181229343,163479313696,161868701069,180122312078,215287356815,233540967824,267095399825,282664656274,282396220819,296623365524,279443430809,279980301722,262263561627,246425869724,214213615005,182001360286,146299444639,179853876752,215018921489,233540984338,248841788948,248036482581,262263578134,245083692568,245620563481,228440694298,212066131483,197033745948,164821491229,146299444766,179585441426,197839052435,216361115284,231661919894,230856613527,210723954328,210187083417,194080956058,179853876891,164821491356,129119575709,213945179924,214750486293,233272532758,233540968215,215018921752,213945179929,197302181658,182001360667,163479314204,127508963101,230588178326,231661920151,214482050968,214750486425,197570617242,179853877147},{1350615040,1080049667,811614212,543178757,272646278,272646407,1346388355,1075855748,807420293,538984838,1612743169,1346388484,1075855877,807436806,538984968,1612743298,1344307845,1075856007,807436936,1883276034,1612776196,1344291592,1077953289,538985226,1881211780,1612727176,807420810,1881195523,2149614598,1889551368,1344291849,1075856394,538985483,1612743811,1881179269,2151695495,1614824585,1346389130,1075856523,538985612,1346389252,1614824709,1883260166,1344292107,1075856652,807421197,1883260295,1883260297,1612744074,1344292236,1075856781,1344292357,1614824966,1881196042,1612727821,1075856910,1075857029,2149680775,1881163405,1612727950,1075857039,1344292613,1881163526,2418067207,2686519050,2418034446,2149598991,1612728080,1344325395,1075857174,2149599110,2686486407,2954905481,3223357322,3491776396,3223357325,2954905487,2686470032,2418067346,2149631893,2954905607,3223357448,3491776522,3760211979,4028680204,3760228367,3491825681,3223373845,2954905624,2418034714,2149599259,1881163804,1612728349,3223341191,3491776648,3760212105,4028647562,4297083019,4565518476,4833953933,4565616782,4297099413,4028647575,3760212120,3491776665,3223341210,2954905755,2686470300,2149599389,1612728478,3491776775,3760212232,4297083145,4565518602,4833954059,5104486668,5372938509,5639342351,5370841365,5102389527,4833954072,4297083161,4028647706,3760212251,3223341340,2686470429,1881164062,1344293151,3223341448,3760212361,4297083274,4565518731,5639276943,5907712401,5643504019,5372922263,5104486808,4836051353,4297083290,4028647835,3760212380,2954906013,2418035102,1612728735,2686470664,3223341577,3760212490,4297083403,4565518860,4833954317,5102389774,5370841615,5641374225,4565518874,4297083419,4028647964,3491777053,2954906142,2418035231,1612728864,2686470793,3223341706,3760212619,4297083532,4565518989,4833954446,5102389903,5370825360,5641357975,5370825368,5102389913,4833970842,4297083548,3760212637,3491777182,2954906271,2418035360,1881164449,1344293538,1075858083,807422628,2149600009,2686470922,3223341835,4028648204,4297083661,4565519118,4833954575,5110778640,5377116945,5639310098,5911890710,5641358104,5370825497,5102406426,4833954588,4297083677,3760212766,3491777311,2954906400,2418035489,1881164578,1344293667,1075858212,1612729225,2149600138,2954906507,3500166028,4028648333,4303375246,4567616399,5639293842,5909793685,5909793687,5639261081,5370842010,5102390172,4833954717,4297083806,4028648351,3491777440,3223341985,2418035618,1881164707,1344293796,538987429,1881164810,2690665483,3760213005,5639277586,5909793812,5907713048,5639277594,5370825756,5102390301,4833954846,4565519391,4028648480,3760213025,2954906658,2418035747,1612729380,1075858469,2149600394,4032842893,4838149263,5639261330,5909793939,6176197781,5907729562,5370825885,5102390430,4833954975,4565519520,4297084065,3491777698,2954906787,2418035876,1612729509,1075858598,5641358609,5909794066,6176148756,6444616982,6176165146,5907696925,5639261470,5370826015,5102390560,4565519649,4028648738,3491777827,2954906916,2418036005,1881165094,2153794954,2959101323,4567616910,5372923280,6176148883,6444567957,6713052566,6444600730,6176132509,5907697054,5639261599,5370826144,5102390689,4565519778,4028648867,3491777956,2954907045,2686471590,1344294409,3762310668,4297084429,5104487951,5907697169,6176149010,6444568084,6713019925,6983536151,6713069080,6444584477,6176132639,5907697184,5639261729,5102390818,4833955363,4297084452,3760213541,3223342630,807423624,1612729993,4833955470,5639261840,6176132753,6444584594,6713020052,6981439126,6981504664,6713020061,6444584607,6178229921,5639261858,5375020707,4836052644,4297084581,4034940582,1612730120,2149601033,2954907402,3760213771,4297084684,4833955597,5102391054,5639261967,5907697424,6444568337,6713020178,6981455636,7249973014,6981439261,6713020190,6444568352,5911891746,4571811621,2149601160,2954907529,3491778442,6444568464,6713003921,6981455762,7249891220,7518392214,7249891228,6981439390,6713020319,6446665633,5108682660,2954907656,3760214025,4297084938,6713004048,6981439505,7249874962,7518343187,7786811414,7518326811,7249891357,6983536671,6713004064,5677010979,1881165957,2686472326,3223343239,3760214152,4297085065,7518326929,7786778771,8055214230,7786795161,7518310557,7249875102,7017091232,6748655777,6211784866,4332753062,2455785733,3261092102,4068495623,4605366536,5140140297,7518310672,7795134737,8055230738,8357187862,8055230744,7820316956,7551865118,7283429663,4867510565,5674914186,6744461708,7281332622,7549768079,7818203536,8061505938,8355074453,8355074456,8055198106,5402284452,4328542632,6207590923,7012897293,8082461337,8080347931,8078267283,7809815569,8076153874,6448765324,6983539086,7251974543,7518312848,7788861842,8055249300,7786781081,7518312860,7249877405,6981441950,6713022879,6176135585,5639264674,5102393763,4565522852,4028651941,3491797414,5909797387,6715103757,7251974672,7520410129,7786813972,7518345753,7249877532,6981442077,6713006622,6444571167,6176135712,5639264801,5102393890,4565522979,4028652068,3491781157,2686474790,4838152841,5372926602,6715103886,6983539343,7518411410,7249894041,6981458587,6713006749,6176135838,5907700383,5639264928,5102394017,4565523106,4028652195,3223345828,2686474917,4299184904,5641362187,6178233100,6446668557,6983539472,7249943313,7518313238,7249894167,6981458713,6713006875,6444571420,6176135965,5907700510,5370829599,5102394144,4565523233,4028652322,3223345955,2418039588,5102394250,6444571534,6713006991,6981442449,7249943442,6981458839,6713023385,6444571547,6176136092,5907700637,5370829726,5102394271,4565523360,4028652449,3223346082,2686475171,4297088009,4565523466,5102394379,5370829836,5639265293,5907700750,6176136207,6444588048,6713089042,6444571672,6176152601,5907700763,5639265308,5370829853,4833958942,4297088031,4028652576,3491781665,2686475298,4028652683,4297088140,4565523597,4833959054,5102394511,5370829968,5639265425,5907799186,5639265433,5370846362,5102394524,4565523613,4028652702,3760217247,3223346336,2686475425,2954910987,3223346444,3491781901,3760217358,4297088271,4565523728,4833959185,5102427410,5370862869,5102411032,4833959194,4565523739,4297088284,4028652829,3491781918,2954911007,2418040096,2418040205,2686475662,3223346575,3491782032,4028652945,4297104786,4565589396,4297104793,4028652955,3760217500,3223346589,2686475678,2149604767,2686475792,3223346705,3491798546,3760234004,4028669462,3760234008,3491782170,3223346715,2954911260,2418040349,2149604894,2686475922,2954911379,3225460372,3495992982,3227557528,2959105690,2690670235,2420137628,1883266717},{225,157,190}},
['Kitsune Egg']={58,64,2.56666667,2.8,2.56666667,{{255,255,255,0},{232,219,217,0},{205,205,176,0},{203,198,168,0},{203,196,166,0},{198,196,163,0},{203,192,167,0},{198,192,161,0},{197,192,159,0},{193,191,162,0},{192,188,157,0},{192,188,153,0},{225,174,206,0},{194,178,159,0},{187,183,150,0},{186,178,149,0},{183,179,146,0},{178,174,143,0},{171,167,140,0},{211,155,190,0},{214,139,194,1},{232,115,216,1},{205,114,185,0},{164,156,129,0},{157,127,131,0},{221,92,204,1},{221,69,199,1},{223,60,201,1},{224,54,200,1},{216,54,194,1},{216,46,194,1},{200,87,179,0},{201,64,180,0},{201,45,181,0},{147,76,131,0},{139,40,127,0},{0,3,65,0}},{190591287321,189517594650,172337676318,154889388063,189785981080,195154690201,193544077466,192738787483,189785981085,172606111902,158379032735,154889371808,137977938081,189249110295,192470335768,195423125785,193812513050,192470352155,194080948509,175290466590,159452774687,158110597408,137709502753,175022031253,177437950358,195691561367,195959996824,195691577753,195959996827,195691594140,178511692191,161600258464,161331823009,143078212002,123482423715,178511692309,197841142294,196765303319,213945172504,213408350745,213139866141,196228448798,179048579616,162137129506,143078212131,123482423844,180390740629,213945172631,215018914456,213408334489,230588170908,213408301725,214213608094,213408301727,197033738912,196496868001,179585434274,161868694179,140662293156,172069241620,197302190869,214482060055,230051316505,229246026523,231661912862,212066140959,214482043681,194886255394,180122305315,157842162468,120798069649,137977938834,155157808019,172337677204,189517546389,206697415574,223877350295,241057170332,223877333918,206697415586,189517546403,172337677220,172069241765,155157808038,137709503399,103618200592,137977938961,158647469074,174753596435,190054433812,207234286614,224145736727,241325605913,241594024987,241325622300,241594024991,224145753120,206965851171,190056514596,173142983717,157573727270,155157808167,120800166952,120798069904,157305291921,176632644754,190859723923,206965851284,208039593109,224145720470,241325606039,241594041497,258773894299,258505475228,241594025118,241325622431,224682591394,208039593123,190322853029,176095773862,157573727399,155157808400,176364209425,193812514066,208039593235,224145720596,229514429717,244278379798,258237023511,261726684440,260384507161,258237023514,258505458971,258773910812,262531990814,258505458975,241325589792,241862460705,242667767074,228172252451,207234286884,189785982245,176366306598,158915904807,121066505512,175290467728,193812514193,228172252562,224951027091,242130896276,246694299029,261726684566,259310765463,262531990936,279443424665,277564376474,277027505563,275955877276,263874168222,261458265503,242130912673,229514429859,209650206116,190591288741,159184340391,123750860200,157842163214,177706386959,214482044432,231661913617,248841782802,247231170067,264411039252,266021651989,283201537558,281054070296,278638118427,279711860254,263874168351,262532007456,248841782818,231661913635,214482044452,197302175269,180122306086,162942436903,145762567720,109792216617,74358736426,37583078955,175022032525,196230530702,215023109775,230856607376,247770138257,264950007442,265216362131,282127795861,300654020247,295551649432,292865197721,293133633178,293402068635,293938955932,276222199454,276759070367,258237023904,263605733025,265484781218,247770138275,230588171940,213676738213,196496869030,179048564391,145225696936,111939700393,76237784746,57178867371,177440048909,230588172048,264947910419,282127795988,299307648790,293938939673,294744262426,293938939676,294207375133,294744262430,276222199584,278369683233,266290087714,247768041252,230588172069,213408302886,196228433703,162405566248,146299438889,111134394154,74358736683,197033740174,230856607632,248036476817,265216346002,282127779731,283738392468,299576100757,312731518872,310581954457,310850373531,310045067164,310313502621,293938939806,294207375263,292865197984,295551649697,283469957026,265216346019,266558523300,248036476837,230856607654,213676738471,196765304744,163479308201,146299439018,108718475179,177706387469,197839046670,214750480399,231930349584,266290087953,283469973522,300649842708,299039213590,317561260055,313803163673,310045083674,310581938204,310045067293,313266292766,312997857311,309776631840,300381390882,283469973539,266021652517,248841783334,231661914151,214750480424,197570611241,163210872874,143346649131,103349766188,120529635467,155157809292,176634742925,192470337678,228440688783,245620557968,262800427153,278369699986,295549552788,293670504597,312460986518,310850373783,329909291160,332595742873,329103984794,329911388315,331519920284,330446162078,331253565599,311924132000,310850373794,297160165539,295549552804,279980296357,261189814438,259310766247,226561640616,210992384169,192470337706,175290468523,137977940140,120529635501,86438332590,121066506507,155694680332,212334561550,229514430735,241862461712,258505459985,279174990098,298233923859,313534728469,310045067542,327761807639,328298678552,332593645850,351920998684,352189434141,331519904030,332593645856,330446162209,327766001954,311655680291,314071599396,298233923877,276222200103,259042330920,245352122665,229514430762,195154692395,175558904108,155426244909,121603377454,137977940363,173142985100,207502723469,224951028110,242399332751,259042331024,276759071121,293402069394,293133633939,310581954964,328298695062,344941676952,344404806041,345210112410,348968208795,350578821532,350847256989,349505079710,345210112415,344941676960,327493372321,328567114147,310584035748,293402069413,293133633958,276490635687,259579201960,241862461865,224951028138,208039594411,190322854316,155694680493,120806459822,172337678859,211260819980,228709124621,242399332878,259847637519,277027506704,293938940433,310581955090,328298695188,344941693462,344404806168,345210112537,348968208922,352189434395,367758690844,368027126301,352189434398,348968208927,345210112544,344941677089,327761807907,311118809637,293938956838,277029603880,242667768361,224682592810,209650207275,194886257196,159721212461,189517548171,231661914764,249378654861,261189814926,276490635919,294744246928,311118809745,330177727122,329103985299,327761808020,344941677205,344673241750,361584675479,364537465496,364269030041,367758690970,369369303707,366416530076,368563997342,369369303711,348699773600,344404806305,344673241762,328298678947,330714598052,310581938853,311387245222,293941037735,259847637673,224951028394,212066126507,197843241644,160526518957,223877286667,266021653260,282664651533,300649827086,300381391631,310850374416,327493372689,348431338258,347894467347,344404806420,362121546517,362658417430,361853111063,365611207448,365879642905,385206995738,383596383003,381180480284,366416513822,368563997471,365879642912,362121546529,345478548258,346285951779,332595743524,310045068069,310581938982,276759071528,261189815081,248841784106,214750481195,162942438189,223608851338,259310766987,283201522572,299844520845,316487519118,317829696399,332325211024,347089161105,348162902930,366953384851,365611207572,365074336661,379301432214,384133254040,384401689497,386549189530,381180464028,383596383133,386549173150,369369303967,367221820320,364537465761,362658417570,331251469221,314071600038,294475811751,278369684392,263605734313,249110219690,213408304043,163747744685,257968589834,275416894475,317561261068,335278017549,350847257615,351384128528,366684949521,381448899602,382791076883,384133254164,399702510613,397018156054,397286591511,399702510616,401313123353,404265913370,403997477915,403729075228,401581558815,384133254176,382522641441,379838286882,363195288611,348162903076,349773515813,331251469350,329909292071,317561261096,282664651817,265484782634,249378655275,232198786092,197302176813,155157810222,71942818946,89122688131,125361474692,292596763786,310850374795,334741130380,352457870477,369637739662,368027126927,385206996112,402118429841,403460607122,396749720723,413392718996,414198025365,415003331734,431914765463,431377894552,430304152729,433525378202,437820345499,437283490972,420640476318,415808638111,413661154464,414198025377,397286591650,397823462563,379838287012,378764545189,365879643302,369100868775,350578822312,333667388585,317024390314,300918262955,266558524588,248841784493,207771159726,172069244079,71942851765,108718476546,143078214915,159989648644,314340035849,332325211402,347089161483,369100868876,385475431693,385206996238,402386865423,402655300880,419566734609,437283474706,437820345619,435404426516,448289344789,449363070231,449631522072,448020892954,451510553883,455805521180,455268650269,450168376606,449631505695,449363086624,431646346530,415808638244,418224557349,403460607270,402655300903,385206996264,368027127081,351115693354,333935824171,317024390444,300381392173,261189815598,246425865519,209381772592,125629910325,125898345782,108718476599,140662295938,177437953411,211529256324,331519905161,352189435274,365879643531,386280738188,402923736461,419835170190,419566734735,437015039376,453926489489,454194908563,472180084116,468958858645,467348245910,481575325079,481843793304,482649066907,484528131484,482649066910,481843760543,464663907744,464395455906,467348245923,451778989476,455268650405,437015055782,419566734760,402386865577,402655301034,385743867307,368832433580,351920999853,332325211566,300918263215,279980297648,177169518005,160258084278,143078215095,194617822722,212871433731,245888994820,365879643657,387086044682,400239382027,420640476684,437015055885,454194908687,471374777872,471106342417,488823082514,488554647059,488017776148,506539822613,503318597142,499023629847,500634242584,499560500761,499292065306,516740369947,516203515420,500097371678,499828936223,499292065312,499560500769,498755194402,503318597155,489359953444,488017776165,471643229734,453926473256,454194908713,437283474986,420372057643,403460607533,383864819246,369637740079,348699774512,228709125685,211797691958,194617822775,189249113656,226563739265,228985949826,247231172227,280785604228,361316241031,380375158408,401581559433,421445783178,417419251339,437837123212,454194908813,471374794382,488563035792,488286211729,507078790802,506002951827,522914385556,523988127381,517008821910,538756271768,533920239257,533383368346,534459223707,533385465501,538754174622,535530851999,533383368352,534188674721,516203499170,518887853731,524256562852,522645950117,506002951846,507078790823,488554663592,472719068842,454194908844,437824540333,418226654894,421192027823,401581559472,380375158449,361047805618,280248733365,247231172278,228985949879,226565836472,248841785091,280248733444,326956502790,364000595719,383059513096,401044688649,420911009546,415808638731,454731779853,471643213582,471374778127,488556744465,507078790931,524256562964,521303772949,517008805654,517279338263,535530852121,535262416666,536604593951,535262416672,534725545761,516471934754,517008805667,521303772964,524256562981,507078790950,488286211880,488560938793,454731779884,401044688688,383059513137,364000595762,326956502835,280517168949,247499607862,228709126017,247235366787,283469959044,295281119109,331519905670,369369304967,384938561416,403729043337,417419251595,455537086349,472716955534,471643213711,506002952082,524524998548,517008805781,516471934870,538752094105,536336158619,533651820444,537409900446,538752094111,536873029537,517010902946,516740370339,517008805796,524524998565,506002952103,488823082920,471645310890,472716955563,455537086380,417419251630,402118430640,384938561457,369369305010,331519905715,292328329140,281859346357,247231172534,228985950209,282664652804,297428602885,332325212166,369637740551,386014400520,404010061833,421183639562,418224558091,454463344653,471106342926,471378972687,488286212113,507076694034,506539823123,517008805908,517277241365,517008805910,516740370455,534188675096,533920256025,534457143323,533920272414,534457110561,517545676835,517277241380,518619418661,506539823142,506271387687,488554647592,471643213867,454463344684,435404427309,418226655278,404012159024,386014400561,369646129202,332325212211,297428602932,282129879093,247499608118,228979658808,226567934080,281859346564,299039215749,335009566854,368566096007,417419251851,454194909325,471374778510,489896824977,504123904146,503318597779,516203499668,516744564885,516474032278,517277241495,534457159832,533920256156,534457110686,533920239775,534457110688,533920239777,517277257890,516471935140,516203499685,501707985062,504123904167,489896825000,471374794922,454735974572,437828735149,335009566899,299039215796,247231172790,226561642681,230053400834,247499608323,283469959428,300918264069,335278002438,386821804296,417152913675,454463344909,471647408398,489628389648,489359954193,501707985170,500365807891,517008806164,516740370711,537141465368,534725546265,533383368986,533651804443,533920239900,533383368989,536336159006,536873029919,533385466144,533651804449,517547774242,516740370723,519424725284,517545677093,498755195174,503318597927,489359954216,488823083305,471643230506,417150816558,386821804337,335278002483,300918264116,283738394933,247499608374,230051320119,228979659065,247239561603,281590911364,299043410309,333667389830,369639838087,455541281165,472716956047,489359954320,481575326097,502781727122,503050162579,516203499924,517545677206,516471935383,538754175384,536336159129,533920240026,534725546395,534457110940,533651804573,537143562654,537409900959,534725546401,516474032547,521574306212,518350983589,499292066214,499828937127,481575326120,489359954345,472716972458,418226655662,333667389875,299043410356,281590911413,247239561654,231664013751,228979659192,231661916674,280517169668,334472696326,421718413834,418224558603,472180085263,484528116240,482112197137,503050162706,504394437139,519156306452,517277241878,516740370967,537141465625,536336159258,535262417435,534733935132,533920240157,538754175519,536336175648,517279339042,520230031909,502244856358,501171114535,482380632616,484528116265,472180085290,472716956203,454463345196,334472696371,280517169717,226561643065,223340417664,226563740289,231930352258,281590911620,334206358150,368566096519,384938562184,418763526795,473253827214,469764166287,481843761808,482917503633,501976421010,521572209300,520230032021,517554066070,517277242007,537409901208,538752094873,537141465755,534736032413,535530853022,538752078496,537409901217,516740371107,519961596580,521572209317,504392340134,502513291943,482649068200,481575326377,469764166314,473253827243,455537087148,418761429678,421716316847,384938562225,368027128498,334204261043,281590911669,231930352311,226563740344,230051304194,281859347204,299307651845,385475433224,435941298956,455805522701,468958860046,467348247311,483722810128,483190133521,500367905554,499560502035,516471935764,516740371221,517549871895,534727643928,534457111321,533920240410,534725546779,534727643934,533920256799,534457111329,517549871906,517277258531,516471935781,499292066598,499560502055,482919600936,483188036393,465737634602,468958860075,455805522732,435941298989,417150817070,385743868721,368832434994,334472696627,299307651892,281859347253,230051304247,223608853376,228979676033,282129879940,299576087429,335286391686,369637741447,386817610632,403729044361,420640478090,418224558987,435672863628,452852732813,466542941070,466006070159,482917503888,500365808531,518082565012,535262417817,535530869658,534725546911,535262417824,534729741217,517545710499,500902679462,500367905703,466006086570,452852732844,435672863661,418224559022,420640478127,386817610673,369637741490,335278003123,299576087476,282664653749,228977578935,226561643520,249114416131,299309749253,368295564295,385206998024,402118431753,419298300938,420908913675,435943396364,449094636557,465739731982,466813473807,483993342992,502244856850,502513292307,517545694228,536873030680,535532950553,534725563418,536336159774,536873030687,534725547040,517545677859,519156306980,499560502310,483185939496,482921698345,468421989418,466811376683,448826201132,435941299245,420908913710,419298300975,402386867248,385206998065,368834532402,334204261427,299309749300,282129880117,249114416182,230053401655,228981756984,226561643577,228977579136,230053401730,282666751108,368838726791,385477530760,402655302793,419837269130,421177349259,450973684877,482919601297,503050179730,516740371604,517545677973,517279339671,538754176152,533920240794,534725547163,535532950684,537143563422,538756273311,533383369888,518086743202,517277242531,519963694244,520230032549,499023631526,500634244263,483991245992,470034699434,467616683179,450705249452,438625653933,421177349294,419839366319,403194270896,385475433649,335282197683,228977562809,226561643776,228977562881,300112958725,403192173833,419298301195,437820347660,450168378637,468153570574,483724907792,503050163474,504394437907,519693178132,518090937622,537141466393,536873030938,536336160027,536873030944,537141466401,517545678115,521574307109,502513292582,502781728039,483722810664,468690425131,451778991404,438088783149,419298301230,385743869233,369637741874,299844523316,282664654133,231661917495,226561643833,226563741057,231661917570,248841786755,281861444996,300918265221,386012304776,403999577481,420105704842,419837269387,437283476876,455805523341,470032618894,483722810769,501978518930,521572210068,520230032789,517545678231,537409901976,538752095641,537141466523,535262434716,536336160158,538752095648,518082549155,518350984612,504392357286,483991246248,483722810793,468153554346,470301037995,455805523372,437285574061,419835172270,403999577520,386014401969,368832435634,300918265268,283469960629,248841786806,231930353079,226563741112,230051304962,247233271299,299844523525,334204261894,385475433992,437551912460,455539185165,472985392654,467348248079,482112198160,483991246353,500365809171,517545678356,517277242901,518082549271,535262418456,534725563929,535262418459,535535064604,535262418462,534457112095,534725563936,518353098274,518082549284,517545678373,500367906342,500902680103,482917504552,482380633641,467348248106,472985392683,455539185196,420372059694,368564000306,334204261939,299844523572,281859348021,247233271350,230057596471,228977579649,283469960836,300918265477,335278003846,369637742215,385209095816,402923738761,420372043402,421177349771,438357218956,472716957326,470303135375,487212471952,485870294673,498755196562,500902680211,519156291220,518082549397,518353082007,535530903192,535530903198,518350984868,519156291237,498755196583,487212471976,487480907433,470301038250,472716957355,437551912621,421177349806,420372043439,403192174256,385475434161,369637742258,335278003891,300112959156,282664654517,228981757624,228979660545,230053402370,249112319747,281859348228,299307652869,333667391238,368564000519,402386867977,419566737162,420908914443,437820348172,455000217357,472180086542,490165262096,490433697553,504660776722,504392341267,516740372244,517545678613,536873031448,536336160537,535262418714,535530854171,536873031454,536336160543,534725547808,535264515873,518350984994,517545678627,519156291364,516740372261,504392341286,504660776743,490704230184,490165262121,468690425642,472180086571,455000217388,437820348205,420913108782,419837269807,402657400624,385206998833,368564000562,333667391283,299307652916,281859348277,249114416950,223608854329,283738396548,299576088453,335284295558,369644033927,385475434376,402655303561,419837269898,420640479115,434330687372,450705250189,464663910286,487480907664,490702133137,507886196626,507345131411,519961597844,520230033301,519961597846,518082549655,538754176920,537409902489,534725547930,535262451611,538754176926,537409902495,534457112480,519156291490,519961597859,521840646052,520230033317,507345131430,507886196647,487212472233,468421990314,467885119403,448557766572,432988510125,385475434417,369644033970,334204262323,300115056564,282664654773,223608854529,229248096258,249647093763,283472058372,299844524037,386821806088,404001675273,420103608331,435941300236,452852733965,470034700302,468690425871,481575327760,490167359505,507886196755,525066082324,521840646166,515935066135,538754177049,536336177178,535262418972,534457112605,538754177055,536336177184,515935066146,524525000739,525066082340,507886196774,490167359528,481575327785,470032619562,451510556716,435404429357,420376238127,404001675312,386821806129,334472697907,283469961269,231661918263,223608854584,248841787523,300918265989,420374141066,419835173003,438357219468,455000217741,468153555087,483185940624,524525000854,521840646295,537141467288,538752080026,537409902747,535532951708,535262419101,537141467294,538752096416,521840646306,524793436323,482917505193,467616684202,470032603307,455000217772,438357219501,419835173038,335280101555,300918266036,283203623093,247499610294,229245999287,226561644802,247231174915,283201526020,300649830661,420105705739,437283477772,455539185933,468690426126,466008168719,484798650640,483722811665,504660777234,525063985430,539020515608,537409902873,534457112858,535530854683,535530871069,535262419231,537409902880,539020515617,525063985442,504392341799,483722811688,484796553513,466542942506,468690426155,455537088812,437551913261,420372044078,300649830708,247231174966,226561644855,243743611267,283469961604,299846621573,333935827334,351384131975,385207015816,402386868618,438357219724,453121169806,483991247249,503050164626,507345148307,507882002837,525063969176,524527098265,517277243802,519156291995,518082550172,518353082781,519156291998,517814114719,524525001120,525061872033,507882002852,507345148325,485870295463,483185940904,467616684457,448826202538,453121169835,438357219756,421177350573,403192175022,385206999471,368295565744,350847261105,334472698290,299844524467,282664655284,249378658741,209381775798,280517171716,334472698374,352457873927,368027130376,385475435017,402655304202,420908915211,437820348940,453121169933,450168379918,466811378191,467618781712,484796553745,485064989202,483722811923,500634245652,507613567509,507882002966,525061872151,516740373018,519693163035,519156292124,519693163038,517277243935,507345132064,507882035745,490433698340,483454376485,482380634662,466811394599,451242121769,433793817130,432988510763,418761431596,403460610605,386549176878,368295565871,351115696688,334204262961,300918266418,282933090867,248304917044,211797695029,175022037558,257700158084,297428605573,332056779398,352189438599,369639840392,386819709577,402923739786,420640479883,434330688140,433793817229,448557767310,449631509135,466813475473,485870295698,487214570131,483991247508,502781745813,503050164887,507882003096,507347229337,502244858522,502513293979,501171133084,501976423070,501707987615,507613567648,507882003105,485870295714,485601860259,487212472996,466542959269,467616684711,449363073704,434330688169,418492996266,414198028971,398897207980,381448903341,369369307822,351652567727,318098135728,300918266545,283469961906,246157433523,211797695156,348968213255,403192175370,402923739915,420911012620,435943398157,434330688270,451512654607,450438912784,470032603922,485333441300,483991247638,500902681367,504660777752,504660777754,500365810459,500097375004,499560504093,500365810462,487480908575,490165263136,487480908577,483722812194,466006072099,470032620324,452852734758,450973686567,432183204648,417150819113,401581562666,401313127211,384401693484,369369307949,351652567854,318098135855,300918266672,283738397489,245888998194,346820729735,364000598920,383327951753,384670129034,402118433675,435672865678,467616684945,468421991314,470032604051,487212489620,484796554134,483722812311,485601860504,487212489625,485601860507,484796554140,483991247773,485870295966,487212489631,468153555873,466811378594,467616684963,451242122148,452852734885,434330688422,433793817511,416077077416,399165643689,382522645418,384133258155,369100872620,352457874349,316219087790,298770783151,263068867504,245888998321,209381776306,384670129164,403997481997,418761432078,413124287503,433793817616,433525382161,450436832274,449631509524,450436815893,467616701462,468153555992,468690426905,470032604186,468421991451,467616701468,468153555998,451510574111,450973686817,450436815906,433256963107,416077077541,415271771174,398897208359,381985774632,364805905449,344673246250,334741134379,335278005292,297697041453,274880027694,332056779916,349505084557,369100872846,384401693839,381985774736,399434095761,416345513107,416613964948,433793834134,433256995992,433793817756,433256946845,416077126814,398897224866,381717339300,365074341029,364805905574,347894471847,330177731752,313266298025,298502347946,280785607851,264411045036,243741514925,314608475406,334741134607,347089165584,347357601041,365611228434,381717339412,381985774869,381717339414,399434079511,399702514968,399434128665,398897208605,382522645790,382254226719,364537486625,347357601059,348431342884,330714602789,312997862694,296354864423,277832817960,261189819689,248841788714,209381776683,294475816336,310850379153,330983038354,332593651091,346552294804,347357601173,347894472086,364537470359,366953389464,365611212185,364537470362,365074357659,347357601181,349773520286,347894472095,330177748384,330714602914,312997862819,298233912740,279443430821,261458271654,225756339624,206697422249,296086429203,296623300116,314071604757,313534733846,312997862935,315413798424,313803185690,313534733852,312997862941,315413798430,298233912864,296891735585,279174995490,261995126307,263874174500,246694305317,228172258854,209650212391,277295947413,276222205590,294744252055,296623300248,298233945753,296354864796,279174995613,279711866526,281054043807,263874174624,261726690977,243473079970,225487904419,208844906148,275416899350,294475833111,293670510361,295817994010,296623316763,279443447581,279174995743,260116078368,258505465633,242936209186,223877291811,292328333209,292596768666,294475833243,277295964061,275685334943,258237030304},{2961260569,2690662430,2422243359,2959098008,2151694497,2959098135,2686484885,2957001118,2686468511,2418049440,2149597602,1881162147,2688565781,2959098390,3223421464,2954904095,2686485024,2418033186,2149597731,1881162276,3223405207,3493872284,3223372445,2954920608,2686468770,2418033315,2149597860,2688566036,2959098645,3223356183,3493905177,3491791645,3223372575,2954904354,2686468899,2418033444,1881162641,2149598098,2418033555,3225437078,3493888919,3762324380,3491824542,3223339938,2954904483,2686485412,2420130726,2149598119,1612727312,2149598225,2418033682,2686469139,2954904596,3760243737,3762324510,3491808288,3225437219,2957001764,2686469157,2426422311,1887454248,1881162896,2418033809,2686469266,2954904723,3223356564,3491775638,3760260247,4030776475,3762324640,3491775650,2961196197,2692760742,2418033936,2686469393,2954904850,3223340307,3491792148,3760211222,4028695831,4030760222,3764405538,3495970083,3227534628,2686469520,2954904977,3491792274,3760227732,4028679574,4299244953,4032841120,3760211361,2418034190,2686469647,3223340560,3491776017,3760227858,4028663316,4297115158,4299179550,4028646943,4030744097,2151695912,1614825001,1077954090,538986027,2696955533,2963293838,3229632143,3498067600,3764405905,4028679826,4297098901,4567713431,4297082527,4030744226,3762308771,3491776164,3223340709,2954905254,2686469799,807421611,4028663570,4297099028,4569712406,4567631646,4297099040,3760211748,3491776293,3223340838,2954905383,2418034472,2149599017,1612728106,1075857195,4028647314,4297099155,4569712533,4565518231,4836132760,4565534624,4297082786,4028663715,3760211877,3491776422,3223340967,2954905512,2418034601,2149599146,1612728235,4032841745,4299196434,4569712660,4836050967,4833986590,4565534753,4297099299,4028647461,3760212006,3491776551,3223341096,2954905641,2418034730,2149599275,1612728364,1883261067,2420131980,3493873807,3762309264,4836051094,5102504088,4833986720,4565534883,4297083045,4028663974,3491776680,3223341225,2954905770,2686470315,2149599404,1881163949,1344293038,3223341326,4297083154,4567615763,4836051221,5102455063,5372938524,5102455070,4833970467,4567632165,4299180327,4030744872,3764406569,3498068266,2954905899,2686470444,2428520749,1891649838,2149599627,2686470540,3223341453,3491776910,3760212367,4028647824,4297083281,4565518738,4833954196,5102406038,5372971416,5372955038,5102422433,4836051364,3231730091,2963294636,2686470667,3223341580,3491777037,3760212494,4028647951,4297083408,4565518865,4833970706,5102406164,5370841622,5641374236,5372922401,5102406178,4838148645,4565535270,4303374888,2954906251,3491777164,3760212621,4028648078,4297083535,4565518992,4833954449,5102422674,5370841749,5639326359,5641374366,5370825376,5372922530,5102406307,4838148774,4569713319,4032842409,3491777291,4028648204,4297083661,4565535502,4833954576,5102390033,5370858258,5639326485,5909842714,5641374496,5372922659,5104487204,3762309930,3491777418,4028648331,4297083788,4565519245,4833971086,5102390160,5370842001,5639293843,5907745686,5907696542,5639261087,5639261090,5102390181,4028648458,4297083915,4833954828,5102406669,5370842127,5639261201,5907729426,6176295957,5907729440,5639261219,5370842148,5102406694,4833954856,4297083945,4028648490,3760213035,3491777580,2954906669,2418035758,1075858562,1344294019,1881164932,4565519498,4833954955,5102390412,5370825869,5639277710,5907696784,6176165009,6444600468,6713101463,6444616862,6176148642,5907713188,5639277734,5370825896,5102390441,4833954986,4565519531,4028648620,3760213165,3223342254,2686471343,1075891381,1612729602,2149600515,2418035972,4833955081,5102390538,5370825995,5639261452,5907713293,6176148751,6444567825,6713036050,6981635349,6713019682,6444584228,6176148774,5907696936,5639261481,5370826026,5102390571,4833955116,4565519661,4028648750,3760213295,3223342384,1881181493,1612729655,2149600642,2686471555,3223342468,5102390665,5370826122,5639261579,5907697036,6176132493,6444584334,6713003408,6981471633,7249907092,7518440855,7249923488,6981455268,6713019814,6444567976,6176148905,5907697067,5639261612,5370826157,5102390702,4565519791,4297084336,2686471605,2418036150,2149600695,2954907138,3223342595,3760213508,5639261705,5907697162,6176132619,6444568076,6713019917,6981438991,7249890832,7518342674,7786827285,8055213595,7786827294,7518326308,7249890854,6981455400,6713003562,6444584491,6176132653,5907697198,5639261743,5370826288,3491778101,3223342646,2954923575,3531640449,3808448131,4345319044,5683302023,5953834632,6220172937,6488624778,6763335308,7029673613,7293931150,7564463760,7832899218,8099270292,8367804056,8099270306,7830802086,7562366632,7293931178,7025479340,6757043885,6488624814,6220172976,5951737521,5683302066,4341124789,3804253878,3531640503,5150625542,5144334131,4611657605,4605366196,3500167296,3498070201,3498070912,3495973945,3491780409,3493877890,3493877943,5379217799,5916088713,6182427018,6448765323,6985636238,7251974543,7788861844,8055396758,7786781092,7518329255,7249877417,6981458346,6713006508,6444571053,6176135598,5907700143,5639264688,5370829233,5102393778,4565522867,4297087412,3760216501,3223345590,5645556232,7251974672,7518345745,7788845590,8055314967,7786797600,7518345764,7249893927,6981442089,6713023018,6444571180,6176135725,5907700270,5639264815,5370829360,5102393905,4565522994,4297087539,3760216628,3223345717,2686474806,4028652164,6717201037,6985636495,7254071953,7518345874,7786748565,7786912407,7518345890,7249910437,6981442216,6713006761,6444587690,6176135852,5907700397,5639264942,5370829487,4833958576,4565523121,4297087666,3760216755,3223345844,6178233099,6446668556,6715104014,6983539472,7251974930,7518362387,7786863383,7518362399,7249910563,6981458726,6713006888,6444571433,6176152362,5907700524,5639265069,5370829614,4833958703,4565523248,4297087793,3760216882,5907700618,7249877907,7518509972,7249910689,6981458852,6713023398,6444571560,6176136105,5907717034,5639265196,5370829741,4833958830,4565523375,4028652464,3760217009,3223346098,5907700748,6176136205,6444588046,6713023504,6981491730,7250009110,6981491743,6713023523,6444588069,6176136231,5907700776,5639265321,5370829866,5102410795,4565523501,4297088046,5102394508,5370829965,5639265422,5907717263,6176152721,6444604563,6713121942,6444620958,6176152738,5907700900,5639281829,5370829991,5102394536,4833959081,4565523626,4297088171,4028652716,3760217261,4833959182,5102394639,5370846480,5639281938,5907733780,6176234775,5907733790,5639281953,5370846499,5102394661,4833959206,4565523751,4297088296,4028652841,3760217386,3223346475,4565523856,4833959313,5102411154,5370862996,5639347607,5370863005,5102427552,4833959331,4565523876,4297088421,4028669350,3491782056,3223346601,4565540371,4834123285,4565540384,4297088546,4028669475,3760217637,3491782182,3223346727,4297105045,4567703191,4301315741,4030766752,3762314914,3493879459,3223346852,4297088790,4565573529,4028653472},{185,178,147}},
['Night Flame Egg']={62,60,2.8,2.8,2.79026084,{{255,255,255,0},{250,247,231,0},{251,246,168,0},{238,215,169,0},{241,175,69,1},{233,155,35,1},{231,143,27,1},{205,204,162,0},{205,158,92,1},{150,197,114,0},{151,155,104,0},{214,140,33,1},{208,132,29,1},{189,135,61,0},{103,134,52,0},{207,122,27,1},{176,119,46,0},{176,108,29,0},{175,96,23,0},{154,108,54,0},{155,98,29,0},{149,93,28,0},{148,83,20,0},{128,109,71,0},{131,86,31,0},{124,78,25,0},{82,114,36,0},{90,85,32,0},{47,93,13,0},{124,68,21,0},{110,68,21,0},{98,64,20,0},{90,53,16,0},{74,56,16,0},{36,61,8,0},{60,40,9,0},{40,23,4,0},{0,0,2,0},{0,0,0,0}},{52347027456,69526896701,53689204864,52615463041,52347027586,69526896827,70869090492,56641995008,55568253185,52615463170,35167158531,34630287620,69526896953,69795332410,71674380603,71942816060,70600638781,71405945216,71942816129,71674397058,69795332484,69526897029,51810156934,103349764509,86438330782,69258461599,86438330807,86975201720,89122718137,89391120828,107376296449,106034135554,106302554628,104691941893,104155070982,103886635527,156499984925,141199163934,139320115743,86438330933,103886635574,104155071031,89122685496,89927991865,88854250042,89927991867,88048943676,125361472129,128045826690,142272905859,140393857668,156231565957,175022031495,175290466952,173679854217,225219461788,209918640797,191396610718,173679854240,86169895603,88048943796,107376296629,106302554806,106034135735,107644732089,91807040186,91538604731,87780508348,156499985153,159721210626,159452775171,175022031620,190322852613,207502721798,226293203719,227366945544,245083685641,242667766538,258773893899,258237022988,277295940380,261458248477,260116071198,241594024735,242936202016,224145720097,86706766641,88048943922,107376296755,107644732212,123482424117,123213988662,121603375927,106034119480,107107861305,108450038586,105228813115,191665030019,211260818308,245888992133,260921377670,276222198663,293402084232,313266291594,312460985227,327761806220,327493370765,344136369038,362926867348,364269028246,362926850967,345746998168,328835548059,330177725340,330714596253,313534727070,296354857887,297428599712,277295940513,225487897508,209650205605,175290467238,158110598055,122408682408,69258462127,86975202224,104423506865,106302555058,123482424243,121603392436,140393857974,124824601527,125361488824,103886635962,191128175617,206697415683,223340413956,242399331333,262800425990,297428599815,313803162632,312192549897,327761806346,344941691915,363732157453,361853109262,364269028367,378764542992,379838284820,383327945749,382522639382,383864833047,380106720281,378227672090,380375155739,381717333020,366416528413,349236659231,330177725473,311118808098,279980295204,263605732389,245888992294,228172252199,192470336552,121066505261,139588551726,138783245359,156231550000,173143016497,175022031924,176364209205,176901080118,174485161015,137709503545,138246374458,122408682555,122140247100,191128159361,193007207554,207502722179,241594025092,258505458821,275148457094,310045066375,311924114568,332056773769,348162901130,362121561227,379301414029,381180462222,399702508687,398360331408,396212847761,412855846034,415003329684,416613958805,417687684247,417956119704,414198023321,415003329690,420640474267,420372038812,417687684253,400507831454,383327945888,384670123169,365879641250,361584673955,348699772068,331788338341,314608469158,296623293607,278369682600,241325589673,206697415851,207234286764,209381770413,210723947694,226293204143,224682591408,241862460593,226293204146,228709123251,228440687796,225219462325,223608849590,206428980407,189785982136,172874548409,157573727418,140930729147,193275643138,226293204227,243741508868,277832811781,293133632774,311387243783,326956500232,343867933961,366953383178,381180462347,396481283340,398091896077,413661168910,415540200720,433525376273,430572586258,448826197268,451242132757,452047422743,452315858200,448826197273,449363068186,456073954587,454731777308,452047455517,434867553568,437551908129,436209730850,413124281635,400239379748,400507815205,383864816934,365342770471,347089159464,311118808362,293133632811,296086422828,295012681005,293402084654,295012681008,293402068273,296623293746,294744245555,275148457268,275685328181,259847636278,241862460727,226561639736,209381770553,192201901370,173948290363,209650206082,226561639811,259042329988,276490634629,312192550278,332325209479,346820724104,361853109641,381448897930,398360331659,413661152652,416882378125,432451650958,449899955600,467885114770,464663889299,466542937492,488823080341,486944032150,486675596695,486407161240,483185935769,487212467610,504929207707,503587046812,486407210398,487480903074,465737631139,468958856612,469227292069,453389600166,454463341991,434599118248,414466459050,398360331691,381985768876,382522639789,379301414318,380912027055,381180462512,362121545137,346820724146,345746982323,327493371316,330983032245,314071598518,276490634679,260652942776,243741509049,209650206138,208039593474,246157428227,262531991044,295012681221,329372419590,349505078791,364000593416,380912027145,396481283594,415273862667,432453731852,451510552077,449899939342,466811373071,467079808528,484259694097,500097369619,500902675988,504660772373,521303770646,520766916119,534725543449,538752075290,540631123483,537946850844,540631123490,533383366179,537678333476,520768996901,521035335206,522109077031,503320692264,498486756905,501707982378,484259677739,485064984108,468690421293,466811373102,449899939375,450705245744,432451634737,413661152818,396481283635,379301414452,365342770741,348162901558,329372419639,295281116728,263605732921,245620557370,243204638339,260384507524,297160164997,314340034182,351384127111,369100867208,385743865481,401044686474,434330683021,452584310414,468421985936,483991242385,485601855122,483722806931,500097369748,503589144213,520766899863,521035335320,517545674393,521572206234,523182818971,537946769052,520769062557,522109077154,517277238947,520498464420,503587047078,481306887849,486138726058,485064984235,467079808684,452584310445,435404424879,415540201136,413661152945,398360331954,383864817331,368563996340,351920998069,315682211510,297160165047,263874168504,226024769209,206965851834,257968588548,292328326917,310045067014,344404805383,362658416392,380643591945,401581557514,399165638411,413931685644,432720070413,449899939598,450705245967,467079808784,468421986065,483722807058,481306887955,483185936148,503587047191,521035335449,520766932762,520766900002,503855466275,504660772644,503587047205,486407161639,485333419816,481575323433,465737631530,468958857003,449899939628,433525376813,432720070446,415271765807,398091896624,396481283889,366148077362,349773514547,328298678068,310045067061,292865197878,257968588599,223608850232,189249111865,225219463043,261191911300,293402068869,310313502598,345746982791,362926851976,361584674697,380106721162,398091896715,432451651469,449631504271,449899939728,468958857105,483185936275,485333436308,503855466390,503587030935,503857563544,503587030937,501707999130,519961593756,503857563549,503589144478,503855466400,502513289121,501707999138,503855466404,486409258917,486675613606,467348260776,447484020650,448557762475,434062247852,415271782317,396749719471,379301414832,362389981105,346552289202,327493371827,310313502644,277027506101,258773895094,224682592183,191933466552,158110599097,278103345157,312192550918,329640855559,348431337480,362389981193,379301414922,396481284107,413661153292,415540201485,430841022478,448020891663,449633601552,467348244497,468958857235,486407178260,486946129942,486409259031,504929208345,502781741082,503589128220,506002950176,503587031073,485601871906,486675597348,469497825318,471643211815,451242117160,451510552617,431648426026,415808636972,415540201517,396481284142,379301414959,362121545776,344941676593,327761807410,293670504499,278906554420,262531991605,226293205046,191933466679,159184341048,122140248121,260384508036,313266292870,330983032967,349505079432,366416513161,383596382346,399970945163,415271766156,417150814349,432720070798,432451635343,448826198161,467348244627,468421986452,486138726549,487483000984,487749339289,485333436570,486677694621,486407178398,488825178272,485601855649,485333420194,468153551011,469497825444,469229389989,453389600935,450973681832,434062248105,400239380652,399970945197,380912027822,363732158639,346820724912,329374517425,297965471922,280248731827,246425864372,228172253365,193007208630,158647470263,123750860984,244009945349,277564377350,311118809351,328298678536,344404805897,362658416906,365342771467,379301415180,399970945293,415540201742,415271766287,432720070928,431377893649,448557762834,453926471955,472180082964,471911647509,469495728406,469227292951,489091516697,487749339418,488823081243,487480903964,486675597598,486407162143,488823081249,470569486626,452317956390,454731778343,437283490088,415003330858,412318976299,401315219756,382791076141,363732158766,364000594223,347626031408,295549552946,276759071027,242399332660,225219463477,190859725110,156768422199,122140248376,241057155462,275685329287,294207375752,310313503113,327761807754,344941676939,363732158860,382791076237,401044703630,416882379152,436478200209,453658069396,471911647639,469495728536,470569470361,471911664026,470569470364,469495761309,469764164000,471643212193,471911664034,453123262884,452315859365,437283473831,437551909288,420372040105,419566733738,416077072811,383864818093,366684948910,349505079727,346820725168,327761807793,293402069426,276222200243,241862461876,225487899061,189785983414,155426245047,210455513606,243741510151,261726685704,296891730441,314071599626,332862081547,348968208908,363732158989,382522657294,399165639184,421177346577,421445782034,436478167571,437015054868,455805520406,455000214039,453389617688,470569470490,469495728667,469227358748,468958857761,453121182242,453389617701,435941296679,436746603048,419298298409,419835169322,405339654699,401581558316,381985770029,365342771758,347626031663,329374517808,315145341489,297697036850,262531992115,245083687476,226561641013,193007209014,157305293367,173948291718,210455513735,245888993928,262800427657,276759071370,311118809739,330714598028,346552289933,363732175502,381180463760,401581558417,404265912978,421445798547,438625651349,438357215894,437551909527,455000214168,454731778713,454463343258,454731811483,454463376030,454731778721,453389601442,454731795107,435941296805,433256942246,436478167719,419300395688,419835169449,402118429354,404265913003,382254205612,380912028333,363732159150,345212209839,312729422513,292865198770,260384508595,245620558516,210455513781,192470338230,191665031943,206967950088,240788720393,259579202314,295012682507,312192551692,329372420877,346552290062,347626031887,367758691088,385477528337,402118445842,421445782292,421982653205,421714217750,438357216023,438088796952,437820345114,455000328987,437820345123,438088780580,437015055141,419298298663,419298298665,402655300394,402386864939,381985770284,364000594733,346552290094,327761808176,312192551729,293402069810,258505460531,240788720436,243473075081,261726686090,277832813451,313803164556,331251469197,329372421006,348167097231,369906174864,384938560402,398897204115,402120526740,421714217877,420372040598,419029863319,435941297048,434599119769,436478167962,435941297051,435136023452,435941297055,435136023456,435941297059,420908911524,421714217893,421982669734,404265929640,387086044074,383596383147,364000594860,346820725677,329372421038,312460987311,297428601776,278101248945,260652944306,227366947763,207234288564,173679856565,211260820488,227635383305,260921379850,279443426315,294744247308,311389342733,330448260110,369100868624,369906174993,385475447826,403999575061,420640476182,419566734359,419298298904,416077073433,419835169818,437820345371,437283474460,437551926301,437283507231,420103621666,420640492580,403460623398,386280737832,386817608745,369637739562,367221820459,350041951276,330714598445,312192551982,296086424623,277564378160,262800428081,227903818802,192201903155,176095775796,226024770697,262800428170,277564378251,292328328332,349236645008,369637739665,387086044306,387891350675,387090238612,403997478038,419835202711,421177347226,420640476315,420372139164,403192171683,403460639908,386012302503,369100885160,352994741418,351115693227,333398953132,316219083949,295549553838,278101249199,242667769008,223608851633,191665032370,158110600371,240788720906,275416894731,295281118476,313266294029,331251469582,332325211407,350041951504,368297659665,369906175250,387086044435,384938560789,402655333654,404265913625,421714218266,420908928283,420640476445,420372057374,403194268960,403462704417,403729042722,403997478179,386817641764,369100868903,369369304360,351920999721,335814872362,335546436907,316219084076,299039214893,264947911982,245083688239,227366948144,190054419761,172069244210,277027507595,296623295884,314608471437,315413777806,332593646991,352189435280,368295579026,387086060949,404265930135,403997478297,401849994650,403194285467,403460607389,403192171934,402923736479,384938560930,381717351843,364537482661,347357597095,350578822568,335278001577,317829696938,318098132395,301186698668,266829057453,247499607470,228440690095,193544080816,176095776177,139588554162,260384509452,277564378637,292328328718,314340036111,335009566224,353263177233,352726306322,368295579155,370445143573,384401690134,385207012887,386280738329,403460607514,403729075741,386549173792,387354480161,387086044706,385475431971,367758724644,350578822695,333398969896,318098132522,300918263339,284543700524,244278382126,225756335663,191665032752,173679857201,278369685134,298770779791,315950648976,335009566353,335814872722,352726306451,353800048276,367221821078,368027127447,384938577560,386280738458,386012319387,387356577437,386817609374,386012303007,387622915744,386549190305,370176708259,369906175652,368295562917,351115710118,333937921704,316755955369,318368665258,301455134379,281861443244,261458251437,248036478638,209918643887,242399334157,265753218830,283201523471,299844521744,300112957201,317561261842,332862082835,333667389204,351921016597,369906175767,368295563032,364537466649,368027127578,369369304859,386549174044,383596384030,382254206751,369100869408,370174611233,369369304866,370174611236,352457871141,351115693862,333935824679,318370762537,299578183467,265218445101,232469319470,213139869487,191396597552,212334563213,231661916046,248841785231,264142606224,282933088145,299844521874,314876907411,315682213780,333130518421,352457871254,352726306711,351115693976,350578823065,367758692250,370443063195,366416514973,365342789534,365074337696,369369304993,370443046818,353263177635,352994742180,351652564901,352457871270,335546437543,316755955624,300918263722,284006829996,213676740527,195960000432,156499988401,157305294860,196228435981,214213611534,231932448783,247237464080,265755316241,283201523730,298770780179,315950649364,317292826645,334472695830,335009566743,352994742296,352726306841,350578823194,352457871387,367221821468,365074337821,366148079646,365074337823,365344870432,365074337825,351921000482,352994742307,352457871396,350044049445,334472695846,335278002215,318903439400,300112957482,283738394667,266826960940,249647091757,232737755182,215824224303,198107484208,157305294897,158381133964,198111678605,215555788942,282933088402,298502344851,315682214036,315950649493,333130535062,351921000600,353263194265,350847258779,365342789788,366684967070,365344870561,348699775138,352457871523,352994742436,333130535078,318637101224,317831794857,298502344874,283469959339,266558525612,249915527341,215557886127,197839048880,156499988657,215021015310,231664013583,265486881041,283469959442,300651925779,317831794964,318098133269,335278002454,335009566999,352457871640,353263178009,351652565274,349236646171,365342773532,366684950813,365611208990,364805902623,366684950816,348162904354,348699775267,352189436196,352457871653,335278018854,300649828650,283738394923,264947913004,247768043821,232198787374,195160985904,160794956172,282935185810,318635004309,335814889878,353263178136,350310388121,347894469018,348162904475,366684950940,365611209117,362390000030,364805902752,366684950945,348968210850,348165001635,348699775396,352994742693,335816987046,318903439784,319440310697,301186699690,281859346859,264679477676,248036479405,230319739310,215018918319,196228436493,215293645326,230319739407,244278383120,264947913233,300112957971,317294924308,317833892373,335278002710,335814873623,350310388248,347894469145,348968210970,349505081883,364805902876,362389983773,362121564702,362389983776,364805902881,349505081890,348165001764,348968210981,318098149928,300918264362,282396217899,266826961452,249647092269,230856610350,214482047535,195154694797,230858707599,247499608720,261458252433,278638121618,299307651731,335814873750,333130519191,347894469272,348968211097,349505082010,347626033819,362389983900,362121548445,362390000286,362121548448,362389983905,347626033826,349505082019,348162904741,332862083750,335814873767,317292827304,315950650025,298770780842,283738395307,265216348844,247499608749,230326031022,213408305839,157036860172,196496872205,249647092496,266826961681,284006830866,300381393683,315950650132,334472696598,330714600215,348968211224,349505082137,347626033946,345210114843,362121548572,362390000413,362121548575,362389984032,362121548577,344943776546,347626033955,349505082148,348968211237,330983035686,332862083879,317561262888,315682214697,297697039146,282933089067,264947913516,244278383405,213676741423,191665034032,122945557387,162137133964,198107485069,232198787983,248841786256,266290090897,282935186322,300112958355,317292827540,315950650261,331519906710,331788342167,349507179416,347628131225,345212212122,344943776667,362390000540,362121548702,361855210399,362123645856,362389984161,344941679523,347628131236,349509276581,331788358566,315682214824,315952747433,298504442794,281593009067,267095397292,247499609005,213139870639,195960001456,156499989425,87782609930,127240524811,163749843980,198375920653,214219904014,231668208655,246962738192,264421528593,295817991187,317561263124,317829698581,333130535958,362389984284,362121548829,361853113374,364805903393,345210131490,332862100518,317561263144,266290091052,248036480045,213676741679,196496872496,127779493003,196228437133,247233270928,283203622034,299039216787,312999957652,318903440533,335278003350,332862084247,350044050584,349507179673,347626034330,345212212379,362121548956,362389984413,362121565342,362389984416,362123646113,345212212386,347626034339,349507179684,332862084262,335009567911,318635005096,317561263273,300112958634,282933089451,265753220268,249378657453,230856610990,215287354543,197839049904,161868698892,195154695437,299578184979,312997860629,336083309846,335009568023,349507179802,362392081692,362123646237,362390000926,362123646240,348431340835,349236647205,334741132582,335814874407,318098134312,318635005225,300649829674,283201525035,265486882092,248841786669,232198788398,215023113519,196230534448,126435218827,195423131021,246966932880,282935186834,316755957140,316219086229,333667390870,336083309975,351921001880,349236647321,348431340955,362123646366,362389984671,362389984673,348431340962,349505082787,349236647332,351652566437,335814874534,335011665319,317831796136,317565457833,298770781610,282935186859,248573351341,232735659438,157036860849,191665034765,214482048526,231932450319,301455136275,318368683540,333935842838,353265276440,351652566553,349236647450,349505082907,365611210268,362389984797,362121549343,362389984800,365611210273,349505082914,349236647459,350310389284,352994743845,335278003750,300115056170,264411043372,247231174189,232198788654,196496873008,162137134641,122945558066,214750484110,281593009810,300918265491,333935826582,335548536471,353263179417,350310389402,349236647579,366684952220,365611210397,362390001310,365611210400,366684952225,349236647586,350041953955,353263195812,330177730214,333398955687,318098134696,283201525419,266290091692,249110222509,232735659694,213141968559,198107485872,161600263857,122677122738,214482048782,232198788879,247231174416,265753220881,300112959251,318098134804,318366570261,335546439446,352457873176,352994760473,350310389531,367223920412,366684952349,365611226910,366684952352,366416516897,350041954082,352998938403,352189437732,352457873189,333935826726,330177730343,312997861160,316487522089,300381394730,283469961003,266560624428,249378658093,230321837870,196496873264,157305296689,208844904334,232735659919,248841787280,266290091921,283201525650,298502346643,317561264020,316755957653,333935826838,335278004119,350310389656,350041954201,352994760602,367221823389,366684968862,366416517024,367221823393,352457873314,350041970596,334743230374,333935826855,316758054824,316219086761,299039217578,283738396587,247501707181,213678839727,191396599728,195154696207,230051305488,248573351953,266021656594,281590913043,283201525780,299039217685,312997877782,334472697880,333130520601,335814875162,353263179803,352994744348,350041970717,349236664351,352457873441,353263179810,333134714916,334204262437,318366570535,299576105001,284006832171,266831157292,230856611886,190859728944,174485166223,195423131792,231393482897,249110222994,267095398547,265216350356,282396219541,299576088726,316219086999,316487522456,315952748697,335009568922,335814875291,336083310748,335009568925,332862085278,332056778911,352189438112,353263179937,335814891682,333130520741,334472698022,318098135207,318366570664,301723572393,284543719594,248036481197,232467224750,213139871919,140125427983,176901085456,195423131921,214482049298,232198789395,248036481300,265216350485,282396219670,301186701591,300918266136,315682232602,335814875420,336083310877,335009569054,334741133599,336085408032,335816972577,333130537250,315954845989,317024393510,317561264423,301723572520,301186701609,284006848810,249647094061,230856612142,190859729298,213139872147,230856612244,248036481429,265216350614,283738397079,282933090712,298770799001,315950651803,318635006364,318903474589,315950684578,317292829094,300112959911,299307653544,281859348905,282398316970,263874173355,260384512428,230319741357,208039598510,174485166610,196496874003,215287355924,232467225109,249915529750,266021657111,264413141528,281590929945,298770782747,300649830940,317561264669,317829700126,317561297439,315950651938,315682216483,315950651940,300112960038,300381395495,299576089128,282396219945,261458254379,177974827666,192738777747,213408307860,232198789781,248841788054,264411044503,282933090969,281590913690,298502363803,300115073693,299844524703,300112960160,315950652065,298502363810,298770782884,298502347429,298770782886,282396236455,265216350889,249647094442,244278385323,226024774421,249110223638,248575449879,264144706328,265755319065,282664655642,281590913819,298770783004,300112960287,300381395744,300112960289,298770799394,282935188260,281590913829,282127784742,265216367399,249647094569,230319741738,226024774443,230590274454,265753222042,282933140379,281590913951,283201543072,282933107618,265753222053,265216351142,249647094695,248036481960,227098516393,249915530263,249110223896,266290093081,267095415834,284275268636,283738397725,283469995038,284275285025,267095399459,266558544932,250183965734,249378659367,225219468328,229514435734,246694304919,249915530392,249378659481,266558610586,266290109600,266558545058,249110224036,249378659493,246694304934,229514435751,249378659608,250183965977,267095547162,250183965988,247768046885,246694321560,263874321818,246694305188,243204644261},{811614208,1080049725,809533569,1077969083,539001091,1075872057,1075937664,807420294,1612726685,1344291230,1075855775,1344373175,1612825089,2418033181,2149614110,1344291381,1614840374,1344356920,1881178753,2149614211,2418049669,2686501511,3491775132,3223339677,2954920606,2686468768,1344307891,1612726965,1614840504,1344324282,2418066177,2686468868,2954904325,3223339782,3491791623,3760227081,4028662539,4297081628,4028662557,3760227103,3491775265,1344308017,1612743475,1881195317,1612743482,2954904451,3223339908,3762307973,4030743430,4297081735,4565533576,4833969034,5102404492,5370823566,5639308180,5370839960,5102420891,4833952670,4565533599,4297081761,3491775396,3223339941,2686469030,2418033575,1881162664,1075856303,1344291760,1612743601,1881195443,2149598134,1881195447,1612727226,2957018113,3225437187,3491775492,4565517319,4833969160,5102388234,5370840075,5639291917,5907694608,5907825684,5639275549,5370840095,5102388257,4833952802,4297081892,4028646437,3760210982,3491775527,2954904616,1881162797,2149614638,2418033712,2686567473,2149614649,1881179195,3762308228,4028646533,4297081990,4833969287,5102388361,5370823818,5639275659,5907711117,6176162959,6444565650,6444713108,6176146590,5907711136,5639275682,5370823844,5102388389,4833952934,4565517479,4297082024,3760211113,3223389355,3491792047,3760211121,3491841202,3223340215,2954904760,2686469305,2418033850,2149598395,2954904834,3493872899,4299179269,4565517574,4833953031,5102388488,5370823945,5639259402,5907694859,6176146700,6444598542,6713017617,6981616916,6713034016,6444565795,6176146724,5907694886,5639259431,5370823976,4833953066,4565648683,4297098548,4028646710,3760211255,3491775800,3223340345,2954904890,2686469435,3225437570,4041229700,4833953158,5102388615,5370824072,5639259529,5907694986,6176130443,6444582284,6713017742,6981453200,7249905042,7518389653,7786775963,7518373278,7249905059,6981453222,6713001384,6444565930,6176130475,5907760556,5639259569,5370840498,5102405044,4833953206,4297082295,4028646840,3760211385,3223340474,3762308611,4571809285,5102388742,5377115655,5645551112,5911889417,6180324874,6446663179,6715098636,6981453325,7249888783,7520421393,7786776083,8055211542,8323794457,8055211557,7786776104,7518324267,7249888813,6981453359,6713001521,6444566066,6176130611,5907695156,5639259701,5370824246,5102388791,4565517880,4028646969,3760211514,4842342022,6717195917,6983550606,7251969680,7522502291,7786776212,8055244439,8323614364,8055309981,7786776230,7518340777,7249872556,6981453485,6713001647,6444582576,6176130738,5907695283,5639259828,5370824373,4833953462,4565518007,4028647096,3491776185,3223340730,6182422283,6450857740,7254066961,7518308114,7522502420,7786792725,8055326489,7786792739,7518340903,7249889066,6981437228,6713018157,6444566319,6176147248,5639259954,5370824499,5102389044,4833953589,4565518134,4028647223,3491776312,2954905401,3491776387,5643454345,5911889802,6717196174,6983550863,7522502549,7786825622,8055179164,7786858397,7518341029,7249889192,6981453738,6713001900,6444582829,6176130991,5907695536,5639260081,5370824626,5102389171,4833953716,4297082805,4028647350,3491776439,2954905528,2418034617,4299180037,5104486407,5372921864,6446663693,7251970067,7520421910,7786891288,7518357538,7249889318,6981453864,6715099178,6444582956,6176131118,5907695663,5639260208,5370824753,5102389298,4565518387,4297082932,4028647477,3491776566,2954905655,2418034744,1881163833,6713002127,6981453968,7251970196,7520454808,7786743964,7518390429,7249922211,6981453991,6715099305,6176147628,5907695790,5641357487,5375019184,5106583729,4576004274,4301277363,3770697908,3498068149,2963294390,2424326327,1883261112,3760212229,4297083142,4833954055,5102389512,5370824969,5639276810,5907695884,6176131341,6444583182,6713018640,6981454098,7249905941,7518390556,7249922338,6981454118,6717196584,6446680362,6180325676,5913987373,5645551918,3760212358,4297083271,4565518728,4833954185,5102389642,5370825099,5639260556,5907696013,6176147854,6444566928,6713035153,6981470612,7250069911,6983567780,6717196711,6450858409,5377116591,3223341574,3760212487,4028647944,4565518857,4833954314,5102389771,5370825228,5639260685,5907712526,6176131600,6444583441,6713035283,6981487126,7249988122,6983551522,6444567082,6180325931,5106584112,4838148657,4032842291,2686470790,3223341703,3760212616,4028648073,4297083530,4833954443,5102389900,5370825357,5639277198,5907696272,6176148113,6444583571,6713035413,6981585560,6981438116,6715116197,6446664360,6178228906,5909793452,3223341749,2954906375,3227536136,3762309897,4034939658,4565519115,4836051724,5104487181,5370841870,5643455248,5909793553,6176148242,6444600084,6713051927,6981552923,6713019171,6446664487,5639260973,5370825518,4305472395,5108681614,5375019919,5911890834,6176148371,6444600213,6713183128,6444600228,6176148392,5907712938,5639261100,5370825645,5102390190,4833954735,4565519280,4297083825,4028648370,3491777459,3223342004,2686471093,3493874697,4571810828,4840246285,5645552657,5911890963,6176148500,6444633110,6713101339,6444616738,6176148518,5907713064,5639277610,5370825772,5102390317,4833954862,4565519407,4297083952,4028648497,3491777586,2954906675,2686471220,5375020176,5911891092,6176148629,6444747927,6176181411,5907696807,5639277736,5370842282,5102390444,4833954989,4565519534,4297084079,3760213168,3491777713,2954906802,2418035891,3760213258,5104487695,5641358610,5909794069,6176181526,6444649754,6176181536,5907729700,5639277863,5370826025,5102406954,4833955116,4565519661,4028648750,3760213295,3491777840,2954906929,2686471474,4833955214,5641358739,5909794198,6176296343,5907729826,5641375141,5370842535,5104487849,4833971626,4565519788,4037037485,3764407726,3493875119,2957004208,2688568753,2149600690,4028648972,4297084429,4565519886,4833955343,5102390800,5370842641,5639278100,5907729943,6176214554,5907746336,5643456036,5372923431,5106585128,4838149674,4571811371,4303375916,4297084558,4565520015,4833955472,5102407313,5370842771,5639294613,5907861144,5641359011,5639261861,5375020710,4871704233,3265285807,3760213773,4028649230,4297084687,4565536528,4833955602,5102407443,5370842901,5639327511,5907746588,5641391904,5406478117,5138042663,3533721390,2992656176,3223342989,3491778446,3760213903,4028649360,4297084817,4565520274,4833972115,5102391189,5370875798,5639344026,5404397475,4871704488,4601171882,2422230961,2424328204,2980073485,3254800398,3523235855,3791671312,4060106769,4328542226,4596977683,4865429524,5133864982,5402333208,5670801436,5404381218,5138042918,4334833707,4068495404,3797962797,2426426124,1889555339,2418037681,1346393098,2424329649,1883264562,2954909711,3491780624,3760216081,4028651538,4297103379,4565522453,4833974294,5102426136,5370927131,5370828835,5104506916,4838152231,4569716777,2686474383,2954909840,3491780753,3760216210,4028668051,4297087125,4565522582,4833990807,5102475418,5370845344,5104507042,4303378602,2149603599,2686474512,2954909969,3223345426,3491780883,3760216340,4028651797,4297087254,4565539095,4833990937,5102475548,5102393636,4836071717,4569717032,2954910098,3223345555,3491781012,3760216469,4028651926,4297103767,4565539225,4834023835,5102410144,4836088226,4567620007,4299184553,4030749099,3491781037,3223345582,2688571922,2957007379,3225442836,3495975445,3764410902,4030765591,4299201049,4567636507,4834023965,4833958437,4567620134,4567669405,4833958561,4565572258,4297104039,4028652201,3760233130,3766508311,4030765848,4297104154,4565523228,4565556001,4297120548,4028668711,3760216873,3491797802,3495975830,4037041050,4297235355,4028668837,3760233383,3491781545,3766508568,4028652569,4034944027,4297186332,4028685347,3760233510,3491781672,3764411545,4032961692,3760250020,3491781799,3762330916},{100,63,21}},
['Archangel Egg']={64,47,2.8,2.1,2.79026084,{{255,255,255,0},{243,245,238,0},{234,231,232,0},{227,227,228,0},{228,223,226,0},{222,221,224,0},{248,245,199,0},{235,228,208,0},{232,221,200,0},{221,219,215,0},{255,255,141,1},{254,254,104,1},{244,236,120,1},{230,212,186,0},{221,210,193,0},{226,205,156,0},{232,204,109,0},{227,194,130,0},{225,186,110,0},{226,187,79,0},{223,177,76,0},{215,213,213,0},{215,204,178,0},{207,206,197,0},{203,190,169,0},{211,183,115,0},{228,171,75,0},{226,171,59,0},{225,170,54,0},{219,170,61,0},{206,170,87,0},{219,164,54,0},{210,163,61,0},{210,158,52,0}},{72479686687,73284993183,72211251360,70600638750,73821864223,72748122400,35972481429,37046223255,53152334233,70332203418,104960377245,107913167262,110865957279,108450038176,107107860897,104691941794,87512072611,70332203428,53152334245,53152334356,71405945365,71942816278,71405945367,88585814552,87512072729,103349764634,122140246556,142004470301,129119568414,124556165663,125361472032,129119568417,123482423842,105765700131,88585814565,71405945382,54226092583,35972465193,18792596010,87512072852,105765716629,122945569432,139051680410,141467599515,158915904156,159721226909,157573743263,159721210529,162674000546,141467599523,121871811236,104691958437,88585814695,71674380968,54494511785,35972465322,18792596139,122140246805,139051680534,156231549719,157305307928,174485193498,191665029917,191933465374,174753645343,157305307939,140125422373,122945553190,105765684007,88585814824,71405945641,54226076458,158379033493,192470336408,189249110937,207771173788,210187076510,211260818335,209381770144,207771157409,191665030050,190591288227,173411419044,156231549861,139051680678,87512073129,72748123050,210187076629,227366945814,242130895896,259310765081,262263555103,261726684192,242667766818,158110598185,121871811626,89927992453,107644748934,124287747208,122140247178,278906553493,297965470870,311387243672,311118808223,208308028586,122408682679,107107861688,109792216249,89391121594,141467600132,159989646597,162942436614,180122305799,197302174984,194080949513,211260818698,210723947787,225219462412,381985785118,381448897824,380106720545,226830075187,210187093300,193812514102,194349385015,177169515832,161600259385,162405565754,144151954747,123750860092,156499985794,179853870467,196765304196,213139867013,231393478022,245083686279,265753216392,266558522761,282127779210,299307648395,298770777484,313266292109,332325209486,434062247324,453389600157,454463341982,437820343711,436746601888,434867553697,434062247330,433525376419,328567113136,313803163057,313266292146,300112954803,300918261172,282664650165,266558539190,248573347256,230051300793,214213608890,197033739707,179853870524,159184340413,192470337025,193275643394,215018915331,245352121860,261189813765,280785602054,311655679495,328567113224,350310385161,348431336970,368563996171,386280736268,402386863629,400239379982,416345507343,502244853274,506271385115,506808256028,506002949661,505734514206,506002966047,506539836961,503587030563,503050159652,485064984101,416345507375,417150813744,402386880049,386280736307,369369302580,348431337013,350310385206,330983032375,315145340472,281054037561,264142603834,246425863739,210187077180,197839046205,193812514366,214213609089,214750480002,245083686531,263605732996,298233906821,311655679622,345746982535,366953383560,383596381833,398628767370,419029862027,434867553932,436748699277,455002326670,467885115024,519424722584,521844835993,539288946330,541438527131,540362688156,537411995293,540094252702,537409898143,537143559840,537948866209,536873027234,540899559075,537946769060,537409898149,519693158054,517545674407,485064984238,471643211439,455537084080,453926471345,437021329074,434867553971,416882378420,401581557429,384133252790,366955480759,350044047032,315684308665,298233906874,260116072123,242399332028,210189174461,214750480062,210187077311,210187077376,214750480129,210723948290,242936203011,263339394820,294475810565,315682211590,349505079047,364539561736,384401688329,397555025674,414736992011,436209731340,471106340624,487749338897,521305868055,522109077272,540631123738,541167994652,541167994654,540631123743,537411995426,540631156515,523988125478,522109077287,518887851816,487749338926,472719050543,455000213296,455537084209,437551908659,414466459444,401313122101,384401688374,298508633914,263337297723,241057154876,210723948350,208308029247,209650206592,210723948417,212066125698,246157428611,298233907077,312997857158,347359692679,383596382089,395944413066,437551908748,437019232141,453926471566,454463342479,471374776208,485064984465,517545674646,521574303640,541167994778,537680431003,537145657244,537946785693,536067721119,536604592032,540362688417,536069818275,537143560100,540899559333,519695255462,520230029223,519693158312,501707982764,485064984493,489091516334,453926487984,434867554227,415808636852,396212848565,381717333942,367221819319,349773514680,315413776313,264144701371,241325590460,212066125757,207234287617,211799787522,246696396803,263876265988,295817988101,315413776390,366416513032,379301414921,397555025930,418224556043,434867554316,455002310670,453926471695,471108438032,488823080977,485601855506,500097386515,498486757397,519424722966,522109077527,522109077529,541438527514,541167994909,537946769438,534725543967,537141463072,537678350369,541438527525,522109077543,522645948456,522109077545,502244870186,506271385644,489896822829,489628387374,471643211823,455537084464,454463342641,438088779827,416345507892,401583654965,378764544054,366416513079,350041950264,315682211897,246157428796,207502723133,212334561409,298233907333,315682211974,344941676679,361853110408,384401688713,401044686986,416077072523,437551909004,455537084559,489896839313,503587031187,503318595732,503050160277,523451254934,519961594007,521840642200,523451254937,537948866715,541436430493,540631124126,538483640479,540631124128,537680431265,536873027746,540631124131,537409898660,520230029478,523451254951,524256561320,523719690409,503587031210,506002950315,506539821228,489359968429,471376873647,455000230064,437283473586,436209731763,414466459828,383866914998,362121545911,344941676728,315145341113,260116072635,207502723330,246157428995,264142604548,294207375621,309776632070,345478547719,366687045896,381448898825,396212848906,413124282635,415808637196,437551909133,453926488334,471374776592,488286226705,488554645779,505734531348,520230029590,522109077783,523451255064,523182835993,537678334236,537409898781,536604608798,541167995168,535530850594,537678334243,537946769700,519963691301,519424723238,520230029607,523182819624,505734531369,505466079531,488286210348,489359952173,471374776622,455000213808,454463342897,434062248242,414198024499,396481284404,380375157045,367221819703,327493372216,310313503033,281054038330,263337298235,228977559868,212334561665,208578562434,246694300035,263874169220,293402069381,315413776774,349505079687,383596382601,395944413578,400776251787,417956120972,432988506509,454731778446,452047423887,468690422160,472448518545,488823081362,489362049427,489898920340,505466079637,503587031446,507080886679,523719690648,522645948825,523719690650,522914384283,523182819740,519426820509,517277239710,519961594271,524258658720,523182819745,518082546082,519693158819,522914384292,517277239718,502781725095,507076692392,505466079657,488554645930,489896823211,488554645932,472180083117,471911647662,450705246639,434062248368,433525377457,416077072818,401581558195,380375157172,366953384373,344404806070,332862081463,315682212280,275416893881,242936203706,194617821628,211797690881,228977560067,258237024772,275953764869,315682212358,330177726983,361584675336,366416513545,378764544522,398897203723,418761427468,430574684685,431646329358,450436811279,448557763088,467885115921,472716954130,488554646037,506002950678,507076692504,506539821593,523182819866,524256561691,522645948956,519424723486,523182819871,520498465313,518350981666,518619417123,503587047972,502781725222,503050160679,489896823336,489359952425,488286210602,472180099627,454463343149,451242117678,430035716655,413124282928,412855847473,395944413746,381985770035,364805900852,344404806197,327761807926,293133634103,278906554936,246425864761,206428981818,223608851075,258505460356,280787700357,312997857926,326956501639,344943774344,361584675465,380106721930,399165639307,414198024844,430841023118,447484037775,469495728785,467885116050,469227293331,488823098004,489359952534,506002983576,505734515355,506808257180,502781725341,506271386270,505734531743,501441645217,501171128994,501439548068,506002950821,488286210726,488554646183,488823081640,469227293353,472180083370,455002311339,453926472364,437283474093,437551909550,415808637615,400776252080,396212849329,383596382898,362121546419,350041950900,315682212533,292865198774,280517167799,242936203960,212602997433,175558904506,138246376123,208576465666,228977560323,261458250500,314876906246,327761808135,366684949257,381985770250,398897203979,400776252172,413392718605,435136006926,447484021520,452315859729,469764164370,472448518931,471911648020,487749339925,489628388118,488286210839,489359952664,505466080025,505734515482,506002950939,502244870940,506808257310,505734515487,506539821856,500902677282,484003842851,485333420837,489896823590,472180083495,468422003496,452047424298,438357216044,436746603309,421177346862,399702510383,380375157552,379301415729,362121546546,344941677363,310313503540,298502343477,278638119734,241862462263,206965852984,175558904633,143883520826,103618202427,207234288514,225487899523,263605734276,275953765253,293404167046,328835550087,345478548360,367221820297,380106722186,378764544907,396483382156,413126380429,413661154190,430841023375,430572587920,448020892561,452584295314,470301035411,467885116308,471913745301,489896823702,488825179031,489896840088,488286210970,489091517339,487749340060,503050161053,489896823710,489359952799,488823081888,484270164897,484003826594,468153551781,471374777254,472448519079,452047424424,454731778985,437283490730,420372057004,403462704046,386012302255,362926853040,361584675761,346015419314,310313503667,293402069940,261458250677,245083687862,228977560503,189517548472,155694681017,71137512379,206428982274,225756335107,259042331652,275416894469,327224937479,350041951240,364269030409,378496109578,383598480395,414734896142,430572588047,430304152592,453121182737,465200761875,465737632788,488556743702,485601856536,485870291993,488558840858,486138727451,486409260060,506539822109,488286227486,485333421088,467079810085,468958858278,471106341927,454194924584,436746603562,437820345387,416345508908,416884476973,383327947823,366684949552,361853111345,349236644914,311655681075,294475811892,263337298997,246425865270,229782866999,190322854968,155159907385,260116073604,275953765509,298233908358,332325211271,347626032264,366953385097,379303513226,401313123468,413661154445,417956121742,435135990927,431646330000,453121166481,452852731026,469495729299,467616681108,472448519317,488017775767,485067082904,485601856665,488823082139,505468177565,489359953054,488554646687,488823082144,468155649189,472716954790,472180083879,453930667176,455537085609,437283474602,438088780971,416882379948,403997478062,386549173423,364269030576,361588870321,344404806834,310045068467,293133634740,258505460917,242399333558,230053399735,191128161464,104423509178,228981755139,258237025540,275687427333,294207376646,330446163207,345478548744,362121547017,379032980747,395944414476,413126380813,413392719118,430304152847,433525378320,450436812049,448020892946,466276601107,467885116692,472716954901,489896824086,488823082263,487749340441,489896840475,489896824094,489359953183,486140824864,468958858534,472716954919,455000214825,437820345642,437283474731,416345525548,402925833518,385745964335,364805901616,349236645170,310581939507,297697037620,263337299253,241594027318,193007209784,160258084153,105497251130,258505461124,298504441222,332325211527,344945872264,366418611593,379032980874,383596383627,396481285516,417956121998,433256942991,436209733008,452852731281,452315860370,468421987732,472182181269,488286211478,486138727831,482917502360,485601856921,489359953306,488823082395,488286211484,505736613277,488286227870,468958858661,471643213222,471106342311,453926473129,436746620330,416882380204,416345509293,365342772656,344943775154,312997858739,297965473204,260116073909,241327689142,225219464631,195691564472,156768423353,104155073978,260116073988,277027507717,328835550727,381717351946,400776252940,413392719373,413661154830,435941314063,452315860497,452852731410,470301036051,471911648788,489359953430,485872389655,487749340696,486407163417,488288308762,489362050587,488554647068,489896824350,488823098911,468153552421,469227294246,472180084263,455000215080,455537085993,437820345898,437015039531,421177347628,417150815789,403729042990,386280738351,365611208240,362658418225,312729423411,298770779700,259579203125,224145722935,192470339128,160526519865,104423509562,223608852099,242938302084,278640217733,294475812486,327224938119,361316241033,364807999114,383864819339,395675979404,413124284045,413392719502,433525378703,435941297808,449094635153,450705247890,471911648915,472180084372,472716971669,489091518104,489896824473,489896824476,488286211741,486138728094,485333421727,483991260832,466811408035,449633603238,449899941543,450973683368,434599120553,434867556010,419566735019,420103605932,399702511277,383327948462,368295562927,351652564656,328567115441,314876907186,294207377075,281590910644,244278382261,206965853878,194617822903,126166781625,86706769594,228979658499,297697038086,326688067335,346015420168,349773516553,384133254923,400776253196,395946512141,418226654990,416882380559,435672862480,435945492241,454731779858,455002328851,471374778133,471643213590,468692520727,468958859032,472180084505,471108439834,468958859035,486138728220,484259680029,466542956318,466811424544,449631522596,432183201575,432451637032,417419267881,402655301419,403460607788,382522642221,369369304878,351115693871,335009566512,312729423665,292865199922,258773897011,247231172404,209650208565,172337680182,155426246455,298233909126,309776633735,327224938376,347359694729,367221821322,380375158667,383596384140,418224557967,435135991696,455537086354,455537102741,471911649176,472716955545,472182181787,471643213724,468958875549,467079810975,466811375520,449631555489,432451637157,433793814438,434599120807,420103606184,403997478825,403460607914,385475432363,386817609644,365611208621,352189435822,334741131183,318098132912,278906556337,263337299890,241594027955,212871434164,175827341237,137977941942,108718477239,293402071046,309508198407,327761809416,364269031434,363195289611,379032981516,395675979789,399167737870,414466461711,418761429008,438090878994,437820346387,455000231956,455537086486,451510571031,455537086489,454197006362,472716955676,471374778397,455537086494,455000215583,452047425568,449899941921,449631506466,432451653667,434599120933,420103606310,420640477223,402386882600,385475432490,368027127851,366148079660,348162904109,331788341294,299576086575,283738394672,261726687281,242936205362,207234289715,177706389556,143883522101,103618203702,310045069447,332056776840,350041952393,345478549642,366416515211,383596384396,396212850829,414198026383,419029864592,420372041873,437015040147,437820362900,453926473878,451778990231,451242119320,452047425689,453926490267,454194909341,453926473886,452047425695,433793814688,432720072865,432451653794,415273865380,416613945509,400239382694,402923737255,385209094312,386280738985,368027127978,352189436075,348162904236,329909293229,300920361134,280248733871,264411041968,245083689137,207502725298,172069245107,108986912949,74358739126,276222202119,292328329480,314876907785,344136372491,344941678860,361853112589,381985771790,379838288143,399970947344,403997479185,421177348370,420372042003,417150816532,421177348373,438357217558,434599121175,432988508440,434330685721,437820346650,438357217563,437820346652,437015040285,438357217566,437820346655,434599121184,415542300961,415271784738,400239382821,403997479206,386817610023,369637740841,351921000746,351384129835,330446164268,312729424173,262531993903,242399334704,230051303729,194617823538,155963117875,241325592968,294475813259,310581940620,328298680717,349505081742,367490257296,369637740945,386549174674,381448901011,397018157460,403192172949,403997479318,417419252119,414198026648,416882381209,420640510362,419835187613,420640477599,417419252128,415271768482,398091915683,382256304549,383059513766,385475432871,368297660840,350847259049,351115694506,334204260779,312729424300,313266295213,283201524142,262800429487,212602999217,189519647154,259042333196,292596765197,294207377934,330983035408,352457871889,352189436434,365342773779,366684951060,386012303893,385475432982,383327949335,398628770328,399702512153,403460608538,400507818523,402118431260,402386866717,402655302174,402386866719,400239383072,398360334881,398091899426,380912046627,368563999270,369100870183,352457871913,333667389994,335009567275,315950649900,297428603437,283738395182,262531994159,212334563889,224145724044,241325593229,296623297168,317561262737,331788341906,333130519187,350310388372,351652565653,369637741206,368027128471,368832434840,384670126745,385743868570,386549191323,385475433117,386817610398,386280739487,385743868576,381180465825,380912046754,363732161188,365879644837,369637741222,351921001127,348968211112,331788358313,317024391851,296891732652,299844522669,282396218030,245083689647,174216729356,261726688016,283738395409,297428603666,312729424659,313803166484,334472696597,335278002966,350847259415,348968211224,348431340313,369100870426,365879644955,365342774044,365879644957,368563999518,368295564063,369100870432,364000596769,363732177698,363463725860,348699775781,351921001254,350847259431,331788342056,330983035689,314071601962,317561262891,299307651884,282664653613,262263558958,242667770671,227366949776,248841786257,280248734610,276759073683,298770781076,300112958357,317292827542,334204277655,331788342169,348968211354,351652565915,348699775900,352189453213,350847259551,351115695008,346820727713,346552325026,350847259557,335278003110,333667390375,335278003112,314071602089,296891732906,300918264747,283201524652,279980299181,242399335342,193007211536,231661917201,245352125458,262263559188,279443428373,295549555734,300112958487,318098150424,314340037658,334204261403,334741132316,333935825949,335278003230,334741132319,333935825952,330714600481,329372439586,331519906852,317561263141,317024392230,317561263143,299844523048,296623297577,282933089322,264947913771,265216349228,245352125485,225487901742,178511697040,196765308049,228172256402,244546819220,261726688405,279711863959,300381394072,299576087705,297428604058,314340037787,314608473244,317561279645,316755956895,317561263264,313534731425,311924118690,312460989603,316487521444,299307652261,296623297702,296086426791,278906557608,278369686697,262263559338,248304915627,231661917356,227635385517,140930733328,176901084433,193812518162,261726688535,280248735000,282127783193,279443428634,294207378715,295549555996,297428604189,299844523294,299307652383,300918265120,296354878753,299307652387,299576087844,283469960485,277027509542,274880025895,258773898536,245083690282,232198788395,210992387372,193007211821,142272910737,176364213650,262800430488,266290091417,259847640474,275148461467,277027509660,282933089693,282127783326,283201525151,283738396064,279980316065,283201525155,279711864228,261726688677,259847640486,210187081130,193275647403,191128163756,122408687121,245352125976,244815255065,242399335962,263337301531,257968592412,261726688797,265484785182,266021672479,265216349729,265484785186,262531995171,259579205156,241057158693,190859728426,175827342891,247231174296,245083690649,258237027996,259579205277,262263559838,262532011679,264411043489,261726688930,259847640739,173679859371,244009948952,246425868057},{1080049695,1077952672,1075855646,539034005,807420313,1075855770,1612808605,1344291235,1075855780,807420325,807420436,1075888661,1344307736,1612726810,1881162268,2149597725,1881227806,1612743203,1344291365,1075855910,807436839,538985001,270549546,1344291476,1612759701,1881178776,2149614234,2418131612,2149597859,1881162404,1612743333,1344291495,1075856040,807420585,538985130,270549675,1881162517,2149597974,2418066199,2686501658,2954920733,2686518047,2418049827,2149597989,1881162534,1612727079,1344291624,1075856169,807420714,2418033557,2954920856,3223421852,2954920866,2686469028,2418033573,2149598118,1344291753,1075856298,3223340053,3491775510,3760210968,4028646425,4028662815,3760210978,2418033705,1881162794,1344291973,1612743814,1881195656,4297082005,4565517462,4833952920,4833952927,3223340202,1881162935,1612743864,1344292026,2149598468,2418050309,2686469383,2954921224,3223356682,3491775756,5907744030,3491775795,3223356724,2954921270,2686469432,2418050361,2149598523,1881163068,2418034050,2686469507,2954904964,3223340421,3491775878,3760211335,4028663176,4297082250,4565534091,4833953165,5102388622,6713001372,6981453213,6713066911,5102388656,4833969585,4565534131,4297082293,4028663222,3760211384,3491775929,3223340474,2954905019,2686469564,2418034109,2954921473,3223340547,3760211460,4028646917,4297082374,4833953287,5102388744,5370840585,5639259659,5907695116,6176146957,6444566031,7786907162,7518307877,6444582447,6176146993,5907695155,5639259700,5370840629,5102388791,4833953336,4297082425,4028646970,3760211515,3223340604,2954921533,3231745665,3772794499,4060104324,4578100869,4852827782,5383407239,5653939848,5920278153,6188713610,6455051915,6721406604,6994036366,7262455440,8067778200,8332183194,8065681062,7526696622,7260358319,6991939248,6721406642,6452954804,6184519349,5918181046,5649745591,5379212984,4844439225,4573906618,4039132859,3766503100,3225470653,3225437952,7526696721,8063567639,8063567656,8061470614,7790938028,7524599725,3225438141,7524599826,7788873747,8057276457,7790954538,3227535618,6450858252,6719293709,7522502931,7786760468,8059373850,8323762459,8057276709,7788841257,7520405804,7251970350,6713002290,6444566835,6176131380,5907695925,5102389560,4297083194,3491776828,3225438593,6182422923,7254067601,7522503060,7786776981,8055327131,8055179686,7786760615,7518325162,7249873325,6981437871,6713018800,6444566962,6176131507,5907696052,5639260597,5370825142,5102389687,4833954232,4297083321,3760212410,2954906044,3500165635,4318054917,5123361287,5658135049,5924473354,6717196814,6983551503,7254067730,7522503189,7786793494,8055310875,7786793508,7518341672,7249889835,6981454381,6713002543,6444583472,6176131634,5907696179,5639260724,5370825269,5102389814,4565518903,4297083448,3760212537,3223341626,5389699720,7266650771,7532989078,7786973847,7518341798,7249889961,6981454507,6713019053,6444567215,6176148144,5907696306,5639260851,5370825396,4833954485,4565519030,4297083575,3760212664,3223341753,2686470842,2149599931,3227536130,6192909068,6459247373,6727682831,6981454608,7264553748,7533005591,7786892057,7518358307,7249906471,6981454634,6713019180,6444567342,6176131887,5907712816,5639260978,5370825523,4833954612,4565519157,4297083702,3760212791,3223341880,2686470969,2149600058,1612729147,4584393606,5924473739,6461344654,6729780112,6994037649,7264553877,7530941337,7797230493,7528893342,7260392357,6991940520,6723505066,6455069612,6186617774,5918182319,5649763248,5381311410,4844440499,4576005044,4039134133,3770698678,3502263223,2965392312,2428521401,1075858363,1619020986,3502263555,3762310788,5645553290,7251971734,7518391965,7249907363,6981471910,6713020073,6444584619,6176132781,5907697326,5639261871,5370826416,5102390961,4833955506,4565520051,4297084596,3760213685,3223342774,2954907319,1881165497,1344294586,5377117961,6182424333,6450859791,6717198097,6983569170,7252037399,7518326556,7249956638,6981472036,6713020199,6444584745,6176149291,5907697453,5639261998,5370826543,5102391088,4833955633,4565520178,4028649267,3760213812,3223342901,2686471990,2418036535,4838150023,5106585480,5911891852,6983552917,7249940380,6981488545,6713036709,6444568488,6176149417,5907713963,5639262125,5370826670,5102391215,4833955760,4297084849,4028649394,3760213939,3223343028,2686472117,2149601206,1612730295,5641359371,6178230286,6446665744,6715117586,6981439508,6983585815,7249907739,6981505054,6713036835,6444584998,6176149544,5907697706,5639278635,5370826797,5102391342,4565520431,4297084976,4028649521,3760214066,3223343155,2686472244,2149601333,1612730422,5370826890,6444568721,6713020564,6981439638,6981505179,6713053344,6444585124,6176149670,5907714216,5639262378,5370843307,5102391469,4567617710,4297085103,4028649648,3760214193,3223343282,2686472371,1612730549,1075859638,4297085191,4565520648,4833956105,5370843403,5639262477,5907714318,6176149776,6444618002,6713168150,6444618017,6176149797,5907714343,5639262505,5370843434,5102391596,4836053293,4032844079,3760214320,3491778865,2959102258,2418037043,3760214408,4565520779,4833956236,5102391693,5370827150,5639278992,5907714450,6176166292,6444749207,6176149923,5907730853,5641359784,5370843561,5104488875,4836053420,4301279662,3225440689,4028649996,4565537293,5102391824,5370843665,5639279123,5907730965,6176297496,5907730979,5639279142,5370827305,5104489002,4567618093,3491779212,3760214669,4565521040,4833956497,5102408338,5370843796,5639295638,5907862169,5639295652,5370843815,5104489129,4836053675,4567618220,3762311855,2686472972,4028650256,4297085713,4565521170,4833973011,5102408469,5370860311,5639426842,5370860325,5104489256,4833956650,4299182893,4028650286,3491779472,3760214929,4297102226,4565537684,4833956758,5102424983,5371007898,5102408614,4833956777,4565537706,4297085868,3760214958,2954908688,3491779601,3760215058,4028650516,4297085973,4565537814,4833989656,5102539803,4833989669,4565537832,4297085994,4028666923,3760215085,3491779630,2686473360,2954908817,3491779730,3760215188,4028650645,4297086103,4565554328,4834104475,4565554341,4297102504,4028650666,3760215211,3491796140,2149602576,2686473489,2954908946,4028650775,4297119000,4565669147,4297119013,4028650792,3760215338,3491779883,3223344428,2954908973,2149602705,2686473618,4028683672,4297233819,4028667301,3223344554,2954925483,1881167377,3760248344,4028798491,3760215589,2954909226,2688570923,3762329240,4028765852},{205,157,43}},
['World Burner Egg']={64,34,2.8,1.86666667,2.79026084,{{199,198,199,0},{191,161,165,1},{150,143,145,0},{178,112,116,0},{127,125,126,0},{112,101,103,0},{171,73,79,0},{115,78,83,0},{98,85,86,0},{98,73,76,0},{89,79,80,0},{84,69,70,0},{84,62,65,0},{69,62,62,0},{118,47,50,0},{86,46,50,0},{76,42,47,0},{75,32,38,0},{69,45,48,0},{70,32,38,0},{69,29,35,0},{59,46,47,0},{55,38,40,0},{61,32,37,0},{51,33,35,0},{63,27,32,0},{57,27,32,0},{50,26,29,0},{42,26,27,0},{73,19,27,0},{46,22,25,0},{43,22,25,0},{42,19,22,0},{37,21,23,0},{36,18,20,0},{33,14,16,0}},{87243636764,105228812317,105765683238,104423506052,123482423429,123213987974,140393873543,123213987977,123482423434,106034151563,88854249614,70063767707,92343910556,108986908829,120798068901,108989005990,106570989735,126166778116,128314261765,144688840966,145494130952,144688824585,145494130954,127508955403,128582697228,111134392589,92343910670,70063767823,52883898650,72748122395,89927991580,106034118941,104423506213,104960377127,86975201576,104155070770,108986908979,109523779892,126703649077,126166778166,143346647351,143883518264,126703649081,126166778170,108986908987,106570989884,123750859136,125898359169,126166778243,144688824708,145494131077,163479306630,158647468423,173679853960,161600258441,159721210250,161868693899,156499984780,158379032973,146567872910,125898342799,123750859152,90733298074,103886651803,120798069149,86975201701,87243637158,87780508071,69526897064,88048943537,106302554546,111939699123,108181602740,124287730101,127508955574,144688824759,141467599288,124287730105,128314261946,110331183547,109523780028,108718473661,109523780030,105230909887,127508955648,128582697473,128314262018,145762566659,162674000388,161868694021,181196046854,192738771463,190591287816,195691561481,193544077834,195959996939,190591287820,190859723277,198375916046,180927611407,176632644112,154889372177,122408682009,129119568410,121066504731,123482423836,70063768102,73821864487,70600639016,60400091689,91807040049,111402828338,112208134707,107107861044,121873908277,125629907510,143615083063,141203358264,121871811129,129656439354,110329086524,109523780157,111675458110,144688824960,145494131329,143615083138,160794952323,159721210500,178511692421,190591287942,206965850759,207771157128,230051299977,227903816330,230051299979,227098509964,224145736333,227098509967,232198783632,211797688977,209650205330,176632644249,156499985050,155426243227,140662293148,52885996198,56910430887,52347028136,35704029865,39998997162,37851513519,56373559984,92343911089,111136490162,104691942067,103886635700,126972084918,142543438519,121066504889,124019294906,109792215739,108181603004,109255344829,105765683903,160526516992,163210871553,159721227010,176364208900,194349384453,207771157254,224145720071,242130895624,247231169289,262263554826,264411038475,261458248460,275685344013,278638117647,284006826768,283469955857,279711859474,227366945561,206428979994,189785981723,175022031644,58252608295,51810173736,43220222762,57447301935,76774654768,93417653041,121871811379,121066505012,124019295029,144151954230,138246374201,121871811386,125629907771,107376296764,108181603133,105228813119,176632644480,180390740865,177974821762,194080949123,210723947396,230051300229,242130895750,258505458567,276490634120,281590907785,296623293322,298770776971,316487533452,317292823438,317829694351,317292823440,335009563537,331251467154,296086422425,275685327770,276490634139,260921377692,240788718493,173142983590,178780128167,172069241768,154889372585,160258081706,160526517167,179048580016,197570610098,198375916467,197570610100,197033739189,195154690998,194080949175,192738771896,173411419065,156231549882,159989646267,142004470716,142541341629,146031002558,140393857983,193814610944,197570610177,194080949250,211260818435,227903816708,245888992261,261458248710,278638117895,295817987080,314608469001,330983031818,333398950923,352189432844,348968207373,364537463822,364805899279,367758689296,369369302033,383864816658,379032978451,367221818393,365342770202,351384126491,352994739228,346552288285,278369682469,283738391590,283201520679,279174988840,278906553385,258773894186,241862460462,263337296943,265216345136,265753216049,262263555122,261458248755,261726684212,266021651509,263874167862,245083702327,227366945849,210723947578,194349384763,176364209212,160794952765,162674000958,158110598207,194886255745,190322852994,230051300483,244546815108,261726684293,296354858118,314608469127,331788338312,348699772041,365342770314,367758689419,386549171340,399165637773,396749718670,416077071503,416882377872,420372038801,437820343442,435941295251,435135988884,454194906265,438894085274,438625649819,438357214364,437015037085,431914763422,414734910623,397555057825,397286589604,399434073253,403729040550,403997476007,404534346920,385206994089,379301414058,361316238509,366684947630,369100866735,351115691184,350847255729,347626030258,347357594803,330446161076,334472692917,315413775542,296354858167,297160164536,261726684345,242399331514,225219462331,210455512252,197033739453,197570610366,191665030335,211797705984,207502722306,245620557059,346023806215,366154368264,382522639625,400247768330,401849992459,420372038924,436746601741,453389616398,468960953616,471106340113,489091515666,489628386579,487480902932,521035334937,524256560410,523719689499,522914383132,523988124957,523451254046,520498480415,519961625889,520766899492,519961593125,522377512230,507076691239,506539820328,504660772137,482380629290,470301033774,454194922799,435672859953,434599118130,417687684403,402118427956,386012300597,366953383222,365349061943,333130515768,311118808377,224682591548,209381770557,213408302398,207234286911,209113335168,211797689729,243741508995,383063704969,417693975947,437820343692,436482360717,451242132878,488286209425,488556742034,506271384979,504123901332,539020510618,541436429723,540903753116,541436429725,539825816990,537141462431,537680512416,522109076902,523451254183,523988125096,518887851433,488286209454,471106340271,454194906544,453658035633,434062263730,419031958964,403198461365,384139543990,348970304952,311387243961,209650206142,208844899841,438357214732,451778987534,451242116623,470569469456,489091515921,506539820563,504660772372,500902675989,518887851542,521303770647,516740367896,538215204378,541704865307,539291043357,537678349854,520498480678,521572206120,518082545193,501171111466,504660788779,489896822317,489359951406,472180082223,454735971888,452047423025,434062247474,434599118387,311120905785,207502722622,207502722689,437822441100,451244213902,452047423119,465737631376,485333419665,489896822418,506271385235,506808256148,507613562517,524793448086,517545674392,535530849946,540899559067,537141495454,537678333601,539288979106,537678333605,520498464422,519961593511,520498464424,516740368041,500365805226,507613562539,507345127084,490167355053,488286209710,468421985967,450705245873,433525376690,436209731251,419300394676,351384127160,206160545470,367490254600,383327946505,436746602253,453660133135,466274502416,485870290705,489091516178,501976418067,505197643540,507076691733,524524996374,524793431831,522914383640,521303770905,541704865562,541436430107,541704865564,539825817373,539557414686,539825817377,541167994658,540631140131,539825817381,522645964582,523988125480,524524996393,505734514474,507345127211,507076691756,488017774382,465737631535,455537084209,437551908658,434599118643,365879641911,345478547256,310313502521,310313502599,345478547336,365074335625,383059511178,401313122187,403460605836,419566733197,434599118734,456073955216,472448518033,471643211666,482917500819,486407161748,489628387221,507076691862,507613562775,504660772760,521840641945,524256561050,524524996507,524793431964,524256626589,523719690146,522914383779,522645948324,523719690149,524256561062,507076708263,506539820969,490165274538,489896822700,470837905325,470569469870,448289343407,434062247857,420908910514,400239380403,402386864052,386280736693,367490254774,348162901943,329640855561,350310385674,367490254859,386549172236,402386864141,399702509582,419298297871,438088779792,431109457937,447484020754,448289327123,470569469972,468958857237,470837905430,490433693719,486675597336,484528113689,506808256538,507345127451,507613562908,507076757533,506808289314,507345127461,490165274662,489896822824,472716953641,471374776362,472985389099,454731778092,451242117165,436209731630,431109457967,413124282416,398897203249,404265912370,383059511347,368027125812,351115692085,331251468342,312460986423,294475810953,313534728330,331519903883,352189433996,368027125901,382522640526,402118428815,404265912464,413929588881,430304151698,431109458067,436209731732,451242117269,451778988182,471374776471,473253824664,472716953753,470837921946,488286242972,489091516575,487480903840,488286210209,489091516578,486944032931,469764163748,469495728293,469764163750,470032615591,453658036393,453389600938,436209731755,433525393580,419029862574,398897219759,383327946929,369369303218,347894466739,334472693940,315682212021,293133633718,316487518476,350847256845,347626031374,366953384207,386549172496,381985769745,398897203474,416882379027,417687685396,414734895381,431646329110,437015038231,455537084696,453926471961,453389601050,451779004699,468958857501,468153551134,467079809311,466274502944,466811373857,467079809314,449899940131,453121165604,452315859237,449363069222,449094633767,432451635496,432720070953,416345508138,419029862699,414198024492,396481284397,384670124334,383059511599,361853110576,350041950513,349505079602,310581938483,300649826612,280785602869,258773895478,300381391244,312192551309,326688065934,329640855951,351920998800,362121546129,379301415314,383327947155,400239380884,396481284501,414466460054,421445781911,419835169176,438088780185,436746602906,436209731995,433793829276,431914764702,432451635615,432988506528,431646329249,434330683810,438894086563,438088796580,435941296550,415003330983,415540218280,397555026346,398360332715,380643592620,379838286253,367490255278,348162902447,327761807792,333667387825,314876905906,267095394740,246425864629,207234288054,264947911180,277564377613,311924115983,335009565200,329640856081,346820725266,365879642643,367490255380,379301415445,381180463638,404534348311,403997477400,404534348313,401581558298,415540202011,414734895644,415003363869,415271766560,415808637473,419566733858,421445782051,416077072932,399702510117,404265912870,401581558311,399970945576,380912044585,364000594475,362926852652,346015418925,331519904302,331788339759,313266293296,298233907761,279711861298,229782866484,195423128117,213676739212,243204639373,276222200463,298502343312,311655680657,330714598034,333130517139,350310386324,346820725397,365611207318,370174610071,386012301976,383864818329,380912028314,381448899227,397823462044,397555026589,399970962078,402655300256,404265912993,403460606626,404265912995,379569851044,381985770149,387086043814,386280737447,369906174632,368832432809,347894467242,346820725419,328835549868,329103985325,312460987054,295281117871,274880023216,260384508593,244009945778,193812515508,160526518965,178243259148,209381772045,260921379600,293402069778,312460987155,311655680788,332325210901,352994741014,350041950999,346552290072,363732159257,362926852890,363195288347,364000594716,382791076637,386280737566,387354479391,386549173024,385475447585,369369303843,361584675620,362658417445,370174610214,350847273767,351920999209,333667388202,315950648107,313534729004,295012682541,276222200622,224414157617,158110599988,123750861621,143078214540,174485162893,224682593168,294207376277,318635002774,332862081943,329103985560,329372421017,346820725658,348431338395,350578822044,351652580253,351115692959,352457870240,351920999329,352189434786,350310386595,344404806564,345210112933,333130517414,333667388327,335278001064,318366567337,317292825514,299307649963,282933087148,279711861677,258773896110,87243639733,122945555468,172069243920,261189815318,284006829079,277832813592,296891730969,301455133722,315413777435,316219083804,317292825629,317561261086,318366567455,318635002912,317292825633,328030243874,309508230179,310045068326,296623295527,301455133736,284006829097,283469958186,264947911723,247499607084,244009946157,224682593326,86975204492,209113336982,229245996183,242667768984,243741510809,262531992730,262800428187,281859345564,283201539229,283469958303,301186698400,300112956577,296623295650,295817989283,275685330084,276490636453,281859345574,282933087399,266290089128,266558524585,247768042666,230588173483,226561641644,208308030637,173142985902,156768423190,180122307863,192470338840,209381772569,208576466202,225756335387,245352123676,247499607325,248573349150,266021653791,265216347424,265753218337,266558524706,267095395619,258505461028,242399333669,249915526438,247768042791,231661915432,231930350889,212334562602,192201903403,191128161580,173948292397,138514812206,126703652247,146836311448,160258084249,173948292506,191933468059,208576466332,209385967005,212334562718,232735657375,232467221920,231930351009,231393480098,231930351011,224951029156,227903819173,215018917286,214750481831,215555788200,194886258089,174216727978,157573729707,156768423340,138783247789,123213991447,143078215192,161868697113,177976921626,175022034459,191665032732,209381772830,209113337375,228172254752,229782867489,231661915682,232467222051,227098512932,212871433765,214482046502,212066127399,192470339112,191665032745,175022034474,157842165291,138783247916,177169518235,192201903772,208576482974,226293206688,225487900321,228977561250,232198786723,230319738532,213408321189,208308031143,191396597416,191933468329,173948292778,157036859051,176632647451,197035839260,212334563101,211797692190,209650208543,226561642272,226024804129,226293206820,209381773093,209650208550,209381773095,194617823016,195423129385,174485163818,173948293019,215555788701,215287369630,231661916064,230856609697,229245996962,228172271523,210992385957,213139869606,214213611431,194886274984,190322855964,212334563357,212871434270,211260821535,228709175328,227903819812,210455531557,210187079719,190322855976,207502725277,208576483486,225756336288,224414175393,224682610851,207234289829,206428983462},{1348485148,1616920605,1616920614,1612726404,1881178245,2151710855,1881178249,1612759179,1346388110,1077952667,1881161893,1614823591,1881178372,2149597446,2149613833,1881178379,1612726541,1075855631,807420186,1612726565,1344291112,1619050802,1887469877,2158002487,1887469881,1619034427,1881211264,2149613956,2418049414,2686468488,2418098569,2149597582,1881178511,1344291226,1612743067,1881162141,1344324005,1077952936,1350582705,1619050941,1881195008,2149597699,2418049540,2686468614,2955018759,2686485007,2418033169,1881211417,1075872294,807420457,2149630592,2418049667,2686468741,2954904198,3223356039,3491889801,3223356049,2686468761,2418049690,2149597852,809550502,539001513,538985135,807420592,2418082560,2686468868,2954904325,3223339782,3491775239,3760227080,4028678922,4297163533,3491775257,3223339802,2954904347,2686468892,807420713,538985258,807420719,1075856176,1612727090,1881195315,2149598006,2149598009,1881178938,1612727100,2686501760,2954904451,3223339908,3491775365,3760210822,4028646279,4297098120,4565533578,4834018188,5102404497,4565517209,4297098138,4028646300,3760210845,2686501798,2418049961,2418033583,2686485424,2955002802,2686469049,2418049978,2149647292,2957034496,3223340035,3491775492,3760210949,4028646406,4297081863,4565517320,4833952777,5102404618,5370840076,5639308302,5907710994,5639275545,5370856475,4297147429,4028646442,3760210990,4028761135,3760227383,3491775545,3223340090,2954904635,2686469180,2418066493,3491775619,3760211076,4028646533,4565517446,4833952903,5102388360,5370823817,5639275658,5907694732,6176146573,6444598415,6713033874,6981436569,6713066650,6444582047,6176244897,5907711145,5639292077,5370873008,5102404788,4833952950,4565533879,4028646585,3760211130,3491775675,3223340220,2954937533,3223373056,3762308355,5379212551,5647648008,5916083465,6176146698,6444565772,6721389837,6989841678,7249888528,7518340370,8055391513,7786775847,7518307626,7249872174,6981453103,6713017649,6444565811,6176130356,5907694901,5639275830,5102388536,4842341689,3491775804,3223373117,3223356800,6182421898,6450857355,6719292812,7256163728,7524615569,7793051027,8330085786,8061519270,7524599214,7256163759,6987744688,6719309234,6450857396,6182421941,5913986486,5645551031,5377115576,3227534782,3225437697,7790937621,8059405846,7790970410,7522502189,8057276185,4833953671,5370824584,5639260041,5907695498,6176147339,6444566413,6713001870,6981453711,7249889169,7518341011,7786776470,8055375770,7786776487,7518341034,7249889197,6981453743,6713001905,6444566450,6176147379,5907695541,5639260086,5370824631,5102389257,5370824714,5639260171,5907695628,6176147469,6444566543,6713018384,6981453842,7249905684,7518341143,7786924058,7518341158,7249905705,6981453868,6713018414,6444566576,6176147505,5907695667,5639260212,5370824757,5102389302,4833953847,4565518473,4833953930,5102389387,5370824844,5639260301,5907695758,6176147599,6444566673,6713034898,6981453973,7249938583,7518423196,7249938596,6981453993,6713034923,6444566702,6176147631,5907695793,5639260338,5370824883,5102389428,4833953973,4565518518,4833954060,5370841357,5639260431,5907712272,6176131346,6444599571,6713018646,6981503256,7249955101,6981503267,6713018664,6444599594,6176131373,5907712302,5639260464,5370841393,4833954099,4565518644,4297083189,4028647734,4565518732,4833954189,5102406030,5370825104,5639260561,5907712402,6176147860,6444599702,6713215385,6444599719,6176147882,5907712428,5639260590,5370825135,5102406064,4833954226,4028647860,3760212405,3223341494,4028647948,4297083405,4833954319,5102406160,5370825234,5639277075,5907712533,6176180759,6444714523,6176180773,5907712553,5639277099,5370825261,5102406190,4833954352,4565518897,4297083442,3491777076,2954906165,3223341708,3760212621,4297083535,4565518992,4833954449,5102406290,5370841748,5639277206,5907745432,6176246428,5907745444,5639277224,5370841770,5102406316,4833954478,4565519023,4297083568,4028648113,3760212658,2954906292,2418035381,2686470924,3223341837,4028648208,4565519122,4833970963,5102390037,5370858262,5639310105,5907778333,5639310115,5370858279,5102390058,4833970987,4565519149,4297083694,3491777329,2418035508,1881164597,2149600140,2686471053,3491777424,4565519253,4833954710,5102422935,5371005850,5102422950,4833971113,4565519275,4297100204,4028648366,1344293813,1881164812,2686471184,4028648470,4297100311,4565535769,4834053147,5102390306,4834004003,4565535783,4297100329,4028648491,3760229420,3491777582,1344294028,3223342230,3491777687,3760229528,4028664986,4297133212,4565568672,4297133220,4028665000,3760213162,3491794091,3223342253,2686471342,2418035990,2686471447,2954906904,3223358745,3491777819,3760246044,4028730655,3760246053,3491794216,3223342378,2954923307,2686471469,2149600558,1883262359,2151697816,2420133273,2690665882,2954907035,3223375260,3491876255,3223375270,2963295657,2692763050,2418052523,2149600685,2692763163,2963295772,3233861149,3502329376,3231764005,2963295784,2420133419,2149600812,3223359653},{46,17,25}},
['Aetheron Egg']={64,58,2.8,2.56666667,2.79026084,{{255,255,255,0},{255,255,231,0},{246,255,241,0},{250,243,217,0},{254,252,164,1},{245,228,174,1},{251,244,83,1},{237,214,179,0},{220,208,178,0},{238,209,103,0},{233,190,106,0},{200,187,139,0},{230,166,91,0},{228,162,13,0},{219,141,37,0},{186,167,129,0},{164,158,135,0},{161,137,95,0},{239,107,91,0},{165,111,63,0},{128,118,94,0},{108,92,72,0},{238,62,67,0},{156,63,56,0},{134,61,48,0},{132,51,44,0},{204,28,33,0},{131,33,28,0},{113,34,29,0},{79,68,53,0},{77,52,44,0},{97,33,28,0},{80,31,27,0},{85,19,16,0},{85,6,6,0},{54,35,25,0},{36,9,7,0},{52,0,0,0}},{138783244296,121603391497,104423505931,138248470663,140662292616,123750875273,105497247883,75164057780,75432476854,74090299575,141203357960,124019310857,106308845835,77049381172,77848412469,75164041527,105765683588,122677133701,139856986503,124038168969,123752956298,77579960757,77848396214,77043089847,74090299832,57984172473,40804303290,106839425540,123750875653,140930728455,77043089973,77579977270,77043089976,59863220793,41878061626,107644732036,126435213957,124019294854,142541357703,124019294858,77848445621,60668527289,43488658106,42683351739,105228813060,122945553157,123750859526,140932825863,141201261320,123750859530,105497248523,76237800244,77579961142,77848396599,75703010104,58521043769,39462126394,121066505093,121882297222,124019295114,106839425931,103349765004,36240901031,36509336488,36240901033,77043090356,77848413109,75969348535,57447302073,35167159226,121603376133,139062166535,140941214728,123750859786,106577282059,105765684236,105497248781,87243637774,73553429543,74627171368,73553429545,53689205802,108718490674,94222976052,95028266038,93149217847,92882879544,74629268537,53420770362,121334940805,124021392522,106841523340,106570990733,88317379726,122140247207,125093037224,126166779049,107913168042,104960378027,128582698161,144957260978,129119585459,128582698165,112208135350,110329087159,121066505477,106839426317,88590009614,121066521884,138246374686,138783245599,138246391072,154889372962,173679854888,177706403113,157842162987,162942436657,180927612210,163479323955,146567890229,127508956471,108986910008,91807040825,107376297348,123213989253,123750860170,106571007372,121066505624,121334941081,139051681178,156231550363,173411435932,190591337886,207771174306,207234287012,224682591653,228172252585,229245994410,210992383403,208039593388,214482060721,197302175155,180659176884,179316999605,163747743158,144688825783,126166779320,108989007289,73016559034,108450039300,128045827589,125361473034,106839459339,121066505751,156231550488,158110598681,175290467866,192470337051,209650206236,225756349981,242936219167,260116071969,259310765602,261189830179,276490634789,276222199334,277027505704,280785618473,262532007467,259579201069,248841782833,249647089202,232198784563,215287350836,198107481653,180927612470,161868695095,143346648632,93417653818,56910431803,125629908612,128314263173,139051681414,141199181449,142541342347,124019295884,123750860429,105765684878,87243638415,70063769232,172874548887,192470337176,209650206361,224951027354,242936202907,258773894812,275685344925,292865197727,293133633184,310313518753,310850373283,312729421476,329909290661,328835548838,332325209769,315145340586,314071615147,312192550573,294207375024,281322473137,284006827698,266558523059,249647089332,232467220149,213408302774,195959998135,160526517944,126166779577,111939700410,74090301115,124556166914,141736036099,160258082564,162405566213,173411419910,190591321863,193544079114,194080950027,192738789132,175290468110,158110598927,157036857104,138783246097,241325590295,260116072216,278369683225,293670520602,310850373404,328030258973,345210144543,362389997346,364269029156,364000593701,362121545510,365611206441,366684948266,348431353643,345478547245,332862080815,333130516272,318098147121,300918261555,284006827828,264947910453,245352122166,228172252983,193812514616,176632645433,146299438906,108718475067,91270170428,56105125693,159989647234,162405566339,179853870980,197033740165,208576464774,224951043975,241594025865,245083686794,245620557707,244278396812,244009944974,244278380431,226830075792,224682592145,327224936344,328835549081,345210111898,362389997467,379569866653,396749719455,398628784032,396749735842,397555025828,395944413093,397018154921,401044686762,399970944939,382791075756,379838285741,369100867503,369906173872,352726321073,335546435507,318366566324,299307648949,279711860662,262531991479,228172253112,210992383929,180659177402,146836309947,128851134396,93686089661,177437952002,198375917571,210723948548,227903817733,241594025990,258773895175,275953780744,296623294474,297160165387,312997857292,312729470989,311655680017,310581938194,327761807379,413124282394,413661153307,430841055260,431914764319,448020924448,447484020771,434330683433,435404425258,434330683435,417150814252,415271766061,416613943342,402655316015,386817607729,385475430450,369100867635,352726304820,333130516533,314071599158,296891729975,279711860792,245352122425,213676738618,197302175803,164553050172,145494132797,194617821314,213945174147,243473074308,259847637125,275953764486,310313502855,327493388424,347626031242,365879642251,364537464972,383059511437,381717350542,398628800656,413661153427,484259678376,469764163753,468690454698,450705246381,455537084590,438357231791,421445781681,404265928882,386817607860,367221819573,348431337654,331251468471,314071599288,279711860921,263874169018,230051301563,198375917756,179585435837,211812370690,249915525379,261726685444,296086423813,313803163910,348162902279,362928949512,379303512329,399746550026,417956120843,433256941836,432990603533,450436811022,450170472719,467350341904,484796565777,499560499475,498486757652,499023628565,516203497750,534457108767,536604592416,517277239590,517545675047,521307982120,503052273962,500097370412,483991243053,490165258542,472719051055,455537084720,455809714481,436746619186,421181540660,402655299893,384135350582,366953384247,349773515064,315682212153,299307649338,265216346427,250183960892,214213609789,248575445379,260652943748,294207375749,314610567558,349020637575,417687685515,432732653964,450170472846,484528130449,501714274707,500634241428,501439547797,518619416982,517814110615,534457108894,533922335135,537141463456,535530850725,521303787942,505734515116,488554645933,489896823214,455000213936,436480281010,401849993653,367490255287,352462064056,317565454777,298233907642,264419428795,250454493628,213945174461,261726685700,296086424069,364805900808,380108818953,417956121099,431122041357,450436811279,467618777616,484796566033,501710096916,518889949718,518619417111,515935062552,534727641630,537678334496,538752076321,532578060836,537409899045,522381707814,521310063143,504123902506,504392337963,507345127980,490165275181,472989583919,455805520432,402663688757,384403786294,368295561783,298770778682,214215707197,249915525763,260659235460,295014779525,313805261446,363738450568,417689782923,448299829902,484528130705,518894144151,517814127256,533920238234,534725544605,533385464479,537141463712,539827915425,537141463714,534457109155,537409899172,539563674277,521305868968,520230029993,505466079914,507345128107,507078789804,489898937005,453926472368,453658036913,435410717362,436478167731,421445782196,367494449847,298236005050,250183961276,248573348611,379838286601,467350342416,484798647057,484528114450,501978516244,501707983637,519158385430,518892063512,534996077338,533383367452,535530851101,534457109278,534725544736,538752076578,537409899299,539559480100,522645949225,507347225386,507076692779,453660134192,452588489521,435685444403,421189929780,384133253942,351920999224,316755954489,249915525948,213945174845,249915526019,296086424453,314608470918,380106722185,417956121483,486138727314,501976419219,501976419221,533920238491,535530851228,537946770333,536604593054,535530867615,539020512161,540096351138,538752076707,521305869222,522914384808,524524997545,507345144747,490165275565,471106341807,384401689526,352189434808,317561260985,298770779066,250452396988,214213610429,248573348867,295012682757,313803164678,379301415945,417687686155,465473391632,484259679249,485064985618,499833146387,501710081045,518887853078,536067738650,537678335004,538217303069,537143561246,536604593183,535530851360,537141464097,540096351267,539827915812,522645949479,524527094824,523719691305,506539822122,507347225643,505197644844,488288324653,469766261807,452584295472,384133254198,367221820471,351920999480,316755954745,298233908282,264142605371,249915526204,213947272253,249915526275,261726686340,296086424709,314608471174,364805901448,380106722441,417956121739,485601873041,519156337814,539022625946,540094254236,535530851487,533383384224,539022609570,539288947877,522109078694,524524997799,524524997801,507345128618,504123903148,451514764464,434336976050,403460607157,384670125238,368295562423,352189435064,317561261241,298770779322,264434109627,250186058940,211529272576,213947272450,248575446275,260652944644,294207376645,313803164934,363732159752,379838287113,417687686411,432183201036,483722808593,483991244050,499831033109,517818305814,520498466071,523719707928,536336157980,536069836061,535801384223,533385465120,535530851617,538756271395,540094254372,541436431653,522914385190,525330320679,522914385193,504392338730,505197645099,503052258604,487755631917,488290405678,468692520239,402655300917,384133254454,367221820727,351920999736,316755955001,298233908538,214750481725,211529272638,211812371840,214217805185,261726686596,295016877445,314608471430,364805901704,380108819849,417956121995,432451636620,430574685581,447752473998,464932326800,485065002385,499292081555,523182820759,521840659864,540094254490,539020512667,536067722652,536604593569,540094254498,539288948132,541704867237,524527095206,523988143527,523719691689,503052275114,403485773237,384403787190,367496547767,352191532472,317561261497,298504441274,249915526588,215555788221,215824223678,215555788223,210730241538,244815252995,260655042052,313805262342,363734257160,417689783819,433525378572,449094635022,449631505935,466811375120,483991260689,501171113491,502244855316,499294162453,523451256343,520498466328,521840643609,539020512794,537678335515,535799320092,535530851871,534457126432,537678335522,538754174500,540094254629,524256595495,503318597164,468958858799,451778989616,451510554161,316758052409,248841784892,214484143677,215555788350,214750481983,245085785731,379838287497,434062249612,432453734029,449633603214,452315860623,469229391504,483991244433,482917502610,502781726355,506273484436,516471934614,520498466455,521840643736,523719691929,537143561882,535535046299,534457110172,533920239261,534457110174,533920239263,534727642784,533383368353,537141464738,539288948387,539291045541,525330304678,524525014695,521574305449,503054356138,507076693675,508150435500,487749340846,472716955311,455537086128,454194908849,436211830450,437822443187,420908912308,384133254838,351921000120,298233908922,248036478652,214750482110,214226194111,215555788545,261726686980,296086425349,314608471814,364805902088,380912029449,417956122379,433527475980,452049522447,488823099153,506002951955,500634242837,517008805654,519156289303,520498466584,521840643865,535530852124,534461304605,535530852126,534457110303,534725545761,535530852130,539020513059,539288948516,524256579366,525332401960,504929210155,507613564716,490435792685,489896824622,472182181679,455002312496,453393796913,421177347892,384670125878,352457871160,317561261881,298770779962,248841785148,214750482237,215824224062,214213611393,244815253379,260652945284,294207377285,313803165574,363732160392,379301416841,417687687051,430841024397,448826199950,468421988240,490433712017,502515388307,501171113876,501735247765,520504758166,517841375127,517008805784,517816209305,535799287706,534457110428,534457110430,533920239519,534457110432,533920239521,534993981346,536340352931,541711159204,538752077733,521572208550,522109079463,522377514921,500099469227,506002952108,490970566574,435672862642,437015039923,420908912564,384133255094,367221821367,351921000376,316755955641,298233909178,248036478908,214482046909,214750482366,215555788801,211529256962,245888995331,261726687236,296086425605,314608472070,364805902344,380106723337,417956122635,434062249996,432451637261,449635700750,454463344655,469495730192,488823083025,486675599378,500634243092,517816209432,534457110554,534725546011,535530852380,535530852382,534457110559,535530852384,534993981473,536071917602,540094255141,521840660518,522914385960,521572208681,504123904042,503587033132,489628389421,490433695790,473253826607,455537086512,436209733682,437826637875,421177348148,384670126134,368295563319,352457871416,317567553593,298770780218,248848076860,214752579645,215824224318,214213611649,210726047874,244815253635,260652945540,295016878213,313805262982,363732160648,379840385161,417689784459,433525379212,430841024653,456073957519,473253826704,490433695889,489091518610,500367904915,500902678676,518353080473,533920239770,534457127067,533920239773,534727643294,533920239775,534457110688,536074014881,541436432549,521840644262,521572225191,521840644265,505468178602,503318597803,503855468716,490970566829,490702131374,473522262191,456342393008,454197006513,435677057202,420911009972,384133255350,367221821623,352189436088,298233909434,215557886142,215557886209,245083689219,261730881796,364807999752,434062250252,431646331149,454738071823,471911649552,486407180561,501976420628,517008806168,534457110810,534725546267,535799288092,534993981725,534725546271,535262417184,535799288099,541709062437,522645950758,521572208935,521840644392,522645950761,505736614187,502513291564,486675616045,473790697775,456615022896,384403788086,367494451511,351921000760,298770780474,214482047293,213945176448,211529257346,245888995715,314608472454,380106723721,417956123019,433525379468,431377895821,448826200462,471645311376,499562598803,501712179604,519158387094,518892048792,518082548121,533920240026,535262417307,536082403740,535264514461,534457110942,534993981855,536076112288,534993981858,533920240035,538752078244,524256563622,522109096359,524258660777,505734517162,501171114412,483991245230,472450617775,453389603249,421177348532,352189436344,298502345146,214750482877,215824224702,211529257472,211797692929,214213612034,249923916291,294207377925,313803166214,363732161032,379838288393,417687687691,434867573260,452315861518,519156290073,536069837338,535799288350,536071918111,533658096162,534461305379,537416192548,524527096358,524256563751,522914386472,507345146410,504660775468,485335519790,455537087025,437015040562,438357217843,420908913204,384133255734,351921001016,316755956281,298233909818,250186060348,215555789373,214213612094,211797692991,211797693058,261995123332,295012684421,314608472710,364805902984,380912030345,417956123275,433256960652,451778990734,469495730832,500097372819,518887854742,518896243353,536336175773,534993982113,538483643045,524527096487,524258661032,524527096489,507076694698,507347227307,504929211052,471911649967,455537087152,453926474417,436478186162,421181543092,384670126774,368295563959,352457872056,317561262777,298770780858,265216348859,211799790269,211529257730,261726688004,294207378181,313817846534,363732161288,379838288649,417419252491,433259041548,432990606093,449899942670,449631507215,501976421140,519158387478,517008806680,536336159514,536076112667,535799288605,536336159518,534188675873,537409901349,522914386726,507349324586,503587033900,468153553711,450705249072,453658039089,435414913842,436480267059,384133255990,367490257719,351923098424,316755956537,298233910074,264411042619,250452398908,210455516033,211797693314,261995123588,295014781829,364805903240,380108821385,417956123531,449094636430,500902679444,518892049304,536067724186,534993982365,535262417822,536336159647,536069821345,533926532003,539825820581,524524999590,524256564135,522113274792,524256564137,505466082219,451514749872,452588491697,384670127030,368295564215,317571748793,298502345658,265218446267,249915528124,214213612477,213945177022,211797693375,211806082048,213945193473,261730882564,363734258696,400507819018,420103607307,432720073740,431119946765,448297718798,500642632724,520506856470,536336159770,535801386013,534457111582,534727644191,536336159776,535000273954,538758370340,541713257509,523719693350,521840645159,524524999721,504392340523,435406525491,421447881780,403729044533,384401691702,367496549431,352189436984,298233910330,250452399164,215555806269,214219904063,215559984257,211533452418,245087884419,294207378565,379301418121,400778351754,421714220171,431115752588,536067724442,534725547166,535262418080,536342451361,521572209830,522109080743,524256564393,507076695210,507347227819,503318598828,404001674421,384133256374,351921001656,298502345914,264411043003,248845980860,214750483645,215824225470,295012685061,364805903624,380106724617,417687688459,519156307224,536336160026,535262418205,534457111838,533920257311,521840645414,521572209959,521840645416,524524999977,507345130794,503587034412,449899943216,451514750257,434334881075,418761430324,384670127414,352457872696,298770781498,264947914043,214482048317,215555790142,260652946820,293938943365,363732161928,379301418377,400509916554,415273866635,517814113688,518082549145,534459209114,535262418331,536336160156,535799289245,534725563806,535530853792,534457111971,522109113766,524256564649,505466082730,503318599083,449633605040,416884479412,384133256630,351921001912,298233910714,264411043259,214750483901,215824225726,213945177601,214213613058,249915528707,261995124228,295012685317,364805903880,380912031241,517008807448,518350984729,534457112091,535262418460,534457112093,534725547550,534457112095,534725547552,536067724834,536336160291,541704869412,521840645670,521572226599,521840645673,504392341034,502244857387,434330687026,404265915957,384670127670,368295564855,352457872952,298770781754,265216349755,250452399676,215555806781,213945177663,210455516800,211529275009,232735659651,261726688900,276222203525,331788342919,346552293000,362121549449,383327950474,398091900555,413929592460,431109461646,484528117397,487480907414,500634261143,501171115673,500365825690,500097373852,501171115677,500365825694,500097373856,501439551137,501707986594,501976422051,507345131172,488554649253,487212471974,487749342887,470301038248,471106344617,452852733610,415271769776,399970965169,381180466867,366148081332,369906177717,349773518518,333130520247,317561263800,299576088249,263874172602,247231174331,233004095164,211797694141,211529275070,210455516930,231393482499,245083690756,278906558213,297428604678,314610571015,347626034952,345746986761,366148081418,380912031499,396212852492,396749723405,413392721678,449094637333,468421990166,465469216535,466274506521,467079812890,466006071067,465737635612,466006120221,448557766433,450436814626,451778991907,438625654564,436209735461,418492995366,419835172647,405071222568,384133257001,382791079722,362658420523,328298698544,331251472178,328298682163,313803167540,318366570293,298502346550,299576088375,283469961016,266021656377,248036480826,214482048827,198375921468,176095778621,193275647874,213945177987,249915529092,267095398277,280519268230,329372424072,328298682249,348968212362,364805904267,379032999820,395944417166,429498849174,433525381015,434599155608,432451639195,431377897372,432451639197,431646332830,413661157279,414466463648,413661173665,400239384483,385475434404,384133257125,366953387942,350310389671,336351745960,313803167657,293938943914,258505463729,260652947378,259579205555,263068866484,266826962869,246694303670,247231174583,248841787320,231930353593,215824226234,198375921595,180390746044,159989651389,210455517187,228709128196,248307013637,297428604935,313266296840,328567117833,331788343306,400239384599,403460626456,401581561882,398897207323,398628788252,381717338142,380912031775,380106725408,363732162593,362658420770,349773518883,333130520612,316755957797,300918265894,301186701351,266290092072,211797694516,215018919989,212603000886,213676742711,197570631736,181196052538,159989651515,141736040508,267095398534,284275267719,300112959624,317024409737,383059515543,385475434648,367221823641,368295565466,367221823643,364537469084,347357616285,329103988895,327761811616,311118813345,311387248802,298502346915,281054042276,265216350373,250452400294,233272531111,197570615464,143078217908,164553087157,164284618936,147104749753,145494137018,211529259269,248304916742,265484785927,282933106952,300112959754,297697040651,314608490764,329372424471,330983037208,332056779033,330983037210,314876942619,297697040670,295012686111,276759091488,259579205922,246962739491,230856612132,212871436581,194617825574,179585440039,142809782568,108718496050,111134398772,129924880693,129656494390,128045832506,228709128583,231125047688,248304916873,248573352330,265484786059,265753221516,263337302413,261995125147,263068899740,245888997791,245083691424,245888997793,228977564066,214482049443,198107486628,178243262885,94491400626,113013447091,112476608948,128851138999,125898348984,177169521159,196765309448,197033744905,215555791370,214213614091,213945178636,211529259533,210455517724,211529259549,211797727774,197033744929,198912793122,180659182115,161063393828,93686094386,94491400755,112476576308,112745011765,112476576310,111673367095,108718479928,142809782919,162405603976,159989652107,176095779485,159184345758,158647491231,158915910305,163479313058,143883524771,91540708020,95298804405,94491400886,91540708024,108450044679,111134399240,128314268425,128045832970,122140252957,123214011166,122408688416,124824607521,109792221986,95296723766,74090306439,76506258312,70869080990,72748129183,71674387360,75164048289,73285000098,74358741940,78116854709,77311531959,74358741944,74090339336,70869081119,72750226464,74358742049,74090306613,74358742070,74090306615,69526903967},{2176860168,1906343945,1637892107,2174763143,1088487604,1619018116,1900052869,1084244408,815808953,547373498,541082171,1623212940,539018151,1621115917,1352680462,1075889191,807420970,1612743730,1344357428,1077953593,807420986,1881195687,1612743850,1881162929,2149598386,1881195699,1612743862,1344292024,1881179420,2149647646,2418033954,2686502184,2418033963,2418033969,2686469426,2418050355,2149614901,1881163063,1612727608,1344292153,1614824836,1881179544,2149598618,2418034075,2686485916,2954954142,3223373218,3491775909,3491792297,3223356843,3223356849,2954905011,2686485940,2418034102,2149598647,1881163192,1614824889,1075856826,1881163287,2418050584,2686469658,2954905115,3223340572,3491792413,3760227871,4028696097,4297098789,4297115176,4028679723,3760227889,3491776051,3223340596,2954905141,2686469686,2418034231,2149598776,1344292410,807421499,1881179780,2149598854,2149631625,1881179788,1612727950,1344292495,1075857040,2686469783,2954905240,3223340697,3491776154,3760211611,4028647068,4297098909,4565534367,4834002593,5102405285,5102388905,4834002602,4565518000,4297098929,4028647091,3760211636,3491776181,3223340726,2954905271,2418034360,1881163449,1612727994,1075857083,1881163522,2149598979,2418050820,2686469894,2955003655,2686469902,2418050831,2149598993,3760211735,4028647192,4297082649,4565534490,4833953564,5102405405,5370857247,5639325474,5639276329,5370857259,5102405423,4833969969,4565518131,4297082676,4028647221,3760211766,3491776311,2954905400,2686469945,2149599034,1612728123,1344292668,807421757,2418050946,2686470020,2954905477,3223340934,3491792775,3760310153,3491792784,5102405528,5370824602,5639276443,5907711901,6176229279,6176163753,5907711916,5639276463,5370841009,5102389171,4833953716,4565518261,4297082806,4028647351,3491776440,3223340985,2686470074,2149599163,1881163708,1344292797,2686470146,2954905603,3223341060,3491776517,3760211974,4028647431,4297099272,4565534730,4834052108,5102389267,6444582938,6713051164,6981486624,6713034793,6444599340,6176147503,5907712049,5639260211,5370824756,5102389301,4833953846,4565518391,4297082936,3760212025,3223341114,2954905659,2418034748,2149599293,2954905730,3223341187,3760212100,4028647557,4297083014,4833953927,5102405768,5370824842,5639276683,5907728525,6176163984,6444566675,7518308520,7249922217,6981453997,6713018543,6444566705,6176147634,5907695796,5639260341,5370824886,5102389431,4833953976,4297083065,4028647610,3491776699,2954905788,2686470333,3282061570,3814738179,4085270788,4620044549,4890577158,5425350919,5693786376,5962221833,6230657290,6499092747,6767544588,7023397134,7289719056,7551879441,7826622739,8109705494,8378157343,8109754662,7828719914,7551879469,7291816239,7035980080,6767544626,6499092788,6230657333,5962221878,5693786423,5425350968,4888480057,4620044602,4083173691,3814738236,3279964477,8107608471,8376043934,8376043941,8105511448,8373946913,8373946916,8103414425,8371849882,8371849885,8371866274,8369752860,8367655835,3244330240,3244330302,7522505134,7799345940,3235926913,6991926158,7797248938,3235943358,3233829888,7788844204,3493877379,4299183749,5102392967,5372925576,5639263881,5907699338,6176134795,6444570252,6713022093,7518328469,7786960535,7518344869,7249893032,6981441194,6444570288,6176151217,5907699379,5639280308,5370828470,5102393015,4833957560,4565522105,4028651194,3760215739,3491780284,3762312964,4565522182,4836054791,5370828553,5639264010,5907699467,6176151308,6444570382,6981441301,7250040598,6981474081,6713022244,6444586790,6176134952,5907715881,5639264043,5102442288,4833974068,4565538614,4297086776,4028651321,3760215866,3223344955,2954909500,2686474045,2954909570,3225442179,4028651397,4299184006,5102409608,5370828682,5639264139,5907715980,6176135054,6713137046,6444619679,6176135075,5907716004,5639264166,5370828711,5102393256,4833957801,4565522346,4028716977,3760248758,3491780537,3223345082,2954909627,2686474172,2418038717,3491780612,3762313221,4565522439,4833957896,5102409737,6176233495,5907732510,5639280673,5370828835,5102393380,4833957925,4565538854,4028651560,3223394356,2954926136,2686474298,2418038843,2149603388,4028651654,4297087111,4565522568,4833974409,5907716247,5639313561,5370845341,5102409887,4833974433,4565522595,4297087140,4028651685,3760216230,3491780775,2954909864,2149603508,2418088117,2149619897,3223345413,3760216326,4028651783,4297103624,4565539082,4833974540,5102442775,4833990939,4565539102,4297103648,4028651810,3760216355,3491780900,3223345445,2954909990,2686474535,2149603624,1612765490,1881250101,3491797383,3760232841,4028684683,4028701083,3760249247,3491781026,3223345571,2954910116,2686474661,1346394546,1612782003,1881184695,2686474759,2954926600,3223394826,3223411228,2954926625,2686474787,2418039332,1344297523,1612798516,2149603975,2418088584,2686474909,2418104990,2149604003,1346427572,1612733111,1346394808,1612749575,1881185033,1881234205,1612733218,1344297783,1075911559,1075927966,1075927988,1075895304,1075895327,1075895349,1075879071},{119,63,27}},
['Cthulhu Egg']={56,64,2.56666667,2.8,2.56666667,{{255,255,255,0},{255,255,196,0},{189,240,189,0},{180,190,178,0},{146,187,134,0},{132,151,111,0},{91,233,91,1},{79,183,80,1},{106,141,80,0},{59,142,65,0},{90,118,90,0},{65,115,71,0},{42,117,63,0},{40,109,64,0},{63,89,117,0},{45,87,102,0},{49,93,63,0},{31,112,55,0},{29,104,55,0},{27,99,50,0},{27,93,49,0},{27,85,46,0},{16,86,40,0},{54,74,102,0},{43,73,98,0},{37,68,85,0},{21,71,40,0},{21,50,45,0},{13,70,30,0},{12,55,27,0},{12,49,27,0},{11,45,25,0},{10,35,19,0},{5,50,19,0},{4,38,15,0},{5,31,14,0},{2,18,5,0},{0,0,0,0}},{86979395609,87780507802,90464862490,86706766107,138514809241,142004470170,139320115611,137977938332,121334940061,223340413464,224414155289,225219461658,224951042587,207234286109,172337676834,155157824035,155426243109,121603375662,292596761239,293938938520,294475825817,293938938523,293670519452,275416892062,275953762975,259310764706,260116071075,241594024612,242130895525,208844898988,209113334445,211529253550,191933465263,191128158896,243204637452,261726683917,277832811278,277564375823,344673239830,363195286295,361584673560,361853109017,363195286298,365342769947,362390012700,362658415391,345478546210,344941675299,328298677029,326956499750,311924114218,295012680491,297160164140,279980294957,279711859502,262531990319,245620556592,226561639217,209113334578,190054417203,259042329482,295817986955,315682210700,332862079885,350310384526,347089159055,364000592784,379301413777,412855845781,431914763158,430035714967,430572585880,431109456793,448289325978,451242115995,448289342364,448557761438,448289325983,430572585890,431377892259,430035714980,430304150437,413392716710,412855845799,398628766633,383864816554,383327945643,365611205548,348699771821,349505078190,331519902639,314340033456,297428599729,262800425906,243741508531,207502721972,259042329609,298506535946,315954840587,350041949196,367490253837,384670139406,399434073104,417419248657,432451634194,448289326101,465737630742,464932324376,465469195289,482917499930,485601854491,482651194396,482919597087,481575322656,464932340771,464395453477,447752455207,448020890664,438357214249,434869650474,417419248683,401044685868,400776250413,382254203950,363463722031,346552288304,316219081777,297428599858,263068861491,243204637748,261458248841,350310384780,363463722125,384133252238,384401687695,401854186640,417956119697,434601215122,432183198867,446678713492,448557761685,466276598934,465737630873,485601854618,482651161755,482112193696,464395453603,464936518820,465200759973,448557761703,449094632616,437017134249,419835167915,399434073260,313534727345,300918260914,263605732531,241862460596,263874168073,344941675788,381717333263,417689781521,431377892627,447215584533,466274534679,482649064730,483458565404,482917500189,482651194654,464932324643,464932324645,465737631014,449094632743,451781084456,434599118122,417687684395,310581937457,297965471026,263068861747,243477267764,264142603657,299307648394,313534727563,380643591567,431377892754,431914763667,448826197396,464395486614,465469195673,482917500314,483454371227,482649064861,465737631141,464395453862,447215584679,435406521769,434869650858,415808636331,311924114865,297428600242,262800426419,241864558088,264411039241,298770777610,312192550411,378764543503,399165638160,417956120081,432720070162,431379990035,451242116628,449096730133,466542937622,465200760343,466006066712,466274502169,483456468506,482917500443,485601855005,483454404126,482380645921,465200760355,464663889444,464395453989,465737631270,448826197543,454194906664,415540201003,313534727729,297160164914,263605732915,261460346505,298502342282,315956938379,346283853452,381717333646,380643591823,400776251024,418226652817,437015037586,448289326740,466274535062,465737631385,488554645147,489896822428,488554677917,486944065184,469766260387,467348244132,463858583205,464395454118,448289326759,449094633128,434062247593,437015037610,417419249323,398091896492,380643591853,363463722670,362121545391,346552288944,316755953329,297965471410,263068862131,224682591924,281322473226,350310385420,347894466317,365611206414,383059511055,401044686608,415271765778,430035715860,448557762325,448291424022,466274502423,468421986072,469764163353,472716953370,471645308699,470837921564,471374776094,469495727903,469227292448,471374776097,469495727906,449631504164,429767280423,430035715880,414198023977,419835168554,400239380267,383327946540,365879641901,348968208174,331519903535,314340034352,280785602353,261995120434,224682592051,278640215946,330446161804,347089160077,365879641998,383864817551,400507815824,397823461265,416613943187,436478166932,431377893269,455805519767,455268648856,454731777945,471643211674,470837905308,471374776221,471643211678,470837921695,471643211681,453658068898,432451635109,432183199654,396212848553,399702509482,383864817579,365879642028,348431337389,331251468206,315145340847,280785602480,261995120561,329915582476,348433434637,366687045646,384938559503,380912027664,395675977745,419568830483,438357215252,431914764309,434062247958,455537100823,454463342617,454731778074,455000213531,454465456156,454731827230,455805519906,437554006051,437820344356,438894086181,416613943334,378496108585,379569850410,362658416683,348162902060,314608470061,296891729966,279980296239,259042330672,281054038154,298504439947,361855207567,380108818576,397286590609,421445781652,435135989909,438357215382,438625650839,437820344472,454731778201,454463342746,454731778203,454463342750,454731794591,437283489953,420372039844,421714217125,399436171430,362389981354,345478547627,331519903916,299576084653,280248731822,263068862639,224682592432,243204638985,281593006346,346820725005,348701870350,398091897105,396212848914,399434074387,421984749844,415540201749,431122041110,437015038231,438357215512,437283588377,438359312673,416613943586,419298298147,420640475428,404265912613,344673241385,345210112298,328038631723,296625391916,282398312749,263337298222,226561640751,208308029744,247233268105,296090618251,329642953101,363195287951,379840383376,380377254289,397286590866,402118429075,416882379157,431119944087,435404425624,438088780185,437820344730,437551909275,437283473820,437820344733,438625651102,437551909279,437820344736,414476945826,417956120995,404265912740,403460606373,382254205350,361853110696,345212209577,328034437546,243473074606,225489996207,191935564208,227102706184,281054038538,331255663116,348433435150,365342771727,400776251922,402923735571,421177346580,414741187093,431109458456,434867554841,437283473946,437015054875,436478167581,437015054878,437283473952,435135990305,416613943843,402923751972,384938560038,379032980007,362392078888,294477908524,280517167661,242676156974,155157809713,121334942258,246694300297,278912846474,331519904397,364269030031,385475431056,383864818321,402655300242,401044687507,418224556692,430035716760,431109458585,435404425882,434867554971,435135990428,435404425885,434869652126,434599119519,435404425888,432451635873,415271766691,401044703908,382522641062,379576142503,345478548137,277031701165,225756334767,190324951728,155694680753,121605474994,246964833033,295551650571,331251469069,348162902798,364000594703,382793173776,383330044689,400507833106,419839363860,431113653016,430572587801,434066443034,435406523163,434867571484,434867555103,434599119648,431652621089,414472751907,401044687652,402659494693,379571948326,365881740072,348968209193,328298679082,293938940716,225489996591,156781005617,229514431368,329640872844,347089161102,365342772111,400776252306,400507816851,431111555993,434867555228,434599136157,435406523295,432453733280,400507816868,348699773865,329909291946,329103985579,294207376300,191933467568,121337039794,210187078663,247768042504,264411040777,313803164683,330983033868,347089161229,364000594958,364269030415,384938560528,400776252433,402655300626,418224557075,431914765333,452315859995,452584295452,435135990813,434867555358,416613944356,397018156070,363195288616,348968209449,347089161258,330714598443,298772876332,277564378157,227635383343,191128161328,243204639879,261726686344,281590910089,312192552074,330983033995,348162903180,365879643277,382791077006,383327947919,403997478032,420103638161,437015039124,435404426389,451779021974,451242118297,454194924698,453658037404,452315860125,453658037406,451778989215,431646330016,431648427170,415271767204,402923736229,400776252582,383864818855,366684966056,348968209578,329909292203,281054039213,260652944558,226293206191,190322855088,121603378354,230051302662,261995121927,298770779400,315682213129,331251469578,348431338763,365342772492,382791077133,398628769038,400776252687,421445782800,420372040977,437551926546,454731795732,455805537558,455537085720,455805521177,471913745690,471643213083,472716954908,454463343901,455805521182,449631505695,448828312864,431650524451,414466460964,421445782821,403729042726,387354479911,386012302632,363732159785,349505080618,331522002219,313266294060,281590910253,264679476526,224682593583,208310127920,121337040178,263874170246,299307650439,315950648712,330446163337,347089161610,365342772619,382522641804,398360333709,415540202894,419835170191,438088781200,437551910289,454463344018,454731779475,455000214932,471643229589,471911648663,471643229592,471911648667,471643213212,471911648669,472180084126,448826199455,448830393762,431650524580,420372041125,420640476582,403729042855,384938560936,362121547177,348162903466,312729423276,278906555821,260384509358,224414158255,261458251269,295817989638,330177728007,347357597192,364269030921,364000595466,381180464651,398360333836,415808654861,437820345871,455268650512,455805521425,455000215058,471913745939,472180100628,471911648790,489359969815,488823082521,489362066970,489091517980,472180084253,471643213342,466008182303,448826199585,419298299429,421716315686,404265913895,386817609256,363732160041,365074337322,348433436203,313803165228,295549554221,261458251310,227635383855,211797691952,122408685106,295822184069,313266294406,349773516423,364807999112,381453094537,399970946698,399702511243,415808638604,434867555981,437283475086,455000231567,472180100753,489360002708,490165259928,489359953561,489359953564,490165259933,488019873438,466008166049,448826199715,433793814181,402923736743,403192172200,387354480297,369637740202,314071600812,296623296173,261726686894,246962736815,214750482096,180122308273,124556168882,332864179974,350041952007,400239382282,417419251467,432722169612,434599120653,455807618830,455000215311,471911681808,489091567379,506273484567,506002951960,506271387417,506002951962,506271403803,489091518237,483185954591,466811375394,466006069027,448826199844,449631506213,437551910694,420103606055,420372041512,404265914153,387086044970,366416514859,348431339308,315145342765,296891731758,261458251567,247231172400,215824224049,161600261938,121603378995,224414158720,224682594177,224145723266,278640217988,349773516679,365074337672,398628769674,415808638859,434867556237,454463344527,472182181776,489091534737,489359970195,506005049237,506271387542,506271387544,506002952089,506271387546,507345129371,507613564828,506808258461,507613581214,489628422048,472448520099,472985391012,472450617253,456073957286,438894104487,421714218921,404265914282,384938561451,364269031340,348162903981,312729423790,295817990063,278638120880,249110220721,196496871346,157305294771,225487917057,241594028035,298502344709,330177728518,364807999495,382254206984,383059513353,399970947082,417419251723,434599120908,454194909197,456073957390,471911649295,489359953937,488823083026,505734516755,506002952212,506002952214,523455451159,523719692312,523182821401,523453354010,524524998683,524795531292,523988127773,506539823134,507613564959,506808258592,506539823137,489628389410,490433712163,472448520230,455268651047,438894104616,421445783594,400507818027,381448900652,365342773293,347626033198,330177728559,298502344752,266021654577,231125045298,192201904179,225487900802,242667769987,281593008260,316487520389,332593647750,383327948936,400507818121,417150816394,434867572875,454463344781,473253826702,472180084879,489359954064,490433695889,507076694162,499828953235,524256563349,524524998806,524524998808,523719692441,523988127899,524793434269,523988127902,524793450655,523988127905,506808258722,507613565091,490433728676,473522262183,456073973928,437015040170,415808639147,400239382700,381448900781,364805902510,350310387887,333667389616,295012683953,265216348338,245620560051,208844902580,171800809653,172874551478,224145723650,243206738179,315950649605,333130518790,367492354311,383059513608,401044689161,418224558346,434867556619,452315861260,455537086733,472180085006,489359954191,489903116560,503318597905,500634243346,499828936979,516471935252,519961596181,522914386198,540899561752,541167997209,540899561754,540631142683,540899578141,540639514911,523988128032,524793467169,507613597988,489362051367,472180085032,471911649577,450168394026,435404427564,417687687469,401849995566,384670126383,368027128112,329103986993,296354861362,280785604915,243204641076,224414159157,224682594614,279174992260,310581940613,333669486982,383332143496,400507818377,417687687562,434599121291,453658038668,455809716621,471913746830,489091518863,500638437777,499837325714,500638437779,524260757908,517013000597,517814112662,541440627095,540633239960,540362690970,541436432795,540362690972,540631142813,541180580256,523988144545,523721789859,506539823524,506810356133,507615662502,490165260712,469495730601,450168377770,451242119595,434064347564,416349704621,402386866606,380643594671,363732160944,329372422577,311655682482,279443427763,243741512116,225492095413,244284674563,281593008644,313534730757,365076435463,399970947593,417419252234,434869654027,454463345164,488286212623,517281436182,539557384730,534725546523,541704868380,539825820189,540362691102,524797628961,523719692834,506808259108,490167357991,488823083560,467348247081,451510555178,450168377899,401581560366,385206997551,366416515632,329642955313,312460988978,278101250611,242674061876,316487520901,333132616326,400239383177,418224558730,455805522572,472985391758,489362051727,541704868504,540362691225,534993982106,534188675739,538483643036,541704868509,540631126686,523988144802,506271388324,502513291941,507882001062,486407164584,468421989033,452047426218,451510555307,432988508844,398901400238,384670126767,365074338480,312729424562,277027508915,281330864900,315950650117,366150177543,383864820488,401044689673,417687687946,436478169867,455268651788,455002313485,472180085518,490165261072,500099470097,503855469331,525061870356,517277242133,541704868631,540094255896,534457127705,534993982235,534457111324,535530853149,541704868638,523988128546,525061870371,501171114788,500365808421,507613565734,488554648359,484259681064,468696716073,452584313642,433793815340,416077075245,384401691439,366416515888,332325212977,312192553778,276226396979,226293207861,315413779333,332862083974,383059514248,400507818889,417423446922,435404428171,455537087372,471913747342,489091519375,488554648464,505197646739,525330305940,517814113173,517008806806,540094256023,534457111448,535801385881,538215207834,535530853275,540094256028,534457111453,535530853278,541706965919,523988128673,524793435042,522377515939,500370002852,501171114917,506271388582,486407164839,486138729384,451514749866,451778991019,433527477164,418492994477,384672224175,367760790448,328835552177,311387247538,226561643445,224414159798,224682595330,244546819075,315686409221,333132616710,365879645191,382791078920,401048884233,431109461003,454194910220,455807620109,489359954959,486138729488,499845714961,500097373202,506539824147,525061870612,519693161493,516471936022,534459208727,540094256152,534993982490,535799288859,534993982492,537946772509,536067724318,524793435169,524524999714,517545677859,500370002981,502513292326,485872407591,450168378411,418761430061,401581560878,329372423217,310581941298,243473077300,228440691765,224682595382,227102708866,246964835459,366687048839,383866918024,431377896587,455537087628,472180085902,490433696911,486946133136,503855469714,507892487315,524524999828,525072356501,517824599190,541715354776,534457111705,540094256282,538215208091,535799305372,542241739934,540364788895,525063967905,518350984354,516471936163,501171115174,450707346603,433256944812,416077075629,398897206446,385209095343,369906177200,335278003377,311387247794,277832815795,245356319924,227903820981,226293208246,330716697862,414198027530,431109461259,448289330444,452315862285,472985392398,489628390671,503591228690,523990226196,534190773527,534996079897,538483643674,541436433691,535799289116,534993982749,541704869150,541977498912,517549888802,501175309604,501439550758,485870294311,485601858856,468960957737,450168378666,436211832108,419029865773,401849996590,369369306416,334204261681,312192554290,280248735027,228442789173,226561643830,247768044931,281595106692,313270490501,366148081031,383330047368,400507819401,419835172234,437015041419,449899943308,448289330573,470837908878,490433697167,486138729872,534457111962,534993982875,534457111964,540094256541,540899562910,540635321759,523988129185,501171115429,503587034534,486407165351,485872391592,451510556074,453389604267,416613946797,402386867630,386012304815,369906177456,335011665329,317563360690,279711864243,226830079414,224682595767,224145724929,227366950402,243204642307,332056778246,365879645703,402655303177,416613946890,432451638795,454463346188,451242120717,465469199886,488823084559,486944036368,524527097364,534465500695,538215208473,540094256666,537678337563,540094256668,540899563037,540652099102,523182822945,501707986469,503318599206,486138730023,468690425385,450709444138,453928572459,432183203372,415003334189,400776255022,386817611311,369371403824,278369687091,245083690548,228172256821,228711224886,226024773175,224682595969,230051305090,247768045187,332327310982,366148081287,383866918536,397557126793,414198027914,431914768011,448557766284,454194910861,465737635470,483454375567,488554649232,503318599314,540631127705,540901660314,541704869531,540899563164,539825821341,542248031904,522377516705,516740372130,517545678499,501439551140,503318599333,503052261030,485876586151,486138730152,467348248233,436478170796,419566737069,397286594222,385743869615,334204262065,317024392882,280517170867,246157432500,229245998773,227102709505,229787064066,247231174403,281324574468,315682215685,366684952327,421177349898,438357219083,451778991884,448561960717,471374780174,488823084815,486944036624,503855470354,523988129556,540899563289,540633224987,541704869660,540631127837,540362692383,519695259425,517547775778,518350984995,503052261156,503589132069,485872391976,467887216425,453121169195,436209735468,419029866285,397018158894,386817611567,368564000560,328567117617,316755957554,282400413491,247499609908,230856611637,226024773430,244278384515,313268393861,329911392134,364002695047,381182564232,398362433417,417956124554,431914768267,455805523852,470837909390,490433697679,486140827536,500365809554,506808260499,524793452436,517545678742,541440628632,540631144345,540899579804,540645808031,520498468771,503318599590,450436831146,435672864684,415278061485,396749723566,387086047151,366416517040,328835553201,316219086770,248036480948,228977563573,246694303747,278638123012,415542302730,438625654795,454194911244,471643215886,490165262351,499292067858,502513293331,525061871636,518350985237,516471937046,540631128089,540364789786,540903757851,540362692636,540631128093,518351001633,521303775267,503318616100,503589132326,484528117800,470301038633,452852733994,450441009195,436209735724,397022353454,387354482735,367758694448,329640859697,316755957810,248304916532,226024773685,229514434690,246962739331,281593010308,315413780613,330448263302,365611210887,382522644616,398628771977,432988510347,448557766796,449899944077,473253828750,489359956111,490173651088,502788020369,499835230354,503318599827,525330307220,517814114453,517008808086,535799290007,540362692761,540631128220,539825821853,541973305504,518350985377,523182823586,522377517219,503855487140,486138730663,485069183144,470032603305,453121169578,435941300396,387086047407,366416517296,331522005169,317024393394,283740494003,246157433012,227100612866,247233272067,315952748805,364271130887,383059515656,400239384841,416882383114,432720075019,449899944204,456073959693,471911651598,489091520783,500103665939,524793436436,516471937301,517279340822,541704870167,540899580184,540631128346,540901677340,541170096416,523719694625,525061871906,522914388259,503855470884,505197648165,504126003494,486946134311,467622975785,450436815146,435672865068,387356580143,363732162864,318366570802,243473078580,277564381572,332599941510,381451000200,398628772233,415542303114,434062252427,450168379788,452315863437,472985393550,488823085455,524525001108,517013002645,541440629143,540631144856,540899563930,540631128475,524793452961,524525001123,505197648292,504123906469,452852734378,453389605291,436746607020,416345512365,400507820462,368564001200,334472698289,318903441842,280517171635,246694304259,282127784452,316487522821,364808002055,399702514185,432720075275,451512654348,449899944461,470837910030,490165262863,525061872148,517816211990,540899564056,540364790297,540631128602,540903758363,540631144988,541975403040,524801825313,523990227490,524793436707,506271390244,503855471141,505734519334,488019876391,487751440936,453928573482,449631509035,433795914284,418763528749,402386868782,386549176879,369369307696,335814875697,313534732850,275953769011,244278385283,281590913668,315950652037,384670128776,398628772489,417150818954,434332785291,451242121869,467079813774,486675602063,504123906705,500634245778,518619421332,541704870552,540362693274,540631128732,540362693277,523990227619,507613567652,505197648549,504126003878,449363073707,399165643438,386280741551,370174614192,328569215665,310581942962,276222204595,281054042884,315682216709,366953388807,384403790600,399165643529,415808641802,450170477324,449899944717,468421991182,484259683087,488017779472,507345148689,499828939539,515935066900,519961598741,522914388758,540633226007,541168016152,540633226010,540899564316,540631128861,541167999776,524795534114,507882003236,506002955045,486944037671,486675602216,467887217449,453389605674,453926476587,436209736492,416077077293,401315224366,384670128943,365074340656,311387249458,278638123908,315950652293,332862086022,367221824391,401581562761,416345512842,432988511115,451242122125,467079814030,485601860495,484528118672,506002955153,507078794130,501439552403,517277244308,522914388885,523988130710,540631128984,540899564441,541167999899,541973322652,541167999902,540899564447,541973306272,524793437091,507615665060,506808261541,505197648806,488554650535,488017779624,453121186730,435672865708,418492996525,384401693615,363463728048,329372425137,310581943218,260384513028,298502347781,315950652422,350041955335,368027130888,385207000073,401849998346,416345512971,432988511244,451510574093,468958862351,485601860624,484528118801,507613584403,507345132565,523451276310,523719695384,523182824473,523451259930,523988130843,525061905436,524793453599,506808261666,507613568035,507882003493,488554650662,486944037927,470837910568,453389605929,450705251370,435941301291,418761432108,401313127469,384401693742,367221824559,350310390832,311387249713,261458254981,281054043270,315950652551,333667392648,362121550985,385207000202,401849998475,416345513100,415808642189,434330688654,451242122383,450168380560,467348249745,468153556114,488017779859,486675602580,488554650773,506002971798,507076697240,506539826329,506271390874,506539826331,507613568156,506808278173,507613600927,490433731746,473253829797,471374781606,452584316071,435135995049,418492996778,416345513131,399165643948,384670129325,368027131054,333130521775,315950652592,275953769649,259042336006,281054043399,316487523592,330714602761,350847261962,367490260235,384133258508,399165644045,416345529614,433525382416,450705267985,467885153555,485065006358,487749344536,488286215449,490165280026,489360022812,489628392737,472985394466,472180088099,472448523556,455805525285,454194912550,436478172455,419835174184,417956125993,401581563178,381717339435,367221824812,350310391085,330446167342,316487523631,275953769776,278638124424,299307654537,333130521994,349773520267,367221824908,384401694093,399165660558,418761432464,436209737105,436746624402,453389622676,470301072790,470837910937,471643233690,471374781852,471643233693,472716975519,471911652769,455000219042,455537089955,437820349860,438625656229,437015043494,419298303399,402655305128,402118434217,384670129578,366953389483,350310391212,330714602925,296354864558,277564382639,278638124553,298502348298,315682217483,350041955852,367221825037,366953389582,384133258767,401581563408,402386869777,415003336210,415271771667,436746608148,436209737237,435941301782,453389606423,453658041880,452584332825,452315864604,452584316445,452315864607,452584300064,437015043617,436478172706,437015043619,419835190820,402118450726,383864823336,368295566889,367490260522,349773520427,315950652972,299307654701,278638124590,278638124682,298770783883,332862103180,350310391438,367221825167,385207017104,398091902610,400776257171,419029868180,418763529877,436209737366,433525382807,433793818264,435404463769,437015043740,435404496541,418224578210,401044692644,402655305381,385475452582,368297664168,351115697833,333398957738,332862086827,298502348460,278638124717,295817993995,330177748748,349773520654,364537470735,384133259024,384401694481,401850015506,418492997396,433256947478,430572592921,430841028378,432183222043,432988544797,434599124768,434867560225,417687691042,416613949219,396481290020,397823467301,383327952678,384938565415,349505085225,333935828778,333398957867,296086429484,413661159316,413124288405,430841028513,415003336610,362121551784,346283859881,329104007082,294744252332},{1348485145,1346388122,1344291099,2149646745,1881162141,3491840536,3223339549,2686468642,2418065955,1881162286,4565615255,4297097886,4028662434,3760226980,3223372460,2954920623,3760210700,4028646157,4297097998,5370823446,5639389975,5370839842,5102404389,4833952554,4565533483,4297098029,4028646191,3760210736,3491775281,3223339826,2954904371,4028646282,4565517195,4833952652,5102388109,5370839950,5639259024,5907694481,6444565397,6713050006,6981518234,6713050018,6444581798,6176129961,5907710890,5639259052,5370839981,5102388143,4833952688,4565517233,4028646322,3760210867,3223339956,4041229321,4576003082,4850729995,5375017996,5641356301,5909808142,6190810128,6457148433,6723486738,6985630741,7260357654,7249888280,7528891418,7254098979,6991938599,6723503145,6455051307,6176146476,5907694638,5639259183,5370823728,4844438577,4576003122,4039132211,3768599604,6721389715,6981436564,7260357785,6176130220,5920277775,7258277143,7256163622,6985631124,7254082980,3762308616,6985631253,7520421409,7254066723,5372921484,5907695246,6176130732,5907695277,5639276206,5370824368,3491776180,4318054154,5379213069,5645551374,6444566290,6717196052,6983534358,7250003738,6983534372,6713018151,6444582697,6176130859,5907695404,5639259949,5370824494,5102389039,4833953584,4297082673,4028647218,3491776307,5121263500,6182422417,6448760723,6717196181,6983567255,7249987482,6981453730,6713018277,6176147369,5907695531,5639260076,5370824621,5102389166,4833953711,4297082800,4028647345,5924472848,6729779222,6981568538,6713034787,6444566566,5907712041,5639260203,5370824748,4833953837,4565518382,4297082927,4028647472,4578101387,5653940367,6459246740,6727698583,6981552281,6713034913,6444583076,6178228390,5639260330,5370824875,5102389420,4565518509,4297083054,4028647599,3491776688,3770697993,5381310734,6186633490,6455052565,6723619097,6444599586,6190811429,5370841385,5121263915,4580198700,4315957549,4028647726,3512748335,3223341360,5110778253,5916084625,6455069090,6184520100,5916084646,5651843496,5381310889,5110778282,3770698158,2967488944,3498068488,5920279079,2434812465,1900038706,3223342087,3760213000,4028648457,4833954827,5370825741,5639261198,6176148497,6446664723,6715100181,6713019417,6983552027,6713068573,6448761892,6180326438,5377117226,3760213127,4028648584,4297084041,4833954954,5102390411,5370825868,5639261325,5907713166,6176132240,6444584081,6713003156,6981504150,6983568541,6713035936,6444567715,5645552809,4037037230,3491777798,4028648711,4565519624,4833955081,5102390538,5370825995,5639261452,5907696909,6176148750,6444584208,6713019666,6981520660,7252004122,6983552288,6713019682,6448762149,5911891240,4840246572,3229633840,4028648838,4565519751,4833955208,5102390665,5370826122,5639261579,5907697036,6176132493,6444584334,6713019792,6981471634,7249939861,7251987869,6981438879,6985633186,6715116963,6448762278,6180326823,4028648965,4565519878,5102390791,5370826248,5639278089,5907697163,6176132620,6444584461,6713003535,6981471760,7249923603,7520488983,7251987999,6981439009,5641358890,5372923435,4567617069,4571811461,4833955462,5375020679,5643456136,5913988745,6176149130,6444568204,6713020045,6981455503,7249907345,7520439956,7520423581,7251971745,6981439139,6713020068,6176132776,5907697321,3760213679,2686471857,5154819846,6180327178,6448762635,6715117324,6983552782,7249907472,7520407315,7788924695,7518326559,7249891106,6981455652,6713003814,6444584743,6176132905,5907697450,5639261995,5370826540,4833955629,4565520174,4028649263,3760213808,3223342897,2418036530,1881165619,3491811200,4347416452,7251971984,7520423825,7518310292,7788859285,7786778525,7518343072,7249907619,6981439398,6713020327,6444568489,6176133034,5907697579,5639262124,5370826669,4833955758,4565520303,4297084848,3760213937,2954907570,2418036659,3491794945,3804254211,5687496711,5955932168,6715101196,6981455885,7251972111,7788859411,8057376791,7786795038,7518343202,7249891365,6981439527,6713020456,6444568618,6176133163,5907697708,5639262253,5370826798,5102391343,4565520432,4028649521,3491778610,2954907699,3493875842,4880093317,6222270601,6490706058,6759141515,7029674125,7296012430,7518326928,7834980498,8101335189,8055230622,7786762402,7518343332,7249875111,6981456040,6713004202,6444568747,6176133292,5907697837,5639262382,5370826927,5102391472,4565520561,4028649650,3760214195,3223343284,2686488757,7025479948,7562367247,7830786321,7832883475,8099221780,8055181591,8367771928,8055230752,7830819108,7564448039,7249891624,7025496362,6757044524,6488609069,6220173614,5951738159,5683302704,5146431793,4565520690,4336931123,3793768756,3491795253,8365560215,8365560224,8097157537,7560253864,7291818409,4875899314,3519041973,3506459574,3514848258,3493877175,3500168705,4028652548,4565523461,4833958918,5370829831,5639265288,5907700745,6176136202,6444571659,6713007116,6981442574,7249878031,7518329872,7786765332,8055364630,7786798114,7518313510,7249878056,6981458985,6713007147,6444571692,6176136237,5907700782,5639265327,5370829872,4833958961,4028652677,4297088134,4833959047,5102394504,5639265417,5907700874,6176136331,6444588172,6713007246,6981459087,7249894545,7518346387,7786929302,7518346402,7249894565,6981459111,6713007273,6444588202,6176136364,5907700909,5639265454,5102394543,4833959088,4297088177,4028652806,4297088263,4833959176,5102394633,5370830090,5639265547,5907701004,6176136461,6444588302,6713007376,6981459217,7249911059,7518493974,7249911074,6981459237,6713007399,6444588328,6176136490,5907701035,5639265580,5370830125,5102394670,4833959215,4297088304,4297088392,4565523849,5102394762,5370830219,5639265676,5907701133,6176152974,6444572048,6713040273,6981459348,7250058646,6981459362,6713040292,6444572071,6176153000,5907701162,5639265707,5370830252,5102394797,4565523886,4297088431,4297088521,4565523978,4833959435,5370830348,5639282189,5907701263,6176153104,6444588562,6713040404,6981590551,6713040417,6444588580,6176153126,5907701288,5639282217,5370830379,4833959468,4565524013,4297088558,4297088650,4567621259,5104508556,5372927630,5641363087,5909814928,6178250386,6448782996,6713187990,6446685858,6178250404,5909814950,5643460264,5375024809,5106605738,4569718444,4297088685,6713007894,6713138969,6713008033,6444572578},{13,65,34}},
['Luminous Cthulhu Egg']={56,64,2.33333333,2.8,2.32163735,{{252,245,252,0},{189,249,251,0},{136,247,252,1},{182,211,216,0},{123,214,237,1},{142,172,188,0},{56,201,222,1},{48,179,200,1},{40,166,185,1},{66,147,189,1},{9,148,161,0},{115,124,145,0},{70,124,175,0},{96,89,129,0},{69,89,137,0},{34,114,145,0},{31,84,115,0},{8,128,140,0},{9,113,125,0},{7,91,103,0},{6,79,94,0},{5,77,87,0},{78,67,122,0},{58,67,114,0},{64,54,105,0},{20,70,97,0},{8,71,84,0},{15,59,82,0},{4,73,86,0},{3,68,85,0},{3,66,77,0},{3,60,74,0},{2,52,68,0},{29,44,80,0},{30,22,83,0},{4,42,50,0},{3,12,32,0}},{52883898399,54762946718,53961834655,52883898653,56373559582,52347027868,55568253341,73553428894,53957640732,73287107101,70869074463,54494511756,55299818125,52883899022,70063768219,73553429148,71408042655,52347028128,71674380972,73016558253,91001733806,89927991983,87243637424,71674381066,72211251979,74627171084,74895606541,73016558350,55568253711,37583078160,69526897434,71405945627,73284993820,90464879389,52615463712,86706766633,88854250282,90196427563,108718474028,110865957677,108450038574,125629907759,108181603120,107107861297,106302554930,89391121289,92075475850,92343944075,75164042126,73016558479,56910431120,36777771921,88317379482,90464863131,88585864092,69795333024,87243637672,109792215977,128582697898,125898359723,145494131629,145762567086,144957260719,142809777072,144957260721,125361472434,125093036979,121603376052,106570990600,109523797001,129119568907,126435214348,126703649805,109523780622,109255345167,91001734160,73553429521,121603376153,124824601626,122945553435,124824601628,140125439005,122945553439,104960377888,123213988904,146031002665,162942436394,162674000939,163210871852,179048563757,177974838318,178780128304,162942436401,160258081842,145225696307,140662293556,143883535496,146299438218,158110598283,174753596557,177706386574,160794952847,158915904656,142541341841,138783245458,209381770393,210992383130,210723980443,208844899486,191665030303,190591288480,155963114661,192738772136,214750479529,214213608618,215555785899,212871431340,207502722221,209113334960,195691562161,197033739442,177169515699,158915904692,123213989127,161063388424,180659176713,178511693066,229245994254,215018915087,210455512336,211260818705,209113335058,259042329880,277564376345,279711859994,279443424539,277564376348,279443440925,277564376351,259579200800,226293204260,226561639717,261995119912,266290087209,263337297194,264679474475,260652942636,226293204273,211529254194,194617820467,176095774004,158110598535,178243257736,197839046025,212334560650,277832811918,281322472847,279174989200,279980295569,278101247378,310045083029,327224935831,328835548568,348162901401,346283951514,327224935841,313266308516,309508195750,333130515880,335009564073,331788338602,313534727595,310045066668,260652942769,245888992690,228709123507,210455512500,175290467847,212602996232,229782865417,244815250954,259042330123,312192550413,330177725966,333130515983,349236643344,351115691537,364537464338,381180462613,399702525462,416882378264,415003330073,416882394650,415003330076,414466491933,415003330080,414198023713,413392717346,396481283619,399970960932,396481283622,386280736296,386549171753,386012300842,366148077099,362121545260,344404805165,310581937712,298770777649,265216345650,246157428275,228709123636,207502722613,191933466247,229782865544,246962734729,281590908554,296354858635,329372419724,350310385293,366150174350,383327946383,402118428304,401849992849,429767280276,450705245845,451512649366,468690437783,468422002329,485870306971,483722872477,466545051298,468958856868,468690421413,449094633126,452852729512,438088795817,419029862059,402923734700,382254204589,365074351790,330714597040,317829695153,283469956786,264679474867,226293204660,246694299401,283738392330,298772875019,317024388876,348968208141,384670123791,381985769232,396481283857,430841022227,431914764052,433525376789,451242116887,468690437912,468421986074,468690437915,466542970653,468421986080,466542937889,451779004196,433525376806,429767280423,416077072169,399165638442,398360332075,381180462892,367490254637,352189433646,334741129007,317561259824,283201521457,247231170354,244012042121,266558523274,314608469900,351115691917,365074335630,363195287439,380375156624,397555025809,413661153170,419029862291,437820344212,437015054229,452315891607,454194907034,452047423387,469227292572,471374776221,469227308958,452315858848,452047423393,451510552482,451779004323,434330683301,432183199654,414466459559,413124282280,397555025833,380375156650,363195287467,345210111916,328835549101,315950647214,301455132591,279174989744,244278380465,263882557450,297160165387,316755953676,334206355469,346015418382,361853110287,378496108560,379035076625,396483381266,420640491539,436478167061,437551925270,452047423512,452315858969,454731778074,452315858971,452047423516,454194923549,452047423519,454194907168,434869651489,434599135266,434330683428,415003346981,397286590503,395407542312,380375156777,362389981226,344673241131,327493371948,310313502765,296086423598,284275263535,243473074224,206965852209,209113335944,246966929545,279980296331,314610567308,345210112142,361316255887,402386864275,420640475284,417419249813,420372039830,437820344471,437015038104,435135989913,436478183578,435136006300,437551909022,436478167199,437015038112,434599119010,417150814371,414466459812,397288687781,397823461542,380375156903,378227673256,361853110441,344136370346,326956501163,309776631980,293133633709,261726685358,249110218927,211260819632,173142984881,209918642440,279174990091,331794630925,345746983182,344673241359,361853110544,378496108817,378764544274,403729041683,403192170772,416882395413,420372039959,437820344600,437551909145,436478167322,437551925531,437015038237,437283473694,437551909151,420103604512,419835169057,417419249954,399702509859,397286590756,380643592486,362658416935,361047804200,345210112297,326956501290,309776632107,275416893740,258773895469,247231170862,210992384303,176634743088,140393859377,212602997128,280248732043,297160165772,348162902414,345746983311,362658417040,379032979857,379301415314,399970961811,416882379157,414200121750,415003330967,434599119256,434330782105,417150847392,397823461795,397026544036,379840383397,379569850790,361318336935,344136370600,344675338665,327493372330,293133633963,276490635692,261995121069,245620558254,208851192239,141199165873,174753597959,212068223496,246430059017,280517167627,297432795660,348431337998,346283854351,362926852624,380643609105,397286590995,397829753364,415005428245,414198024727,432183282200,431646329374,432189491743,415003331104,416882395681,397288688163,378498206246,344673241640,328835549738,297160165931,283469957676,265753217581,243208833582,175829436976,137709505073,106302556722,70063770163,175292566151,261995121290,280248732299,348968209038,348431338127,363463723664,380647787153,382522641042,397823462035,414466476694,432187394712,434064345753,432183233178,434064345757,432183200414,416886573728,417150814881,415003331234,380108819109,361853110951,346015419048,346820725417,329640856234,299039214251,283201522348,260386605741,140393859761,107644734130,212602997512,264413137674,280519265035,332058872589,351652563726,348699773711,365342771984,380645690130,399702510355,416882395925,415005428503,434062248730,432185314075,434062248734,416882379553,414466460450,397823462179,379571948326,363195288359,347626031912,350310386473,330177727274,298233908011,279443426092,176901081904,142272908081,105230912306,177706388359,212066126728,246696397705,297160166284,351384128398,348162902927,363463723920,397823462291,415003347861,432183217049,432183200669,431646329758,415003331489,414200122274,397286591395,379569851301,362926853031,348968209320,351923096489,330714598314,295817989035,278906555308,259847637933,242667768750,210723949487,176632646576,140125424561,158110600198,195154693127,229782866952,280248732682,297697037323,314608471052,351115693069,349236644878,365611207695,382791093264,399970946066,417150848019,434330700822,434062330904,434330684446,434062248991,434330684448,432183200801,414198025251,415003331620,397823462437,380643593254,382522641447,365879643176,351652564010,312997858347,298233908268,277564378157,243204639790,228172254255,191665032240,157305293873,122140249138,192738774150,227098512519,264142605448,279174990985,297697037450,333398953099,351652564108,368563997837,386012302478,384938560655,400776252560,420640476305,417956121746,435135990931,437551926420,452047424662,454463343767,454731779224,454194908313,452047424666,454731779227,451778989212,447752457373,449094634654,452315860127,451242118304,449363070113,432183200930,431646330019,432183200932,420103605413,417956121766,400239381671,385743867048,386280737961,368563997866,350310386859,330177727660,298233908397,278906555566,262531992751,225487899824,191128161457,156499987634,232198786310,266826960135,298233908488,315950648585,331788340490,349236645131,368295562508,384938560781,403460607246,420640476431,419298299152,437820345617,454731779346,452315860243,453658037524,472180083989,469495745814,470837906712,489091517721,486675598618,489091517723,486407163164,482917502237,482112195870,469227293983,466542939424,466006068513,466542939426,448826199331,449363070244,454194908453,436478168358,417956121895,417419250984,399970946345,386280738090,368832433451,347894467884,332325211437,315950648622,294744247599,259847638320,226024770865,190859726130,244009946501,264142605702,298502344071,332593646984,348968209801,366416514442,384938560907,402655301004,419835170189,437820362126,453658037648,454731779473,472180084114,471643213203,488554646932,489091534229,488554646935,506271403416,500634242458,502244871579,499292065181,500634242462,503318597023,483722808736,483185954209,482917502371,466006068644,469227294117,454194924966,434330684840,432183201193,420372041130,402118430123,385743867308,366953385389,347357597102,329103986095,293938941360,259847638449,242936204722,278369684997,315145342470,332325211655,365074337288,383596383753,400507817482,419835186699,435135991309,455268650510,468958858767,471374777872,488017792529,505734516243,505197678100,522914385431,523182820888,520766901785,517008805402,517814111771,522377514524,519424724509,518619418142,517545676319,518082547232,500902678049,500097388066,500365807140,486138727973,486407163430,469227294247,468958858792,451510554153,434599120426,417419251243,420372041260,401849994797,381717335598,364805901871,331519905328,311387246129,279443426866,241862463027,277832814212,315145342597,332325211782,366684950151,384672222856,403194269321,419835170442,437021331083,454463344268,472448519821,467885117070,481575325327,485064986256,506539822737,503855468178,521035337363,522377531028,520766901910,540094254743,540633222808,540899561113,536873029274,539559480987,541167996572,540631125661,534993981086,535262416543,534725545632,518082547361,517545676450,517277257379,503050161829,503855468198,486138728103,486675599016,469495729833,469227294378,452047425195,437015039660,420372041389,399434075822,381455191727,367490256560,333398953649,317292826290,277832814259,241862479616,278369685252,315682213637,332862082822,366957580039,420640476938,455000215308,468155649805,466274504462,483185938191,482114293520,503318597393,506808258322,523451272979,523719692053,523451256598,540631125783,540362690329,540633222938,539288948508,540899561245,536873029406,536604593951,537141464864,520230063905,519961595684,503318597413,506002951974,486407163687,488017776424,469227294505,471911649066,454463344427,434869653292,417958219565,401852092206,364271128368,335814872881,317833891634,278638120755,244546817921,242667769730,260116074371,281056137092,315145342853,332327309190,383596384136,400776253321,417956122506,454731779980,468421988238,482917502863,502513291153,506539822994,519693160339,522109079444,523451256725,523721789334,539557400471,540899561369,541168013211,541977546653,524803968929,506808258469,506271387558,489359970215,470840004521,469495730090,454194909099,335009566641,278906556339,241325592577,243204640770,262265655299,315682213893,385475432456,400507817993,417687687178,453658038284,472448520205,467079811086,482112196623,486138728464,506808258577,502246952978,517008822291,519693160469,540362690583,540631126040,539557400601,541170094107,541975400476,507619856421,506541920294,489362051111,489630486568,469233586218,454731780139,436478169132,420103606317,401313124398,364541661232,333130518577,280248733747,259042332724,241862463618,283740491908,318366568581,332862083206,365074337927,385745965192,402118430857,419298300042,436478169227,454731780236,470569472141,467885117582,485064986767,488823083152,504929210513,516471951507,519424725141,523182821526,536604610711,540362690713,540094255258,471913746601,454194909355,437820346540,419029864621,401044689070,384401690799,328835551409,311655682226,279174992051,260652945588,241325609142,260921381123,315413778693,335278002438,367494451463,403460608265,420372041994,437820346635,450973683980,465469214989,483458568463,487753535760,501441646865,500634243346,519158386963,524793434388,517814128917,534993998103,536604594457,540364787994,540633223451,540901658908,540631126301,539557384478,541167997215,541996372256,506808258854,488017776935,489091518760,452051620139,435135992108,416613945645,401581560110,386817610031,328030245169,309778731314,275418992947,261728784692,240788721973,242938302774,241862463799,260652945795,281590911364,312460988805,335546438022,385475432840,402118431113,419298300298,437551911307,447760847244,464399651213,464932327822,499300454802,524256563604,516471951765,533655998871,534993981848,535801385369,538215207325,537678336414,540639515039,507613565350,486675616167,470842102185,434867556780,421177348525,398897205678,381180465583,365074338224,327495471537,242667770293,261194011139,283738395140,318368666117,335278002694,383596384776,400776253961,420103606794,437015040523,464397554190,500663603729,518621516307,516740370964,515666629141,515937161750,534188675608,541167997466,536604594715,535799288348,541167997469,539557384734,504929210917,506812453414,486675599911,488017777192,471374778922,436211831340,418492994093,401583657518,386817610287,362121548336,310313505330,275148460595,259579204148,245083689525,241862464054,281332961924,332862083718,367760790151,384938562184,402118431369,420372042378,437820347019,485064987279,488286212752,515668726420,515935064725,534993982104,536873030297,534993982106,533651804827,533114933916,536604594845,540094255774,524799726241,523988128418,524793434787,520498467492,500902679205,488017777319,488554648232,470837908138,454463345323,415808639661,384401691311,361853113008,326956503729,313266295474,275953767091,258775995060,243204641461,315682214661,332595745542,386280739592,403460608777,420640477962,434330686219,464127021837,465200763662,489630487311,485064987408,516471935763,515666629397,516474032918,535014953751,540362707736,533651804954,535799288603,534188675868,533651804957,538215207710,524795532066,523719693091,518082548516,500370002725,489091519271,486675600168,469495730985,471911650090,455000216363,435672863532,418230850349,401048884014,383864820527,363195290416,326688068401,311655682866,278906557235,244546818869,263609930627,315147441029,368563999623,384938562440,402122625929,420913107850,431916864395,464397554573,467887215502,484278555536,515666629523,516740387732,539288949656,541973304217,536604595098,533651821467,537409901469,540094256030,519961596835,517547774884,505197646758,488017777575,486407164840,469229392809,469495731114,453389603755,433256944556,384135353263,369371403184,330446164913,309776634802,277564380083,260384510900,245620560821,243475174326,243473077250,333132616710,368295564295,385477530632,449096733708,489362052111,499560502290,519156290579,525076567060,518634099734,540368983064,540899562521,541167997978,534993982491,536604595228,541973304349,540631127070,540903756831,520498467874,518084645923,503318598694,486675600423,486140826664,471643214890,450973684779,432990606380,331251471409,310850376754,277027509299,262531994676,248573350965,244012045442,315417973893,368832435335,433525380235,466274505869,468153554062,507345130642,525074453651,540631127193,540094256282,540899562651,538215208092,536873030813,540899562654,520766903457,518086743202,517277242532,500902679717,506271388838,486407165095,471374779561,470837908650,450436813995,398628770990,385206998191,365074338992,328567116977,311924118706,279443428531,263068865716,248036480181,244546819254,266558526723,333667390726,369100870919,386280740104,403462706441,417687688458,431914767627,455000216844,473253827853,472180086030,488823084303,507882001682,539557385497,537946772762,540631127323,534996079900,533653902621,536604595486,520232129825,517545694499,503587034405,506539824422,488825181479,486675600680,470837908777,470569473322,452584297771,435404428588,415808640301,398897206574,386280740143,362389984560,328030246193,313803167026,280252929331,265218446644,245888996661,244815254838,246425867650,263874172291,283740493188,334476891526,368832435591,386016499080,416613946762,430572590475,449094636940,472450618765,471911650702,489091519887,507613566354,540899562905,540631127450,539288950171,534993982878,541167998367,518082549155,520498468260,506002953637,505734518182,488556746152,470569473449,470032602538,455537087915,438357218732,418761430445,401313125806,386012304815,362926855600,328567117233,317024392626,248573351349,245891093942,243473077687,246969030146,261458253315,315952748037,367758693895,403729045001,419298301450,431377896971,450705249804,472180086286,488823084559,507882001938,540899563032,539557385753,536873031194,540899563035,536873031196,534993983005,537946773022,540905854495,519965791777,517545678370,520230032931,520769000996,503318599205,503855470118,486679795239,468153554473,472716957226,450438911531,432720074284,418492995117,398897206830,386282837551,365879645744,331519907377,316755957298,263068866100,245888996917,244280481335,243473077889,266826962563,281324574340,366416516743,402118432393,416613947018,438088783499,449899943564,466274506381,470837909134,489359955599,507613566610,539288950424,533920241305,533653903002,537680434843,540899563164,540631127709,540094256798,519961597602,523182823075,503587034789,505734518438,488017778344,470032602793,472985392810,435672864428,415540205229,398360336046,367758694064,333935826609,314876909234,282664654515,265753220788,248573367989,244012046081,264142608131,316487522053,335009568518,369100871431,386549176072,399165642505,413394818826,432720074507,449094637324,464395458317,468153554702,489628391183,507882002194,536873031448,534993983257,540362692380,537678354205,540899563296,520498468642,523451275043,505734518565,503857567526,485333423912,469772556073,472716957482,455805523755,438357219116,413399013165,399165642542,385743869743,366148081456,331788343089,317292828466,283469961011,266290091828,247768045365,244815255350,263605737347,281054041988,315950651269,333398955910,367758694279,386012305288,398360336265,431914768267,450973685644,466274506637,470837909390,489364150159,501976422290,539825821592,536873047961,540631127963,539557402524,537946773406,539557386144,519424726945,523451275170,522377516964,503855470501,488017778599,486950328232,469770459050,453121169323,433261139884,399434078126,386012305327,368295565232,334741133233,317561264050,281590912947,260921382836,244280481717,243473078198,246425868290,264142608387,281322477572,313534732293,331519907846,365881743367,383061612552,400239384585,415540205578,433793816587,455268653068,473253845005,499294165010,524525000723,525063968788,519156291605,516474034198,539291047960,541168015385,538215208987,539557386268,540631128093,539557386270,541167999007,539288950816,522109081633,524797630498,523721807907,506271389733,505734518822,487749343271,452584298539,401852094510,386549176367,365879646256,330714601521,310581942322,275953768499,258773899316,246962739330,266826963075,283738396804,315413780613,331788343430,400507820169,420372043914,437820348555,454731782284,467885119629,466274506894,487749343376,524256565395,518619420821,535799290007,540633225369,539557386394,540094257307,538215241884,540899563679,541167999136,524797630625,506808260773,506539825318,487214569639,453123266731,381985773743,362389985456,326958602417,309778733234,275416897715,259042334900,246425868546,261458254083,281054042372,315684313349,330714601734,366148081927,383327951112,400241481993,417421351178,435135994123,448020896012,464127023373,464399653134,485064988943,489628391696,498755197202,515935066387,518619420948,516740372757,517814114582,540362692887,540899563800,537946773786,538215209243,540094257436,537946790173,540631128351,541973305632,523988146467,506539825445,506808260902,432720075052,414734899501,398360336686,379032983855,361316243760,275953768755,260652947764,226293209474,263874173315,283738397060,332593650054,365879646599,383061612936,434599123339,430035720588,447215589773,465469200783,485333424528,484261779857,499292068242,498755197331,515666631060,515935066517,516471937430,519693162903,522109082008,539288951193,540362693018,521035340187,522379614620,521035340189,520498469278,523453356447,524793436576,507615664546,506808261027,506539825572,489628408229,470569474471,469764168104,452584298921,453121169834,438357219755,418224560556,397555030445,379032983982,361316243887,326688070064,311655684529,279174994354,244815255987,246962739715,284006832644,298510735877,332325214726,349773519367,400507820553,400239385098,417419254283,430572591628,446947154445,464932329999,467885120016,483454376466,499292068371,498757327380,516471937559,517814131224,522109082138,522914388507,523451259421,522377517598,507613583904,490435795491,489359972900,472448522790,453926476327,452584299048,438357219881,418492996138,398360336939,384401693228,364000598573,344673245742,326956505647,294475815472,283469961777,247231175218,207502727731,246425868931,281322478212,332862085766,349505084039,384133257864,384670128777,400507820682,417687689867,433793817228,449899944589,449094638222,466274507407,468153555600,485333424785,484259682962,482114296467,498755197591,499828939416,500636342937,502244858522,506271390363,503855487644,505734519454,506271390367,507613567648,490433714849,472448522916,472180087461,455268653734,436746607271,435672865448,418761431721,401313127082,381180467883,369637743276,349505084077,329640860334,298770782895,283201526448,241862466225,206160550578,173142989491,280785607428,315688508166,350044052231,367221824264,384133257993,401849998090,419835173643,417956125452,435135994637,452315863822,452047428367,469227297552,472448523025,485333424914,482112199444,484259683093,483454376726,499292068631,500634245912,502513294106,503855487771,486138747677,489091521311,490433698592,473253862177,455268653860,455000218405,437820349222,420640480039,418492996392,401044691753,387086048042,369906178859,332862085932,315145345837,298233912110,283201526575,246157433648,207234292529,156768426802,121603382067,263605738372,369906178952,384401693577,401313127306,399434079115,417419254668,434599140237,451779009423,471911652241,468153555858,483454393235,487749344149,489628392342,489359956887,487749344152,485333425049,488286215066,489628408731,489091521437,486675602334,472448523167,473253845920,456073976738,438896188324,437820349349,420911012774,403731143591,401849998248,383864822697,367221824426,332327312299,315145345964,297965476781,263605738414,246694304687,210723953584,174485167025,122140253106,352457874439,364537469960,386817612809,384401693706,401313127435,416613948428,434599123981,434867559438,452047445007,468958862353,471643216914,472180087827,471643216916,489091537941,489628425239,489359957018,490433731611,473253862430,456076074017,438896188451,420644674597,385207000104,366684953641,349513473066,297967574060,281322478637,246962740270,229246000175,191665036336,140125428785,103886642226,352726310023,364000599176,384133258377,387086048394,401046789259,418492996748,433793817741,436209736846,453389606031,450973686928,468153556113,470569491602,471106346132,488017796245,487749344407,488286215320,489091521689,488017779866,486675618971,489359957149,472180087966,472448539807,438088785060,420640480422,403462708391,386280742056,366955486377,332593650859,283738397869,249378659502,229784968367,193275649200,139856993457,349505084679,369906179336,387086048521,384405888266,418767723788,435947592973,435672866062,452584299791,453121170704,470301056273,470032620819,487212506389,487749344536,488017779993,489091521818,488554650907,486407183644,469495749918,468958862624,452047445281,434599124259,437551914276,420915207462,386555469096,332325215531,300920364332,278638124333,246696402222,190322859312,367221824904,386817613193,401585757579,435945495950,453121170831,455537089936,472716991889,470305234324,487480925589,485333425559,485601877400,485870296474,486138764699,469227298206,471911652767,469495733664,454194912673,452047429026,434867559843,438088785316,420908916133,403733241255,367490260393,332862086571,281054043565,383864823305,455807622671,452852735504,466274508305,472716975634,487483006485,487749344790,485870296599,485601861144,483722878489,466545040926,468422008351,451510574625,434330689059,437820349988,421714222629,368027131433,332327312939,298504445484,283738398253,243473079854,381448904330,455537090192,472716975761,470301040275,484259683990,483454394007,485064990361,483722829466,485601861276,483722813085,466542960287,449363091105,434062253731,432720076452,419029868197,370174615209,352457875114,277832818349,398091902731,415271771916,432451657485,449631526671,467348250385,469764185874,467348250388,483991248661,481843765018,482380652315,483454377757,465737637662,466006073119,467885121312,451242123041,449363074850,430841028387,415808642854,401313128231,384670129960,368027131689,352189439786,332862086955,295549558572,464663895968,447484043169,329372426155},{813711391,809517214,809517341,809517468,1080050078,1077953053,1080050207,807453324,1077969563,809517728,1075872428,1344324270,1075921674,807420687,538985232,1075856154,1346405149,1344324393,1612759852,1881162543,1612759856,1344357257,1075872654,807420816,538985361,1344324506,1344291743,1075856288,1344291752,1612727209,1881195434,2149663661,1881195442,1612760072,1881195531,1612743694,1344291856,1075856401,1881211929,2149614621,1881162783,1612727328,1881162792,2149598249,2418066474,2686518317,2418050097,2149614643,2149631112,2418033803,2686485645,2418050191,2149614737,3223422105,2954921119,2418033829,2954904744,3223405737,3223340208,2954921137,2686469299,2418033844,1881163015,2418033928,2686485769,3491775758,3223389455,4028646680,4297180441,4028646688,3491792164,4028712232,3491775793,3223340338,2954904883,2686469428,2418034055,2686469512,2954904969,3223340426,4297147790,4833969557,5102405015,5370938777,5102388641,4833985956,5102421416,4833969579,4028646833,3760211378,3491775923,3223340468,2686469639,3223340552,3491776009,3760211466,4028646923,4833953293,5102405134,5370840592,5639259666,5907695125,6176146966,6444729880,6176179747,5907727912,5639276075,5370824237,4833953328,4565517873,4028646962,3760211507,3493873204,3223340597,2954905223,3491776136,3783280265,4299179658,4571809419,5102388876,5375018637,5643454094,5909792399,6176147088,6717195924,6981453461,7249921687,7518406299,7249921698,6981437094,6981437096,6713018025,6444566187,6176130732,5907695277,5639276206,5102388912,4833953457,4297082546,4028647091,4842342156,5911889680,6178227985,6713001747,6717196053,6981453590,7250052888,6981453604,6713018150,6444566313,6176147242,5907695404,5639259949,5370824494,5102389039,4833953584,4297082673,3760211762,4045424522,5643454351,6444582802,6715099030,6981502871,7249921948,6981502880,6713018277,6444582823,6176130985,5907695530,5639260075,5370824620,5102389165,4833953710,4565518255,4297082800,3760211889,5117069325,5387601934,5924472849,6178228242,6444582931,6715099159,6981568536,6713051169,6444582949,6176147495,5907695657,5639260202,5370824747,5102389292,4833953837,4565518382,4297082927,3760212016,3223341105,3235924104,4309665931,5651843216,6188714131,6444599444,6713165976,6444583075,6176147621,5907712167,5639260329,5370824874,5102389419,4833953964,4565518509,4028647598,3760212143,3223341232,2686470321,5381310735,5918181650,6186617108,6455085333,6725699864,6455085344,6176164131,5920278822,5639276839,5383407913,5112875306,4833954091,4307568940,4039133485,3772795182,3233827119,2696956208,2160085297,4573907340,6184536483,5916084645,5647649191,5379213736,4573907371,2692762119,1619020338,1075857971,2418035718,2954906631,3491777544,4297083914,4565519371,4833954828,5370825741,5639261199,5907696656,6176132114,6444600339,6713019414,6713019424,6444600354,6176132133,5907696679,5639261224,5370825770,4833954859,4565519404,4297083949,3491777583,2954906672,2418035761,1881164850,2954906758,3491777671,4028648584,4297084041,4565519498,5102390411,5370825868,5639261325,5907713166,6176132240,6444584081,6713035923,6981618838,6713035938,6444584101,6176132263,5907713192,5639261354,5370825899,5102390444,4565519533,4297084078,4028648623,3491777712,2954906801,2418035890,3491777798,4028648711,4565519624,4833955081,5102390538,5370825995,5639261452,5907696909,6176132366,6444584207,6713003281,6981471506,7249923349,7518391577,7249923359,6981471523,6713003302,6444584231,6176132393,5907696938,5639261483,5370826028,5102390573,4833955118,4565519663,4028648752,3491777841,2954906930,3760213381,4028648838,4565519751,5102390664,5370826121,5639261578,5907697035,6176132492,6444567949,6713019790,6981455248,7249890706,7518358932,7786859928,7518358944,7249890724,6981455270,6713019816,6444567978,6176132523,5907697068,5639261613,5370826158,5102390703,4565519792,4028648881,3760213426,4297084421,4833955334,5102390791,5639261704,5907697161,6176132618,6444584459,6713003533,6981438990,7249890831,7518326289,7786794515,8055328279,7786794529,7518326309,7249890855,6981439017,6713003562,6444584491,6176132653,5907697198,5639261743,5102390832,4833955377,4297084466,3760213555,4349513348,4880092805,5152722566,5685399175,5958028936,6224367241,6490705546,6759141003,7025479308,7293931149,7562366607,7830802065,8099270291,8367804055,8099270305,7830802085,7562366631,7293931177,7025479339,6757043884,6488608429,6220172974,5951737519,5683302064,5146431153,4877995698,4341124787,3760230144,3762327425,4070592387,4066398260,3760214146,3762327734,3789574453,3762311606,3776992182,3781186562,3764409783,3764409985,3491780994,6717200780,6985636237,7251990926,7518329232,7786764690,8055249300,8323635609,8055282075,7786781090,7518329253,7249893799,6981458345,6713006507,6444571052,6176135597,5907700142,5639264687,5102393776,4833958321,4297087410,3760216499,3762313731,4573911557,5383412231,6182427146,6448765451,7254071824,7520426513,7786797587,8055314967,7786781216,7518345763,7249877542,6981458471,6713006633,6444571178,6176135723,5907700268,5639264813,5370829358,5102393903,4565522992,4297087537,3760216626,3223345715,5922380425,6983539342,7249877647,7522507411,7786945172,7518345889,7249894052,6981442214,6713023143,6444571305,6176135850,5907700395,5639264940,5370829485,5102394030,4565523119,4297087664,3760216753,3223345842,2686474931,4840250118,5649750792,6461348620,6729784077,6998219535,7266654993,7518313234,7520443156,7786830615,7518362397,7249910561,6981458724,6713006886,6444587815,6176135977,5907700522,5639265067,5102394156,4833958701,4565523246,4297087791,3760216880,3223345969,2418039602,1881168691,4028652420,6190816139,6727687054,6996122512,7264557970,7518428055,7249910687,6981458850,6713023396,6459251622,6176152487,5907700649,5639265194,5119171499,4833958828,4565523373,4028652462,3760217007,3223346096,2686475185,1881168818,5918186506,7262477331,7528930325,7262493726,6996139041,6723509283,6455057445,6188719143,5920283688,5651848233,5383412778,4578106412,4307573805,3768605742,3495975983,2959105072,2151701553,1612733490,7518314261,7518363418,6713007907,7249878944},{12,78,88}},
['Sabertooth Egg']={58,64,2.56666667,2.8,2.56666667,{{255,255,255,0},{251,215,102,0},{236,222,194,0},{230,198,151,0},{208,194,159,0},{220,171,148,0},{240,162,44,1},{237,134,65,1},{235,118,31,1},{188,167,133,0},{163,129,105,0},{228,104,18,0},{226,91,18,0},{199,94,35,0},{169,94,46,0},{213,70,20,0},{203,55,15,0},{173,62,33,0},{120,90,69,0},{101,75,64,0},{117,64,43,0},{76,64,60,0},{106,52,32,0},{60,51,49,0},{190,38,17,0},{197,15,11,0},{162,31,17,0},{160,8,6,0},{112,41,23,0},{128,17,14,0},{91,40,23,0},{81,41,26,0},{62,41,36,0},{50,42,42,0},{72,33,22,0},{66,21,14,0},{23,19,19,0}},{241862459418,227098509465,242399330458,227903815961,244546814234,241862459675,243204636959,226024767776,121334939944,140125421970,172606112148,189517545877,224682590616,229787058585,247235363226,242399330715,240520282526,245083685279,227366945184,223877284257,189785981348,172337676709,140125421991,122945552808,140930728466,173142983188,189249110549,226024768024,244009943579,243204637214,247235363359,229782864416,224682590753,206965850659,190591287844,172608209445,140930728487,143883518610,155963114131,173679854228,191128158869,206965850774,227100607128,244546814619,241862460060,244278379166,230055494304,226830074529,223340413602,208039592611,191933465252,157036855974,143883518631,142006567698,161063387923,173948289812,191933465365,207771157270,230053397273,246962750234,242399331100,245083685662,227635381025,224682591010,209115431715,191128159012,173679854373,159184339750,142006567719,161331823507,175022031764,191128159125,208308028310,224145720215,230319735704,246962733978,247231169435,244278379420,243204637597,247768040350,246962733983,229782864801,226561639330,190591288228,174753596325,161868694438,176364209170,196228432915,210455512084,225487897621,226293203990,244278379543,247499605016,264947909657,264411038746,264142603291,262800426012,262531990557,264679474206,264411038751,264142603296,246962734113,244009944098,226293204003,208308028452,209113334821,196228432934,176364209191,244278379666,247768040595,261995119764,277027505301,278369682582,300112954519,299844519064,299307648153,315950646426,315682210971,316755952796,317292823709,316219081886,298770793631,298502341793,299844519074,278369682595,259847636132,242667766949,247768040614,227098510503,172337677576,277564376337,297160164626,317024388371,313803162900,328567112981,329372419350,348162901271,350847304984,368564012316,350847272222,350041949472,350310384929,333398951202,329372419363,311387243812,295012680997,299844519206,278638118183,258773894440,223877285255,241594025352,309776631183,328298677648,352189433233,369100866962,365611206035,366148076948,381448897941,381180462486,399434073495,402118428056,402923750809,402655298971,400507815324,402923734429,402118428062,402386863519,384938558880,384401687969,381985768866,362926867875,348968207781,348699772326,332593644967,317292823976,293938939305,258237023750,275416892935,293133633032,379301414415,399165638160,404265911825,416077071890,414198023699,435404424724,437015037461,435941295638,453658052119,450436826649,451778987547,452315858460,452047423005,450436810270,434062263839,432720086561,416345507363,414466459172,398897202725,386817607206,383596381735,368832431656,347089159721,309776631430,344945870471,361855207048,430572586638,448826197647,450973681296,454194906769,466006066834,467348244115,471911646868,488017774229,488286226070,485064984216,483185936025,482649065114,483185936027,488554645148,489091516061,486944048798,471374775968,468153550497,467885115042,450973681315,448826197668,432988505765,438357214886,435135989415,418224555688,399434073769,379838285482,361316239020,326419629741,292598859525,310045067014,399970944779,417150813964,434330699533,451242133263,468421986065,466811373330,488554645267,489091516180,488286226197,505197643543,501171128088,500365805338,501439547163,506273498908,489091516190,486944032543,489091516192,488017774369,485064984354,468153550627,466813470500,450168375077,455268648742,435672860455,434867554088,419298297641,398897202986,380375156523,379301414700,345478547245,327224936238,309776631599,189517547315,258237024132,310313502598,363195287432,418492991371,420908910476,438088779661,452852729742,452047423375,468690421648,467616679825,483454371730,486944032659,488554645396,488286209941,505466079126,502513289111,501171111832,501439547289,501171111834,501707982747,506271401886,507347224480,488823080865,485333436322,467348244389,469495728038,451779004327,434330683305,417419249578,400239380395,403460605868,385475430317,345746982830,328030242735,309508196272,292596762545,224145721267,189517547444,275962152964,292865198085,327224936454,344675338247,361853110280,417956120587,433256941580,452049520653,456342390798,471911647247,465737631760,486411356177,482114291730,483722807315,503855466516,503050160149,503587031062,501976418327,518887852056,518619416601,517545674778,519961593883,524524996636,523451254813,523719690270,507345127455,504123901985,502781724706,501976418339,484796549156,485870290981,468958857254,467616679975,455000213544,452047423529,433256941610,421714233387,400239380525,379838285870,363732158511,328567113776,311118809137,292596762674,258773895219,224145721396,189517547573,293402069125,328837646470,378496108680,417150814347,431648426124,456073955470,469227292815,468421986448,499292063891,507613563028,501976418453,520230029462,521572206743,521035335832,520766900377,520230029466,520766900379,523988125852,523719690397,521035368606,520498464929,521035335842,504392337571,501976418468,500367902885,484796549286,482649065639,467348244648,471374776489,452047423658,452584294571,438625650860,417419249837,395675977902,380106721455,363732158640,346552289457,327761807538,293133633715,260116072628,223877286069,206697416886,294475811077,363195287815,380643592456,399970945289,417421347082,416077072651,454194907405,473253824782,469766261007,489091516688,499560499474,498755193107,500902676756,518350981397,518887852310,523451255063,520766900504,537946769689,538752076058,538215221531,541438527773,538752092446,541438527776,523988142369,523719690531,518353078564,500365805862,501173209383,483188033832,484528113961,471913744682,469764163883,455805520172,437820344621,414198024494,396481284399,381180463408,380912027953,345746983218,327761807667,293402069300,275687426357,241057155382,293133633925,327761807750,366148077959,387086043528,400239380873,414466460043,432720071052,452047423885,469497825678,490165258640,485870291345,499027839378,515935062420,517545675157,518350981526,517545675159,534725560728,537946769818,541973301659,541436430748,538215205278,541436430751,540899559841,524527094178,523455449507,518353078693,501171112358,483991243177,471911647659,452584294828,438088780205,418224556462,417150814639,398897203632,381985769905,363732158898,328298678707,294490491316,241325590966,223877286327,293402069509,329909291526,368295561735,386549172744,404534348297,421445782026,415808637451,434062248460,452852730381,468958857743,486675597840,483731196433,516203514388,519424723478,518350981655,535532964376,536067721754,540899559963,538217302556,537678367261,538752076320,541170092577,518619417124,501439547942,501707983399,484796566056,468958874154,451778988588,435138087469,417419266606,401313122864,386012301873,362658417202,328850229811,275953764917,242940398134,225756334647,275685329540,295549553285,332862081670,363465820807,383598480008,400239381129,417958218378,416077073035,435404425868,455539182221,472719051406,470032599695,489898920592,516207692436,515935062677,517277239958,519424723607,537141463706,541167995547,538752109213,538215205536,523990223522,518350981796,518619417253,502781725350,503857564327,486675614376,470032616106,452854827692,420908911278,421445782191,400776252080,380643592881,361584675506,277300136629,224414157495,241057155843,276759071492,296623295237,331788339974,400776252169,417150814987,435135990540,472716954383,500636338962,499023629075,516203498261,515935062806,518887852823,535799286552,535530851097,540094253850,541440625435,538754206492,541436463903,521303771939,518887869220,503587031846,487214582568,470032599850,472716954411,435674958637,420640475950,417956121391,397555026736,378496109361,363205774130,223879383863,242399333251,278906555268,297430698885,332056775558,366953384839,383864818568,401044687753,418493008778,435674958732,452584295309,467616697230,490433694608,499292064659,516740369301,516203514774,536336157592,537946770329,537678334874,538756271007,541436431264,538754173857,520498498466,521303772069,506808257446,504392338343,472716954538,472448519083,456342391724,416077073326,420640476079,400239381424,380375157681,241862462390,244012043267,279174990852,332595743750,369639836679,386012302344,402655300617,420642573322,418495089675,450176764941,466006084622,488554646544,499292064786,500634242067,517814144020,515935063063,533651803160,541168012313,541440625692,538752093213,538215205920,523988126754,524524997667,524793449508,507881999398,507078790183,489896823848,489091517481,470837922858,455805520940,434330684461,413929589806,419835169839,401044687920,380643593265,277564378165,241596124214,223877287042,281859345540,297697037445,387354479752,403192171657,437824539788,466811374734,467616681103,486944033936,485874486417,500640533650,499560500371,517814111380,516740385941,516203498647,533114932376,533920238745,540899560602,541167996059,541440625821,538752076958,538752076960,541436431521,524256562338,521035353251,520498465957,503857564838,490433694888,488017775785,468153552042,470301035691,451778989228,434867555501,414466460846,416077073583,404534348976,382791077041,277295942837,224145722626,244546817283,282396216580,298238102789,335280098566,369100868871,384938560776,402118429961,420372040970,420911009035,468421987598,470034697487,489634680080,500638436627,516744563988,517822516501,516471934231,533383384344,535264513306,541975399707,541436448030,541167996192,540899560737,521572207906,521035336995,520498466084,521035336997,504392338727,489091517736,488290405673,470569471274,471106342187,455274941740,437824539949,415273864494,415808638255,401044688176,380643593521,277564378421,243204640054,224682593666,244815252867,280248733060,367760788871,382254206344,401581559177,421714218378,469764165006,516740369815,533383368088,533651803545,541975399836,540899560862,537946770847,536067722656,534725545377,518887853474,521303772579,523988127140,521303772581,504123903398,506539822503,488823082408,471110536618,471649504683,419835170223,397823462832,380375158193,296895925684,284275264949,245352123830,226830077442,245083688451,280517168644,335009566214,384676417032,402388962825,420116188682,421714218507,438894087692,471911648782,472716955151,486944034321,517816208919,533651803672,533383368217,537409900058,541704867355,537141464605,534725545502,535530851871,535803498016,518619434530,519963692580,523453353509,506271387174,504123903527,488554647080,415810735662,416077073967,396749721136,379571949105,363463724594,335009566259,282396216885,244278382134,226024771202,248036478595,283740491396,300926652037,335550631558,367223918215,417956122251,437820345996,450436812429,469764165262,472180084367,489359953553,500902694546,517818306196,534993981080,535262416537,537946787482,540094254748,536877223581,535799303838,519693176482,506539839142,489359953576,488827276969,438625652397,413935881903,395407543984,362404662962,330177728179,279711862453,245888994998,224682594050,245352124163,401849995017,418501381899,434599120652,452049522445,469231488782,467616681743,490433695504,490165260049,500902678290,500634242835,518082547479,537409900312,540631125785,538485739290,540631125787,539557383964,536877223710,536604593951,519426838306,522377514788,524793433893,506808258342,507347226407,490433695528,470837907242,455537086252,435135991597,416079171374,396760207152,378227674929,328040730419,297428602676,275953766197,245352124214,225756335927,223879384962,241862463363,284008927108,367758692231,402395254665,435135991692,469227294607,484796551056,482651164561,498486759314,500902678419,517816209301,518082547606,520766902167,540631125912,538483642265,540094271387,536873045919,535799287713,518619418532,523451256741,507613564838,489359953832,471643213738,472180084651,452852731820,438090878893,379582435249,295817990068,278369685429,241864560566,226024771511,244009947139,335013761030,368566095879,385213288456,435679154188,452320055309,465483878415,481308987408,499828953106,518082547732,523719692310,524527095831,538483642392,537946787865,538483642395,540631126044,539559481373,536873029663,539020529696,519424725026,519705743395,519424725028,522914385957,503857565734,503318597671,486140825640,486944034857,471374778410,472716955691,455270748204,416882380846,294209474612,281861443637,224682594434,246962737283,283201523844,465477587086,481306890385,498486759570,501707985043,523182821524,519156289685,523451256982,540633223320,538485739673,540094255258,540631126171,541704867996,539020529822,539557384352,539024707745,519695257762,519693160612,520766902437,503855468711,486142922921,468965150890,470032601259,434867556525,416345510062,414466461871,245083689142,223340417207,223879385272,224416256185,223877304576,226834272514,247503802627,282935185668,301723570437,368295563527,482659569936,499837325586,502781726995,522645967124,522914386198,523719692567,538483659034,540094271772,537141465374,539020529951,521840644388,522920677669,504392356134,486675599656,469497827627,455537086764,434062250285,415540203822,413935882543,295549554996,281324572981,247774335286,224682594615,224422547840,223877288321,301186699653,335814873478,366684950919,419835171210,417956123019,455272845709,501710082451,522648048020,522379612565,523182821782,523453354391,541706965400,540631126425,538483642778,540641612187,540094255516,540633223581,541979595166,539557384607,539020513696,521844838818,519695258020,504123920806,487212470696,452315861420,433256944045,415271768494,299576086964,227905917367,224684691896,223877288377,224145723905,280785605124,301455135237,335011664390,365879644679,385743868424,402925834761,420640477706,418497188363,438359314956,522379612694,541704868377,540635320858,540631126556,541975400991,537141465632,536873030177,506271388198,505734517287,489359954472,486407164457,470034698795,455539184172,434867556909,414466462254,397286593072,329909293619,301455135284,281859346997,224414159489,224682594946,244278383235,277564379780,301723570821,366416515719,386012304008,421177348746,502781727379,523182822036,522648048277,523182822039,540899578520,538483643036,541704868509,541973303968,539557384865,519961596580,505734517414,502781727399,484259680936,484528116393,469229392554,438357217965,416077075118,396749722288,362926854834,333935825587,297160168116,278638121653,227098514103,224416256696,224682595073,224145724162,241325593347,275953767172,297697039109,334741132038,366148080391,385475433224,403194270473,418492994314,435672863500,456342393613,467616682766,505474470675,522650145556,522648048406,522377515799,540631126808,541704868633,540633223964,541975401245,540899562271,538485740320,540631126817,522377515810,522379612964,519961596709,502244872998,485065003816,469764166443,455000216364,435672863533,418492994350,416882381615,398091899696,381448901425,368832434994,336083309363,294748443444,277295944501,248307012406,226024772407,225756337025,224682595202,241594028931,275685331844,292596765573,328835552134,369906176903,383864820616,420913107850,421179446155,438359315340,455539184525,469227295630,502244856722,523182822293,522645951383,540362691480,541973304217,540899562394,540899562398,538483643295,538489934753,522914403234,519693161381,502513308582,485064987560,485333423017,468421989290,471374779307,452584297388,437820347309,421183640494,419835171759,399165641648,385475433393,369906176946,335816971187,277564380085,224682595255,224414159873,225756337154,242938303491,276224300036,293133636613,327763907590,366684951559,387354481672,403460609033,471911650318,470837908495,485601858576,485333423121,505470276626,522914386965,523182822422,519693161495,536067724312,537141466137,540631127066,541973304348,541704868893,538483643422,540641612831,540094256160,521305887778,522914386980,519961596965,502244873254,485333423144,482917504041,469227295786,472985392171,454199104556,437556106285,417687688239,398360335408,382522643505,369100870706,278638122037,244278383670,223877289015,224414160002,294477911173,362121548935,382791079048,404265915529,420640478347,434867557516,454731781261,470837908622,471108441231,488288326800,523182822548,520230032533,518887855254,517545677975,534727660696,536067724442,540094256283,540631127196,541975401629,540635321502,538483643552,523455452324,523187016869,502244856998,502513292455,484528116904,481843762345,471374779562,471917941931,418224559279,399167739056,385477530801,369906177202,335548535987,296891733172,280248734901,242936206518,241594029315,277295944964,329103987974,363463726343,380643595528,403731141897,418492994826,421445784843,432988509452,450707346701,470301037838,522914387220,520769000725,518351000854,534725563674,537141466396,540635321632,523453371682,504660776230,502781728039,481845859624,483458569513,471911650602,420372043055,370174612786,297965475124,278638122293,241057158454,328835552646,369637741959,382791079304,421177349514,420640478603,433527477644,470837908878,471645312399,488288310672,488017778065,505197647250,506002953619,523453355412,518350984598,518625711511,535532950936,534725547417,535530853786,535799305627,540096353693,540633224609,502781728166,499025728935,472180086186,452584297900,438627751341,421445785006,419835172271,399704610224,386012304817,369369306546,331519907251,299578185140,282396218805,242936206774,331519907334,370443048455,386549175816,404534351369,421714220554,419298301451,451242120717,473255925262,483995440657,501439550994,502781728275,519156291093,517545678358,535532951065,535799289370,535530870299,540901660190,523451258402,523719693859,524793435684,522914387493,499560502822,482114295336,472985392682,454731781676,419298301486,418761430575,387356579377,363463726642,279711864373,332593649286,369637742215,387354482312,403460609673,417687688842,418761430667,435941299852,454467540621,473253828239,488017778320,501171115666,501707986579,507345131156,522914387605,518619420310,518623614616,535530870426,536067724956,541973304989,541704869536,523453355681,523719693986,525061871267,521035339428,499023648421,500634244775,485870294697,472448521898,472180086443,454194910892,437283477165,419029866158,401849996975,384938563248,346283857586,327761811123,297428604596,297697040133,335280101126,353267373831,383864821512,379576145673,396749723402,419029866251,436748703500,452315862798,470032602895,468421990160,484528117522,506271389459,507076695828,506808260373,518887855894,518353082137,518619420442,518350984987,518887855900,525061871389,524795533086,523719694111,523451258656,524525000482,503050164003,498755213092,483454392102,466274506536,470032602921,452852733738,455268652843,438625654572,420103608109,401849997102,384670127919,368564000560,352994744113,329103988530,294475814707,297160169349,364541663112,397286594442,419568834443,455270750094,472716957583,469227296656,484796553105,489359955858,490702133139,507345147796,502781728662,501441648535,518350985114,518887856027,524793452444,506271405983,507345131425,500634245026,498755196835,481843763108,483454375845,466276603814,465200764839,451510556584,455537088425,438357219242,421177350059,420908914604,402923739053,385206998958,368027129775,334204262320,318635005873,296623298482,259042334643,315413780486,396751820810,419570931724,437285574669,455539185679,472448538640,489896826898,489628391443,486944053268,505734518806,501441648664,501171132441,505197664283,501708003357,505197647903,507613567008,489359956001,482112215074,466274523172,449094637607,455000217640,439162525737,421177350186,403997497387,386012305453,350847260718,333667391535,317024393264,299039217713,264142608434,224682596403,314879006854,352994744455,402120530059,434867558542,455539185808,472716974225,489359956115,489091520660,486946134165,489091520662,501707987095,502781728921,504660777114,502244858011,501439568028,485064988830,485335521439,488017778848,489091520673,483454376098,466274523299,449094654117,431109478567,417687689385,404802787498,386817628331,351652567213,333667391662,316487522479,279443429552,259042334897,230588176562,192738777267,351921002759,362121550088,362389985545,379569854730,436478171405,434330687758,456342395151,452852734225,472716957970,471911667987,488554649878,485601876247,488823085337,488017778970,485333424411,485065005340,485333424414,468155652384,471911651617,466542942498,449363089699,432183204133,431109478694,413929593128,396749723945,386549176618,369637759275,335546439981,316487522606,282129881391,262263560496,223877290289,213139872050,159188539699,262800431494,282933090695,327224940937,343867939210,365342775691,385206999436,385475434893,403997481358,421177366927,438357219729,438625655186,455805524371,454731798932,471911684502,471374780825,468421990810,470301039003,468153555356,467885119901,468153571742,450436815265,451510557090,451778992547,435135994276,433256946085,413929609638,396749724072,379571952041,383327951274,370443049387,352457873836,335278004653,300112959918,244280482224,195960002994,210992388614,228172257799,274880027146,311655684619,334204262924,349505083917,366953404942,386817612304,404534352401,418761431570,419298302483,421445786132,438625655317,437551913494,454731815447,454463347226,453121186331,450705250845,450973719070,436478171681,438894107170,421714221604,414466464293,413929593382,396751821351,379571952168,368832436778,353265277483,335282199084,315415878189,300649830958,265216350767,192738777650,157305297543,279443430028,314876910221,315413781134,332593650319,352726309520,368564001425,384670128786,384401693331,402923739796,404265917077,420372077206,438625655449,438894090906,436478171803,435941317276,433793817246,435941317279,437283478177,421714238114,419835173540,398091901605,396749724326,362389985961,352726309546,283738397358,260384512687,241862466224,191665035954,140125428403,243204643596,263874173709,283738397454,300918266639,318366571280,333398956817,350310390546,367221824275,367758695188,386012322581,403192208151,402655304474,419835173659,419298302748,418761464605,416613948192,419835173665,421714221858,403192175395,401581562660,399434079013,380106726182,379569855271,362389986088,362926857001,347089165098,334472698667,300920363821,281054042926,232198790029,249378659214,266558528399,284543703952,299844524945,316487523218,333667392403,350847261588,351384132501,370174614422,368832437143,386012306328,381448903577,379569855386,398628772763,402923740060,402118433693,401581562782,399434079135,401581562784,402655304609,403192175522,385743870883,382254226340,381985774502,362926857127,363732163496,346820729769,329372425130,329909296043,311924120492,280517172142,194619923469,215021018126,250183965711,263337303056,280248736785,299309751314,316487523347,333667392532,333398957077,347089165334,351115697175,368295566360,363732196377,386012306460,387354483741,384938564638,382254210079,385743871008,386012306465,383864822818,368295566371,367758695460,367221824549,350041955366,350578826279,330714602536,312460991529,313534733354,293938945067,263337303085,245620562990,228977564815,277564382353,299309751443,316487523476,316219088021,328567118998,347089165463,347626036376,346552294553,346820730010,346552294555,368295566492,370174614685,368295566494,350578826399,351115697312,349505100961,351652568227,333398957220,332862086309,316219088038,312997862567,293938945192,279174995113,261189819562,241325595819,194080955661,211797695758,281859349778,299039218964,311924120853,312460991766,329640860951,329372425496,329640860953,330446167322,329909296411,348968213788,352726310173,334472715550,333935828256,334472699169,334741134626,317292829987,299039218980,298502348069,281322478886,276222205223,241325595944,227366952233,208039599402,279443447186,293402074516,292596768149,312192556438,313266298263,312461008280,313266298266,310581943707,326956506524,335546441117,317292862878,301186719137,279711866275,281859349924,264679480741,243204644262,190322859433,155426250154,260116078098,275416899093,293938945558,296086429207,295281122840,296086429209,293938945562,292596768283,296891735581,300112977438,282933091872,284006833697,279980301858,244278386212,227903823397,206697422374,276222205590,295281122967,296086429336,293938945689,292596768410,280785608350,284008930975,266826964640,263605739169,245352128162,208576470692,190322859685,293938962199,292596768537,279711866654,262800432928,260384513825,279711866783},{3774890010,3504357529,3770695963,3770695967,3502260512,1883259176,2157986194,2694857108,2963292565,3500163480,3768598942,3500163489,2963292580,2694857125,2157986215,3229631011,2422227603,3227533974,3764404892,3495969442,2422227622,3491775383,3760210845,2686469138,2954904595,3223340052,3491791893,3760227351,4028761113,3760227361,3491775523,3223356452,2954904614,2686469159,3760227474,4028646548,4297098389,4565550231,4834018458,4565566623,4297082019,4028646564,3760227493,3491775655,2686469384,4297082129,4565517586,4833969427,5102404885,5370889495,5639275804,5370873118,5102404898,4833953060,4565533989,4297082151,4028646696,3491775879,3760211336,4833953167,5102388624,5370824081,5639292306,5907711381,6176261527,5907727776,5639275939,5370840485,5102388647,4833953192,4565517737,4028646918,4297082375,4565517832,5907695119,6176146960,6444582418,6713034260,6981551639,6713050655,6444582435,6176130597,5907711526,5639259688,5370824233,4838147718,5379212935,5645551240,6715098766,6981469839,7249905298,7518471829,7249905312,6981453475,6713034405,6444566184,6176130729,5907695274,5639259820,5102388909,4624238341,6176130827,6446663436,6715098893,6981453583,7249889041,7518357267,7788939031,7518373662,7249889059,6981453605,6713018151,6444566313,6176130858,5907711787,5370824493,5102389038,4833953583,2954905395,4028647300,6513772427,6981453710,7249889168,7518357394,7788840854,7786776478,7518341025,7249905572,6981453735,6713001897,6444566442,6176147371,5907695533,5370824622,5102389167,4833953712,4565518257,3491776435,2954905524,4351608836,5167400966,6778013708,6983550989,7251986447,7518341137,7788857364,7786743831,8057374744,7786809375,7518324772,7249889318,6981453864,6713002026,6444582955,6176131117,5907695662,5639260207,5102389296,4833953841,4565518386,4028647475,3491776564,2954905653,5968513160,7518324881,7847561363,8116013206,8055228575,7786776739,7518324902,7249889448,6981453994,6713002156,6444566701,6176131246,5907695791,5639260336,5370824881,5102389426,4565518515,4028647604,3491776693,3223341238,5695883527,6232754441,6501189898,7042255117,7306512654,7574948112,7843367186,7786744084,8111802645,8055179544,8380352793,8055228705,7786776869,7574948136,7306512682,7038060844,6769625389,6501189934,6176131375,5907712304,5370825010,5154818355,4622141748,4351609141,3812641078,8107608468,8376043928,8376043937,8107657634,7841286566,6496995759,6228560304,5962222001,5691689394,3500165559,3802155779,3525332098,3493875511,3496005815,3502280960,3495989815,3493876663,3491779585,7790941844,8059377304,8055232161,7788844709,6176134831,5907699376,5370828466,5102393011,4567619333,5379217159,5913990921,6182426378,6985635598,7251990287,7520425745,7788844821,8055330585,7786764067,7518328614,7249893160,6981457706,6713005868,6444570413,6176134958,5907699503,5639264048,5370828593,5102393138,4565522227,5645555592,7522506643,7788861334,8055265177,7786813343,7518328740,7249893286,6981457832,6713005994,6444586923,6176135085,5907699630,5639264175,5102393264,4833957809,4565522354,4028651443,4838152198,6448764940,6717200397,6985635855,7249893392,7518312466,7520426004,7786879000,7518345249,7249909796,6981457959,6713006121,6444570666,6176151595,5907699757,5370828846,5102393391,4833957936,4565522481,4028651570,3491780659,6178232459,6715103374,6983538832,7249893521,7520409750,7786846359,7518378142,7249893539,6981458085,6713022631,6444570793,6176135338,5907716267,5370828973,5102393518,4833958063,4297087152,4028651697,3491780786,2954909875,5639264521,5907699978,6981441809,7249910034,7518312725,7518443799,7249910048,6981458211,6713039141,6444570920,6176135465,5909797162,5639280939,5104490797,4833958190,4299184431,4028651824,3491780913,3223345458,2422233395,4028651910,4297087367,5102393737,5370829194,5639264651,5907716492,6176135566,6444587407,6713022865,6981474707,7250041238,6981474721,6713022884,6444587430,6176135592,5909797289,5639264683,5370829228,4567620014,3764410800,2959104434,3223345670,3491781127,4297087498,4833958411,5102393868,5370829325,5639281166,5907700240,6176135697,6444603922,6713022997,6981589527,6713039393,6444603940,6178232871,5909797416,5639264810,5372926507,5106588204,4836055597,4030749231,2418039431,4297087628,4833974925,5102393999,5370829456,5639264913,5907716754,6176152212,6444604054,6713137817,6444604066,6176152229,5641362089,5372926634,4301281966,2149604019,3760216844,4028652301,4297087758,4565523215,4833958672,5102394129,5370829586,5639281427,5907716885,6176185111,6444686107,6176168739,5907716902,5641362216,5104491307,4567620397,3491781517,3760216974,4028652431,4297087888,4565523345,4833958802,5102394259,5370846100,5639281558,5907733400,6176250779,5907749795,5639265191,5370829737,5102394282,4833958828,2959105037,3227540494,3760217103,4028652560,4299185169,4567620626,4833958931,5102410772,5370846230,5639314456,5907799068,5639298083,5370846246,5102394408,4833975337,4565523499,4028652589,3760217134,3491781775,4567620755,4833975444,5102394518,5370895511,5639298204,5370895519,5102410916,4833975462,4565523624,4297088169,4028652714,3760217259,4299185426,4567620884,4833975573,5102460183,5370846492,5102460190,4833959203,4565540132,4297104678,3760217384,3491781929,3223346474,4297088403,4565523861,4834041238,5102411164,4833992094,4565540257,4297104803,4028652965,3760217510,2954911145,2418040234,4028653074,4297088533,4565605910,4565556765,4297121312,3760217636,3491782181,3223346726,4297088662,4565573271,4299202206,4030766752,3760217762,3223346852,2954911397,4565557015,4297088927},{57,37,30}},
['Skeletal Sabertooth Egg']={64,64,2.8,2.8,2.79026084,{{255,255,255,0},{239,249,247,0},{247,239,205,0},{254,244,48,0},{231,212,179,0},{213,195,172,0},{244,208,60,1},{228,191,105,0},{217,181,134,0},{204,176,132,0},{213,173,96,0},{189,172,143,0},{191,165,124,0},{191,164,113,0},{194,159,107,0},{186,159,112,0},{190,152,96,0},{181,155,114,0},{181,153,105,0},{179,147,102,0},{173,149,113,0},{173,146,98,0},{170,141,98,0},{168,137,94,0},{161,135,94,0},{169,128,86,0},{155,127,87,0},{146,122,85,0},{135,106,71,0},{116,82,51,0},{91,69,49,0},{76,53,35,0},{61,39,26,0},{55,30,18,0},{48,29,20,0},{43,26,17,0},{52,18,10,0},{23,9,4,0},{0,0,0,0}},{138514808861,121334956062,120798068768,104155070497,120798068892,139588550813,124556165278,123750858911,125093036192,106034118817,121603375388,143615082781,126435213598,125361471775,123750859040,107644731681,103618199842,143883518361,161868693914,162405564827,162674000284,180390740381,163479306654,162674000287,157036855712,139588567457,121603375523,104423506340,197033738777,197302174234,214750478875,215287366172,216092656158,214213607967,191396594208,192470336033,194886255138,177437950499,162942435876,162137129509,137977938578,206697415318,224414155415,227903816344,231661912729,249110217370,249378652827,248573346460,265216344733,247499604638,243741508255,242936201888,245352137377,228172251811,213945172644,213676737189,189249110694,172874547881,155694678698,155157807787,190054417169,191128158994,208576463635,224682590996,241594024725,242667766550,260116071191,277027504920,279980294937,282396214042,279980294939,293133632284,294207390493,295549551391,297965470496,295817986849,277027504930,278906569507,261726683941,263068861222,248036475687,241594024744,225487897385,230051300138,209381770027,207502721836,189517546285,189517546383,208308028304,228440687505,246425863058,262800425875,280785601428,281859343253,299576083350,311655695255,312729420697,327493387162,328835548060,332056773533,332593660830,332325208992,333130515361,331519902626,332056789923,314340033445,316219081638,317829694375,295549551528,297160164265,281859359658,263874167724,244278379437,224682591150,207502721967,190054417328,207502722062,242936202255,261995119632,279711859729,297160164370,297697035283,316487517204,331519902741,328835548182,346015417367,347089159192,346015433753,364537463835,366953382940,366684947485,366953399326,366684947488,367221818401,366684947490,365879641123,349236659236,348968207398,351654659111,333398967336,316219081770,298502341675,299307648044,277295940653,260116071470,245352121391,226561639472,208576463921,241862460557,260116071566,279174988943,295817987216,296086422673,315413775506,332593644691,328835548308,345746982037,346015417494,366953383063,366684947608,367221818521,384938558618,383864833179,384938558621,383059510430,380375155871,384938558624,385475429537,383059510434,365611238563,365881738406,351920997544,333667386537,332325209258,316487517355,294475809964,294207374509,263337297070,246157427887,229245994160,212602995889,192203998386,276222199053,295817987342,312997856527,315413775632,333667386641,351115691282,368295560467,364269028628,362926851349,381448897814,384133252375,383864816920,401581557017,402118427930,401044686107,402118427932,397555025181,396212847902,398628767007,402386863392,403192169761,402386863394,385207026979,362926851367,344673240360,346015417641,332593644842,315413775659,311387243820,296354858285,281322472750,263876265263,228440687920,210992383281,292596761996,311387243917,330177725838,345746982287,346820724112,368027125137,386012300690,386280736147,381180462484,397286589845,398360331670,401313121687,418761442712,419298297242,418761426331,415808636316,413392717213,414734894494,418492990879,419566732704,403997476257,402923734434,401581557155,401044686244,385206994341,380106720678,379032978855,364269028776,350578820521,348431336874,332056774059,315413775788,312729421229,278369682862,247499605424,212066125233,194617820594,155963114931,121334941108,344941676044,364537464333,365879641614,380375156239,380106720784,397286589969,397555025426,419835168275,416613942804,414466459157,415808636438,435941295639,436478166552,435941295641,436478166554,435135989275,431646344732,435404424734,435135989279,415808636448,415540200993,414466475554,398360331812,399970944549,397286589990,381448898087,384401688104,364000593449,346015417898,330446161451,332325209644,315413775917,296086423086,260921378351,245620557360,229514430001,195423127090,161331824179,122677118516,190054418050,344136369802,362926851723,382254204556,398628767373,400239380110,401044686479,415808636560,414466459281,432720070290,436478183059,431646328469,450705245846,454463358615,454194906777,454463342234,449094633115,448826197660,449094633117,453121164958,451778987679,432988505760,435135989409,436478166690,436746602147,419566732964,419835168421,398897202854,400776251047,380375172776,365342770858,347626030763,329909290668,329640855213,297965471406,281054037679,262531991216,229245994673,213676738226,177706387123,142541342388,104423507637,209381771010,224682592003,363732158218,383598479115,381985769228,399970944781,417419249422,418492991247,435404424976,434599118609,434330683154,453926471443,453658035988,449094633237,450168375062,471374776087,472448517912,473790695193,471374776090,466006083355,467616679709,470569469726,468690421535,450436810528,449094633249,448826197794,449094633251,434330699556,434599118630,414734894887,415540201256,399165638441,381448898346,381985769259,364805900076,346820724525,332325209902,316219082543,299039213360,281322473265,265484781362,229245994803,193007208244,161063388981,121334941494,209113335682,227366946691,241862461316,362121545610,400776251276,419300394893,418492991374,435135989647,434599118736,451510552465,452584294290,451778987923,467616679828,468690438037,466274502551,484528113560,488017774489,483185969050,485064984477,483454371742,483185952671,466006067105,466274502562,467348260771,450168391589,450705246119,433525393320,416345507754,415808636843,398628767660,381180463021,366684948398,351115691951,332593645488,310313502641,293133633458,277027506099,244009945012,212066125749,192201902006,155157809079,104423507900,207234287618,229245995011,262531991556,276222199813,362121545737,380106721290,401849993227,402655299596,436480264206,436746602511,454463342608,453926471697,468690421778,468958857235,467348244500,484796581909,486138726424,501976418329,500634241050,501707999259,504929208349,501707999262,502244853792,503050160161,485065000994,484528113700,485064984613,467348277286,450705262633,432988522539,415540201517,401581557806,383059511343,379032979504,361853110321,345746982962,314071599155,296623294516,278369683509,244546816054,226561640503,209113335864,155694680123,140393859132,226561640579,265216346244,279443425413,366148077704,368832432265,384938559626,401581557899,419298297996,435941296269,453658036367,455000213648,472716953745,471911647378,488823097491,485601855637,503318595734,504123902103,504660773016,504392337561,501976418458,520230029467,520498464924,522645948573,518887868574,518619416736,518887868577,504123902115,503050160292,502244886693,484528113832,485870291113,469495728298,467885131947,451778988205,431914764462,430572587183,413392718000,397555026097,382791076018,364805900467,347626031284,330446162101,313803163830,297965471927,260921379000,241057155257,224414156986,208576465083,191933466812,207502739712,206697416962,243745704195,264950008068,299307649285,313803163910,348968208647,369100867848,386817607945,404802783498,418761427211,414466459916,436480264461,453658036494,453121165583,470840002832,489628387601,490433710354,508152531220,506539821333,504660773142,524795529495,525332400408,522916481305,518619416858,537678350619,539827915037,534993996062,536604592416,535799302433,537678334243,522377513252,520230029605,519424756006,503050160425,504123902250,501707983147,485064984876,483188033837,464932342062,450168375600,451246311729,433527474482,416345508147,398628768052,381985769781,366953384246,349236644151,330983033144,310313503033,277027506490,262263556411,208576465281,208308029826,299576084869,316487518598,351115692423,368832432520,383864818057,401044687242,417150814603,433256941964,453926488462,488286210449,489091516818,507345127827,505197644181,518619416982,537409898906,538215221659,537946769822,540094253471,539557382560,537141463457,536067738018,539020511652,539825818021,522379610534,521035336103,518619417000,519963691433,505197644202,504392337835,500367903148,484259678638,469495728559,452315859376,432988506547,417956121012,402386864565,384133253558,364000594359,348162902456,315682212281,295549553082,263070960059,209381771777,211260819970,262800427524,299039214085,315413776902,345749080583,362926852616,381448899081,400239381002,417956121099,431646329356,435672861197,453658036750,453121165839,470301035024,486944033297,486675597842,506271386131,506539821588,500367903253,518887852566,523451255319,525598738968,523451255321,534725560858,540631124508,541973301789,542510189086,541167995424,540094253601,538215205410,536604609059,538483640869,522377513511,521035336232,504660773418,502244854315,485870307885,468690422319,451510553136,432720071218,434599119411,418761427508,401044687413,383327947318,368832432695,351386225208,311389342265,298233907770,206697417277,207234288190,207502723647,209113336449,209918642818,244546816643,261189814916,296891730565,311387245190,366416513672,383864818313,399165639306,417150814859,432720071308,434332781197,453121165966,452584295055,468958857872,487212485265,504660773523,503050160788,519156288150,522914384535,523719690904,516474030745,533651802778,536336157339,540362689180,542510172829,540362689182,540899576479,540631124641,540094253730,539291044515,536604592804,535799286437,518889949862,521303771815,521840642728,521572207273,503318596266,500365806251,501707983532,485073390253,467348245167,450170473136,450705246897,435138087602,435404425907,417150814900,399434074805,385743866550,370443045559,299041311418,259042331323,241057155772,207234288317,209381771966,207502723841,209650207490,246425864963,262531992324,295281117957,313266293510,350578821895,367758691080,383059512073,397555026698,418492992267,437015038732,451510569742,468690422544,485872388881,486675598098,504929209107,500372097812,500636338965,520230030102,520498465559,518619417368,536604592922,538487835419,539020512028,542241737501,539288947486,534188722975,540094253860,537678334757,519424723751,520230030120,521840642857,501439564586,502249048876,467887213359,451512650545,433793813299,415003331380,396749720373,379571948342,368563997495,348699773752,312729422649,260116073275,242667768636,210992384829,211529255742,210723949442,247499606915,263874169732,296891730821,312729422726,349236644743,368027126664,385206995849,400239381386,418761427851,439162522508,437820345229,452584295310,450168376207,467616680848,486138727314,501976419219,520498465686,520234224535,521840642968,520500562841,538485738394,537409899420,541168012189,534188690335,533385481121,534188673955,539288947620,540362689445,521572207526,519156288423,518887852968,520230030249,501707983786,502249049003,451242118064,433793813426,432183200691,413929589684,395946511285,369100868535,346017516472,314876906425,298502343610,262531992507,244546816956,211531353021,209381772290,247768042499,264950008836,298233908229,313803164678,350847257607,368832433160,385475431433,399165639690,417150815243,437015038988,438088780813,455537085454,454463343631,468421987344,484528114705,485870291986,501707983891,501707983893,521037433878,521035336728,537678335004,540631125021,542510173214,540094254111,534190771232,533387578403,534188674085,523182820390,522914384935,520230030376,521303772201,503052258346,469764164655,452852730928,450973682737,431109475378,413128477748,385743866934,368832433207,315422166073,297160166458,263876267067,245888994364,243473075331,299844521093,317024390278,353263176839,370443046024,383864818825,397555027082,416345509003,431914765452,437551910029,456342408334,472448519312,488286211217,487480904850,503050161299,501978516629,520498465944,520230030489,538752076954,538215206043,538483641500,534727642269,538483641502,541167996063,534190771361,533385464994,533385464997,517008805030,523182836903,521574304937,502783823020,470301035695,454194908336,448289328305,430306266290,396749720757,386817608886,364000595127,345746984120,296086424762,246694300860,209113337021,300381392133,318903438598,351920999687,368295562504,380375158025,401315220746,419298299147,434599120140,437820345613,455268650254,455000214799,473253825808,490702130449,490437889298,506271386899,500634242324,519424724246,521035336983,520230030616,520498466073,539557383450,538752077083,536067722524,537678335262,540094254367,540364786976,516205595942,517008805159,523719691560,502513290538,503050161451,485870292269,485601856814,468153552175,448293522736,447486119217,402923736373,385743867190,361853111607,349773516088,296891731258,263605734715,243473075516,299576085893,315413777798,346015419783,364000595336,383059512713,414734896523,431648427404,434599120269,454731795854,472450616720,490433695121,507349323155,505734516116,500634242453,518619418006,521303772567,518892047768,519428918681,537680432538,536604593563,534725545372,538752077213,539024706974,537678335391,540362689953,539288948130,534188707235,516203498919,523182820776,522914385321,500902677930,501708000683,484528131501,466542939567,430304153010,431109459379,419029863860,402655301045,380375158198,364269030839,350041951672,298236005818,260921380283,258775993860,295817989637,311387246086,347357597191,366953385480,384133254665,398897204746,414466461195,431646330381,454731779598,455000215055,490970566161,506808258068,506002951701,523182820886,520230030871,536067722779,537409900060,539557383709,538752077343,536067722784,534993980961,536336158242,536873029155,535262432804,517008821798,522109079080,523451256361,505197645354,505466097195,488554647085,488823082542,470571568687,448289328689,432183217714,416077073972,397555027509,381448900150,364805901879,348162903608,260652944955,294744247941,315413778054,350847258247,366416514696,381448900233,402386865802,417419251339,414734896780,431914765965,454463344270,456342392463,471911648912,489091518097,490165259922,507615661716,508150435477,525598740118,523182821015,520230031002,538752110235,536604593823,535799287456,536604642977,519424724645,520498466470,519693160103,518082547368,505197645481,505466080938,505734516395,490433695404,490970566317,471643213486,450973683376,452315860657,435404426930,417419251379,399165656756,381180464822,365342772919,349505081016,315682213561,279443427002,259042332347,259579203332,298770779909,317024390918,351115693831,368027127560,383327948553,402923736842,402655301387,417956122380,435404427021,452047425294,455537086223,471374778128,470301036305,490433695506,489896824595,507345129237,508150435606,524793433879,521840643864,521303772953,520498466586,521572241179,521840643870,522379611935,521303772960,521035337505,520498499362,521840643877,521572208422,501707984679,502244855592,504123903785,484259680042,488823082795,490970566444,473790697261,471911649070,453658038063,436746604336,435404427057,418224557874,402118430515,384133254964,366416514869,350041952054,332862082871,314876907320,281054039865,243473076026,223877287811,259310768004,276490637189,317561261958,334741131143,369100869512,365879644041,380375158666,398360334219,418761428876,436478168973,434599120782,454463344527,453658038160,469227294609,472716955538,490165260179,490433712020,507613564822,508150435735,506271387544,503587032985,521572208538,522377514907,522914385820,521303789469,521035337632,521572208545,521840644002,521572208547,505197645732,505734516645,503050162086,500365807527,487212470184,486138728361,488286212010,473790713771,456610844589,437283475375,419566751664,401044688818,384938561459,368027127732,349236645813,330446163894,316219084727,282396217272,245888995257,224418353155,258505461764,281590910981,317292826630,335009566727,352457871368,367221821449,380106723338,398628769803,420105703436,437283475469,436478169102,452584296463,451242119184,470301036561,472180084754,490433695763,490165260308,490435809301,507613564951,508150435864,506539823129,505734516762,505197645851,505734516764,522914385949,505466081310,505734516767,505466097696,504123904034,504660774947,505466081316,504123904037,484528115750,485870293031,486675599400,467348246569,472180084778,456879263787,456610844716,439430959150,419566735407,397286592560,399165640753,384401690674,367758692403,349236645940,313803165749,297160167478,281322475575,248036479032,209113337913,259325448324,282664652933,318098133126,335278002311,353263177864,368027127945,381717336202,399970947211,421179445389,437822443662,437283475599,454731780240,455537086609,473255923858,472995877011,473253826708,490435793047,507613565080,508150435993,504660775066,500634243227,504123904156,505734516893,507613565086,508150435999,506808258720,506002952353,506539823266,488823083171,483185971364,466012360871,467348246696,466274504873,452047425706,456073957547,439430975660,420103606446,396212850863,380106723504,381448900785,367221821618,347626033331,312460988596,296086425781,279711862966,242936205495,226830078136,194349387961,157573730490,282396217605,301723570438,334204260615,349505081608,365342773513,382791094538,402923737356,437820346639,455268667664,473010557204,473253826837,490433696022,490433696024,489091518745,483192230170,483454374171,504392339740,502783824157,489093615902,490702131487,484259680544,483185938721,488017793314,483198521636,466010280229,449899942184,450168377641,432720073002,437283475755,422251090220,421445783853,401581560110,380375159087,365074338096,367490257201,349773517106,330446164275,296086425908,278369685813,242938302774,225758433591,192470339896,160526520633,123213992250,225223659907,276490637701,298770780550,328835551623,348431339912,366953386377,383596401034,397555028364,415808639373,420640477582,438088798607,455268651409,456080249234,472987488661,490165277078,490970567064,487480906137,484796551579,487212470684,489898922399,485064987040,483454374305,486944035234,487480906147,449094635944,449899942313,434330685866,437551911339,420640477612,420908913069,402923737518,384938561967,366416515504,364000596401,348699775410,313266295219,295817990580,261189816757,191396598200,159452778937,107109962170,71678579131,276759073285,294207377926,331251470855,350041952776,368027128329,380643611146,397286593036,413392720397,418761429518,438357217807,438088782352,456073957905,490165260822,490433712663,483454374425,486138745371,504123904541,489628389918,485870293536,483185938977,488017793570,450168377896,450705248809,435672863274,432990605867,414734897708,420372042285,404534350382,385475433007,363195306544,351115694642,316487520819,295281119796,261726687797,244009947702,226830078519,192201904696,158110601785,279174992517,299039216262,333398954631,350847259272,368295563913,378772935306,380643594891,398897205900,415540204173,418492994190,437283476111,436746605200,455268651665,473255924373,490437890710,490972664471,489628390040,482380632729,486946132635,485067084444,505466081949,490987344542,490165260959,486407164576,484528116385,488288309922,488823083683,468694618789,467348263590,451510555304,452586394281,437015040682,415540204204,420640477869,405071221422,386280739503,364000596656,362926854833,351654662834,317829698227,294475813556,262531994293,246157431478,228440691383,193544082104,159184343737,108991107770,224416256771,276490638085,299576087302,333667390215,351923098376,365074338569,379582436107,400776254220,417150833421,432988508943,431914767120,453121168145,489091519256,483185939225,485064987418,506002952989,490970567455,489091519264,484259681057,489093616419,467889328934,452317958952,437820347178,434599121707,416882381612,420908913453,403735335726,386549175087,365342774064,363195290417,318100230963,295281120052,261191914293,246962737974,229782868791,193812517688,160260182841,71942820667,281590911877,300383490950,335009567623,361595163529,397823464332,417956123533,418492994446,433525396367,452047426449,455000216466,473255924627,472989586325,490433696663,489628390296,485064987545,486138729370,488017777563,486138729372,506275582877,490442085279,490970567584,488554648481,488017777570,453658039209,438361412522,437283476395,419566736300,421179446189,386817610671,366148080560,368295564209,352994743218,297428603828,244014142390,226830078903,192201905080,70065869755,223877288963,282396218373,335546438663,351115695112,401849996300,420103607309,419566736398,435672880143,451242120209,454731781138,490167374870,490972664856,487480906777,484528116762,487480906779,485874488348,490437891104,490165261345,488554648610,489362052131,467887215653,449899942952,452047426601,437820347435,420103607340,386551272495,368563999792,369369306161,352726307890,318639199283,297965474868,260921381941,227366949943,193007211576,160528618553,108452140090,259579204740,282666751109,300918264966,335278003335,350310388872,396753917068,421982655629,420908913806,437283476623,436746605712,453121168529,455000216722,472985392275,488554648729,483454375066,486944035995,490433713313,483454375076,468430378150,468698813607,450172572840,453123265705,438088783019,420908930220,369908290736,352191534258,299039216820,260122367157,226563740855,192201905336,258775995652,300112958726,330983036167,345210115336,379569853706,419029865741,421177349390,438088799503,455268652305,456078152978,472448521491,473260119317,490440021270,489359955225,484259681562,486138729755,506007147805,490433697057,490970567970,489896826147,484259681572,467616683301,438896203050,421714236716,404534351150,387356579119,299307652404,245888996662,193007211832,160794957113,107644736826,277564380549,294475814278,328835552647,346283857288,378770838922,415003334029,420640478606,437820364175,456610829713,472991683987,490165261721,486944036250,485064988059,486138729884,489896826272,489632601505,490165261731,485064988068,467352442277,453926475177,421714220460,422251091373,404265915822,370174612912,370711483825,352996840882,319171876275,299576087988,246425867702,227366950327,193812518328,159184344505,106034124218,277027509765,295817991686,331519907335,350310389256,397018158604,414470657549,419835172366,438357218831,438088783376,456073958929,490435794457,488554649114,484528117275,485870294556,490167359007,489630488096,490433697315,486946133540,451510556200,453121168937,438894089770,438625654315,421445801516,403731142190,386551273007,369371403824,369908274737,318635005491,299844523572,246962738742,229782869559,194617824824,155965216313,276222203525,299039217286,333667391111,351115695752,362389984905,380643595915,397555029644,432722171534,438088783503,455268652688,455000217233,473255925394,489359955610,485064988315,503050163868,505734518429,490165261987,452315862696,454194910889,438357235370,421177349804,421445785261,352726308530,335814874803,300112959156,277295945397,245083690678,227366950583,192201905848,223877289731,258773899012,277027510021,316755957510,333935826695,351384131336,368564000521,396751820555,416613947148,437015041807,455000217360,452047427345,490165294869,507349341976,507615663898,506271389467,502781728540,505466083101,508150437662,507615663903,506810390304,490433697571,488286213924,484528117541,485601859366,468421990183,467885119272,471645312809,455537088298,455000217387,439162525484,438625654573,420908914478,403729045295,386549176112,387086047025,370174613298,353531615027,317561263924,295281121077,279711864630,245352126263,226293208888,188980680505,207234291586,224414160771,261458253700,281054041989,317026490246,335278004103,352189437832,369100871561,379569854346,419029866380,435672864653,435404429198,451510556559,452852733840,469227296657,472180086674,490165311379,507347228567,508150437787,506271389596,519961597853,506808260510,507613566883,506271389604,501439551397,485064988582,485601859495,484259682216,470569473962,448289331115,454194911148,455537088429,438088783790,420908914607,403729045424,404534351793,387354482610,370174613427,351921002420,312460990389,295549556662,278101252023,245083690936,207234291641,189517551546,207502743552,212066129922,230588176387,265216350212,282396219397,335009568775,369369323528,384670128138,397823465483,418492995596,436478187533,453121169423,451778992144,468421990417,471911651346,490165278739,490433697813,507615664150,524525000730,524795533339,525332404252,523182823453,523451258910,525330307103,524795582496,506539825188,502244890661,485870295080,485333424169,481845860394,464663910443,454463346733,456073959470,438088783919,421177350192,421445785649,403729045554,386549176371,368832436276,346820728885,331251472438,313266296887,281054042168,244278384697,225487902778,190322858043,155694684220,243473078403,264142608516,297428605061,316487522438,351652567175,369369307272,385475434633,397555030154,398628771979,419837270156,437551913101,454465443982,454733879439,471374796944,490165262482,490433697939,507345131668,507613567125,524793452695,524525000857,524256565402,525330307229,524793452702,524525000868,520766904485,518623615142,502781728935,503050164392,499828938921,481843779755,470569474221,473790699694,456610830511,439430961328,438088784049,420640479410,403729045683,386012305588,364805904565,349505083574,332056778935,312460990648,277295945913,246157433018,229245999291,190322858172,368564001032,380106725641,399970949386,418224560395,437015042317,472716957968,490702133521,488017778962,503587035411,506539825428,508150438165,524793436438,524256565527,523988130072,524793452825,541436434715,540899563804,541167999261,541973322014,541168032032,541704870179,542510176548,522914388261,520230033703,520498469160,500904778025,499023649066,481845860652,482649069869,471643216174,471911651631,455000217904,455268653361,437820348722,421177350451,402923739444,398360336693,384133257526,366684952887,349505083704,314071603513,278906558778,259042335035,223608854844,346552293768,364537469321,385206999434,384133257611,397555030412,415540205965,430841026958,433525381519,456342395280,470032603537,466006071698,487480908179,488286230932,505197648278,504123906455,503318600088,522645952921,523451259290,520766904731,517814131100,523451259294,523988130207,523719727520,524525001123,524256565668,522645952933,503318600103,504392341928,481843780010,465469200813,468153555374,450705250735,434062252464,437551913393,421177350578,403997481395,385206999476,381180467637,365342775734,349505083831,316487522744,299039218105,263874173370,228172257723,209113340348,173142989245,310581942792,331788343817,351115696650,368295565835,383059515916,401313126925,414734916110,435941300752,450168379921,453926476306,470837926419,469764168213,485064989206,485870295575,486138731032,503855471129,500365826586,501976439324,505734519326,507613567519,507345132064,507076696609,506808261154,507345132067,506271390244,500634245669,503050164774,485870295591,488017779240,482649070121,464663927338,448289331757,453389605422,436478171695,418761431600,417150818865,402655304242,386012305971,364000598580,347626035765,332056779318,316487522871,295012686392,312192555658,351384132235,367758695052,383059516045,384133257870,397555030671,416345512592,419566738065,436478171794,453658073747,470837910166,470301055639,484528118425,483185941146,484796553883,485870295708,486944037533,488017779358,488554683039,489359956642,490433698467,488554650276,486675602085,486138731174,468421991079,468958861992,465469201065,447484058282,431109462701,419029867182,419298302639,402118433456,384938564273,383864822450,366684953267,347089164980,313803168437,297965476534,280248736439,293402073866,311387249419,333130521356,366953388813,366684953358,383864822543,402386885392,419566754578,436746607380,436478171925,453926509334,468690426649,467348249370,467616684827,467348249372,470032603933,467885120286,464932330271,467348265760,471643216674,471911652131,468421991204,470301039397,468690426662,451242122023,450973686568,448289332009,430304172842,413124287276,419029867309,403460610862,402655304495,385475435312,368027147057,331519908659,311655684916,298502347573,279980301110,260652948279,259042335626,295281122187,316755958668,333935827853,351115697038,368564018063,385475435409,402386869138,402118433683,420372061076,437015042966,436478188439,453658041241,452315863962,449094638491,451242122140,454194912157,448826203038,451510557599,453658090400,452584299428,453121170341,453926476710,434330688423,433793817512,431109462953,413124303786,396749724588,402923740077,387891354542,369369308079,368564001712,350847261617,333935827890,311655685043,296891734964,265216351157,246962740150,260652948491,282127784972,299307654157,316487523342,336351747087,334204263440,346820729873,366953389074,383864822803,386280741908,405071223829,404534352918,421445786647,420372044824,419835173913,420103609370,437015043099,437551930396,433256946718,436478172191,435941334048,437015059491,437820349477,421982657574,418761432103,416613948456,396749757481,379569855532,386817612845,368295566382,350041955375,331519908912,332325215281,314340039730,277027511347,262800432180,245888998453,209113340982,209113341068,224682597517,282933091471,297965477008,312997862545,330177731730,329909296275,351115697300,351921003669,370174614678,387354483863,386817612952,386280742041,404534353050,405071240347,402923740317,398897208478,419566754975,419298303137,418492996770,402923740323,405071223972,404802788517,402386869414,400239385767,382254210216,379569872041,362389986475,368295566508,353531616429,334204263598,333398957231,316219088048,298502347953,278638124210,261458255027,227903823028,207234292917,241862466832,261458255121,279174995218,294475816211,311387249940,315145346325,333667392790,349236649239,347089165592,364269034777,366684953882,368295566619,385207016732,382791081246,383864823071,384401710368,384133258530,382522645795,386549194020,381180468518,366953389351,366684953896,367490260265,351384149290,335278005548,336351747373,318098136366,299307654447,280517172528,260116077873,242936208690,227635387699,192201907508,172874554677,209381776785,245620563346,260116077971,263337303444,281859349909,299844525462,317292830103,316219088280,331251473817,332593651098,350041955739,351384133020,352189455773,351115697567,366684970400,367221824930,365611212195,350041955748,351115697573,348431343014,348699778471,349236649384,333667392937,335814876586,319171894699,300649831853,282396220846,260116077999,259847642544,242936208817,229246000562,195960004019,174753602996,173142990353,192201907730,209381776915,230856613396,249110224405,267095399958,284812140055,300649831960,300112961049,300381396506,317561265691,319171878428,335814893085,336083312159,334741134880,333935828513,333667393058,332325215779,331788344868,329640861221,329909313062,312729443880,296891735594,297428606507,279443430956,277027511853,259847642670,242936208943,228440694320,212066131505,193544085042,157573733939,214482050709,232467226262,249915530903,267095400088,284277382809,301455138459,301186719388,318366588574,318635007648,319171878561,317561265826,316219088547,315682217636,315413798565,297697074855,278638124714,278101253803,261189820076,262800432813,246694305454,228440694447,210723954352,190322859697,230588178198,248841789207,266826964760,301186703131,301455154972,318635024158,318366572320,317829717793,316487524131,314608492324,313803169574,297428623143,299039219497,281322495786,264679481132,263068868397,243741515566,226293210927,265216352152,283201527705,282933092250,299844525979,300112961436,300381396893,317292847006,316755959712,295012687785,277832818602,280248737707,260652949420},{2153791517,1885388830,1616920609,1883259036,1612726562,2149597593,2418065818,2686468509,2418065822,2149613985,1881162147,1612726692,2954920473,3223405083,2954936864,2686468643,2418049572,2149597842,3223339670,3491807895,3760243354,4028646045,3760276126,3491775139,3223356068,2954904230,2686468777,2418049706,2954920721,3223339795,3491775252,3760227093,4028646167,4297130776,4565599004,4297114402,4028662565,3760227111,3491791657,3223356203,2954904365,2954904463,3223339920,3491775377,3760210834,4028646291,4297098132,4565517206,4833985431,5102551962,4833985445,4565533608,4297098154,4028646316,3760210861,3491775406,3223339951,2954904496,3223340046,3760210959,4028646416,4297081873,4565533714,4833952788,5102404629,5370872855,5639390235,5370872868,5102404648,4833952810,4565533739,4297081901,4030743598,3762308143,3495969840,3229631537,3760211085,4028646542,4297081999,4565533840,4833952914,5102404755,5370840213,5639292055,5907825818,5639308451,5370840231,5102404777,4836050091,4565533868,2961196210,4297082125,4565517582,4833969423,5102388497,5370823954,5639292179,5907727638,6176277785,5907727651,5639275814,5370840360,5102388522,4836050220,4565517613,4299179310,4032841007,4565517708,4833953165,5102388622,5370840463,5639259537,5907727762,6176163221,6444696984,6176179617,5907727781,5639259560,5370840489,5104485803,4836050349,3762308528,2420131251,1883260340,5370824204,5639276045,5907711503,6176146961,6444615187,6713132567,6444615200,6176163364,5907711527,5639259689,5370824234,5104485932,4567615022,3493873201,2954905218,5370824330,5639259787,5909792396,6176163469,6444582544,6713050770,6981584534,6713050784,6444582564,6176147110,5907711656,5639259818,5370824363,5102388909,4297082543,4028647088,3223340722,2686469811,2149598900,1612727989,3227535106,3498067715,5641357066,5909792523,6176130829,6444582670,6713034512,6981486355,7250003735,6981486368,6713034532,6444582695,6176130857,5907711786,5639259948,5370824493,5102389038,4833953583,4565518128,4297082673,4028647218,3491776307,2954905396,2418034485,1881163574,3760211844,6178228108,6444582797,6713018255,6981470097,7249921940,7518439320,7249921953,6981470117,6713018280,6444582826,6176130988,5907695533,5639260078,5370824623,5102389168,4833953713,4565518258,4297082803,3760211892,3223340981,2954905526,2418034615,1612728252,4047521796,4299180037,5641357321,5909792778,6178228235,6444566541,6713018382,6981453840,7249905682,7518357525,7786874905,7518357538,7249905702,6981453865,6713018411,6444566573,6176131118,5907712047,5639260209,5370824754,4833953843,4565518388,4297082933,3760212022,3491776567,3223341112,2418034747,2149599292,5668620424,6446663820,6713018509,6981453967,7249889425,7518341267,7786809494,8055294107,7786809507,7518324904,7249905834,6981437613,6713018542,6444566704,6176131249,5907695794,5639260339,5370824884,5102389429,4833953974,4565518519,4028647608,3760212153,3491776698,3223341243,2954905788,3223374080,3774892291,4590684421,4865411334,5395990791,5932861705,6201297162,6467635467,6742362381,7006619918,7275038992,7518341393,7786776852,8055228695,8346814747,8055245092,7786776873,7518325036,7249889582,7004522800,6736070962,6444566835,6176131380,5907695925,5639260470,5370825015,5102389560,4857022777,4297083194,4051716411,3229649281,6731876748,7539296657,7807748499,8076200342,8342489498,8342505892,8074103206,7805651370,7537199533,7270844847,6731876787,6463441332,6197103029,5928667574,5660232119,5391796664,4584393146,3223374397,3770698428,3225455293,3225439106,3227536317,4060106244,6452956812,8059375258,8323616420,8055230117,7786778281,7518326444,7251971758,6444568243,6176132788,4297084602,6182424331,7254069009,7518326546,7786778388,8055213847,8055361307,7786778407,7518342954,7249874733,6981439279,6713020208,6444568370,6176132915,5907697460,5639262005,5370826550,5102391095,4833955640,4297084729,3760213818,3510652803,4332736389,5138042759,5674913673,5943349130,6719295374,6983552911,7256166290,7520440211,7786794902,8055312283,7786794916,7518343080,7249891243,6981455789,6713003951,6444584880,6176133042,5907697587,5639262132,5370826677,5102391222,4833955767,4297084856,3760213945,5402284040,7549767702,7786827799,8055181341,7786860574,7518343206,7249891369,6981472299,6713004078,6444568623,6176149552,5907697714,5639262259,5370826804,4833955893,4565520438,4297084983,3760214072,3223343161,6471831693,6740267151,6983553168,7277154451,7518310549,7545573527,7786909848,7518359715,7249907879,6981456042,6713020588,6444568750,6176133295,5907714224,5639262386,5370826931,4833956020,4565520565,4297085110,3760214199,3491778744,2954907833,2418036922,4588589318,5930766603,6199202060,7272943893,7541428504,7786762524,7541477662,7272976677,7004524840,6736089386,6467653932,6199202094,5930766639,5662347568,5393895730,5102391603,4588589364,4297085237,3783282998,3514847543,2977976632,2441105721,1881166138,6463443342,6731878800,7000330641,7537185180,7809814941,4852830643,4047524277,1629508026,1086345659,6719297166,6983554704,7256168082,7790941852,5102393011,4297086645,3495974659,4034942724,4840249094,6182426379,6452958988,7522506517,7788893976,7788910366,7518361379,7249909543,6981457706,6713022252,6444570414,6176134959,5907715888,5639264050,5370828595,4833957684,4565522229,4297086774,3760215863,3491780408,2954909497,3225442178,6719297421,6983554959,7254071185,7520425875,7788844951,8059377565,7786780579,7518345126,7249893289,6981474219,6713005998,6444570543,6176151472,5907699634,5639264179,5370828724,4833957813,4565522358,4297086903,3760215992,3223345081,2954909626,3223361536,5643458568,7788845078,7786764312,8057313306,8057362462,7786797092,7518345256,7249893419,6981457965,6713006127,6444587056,6176135218,5907699763,5639264308,5370828853,5102393398,4833957943,4297087032,3760216121,3491780666,2954909755,2418038844,3760216195,4565522565,5370828935,5909797001,6178232458,6983555214,7251974288,7518328978,7788861588,8057313431,8055216292,7786780839,7518345386,7249893549,6981441711,6713022640,6444570802,6176135347,5907699892,5639264437,5370828982,5102393527,4833958072,4297087161,3760216250,3491780795,2954909884,6444570891,7518329105,7786748179,8055183638,8057280794,8323766555,8055232805,7786780969,7518329132,7249893678,6981458224,6713006386,6444570931,6176151860,5907700022,5639264567,5370829112,4833958201,4297087290,4028651835,3491780924,5370829192,5639264649,5907716490,6176135564,6444571021,6713022862,6981441936,7249893777,7518345619,7786781078,8055183769,8055363995,7786781095,7518345642,7249893805,6981441967,6713022896,6444571058,6176135603,5907716532,5639264694,5370829239,4833958328,4565522873,4028651962,3491781051,3223345596,2686474685,4833958408,5102393865,5370829322,5639264779,5907700236,6176135693,6444587534,6713006608,6981458449,7249910291,7518345750,7786961433,7518345767,7249910314,6981458477,6713006639,6444587568,6176135730,5907700275,5639264820,5370829365,5102393910,4833958455,4565523000,4833958538,5370829451,5639264908,5907716749,6176135823,6444587664,6713006738,6981474963,7249910422,7518526105,7249910439,6981474986,6713006765,6444587694,6176135856,5907716785,5639264947,5370829492,4833958581,4565523126,4297087671,4565523210,4833958667,5102394124,5639281421,5907700495,6176152336,6444587794,6713023252,6981475094,7250090777,6981475111,6713023274,6444587820,6176152366,5907700528,5639281457,5102394163,4833958708,4565523253,4297087798,4028652343,4028652426,4565523339,4833958796,5102394253,5370829710,5639281551,5907700625,6176152466,6444587924,6713039766,6981655449,6713039783,6444587946,6176152492,5907700654,5639281583,5370829745,5102394290,4833958835,4565523380,4028652469,3760217014,4028652555,4297088012,4565523469,4833958926,5102410767,5370829841,5639265298,5907717139,6176152597,6444620823,6713170971,6444604454,6176169001,5907717164,5639265326,5370829871,5102410800,4833958962,4297088051,4028652596,3760217141,3223346230,3223346316,3491781773,4297088143,4565523600,4833959057,5102410898,5370846356,5639265430,5907733655,6176201882,6444620959,6176201891,5907733672,5639281835,5370829997,5102410926,4833959088,4565523633,4297088178,4028652723,3491781812,3223346357,3760217360,4028652817,4297088274,4565523731,4833975572,5102394646,5370846487,5639298329,5907864860,5639298343,5370846506,5102411052,4833959214,4565523759,4297088304,4028652849,3760217394,3491781939,2954911028,2686475573,3223346577,3760217490,4028669331,4297088405,4565523862,4833975703,5102411161,5370895771,5639314848,5370895780,5102411177,4833975723,4565523885,4297088430,4028669359,3760217521,3491782066,2954911155,2686475700,2686475793,2954911250,3223346707,3491782164,3760217621,4028653078,4297088535,4565556760,4833975835,5102558749,4833975848,4565540394,4297104940,4028653102,3760217647,3491782192,3223346737,2954911282,2418040371,3223346837,3493879446,3762314903,4032847512,4301299353,4569751195,4836187806,4567654055,4301299370,4030766764,3762314926,3493879471,3223346864,2954911409,4833992606,4565524393,4028653484},{146,115,75}},
['Octophant Egg']={61,64,2.56666667,2.8,2.56666667,{{230,252,72,1},{215,221,134,1},{200,193,136,0},{164,218,63,1},{186,185,144,0},{177,176,134,0},{173,168,143,0},{171,166,117,0},{162,157,130,0},{158,152,111,0},{148,147,116,0},{144,138,102,0},{130,137,84,0},{128,125,113,0},{129,122,82,0},{119,118,87,0},{114,110,81,0},{107,101,74,0},{98,96,70,0},{91,89,67,0},{78,91,51,0},{79,80,57,0},{74,74,53,0},{70,68,50,0},{62,65,45,0},{64,61,44,0},{58,58,43,0},{54,52,39,0},{46,49,34,0},{41,41,31,0},{38,36,28,0},{32,34,28,0},{30,29,25,0},{22,25,18,0},{17,19,13,0},{9,10,6,0},{1,0,1,0},{0,0,1,0},{0,0,0,0}},{124287729691,142541340700,143346647069,143615082526,142541340703,142272905248,125361471521,123750858786,123750858906,125629907099,141199163548,142272905373,142809776286,144151953567,144957259936,128582697121,127508955298,122408681754,124019294491,138246390044,137441067294,142809776415,145762566432,128851132705,125898342690,123750859162,125898342811,144688824732,144151970205,144690921887,145225695648,128045826465,125361488290,106570989988,125363569177,127242617370,127508955675,143883518492,143615083037,143885615646,144688824864,127777391137,128045842978,110062748196,105228812952,127777391259,144688841372,142541341343,144151954080,128314262177,128045826722,128582697635,125898343193,127777391386,126703649563,143883518748,144957260573,144688825118,143883518751,145494131488,128582697761,128314278690,107913167652,125898343322,121066505115,137441067932,138246423453,127777391521,128851133346,128045826979,159721210906,155426243611,171800806428,172069241885,188980675614,172606129183,159989646369,162942436386,162405565475,209650205847,228440704152,248036476058,241325589659,240520283292,240788718749,257700152478,241325606047,245888992417,248573346978,231393477795,226830075044,208308028581,191128159398,244009944339,244815250708,262800426261,280785601814,299844519191,300112954648,317561275673,310045066523,326419662108,327224952095,314608469281,317829694754,318098130211,300381390116,299307648293,281859343654,264679474471,246694298920,247499605289,228977575210,224951026988,224414156077,206697415982,207771157807,208308028720,191128159537,192470336818,258773894538,278369699211,296086422925,294744245646,310850373007,312729421200,314340033937,333398951314,333935822227,351384126868,351920997781,368563996054,368295560599,385207010712,385475429786,402655298971,398360331676,395944428957,400507831711,402655298977,386549171618,386280736163,385743865252,368295560613,368563996070,352189433255,352726304168,335814886825,316755953067,311387243948,312192550317,295817987502,296891729327,280517166512,279711860145,262800426418,262531990963,243204638132,329103984137,347626030602,349505078795,367490254348,383596381709,383059510798,401044686351,399434073616,415808636433,418492990994,419566732819,437283472916,438088779285,455000213014,455268648471,472448583192,471911646749,471643211294,472180082207,471643211296,471374775841,471106340386,471374775843,472448517668,455805519397,456073954854,438088779303,435672860200,417150813737,416613942826,415271765547,399434073644,402118428205,384401688110,384133252655,367221818928,350578837041,333130516019,314340034100,295549552181,363463722632,382254204553,401313121930,419566732939,436209731212,452852729485,453658035854,472716953231,467885115024,482112210577,501171127955,500365805205,518350980758,518887851671,519693158040,537409898137,538215204506,538752075419,539825833628,540631139998,541168010912,541436429986,541704865443,523451254436,521035335333,519424722598,501707982503,501171127976,485333419690,484796548779,468153550508,470032598701,452315858606,452584294063,436746602160,419835168433,402386863794,384135349939,366684948148,348699772597,330446161590,347626030855,365611206408,384133252873,402118428426,419298297611,435404424972,453389600525,454194906894,468958856975,466274502416,482380646161,500902676243,500634240788,499292063509,517814109974,518350980887,517545674520,533651801881,534993979162,535530850075,534725543708,534188672797,535530850078,536604591903,536067737376,537141462818,536604591907,519424739108,519156287270,502513288999,501976418088,501171111721,483454371626,482380629803,464932325164,466006066989,449363068718,450705245999,434330683184,417150814001,400776251186,367492351796,349505079093,332056774454,296623294263,294744246149,330714597254,348699772807,367490254728,384670123913,401581557642,415003330443,430035715980,447752456077,448020891534,464932325263,465200760720,482380629905,482114291602,499294160787,499560515476,516740368278,517545674647,517008803736,533920237465,534725560218,533922351004,534993979294,535262414751,533922334624,533651802017,535262414754,537409898403,521035351972,520498464678,503318595495,501171111848,499292063657,482649065386,483991242667,467885115308,466811373485,449631504302,450436810671,431646328752,413392717745,396212848562,380914124723,349773514677,332593645494,297965471671,279443425208,244009945017,277564377092,296354859013,332593645574,350312482823,366953383944,384401688585,398091896842,412855846923,430576781324,447215585293,448289327118,467616679951,466811373584,482112194577,499828951060,516476160022,533651818521,534725543963,533920253982,533920237601,534725543970,537678333987,521303771172,521572223013,503855466535,503324887080,503050160169,487749339178,488286210091,470032599084,469495728173,451510552622,451242117167,432183199792,413661153329,397288687666,369369303092,352457869365,333667387446,298502342711,282127779896,246157428793,244009945219,279980296324,298770778245,333667387526,369369303176,383327946889,395678075018,413394815115,447752456333,449637795982,467887212687,467616680080,482649065617,482380630162,500634241171,500101564564,498755192981,533920237721,536604592282,536336156827,533920237724,533651818653,533920237727,533651818656,535532947618,536604592291,521572206756,521035335845,520230029478,503318595751,505734514857,488823081130,487480903851,468958873772,452315875502,434330683568,416345508017,380375156915,362926852276,346283854005,330983033014,298772875447,281590909112,246425864377,245352122627,281590909188,299307649285,332862081286,349236644103,364269029640,379838286089,448020891917,467885115664,483185936657,484796549394,501707983123,498218322197,534993979673,537141463322,535530850587,534727641372,533651802397,534188689694,533920237856,533651802401,534725544227,517545675044,520498481445,503050160423,503318595881,487212468522,488286210347,471643212076,470837905709,452584311086,437551909168,419566733617,398628768050,380106721587,362658416948,344941676853,330446162230,281322473784,246694299961,245620558211,280787700100,298770778501,332325210502,349505079687,366416513416,379032979849,396502256010,413661153675,431646329228,448826198413,467616696719,482380630417,483185936786,500097370515,500634241429,516471949718,515935062424,534725544345,536875125146,536604592539,536336173469,533922335135,534725560736,536336173474,516740368804,518350981541,521035336102,502781725095,504929208745,485601855914,481845856683,467616680364,470569470381,453658036654,454194907567,437015038384,419835169201,404268009906,382522640819,363195287988,346552289717,330714597814,299307649463,281054038456,246425864633,226832173498,226024770050,245352122883,299844520453,333130516998,347626031623,363732158984,379569850889,415271766539,433256942092,448020892173,468153551375,468421986832,482112195089,481575324178,501439564307,499027823125,516740368918,517545675287,518887852568,536604592665,534188673563,533114931740,533653899805,534188673566,533920238112,535530850849,536336157218,535262415395,516471933476,518082546213,520230029862,503320693287,503050160680,503318596137,486409259562,464663890476,469764164141,452584294958,454733875759,437551909424,421179443761,385743866419,362931046964,344673241653,330446162486,299576085047,280785603128,247237462585,226832173698,245622655619,281322474116,297160166021,333398952582,348431338119,361853110920,379303512713,413396912779,432183200396,449631505037,451242117774,472985406095,486944033425,485870291602,503587031699,499023628948,517814110870,519961594519,522645949080,540094253721,537678334618,533651819163,534993980062,536604592799,535262415520,533651802785,536604592802,535530850979,517008804516,518350981797,521035336358,503318596264,503050160809,484263873195,467079809708,469227293357,454731778734,438088780464,404534348466,387086043827,345746983605,328835549878,298233907895,281062427320,227635382970,279980296964,296354859781,333935823622,348699773703,361316240136,432451635980,450973682445,451510553358,473253825295,472987486992,490702129937,490433694482,507076692755,503587031828,515398191894,515935062807,518082546456,537141463833,536067722010,534725544731,535530851100,534725544733,536604592926,536875125535,540631141152,541704882978,524256578340,524799724326,504123919143,504392338217,488554646314,464129116972,464663890733,449899940654,454197005103,438357216048,421445782321,402118429490,381448899379,346554387253,329374518070,297699134263,228442786618,228442786690,246962736003,281054038916,297965472645,330446162822,346552290183,361853111176,380106722185,432183200652,450438908813,451242118030,472987487119,488286210961,481308986258,498486758291,508418870164,506002951061,516203498390,515398192023,515935062936,539291044761,536604593050,533114932123,533651819420,535530851230,541436431264,542241737633,541973302178,541167995811,523990223780,524256562085,505197644711,503320693672,505197644713,488823081898,463858584493,446678715310,438627748784,419029863345,397286591410,380643593139,363732159412,241325591555,278101249028,300649827333,327493372934,345746983943,364537465864,380375157769,415003331595,433525378060,450973682702,473253825552,487212469265,500634242067,507613580308,524795530262,520766901271,516740369432,537141464090,534725561371,534188674077,536336157726,536604593183,539288964128,539557383202,540899560483,523990223909,505466080295,504929209385,488556743722,484796550187,463858584620,464665988141,447484021806,454731779119,417150815281,398091897906,381180464179,364537465908,347357596725,330177727542,298233908279,246694300729,229514431546,228977560706,245083688067,279443426436,300112956549,328567114886,344943774855,362389982344,379301416073,414468557963,433256942732,449631505549,451778989198,473253825679,472985390224,488554646673,486407163026,507615661203,507345128596,507613564053,521303772311,517545675928,537678335129,539288964250,538483641500,538752076957,534725545118,533651803295,532846496928,533114932385,533651803298,537678335139,524524997796,505734515879,502781725864,504662871209,486407163051,464670182572,452047424686,455268650159,438088780976,415273864369,398897204402,381717335219,363463724212,344941677749,328567114934,297160166583,246962736313,228977560762,225487899905,228440689922,246962736387,282664652036,295012683013,327493373190,361855208712,379032980745,432183201036,453389602061,455537085710,470837906703,469764164880,486944034065,487749340434,507613564180,504660774165,517277240598,515400289559,518619417880,534993980697,535530851610,537678335259,538752077084,538215206173,534188674334,533920238879,533651803424,535262416161,536338255138,538215206179,524793433380,524256562469,525061868838,506808257831,503050161448,488286211370,487480905003,467079810349,455000214830,455537085743,436746603824,397286591794,379032980787,361853111604,345746984245,327493373238,294744247607,281590910264,246694300985,229245996346,227366948155,229250190722,248036478339,280519265668,294744247685,328567115142,345210113415,379301416329,416613944715,433525378444,453926473101,452584295822,469495729551,470301035920,488554646929,489628388754,506271387027,499023629716,498220420501,515400289686,517814111640,534725545369,533651803546,536606690715,538483658140,538752077214,535530868127,535799287201,536873029027,521303772580,522109078949,520230030758,502781726119,503859662248,504396533161,488021970346,487751437739,469229391277,454731779502,456073956783,434062249392,413394816433,396212850098,381985770931,367758691764,352726306229,333667388854,297965473207,282933087672,247768042937,230051302842,227903819195,226024771073,249110220291,296623296005,331788340742,346015419911,363732160008,380375158281,416347606539,433256943116,453658054157,471643213327,472716955152,490435792401,489898921490,499025726995,498222517780,515666644503,533114932761,533920239130,532578061852,533383368221,540631125534,534725561887,534993980961,536604593698,535532949027,516471967268,501976419879,455537102382,432988507696,399970946610,386549173811,368027127348,344406904373,331788340790,300649827895,283738394168,245083688505,229246012986,227366948481,248036478595,282129878660,292865199749,326421728902,345480646279,363195289224,380106722953,432451636876,453389602445,456073957006,472985407119,503587032725,523182821014,523451256471,524524998296,539020512921,533651803802,535530851995,537946787484,540094254750,534188674719,533651803808,534725545633,536873029282,516740402852,502246952615,487480905387,467079810732,471374778029,455805521582,454731779759,436478168752,419029864113,402118430386,385743867571,366148079284,334204260022,301186698935,284275265208,241331883705,227903819450,230051303099,226830077628,227903819521,228442787586,246962736899,292059893509,362121547528,379032981257,396212850442,415271767819,433525378828,454194908941,455805521678,472719052559,472987488016,489628389137,483991244562,498220420883,498486759189,515666628374,516740370199,517277241112,534993981209,534188691226,538215206684,539288948509,539020513054,536604593951,533114933024,534457110305,536604593954,536338255651,517277241124,516740386597,503324888872,504126000937,488286211882,487212470059,468690423596,472448519981,455537086254,455268650799,438361411376,421716315953,402923736882,385206996787,368832433972,352726306613,335814872886,300918263607,283738394424,228172255034,229784964923,227903819580,225487900544,228172255105,248038576003,279174991748,294475812741,331788341126,348431339399,366416514952,383596384137,399702511498,419298299787,438627749772,455539199885,486944034705,481306890130,499023630228,498218323861,515400290198,516203499415,518621515672,534457110425,533920239514,535530852251,536067723164,537678335901,540362690462,537141464991,534993981344,535530852257,537409900450,517814112164,516740370341,518082547622,502513291175,488017776554,487483002795,471106342828,472180084653,455268650926,455549669295,399434076082,379569852339,367490256820,351921000373,335009566646,301455134647,284006830008,228713320378,229514432444,227366948864,228440690689,228977561602,281054040068,299039215621,334741131270,349775613959,368295563272,387086045193,404802785290,421714219019,472448520207,472719052816,488554647569,484796551186,506539823123,507345129492,501439549461,515400290327,539020513305,534188675098,534993981467,534725546012,536877223965,540631126046,537946771487,539288948768,540631126049,538752077858,533651804195,516471951396,517545676838,501976420391,503857565737,487753535530,472448520236,472716955693,455545475118,421449977905,403460608050,383596384307,368029225012,352457871413,335546437686,299576086583,282666750008,230588174395,228172255292,227903819904,229245997185,229782868098,248304914563,283201523844,298233909381,332593647750,368027127944,386549174409,403460608138,420640477323,438359314572,455541280909,455268651150,472716955791,490433695889,491239002258,507613581459,508418871445,520766902422,515666628760,532846497945,534457110682,534725546139,533920239772,537946771614,532580176031,538752077985,540362690722,538215207075,519961596068,518082547877,517008806054,502513291431,487212470443,472716955820,472991682733,438625652912,404268011698,385743868083,350578823349,332325212342,298233909431,243741511865,229516529851,226832175292,227369046272,229514449153,248040673539,281322475780,298502344965,332325212422,350041952519,368295563528,386280739081,402923737354,420372041995,455537086734,472985391375,473253826832,489896825105,488286212370,507078791443,507613565204,507347226901,524793434390,524256563479,518619418904,532582256921,532846498074,533383385371,537141465374,537946771745,541436449058,524793450788,523451257126,507347226919,504392339752,503320695081,486944035115,472180085036,438357217584,385475432755,366416515380,349505081653,333667389750,300115054903,283201524024,247231172921,228979659066,228446982529,229514432898,279174992260,293135733125,332595745158,351117791623,368563999112,386549174665,403460608394,420640477579,438627750284,455805522318,472448520591,470301036944,486675616145,507345129876,525061869974,525598740887,521840644504,532578095514,539022610845,539288949150,537141465503,536336159136,539288949153,541436432802,541167997347,524271243684,524814406053,524256563622,505466081704,486944035242,486675599787,471106343340,438625653168,420640477617,401044689330,383596384691,367221821876,351384129973,334472696246,282664653240,246694302137,229246013883,229248094722,279711863300,369100870152,386817610249,404265914890,421445784075,455809716749,453121167886,468958859791,469764166160,487480906257,488823083538,507347227155,508418871828,507076694549,520766902806,516203500055,515398193688,533383385626,532578062876,541167997470,539557384735,540094255648,540631126561,541704868386,540905853475,523992322598,506808259111,506271388200,503050162729,487212470826,487749341739,470837908012,438898283056,419298300465,400776254002,385211191859,368563999284,352457871925,335278002742,299307651639,282396217912,246962737721,230319739450,229514433083,227366949436,247231173251,282935186052,299844522629,333667390086,351652565639,367758693000,383864820361,403192173194,420908913291,438361412236,452315861646,470301037199,471911649936,490167358097,490433696402,502781727380,498220421781,515398210198,516203500184,537141465753,541704868506,540899562139,536336159388,538752078493,539557384862,538483643039,539288949408,540362691233,540903756450,506539823783,506808259240,503318598313,486944035498,488554648235,470569472684,472448520877,455807619758,419835171505,402118431410,369637741236,353800049333,333935825590,295283217079,282933088952,246425866937,229514433210,228981756603,226024772284,229516530434,247768044291,297965474565,332862083846,351923098375,365611209480,383596385033,402655302410,420642575115,455268651790,472987489039,473253827344,490167358226,501439550227,498222519060,515398193942,515666645783,533114950425,537678336795,540631126812,539020514077,538483643166,540094272287,539830014753,506002952999,506541921064,503855469353,486138729258,487214568235,469497828140,471643214637,455805522735,420640478001,402655302450,370176709428,352994743093,329640858422,283738395448,246157431609,228979659578,228172256129,246157431683,279174992772,298502345605,332593648518,366684951432,384938562441,403192173450,455543378829,455805522830,472721150864,489896825745,499023631251,501439550357,522914419606,539020514201,537946788762,535262417820,537409901469,539825820574,540901659551,540094256032,524256564134,506539824039,505466082217,485872391082,470840005549,456073958318,454194910127,438357218224,419835171761,401581560754,384940659635,352457872309,326421730230,292867298231,281322476472,246694302649,227635385345,230053401602,243204641795,277027509252,299576087557,332862084102,351384130567,366416516104,383059514377,400776254474,421447881739,438625653772,455543378958,472721150991,490165261329,490433696786,501439550483,498486760469,515666629654,517277242391,518619419672,537409901593,540362691610,540094256155,532846498844,535530853405,540094256158,539825820704,541436433442,541167997987,523992323110,506808259623,507345130536,506271388713,486944035883,470032602156,453928571950,453121168431,438088782896,419568833585,401315222578,370443047988,351115695157,282396218424,247231173689,230051304506,228172256315,243473077379,278371783812,299844523141,333667390598,348431340679,362926855304,380912030857,399167739018,438359315596,489896826001,482917504146,498488857747,501439550612,499023631509,515398210710,515668726936,534457111705,532846498970,534993982619,537141466268,539020514461,540362691742,541167998111,540362708128,541167998114,540903756963,506539824295,507076695208,506539824297,486147118250,487749342379,471376876716,470301037741,455002313903,438359315632,385211192499,369906177204,346820727989,327224939702,298502345911,283201524920,246425867449,228977562810,228440691970,244546819331,299307652357,333935826182,349505082631,365074339080,382522643721,420908913931,472985392400,489091519761,481306891538,507345130772,506002953493,516203500822,515398194455,536873030937,541436433690,539557385499,537946772764,539825820957,538754176286,539557401887,540364789025,540901659938,506271388967,506539824424,506271388969,488286213419,470837908781,455268652334,420372043057,402388964658,369637741876,351652566325,331790439734,297428604215,282933089592,246157432121,228440692026,242667771267,279443428740,299576087941,332862084486,350041953671,369637741960,384133256585,399434077578,421714220427,439162525068,455805523341,472985392527,473253827984,489628390801,484796552594,506271389075,507613582740,524793435542,519961597335,515398194584,532846499225,533114934682,540362708379,538752079261,538752095647,524525000100,524258661798,506002970023,506808260009,486946133419,470842103212,470301037997,451242120622,454194910639,438090880432,420103607729,370174612916,352457872821,299576087991,283201525176,246425867705,228172256698,241594029571,279711864324,292596766213,330177730054,351117792775,369369306632,384401692169,397823464970,416613946891,433793816076,454463346189,456073958926,472716957199,470837909008,486675600913,487480907282,507076695571,507613566484,507076695573,524525000214,525598742039,523182822936,533383370265,532580193818,537946773021,539559482910,538485741087,539557385760,540899563041,541168014882,524256564772,506810357287,506539824680,507076695593,469227296301,446678717998,452047427119,419568834097,401315223090,385477531187,368027129396,349505082933,334204261942,300112959031,281590912568,246694303289,226830079546,224951031426,242130900611,262800430724,294475814533,330446165638,369637742216,381448902281,395407545994,413392721547,431646332556,453926475405,455000217230,468958860943,469495731856,487480907409,489091520146,507345131155,507076695700,507345131157,525061871254,524793435799,522914387608,518619420313,535799289501,540362692256,539020514977,538752079522,524525016739,522645952166,507613566632,507345131177,486675601067,470301038253,447484024494,434867558063,438357218992,367758694068,352189437621,317024392886,298502346423,263605737144,246157432505,226830079745,227905918722,245352126211,264679479044,300649830149,316755957510,352189437703,365879645960,380106725129,396483385098,416345511691,433256945420,436746606349,453658040078,452584298255,471643215632,472989587217,490165278482,508150437652,507076695829,503587034902,516203501335,515398211352,516203534106,519961597725,522377516830,522645952287,522914387744,518887855905,521572210466,524525000483,523182823204,500365809445,499292084006,483722811176,488286213929,470569473834,470301038379,454194911020,453121169197,430304155438,417687689007,403460609840,385743869745,368027129650,351115695923,335009568564,314340038453,277027510070,261995124535,230051305272,193812518713,247231174531,258505463684,295281121157,317292828550,352457873287,363732162440,379035080585,398096095115,415273867148,436480268173,455537088398,455268652943,473253828496,490165262226,489896826771,484796553108,499023632277,498218358678,518619420569,522914387866,524256565147,522377516956,521572226973,523182823327,522109081504,501171115937,504392341410,507345131427,503855470500,498755196837,482112214950,466542942120,470569473961,453121169322,452584298411,437015041964,436478171053,413124286382,400507819951,386012305328,369100871601,351384131506,333667391411,315413780404,278369687477,242130900918,226293209015,195154696120,158110603193,243204642819,261458253828,295817992197,317024393222,335280101383,364805904392,379569854474,438896187406,455805523983,455537088528,472985393170,484259682323,481038489620,498218326039,498486794264,502513293339,505466083356,504660776989,504392341534,505734518815,503318599712,500902680609,505466083362,491239004195,487749343268,482112198693,464934426662,465200764967,466811377704,453926475817,453389604906,434599122987,419566737452,419835172909,395944417326,383327950895,369369307184,351652567089,334472697906,297160169523,281322477620,249647093813,210992388150,191933470775,159452780600,224416258179,261189818500,283469961349,316489619590,365611210888,361853114505,380106725514,416077076620,419029866637,455537088655,455805524112,455004412049,469495732370,469227296915,481843763348,484259682453,486407166102,484259698839,501439551641,498755197082,502781728923,499560503452,500634245277,504929212574,506271389855,485333424288,483991247009,484528117922,487212472483,468690426020,464932329637,448826202279,449631508648,436209752233,417956124843,402386868396,402118432941,378764548270,364000598191,351384131760,317024393393,300381395122,282127784115,247231174836,226561644725,192738777270,140125427895,260384512260,282127784197,335011666183,349236648200,363732162825,380375161098,398897207563,397823465740,413392722189,433793816846,438896187663,456073959696,469764167954,471106345235,470301038868,469227297045,486138730774,486675618071,487480908057,483722811674,486138730779,483454376220,482917505309,488286214430,489359956255,483993344288,482112198945,464127039778,465469200676,449363073317,448826202406,432453736743,433256945960,435672865065,418224560426,401044691243,385743870252,383327951149,361588873518,344409004335,314612668720,300112959793,283201526066,249378658611,224145725748,189785987381,158915909942,104691947831,226830080387,262802528644,279980300677,314879007110,349773519240,362389985673,379301419402,396749724043,396212853132,415003335053,434068543886,455537088912,454194911634,471374780819,470032603540,468958861717,486675601814,486138763671,483454376346,482651167131,488017779100,488823085469,488556747166,489628391839,466006071713,464940718498,466006071715,468155652516,448826202533,449094637990,432455834024,418492996009,417423448490,401854192043,386012305836,364537469357,300383492529,266290092466,248573352371,229245999540,176364214709,142272911798,280785607173,333669489159,351652567560,365074340361,379032984074,396214950411,397823465996,416345512461,438090881551,454194911760,454465444369,455000218130,472448522771,471645313556,471106345493,488286214678,488017779223,486944037400,487212472857,483724909082,486944037404,486407166493,488286214687,483185941024,465200765473,466542942755,448557767205,447756655142,431111559719,417956125225,385743870508,364000598573,265216350770,248841787955,230319741492,176632650293,281859349125,317292829318,350849358472,368832436873,380912032394,397555030668,416077077133,454463347344,454194911890,471374781075,471643216533,489359973014,488823085720,489359956633,483724909211,484259682972,481038457501,486407166622,486944037535,487749343904,467616684705,466274507427,467889314468,448826202789,417150818985,384938564268,366148098733,348968213167,315682216624,299307653809,265484786354,249378658995,229514435252,314876910342,333130521351,368564001545,385206999818,396749724427,397825563404,416345512717,438894091023,455537089296,455268670225,472716974867,472180087573,488556747542,488286214935,489359956760,484528118553,481575328538,487749344028,486407166749,487749344030,488017779487,486944037664,467348249377,466542943011,449094638373,431646333735,433525381928,416886577961,417956125482,402386869035,385206999852,368832437037,368027130670,350847261487,316758055728,299844524849,266290092850,248304917299,228440693556,313534733190,332056779655,349236648840,368027130761,387086048138,399434079115,416613948301,433525382030,435941301135,454463347600,454731783057,448557767570,464663894931,467079814036,469227297685,489628392343,490165263256,483722812313,482112215962,486944037788,489359973277,488554650527,483185941408,466006072225,466274507683,449363073957,449631509414,432720075687,433256946600,418224561066,402923740075,384133258156,364000598957,366416518062,350041955247,300112960433,265216351154,278906559494,297697041415,315682216968,334472698889,349505084426,361853115403,380375161868,399165643789,397823466510,413392722959,415003335696,435941301265,434330688530,449899944979,447484025876,446947154965,463858588694,464395459607,468153555992,466811378713,464932330522,465469201435,469495733276,471106346013,471911652382,470837910559,466006072352,466274507809,447752461346,449631509539,450973686820,431646333989,431109463078,431914769447,415271771176,401849998378,385475435563,366148082732,361584679981,349773519918,333398957103,299307654192,281054043185,263337303176,282664656009,296354864266,310850378891,329909296268,351115697293,366953389198,365074341007,382522645648,402655304849,402923740306,420103609491,419835174036,419566738581,434867559574,432720092311,432451640473,447752461466,451510557851,451779009692,452852735134,453389606047,430572592288,430841027745,430572592290,431914769571,416613948580,413929594021,413392723110,397018160295,398360337576,382522645673,367758695594,350847278251,335278005421,314340039854,296086428847,296354864397,315682217230,333935828239,351115697424,350847261969,361584680210,382522645779,386280742164,401849998613,402655321366,420103609624,415003335961,415808642330,419029867803,418492996892,417956125981,419298303262,416613948703,413392739616,396212854050,397823466787,399165644068,379301420325,379032984870,380106726695,364537470248,365611212073,350847261994,333667392811,316219088172,296891735341,297697041808,312997862801,326419635602,348968213907,352189439380,361584696725,369369308567,385475435928,382791081369,383864823194,384133258651,386817613212,386012306845,398091902366,380106726815,381717339552,380912033185,379032984994,380106726819,362926874020,345210117542,346552294823,347357601192,330446167465,317829701034,297965477291,278638124561,295281122834,317292830227,314608475668,326419635733,330177732118,352189439511,347357617688,366953389594,366416518683,367758695964,363463728669,361853115934,362926857759,365074357792,346820730402,347357601315,345746988580,327761813029,329103990310,312192556583,313266298408,316487523881,300112961066,279980301971,296891735700,295817993877,315950653078,316755959447,326419635864,327224942233,334472699546,334204264091,332056780444,346283859613,345746988702,344673246879,329372442272,327493377698,330177732259,333130522276,314071604901,311924121254,295549558439,299844525736,281054043817,314340040470,314876911383,330983038744,331788345113,333667393306,334741135131,335009570588,349773520669,349236649758,348431343391,332593651488,333667393313,331251474210,332056780579,335814876964,318098136869,317829701414,300381396775,331519909786,332056780699,332593651617,331519909794,332325216163,332056780708},{1895841819,2164342812,1895858209,1893744794,1889550755,1619018148,1885356569,1612726936,2418050074,2686485532,2954904606,2686485535,2418066465,3223340183,3491792024,3760260250,4028646558,3760260255,3491792035,3223340197,2954904742,3760227603,4028646677,4297082134,4565533975,4833985817,5102454044,4833985825,4565533988,4297082150,4028646695,3760227624,3491824938,3223373102,2954921265,4028646794,4297098635,4565534093,4833985935,5102405010,5370840468,5639275926,5907727768,6176228763,5907727778,5639275941,5370840487,5102405033,4833985963,4565534126,4297098672,4028663218,3760211380,5102388745,5370840586,5639259660,5907711501,6176146959,6444598801,6713017876,6981453334,7250069016,6981453349,6713017895,6444598825,6176146988,5907711534,5639259696,5370840625,5102388787,4833953332,4565517877,5714757256,5981095561,6247433866,6513772171,6782207628,7048562317,7316997775,7585433233,7853885075,8122320534,8388789913,8122320548,7853885095,7585433258,7316997804,7046465198,6780110512,6511675057,6243239602,5974804147,5706368692,5437933237,5167400630,5440030471,4630529847,4634724229,5165303686,4357900216,3823126457,4355803140,3825223811,3544205754,3537914370,3491777793,3521137979,3516943873,3508555452,3500167040,3495974530,4043331204,8059377305,8323749530,8057280163,6981441198,6713005743,4833957558,4028651192,3491780353,4852832006,6717200141,6983554830,7251990288,7520425746,7786780436,8055199511,8055314202,8055183140,7786780453,7518328616,7249893162,6981457708,6713005870,6444570415,6176134960,5907699505,5639264050,5370828595,5102393140,4833957685,4297086774,4028651319,3491780408,2954909497,6192912267,6448764812,7522506644,7786796949,8055281562,7786813345,7518328742,7249893288,6981457834,6713022380,6444570542,6176135087,5907699632,5639264177,5370828722,5102393267,4833957812,4297086901,3760215990,3491780535,2954909624,2418038713,5117073415,5922379786,6727686158,6983555087,7249893393,7518312467,7520426005,7786928151,7518345251,7249909798,6981457961,6713006123,6444587052,6176135214,5907699759,5639264304,5370828849,5102393394,4565522483,4297087028,3760216117,3223345206,2954909751,2418038840,3495975043,4305475717,5651847305,6457153677,6994024593,7251990674,7530911895,7786846361,7518361760,7249909924,6981458087,6713022633,6444570795,6176151724,5907699886,5639264431,5370828976,4833958065,4565522610,4297087155,3760216244,3491780789,2954909878,2149603511,5381314824,6186621196,6723492111,6991927568,7260379412,7528798486,7518443801,7260395810,6991943973,6713039143,6455056682,6186621227,5907716396,5649750318,5381314863,4844443952,4576008497,4297087282,3768604979,3500169524,2954910005,2418039094,1612732727,6989830546,7258266003,7526816153,7260363169,6721411495,6455056809,5916088748,5649750445,4037040562,2688571829,2149603766,4297088006,4565523463,4833958920,5102394377,5370829834,5639265291,5907700748,6176152589,6444588047,6713023505,6981475347,7250041878,6981475362,6713039909,6444571688,6176136234,5907700779,5639265324,5370829870,5102394415,4565523504,4297088049,4028652680,4297088137,4565523594,4833959051,5102394508,5370829965,5639281806,5907700880,6176152721,6444604563,6713056406,6981524634,6713056416,6444604580,6176152743,5907700905,5639265450,5370846379,5102394541,4833959086,4565523631,4565523725,4833959182,5102394639,5370846480,5639265554,5907717395,6176169237,6444719384,6176169250,5907733797,5639281960,5370830122,5102394667,4833959212,4565523757,4565523856,4833959313,5102394770,5370846611,5639298453,5907783064,6176136606,5907766687,5639282084,5370863014,5102394793,4833959338,4565523883,4297088529,4565523986,4833975827,5102411285,5370863127,5639380506,5370863138,5102411301,4833992231,4565524010,4297088659,4565540500,4836073110,5104557720,5372960413,5104557728,4836073125,4565540519,4297088681,4565524263,5102411674,5102444449},{81,82,56}},
['Mecha Scrambler Egg']={61,64,2.8,2.8,2.79026084,{{255,255,252,0},{254,255,97,1},{235,236,119,1},{198,200,127,1},{168,169,125,0},{145,146,113,0},{123,123,107,0},{99,100,86,0},{86,86,77,0},{74,74,68,0},{68,68,68,0},{66,66,66,0},{65,65,62,0},{62,62,62,0},{60,60,54,0},{57,57,56,0},{54,54,54,0},{52,51,52,0},{50,50,46,0},{46,46,46,0},{44,43,38,0},{40,40,36,0},{37,37,36,0},{35,35,30,0},{33,32,30,0},{31,31,28,0},{30,30,28,0},{28,28,27,0},{27,26,26,0},{24,24,25,0},{24,24,21,0},{22,21,22,0},{21,21,17,0},{18,19,17,0},{16,16,15,0},{13,14,12,0},{11,11,10,0},{5,5,4,0},{1,0,4,0},{0,0,0,0}},{70869073948,70600638493,71674396702,71942815776,71674380321,53420769314,72748122267,71137509532,69795332253,70869074079,76506218656,78653702305,57447301282,71674380572,73553428765,71405945118,73016557855,76237783328,76774654241,53420769570,71405945242,89391120795,92612346268,93417652637,93954523550,94491394463,93149217184,76237783457,57178866082,37851513251,37583077796,70063768089,91538604570,94222959131,110060651036,92880781853,92343910942,91270169119,91807040032,76506219041,77579960866,61205398051,39462126116,88585814682,109523780251,109792215708,111134409373,110597522079,95028265632,95296701089,77311525538,59863220899,36777771684,121871811355,121334940444,103886652189,104155087647,88317379361,78385267490,56641995555,121603376027,120798086044,120529634206,103349781407,87243637665,79190573986,55836689315,173679854619,155426243612,155157808157,154889372702,137709519903,121871811617,113013441570,91538605091,208308028567,211797689496,229245994137,228977558682,229514429595,223877301404,223608865950,206428980384,207771157665,198644352162,179853870243,158110598308,139856987301,139320132774,208039593234,226024768787,244546815252,246425863445,263605732630,282933085463,283469972760,300918261018,300649825563,293938939164,292865197341,293133665566,277295940897,267095393570,266290087203,249647105316,232735655206,230319736103,229782865192,229245994281,228709123370,212066125099,207771157804,208308028717,208039593262,190859724079,191396594992,190322853169,173142983986,190322853258,208039593355,225219478924,241862460814,241594025359,277027505553,283201521042,300381390227,318366582164,335546434966,352189466007,369369302426,369637737883,370443109788,352726304161,351384126882,351652562339,334472693156,334741128613,318098130342,318635017639,318098130345,316755953066,297160164779,295549552044,297428600237,280248731054,280785601967,280517166512,262531990961,245888992690,244009944499,224951027124,208039593481,244815250954,265216345611,280785602060,296891729421,314340034062,330983032335,328835548688,347089159697,365074335250,365342770707,382522639892,382791075349,400776250902,418224555543,418492991000,419029861913,420372039194,437015037467,437283472924,437820376605,438088779296,437820360225,421445781027,421714216484,421177345573,419835168294,401044686375,399702509096,399165654569,382254204459,383596381740,366953383469,366684948014,366953383471,350578820656,333935822385,333130516018,316755953203,297428600372,277027505717,225487898248,263605733001,281590908554,315413776011,332862080652,350310385293,368027125390,384133252751,398628767376,415003346577,432988505747,432720070292,449094633109,449899939478,467616679575,467079808664,466274502297,484528113306,485333419675,485064984220,484796548765,485870290590,486138726047,503318595232,503587030689,486675596962,487212467875,486138726052,485601855141,485333436070,468153566888,467885115050,449899939499,450168374956,433525376685,433795909294,417687684783,418492991152,400507815601,384133252786,367490254515,350041949876,332862080693,313266292406,276490634935,190322853638,244546815751,264142604040,280785602313,315682211594,332593645323,366416512780,366684948237,382522640142,398091896591,415271765776,432720070417,432451634962,449363068691,449631504148,467079808789,466811373334,483993339671,483722807064,483991242521,483722807066,501173225243,500902676253,501173208862,501707982623,501173208864,500634240801,501439547170,502513288995,503318595364,503587030821,486675613478,485601855272,466542954281,466811373355,450705262380,433793812271,415273862960,398091896625,381985769266,366148077363,367490254644,350041950005,315950647094,297428600631,259847636792,190859724677,228709123974,264142604167,297965471624,315950647177,330983032714,346552289163,380375173004,398360332174,416345507727,432988506000,432183199633,449094633362,449631504275,466542954388,483991242646,483991242648,501171111833,500902676378,501439547293,501171111839,501171128225,502781724579,504123934628,486675613607,485333419945,468690421674,469764163499,470301034412,452047423405,434599118766,434330683311,397555042225,381717333939,364269029300,347894466485,316219082678,299039213495,264947910584,243473074105,156231550979,192201902084,229514430469,264142604294,297965471751,317292824584,331788339209,346015418378,380912027659,397823461388,415808636941,417419249678,434599118863,450436810768,449363068945,466542938130,466811373587,484528113684,483722807317,500634241046,500904773655,500634257432,501707982874,519424722971,518350981148,518084659229,518619432991,518350981153,518887852066,519961593891,521035335716,504392337445,503855482918,486675597352,487480903721,488554645546,471374776363,469764163628,452584310829,435406522415,434330683440,415271766065,397555025970,381985769523,363463723060,345210112053,311655680054,299307649079,264144701496,246157428793,208039594042,192738773123,231393478788,264142604421,298502342790,315413776519,350847256712,362926852233,380106721418,397823461515,415003330700,432988506253,434330683534,451778988175,450168375440,467348244625,485065001106,482917501076,500097370261,501707982998,518086740120,519424723097,520498464922,519961594011,518619416732,518619416735,518350981280,518082545825,519424739490,518619416740,520230029477,521035335846,503587031207,503855466664,487212468393,487480903850,488554645675,470837905580,469495728301,452584294574,435941296304,419029862577,399702509746,381180463283,364269029556,346283854005,329372420278,297430698167,246425864377,208576465082,207502723330,245352122627,263874169092,298233907461,315413776646,350310385927,364805900552,380645689609,398630865162,415003330827,432451635468,450172569869,451512649998,468958857487,467348244752,483991243025,484528113938,501707983123,500097370388,517277239573,518887852310,518082545943,519693158681,537678334234,537141463323,536067721500,536606689565,536067737886,535799286048,535530850593,536067721506,536873027875,518889949476,518082545957,520498465062,521039530279,503591225640,504392337705,485601855786,482651162923,468421986604,470301034797,453121181998,437015038256,419837266225,402655299890,384401688883,365076433204,347626031413,330446162230,281054038328,247768041785,208039594298,208308029826,245083687299,281054038404,298772875653,331519904134,348968208775,365342771592,416345508235,432990603660,468421986703,485064984976,483724904849,500904774034,501439547795,501976418708,519156287893,518350981526,517814110615,536604592537,537409898906,536873027995,535530850716,536604592542,535799286175,535262415264,536604592545,537141479842,518619416997,520230029734,504123902377,503050160554,466274503085,453389601198,453121165743,437283473840,403462703538,386817608115,346283854261,329909291446,297697036727,281590909368,246962735545,208576465338,208039594498,245888993795,280785603076,332862081542,347089160711,363463723528,380912028169,397827656202,415808637451,451778988558,469764164111,485870291472,503050160659,499023628820,516740368917,519424723478,519156288023,521305868824,538485738009,537678334490,535262415387,534994012700,536604592671,536067721760,534993979937,536604609058,518082562596,519693158950,503587031593,504392337962,482382727723,482649066028,470032599597,455537084974,454463343151,437551909424,421177346609,387354479155,365879642676,346015418933,329640856118,297160165943,281322474040,247231171129,209650207290,207771159170,247231171203,280517167748,296891730565,334472694406,347632323207,363195288200,380643592841,415542299275,434062248588,450973682317,453930666638,473522260623,489628387984,488286210705,507076692626,501976418963,498486758036,516471933589,520766917270,537946770074,536604609179,536067721885,537147755166,537678334623,537946770080,537678334625,537946770082,538483640995,521303771812,521035336357,522914384550,522645949095,503855483560,506808257194,481583712940,464663890605,448557763246,452852730543,438088780464,420642572977,404265913010,386280737459,364807998132,346552289973,330446162614,296893827767,280789797560,248573348537,208844901050,208308030210,246425864963,280248732420,297162263301,333935823622,363463723784,380914125577,434332781324,451244215053,473258019599,490702129936,490970565393,504392338194,504929209107,500634241812,516203514645,516740369175,519156288280,537409899289,536604592922,536067722011,536604592924,535799286557,537143560991,539020512032,541973318433,541438528291,523721788196,524524997413,525061868326,523719691047,503855467304,504394435369,506541919018,483454372651,464133311277,446949247790,448020892463,439164619568,400507816754,381448899379,348162902837,330983033654,247768042297,210187078458,210187078530,245352123267,281054038916,330177727366,364269030280,398093994890,415808637835,490970565520,482649066385,498757290898,499023629203,508687305620,523451255701,516471933846,515935062935,518623611800,540094253977,537946770330,534993980315,535262432156,539557383072,541973302177,541704866722,523992320933,524256562086,523451255719,503320693672,484259679147,448826198959,420372040625,399436172210,382254205875,365074336692,347894467509,331251469238,296086424503,247499606969,211260820410,208308030466,280517168132,297967569925,329108179974,364805901320,380647787529,416613944331,434599119884,450973682701,453121166350,491507436560,482380631057,499828935699,508150434836,524793433109,525867174934,520766901271,539557383193,538215205914,536873028635,536067738652,536873045023,538215205921,538752076834,540094254115,524256562212,524524997670,523719691303,504123903017,506271386666,485870292011,447484021806,452852730927,438357216304,418761428017,382524738611,365342772276,348162903093,331788340278,294209473591,279174990904,248038575161,211531353146,207502724155,210723949698,244278381699,280248732804,346288049287,363463724168,397823462538,415540202635,434064346252,451778989197,455000214670,473522261135,490433694864,487749340305,504392338578,508152532115,507613564052,525867175061,525061868694,519156288663,537678335129,537946770586,539020512411,538483641500,539020512413,536606690462,535262416031,534993996960,535530851490,536873028771,523719691428,524256562342,524524997799,503855467688,504660774057,505734515882,486675598507,449094634670,455805521071,437820345520,417687686321,399702510770,364269030580,346283855029,329103985846,278906555576,207771159739,207502724353,210455514370,246962736387,281054039300,294744247557,363195288840,398628769034,416345509131,455537085709,455268650254,471374777615,488017792272,505734515986,507881999636,517814111509,516203498774,515939257623,519158385944,535530851609,535799287066,537141464347,537946770716,538483641629,536067722527,535262416160,536067722529,537678351650,524256578852,523719691558,521840643367,504392338728,504931306793,504660774186,489896824107,482649066796,464395455789,454731795758,438088781104,417150815537,399165639986,380375158067,363463724340,348699774261,331519905078,296354860343,280785603896,246962736441,212334562618,208308030779,210992385410,247768042883,279980297604,296086424965,329909292422,363463724424,380912029065,399169834378,417155009931,434601217420,453926473101,452584295822,470301035919,488017776016,489091517841,508150435218,503587032467,499023629716,515666644373,536336158105,534993980826,537409899931,538215206300,537141464477,539288948126,537141464479,536604593568,536873029025,537678335394,537409899939,519961611684,519693159846,518082547111,503320694184,504929209770,489359953323,482919599532,465200762285,456073956782,455539183023,436478168496,415271767473,397823462834,383059512755,368832433588,351384128949,332325211574,299039215031,283201523128,248573349305,213676740026,210187079099,207771160065,212066127362,249378655747,280248733188,296354860549,330446163462,347089161735,364805901832,380645690889,454463344141,453121166862,472180084239,490167356944,490970566161,503050161682,498755194387,498493050388,515666628117,515935063574,516471934488,534188674585,535799287322,537141464603,533920239132,533383368221,539020512798,536875126303,535262416416,536069819937,537411997218,537143561763,518619418148,518350982693,518082547238,518889950759,504123903529,504662871594,490165259819,464932326957,456344489518,434867555888,415540203057,399434075698,386280738355,368563998260,345210113589,298502344247,284543700536,244009946681,208308031034,212066127419,208308031105,212871433858,248036478595,279980297860,328030244486,346015420039,364269031048,434062249612,455000215181,456084442766,473253826191,491507437201,501976419986,498488856211,517814111893,520766901910,521572224663,537409900185,534993981082,536604593819,536873029276,537678335645,540631125662,534996078240,519428918948,518619418277,518350982822,503587032744,504394436265,489359953579,483454373548,466006068909,454463344303,437283475120,420908912305,402923736754,385206996659,368027127476,345478549173,330983034550,301455134391,284812136120,242401431225,207771160250,213139869371,208308031164,210455514881,212334563074,247768043267,279443427076,292059893509,327493373702,345746984711,363732160264,380375158537,398360334090,416882380555,434867556108,455537086221,472985390863,490702130960,486675599121,499560501010,515935063829,516203499286,516471934743,516740370200,534457110297,536067723034,535530852123,538215206684,539020513053,538483642142,537680432927,535799287585,537141464866,537409900323,518353080101,518889951014,519424724775,503318597416,505203937066,488017776427,486407163692,470837907245,455000215342,455537086255,438625652528,421986848561,404265914162,383864819507,368295563060,351115693877,336083308342,300918263607,284275265336,208043790138,212871434043,210187079484,207771160448,211260821377,212873531266,245888995203,277027508100,296086425477,328567115654,348431339399,366148079496,383059513225,400776253322,420372041611,438894088076,456082345869,472716955535,491507437456,482649067409,498755211154,515666644885,516203499415,516471934872,533920239513,536336158618,536604610459,537680433053,539020513182,536336175008,537678335906,537141464995,519693160359,503587033000,504123903913,487749341099,488017776556,472180084653,455537086382,456088637359,438902476720,403460607922,382254206899,366148079540,351654662069,335009566646,301186699191,284812136376,242130898873,213408305083,210992385980,208308031488,212334563329,245083688963,276222201860,301723570181,333130518534,349505081351,368566095880,387086045193,404534349834,421716316171,438627749900,472985391119,490970566672,484796551185,500097372178,504392339475,500634243092,515935064085,515666628630,515935064087,516740370456,537409900569,534993981466,535262433307,540899561502,539020513311,538483642400,539557384225,539825819682,535799287843,517814112292,518082547749,518621515814,519426822183,503318597672,504392339497,487485100075,489095712812,473255923757,456080248878,404536447026,385206997043,367758692404,335546437686,300112957495,283201523768,241862463545,214752579643,209650208828,208039596160,213408305281,213676740738,242401431683,276490637444,299307651205,332593647750,349773516935,386282836105,403997479050,473255923855,490433695888,490970566801,508687306898,507882000531,508687306900,523451256981,516740370582,515666628759,515935064216,533651804313,537946771610,536336158875,536067723420,537409900701,540094255262,533651820703,536604594337,540901658786,538483642531,520498466980,519693160613,503587033256,504123904169,421718413489,385743868083,368027127988,351115694261,333130518710,298502344887,284275265720,242399334585,208576467130,208310128828,210992386304,211799789825,214482047234,280248733956,301186699525,333667389702,351921000711,369100869896,402655301898,421447880971,438894088460,490702131472,490165260561,506808258834,507613565203,507347226900,525063966997,525332402454,517814112535,516203499800,533114933529,533383368986,533651804443,533920239900,535799288093,537141465374,534725546273,541170094371,524524998948,525063967013,523451257126,522914386215,504929210664,503855468841,504929210666,473524359469,404802785586,386817610035,367760789812,350578823477,334472696118,300918264119,283738394936,248573350201,211797692730,212334563643,207773258112,212602999170,246157431171,276759073156,294207377797,334741131654,351386227079,369637740936,386549174665,403192172938,439162524044,456342393230,472985391503,488823083408,488017777041,505734517138,507347227027,525867176343,519156289944,532848644505,534993981853,538483642782,535799288223,534188675488,535262417313,541436432802,523988128164,524524999078,524256563623,506271388072,504128098729,504660775338,487212470699,488286212524,402655302066,384401691059,351921000885,335278002614,300381393335,282664653240,247499608505,212334563770,211797692859,210187080124,211529257473,212066128386,249647092227,276490637828,293670507013,335546438150,369906176520,387086045705,403997479434,421714219531,438894088716,455805522445,454194909710,470301037071,487480906256,488554648081,506271388178,508687307284,524524999189,517814112790,516471935511,515668726296,536336159261,541704868382,537409901087,537946772000,540094255649,541704868386,541436432931,524275438116,524810211877,524258660902,523990225447,507078791720,504392340010,487480906283,487749341740,472985391661,456348684846,439162524208,420908913201,401044689458,385477530163,369100870196,352726307381,335814873654,298233909815,282933088824,247231173177,212871434810,212334563899,208576467516,211260822145,213139870338,245620560515,277027508868,300918264453,333669487238,351921001095,368295563912,385743868553,403460608650,421447881355,439162524300,455268651661,452584297102,471106343567,489091519120,489896825489,507882001042,508687307411,500365808276,516203500181,515668742806,533651804825,536336159386,537411998363,533920240284,538752078493,540362691230,538215207583,538483643040,540631126689,540899578530,504126001834,488554648235,488017777324,472716956333,438894088880,421447881393,402118431410,369641935540,353263178421,336888615606,293402071735,280250831544,248038576825,212066144954,208308032188,210187080449,214213612290,245352125187,276490638084,297965474565,351115694855,366416515848,384938562313,402923737866,438904574732,455805522701,455000216334,472985391887,490433712912,507613565714,499560502035,498493051668,515666629397,515935064856,533920256793,542510175004,539825820445,539020514078,540899562271,539557384992,539825820449,541442724642,540631126819,524527096614,523451257639,505734517544,504392340265,487749341995,487485100844,472448521005,439162524464,403192173362,386012304179,353531614005,328835552054,292865200951,211529257786,212066128699,207771161404,209652306817,213139870594,245620560771,278369686404,298502345605,333937922950,351921001351,366684951432,385475433353,402655302538,421177349003,456084460429,473258021775,490167358352,490970567569,503587034002,498486760339,516740371349,517277258646,517008806808,533920240537,533651805082,536336159643,538752078748,539288949661,540094256030,541704868767,540094272416,540899562403,523988128679,506271388584,505466082217,503857566634,487480906667,471374779309,455537087407,438625653680,420908913585,402386867122,385475433395,353263178677,327224939446,292328330167,276222202808,246696399801,212334564282,210723951547,212334564354,243743609859,280248734724,299039216645,351652566023,366416516104,384401691657,402925835274,421445784587,490435793937,508150436882,499025728531,516203500565,516740371478,517277242391,517814113304,538752078873,543047046170,541167997979,533383369756,534725547037,541436433438,540899562527,539825820704,540094256161,541438530595,524256580646,507345130536,506810356777,487212471339,471106343981,454731781166,454194910255,438363509808,420105704497,401581560882,385209095219,370443047988,352189436981,326688068662,292596765751,276759073848,213676741690,208308032571,207771161729,212066129026,280519267460,298502345861,333667390598,347894469767,364805903496,382522643593,421714220171,490433696912,500634244242,515666662549,515935065240,533114950809,534459208859,534725547164,537411998877,541167998110,541436433567,540362691744,540631127201,524264952998,523988128935,507076695208,504128099498,487480906923,488286213292,470840005805,453658039470,455539184815,402118431922,370711483572,345478550709,326956504246,293672604855,285349008568,246425867449,211797693626,207771161787,210455516418,244817351939,297965475077,334204261638,348431340807,365611209992,383059514633,402118432010,421447881995,472987489551,490972665104,486407165201,498755212562,501976421652,516740371733,515666646294,516203500824,534457111833,536336160026,534188676380,540094256414,539557385503,539825820960,540901692705,523721790759,506808259880,506539824425,488286213419,488554648876,455537087790,420640478513,402388964658,385475433779,369369306420,346015421749,328030246198,284543702328,246962738489,208844903738,208576468354,281322476932,301723571589,333935826310,351384130951,369641936264,383596385673,401044690314,487212471697,499023631762,500097373587,508150437268,525330306453,517545678230,515935081879,533117031833,534188676506,542510175643,541167998364,538215208349,538483643806,538215208351,538483643808,505466082728,506271389097,487212471723,488017778092,470032602541,450436814254,453389604271,420103607729,385748063667,369906177460,353800050101,331251471798,297428604343,284006831544,246425867705,208308032954,242938304003,278103348740,293670508037,333130520070,351652566535,383327950345,400239384074,419566736907,436746606092,473253828111,489628390928,487749342737,506271389202,508418872851,507613566484,524525000213,525598742038,523451258391,516740371992,533114951194,533383370268,534725547549,540631127582,537946773023,538752079392,541436433953,540899579426,524256564775,506271389224,506808260137,503855470122,486677698091,488286213676,469227296301,447215588910,448826201647,439162525232,419835172401,402118432306,368295564852,349505082933,335278003766,300918265399,282396218936,245352126009,293133637253,332593649286,351921002119,381985773193,397555029642,415271769739,434062251660,455805523597,455537088142,470837909135,469764167312,487480907409,488286213778,507076695699,507345131156,524793435797,525061871254,525867177623,525330306712,533920241305,532846532250,534993983133,539825821342,538483644063,540094256800,540899563169,539825821346,524258662051,525061871269,523719693991,507345147560,486944036522,470837909164,470032602797,446947153582,448020895407,439430960816,418761430705,401581561522,368832435892,352457873077,317561263798,298233910967,263874172600,243204642489,207771162370,243204642563,266826962692,301723571973,333935826694,351384131335,366148081416,381448902409,399165642506,417419253515,434599122700,438625654541,452852733710,470301038351,471106344720,489896826641,490433713938,508418873108,508150437653,520766904086,516740372247,515935065880,515666663193,516203501340,520766904093,521305872158,522109081375,522645952288,520498468641,521303775010,523719694116,503855470373,502244874022,485601859368,487480907561,487749343018,470032602923,454733879084,453389604653,430035719982,431109461807,421714220848,402923738929,385475434290,368564000563,352726308660,315413780277,296086427446,262800430903,228977563448,190859728697,208039597953,210187081602,246694303619,259847640964,297160169349,318366570374,351115696007,363734259592,380643596169,398628771722,417150818187,434330687372,438359316365,454731782030,455268652943,473255925648,472985393041,490433697682,490702133139,483185940372,499023632277,498488874902,515666630552,516203501465,517277243290,519156307867,521035339677,523451258783,521572210592,519961597857,504126003106,507345131427,504660776868,500902680485,501171115942,484259682215,484528117672,469764167593,470837909418,452852733867,437551912877,412855850926,414734899119,404534351792,386280740785,351652566962,334741133235,316219086772,295549556661,260384511926,228709128119,193544083384,207502727170,242936207363,258773899268,294207379461,318903441414,351652567047,380375160841,399165642762,399973046283,417152915468,439164622862,456342394895,473253828625,473522264082,482112198675,481306908692,498486761496,499294165017,499560503322,501976422427,508150437916,505197647901,504392341534,505466083359,503587035168,502515390497,507076696099,487480907812,483991263269,467348248615,468153554984,453121169449,453389604906,435135993899,436209735724,420372043821,395675981870,379301419055,387891353648,351921002545,334741133362,315682215987,299039217716,266021656629,228977563702,192738777143,156231555128,225221564547,263605737604,299844524165,317561264262,352457873543,364269033608,363463727241,381987870858,438894090381,455805524111,456076056720,472180086929,471106345106,464663894163,481306892436,482380650645,499560519831,499292067994,501439551643,500097374364,503050164381,505734518942,506271389855,503050164384,486675601570,490165262499,488017778852,483991247013,466274506918,466811377831,450973685928,452852734121,435941300394,434867558571,418761431212,401313126573,378496112814,361853114543,370443049136,334204262577,318098135218,282664655027,263605737652,242936207541,193275648182,156768426167,262263560452,282933090565,317026490630,335278004487,348431341832,364805904649,400239384843,416345512204,417150818573,437820348686,439164623119,453926476049,470837909778,468690426131,465200765204,487212472597,489091520790,488554666263,489628391705,486675601690,503855470875,499023632668,482917505309,489896827166,488554649887,485335521568,484261779745,483454376226,467079813411,467348248868,467885119781,450168396070,434062252328,435406526761,418495093034,417956124971,402923739436,382791080237,361052002606,343872133423,328567118128,318635006257,283469961522,265218447667,207771162933,173948295478,121871817015,226561644931,262800431492,281859348869,335546440071,348162906504,363732162953,381448903050,398096095627,415003335052,415808641421,436478171534,455805524368,454463347089,471106345362,471915846035,472448522644,486675618197,486407166359,486138730904,486675601817,485067086234,485601859995,487749360028,489362069918,483722811810,466542942627,468153571748,450705250726,450973686183,434330687912,418761431467,404534352300,380375161261,327761811888,318903441841,283201526194,228172257716,209381775797,156231555510,224951032323,261726689796,280785607173,315684313606,334472698375,349505083912,363463727625,380643596810,416882383372,417150818829,436209736206,438357219855,455268653584,455000218129,472180087314,471106345492,488286214677,487480908310,487212472855,486675601944,486944037401,484528118299,488286214684,488554650141,484528134688,483993344546,467891411491,468963056164,467350346277,449363073574,450168379943,433798011432,435135994409,418228754986,418495093291,404265916972,379571952173,327493376560,318098135601,282935188018,266826963507,227903822388,207502727733,277027510917,332862085767,351652567688,366148082313,380375161482,416613948044,416886577805,435406527118,438088784527,455000218256,454731782801,471374781074,472180087444,489628392085,489896827542,489628392087,489091537560,485870295706,484259682971,482917522076,486675602078,487480908447,485064989344,484259682977,449096735398,449631509159,434867559081,403192175276,361584679598,344941681327,328567118512,317294926513,267095399091,225219467956,314071603974,333401053959,350578825992,369100872457,382522645258,397823466251,416882383628,438357220111,454731782928,456073960209,474327571218,473790700307,472985393940,489091554069,489628392216,489091521305,484796554010,484530215707,483454376732,482380634909,485870295838,486944037663,487480908576,485601860385,483724909346,467885120293,449899944743,434601220905,419298302763,402386869036,386012306221,369369307950,352457874223,335278005040,284006832946,262800431923,311655684998,350041955208,368564001673,385743870858,399165643659,417150819212,434867559310,437283478415,455805524880,451510557585,465200765842,465737636755,468690426772,490433698709,490970586006,490165263256,484528118681,483454376858,488286215068,488823085981,489091521438,487749344159,485065005984,468690426788,468153555877,450168380326,450705251239,434330688424,418492996522,420372044715,401044691884,380375161773,366148082606,350847261615,333935827888,317561265073,278369688498,276490640390,311655685127,333667392520,349505084425,347626036234,363195292683,382522645516,400239385613,415808642062,414734900239,434867559440,433256946705,448020896786,447484025875,447215590420,464395459605,464932330518,465737636887,469227297816,467885120537,466542943258,467079814171,470301039644,471374781469,472448523294,470837910559,467885136928,466542943266,450705251363,451510557732,450705251365,432988511270,433525382183,416613948456,417419254825,401581562922,386012306475,363732163628,344941681709,328835554350,314340039727,296623299632,276759075889,259579206792,276759075977,310850378891,346283859084,348162907277,365879647374,382522645647,383864822928,403460611217,422251093138,421982657683,417687690388,431646334101,430841027734,430304156823,430572592280,434330688665,431914769562,451510557851,452584299676,435941301405,438088785054,435404430495,432720075936,432988511393,432451640482,416345513123,417150819492,398628773029,397823466662,381180468391,381985774760,365879647401,350041955498,334472699051,315145346220,294207380653,328567119119,349236649232,366684953873,362658422034,382522645779,386817613076,404534353173,404802788630,403729046807,401313127704,399165644057,398360337690,418224561435,417956125980,400507821341,402118434078,400239385887,397555031328,398091902241,380912033058,381985774883,383059516708,364805905701,363195292966,346820730151,330446167336,314340039977,317561265450,297428606251,259847642412,311387250064,328567119249,347357601171,351384133012,345210117525,363463728534,368564002199,369100873112,365611212185,384133258650,385207016859,384401694109,366148083102,364805905823,364000615840,346283859362,347626053027,330446167461,329372425638,312729427367,296354864552,279980301737,263068868010,242130902443,259310771728,276490640913,294475816466,317829701139,311387250196,328835554838,335009570327,328567119384,332056780313,349773520410,350041955867,350847262236,347894472221,329103990302,330446167583,331519909408,331251473953,313803185698,295281122852,295549558309,278906560038,261726690855,245352128040,225756339753,259579207314,277295947411,276490641044,293938945685,299307654806,296891735703,311387250329,316219088538,316755959451,313534733980,312192556701,312461008542,296354864800,296086429345,295012687522,279711866531,280248737444,262265659045,244546821798,227366952615,208576470696,293938945814,294207381271,310850379544,311924121369,317292830490,314876911387,311924121372,311387250461,311924137758,297697042208,297965477665,296891735842,280248737571,282396221220,245620563750,225487904551,311118831514,293938945952,297160171425,295281123234,276490657699},{1075937308,813711394,1075888283,1077985439,1075888412,1075855770,1344373147,1077952929,539001251,1075855897,1344307738,1614823964,1344340509,1082147362,813711907,541082148,1344291482,1612726939,1614856861,1344307872,1883276059,1614824224,1346388769,1881179037,1612727199,2686469147,2418066460,2149614623,1881162785,1612727330,1344291875,3223356567,3491873945,3223356576,2954904738,2686469283,2418033828,2149631141,3223340306,3491775763,3760227604,4028646678,4297114903,4565615898,4297082145,4028663074,3760227620,3491841318,3223389483,2954937647,2686469426,2954904970,3223340427,3491792268,3760227726,4297098641,4565517715,4833969556,5102388630,5370856855,5639357850,5370856865,5102405028,4834018726,4565550507,4297115054,4028646833,3760227762,3491775924,3223340553,3760211466,4028646923,4297082380,4565517837,4833953294,5102405135,5370824209,5639276050,5907711508,6176130582,6444615191,6713116187,6444615203,6176179751,5907711531,5639292461,5370824240,5102405169,4833953331,4565517876,4297082421,3491776136,4028647049,4297082506,4833953419,5102388876,5370824333,5639259790,5907695247,6176130704,6444582545,6713018003,6981453461,7249905303,7518389914,7790954144,7518389922,7249905320,6981453483,6713018029,6444582575,6180325041,5909792434,5641356979,5370824372,5102388917,4840244918,4297082551,2954905350,3760211719,4028647176,4297082633,4833953546,5102389003,5639276300,5907695374,6176130831,6444566288,6713018129,6981453587,7249889045,7518357271,7788906267,7788889890,7518340902,7249905449,6981453612,6715115310,6446663472,5704271668,5435836213,4630529847,4034938680,2954905477,3491776390,4028647303,4565518216,4833953673,5102389130,5370824587,5907711884,6176130958,6444566415,6713018256,6981453714,7249889172,7518341014,7788857241,7788840870,7518341031,7249905578,6983534509,6239045554,5970610099,3823126457,2418034691,2954905604,3491776517,4028647430,4565518343,4833953800,5102389257,5370824714,5907695627,6176131084,6444582925,6713001999,6981453840,7249889298,7518324756,7786776598,8057423899,7786743845,7788840999,7518341160,7249889323,7042254894,6715115567,6505383985,3279964218,2954905731,3491776644,4028647557,4565518470,4833953927,5370824840,5639260297,5907695754,6176131211,6444566668,6713018509,6981453967,7249873041,7518341266,7786776725,8055212184,8113916069,7845464232,7518341289,7251986604,5123360950,3275770114,3770697987,4028647684,4586490117,4833954054,5435836679,5704272136,5970610441,6239045898,6505384203,6773819660,7038077197,7249889551,7518325009,7843383571,8055245077,8355219738,8113899812,8111802663,7843367209,7518325034,7038060847,6769625392,4351609144,4351609220,5159012742,7306496399,7570753936,7839173010,8109754773,8378141081,7839173034,7572834731,7304399277,7568640556,3258993723,3808447619,3223342337,3250605569,5133848246,3242217148,4605366021,3233828736,8346751258,8344621345,8344605087,7256168080,7520425617,8323634849,8057280163,7520409258,7249876652,4833957558,4028651192,3227539202,4041234180,6719297293,6983538446,7522506515,7786764052,8055379734,7786780453,7518328616,7249876779,6981457708,6713022254,6444570416,6176134961,5907699506,5639264051,5370828596,4833957685,4565522230,4028651319,3491780408,2954909497,3223345025,4850734982,6985635727,7254071185,7518312338,7522506644,7786780565,8055330712,7786813346,7518328743,7249893289,6981457835,6713005997,6444586926,6176135088,5907699633,5370828722,5102393267,4833957812,4565522357,4028651446,3491780535,2954909624,6190815243,6459250700,6727686158,7264557074,7532992533,7786960918,7518345252,7249893415,6981457961,6713022507,6444570669,6176135214,5907716143,5370828849,5102393394,4833957939,4565522484,4028651573,3491780662,2954909751,2418038840,3498072195,5651847305,5920282762,6994024592,7262460051,7530895510,7786911895,7518361762,7249893542,6981458088,6713022634,6444570796,6176135341,5907699886,5639280815,5102393521,4833958066,4297087155,4028651700,3760216245,2954909878,2418038967,4303378693,5112879367,5381314824,6455056653,6723492111,6991927569,7260363028,7528847639,7786764571,7528880413,7260395811,6991943974,6723508520,6455073066,6186621228,5918185773,5649750318,5381314863,5112879408,4844443953,4307573042,4037040435,3227539765,2686474550,1881168183,7526717851,3495975348,2418039222,4297088006,4833958919,5102394376,5370846217,5639265291,5907700748,6176136205,6444588046,6713023504,6981475346,7250091029,6981475363,6713023526,6444588072,6176136234,5907700779,5639265324,5370829869,5102394414,4833958959,4565523504,4297088049,4028652680,4297088137,4833959051,5370846348,5639265422,5907717263,6176136337,6444604562,6713089173,6981459099,6713089181,6444588195,6176152741,5907717287,5639265449,5370829994,5102394539,4833959084,4565523629,5102394639,5370830096,5639281937,5907717395,6176218389,6444588315,6176202013,5907733794,5639281957,5370830119,5102394664,4833975593,4565523755,4028652844,4833959312,5102394769,5370862995,5639314838,5907750298,5639314846,5370863010,5102411173,4833959335,4565523880,4297088425,4028652970,3760217515,4028653072,4297088529,4565523986,4833975827,5102444054,5370879514,5102444062,4833975842,4565540388,4297088550,4028653095,3760217640,3491782185,4028653202,4297105043,4565556885,4836155033,4569751200,4301299363,4030750373,3762314918,3493879463,3223346856,4565540630,4833959704,4833976218},{32,33,29}},
}

-- Shell dimensions retain the previous hand-sized envelope. Fine panels carry
-- the reference markings through the rounded volume, on both front and back.
local function pullBits(n, bits)
    local base = 2 ^ bits
    local value = n % base
    return value, (n - value) / base
end

local function buildVox(name)
    local spec = VOX[name]
    if not spec then return nil end
    local width, height = spec[1], spec[2]
    local sizeX, sizeY, sizeZ = spec[3], spec[4], spec[5]
    local palette, panels = spec[6], spec[7]
    local unitX, unitY = sizeX / width, sizeY / height
    local m = Instance.new('Model')
    m.Name = name
    local root = part(m, 'Core', Vector3.new(.05, .05, .05), rgb(255,255,255), CFrame.new(), MAT, 1)
    -- Keep the pivot at the handle rather than at the changing visual bounds.
    m.PrimaryPart = root
    local function panel(label, sx, sy, depth, color, x, y, z, material)
        local p = part(m, label, Vector3.new(sx, sy, depth), color, CFrame.new(x,y,z), material)
        -- Smooth faces preserve the small armor/feather lines baked into the
        -- reference instead of stamping oversized Roblox studs over them.
        p.CastShadow = false
        local weld = Instance.new('WeldConstraint')
        weld.Part0 = root
        weld.Part1 = p
        weld.Parent = root
        return p
    end
    local shellColor = rgb(spec[9][1],spec[9][2],spec[9][3])
    for i, packed in ipairs(spec[8]) do
        local x, y, sx, sy, level
        x, packed = pullBits(packed, 7)
        y, packed = pullBits(packed, 7)
        sx, packed = pullBits(packed, 7)
        sy, packed = pullBits(packed, 7)
        level, packed = pullBits(packed, 5)
        local depth = math.max(.05, sizeZ * level / 31)
        local cap = math.min(.012, depth / 4)
        panel('Shell', sx*unitX, sy*unitY, depth-2*cap, shellColor,
            (x+sx/2-width/2)*unitX, (height/2-y-sy/2)*unitY, 0, MAT)
        if i % 160 == 0 then task.wait() end
    end
    for i, packed in ipairs(panels) do
        local x, y, sx, sy, pi, level
        x, packed = pullBits(packed, 7)
        y, packed = pullBits(packed, 7)
        sx, packed = pullBits(packed, 7)
        sy, packed = pullBits(packed, 7)
        pi, packed = pullBits(packed, 6)
        level, packed = pullBits(packed, 5)
        local c = palette[pi + 1]
        local color = rgb(c[1],c[2],c[3])
        local px = (x + sx / 2 - width / 2) * unitX
        -- Image rows start at the top; Roblox Y points up.
        local py = (height / 2 - y - sy / 2) * unitY
        local depth = math.max(.05, sizeZ * level / 31)
        local panelX, panelY = sx * unitX, sy * unitY
        -- Both luminous and painted details stay on the shell's surface.
        local cap = math.min(.012, depth / 4)
        local material = c[4] == 1 and NEON or MAT
        local label = c[4] == 1 and 'LuminousInlay' or 'ReferenceInlay'
        panel(label, panelX, panelY, cap, color, px, py, -(depth-cap)/2, material)
        panel(label, panelX, panelY, cap, color, px, py, (depth-cap)/2, material)
        -- Large shells are built off-tree in batches so the panel remains
        -- responsive. They are attached to the Tool only after completion.
        if i % 160 == 0 then task.wait() end
    end
    m:SetAttribute('SAE_REFERENCE_DETAIL', 64)
    return m
end


local function nightPet()local m=Instance.new('Model')m.Name='Night Flame'local body,dark,blue,glow=rgb(36,41,54),rgb(23,27,38),rgb(35,92,170),rgb(185,255,248)local r=ball(m,'Torso',Vector3.new(4.6,6.1,3.2),body,CFrame.new(),Enum.Material.Slate)ball(m,'Head',Vector3.new(3,2.8,2.7),dark,CFrame.new(0,3.85,-.25),Enum.Material.Slate)wedge(m,'HornL',Vector3.new(.8,2,.7),blue,CFrame.new(-.95,5.35,-.1),METAL)wedge(m,'HornR',Vector3.new(.8,2,.7),blue,CFrame.new(.95,5.35,-.1)*CFrame.Angles(0,math.rad(180),0),METAL)eye(m,-.55,4.15,-1.55,glow,Vector3.new(.42,.28,.18))eye(m,.55,4.15,-1.55,glow,Vector3.new(.42,.28,.18))for ai,y in ipairs({1.7,.2,-1.3})do local spread=3.05+(ai-1)*.15 for _,sx in ipairs({-1,1})do part(m,'Arm',Vector3.new(3.4,.9,.95),body,CFrame.new(sx*spread,y,-.05)*CFrame.Angles(0,0,math.rad(sx*(ai==2 and 8 or(ai==1 and-16 or 18)))),Enum.Material.Slate)ball(m,'Hand',Vector3.new(1.15,1.25,1),dark,CFrame.new(sx*(spread+1.75),y,-.1),Enum.Material.Slate)end end for _,sx in ipairs({-1,1})do part(m,'Leg',Vector3.new(1.45,3.5,1.5),body,CFrame.new(sx*1.25,-4.2,0),Enum.Material.Slate)ball(m,'Foot',Vector3.new(1.8,.9,2.2),dark,CFrame.new(sx*1.25,-6,-.45),Enum.Material.Slate)end part(m,'ChestV',Vector3.new(.34,2.7,.22),glow,CFrame.new(0,.55,-1.72),NEON)for _,sx in ipairs({-1,1})do part(m,'ChestBranch',Vector3.new(.25,1.7,.2),glow,CFrame.new(sx*.6,1.05,-1.72)*CFrame.Angles(0,0,math.rad(sx*40)),NEON)end return finalize(m,r)end
local function luminousPet()local m=Instance.new('Model')m.Name='Luminous Cthulhu'local body,dark,ice,cyan=rgb(20,43,91),rgb(17,31,72),rgb(194,242,255),rgb(81,217,255)local r=ball(m,'Torso',Vector3.new(5.4,6.2,3.6),body,CFrame.new(),Enum.Material.Slate)ball(m,'Head',Vector3.new(3.6,3.2,3.1),dark,CFrame.new(0,3.7,-.25),Enum.Material.Slate)eye(m,-.55,4.05,-1.65,ice,Vector3.new(.48,.3,.18))eye(m,.55,4.05,-1.65,ice,Vector3.new(.48,.3,.18))for i=-2,2 do tentacle(m,i*.5,2.65,-1.4,body,2.6,-90+i*10,Enum.Material.Slate)end for _,sx in ipairs({-1,1})do wing(m,sx,dark,ice,1.65,.7,.6)part(m,'UpperArm',Vector3.new(1.65,4,1.65),body,CFrame.new(sx*3.05,-.15,0),Enum.Material.Slate)ball(m,'Fist',Vector3.new(2,2,1.85),ice,CFrame.new(sx*3.5,-2.25,-.25),Enum.Material.Ice)part(m,'Leg',Vector3.new(1.75,3.7,1.8),body,CFrame.new(sx*1.45,-4.25,0),Enum.Material.Slate)ball(m,'Foot',Vector3.new(2,1,2.25),ice,CFrame.new(sx*1.45,-6.1,-.45),Enum.Material.Ice)end for _,p in ipairs({{-2.25,1.3,-1},{2.25,1.3,-1},{-2.7,-1.2,-.9},{2.7,-1.2,-.9}})do for j=1,3 do wedge(m,'IceCrystal',Vector3.new(.38,.9+.22*j,.38),j==2 and cyan or ice,CFrame.new(p[1]+(j-2)*.32,p[2]+.25*j,p[3]),Enum.Material.Ice)end end return finalize(m,r)end
local function star()local m=Instance.new('Model')m.Name='Star'local gold,edge,dark=rgb(255,208,22),rgb(239,165,10),rgb(25,20,18)local r=ball(m,'Center',Vector3.new(4.5,4.5,1.25),gold,CFrame.new(),MAT)for i=0,4 do local a=math.rad(-90+i*72)local x,y=math.cos(a)*3.25,math.sin(a)*3.25 wedge(m,'Point',Vector3.new(2.75,4.7,1.15),gold,CFrame.new(x,y,0)*CFrame.Angles(0,0,a+math.rad(90)),MAT)wedge(m,'BackEdge',Vector3.new(2.55,4.4,.3),edge,CFrame.new(x,y,.68)*CFrame.Angles(0,0,a+math.rad(90)),MAT)end for _,s in ipairs({{-1.25,1.45},{0,1.65},{1.15,1.15},{-2,.55},{-.8,.55},{.45,.6},{1.8,.45},{-1.55,-.65},{-.35,-.5},{.9,-.55},{1.65,-.95},{-.95,-1.65},{.25,-1.6}})do part(m,'Stud',Vector3.new(.52,.52,.22),rgb(255,221,43),CFrame.new(s[1],s[2],-.72),MAT)end eye(m,-.9,.15,-.78,dark,Vector3.new(.82,1.05,.3))eye(m,.9,.15,-.78,dark,Vector3.new(.82,1.05,.3))ball(m,'BlushL',Vector3.new(.65,.32,.14),rgb(255,133,97),CFrame.new(-1.75,-.55,-.83),NEON)ball(m,'BlushR',Vector3.new(.65,.32,.14),rgb(255,133,97),CFrame.new(1.75,-.55,-.83),NEON)return finalize(m,r)end

local function refEgg(name) return function() return buildVox(name) end end
local Built={['Unicorn Egg']=refEgg('Unicorn Egg'),['Kitsune Egg']=refEgg('Kitsune Egg'),['Night Flame Egg']=refEgg('Night Flame Egg'),['Archangel Egg']=refEgg('Archangel Egg'),['World Burner Egg']=refEgg('World Burner Egg'),['Aetheron Egg']=refEgg('Aetheron Egg'),['Cthulhu Egg']=refEgg('Cthulhu Egg'),['Luminous Cthulhu Egg']=refEgg('Luminous Cthulhu Egg'),['Sabertooth Egg']=refEgg('Sabertooth Egg'),['Skeletal Sabertooth Egg']=refEgg('Skeletal Sabertooth Egg'),['Octophant Egg']=refEgg('Octophant Egg'),['Mecha Scrambler Egg']=refEgg('Mecha Scrambler Egg'),['Night Flame']=nightPet,['Luminous Cthulhu']=luminousPet,['Star']=star}

local cache={}
local function badPet(o)local x=o while x and x~=workspace and x~=RS do if norm(x.Name):find('egg',1,true)then return true end x=x.Parent end return false end
local function hit(o,want)if want[norm(o.Name)]then return 1000 end local n=norm(o.Name)for a in pairs(want)do if #a>=5 and n:find(a,1,true)then return 420 end end for _,k in ipairs({'ItemName','DisplayName','PetName','EggName','Title','Type'})do local ok,v=pcall(function()return o:GetAttribute(k)end)if ok and v and want[norm(v)]then return 850 end end return 0 end
local function source(cat,name)local key=cat..'|'..name if cache[key]and cache[key].Parent then return cache[key]end local want={}for _,a in ipairs(Aliases[name]or{name})do want[norm(a)]=true end local best,bs=nil,-1 local function scan(o,bonus)if not(o:IsA('Model')or o:IsA('Tool'))then return end if P.Character and o:IsDescendantOf(P.Character)then return end if o:IsDescendantOf(Placed)then return end if cat=='Pets'and badPet(o)then return end local h=hit(o,want)if h<=0 then return end local count=0 for _,d in ipairs(o:GetDescendants())do if d:IsA('BasePart')then count+=1 end end if count<1 then return end local sc=h+bonus+math.min(count,100)if sc>bs then best,bs=o,sc end end for _,r in ipairs({{RS,220},{workspace,80}})do local list=r[1]:GetDescendants()for i,o in ipairs(list)do scan(o,r[2])if i%1500==0 then task.wait()end end end if type(getnilinstances)=='function'then local ok,list=pcall(getnilinstances)if ok then for i,o in ipairs(list)do if typeof(o)=='Instance'then scan(o,120)end if i%1500==0 then task.wait()end end end end cache[key]=best return best end
local function clone(src,name)if not src then return nil end local ok,c=pcall(function()return src:Clone()end)if not ok or not c then return nil end local m=c if c:IsA('Tool')then m=Instance.new('Model')m.Name=name for _,q in ipairs(c:GetChildren())do if not(q:IsA('Script')or q:IsA('LocalScript')or q:IsA('ModuleScript'))then q.Parent=m end end c:Destroy()end if not m:IsA('Model')then return nil end local kill={}for _,d in ipairs(m:GetDescendants())do if d:IsA('Script')or d:IsA('LocalScript')or d:IsA('ModuleScript')or d:IsA('Humanoid')or d:IsA('Animator')or d:IsA('ProximityPrompt')or d:IsA('ClickDetector')or d:IsA('SurfaceGui')or d:IsA('BillboardGui')then kill[#kill+1]=d end end for _,d in ipairs(kill)do d:Destroy()end if not m:FindFirstChildWhichIsA('BasePart',true)then m:Destroy()return nil end m.Name=name return m end
local function fit(m,target)local ok,s=pcall(function()return m:GetExtentsSize()end)if ok then local mx=math.max(s.X,s.Y,s.Z)if mx>.01 then pcall(function()m:ScaleTo(target/mx)end)end end end
local function model(cat,name)if cat=='Eggs' and VOX[name] then local m=buildVox(name) if m then return m,false end end local src=source(cat,name)if src then local m=clone(src,name)if m then fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,true end end local f=Built[name]if f then local m=f()fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,false end return nil,false end
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
local title=label(head,'DIVINE ITEM SPAWNER · DETAILED EGGS',UDim2.fromOffset(16,8),UDim2.new(1,-70,0,24),15)title.Font=Enum.Font.GothamBold
label(head,'Detailed reference eggs • spawn a new egg to inspect',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
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