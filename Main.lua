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
['Unicorn Egg']={palette={{244,181,205},{255,229,239},{56,221,229},{211,65,185},{246,79,117},{176,123,237},{255,239,175},{226,187,86}},parts={{'box','EggShell',{0.288356,0.25869,0.673214},1,{-0.144178,-1.422794,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.903211},1,{0.144178,-1.422794,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.673214},1,{0.432535,-1.422794,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.998538},1,{-0.72089,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.564406},1,{-0.432535,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.781156},1,{-0.144178,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.781156},1,{0.144178,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.564406},1,{0.432535,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.998538},1,{0.72089,-1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{-0.72089,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{-0.432535,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{-0.144178,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.107493},1,{0.144178,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{0.432535,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{0.72089,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{1.009246,-0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{-0.72089,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{-0.432535,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{-0.144178,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.107493},1,{0.144178,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{0.432535,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{0.72089,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{1.009246,-0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{-0.72089,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{-0.432535,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{-0.144178,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.107493},1,{0.144178,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{0.432535,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{0.72089,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{1.009246,-0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{-0.72089,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{-0.432535,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{-0.144178,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.107493},1,{0.144178,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,2.01964},1,{0.432535,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.729517},1,{0.72089,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.085524},1,{1.009246,-0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.998538},1,{-0.432535,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.564406},1,{-0.144178,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.781156},1,{0.144178,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.781156},1,{0.432535,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.564406},1,{0.72089,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.998538},1,{1.009246,0.129345,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.903211},1,{-0.432535,0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.379676},1,{-0.144178,0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.505351},1,{0.144178,0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.379676},1,{0.432535,0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.903211},1,{0.72089,0.388035,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.903211},1,{-0.72089,0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.379676},1,{-0.432535,0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.505351},1,{-0.144178,0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,1.379676},1,{0.144178,0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.903211},1,{0.432535,0.646725,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.521469},1,{-0.72089,0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.521469},1,{-0.432535,0.905414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.521469},1,{-1.009246,1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.521469},1,{-0.72089,1.164105,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','OriginalShellCell',{0.288356,0.25869,0.331176},1,{-1.009246,1.422794,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.03},{'box','PearlVein',{0.019936,0.459721,0.019936},2,{-0.623025,-0.706869,0.550481},{0.988562,-0.150812,-0.000256,0.150812,0.988561,0.001676,0,-0.001695,0.999999},'plastic',0,0},{'box','PearlVein',{0.019936,0.65427,0.019936},2,{-0.490595,-0.199201,0.528817},{0.859064,0.510785,0.033286,-0.511868,0.857246,0.055864,0,-0.065029,0.997883},'plastic',0,0},{'box','PearlVein',{0.019936,0.646491,0.019936},2,{-0.469617,0.368597,0.483905},{0.891387,-0.452029,-0.033146,0.453243,0.889,0.065188,0,-0.073131,0.997322},'plastic',0,0},{'box','PearlVein',{0.019936,0.457867,0.019936},2,{-0.69564,-0.706869,-0.549411},{0.992568,0.121689,0.000283,-0.121689,0.992566,0.00231,0,-0.002327,0.999997},'plastic',0,0},{'box','PearlVein',{0.019936,0.59738,0.019936},2,{-0.56744,-0.199201,-0.527505},{0.941544,0.335938,-0.02531,-0.33689,0.938883,-0.070736,0,0.075128,0.997174},'plastic',0,0},{'box','PearlVein',{0.019936,0.663685,0.019936},2,{-0.631264,0.368597,-0.480764},{0.8683,-0.494707,0.036324,0.496039,0.865969,-0.063584,0,0.073228,0.997315},'plastic',0,0},{'box','PearlVein',{0.019936,0.468881,0.019936},2,{0.20187,-0.706869,-1.0637},{0.969249,0.246083,-1.4e-05,-0.246083,0.969249,-5.5e-05,0,5.6e-05,1.0},'plastic',0,0},{'box','PearlVein',{0.019936,0.584125,0.019936},2,{0.261174,-0.199201,-0.982115},{0.999983,0.00552,-0.001606,-0.005749,0.960189,-0.279291,0,0.279295,0.960205},'plastic',0,0},{'box','PearlVein',{0.019936,0.764012,0.019936},2,{0.020724,0.368597,-0.831583},{0.764817,-0.633663,0.116303,0.644247,0.752252,-0.138069,0,0.180525,0.98357},'plastic',0,0},{'box','PearlVein',{0.019936,0.456499,0.019936},2,{1.033376,-0.706869,-0.5482},{0.995545,0.094286,-0.00028,-0.094287,0.995541,-0.00296,0,0.002974,0.999996},'plastic',0,0},{'box','PearlVein',{0.019936,0.563396,0.019936},2,{1.038384,-0.199201,-0.526604},{0.998271,-0.058614,0.004364,0.058777,0.995515,-0.074127,0,0.074255,0.997239},'plastic',0,0},{'box','PearlVein',{0.019936,0.81871,0.019936},2,{0.731286,0.368597,-0.482206},{0.703153,-0.709868,0.040785,0.711039,0.701995,-0.040333,0,0.05736,0.998354},'plastic',0,0},{'box','PearlVein',{0.019936,0.563017,0.019936},2,{0.836741,-0.706869,0.712161},{0.984876,-0.142004,0.099271,0.173263,0.807192,-0.564288,0,0.572953,0.819588},'plastic',0,0},{'box','PearlVein',{0.019936,0.683644,0.019936},2,{0.865049,-0.199201,0.690325},{0.971613,0.199761,0.126744,-0.236577,0.820412,0.520534,0,-0.535742,0.844382},'plastic',0,0},{'box','PearlVein',{0.019936,0.767166,0.019936},2,{0.680395,0.368597,0.483095},{0.750643,-0.659403,-0.041514,0.660708,0.74916,0.047165,0,-0.062833,0.998024},'plastic',0,0},{'box','CrystalPrism',{0.412955,0.58312,0.398714},3,{-0.640791,1.218357,0.042719},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.206476,0.325773,0.206476},3,{-0.721779,1.662508,0.145957},{0.991365,0.131133,0,-0.131133,0.991365,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.325773,0.206476},3,{-0.517085,1.635431,0.145957},{0,0.131133,0.991365,0,0.991365,-0.131133,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.325773,0.206476},3,{-0.517085,1.635431,-0.060519},{-0.991365,0.131133,0,0.131133,0.991365,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.325773,0.206476},3,{-0.721779,1.662508,-0.060519},{0,0.131133,-0.991365,0,0.991365,0.131133,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.412955,0.796005,0.398714},4,{0.185117,1.357339,0.142399},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.206476,0.44293,0.206476},4,{0.10372,1.955116,0.245636},{0.995338,0.096447,0,-0.096447,0.995338,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.44293,0.206476},4,{0.309235,1.9352,0.245636},{0,0.096447,0.995338,0,0.995338,-0.096447,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.44293,0.206476},4,{0.309235,1.9352,0.03916},{-0.995338,0.096447,0,0.096447,0.995338,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.44293,0.206476},4,{0.10372,1.955116,0.03916},{0,0.096447,-0.995338,0,0.995338,0.096447,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.412955,0.6294,0.398714},5,{0.640791,1.198421,0.071199},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.206476,0.351199,0.206476},5,{0.55968,1.675768,0.174438},{0.992574,0.121639,0,-0.121639,0.992574,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.351199,0.206476},5,{0.764624,1.650651,0.174438},{0,0.121639,0.992574,0,0.992574,-0.121639,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.351199,0.206476},5,{0.764624,1.650651,-0.032039},{-0.992574,0.121639,0,0.121639,0.992574,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.351199,0.206476},5,{0.55968,1.675768,-0.032039},{0,0.121639,-0.992574,0,0.992574,0.121639,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.412955,0.47205,0.398714},6,{-0.042719,1.112414,-0.541112},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.08,0.05},{'corner','CrystalPoint',{0.206476,0.264909,0.206476},6,{-0.123248,1.477652,-0.437874},{0.986912,0.16126,0,-0.16126,0.986912,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.264909,0.206476},6,{0.080527,1.444356,-0.437874},{0,0.16126,0.986912,0,0.986912,-0.16126,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.264909,0.206476},6,{0.080527,1.444356,-0.644351},{-0.986912,0.16126,0,0.16126,0.986912,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.206476,0.264909,0.206476},6,{-0.123248,1.477652,-0.644351},{0,0.16126,-0.986912,0,0.986912,0.16126,1.0,0,0},'glass',0,0},{'box','IvoryHorn',{0.284796,0.523784,0.284796},7,{-0.583832,1.352781,-0.377355},{0.924678,-0.380609,0.010351,0.38075,0.924336,-0.025139,0,0.027186,0.99963},'plastic',0,0},{'box','IvoryHorn',{0.206476,0.519314,0.206476},7,{-0.790309,1.829816,-0.341755},{0.910366,-0.411306,0.045387,0.413803,0.904874,-0.099851,0,0.109682,0.993967},'plastic',0,0},{'box','IvoryHorn',{0.128158,0.508264,0.128158},7,{-0.989668,2.29973,-0.284796},{0.930408,-0.364216,0.041075,0.366525,0.924547,-0.104267,0,0.112066,0.993701},'plastic',0,0},{'corner','HornTip',{0.06408,0.791687,0.06408},7,{-1.074716,2.411957,-0.231651},{0.924678,-0.37772,0.047939,0.38075,0.91732,-0.116423,0,0.125907,0.992042},'plastic',0,0},{'corner','HornTip',{0.06408,0.791687,0.06408},7,{-1.015464,2.436356,-0.231651},{-0.047939,-0.37772,0.924678,0.116423,0.91732,0.38075,-0.992042,0.125907,0},'plastic',0,0},{'corner','HornTip',{0.06408,0.791687,0.06408},7,{-1.018536,2.443818,-0.29522},{-0.924678,-0.37772,-0.047939,-0.38075,0.91732,0.116423,0,0.125907,-0.992042},'plastic',0,0},{'corner','HornTip',{0.06408,0.791687,0.06408},7,{-1.077788,2.419419,-0.29522},{0.047939,-0.37772,-0.924678,-0.116423,0.91732,-0.38075,0.992042,0.125907,0},'plastic',0,0},{'box','HornSpiral',{0.327515,0.06408,0.284796},8,{-0.484154,1.110705,-0.384475},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.277676,0.06408,0.246349},8,{-0.633672,1.4667,-0.352436},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.227837,0.06408,0.207901},8,{-0.783189,1.822695,-0.320395},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0},{'box','HornSpiral',{0.177998,0.06408,0.169454},8,{-0.932708,2.178691,-0.288356},{0.840314,0.339509,0.422618,-0.374607,0.927184,0,-0.391845,-0.158316,0.906308},'metal',0,0}},bounds={2.411892,4.375,2.127428}},
['Kitsune Egg']={palette={{194,186,154},{135,126,94},{222,48,196},{27,28,35},{240,74,216},{223,48,194},{255,235,246}},parts={{'box','EggShell',{0.284961,0.351511,0.863432},1,{-0.854882,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{-0.569921,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{-0.284961,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{0,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{0.284961,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{0.569921,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.134771},1,{-1.424805,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.859161},1,{-1.139844,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.254564},1,{-0.854882,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.483435},1,{-0.569921,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.590296},1,{-0.284961,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.590296},1,{0,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.483435},1,{0.284961,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.254564},1,{0.569921,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.859161},1,{0.854882,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.134771},1,{1.139844,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{-1.139844,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.625789},1,{-0.854882,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.930694},1,{-0.569921,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.066342},1,{-0.284961,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.066342},1,{0,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.930694},1,{0.284961,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.625789},1,{0.569921,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{0.854882,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.93865},1,{-0.854882,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.495507},1,{-0.569921,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.746379},1,{-0.284961,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.822342},1,{0,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.746379},1,{0.284961,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.495507},1,{0.569921,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.93865},1,{0.854882,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{-0.854882,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{-0.569921,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{-0.284961,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{0,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{0.284961,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{0.569921,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.781004},1,{-0.569921,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-0.284961,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.301674},1,{0,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{0.284961,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.781004},1,{0.569921,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.688781},1,{-0.569921,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{-0.284961,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{0,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.688781},1,{0.284961,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.509684,-1.567339,1.297211},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.607985,-1.652475,1.275744},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.257694,-1.567339,0.664037},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.32746,-1.652475,0.591536},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.523234,-1.567339,-0.480673},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.494864,-1.652475,-0.577206},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.108906,-1.567339,-0.915444},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.019038,-1.652475,-0.960689},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,-1.567339,-1.329976},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,-1.652475,-1.329976},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.644208,-1.567339,-1.005934},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.734076,-1.652475,-0.960689},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.181534,-1.567339,-0.673739},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.209904,-1.652475,-0.577206},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.112262,-1.567339,0.519034},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.042499,-1.652475,0.591536},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.421323,-1.567339,1.254276},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.323024,-1.652475,1.275744},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.413013,-0.721342,1.389311},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.511311,-0.806478,1.367844},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.231201,-0.721342,1.079392},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.300968,-0.806478,1.006891},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.51265,-0.721342,-0.509788},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.484281,-0.806478,-0.606322},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.052516,-0.721342,-1.185946},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.962647,-0.806478,-1.231192},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.100616,-0.721342,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0,-0.806478,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.872777,-0.721342,-1.276438},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.962647,-0.806478,-1.231192},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.455913,-0.721342,-0.702855},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.484281,-0.806478,-0.606322},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.370731,-0.721342,0.934389},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.300968,-0.806478,1.006891},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.609611,-0.721342,1.346378},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.511311,-0.806478,1.367844},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.413013,0.293525,1.389311},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.511311,0.208388,1.367844},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.231201,0.293525,1.079392},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.300968,0.208388,1.006891},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.51265,0.293525,-0.509788},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.484281,0.208388,-0.606322},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.052516,0.293525,-1.185946},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.962647,0.208388,-1.231192},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.100616,0.293525,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0,0.208388,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.872777,0.293525,-1.276438},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.962647,0.208388,-1.231192},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.455913,0.293525,-0.702855},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.484281,0.208388,-0.606322},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.370731,0.293525,0.934389},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.300968,0.208388,1.006891},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.609611,0.293525,1.346378},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.511311,0.208388,1.367844},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.326456,1.239675,0.825574},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.424755,1.154539,0.804106},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.793742,1.239675,0.528367},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.863506,1.154539,0.455866},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.995646,1.239675,-0.345003},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.967276,1.154539,-0.441536},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.764549,1.239675,-0.662233},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.67468,1.154539,-0.707479},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,1.239675,-0.804909},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,1.154539,-0.804909},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.29985,1.239675,-0.752724},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.389719,1.154539,-0.707479},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.653948,1.239675,-0.53807},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.682316,1.154539,-0.441536},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.64831,1.239675,0.383364},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.578545,1.154539,0.455866},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.238094,1.239675,0.78264},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.139794,1.154539,0.804106},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.23484,1.862191,0.55963},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.333141,1.777055,0.538162},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.561765,1.862191,0.44104},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.63153,1.777055,0.368539},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.731854,1.862191,-0.257676},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.703483,1.777055,-0.354211},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.592369,1.862191,-0.330254},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.5025,1.777055,-0.375499},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,1.862191,-0.538964},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,1.777055,-0.538964},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.12767,1.862191,-0.420744},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.217539,1.777055,-0.375499},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.390154,1.862191,-0.450744},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.418521,1.777055,-0.354211},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.416332,1.862191,0.296038},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.346569,1.777055,0.368539},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.146477,1.862191,0.516695},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.04818,1.777055,0.538162},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.890215,0.510229,-0.843289},{0.872689,0,0.488277,0,1.0,0,-0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.716029,0.790069,-0.776737},{0.832165,0,0.554528,0,1.0,0,-0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.80595,1.054531,-0.458962},{0.782307,0,0.622894,0,1.0,0,-0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.848086,1.298469,-0.456839},{0.721315,0,0.692607,0,1.0,0,-0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,1.141603,0.69657},3,{-0.812666,0.541778,-0.928989},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,0.677222,0.48373},3,{-1.102905,0.928761,-0.620231},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.522427,0.232191,0.145119},3,{-0.599825,1.470539,-0.44855},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.619174,0.174142,0.12577},4,{-0.48373,-0.928761,-1.440239},{0.913545,-0.406737,0,0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.580475,0.800119,0.580475},3,{-0.725595,-1.751101,-1.10137},{0.27146,-0.943133,-0.19186,0.96245,0.266012,0.054114,0,-0.199346,0.979929},'plastic',0,0},{'box','FoxTail',{0.475991,0.798099,0.475991},3,{-1.354444,-1.383467,-1.01458},{0.72032,-0.630347,0.289485,0.693642,0.654591,-0.300619,0,0.417341,0.90875},'plastic',0,0},{'box','FoxTail',{0.371505,0.650432,0.371505},3,{-1.731754,-0.822341,-0.84804},{0.922194,-0.386727,0,0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.267019,0.684096,0.267019},3,{-1.80915,-0.183817,-0.84804},{0.989949,0.141421,0,-0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.162532,0.332896,0.162532},3,{-1.664031,0.290238,-0.84804},{0.813733,0.581238,0,-0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.541778,0.348286,0.580475},5,{-1.102905,-1.644681,-1.18112},{0.949092,0.201736,-0.241922,-0.207912,0.978148,0,0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.493405,0.348286,0.532104},5,{-1.605983,-1.122254,-0.84804},{0.905849,0.347723,-0.241922,-0.358368,0.93358,0,0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.445031,0.348286,0.48373},5,{-1.857521,-0.522427,-0.84804},{0.840301,0.485148,-0.241922,-0.5,0.866025,0,0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.396657,0.348286,0.435356},5,{-1.760776,0.154794,-0.84804},{0.754061,0.610627,-0.241922,-0.62932,0.777146,0,0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.751869,0.453832,-0.716069},{0.957826,0.282587,-0.052091,-0.287348,0.941956,-0.173638,0,0.181283,0.983431},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.603605,0.409354,-0.716069},{0.052091,0.282587,0.957826,0.173638,0.941956,-0.287348,-0.983431,0.181283,0},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.595541,0.436231,-0.868299},{-0.957826,0.282587,0.052091,0.287348,0.941956,0.173638,0,0.181283,-0.983431},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.743806,0.480711,-0.868299},{-0.052091,0.282587,-0.957826,-0.173638,0.941956,0.287348,0.983431,0.181283,0},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.605255,0.510229,-0.843289},{0.872689,0,-0.488277,0,1.0,0,0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.716029,0.790069,-0.776737},{0.832165,0,-0.554528,0,1.0,0,0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.520989,1.054531,-0.458962},{0.782307,0,-0.622894,0,1.0,0,0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.563125,1.298469,-0.456839},{0.721315,0,-0.692607,0,1.0,0,0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,1.141603,0.69657},3,{0.812666,0.541778,-0.620231},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,0.677222,0.48373},3,{1.102905,0.928761,-0.58542},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.522427,0.232191,0.145119},3,{0.599825,1.470539,-0.44855},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.619174,0.174142,0.12577},4,{0.48373,-0.928761,-1.440239},{0.913545,0.406737,0,-0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.580475,0.791599,0.580475},3,{0.725595,-1.751101,-0.873417},{0.27146,0.953285,-0.132505,-0.96245,0.268875,-0.037373,0,0.137675,0.990478},'plastic',0,0},{'box','FoxTail',{0.475991,0.725856,0.475991},3,{1.354444,-1.383467,-0.833483},{0.72032,0.693083,0.027823,-0.693642,0.71974,0.028893,0,-0.040112,0.999195},'plastic',0,0},{'box','FoxTail',{0.371505,0.650432,0.371505},3,{1.731754,-0.822341,-0.84804},{0.922194,0.386727,0,-0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.267019,0.684096,0.267019},3,{1.80915,-0.183817,-0.84804},{0.989949,-0.141421,0,0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.162532,0.332896,0.162532},3,{1.664031,0.290238,-0.84804},{0.813733,-0.581238,0,0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.541778,0.348286,0.580475},5,{1.102905,-1.644681,-0.818925},{0.949092,-0.201736,0.241922,0.207912,0.978148,0,-0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.493405,0.348286,0.532104},5,{1.605983,-1.122254,-0.84804},{0.905849,-0.347723,0.241922,0.358368,0.93358,0,-0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.445031,0.348286,0.48373},5,{1.857521,-0.522427,-0.84804},{0.840301,-0.485148,0.241922,0.5,0.866025,0,-0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.396657,0.348286,0.435356},5,{1.760776,0.154794,-0.84804},{0.754061,-0.610627,0.241922,0.62932,0.777146,0,-0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.600283,0.420426,-0.761009},{0.957826,-0.287202,0.00917,0.287348,0.957338,-0.030565,0,0.031911,0.999491},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.748546,0.464906,-0.761009},{-0.00917,-0.287202,0.957826,0.030565,0.957338,0.287348,-0.999491,0.031911,0},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.747129,0.469637,-0.915724},{-0.957826,-0.287202,-0.00917,-0.287348,0.957338,0.030565,0,0.031911,-0.999491},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.598863,0.425157,-0.915724},{0.00917,-0.287202,-0.957826,-0.030565,0.957338,-0.287348,0.999491,0.031911,0},'plastic',0,0},{'box','CrownPatch',{0.832016,0.193492,0.677222},3,{0,1.992968,-0.038699},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CrownFrontPatch',{0.832016,0.193492,0.116095},3,{0,1.857521,-0.571858},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilBezel',{0.445031,0.445031,0.270889},6,{0,0.832016,-1.046615},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','ForeheadSigilGem',{0.311521,0.311521,0.290238},7,{0,0.832016,-1.220757},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilFacet',{0.133509,0.133509,0.067721},7,{-0.048374,0.880387,-1.385226},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0}},bounds={4.375,4.26163,2.967437}},
['Night Flame Egg']={palette={{82,46,18},{159,103,35},{143,88,29},{115,66,21},{213,140,31},{224,159,44},{46,106,23},{61,125,28},{77,143,35},{35,79,18},{126,78,25},{107,183,36},{204,128,27},{255,143,12},{255,195,48}},parts={{'box','EggShell',{0.184224,0.247905,0.560145},1,{-0.460558,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.877579},1,{-0.276335,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.999167},1,{-0.092111,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.999167},1,{0.092111,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.877579},1,{0.276335,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.560145},1,{0.460558,-1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.608942},1,{-0.460558,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.970199},1,{-0.276335,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.132949},1,{-0.092111,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.18223},1,{0.092111,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.132949},1,{0.276335,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.970199},1,{0.460558,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.608942},1,{0.644781,-1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{-0.644781,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{-0.460558,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.276335,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.092111,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{0.092111,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{0.276335,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{0.460558,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{0.644781,-0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{-0.644781,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{-0.460558,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.276335,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.092111,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{0.092111,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{0.276335,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{0.460558,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{0.644781,-0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{-0.644781,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{-0.460558,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.276335,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.092111,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{0.092111,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{0.276335,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{0.460558,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{0.644781,-0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{-0.644781,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{-0.460558,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.276335,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.092111,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{0.092111,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{0.276335,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{0.460558,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{0.644781,-0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.696351},1,{-0.829002,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.132949},1,{-0.644781,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.361635},1,{-0.460558,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.482004},1,{-0.276335,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.520009},1,{-0.092111,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.482004},1,{0.092111,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.361635},1,{0.276335,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.132949},1,{0.460558,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.696351},1,{0.644781,0.123954,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.736175},1,{-0.829002,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.206115},1,{-0.644781,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.46263},1,{-0.460558,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.611107},1,{-0.276335,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.680435},1,{-0.092111,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.680435},1,{0.092111,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.611107},1,{0.276335,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.46263},1,{0.460558,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.206115},1,{0.644781,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.736175},1,{0.829002,0.371857,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.773951},1,{-1.013226,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.275092},1,{-0.829002,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.557089},1,{-0.644781,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.730608},1,{-0.460558,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.826825},1,{-0.276335,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.857791},1,{-0.092111,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.826825},1,{0.092111,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.730608},1,{0.276335,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.557089},1,{0.460558,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.275092},1,{0.644781,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.773951},1,{0.829002,0.619762,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.809969},1,{-1.013226,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.829002,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.646136},1,{-0.644781,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.842372},1,{-0.460558,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.962325},1,{-0.276335,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,2.019631},1,{-0.092111,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,2.019631},1,{0.092111,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.962325},1,{0.276335,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.842372},1,{0.460558,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.646136},1,{0.644781,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{0.829002,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.809969},1,{1.013226,0.867668,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{-1.013226,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{-0.829002,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.644781,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.460558,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.340524},1,{-0.276335,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.252522},1,{-0.092111,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,1.054717},1,{0.092111,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.654108},1,{0.276335,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.37765},1,{0.644781,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.50667},1,{0.829002,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.37765},1,{1.013226,1.115574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.18578},1,{-1.013226,1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.18578},1,{-0.092111,1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.292526},1,{0.829002,1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.184224,0.247905,0.292526},1,{1.013226,1.363477,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0,-1.288154,0.524146},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{-0.267795,-1.288154,0.461999},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{-0.467607,-1.288154,0.297104},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{-0.544072,-1.288154,-0.280071},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{-0.467607,-1.288154,-0.297104},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{-0.267795,-1.288154,-0.461999},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{0,-1.288154,-0.524146},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.267795,-1.288154,-0.461999},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.467607,-1.288154,-0.297104},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{0.544072,-1.288154,-0.280071},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.467607,-1.288154,0.297104},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{0.267795,-1.288154,0.461999},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.183179,-0.853155,0.694513},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{-0.502436,-0.853155,0.548423},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.691505,-0.853155,0.33707},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.691505,-0.853155,-0.33707},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{-0.502436,-0.853155,-0.548423},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.183179,-0.853155,-0.694513},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{0.183179,-0.853155,-0.694513},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.502436,-0.853155,-0.548423},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.691505,-0.853155,-0.33707},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.691505,-0.853155,0.33707},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.502436,-0.853155,0.548423},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.183179,-0.853155,0.694513},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0,-0.258289,0.694825},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.35438,-0.258289,0.64947},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.617576,-0.258289,0.344086},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.717243,-0.258289,-0.327055},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.617576,-0.258289,-0.344086},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.35438,-0.258289,-0.64947},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0,-0.258289,-0.694825},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.35438,-0.258289,-0.64947},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.617576,-0.258289,-0.344086},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{0.717243,-0.258289,-0.327055},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{0.617576,-0.258289,0.344086},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.35438,-0.258289,0.64947},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.227996,0.384975,0.829806},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.624885,0.384975,0.62412},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.858774,0.384975,0.378102},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.858774,0.384975,-0.378102},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.624885,0.384975,-0.62412},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{-0.227996,0.384975,-0.829806},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.227996,0.384975,-0.829806},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.624885,0.384975,-0.62412},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.858774,0.384975,-0.378102},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{0.858774,0.384975,0.378102},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.624885,0.384975,0.62412},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.227996,0.384975,0.829806},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0,0.956101,1.034379},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{-0.527549,0.956101,0.944398},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{-0.917515,0.956101,0.687293},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-1.063581,0.956101,-0.404984},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},4,{-0.917515,0.956101,-0.687293},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{-0.527549,0.956101,-0.944398},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0,0.956101,-1.034379},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.527549,0.956101,-0.944398},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.917515,0.956101,-0.687293},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{1.063581,0.956101,-0.404984},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},2,{0.917515,0.956101,0.687293},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.409385,0.382093,0.122816},3,{0.527549,0.956101,0.944398},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{-0.272817,1.313324,0.694513},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{-0.747334,1.313324,0.647324},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{-1.026042,1.313324,0.102906},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{-1.026042,1.313324,-0.102906},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{-0.747334,1.313324,-0.647324},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{-0.272817,1.313324,-0.694513},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},4,{0.272817,1.313324,-0.351306},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.747334,1.313324,-0.209888},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{1.026042,1.313324,-0.15628},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},3,{1.026042,1.313324,0.15628},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.747334,1.313324,0.209888},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.313861,0.382093,0.122816},2,{0.272817,1.313324,0.351306},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'wedge','GoldenPinion',{0.231984,0.695952,0.218339},5,{-1.125807,0.573139,0.027292},{-0.470588,-0.882353,0,0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.751314,0.218339},5,{-1.183804,0.736892,0.027292},{-0.23612,-0.971724,0,0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.846501,0.218339},5,{-1.2418,0.900646,0.027292},{-0.032241,-0.99948,0,0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.969861,0.218339},5,{-1.299795,1.0644,0.027292},{0.126632,-0.99195,0,0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.112056,0.218339},5,{-1.357792,1.228152,0.027292},{0.245422,-0.969416,0,0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.266761,0.218339},5,{-1.415789,1.391908,0.027292},{0.333947,-0.942592,0,0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.429919,0.218339},5,{-1.473785,1.555661,0.027292},{0.400819,-0.916157,0,0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.136461,0.758805,0.136461},6,{-1.118984,1.255448,0.109169},{0.611448,-0.791285,0,0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.136461,0.830063,0.136461},6,{-1.787645,1.678476,0.109169},{0.460317,-0.887755,0,0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{-0.818769,-1.132631,-0.754869},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{-0.910631,-0.805124,-0.834015},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},9,{-0.918036,-0.477616,-0.834015},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{-0.834175,-0.150108,-0.834015},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{-0.73615,0.1774,-0.904756},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},9,{-0.714084,0.504908,-1.077166},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{-0.788266,0.832416,-1.173569},{0.829516,-0.518339,-0.207912,0.529919,0.848048,0,0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{-0.890492,1.159924,-0.691113},{0.847101,0.489074,-0.207912,-0.5,0.866025,0,0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.075052,0.877336,0.075052},10,{-0.818769,-0.825592,-0.721384},{0.96728,-0.248865,-0.049358,0.253713,0.948799,0.188176,0,-0.194541,0.980894},'wood',0,0},{'box','IvyVine',{0.075052,1.052745,0.075052},10,{-0.907469,0.102348,-0.928299},{0.999201,0.038887,0.009231,-0.039968,0.972184,0.230784,0,-0.230969,0.972961},'wood',0,0},{'box','IvyVine',{0.075052,0.731609,0.075052},10,{-0.784652,0.907469,-0.856847},{0.9442,0.279784,-0.173802,-0.329372,0.802046,-0.498233,0,0.527677,0.849445},'wood',0,0},{'wedge','GoldenPinion',{0.231984,0.695952,0.218339},5,{1.125807,0.573139,0.027292},{-0.470588,0.882353,0,-0.882353,-0.470588,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.751314,0.218339},5,{1.183804,0.736892,0.027292},{-0.23612,0.971724,0,-0.971724,-0.23612,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.846501,0.218339},5,{1.2418,0.900646,0.027292},{-0.032241,0.99948,0,-0.99948,-0.032241,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,0.969861,0.218339},5,{1.299795,1.0644,0.027292},{0.126632,0.99195,0,-0.99195,0.126632,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.112056,0.218339},5,{1.357792,1.228152,0.027292},{0.245422,0.969416,0,-0.969416,0.245422,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.266761,0.218339},5,{1.415789,1.391908,0.027292},{0.333947,0.942592,0,-0.942592,0.333947,0,0,0,1.0},'metal',0,0},{'wedge','GoldenPinion',{0.231984,1.429919,0.218339},5,{1.473785,1.555661,0.027292},{0.400819,0.916157,0,-0.916157,0.400819,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.136461,0.758805,0.136461},6,{1.118984,1.255448,0.109169},{0.611448,0.791285,0,-0.791285,0.611448,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.136461,0.830063,0.136461},6,{1.787645,1.678476,0.109169},{0.460317,0.887755,0,-0.887755,0.460317,0,0,0,1.0},'metal',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{0.818769,-1.132631,-0.754869},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{0.910631,-0.805124,-0.834015},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},9,{0.918036,-0.477616,-0.834015},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{0.834175,-0.150108,-0.834015},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{0.73615,0.1774,-0.904756},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},9,{0.714084,0.504908,-1.077166},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},7,{0.788266,0.832416,-1.173569},{0.829516,0.518339,0.207912,-0.529919,0.848048,0,-0.176319,-0.110176,0.978148},'plastic',0,0},{'wedge','IvyLeaf',{0.313861,0.409385,0.163754},8,{0.890492,1.159924,-0.691113},{0.847101,-0.489074,0.207912,0.5,0.866025,0,-0.180057,0.103956,0.978148},'plastic',0,0},{'box','IvyVine',{0.075052,0.877336,0.075052},10,{0.818769,-0.825592,-0.721384},{0.96728,0.248865,0.049358,-0.253713,0.948799,0.188176,0,-0.194541,0.980894},'wood',0,0},{'box','IvyVine',{0.075052,1.052745,0.075052},10,{0.907469,0.102348,-0.928299},{0.999201,-0.038887,-0.009231,0.039968,0.972184,0.230784,0,-0.230969,0.972961},'wood',0,0},{'box','IvyVine',{0.075052,0.731609,0.075052},10,{0.784652,0.907469,-0.856847},{0.9442,-0.279784,0.173802,0.329372,0.802046,-0.498233,0,0.527677,0.849445},'wood',0,0},{'box','CrownBattlement',{0.245631,0.3548,0.341154},11,{-0.655015,1.391908,-0.136461},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.245631,0.3548,0.341154},11,{-0.218339,1.391908,-0.136461},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.245631,0.3548,0.341154},11,{0.218339,1.391908,-0.136461},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBattlement',{0.245631,0.3548,0.341154},11,{0.655015,1.391908,-0.136461},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'corner','CrownEmerald',{0.163754,0.491261,0.163754},12,{-0.081876,1.719415,0.081876},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'corner','CrownEmerald',{0.163754,0.491261,0.163754},12,{0.081876,1.719415,0.081876},{0,0,1.0,0,1.0,0,-1.0,0,0},'plastic',0,0},{'corner','CrownEmerald',{0.163754,0.491261,0.163754},12,{0.081876,1.719415,-0.081876},{-1.0,0,0,0,1.0,0,0,0,-1.0},'plastic',0,0},{'corner','CrownEmerald',{0.163754,0.491261,0.163754},12,{-0.081876,1.719415,-0.081876},{0,0,-1.0,0,1.0,0,1.0,0,0},'plastic',0,0},{'box','EmberHeartBezel',{0.832416,0.832416,0.191048},13,{0,-0.068231,-1.118984},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','EmberHeartGem',{0.58269,0.58269,0.204692},14,{0,-0.068231,-1.2418},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','EmberHeartFacet',{0.249725,0.249725,0.047761},15,{-0.034115,-0.034115,-1.357792},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={4.375,3.452476,2.47746}},
['Archangel Egg']={palette={{207,144,29},{241,185,52},{191,121,20},{225,163,38},{246,195,62},{248,245,229},{255,237,112},{255,224,78}},parts={{'box','EggShell',{0.156209,0.280279,0.474969},1,{-0.390525,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.744132},1,{-0.234316,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.847233},1,{-0.078105,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.847233},1,{0.078105,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.744132},1,{0.234316,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.474969},1,{0.390525,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.554644},1,{-0.546734,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.894336},1,{-0.390525,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.062063},1,{-0.234316,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{-0.078105,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{0.078105,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.062063},1,{0.234316,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.894336},1,{0.390525,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.554644},1,{0.546734,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.624231},1,{-0.859155,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.022712},1,{-0.702945,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.240221},1,{-0.546734,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.366122},1,{-0.390525,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.424906},1,{-0.234316,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.424906},1,{-0.078105,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.366122},1,{0.078105,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.240221},1,{0.234316,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.022712},1,{0.390525,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.624231},1,{0.546734,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{-0.859155,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.0812},1,{-0.702945,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.320318},1,{-0.546734,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.46745},1,{-0.390525,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.549036},1,{-0.234316,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.575294},1,{-0.078105,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.549036},1,{0.078105,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.46745},1,{0.234316,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.320318},1,{0.390525,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.0812},1,{0.546734,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{0.702945,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{-0.859155,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.0812},1,{-0.702945,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.320318},1,{-0.546734,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.46745},1,{-0.390525,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.549036},1,{-0.234316,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.575294},1,{-0.078105,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.549036},1,{0.078105,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.46745},1,{0.234316,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.320318},1,{0.390525,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.0812},1,{0.546734,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{0.702945,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.686804},1,{-0.859155,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{-0.702945,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.395824},1,{-0.546734,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.56222},1,{-0.390525,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.663931},1,{-0.234316,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.712524},1,{-0.078105,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.712524},1,{0.078105,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.663931},1,{0.234316,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.56222},1,{0.390525,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.395824},1,{0.546734,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{0.702945,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.686804},1,{0.859155,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.686804},1,{-0.859155,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{-0.702945,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.395824},1,{-0.546734,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.56222},1,{-0.390525,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.663931},1,{-0.234316,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.712524},1,{-0.078105,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.712524},1,{0.078105,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.663931},1,{0.234316,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.56222},1,{0.390525,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.395824},1,{0.546734,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,1.136681},1,{0.702945,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.686804},1,{0.859155,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.429625},1,{-0.390525,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{-0.234316,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.716042},1,{-0.078105,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.656264},1,{0.078105,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.429625},1,{0.234316,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.248044},1,{-0.078105,1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.156209,0.280279,0.248044},1,{0.078105,1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{0,-1.092275,0.444444},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{-0.227074,-1.092275,0.391746},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{-0.396502,-1.092275,0.251926},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{-0.461341,-1.092275,-0.237484},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{-0.396502,-1.092275,-0.251926},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{-0.227074,-1.092275,-0.391746},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{0,-1.092275,-0.444444},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{0.227074,-1.092275,-0.391746},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{0.396502,-1.092275,-0.251926},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{0.461341,-1.092275,-0.237484},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{0.396502,-1.092275,0.251926},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{0.227074,-1.092275,0.391746},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.155324,-0.723424,0.588905},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.426035,-0.723424,0.465028},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.586353,-0.723424,0.285816},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.586353,-0.723424,-0.285816},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.426035,-0.723424,-0.465028},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.155324,-0.723424,-0.588905},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.155324,-0.723424,-0.588905},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.426035,-0.723424,-0.465028},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.586353,-0.723424,-0.285816},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.586353,-0.723424,0.285816},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.426035,-0.723424,0.465028},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.155324,-0.723424,0.588905},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.078105,-0.219014,0.808475},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.488725,-0.219014,0.679839},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.79252,-0.219014,0.555042},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.906539,-0.219014,-0.328131},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.79252,-0.219014,-0.555042},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.488725,-0.219014,-0.679839},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.078105,-0.219014,-0.808475},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.332515,-0.219014,-0.679839},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.636309,-0.219014,-0.555042},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.750329,-0.219014,-0.328131},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.636309,-0.219014,0.555042},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.332515,-0.219014,0.679839},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.231331,0.326436,0.85253},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.633694,0.326436,0.715772},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.870023,0.326436,0.351895},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.870023,0.326436,-0.351895},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.633694,0.326436,-0.715772},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.231331,0.326436,-0.85253},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{0.231331,0.326436,-0.85253},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.633694,0.326436,-0.715772},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.870023,0.326436,-0.351895},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.870023,0.326436,0.351895},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.633694,0.326436,0.715772},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.231331,0.326436,0.85253},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.078105,0.810715,0.378849},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.268469,0.810715,0.347812},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.411025,0.810715,0.229255},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.466026,0.810715,-0.214813},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},3,{-0.411025,0.810715,-0.229255},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{-0.268469,0.810715,-0.347812},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{-0.078105,0.810715,-0.378849},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.112259,0.810715,-0.347812},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.254815,0.810715,-0.229255},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},2,{0.309817,0.810715,-0.214813},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.254815,0.810715,0.229255},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.347133,0.32399,0.10414},4,{0.112259,0.810715,0.347812},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{-0.041311,1.113619,0.144586},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{-0.114545,1.113619,0.141881},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{-0.160851,1.113619,0.132515},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{-0.160851,1.113619,-0.132515},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{-0.114545,1.113619,-0.141881},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{-0.041311,1.113619,-0.144586},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{0.041311,1.113619,-0.144586},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},3,{0.114545,1.113619,-0.141881},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{0.160851,1.113619,-0.132515},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{0.160851,1.113619,0.132515},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},2,{0.114545,1.113619,0.141881},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.266136,0.32399,0.10414},4,{0.041311,1.113619,0.144586},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','WingSpar',{0.161995,0.795466,0.161995},5,{-0.925689,0.931474,0.075213},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.161995,0.808489,0.161995},5,{-1.591029,1.290177,0.092569},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.219851,0.948831,0.161995},6,{-0.84469,0.560968,0.023142},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.683157,0.032399},5,{-0.851755,0.592056,-0.083014},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.219851,0.909158,0.161995},6,{-1.00338,0.64137,0.031407},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.654594,0.032399},5,{-1.0085,0.671869,-0.074475},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.219851,0.869486,0.161995},6,{-1.16207,0.721774,0.039672},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.62603,0.032399},5,{-1.165314,0.751584,-0.065946},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.219851,0.829814,0.161995},6,{-1.320759,0.802175,0.047938},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.597466,0.032399},5,{-1.322201,0.831206,-0.057429},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.219851,0.79014,0.161995},6,{-1.479449,0.882578,0.056204},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.568901,0.032399},5,{-1.479164,0.910739,-0.04892},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.219851,0.750469,0.161995},6,{-1.638139,0.962981,0.064467},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.540338,0.032399},5,{-1.636208,0.990187,-0.040425},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.219851,0.710797,0.161995},6,{-1.796828,1.043382,0.072733},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.511774,0.032399},5,{-1.793336,1.069555,-0.03194},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.219851,0.671125,0.161995},6,{-1.955518,1.123786,0.080999},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.483209,0.032399},5,{-1.95055,1.148849,-0.023467},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{-0.775264,0.83312,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{-0.983544,0.937259,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{-1.191824,1.0414,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{-1.400105,1.145539,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.161995,0.795466,0.161995},5,{0.925689,0.931474,0.075213},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.161995,0.808489,0.161995},5,{1.591029,1.290177,0.092569},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.219851,0.948831,0.161995},6,{0.84469,0.560968,0.023142},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.683157,0.032399},5,{0.851755,0.592056,-0.083014},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.219851,0.909158,0.161995},6,{1.00338,0.64137,0.031407},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.654594,0.032399},5,{1.0085,0.671869,-0.074475},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.219851,0.869486,0.161995},6,{1.16207,0.721774,0.039672},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.62603,0.032399},5,{1.165314,0.751584,-0.065946},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.219851,0.829814,0.161995},6,{1.320759,0.802175,0.047938},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.597466,0.032399},5,{1.322201,0.831206,-0.057429},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.219851,0.79014,0.161995},6,{1.479449,0.882578,0.056204},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.568901,0.032399},5,{1.479164,0.910739,-0.04892},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.219851,0.750469,0.161995},6,{1.638139,0.962981,0.064467},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.540338,0.032399},5,{1.636208,0.990187,-0.040425},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.219851,0.710797,0.161995},6,{1.796828,1.043382,0.072733},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.511774,0.032399},5,{1.793336,1.069555,-0.03194},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.219851,0.671125,0.161995},6,{1.955518,1.123786,0.080999},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.483209,0.032399},5,{1.95055,1.148849,-0.023467},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{0.775264,0.83312,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{0.983544,0.937259,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{1.191824,1.0414,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},5,{1.400105,1.145539,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','HolyRuneStem',{0.086782,1.643096,0.086782},7,{0,0.057856,-0.890975},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','HolyRuneCross',{0.080999,0.786836,0.080999},7,{0,0.115711,-0.937259},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7,{-0.037606,0.936939,-0.809014},{1.0,0,0,0,0.948683,-0.316228,0,0.316228,0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7,{0.037606,0.936939,-0.809014},{0,0,1.0,0.316228,0.948683,0,-0.948683,0.316228,0},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7,{0.037606,0.960724,-0.880367},{-1.0,0,0,0,0.948683,0.316228,0,0.316228,-0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7,{-0.037606,0.960724,-0.880367},{0,0,-1.0,-0.316228,0.948683,0,0.948683,0.316228,0},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7,{0.037606,-0.843674,-0.788738},{-1.0,0,0,0,-0.872506,0.488603,0,0.488603,0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7,{-0.037606,-0.843674,-0.788738},{0,0,-1.0,-0.488603,-0.872506,0,-0.872506,0.488603,0},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7,{-0.037606,-0.880422,-0.854361},{1.0,0,0,0,-0.872506,-0.488603,0,0.488603,-0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7,{0.037606,-0.880422,-0.854361},{0,0,1.0,0.488603,-0.872506,0,0.872506,0.488603,0},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.568699,1.619955,0.07487},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.529942,1.619955,0.219509},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.455072,1.619955,0.349189},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.349189,1.619955,0.455072},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.219509,1.619955,0.529942},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.07487,1.619955,0.568699},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.07487,1.619955,0.568699},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.219509,1.619955,0.529942},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.349189,1.619955,0.455072},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.455072,1.619955,0.349189},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.529942,1.619955,0.219509},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.568699,1.619955,0.07487},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.568699,1.619955,-0.07487},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.529942,1.619955,-0.219509},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.455072,1.619955,-0.349189},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.349189,1.619955,-0.455072},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.219509,1.619955,-0.529942},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{-0.07487,1.619955,-0.568699},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.07487,1.619955,-0.568699},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.219509,1.619955,-0.529942},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.349189,1.619955,-0.455072},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.455072,1.619955,-0.349189},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.529942,1.619955,-0.219509},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.05554,0.151033,0.05554},8,{0.568699,1.619955,-0.07487},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5,{-0.555412,1.492674,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5,{0.555412,1.492674,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5,{0,1.492674,0.555412},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5,{0,1.492674,-0.555412},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},5,{-0.05207,1.805093,0.05207},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},5,{0.05207,1.805093,0.05207},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},5,{0.05207,1.805093,-0.05207},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},5,{-0.05207,1.805093,-0.05207},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0}},bounds={4.375,3.274624,1.909249}},
['World Burner Egg']={palette={{49,14,25},{101,29,43},{53,15,27},{78,22,36},{33,17,23},{239,88,117},{38,17,24},{82,21,37},{32,15,21},{91,79,85}},parts={{'box','EggShell',{0.176925,0.357126,0.486599},1,{-0.265387,-1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.743293},1,{-0.088462,-1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.810999},1,{0.088462,-1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.743293},1,{0.265387,-1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{0.442314,-1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.17842},1,{-0.619239,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{-0.265387,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.743293},1,{-0.088462,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.810999},1,{0.088462,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.743293},1,{0.265387,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{0.442314,-0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.628196},1,{-0.619239,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.012936},1,{-0.442314,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.202905},1,{-0.265387,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{-0.088462,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{0.088462,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.202905},1,{0.265387,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.012936},1,{0.442314,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.628196},1,{0.619239,-0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.707012},1,{-0.796164,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.158338},1,{-0.619239,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.40469},1,{-0.442314,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.547286},1,{-0.265387,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.613865},1,{-0.088462,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.613865},1,{0.088462,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.547286},1,{0.265387,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.40469},1,{0.442314,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.158338},1,{0.619239,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.707012},1,{0.796164,-0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.777883},1,{-0.973089,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{-0.796164,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.580926},1,{-0.619239,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.769389},1,{-0.442314,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.884589},1,{-0.265387,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.939626},1,{-0.088462,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.939626},1,{0.088462,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.884589},1,{0.265387,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.769389},1,{0.442314,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.580926},1,{0.619239,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{0.796164,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.777883},1,{0.973089,0.178564,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.777883},1,{-0.973089,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{-0.796164,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.580926},1,{-0.619239,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.769389},1,{-0.442314,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.884589},1,{-0.265387,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.939626},1,{-0.088462,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.939626},1,{0.088462,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.884589},1,{0.265387,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.769389},1,{0.442314,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.580926},1,{0.619239,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,1.28742},1,{0.796164,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.777883},1,{0.973089,0.535691,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.537955},1,{-0.973089,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.842814},1,{-0.796164,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.959586},1,{-0.619239,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.959586},1,{-0.442314,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.842814},1,{-0.265387,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.537955},1,{-0.088462,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.17842},1,{0.265387,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{0.619239,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{0.796164,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{0.973089,0.892817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{-0.973089,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{-0.796164,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{-0.619239,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{-0.088462,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{0.088462,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{0.265387,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{0.619239,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.486599},1,{0.796164,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.176925,0.357126,0.362689},1,{0.973089,1.249945,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{0.088462,-1.237125,0.429089},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},3,{-0.127147,-1.237125,0.393936},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{-0.288608,-1.237125,0.259656},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{-0.350901,-1.237125,-0.2433},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{-0.288608,-1.237125,-0.259656},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{-0.127147,-1.237125,-0.393936},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.088462,-1.237125,-0.429089},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.304073,-1.237125,-0.393936},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{0.465532,-1.237125,-0.259656},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{0.527826,-1.237125,-0.2433},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.465532,-1.237125,0.259656},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{0.304073,-1.237125,0.393936},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-0.242861,-0.81936,0.26659},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.512195,-0.81936,0.109438},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.672253,-0.81936,0.09883},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.672253,-0.81936,-0.09883},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-0.512195,-0.81936,-0.109438},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.242861,-0.81936,-0.26659},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.065936,-0.81936,-0.428791},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.33527,-0.81936,-0.391875},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.495329,-0.81936,-0.252919},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.495329,-0.81936,0.252919},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.33527,-0.81936,0.391875},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.065936,-0.81936,0.428791},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0,-0.248058,0.830524},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.423496,-0.248058,0.724636},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.737141,-0.248058,0.369862},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.855139,-0.248058,-0.353506},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.737141,-0.248058,-0.369862},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.423496,-0.248058,-0.724636},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0,-0.248058,-0.830524},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.423496,-0.248058,-0.724636},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.737141,-0.248058,-0.369862},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.855139,-0.248058,-0.353506},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.737141,-0.248058,0.369862},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.423496,-0.248058,0.724636},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.26201,0.369725,0.965586},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.71773,0.369725,0.810692},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.985397,0.369725,0.398561},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-0.985397,0.369725,-0.398561},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.71773,0.369725,-0.810692},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.26201,0.369725,-0.965586},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.26201,0.369725,-0.965586},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.71773,0.369725,-0.810692},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.985397,0.369725,-0.398561},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.985397,0.369725,0.398561},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.71773,0.369725,0.810692},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.26201,0.369725,0.965586},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0,0.918229,0.292568},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-0.506651,0.918229,0.502082},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{-0.88117,0.918229,0.437764},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-1.021449,0.918229,-0.268978},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{-0.88117,0.918229,-0.437764},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{-0.506651,0.918229,-0.502082},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0,0.918229,-0.993403},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},4,{0.506651,0.918229,-0.906986},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.88117,0.918229,-0.259656},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{1.021449,0.918229,-0.181345},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},3,{0.88117,0.918229,0.259656},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','ObsidianPlate',{0.393168,0.366956,0.11795},2,{0.506651,0.918229,0.906986},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{-0.26201,1.261299,0.444699},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},3,{-0.71773,1.261299,0.201574},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{-0.985397,1.261299,0.190964},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{-0.985397,1.261299,-0.190964},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{-0.71773,1.261299,-0.201574},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},3,{-0.26201,1.261299,-0.444699},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.26201,1.261299,-0.204636},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},2,{0.71773,1.261299,-0.201574},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.985397,1.261299,-0.190964},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},3,{0.985397,1.261299,0.190964},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},3,{0.71773,1.261299,0.201574},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','ObsidianPlate',{0.301429,0.366956,0.11795},4,{0.26201,1.261299,0.204636},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','DemonHorn',{0.209689,0.461124,0.209689},5,{-0.412826,1.297454,0.032764},{0.966705,-0.255789,-0.007273,0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.14154,0.357712,0.14154},5,{-0.445589,1.697174,0.026211},{0.989203,0.146549,0,-0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.073391,0.129739,0.073391},5,{-0.37351,1.919967,0.026211},{0.707107,0.707107,0,-0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.04587,0.332065,0.04587},6,{-0.393168,1.474379,-0.072081},{0.987441,-0.157867,0.006235,0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.04587,0.245182,0.04587},6,{-0.386614,1.756149,-0.058975},{0.963518,0.267261,-0.014306,-0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.183479,0.841517,0.183479},7,{-1.028787,0.858416,0.16382},{0.794358,-0.607376,0.00946,0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.183479,0.909305,0.183479},7,{-1.723384,1.310558,0.16382},{0.259457,-0.965654,-0.013919,0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.183479,1.205714,1.36298},8,{-1.441614,0.747019,0.196585},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{-1.166397,0.688044,0.072081},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{-1.520247,0.832205,0.072081},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{-1.874099,0.976366,0.072081},{-0.990747,0.135719,0,-0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.058975,0.324744,0.058975},6,{-1.323664,0.871522,0.032764},{0.686624,-0.726421,-0.02934,0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.058975,0.249006,0.058975},6,{-1.402297,1.100869,0.032764},{0.948683,0.315789,-0.016644,-0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','DemonHorn',{0.209689,0.461124,0.209689},5,{0.412826,1.297454,0.032764},{0.966705,0.255789,0.007273,-0.255893,0.966315,0.027475,0,-0.028421,0.999596},'slate',0,0},{'box','DemonHorn',{0.14154,0.357712,0.14154},5,{0.445589,1.697174,0.026211},{0.989203,-0.146549,0,0.146549,0.989203,0,0,0,1.0},'slate',0,0},{'box','DemonHorn',{0.073391,0.129739,0.073391},5,{0.37351,1.919967,0.026211},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'slate',0,0},{'box','HornInset',{0.04587,0.332065,0.04587},6,{0.393168,1.474379,-0.072081},{0.987441,0.157867,-0.006235,-0.157991,0.986671,-0.038971,0,0.039467,0.999221},'neon',0,0},{'box','HornInset',{0.04587,0.245182,0.04587},6,{0.386614,1.756149,-0.058975},{0.963518,-0.267261,0.014306,0.267644,0.96214,-0.051502,0,0.053452,0.99857},'neon',0,0},{'box','WingLeadingEdge',{0.183479,0.841517,0.183479},7,{1.028787,0.858416,0.16382},{0.794358,0.607376,-0.00946,-0.60745,0.794261,-0.012371,0,0.015574,0.999879},'slate',0,0},{'box','WingLeadingEdge',{0.183479,0.909305,0.183479},7,{1.723384,1.310558,0.16382},{0.259457,0.965654,0.013919,-0.965755,0.25943,0.003739,0,-0.014413,0.999896},'slate',0,0},{'wedge','BatMembrane',{0.183479,1.205714,1.36298},8,{1.441614,0.747019,0.196585},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{1.166397,0.688044,0.072081},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{1.520247,0.832205,0.072081},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFinger',{0.058975,0.965643,0.058975},9,{1.874099,0.976366,0.072081},{-0.990747,-0.135719,0,0.135719,-0.990747,0,0,0,1.0},'slate',0,0},{'box','WingFissure',{0.058975,0.324744,0.058975},6,{1.323664,0.871522,0.032764},{0.686624,0.726421,0.02934,-0.727013,0.686064,0.02771,0,-0.040357,0.999185},'neon',0,0},{'box','WingFissure',{0.058975,0.249006,0.058975},6,{1.402297,1.100869,0.032764},{0.948683,-0.315789,0.016644,0.316228,0.947368,-0.049931,0,0.052632,0.998614},'neon',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.799441,-0.222795,-1.12708},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.751228,-0.047983,-1.12708},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.612406,0.105745,-1.12708},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.39972,0.219845,-1.12708},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.138821,0.280558,-1.12708},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.138821,0.280558,-1.12708},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.39972,0.219845,-1.12708},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.612406,0.105745,-1.12708},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.751228,-0.047983,-1.12708},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.799441,-0.222795,-1.12708},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.751228,-0.397608,-1.12708},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.612406,-0.551335,-1.12708},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.39972,-0.665436,-1.12708},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.138821,-0.726146,-1.12708},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.138821,-0.726146,-1.12708},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.39972,-0.665436,-1.12708},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.612406,-0.551335,-1.12708},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.751228,-0.397608,-1.12708},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.799441,-0.222795,1.12708},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.751228,-0.047983,1.12708},{-0.34202,-0.939693,0,0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.612406,0.105745,1.12708},{-0.642788,-0.766044,0,0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.39972,0.219845,1.12708},{-0.866025,-0.5,0,0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.138821,0.280558,1.12708},{-0.984808,-0.173648,0,0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.138821,0.280558,1.12708},{-0.984808,0.173648,0,-0.173648,-0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.39972,0.219845,1.12708},{-0.866025,0.5,0,-0.5,-0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.612406,0.105745,1.12708},{-0.642788,0.766044,0,-0.766044,-0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.751228,-0.047983,1.12708},{-0.34202,0.939693,0,-0.939693,-0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.799441,-0.222795,1.12708},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.751228,-0.397608,1.12708},{0.34202,0.939693,0,-0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.612406,-0.551335,1.12708},{0.642788,0.766044,0,-0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.39972,-0.665436,1.12708},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{-0.138821,-0.726146,1.12708},{0.984808,0.173648,0,-0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.138821,-0.726146,1.12708},{0.984808,-0.173648,0,0.173648,0.984808,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.39972,-0.665436,1.12708},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.612406,-0.551335,1.12708},{0.642788,-0.766044,0,0.766044,0.642788,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.288324,0.131056,0.170371},10,{0.751228,-0.397608,1.12708},{0.34202,-0.939693,0,0.939693,0.34202,0,0,0,1.0},'metal',0,0},{'box','BurnerSigil',{0.085186,0.982919,0.085186},6,{0,-0.203136,-1.048447},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerSigil',{0.085186,0.524224,0.085186},6,{0,-0.183479,-1.061551},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0}},bounds={4.375,3.420294,2.424533}},
['Aetheron Egg']={palette={{203,151,43},{239,192,65},{119,18,33},{232,175,36},{244,233,186},{136,20,37},{94,14,27},{255,226,82},{245,234,190},{99,30,25}},parts={{'box','EggShell',{0.156209,0.229319,0.248044},1,{-0.702945,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{-0.546734,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{-0.078105,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.078105,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.546734,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.702945,-1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.554644},1,{-0.859155,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.894336},1,{-0.702945,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.062063},1,{-0.546734,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.390525,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.234316,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.062063},1,{-0.078105,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.894336},1,{0.078105,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.554644},1,{0.234316,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{0.546734,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.429625},1,{0.702945,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{0.859155,-0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,-0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,-0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,-0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,0.229319,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{-0.859155,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{-0.702945,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{-0.546734,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{-0.390525,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{-0.234316,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{-0.078105,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.712524},1,{0.078105,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.663931},1,{0.234316,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.56222},1,{0.390525,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.395824},1,{0.546734,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.136681},1,{0.702945,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.686804},1,{0.859155,0.458636,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.859155,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.429625},1,{-0.702945,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.546734,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.516345},1,{-0.234316,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.82267},1,{-0.078105,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.960671},1,{0.078105,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,1.002459},1,{0.234316,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.960671},1,{0.390525,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.82267},1,{0.546734,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.516345},1,{0.702945,0.687955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.859155,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.429625},1,{-0.702945,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.546734,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.15753},1,{0.234316,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.546734,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.702945,0.917274,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.859155,1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.429625},1,{-0.702945,1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.320224},1,{-0.546734,1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.546734,1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.156209,0.229319,0.248044},1,{0.702945,1.146593,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,-0.966174,0.591189},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,-0.431374,0.854814},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,0.219014,0.854814},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.290801,0.810715,0.281023},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.290801,1.143081,0.281023},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,-0.966174,0.550875},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,-0.431374,0.717756},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,0.219014,0.717756},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.661075,0.810715,0.234656},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.661075,1.143081,0.234656},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,-0.966174,0.286759},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,-0.431374,0.352839},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,0.219014,0.352839},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.879324,0.810715,0.169549},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.879324,1.143081,0.169549},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,-0.966174,-0.286759},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,-0.431374,-0.352839},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.872135,0.219014,-0.352839},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.879324,0.810715,-0.169549},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.879324,1.143081,-0.169549},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,-0.966174,-0.550875},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,-0.431374,-0.717756},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.634885,0.219014,-0.717756},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.661075,0.810715,-0.234656},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.661075,1.143081,-0.234656},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,-0.966174,-0.591189},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,-0.431374,-0.854814},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.2317,0.219014,-0.854814},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.290801,0.810715,-0.281023},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},2,{-0.290801,1.143081,-0.281023},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,-0.966174,-0.30017},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,-0.431374,-0.854814},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,0.219014,-0.854814},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.134593,0.810715,-0.503185},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.134593,1.143081,-0.101614},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,-0.966174,-0.179956},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,-0.431374,-0.717756},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,0.219014,-0.717756},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.504865,0.810715,-0.143868},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.504865,1.143081,-0.143868},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,-0.966174,-0.169549},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,-0.431374,-0.352839},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,0.219014,-0.352839},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.723112,0.810715,-0.13346},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.723112,1.143081,-0.13346},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,-0.966174,0.169549},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,-0.431374,0.352839},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.872135,0.219014,0.352839},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.723112,0.810715,0.13346},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.723112,1.143081,0.13346},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,-0.966174,0.179956},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,-0.431374,0.717756},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.634885,0.219014,0.717756},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.504865,0.810715,0.143868},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.504865,1.143081,0.143868},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,-0.966174,0.30017},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,-0.431374,0.854814},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.2317,0.219014,0.854814},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.134593,0.810715,0.503185},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','DualArmor',{0.32399,0.335563,0.10414},3,{0.134593,1.143081,0.101614},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','WingSpar',{0.161995,0.795466,0.161995},4,{-0.925689,0.931474,0.075213},{0.74257,-0.669131,0.029228,0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.161995,0.808489,0.161995},4,{-1.591029,1.290177,0.092569},{0.157432,-0.98753,0,0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.219851,0.948831,0.161995},5,{-0.84469,0.560968,0.023142},{0.81118,-0.567994,-0.139173,0.573576,0.819152,0,0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.683157,0.032399},4,{-0.851755,0.592056,-0.083014},{0.821775,-0.567994,-0.045486,0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.219851,0.909158,0.161995},5,{-1.00338,0.64137,0.031407},{0.830509,-0.539339,-0.139173,0.544639,0.838671,0,0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.654594,0.032399},4,{-1.0085,0.671869,-0.074475},{0.84109,-0.539339,-0.040999,0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.219851,0.869486,0.161995},5,{-1.16207,0.721774,0.039672},{0.848825,-0.510026,-0.139173,0.515038,0.857167,0,0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.62603,0.032399},4,{-1.165314,0.751584,-0.065946},{0.859378,-0.510026,-0.036653,0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.219851,0.829814,0.161995},5,{-1.320759,0.802175,0.047938},{0.866108,-0.480091,-0.139173,0.48481,0.87462,0,0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.597466,0.032399},4,{-1.322201,0.831206,-0.057429},{0.876617,-0.480091,-0.032467,0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.219851,0.79014,0.161995},5,{-1.479449,0.882578,0.056204},{0.882335,-0.449572,-0.139173,0.45399,0.891007,0,0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.568901,0.032399},4,{-1.479164,0.910739,-0.04892},{0.89279,-0.449572,-0.028462,0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.219851,0.750469,0.161995},5,{-1.638139,0.962981,0.064467},{0.897488,-0.418505,-0.139173,0.422618,0.906308,0,0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.540338,0.032399},4,{-1.636208,0.990187,-0.040425},{0.90788,-0.418505,-0.024658,0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.219851,0.710797,0.161995},5,{-1.796828,1.043382,0.072733},{0.911547,-0.386929,-0.139173,0.390731,0.920505,0,0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.511774,0.032399},4,{-1.793336,1.069555,-0.03194},{0.921869,-0.386929,-0.021072,0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.219851,0.671125,0.161995},5,{-1.955518,1.123786,0.080999},{0.924495,-0.35488,-0.139173,0.358368,0.93358,0,0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.483209,0.032399},4,{-1.95055,1.148849,-0.023467},{0.934744,-0.35488,-0.017722,0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},4,{-0.775264,0.83312,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},4,{-0.983544,0.937259,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},4,{-1.191824,1.0414,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},4,{-1.400105,1.145539,-0.092569},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','WingSpar',{0.161995,0.795466,0.161995},6,{0.925689,0.931474,0.075213},{0.74257,0.669131,-0.029228,-0.669769,0.741862,-0.032405,0,0.043639,0.999047},'metal',0,0},{'box','WingSpar',{0.161995,0.808489,0.161995},6,{1.591029,1.290177,0.092569},{0.157432,0.98753,0,-0.98753,0.157432,0,0,0,1.0},'metal',0,0},{'wedge','Feather',{0.219851,0.948831,0.161995},7,{0.84469,0.560968,0.023142},{0.81118,0.567994,0.139173,-0.573576,0.819152,0,-0.114004,-0.079826,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.683157,0.032399},6,{0.851755,0.592056,-0.083014},{0.821775,0.567994,0.045486,-0.569813,0.819152,0.065599,0,-0.079826,0.996809},'metal',0,0},{'wedge','Feather',{0.219851,0.909158,0.161995},7,{1.00338,0.64137,0.031407},{0.830509,0.539339,0.139173,-0.544639,0.838671,0,-0.11672,-0.075799,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.654594,0.032399},6,{1.0085,0.671869,-0.074475},{0.84109,0.539339,0.040999,-0.540895,0.838671,0.063754,0,-0.075799,0.997123},'metal',0,0},{'wedge','Feather',{0.219851,0.869486,0.161995},7,{1.16207,0.721774,0.039672},{0.848825,0.510026,0.139173,-0.515038,0.857167,0,-0.119295,-0.071679,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.62603,0.032399},6,{1.165314,0.751584,-0.065946},{0.859378,0.510026,0.036653,-0.511341,0.857167,0.0616,0,-0.071679,0.997428},'metal',0,0},{'wedge','Feather',{0.219851,0.829814,0.161995},7,{1.320759,0.802175,0.047938},{0.866108,0.480091,0.139173,-0.48481,0.87462,0,-0.121724,-0.067472,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.597466,0.032399},6,{1.322201,0.831206,-0.057429},{0.876617,0.480091,0.032467,-0.481188,0.87462,0.059148,0,-0.067472,0.997721},'metal',0,0},{'wedge','Feather',{0.219851,0.79014,0.161995},7,{1.479449,0.882578,0.056204},{0.882335,0.449572,0.139173,-0.45399,0.891007,0,-0.124004,-0.063183,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.568901,0.032399},6,{1.479164,0.910739,-0.04892},{0.89279,0.449572,0.028462,-0.450472,0.891007,0.056409,0,-0.063183,0.998002},'metal',0,0},{'wedge','Feather',{0.219851,0.750469,0.161995},7,{1.638139,0.962981,0.064467},{0.897488,0.418505,0.139173,-0.422618,0.906308,0,-0.126134,-0.058817,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.540338,0.032399},6,{1.636208,0.990187,-0.040425},{0.90788,0.418505,0.024658,-0.419231,0.906308,0.053399,0,-0.058817,0.998269},'metal',0,0},{'wedge','Feather',{0.219851,0.710797,0.161995},7,{1.796828,1.043382,0.072733},{0.911547,0.386929,0.139173,-0.390731,0.920505,0,-0.12811,-0.054379,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.511774,0.032399},6,{1.793336,1.069555,-0.03194},{0.921869,0.386929,0.021072,-0.387502,0.920505,0.050131,0,-0.054379,0.99852},'metal',0,0},{'wedge','Feather',{0.219851,0.671125,0.161995},7,{1.955518,1.123786,0.080999},{0.924495,0.35488,0.139173,-0.358368,0.93358,0,-0.129929,-0.049875,0.990268},'plastic',0,0},{'box','FeatherQuill',{0.032399,0.483209,0.032399},6,{1.95055,1.148849,-0.023467},{0.934744,0.35488,0.017722,-0.355323,0.93358,0.046621,0,-0.049875,0.998755},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},6,{0.775264,0.83312,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},6,{0.983544,0.937259,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},6,{1.191824,1.0414,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'wedge','WingCovert',{0.231421,0.462844,0.185137},6,{1.400105,1.145539,-0.092569},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.161995,0.542362,0.161995},4,{-0.53227,1.05297,0.098355},{0.768221,-0.640039,0.013658,0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.109346,0.574725,0.109346},4,{-0.827335,1.5216,0.098355},{0.906183,-0.4228,-0.008514,0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.056699,0.36038,0.056699},4,{-0.966187,1.961302,0.092569},{0.99535,-0.096324,0,0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','CrownHorn',{0.161995,0.542362,0.161995},6,{0.53227,1.05297,0.098355},{0.768221,0.640039,-0.013658,-0.640184,0.768046,-0.01639,0,0.021335,0.999772},'metal',0,0},{'box','CrownHorn',{0.109346,0.574725,0.109346},6,{0.827335,1.5216,0.098355},{0.906183,0.4228,0.008514,-0.422885,0.905999,0.018244,0,-0.020133,0.999797},'metal',0,0},{'box','CrownHorn',{0.056699,0.36038,0.056699},6,{0.966187,1.961302,0.092569},{0.99535,0.096324,0,-0.096324,0.99535,0,0,0,1.0},'metal',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.432211,1.631526,-0.035667},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.402756,1.631526,0.074258},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.345855,1.631526,0.172814},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.265384,1.631526,0.253286},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.166826,1.631526,0.310188},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.056901,1.631526,0.339643},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.056901,1.631526,0.339643},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.166826,1.631526,0.310188},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.265384,1.631526,0.253286},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.345855,1.631526,0.172814},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.402756,1.631526,0.074258},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.432211,1.631526,-0.035667},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.432211,1.631526,-0.14947},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.402756,1.631526,-0.259395},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.345855,1.631526,-0.357953},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.265384,1.631526,-0.438424},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.166826,1.631526,-0.495325},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{-0.056901,1.631526,-0.52478},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.056901,1.631526,-0.52478},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.166826,1.631526,-0.495325},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.265384,1.631526,-0.438424},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.345855,1.631526,-0.357953},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.402756,1.631526,-0.259395},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.05207,0.114786,0.05207},8,{0.432211,1.631526,-0.14947},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'box','IvorySigil',{0.219851,1.388533,0.115711},9,{0,0.057856,-0.914118},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','RadiantSigil',{0.067113,1.376962,0.067113},8,{0,0.109925,-0.995116},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.06364,0.508075,0.06364},8,{0,-0.289279,-0.948831},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.06364,0.508075,0.06364},8,{0,0.127282,-0.948831},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'box','SigilBranch',{0.06364,0.508075,0.06364},8,{0,0.497557,-0.948831},{0.501036,0.865426,0,-0.865426,0.501036,0,0,0,1.0},'neon',0,0},{'corner','BasePoint',{0.214066,0.647983,0.214066},10,{0.107032,-1.295964,0.107032},{-1.0,0,0,0,-1.0,0,0,0,1.0},'metal',0,0},{'corner','BasePoint',{0.214066,0.647983,0.214066},10,{-0.107032,-1.295964,0.107032},{0,0,-1.0,0,-1.0,0,-1.0,0,0},'metal',0,0},{'corner','BasePoint',{0.214066,0.647983,0.214066},10,{-0.107032,-1.295964,-0.107032},{1.0,0,0,0,-1.0,0,0,0,-1.0},'metal',0,0},{'corner','BasePoint',{0.214066,0.647983,0.214066},10,{0.107032,-1.295964,-0.107032},{0,0,1.0,0,-1.0,0,1.0,0,0},'metal',0,0}},bounds={4.375,3.763341,1.96061}},
['Cthulhu Egg']={palette={{11,59,26},{14,66,28},{35,108,49},{25,89,40},{33,48,69},{108,147,70},{113,139,42},{112,255,47},{62,124,32},{5,29,12},{4,32,12}},parts={{'box','EggShell',{0.239011,0.29483,0.900305},1,{-0.956044,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-1.195055,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.956044,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.717032,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.478021,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{-0.239011,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.239011,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.478021,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.717032,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{0.956044,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{-0.956044,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{-0.956044,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-0.956044,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.717032,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.478021,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.239011,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0.239011,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.478021,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.717032,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.956044,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{1.195055,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-0.956044,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.717032,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.478021,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.239011,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0.239011,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.478021,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.717032,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.956044,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{1.195055,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.378202},1,{-0.239011,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.378202},1,{0,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0,-1.53198,1.011814},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.51507,-1.53198,0.907824},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.896615,-1.53198,0.470407},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.04023,-1.53198,-0.450151},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.896615,-1.53198,-0.470407},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.51507,-1.53198,-0.907824},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0,-1.53198,-1.011814},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.51507,-1.53198,-0.907824},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.896615,-1.53198,-0.470407},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{1.04023,-1.53198,-0.450151},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.896615,-1.53198,0.470407},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.51507,-1.53198,0.907824},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,1.209781},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,0.849325},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,0.512227},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,-0.512227},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,-0.849325},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,-1.209781},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.324456,-1.014644,-1.209781},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,-0.849325},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.220256,-1.014644,-0.512227},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.220256,-1.014644,0.512227},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,0.849325},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.324456,-1.014644,1.209781},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0,-0.30718,1.230169},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.627406,-0.30718,1.034174},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,0.84453},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.2649,-0.30718,-0.500316},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,-0.84453},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.627406,-0.30718,-1.034174},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0,-0.30718,-1.230169},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,-1.034174},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.091186,-0.30718,-0.84453},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.2649,-0.30718,-0.500316},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.091186,-0.30718,0.84453},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,1.034174},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.266308,0.457845,0.986874},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.729926,0.457845,0.757437},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.003241,0.457845,0.462064},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-1.003241,0.457845,-0.462064},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.729926,0.457845,-0.757437},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.266308,0.457845,-0.986874},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.266308,0.457845,-0.986874},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.729926,0.457845,-0.757437},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.003241,0.457845,-0.462064},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.003241,0.457845,0.462064},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.729926,0.457845,0.757437},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.266308,0.457845,0.986874},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.119506,1.137076,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.451732,1.137076,0.973111},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.874395,1.137076,0.49615},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.03306,1.137076,-0.475895},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.874395,1.137076,-0.49615},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.451732,1.137076,-0.973111},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.119506,1.137076,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.690744,1.137076,-0.973111},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{1.113406,1.137076,-0.49615},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.27207,1.137076,-0.475895},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.113406,1.137076,0.49615},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.690744,1.137076,0.973111},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.182292,1.561914,0.217944},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.293401,1.561914,0.214151},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.363194,1.561914,0.201014},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.363194,1.561914,-0.201014},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.293401,1.561914,-0.214151},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.182292,1.561914,-0.217944},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.05672,1.561914,-0.217944},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.054391,1.561914,-0.214151},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.124183,1.561914,-0.201014},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.124183,1.561914,0.201014},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.054391,1.561914,0.214151},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.05672,1.561914,0.217944},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.259665,0.580183,0.259665},5,{-0.835801,-1.395706,-1.23784},{0.483077,-0.811201,-0.329529,0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{-1.071124,-1.265874,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.71353,0.246682},5,{-1.176613,-0.925061,-1.347019},{0.955286,-0.295684,0,0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{-1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.804925,0.2337},5,{-1.257759,-0.186636,-1.289694},{0.998131,0.060487,-0.008704,-0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{-1.233416,0.210979,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.822739,0.220715},5,{-1.079238,0.592364,-1.232369},{0.92711,0.374789,0,-0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{-0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.133868,0.207732},5,{-0.803342,1.298331,-0.783765},{0.936329,0.214696,-0.277836,-0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.681624,1.622914,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{-0.876374,1.850121,-0.335164},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{-1.071124,2.077331,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{-1.257759,1.98807,-0.335164},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{-1.444394,1.89881,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{-1.42005,1.728405,-0.335164},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{-1.395706,1.557999,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{-1.24153,1.517425,-0.335164},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-1.087354,1.476851,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.600477,-1.525539,-1.277971},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.071124,-1.265874,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.233416,0.210979,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.681624,1.622914,-0.484472},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.352071,-0.5307,0.267669},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.285001,-0.365258,0.267669},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.293279,-0.361904,0.089371},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.36035,-0.527345,0.089371},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.390753,0.291331,0.267695},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.312486,0.451781,0.267695},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.319514,0.455209,0.089345},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.397781,0.29476,0.089345},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.427911,1.113131,0.267714},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.341214,1.269187,0.267714},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.347271,1.272552,0.089328},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.43397,1.116498,0.089328},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{-0.681624,1.590456,-0.448769},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.259665,0.580183,0.259665},5,{0.835801,-1.395706,-1.23784},{0.483077,0.811201,0.329529,-0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{1.071124,-1.265874,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.71353,0.246682},5,{1.176613,-0.925061,-1.347019},{0.955286,0.295684,0,-0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.804925,0.2337},5,{1.257759,-0.186636,-1.289694},{0.998131,-0.060487,0.008704,0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{1.233416,0.210979,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.822739,0.220715},5,{1.079238,0.592364,-1.232369},{0.92711,-0.374789,0,0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.133868,0.207732},5,{0.803342,1.298331,-0.783765},{0.936329,-0.214696,0.277836,0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.681624,1.622914,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{0.876374,1.850121,-0.335164},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{1.071124,2.077331,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{1.257759,1.98807,-0.335164},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{1.444394,1.89881,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{1.42005,1.728405,-0.335164},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{1.395706,1.557999,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{1.24153,1.517425,-0.335164},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{1.087354,1.476851,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.600477,-1.525539,-1.277971},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.071124,-1.265874,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.233416,0.210979,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.681624,1.622914,-0.484472},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.285001,-0.365258,0.267669},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.352071,-0.5307,0.267669},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.36035,-0.527345,0.089371},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.293279,-0.361904,0.089371},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.312486,0.451781,0.267695},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.390753,0.291331,0.267695},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.397781,0.29476,0.089345},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.319514,0.455209,0.089345},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.341214,1.269187,0.267714},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.427911,1.113131,0.267714},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.43397,1.116498,0.089328},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.347271,1.272552,0.089328},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{0.681624,1.590456,-0.448769},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.020789,1.98229,0.27125},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.330756,1.918474,0.27125},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.336251,1.945162,-0.044042},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.026285,2.00898,-0.044042},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{1.022436,1.574226,0.227208},10,{0,-0.162293,-1.226924},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.068163,0.51038,0.068163},8,{-0.129832,-0.819572,-1.411936},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.068163,0.828322,0.068163},8,{-0.275895,-0.186636,-1.428164},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.640589,0.068163},8,{-0.146062,0.511219,-1.403822},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.068163,0.626452,0.068163},8,{0.129832,0.511219,-1.403822},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.068163,0.827845,0.068163},8,{0.251551,-0.186636,-1.428164},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.502317,0.068163},8,{0.121719,-0.819572,-1.411936},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.17852,1.038665,0.17852},11,{0,-0.129832,-1.395706},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,0.081145,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.535807,0.056801},8,{-0.365156,1.971841,-0.162293},{0.817806,-0.575493,0,0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.347319,0.056801},8,{-0.413844,2.328882,-0.162293},{0.794358,0.60745,0,-0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.23066,0.056801},8,{-0.219094,2.393799,-0.162293},{-0.633238,0.773957,0,-0.773957,-0.633238,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,0.081145,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.535807,0.056801},8,{0.365156,1.971841,-0.162293},{0.817806,0.575493,0,-0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.347319,0.056801},8,{0.413844,2.328882,-0.162293},{0.794358,-0.60745,0,0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.23066,0.056801},8,{0.219094,2.393799,-0.162293},{-0.633238,-0.773957,0,0.773957,-0.633238,0,0,0,1.0},'neon',0,0}},bounds={3.691006,4.375,2.837143}},
['Luminous Cthulhu Egg']={palette={{8,72,85},{8,76,91},{24,125,134},{14,104,118},{64,42,111},{85,176,194},{39,154,173},{78,225,255},{4,23,44},{2,16,31}},parts={{'box','EggShell',{0.262912,0.29483,0.995324},1,{-1.183105,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.920192,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.65728,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.394369,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{-0.131456,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.131456,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.394369,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.65728,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{0.920192,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{-1.183105,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.920192,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.65728,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.394369,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{-0.131456,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.131456,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.394369,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.65728,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{0.920192,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{-0.920192,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{-0.65728,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{-0.394369,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{-0.131456,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{0.131456,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{0.394369,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{0.65728,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{0.920192,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{-0.920192,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{-0.65728,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{-0.394369,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{-0.131456,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{0.131456,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{0.394369,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{0.65728,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{0.920192,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{-0.920192,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.65728,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.394369,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.131456,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{0.131456,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.394369,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.65728,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.920192,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{1.183105,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.920192,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.65728,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.131456,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{0.131456,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.539791},1,{0.65728,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.724205},1,{0.920192,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.539791},1,{1.183105,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.265543},1,{0.131456,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.131456,-1.53198,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.697076,-1.53198,1.000724},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.115627,-1.53198,0.517918},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.272787,-1.53198,-0.497663},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-1.115627,-1.53198,-0.517918},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.697076,-1.53198,-1.000724},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.131456,-1.53198,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.434165,-1.53198,-1.000724},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.852717,-1.53198,-0.517918},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{1.009875,-1.53198,-0.497663},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.852717,-1.53198,0.517918},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.434165,-1.53198,1.000724},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,1.180252},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,0.887025},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,0.538034},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,-0.538034},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,-0.887025},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,-1.180252},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.324456,-1.014644,-1.180252},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,-0.887025},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.220256,-1.014644,-0.538034},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.220256,-1.014644,0.538034},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,0.887025},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.324456,-1.014644,1.180252},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0,-0.30718,1.230169},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.627406,-0.30718,1.072901},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,0.546379},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.2649,-0.30718,-0.526123},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,-0.546379},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.627406,-0.30718,-1.072901},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0,-0.30718,-1.230169},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,-1.072901},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.091186,-0.30718,-0.546379},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.2649,-0.30718,-0.526123},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.091186,-0.30718,0.546379},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,1.072901},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.260493,0.457845,0.986874},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.714041,0.457845,0.778825},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.981539,0.457845,0.479385},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.981539,0.457845,-0.479385},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.714041,0.457845,-0.778825},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.260493,0.457845,-0.986874},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.260493,0.457845,-0.986874},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.714041,0.457845,-0.778825},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.981539,0.457845,-0.479385},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.981539,0.457845,0.479385},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.714041,0.457845,0.778825},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.260493,0.457845,0.986874},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.131456,1.137076,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.434165,1.137076,1.000724},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.852717,1.137076,0.517918},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.009875,1.137076,-0.497663},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.852717,1.137076,-0.517918},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.434165,1.137076,-1.000724},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.131456,1.137076,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.697076,1.137076,-1.000724},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{1.115627,1.137076,-0.517918},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.272787,1.137076,-0.497663},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.115627,1.137076,0.517918},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.697076,1.137076,1.000724},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.094838,1.561914,0.161612},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.02905,1.561914,0.15782},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.014575,1.561914,0.144682},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.014575,1.561914,-0.144682},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.02905,1.561914,-0.15782},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.094838,1.561914,-0.161612},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.168075,1.561914,-0.161612},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.233863,1.561914,-0.15782},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.277487,1.561914,-0.144682},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.277487,1.561914,0.144682},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.233863,1.561914,0.15782},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.168075,1.561914,0.161612},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.259665,0.537525,0.259665},5,{-0.835801,-1.395706,-1.205206},{0.483077,-0.875578,0,0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{-1.071124,-1.265874,-1.205206},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.727484,0.246682},5,{-1.176613,-0.925061,-1.276112},{0.955286,-0.290011,-0.057639,0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{-1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.796717,0.2337},5,{-1.257759,-0.186636,-1.347019},{0.998131,0.06111,0,-0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{-1.233416,0.210979,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.830689,0.220715},5,{-1.079238,0.592364,-1.289694},{0.92711,0.371202,-0.051728,-0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{-0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.178944,0.207732},5,{-0.803342,1.298331,-0.755601},{0.936329,0.206488,-0.28399,-0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.681624,1.622914,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{-0.876374,1.850121,-0.278832},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{-1.071124,2.077331,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{-1.257759,1.98807,-0.278832},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{-1.444394,1.89881,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{-1.42005,1.728405,-0.278832},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{-1.395706,1.557999,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{-1.24153,1.517425,-0.278832},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-1.087354,1.476851,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.600477,-1.525539,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.071124,-1.265874,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.233416,0.210979,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.681624,1.622914,-0.42814},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.352071,-0.5307,0.267669},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.285001,-0.365258,0.267669},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.293279,-0.361904,0.089371},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.36035,-0.527345,0.089371},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.390753,0.291331,0.267695},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.312486,0.451781,0.267695},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.319514,0.455209,0.089345},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.397781,0.29476,0.089345},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.427911,1.113131,0.267714},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.341214,1.269187,0.267714},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.347271,1.272552,0.089328},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.43397,1.116498,0.089328},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{-0.681624,1.590456,-0.392437},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.259665,0.537525,0.259665},5,{0.835801,-1.395706,-1.205206},{0.483077,0.875578,0,-0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{1.071124,-1.265874,-1.205206},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.727484,0.246682},5,{1.176613,-0.925061,-1.276112},{0.955286,0.290011,0.057639,-0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.796717,0.2337},5,{1.257759,-0.186636,-1.347019},{0.998131,-0.06111,0,0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{1.233416,0.210979,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.830689,0.220715},5,{1.079238,0.592364,-1.289694},{0.92711,-0.371202,0.051728,0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.178944,0.207732},5,{0.803342,1.298331,-0.755601},{0.936329,-0.206488,0.28399,0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.681624,1.622914,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{0.876374,1.850121,-0.278832},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{1.071124,2.077331,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{1.257759,1.98807,-0.278832},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{1.444394,1.89881,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{1.42005,1.728405,-0.278832},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{1.395706,1.557999,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{1.24153,1.517425,-0.278832},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{1.087354,1.476851,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.600477,-1.525539,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.071124,-1.265874,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.233416,0.210979,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.681624,1.622914,-0.42814},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.285001,-0.365258,0.267669},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.352071,-0.5307,0.267669},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.36035,-0.527345,0.089371},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.293279,-0.361904,0.089371},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.312486,0.451781,0.267695},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.390753,0.291331,0.267695},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.397781,0.29476,0.089345},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.319514,0.455209,0.089345},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.341214,1.269187,0.267714},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.427911,1.113131,0.267714},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.43397,1.116498,0.089328},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.347271,1.272552,0.089328},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{0.681624,1.590456,-0.392437},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.020789,1.98229,0.27125},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.330756,1.918474,0.27125},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.336251,1.945162,-0.044042},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.026285,2.00898,-0.044042},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{1.022436,1.574226,0.227208},9,{0,-0.162293,-1.226924},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.068163,0.51038,0.068163},8,{-0.129832,-0.819572,-1.411936},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.068163,0.828322,0.068163},8,{-0.275895,-0.186636,-1.428164},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.640589,0.068163},8,{-0.146062,0.511219,-1.403822},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.068163,0.626452,0.068163},8,{0.129832,0.511219,-1.403822},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.068163,0.827845,0.068163},8,{0.251551,-0.186636,-1.428164},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.502317,0.068163},8,{0.121719,-0.819572,-1.411936},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.17852,1.038665,0.17852},10,{0,-0.129832,-1.395706},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,0.081145,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,0.081145,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={3.691006,4.375,2.819814}},
['Sabertooth Egg']={palette={{32,27,25},{169,43,17},{49,42,35},{219,68,13},{242,104,18},{105,33,23},{238,221,171},{91,42,14},{255,197,17}},parts={{'box','EggShell',{0.246099,0.303571,0.745677},1,{-0.738295,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.168255},1,{-0.492196,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.330115},1,{-0.246099,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.330115},1,{0,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.168255},1,{0.246099,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.745677},1,{0.492196,-1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.870765},1,{-0.738295,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.404068},1,{-0.492196,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.667389},1,{-0.246099,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.784537},1,{0,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.784537},1,{0.246099,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.667389},1,{0.492196,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.404068},1,{0.738295,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.870765},1,{0.984394,-1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.980014},1,{-1.230492,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.605612},1,{-0.984394,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.947091},1,{-0.738295,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.144747},1,{-0.492196,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.237036},1,{-0.246099,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.237036},1,{0,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.144747},1,{0.246099,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.947091},1,{0.492196,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.605612},1,{0.738295,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.980014},1,{0.984394,-1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,-0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,-0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,-0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,0.151786,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,0.455357,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-1.230492,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{-0.984394,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{-0.738295,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{-0.492196,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{-0.246099,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.473137},1,{0,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.431916},1,{0.246099,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.303829},1,{0.492196,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.072836},1,{0.738295,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.697434},1,{0.984394,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{1.230492,0.75893,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.980014},1,{-1.230492,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.605612},1,{-0.984394,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.947091},1,{-0.738295,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.144747},1,{-0.492196,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.237036},1,{-0.246099,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.237036},1,{0,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,2.144747},1,{0.246099,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.947091},1,{0.492196,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.605612},1,{0.738295,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.980014},1,{0.984394,1.062501,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.674493},1,{-0.492196,1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-0.246099,1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.124154},1,{0,1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{0.246099,1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.674493},1,{0.492196,1.366074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.674493},1,{-0.492196,1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{-0.246099,1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.124154},1,{0,1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,1.030303},1,{0.246099,1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246099,0.303571,0.674493},1,{0.492196,1.669645,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{-0.123049,-1.577406,0.695136},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},3,{-0.479894,-1.577406,0.612549},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},3,{-0.745742,-1.577406,0.393695},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},4,{-0.847125,-1.577406,-0.372839},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{-0.745742,-1.577406,-0.393695},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{-0.479894,-1.577406,-0.612549},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{-0.123049,-1.577406,-0.695136},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{0.233795,-1.577406,-0.612549},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},6,{0.499644,-1.577406,-0.393695},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{0.601026,-1.577406,-0.372839},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},6,{0.499644,-1.577406,0.393695},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},6,{0.233795,-1.577406,0.612549},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{-0.42719,-1.04473,1.10207},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-0.956407,-1.04473,0.828599},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{-1.267764,-1.04473,0.502273},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{-1.267764,-1.04473,-0.502273},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{-0.956407,-1.04473,-0.828599},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{-0.42719,-1.04473,-1.10207},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{0.181092,-1.04473,-1.10207},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{0.71031,-1.04473,-0.828599},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{1.021665,-1.04473,-0.502273},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{1.021665,-1.04473,0.502273},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{0.71031,-1.04473,0.828599},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{0.181092,-1.04473,1.10207},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{0,-0.316289,1.266646},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{-0.646009,-0.316289,1.064839},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-1.123543,-0.316289,0.869574},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-1.302407,-0.316289,-0.515151},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-1.123543,-0.316289,-0.869574},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{-0.646009,-0.316289,-1.064839},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{0,-0.316289,-1.266646},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{0.646009,-0.316289,-1.064839},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{1.123543,-0.316289,-0.869574},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{1.302407,-0.316289,-0.515151},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{1.123543,-0.316289,0.869574},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{0.646009,-0.316289,1.064839},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{-0.334076,0.471421,1.245655},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{-0.915148,0.471421,0.87451},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{-1.256439,0.471421,0.527417},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{-1.256439,0.471421,-0.527417},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-0.915148,0.471421,-0.87451},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{-0.334076,0.471421,-1.245655},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{0.334076,0.471421,-1.245655},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{0.915148,0.471421,-0.87451},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{1.256439,0.471421,-0.527417},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{1.256439,0.471421,0.527417},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{0.915148,0.471421,0.87451},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{0.334076,0.471421,1.245655},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{-0.123049,1.170794,1.148597},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{-0.711226,1.170794,1.001968},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{-1.146421,1.170794,0.510862},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{-1.30979,1.170794,-0.490006},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{-1.146421,1.170794,-0.510862},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},4,{-0.711226,1.170794,-1.001968},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},6,{-0.123049,1.170794,-1.148597},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{0.465129,1.170794,-1.001968},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},3,{0.900324,1.170794,-0.510862},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},5,{1.063692,1.170794,-0.490006},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{0.900324,1.170794,0.510862},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','VolcanicPlate',{0.501311,0.46789,0.150394},2,{0.465129,1.170794,1.001968},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{-0.154457,1.608227,0.544849},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{-0.424418,1.608227,0.363038},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},5,{-0.586089,1.608227,0.349511},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{-0.586089,1.608227,-0.349511},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{-0.424418,1.608227,-0.363038},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},4,{-0.154457,1.608227,-0.544849},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},6,{0.154457,1.608227,-0.544849},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{0.424418,1.608227,-0.363038},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},3,{0.586089,1.608227,-0.349511},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},3,{0.586089,1.608227,0.349511},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},2,{0.424418,1.608227,0.363038},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','VolcanicPlate',{0.384339,0.46789,0.150394},6,{0.154457,1.608227,0.544849},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'corner','LavaCrown',{0.183814,0.919937,0.183814},5,{-0.091907,1.789026,-0.773369},{1.0,0,0,0,0.985315,0.170748,0,-0.170748,0.985315},'slate',0,0},{'corner','LavaCrown',{0.183814,0.919937,0.183814},5,{0.091907,1.789026,-0.773369},{0,0,1.0,-0.170748,0.985315,0,-0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.183814,0.919937,0.183814},5,{0.091907,1.75764,-0.954485},{-1.0,0,0,0,0.985315,-0.170748,0,-0.170748,-0.985315},'slate',0,0},{'corner','LavaCrown',{0.183814,0.919937,0.183814},5,{-0.091907,1.75764,-0.954485},{0,0,-1.0,0.170748,0.985315,0,0.985315,-0.170748,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.147875,0.183814},5,{-0.705944,1.886083,-0.570406},{0.993346,-0.114536,-0.012073,0.11517,0.987873,0.10413,0,-0.104827,0.99449},'slate',0,0},{'corner','LavaCrown',{0.183814,1.147875,0.183814},5,{-0.523354,1.907253,-0.570406},{0.012073,-0.114536,0.993346,-0.10413,0.987873,0.11517,-0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.147875,0.183814},5,{-0.521134,1.888113,-0.753208},{-0.993346,-0.114536,0.012073,-0.11517,0.987873,-0.10413,0,-0.104827,-0.99449},'slate',0,0},{'corner','LavaCrown',{0.183814,1.147875,0.183814},5,{-0.703725,1.866942,-0.753208},{-0.012073,-0.114536,-0.993346,0.10413,0.987873,-0.11517,0.99449,-0.104827,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.216036,0.183814},4,{-1.030975,1.906389,-0.058136},{0.986179,-0.165643,-0.003716,0.165685,0.985931,0.02212,0,-0.02243,0.999748},'slate',0,0},{'corner','LavaCrown',{0.183814,1.216036,0.183814},4,{-0.849701,1.936844,-0.058136},{0.003716,-0.165643,0.986179,-0.02212,0.985931,0.165685,-0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.216036,0.183814},4,{-0.849017,1.932778,-0.241904},{-0.986179,-0.165643,0.003716,-0.165685,0.985931,-0.02212,0,-0.02243,-0.999748},'slate',0,0},{'corner','LavaCrown',{0.183814,1.216036,0.183814},4,{-1.030293,1.902324,-0.241904},{-0.003716,-0.165643,-0.986179,0.02212,0.985931,-0.165685,0.999748,-0.02243,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.143449,0.183814},4,{-0.916431,1.863069,0.523653},{0.987871,-0.154911,0.010665,0.155278,0.985538,-0.067853,0,0.068686,0.997638},'slate',0,0},{'corner','LavaCrown',{0.183814,1.143449,0.183814},4,{-0.734847,1.891611,0.523653},{-0.010665,-0.154911,0.987871,0.067853,0.985538,0.155278,-0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.143449,0.183814},4,{-0.736806,1.904082,0.340274},{-0.987871,-0.154911,-0.010665,-0.155278,0.985538,0.067853,0,0.068686,-0.997638},'slate',0,0},{'corner','LavaCrown',{0.183814,1.143449,0.183814},4,{-0.91839,1.87554,0.340274},{0.010665,-0.154911,-0.987871,-0.067853,0.985538,-0.155278,0.997638,0.068686,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.138315,0.183814},5,{-0.417449,1.865797,0.902956},{0.998078,-0.061455,0.008037,0.061978,0.989651,-0.12942,0,0.129669,0.991557},'slate',0,0},{'corner','LavaCrown',{0.183814,1.138315,0.183814},5,{-0.233987,1.877189,0.902956},{-0.008037,-0.061455,0.998078,0.12942,0.989651,0.061978,-0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.138315,0.183814},5,{-0.235465,1.900978,0.720694},{-0.998078,-0.061455,-0.008037,-0.061978,0.989651,0.12942,0,0.129669,-0.991557},'slate',0,0},{'corner','LavaCrown',{0.183814,1.138315,0.183814},5,{-0.418926,1.889586,0.720694},{0.008037,-0.061455,-0.998078,-0.12942,0.989651,-0.061978,0.991557,0.129669,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.039674,0.183814},4,{0.233875,1.826731,0.902801},{0.997687,0.067286,-0.00965,-0.067974,0.987581,-0.141644,0,0.141972,0.989871},'slate',0,0},{'corner','LavaCrown',{0.183814,1.039674,0.183814},4,{0.417264,1.814236,0.902801},{0.00965,0.067286,0.997687,0.141644,0.987581,-0.067974,-0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.039674,0.183814},4,{0.419039,1.840272,0.72085},{-0.997687,0.067286,0.00965,0.067974,0.987581,0.141644,0,0.141972,-0.989871},'slate',0,0},{'corner','LavaCrown',{0.183814,1.039674,0.183814},4,{0.23565,1.852767,0.72085},{-0.00965,0.067286,-0.997687,-0.141644,0.987581,0.067974,0.989871,0.141972,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.125849,0.183814},4,{0.73485,1.882809,0.523646},{0.987484,0.157332,-0.011002,-0.157717,0.985079,-0.068887,0,0.06976,0.997564},'slate',0,0},{'corner','LavaCrown',{0.183814,1.125849,0.183814},4,{0.916364,1.853819,0.523646},{0.011002,0.157332,0.987484,0.068887,0.985079,-0.157717,-0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.125849,0.183814},4,{0.918387,1.866481,0.34028},{-0.987484,0.157332,0.011002,0.157717,0.985079,0.068887,0,0.06976,-0.997564},'slate',0,0},{'corner','LavaCrown',{0.183814,1.125849,0.183814},4,{0.736874,1.895471,0.34028},{-0.011002,0.157332,-0.987484,-0.068887,0.985079,0.157717,0.997564,0.06976,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.027443,0.183814},2,{0.850354,1.844105,-0.058145},{0.980581,0.196048,0.005206,-0.196117,0.980235,0.026032,0,-0.026548,0.999648},'slate',0,0},{'corner','LavaCrown',{0.183814,1.027443,0.183814},2,{1.030596,1.808056,-0.058145},{-0.005206,0.196048,0.980581,-0.026032,0.980235,-0.196117,-0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.183814,1.027443,0.183814},2,{1.02964,1.80327,-0.241894},{-0.980581,0.196048,-0.005206,0.196117,0.980235,-0.026032,0,-0.026548,-0.999648},'slate',0,0},{'corner','LavaCrown',{0.183814,1.027443,0.183814},2,{0.849395,1.83932,-0.241894},{0.005206,0.196048,-0.980581,0.026032,0.980235,0.196117,0.999648,-0.026548,0},'slate',0,0},{'corner','LavaCrown',{0.183814,0.977792,0.183814},4,{0.524011,1.824485,-0.570599},{0.990779,0.134459,0.016673,-0.135488,0.983248,0.121927,0,-0.123061,0.992399},'slate',0,0},{'corner','LavaCrown',{0.183814,0.977792,0.183814},4,{0.706131,1.79958,-0.570599},{-0.016673,0.134459,0.990779,-0.121927,0.983248,-0.135488,-0.992399,-0.123061,0},'slate',0,0},{'corner','LavaCrown',{0.183814,0.977792,0.183814},4,{0.703066,1.777169,-0.753016},{-0.990779,0.134459,-0.016673,0.135488,0.983248,-0.121927,0,-0.123061,-0.992399},'slate',0,0},{'corner','LavaCrown',{0.183814,0.977792,0.183814},4,{0.520948,1.802074,-0.753016},{0.016673,0.134459,-0.990779,0.121927,0.983248,0.135488,0.992399,-0.123061,0},'slate',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{-1.498333,1.167209,-1.160814},{0.875578,-0.469574,-0.11342,0.483077,0.851103,0.205574,0,-0.234787,0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{-1.271549,1.292331,-1.160814},{0.11342,-0.469574,0.875578,-0.205574,0.851103,0.483077,-0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{-1.24217,1.239086,-1.412585},{-0.875578,-0.469574,0.11342,-0.483077,0.851103,-0.205574,0,-0.234787,-0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{-1.468955,1.113964,-1.412585},{-0.11342,-0.469574,-0.875578,0.205574,0.851103,-0.483077,0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{-1.075526,-1.318926,-1.263264},{-0.931243,-0.342376,-0.124762,0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{-1.254483,-1.2489,-1.263264},{0.124762,-0.342376,-0.931243,0.318835,-0.874961,0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{-1.230506,-1.18763,-1.443819},{0.931243,-0.342376,0.124762,-0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{-1.05155,-1.257656,-1.443819},{-0.124762,-0.342376,0.931243,-0.318835,-0.874961,-0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.150394,0.735256,0.735256},8,{-1.086175,0.100263,-1.30341},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.133683,0.501311,0.501311},9,{-1.153018,0.100263,-1.420383},{-0.447214,-0.894427,0,0,0,1.0,-0.894427,0.447214,0},'neon',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{1.271549,1.292331,-1.160814},{0.875578,0.469574,0.11342,-0.483077,0.851103,0.205574,0,-0.234787,0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{1.498333,1.167209,-1.160814},{-0.11342,0.469574,0.875578,-0.205574,0.851103,-0.483077,-0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{1.468955,1.113964,-1.412585},{-0.875578,0.469574,-0.11342,0.483077,0.851103,-0.205574,0,-0.234787,-0.972047},'sandstone',0,0},{'corner','IvoryHorn',{0.259011,1.138761,0.259011},7,{1.24217,1.239086,-1.412585},{0.11342,0.469574,-0.875578,0.205574,0.851103,0.483077,0.972047,-0.234787,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{1.254483,-1.2489,-1.263264},{-0.931243,0.342376,0.124762,-0.364399,-0.874961,-0.318835,0,-0.342376,0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{1.075526,-1.318926,-1.263264},{-0.124762,0.342376,-0.931243,0.318835,-0.874961,-0.364399,-0.939563,-0.342376,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{1.05155,-1.257656,-1.443819},{0.931243,0.342376,-0.124762,0.364399,-0.874961,0.318835,0,-0.342376,-0.939563},'sandstone',0,0},{'corner','IvoryTusk',{0.192169,0.878529,0.192169},7,{1.230506,-1.18763,-1.443819},{0.124762,0.342376,0.931243,-0.318835,-0.874961,0.364399,0.939563,-0.342376,0},'sandstone',0,0},{'cylinder','FurnaceRim',{0.150394,0.735256,0.735256},8,{1.086175,0.100263,-1.30341},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'metal',0,0},{'cylinder','Furnace',{0.133683,0.501311,0.501311},9,{1.153018,0.100263,-1.420383},{0.447214,-0.894427,0,0,0,1.0,-0.894427,-0.447214,0},'neon',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},2,{0.300787,-1.253277,-1.236569},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},4,{-0.300787,-0.85223,-1.236569},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},5,{0.300787,-0.45118,-1.236569},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},2,{-0.300787,-0.050131,-1.236569},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},4,{0.300787,0.350919,-1.236569},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},5,{-0.300787,0.751968,-1.236569},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'wedge','MagmaFacet',{0.501311,0.534733,0.233945},2,{0.300787,1.153018,-1.236569},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0}},bounds={3.787558,4.375,3.044175}},
['Skeletal Sabertooth Egg']={palette={{57,37,23},{166,135,91},{211,184,136},{191,161,110},{185,153,103},{202,172,121},{49,29,12},{255,185,16},{237,218,171},{39,26,18}},parts={{'box','EggShell',{0.269395,0.362519,0.890474},1,{-0.673488,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.418751},1,{-0.404093,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.656745},1,{-0.134697,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.728811},1,{0.134697,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.656745},1,{0.404093,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.418751},1,{0.673488,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.890474},1,{0.942883,-1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.07653},1,{-1.212279,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.763739},1,{-0.942883,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.138849},1,{-0.673488,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.355971},1,{-0.404093,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.45735},1,{-0.134697,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.45735},1,{0.134697,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.355971},1,{0.404093,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.138849},1,{0.673488,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.763739},1,{0.942883,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.07653},1,{1.212279,-1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{-1.481671,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{-1.212279,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{-0.942883,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{-0.673488,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{-0.404093,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{-0.134697,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{0.134697,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{0.404093,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{0.673488,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{0.942883,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{1.212279,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{1.481671,-1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{-1.481671,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{-1.212279,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{-0.942883,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{-0.673488,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{-0.404093,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.716704},1,{-0.134697,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{0.134697,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{0.404093,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{0.673488,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{0.942883,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{1.212279,-0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{-1.481671,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{-1.212279,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{-0.942883,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{-0.673488,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{-0.404093,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.716704},1,{-0.134697,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{0.134697,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{0.404093,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{0.673488,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{0.942883,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{1.212279,-0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{-1.481671,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{-1.212279,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{-0.942883,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{-0.673488,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{-0.404093,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.716704},1,{-0.134697,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.67142},1,{0.134697,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.53072},1,{0.404093,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.276978},1,{0.673488,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.864605},1,{0.942883,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.131771},1,{1.212279,-0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{-1.481671,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{-1.212279,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{-0.942883,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{-0.673488,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{-0.404093,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{-0.134697,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{0.134697,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{0.404093,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{0.673488,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{0.942883,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{1.212279,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{1.481671,0.18126,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{-1.481671,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{-1.212279,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{-0.942883,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{-0.673488,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{-0.404093,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{-0.134697,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{0.134697,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{0.404093,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{0.673488,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{0.942883,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{1.212279,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{1.481671,0.543778,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{-1.481671,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{-1.212279,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{-0.942883,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{-0.673488,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{-0.404093,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{-0.134697,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.953367},1,{0.134697,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.869567},1,{0.404093,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.694156},1,{0.673488,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.407195},1,{0.942883,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{1.212279,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.184441},1,{1.481671,0.906299,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.07653},1,{-1.481671,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.763739},1,{-1.212279,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.138849},1,{-0.942883,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.355971},1,{-0.673488,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.45735},1,{-0.404093,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.45735},1,{-0.134697,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.355971},1,{0.134697,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,2.138849},1,{0.404093,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.763739},1,{0.673488,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.07653},1,{0.942883,1.268817,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.956521},1,{-0.942883,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.542345},1,{-0.673488,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.8316},1,{-0.404093,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{-0.134697,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.960287},1,{0.134697,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.8316},1,{0.404093,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,1.542345},1,{0.673488,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.956521},1,{0.942883,1.631336,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.552249},1,{-0.404093,1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.740919},1,{-0.134697,1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.269395,0.362519,0.552249},1,{0.134697,1.993855,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{0.134697,-1.883705,0.900325},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.320214,-1.883705,0.743316},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.658751,-1.883705,0.470143},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.787531,-1.883705,-0.445238},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.658751,-1.883705,-0.470143},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{-0.320214,-1.883705,-0.743316},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{0.134697,-1.883705,-0.900325},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{0.58961,-1.883705,-0.743316},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{0.928148,-1.883705,-0.470143},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{1.056926,-1.883705,-0.445238},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{0.928148,-1.883705,0.470143},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{0.58961,-1.883705,0.743316},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-0.398949,-1.247595,1.470248},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.09285,-1.247595,1.234399},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-1.500412,-1.247595,0.606868},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-1.500412,-1.247595,-0.606868},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-1.09285,-1.247595,-1.234399},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-0.398949,-1.247595,-1.470248},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{0.398949,-1.247595,-1.470248},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{1.09285,-1.247595,-1.234399},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.500412,-1.247595,-0.606868},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.500412,-1.247595,0.606868},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.09285,-1.247595,1.234399},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{0.398949,-1.247595,1.470248},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-0.134697,-0.377705,1.39427},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-0.84284,-0.377705,1.17243},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.366756,-0.377705,0.957207},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.563389,-0.377705,-0.565886},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.366756,-0.377705,-0.957207},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-0.84284,-0.377705,-1.17243},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-0.134697,-0.377705,-1.39427},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{0.573445,-0.377705,-1.17243},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.097361,-0.377705,-0.957207},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.293994,-0.377705,-0.565886},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{1.097361,-0.377705,0.957207},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{0.573445,-0.377705,1.17243},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-0.398949,0.562961,1.470248},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.09285,0.562961,1.234399},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-1.500412,0.562961,0.606868},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-1.500412,0.562961,-0.606868},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-1.09285,0.562961,-1.234399},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-0.398949,0.562961,-1.470248},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{0.398949,0.562961,-1.470248},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{1.09285,0.562961,-1.234399},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.500412,0.562961,-0.606868},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{1.500412,0.562961,0.606868},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{1.09285,0.562961,1.234399},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{0.398949,0.562961,1.470248},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-0.269395,1.398137,1.264594},{-1.0,0,0,0,1.0,0,0,0,-1.0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-0.914231,1.398137,1.103365},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-1.391801,1.398137,0.56317},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{-1.57147,1.398137,-0.538266},{0,0,1.0,0,1.0,0,-1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-1.391801,1.398137,-0.56317},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{-0.914231,1.398137,-1.103365},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{-0.269395,1.398137,-1.264594},{1.0,0,0,0,1.0,0,0,0,1.0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{0.375441,1.398137,-1.103365},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{0.853011,1.398137,-0.56317},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},4,{1.032681,1.398137,-0.538266},{0,0,-1.0,0,1.0,0,1.0,0,0},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},2,{0.853011,1.398137,0.56317},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'sandstone',0,0},{'box','BonePlate',{0.598656,0.558745,0.179597},3,{0.375441,1.398137,1.103365},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{-0.238711,1.920513,0.405924},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.42177,1.920513,0.306925},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.534399,1.920513,0.29077},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{-0.534399,1.920513,-0.29077},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{-0.42177,1.920513,-0.306925},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},3,{-0.238711,1.920513,-0.405924},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{-0.030684,1.920513,-0.405924},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{0.152375,1.920513,-0.306925},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{0.265004,1.920513,-0.29077},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{0.265004,1.920513,0.29077},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},4,{0.152375,1.920513,0.306925},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'sandstone',0,0},{'box','BonePlate',{0.458969,0.558745,0.179597},2,{-0.030684,1.920513,0.405924},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.716864,-1.162087,0.179256},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.589825,-0.983079,0.179256},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.575741,-0.993071,-0.03957},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.70278,-1.172082,-0.03957},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.716864,-0.304014,0.179256},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.589825,-0.125005,0.179256},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.575741,-0.135,-0.03957},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.70278,-0.31401,-0.03957},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.716864,0.554057,0.179256},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.589825,0.733069,0.179256},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.575741,0.723074,-0.03957},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.70278,0.544064,-0.03957},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.716864,1.412131,0.179256},{0.578747,-0.812979,-0.06416,0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.589825,1.59114,0.179256},{0.06416,-0.812979,0.578747,-0.045533,0.576953,0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.575741,1.581145,-0.03957},{-0.578747,-0.812979,0.06416,-0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{-1.70278,1.402136,-0.03957},{-0.06416,-0.812979,-0.578747,0.045533,0.576953,-0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{1.07758,0.458969,0.518835},6,{-0.49888,0.937894,-1.436774},{0.936608,0.304322,-0.173648,-0.309017,0.951057,0,0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.798207,0.359194,0.259417},7,{-0.538791,0.598656,-1.556505},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.598656,0.189575,0.179597},8,{-0.558745,0.618611,-1.716145},{0.956305,0.292372,0,-0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.399103,0.613439,0.399103},5,{-0.957849,0,-1.406841},{-0.980581,-0.19518,-0.019139,0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.399103,0.980244,0.399103},5,{-0.987781,-0.778251,-1.336996},{-0.998053,0.061072,-0.012699,-0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.399103,0.678182,0.399103},5,{-0.768275,-1.506616,-1.107512},{-0.796162,0.559065,-0.231455,-0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{-0.329105,-0.648526,-1.606548},{-0.998581,0.053182,0.002832,-0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{-0.548301,-0.660218,-1.606548},{-0.002832,0.053182,-0.998581,0.053107,-0.997168,-0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{-0.548922,-0.64856,-1.825744},{0.998581,0.053182,-0.002832,0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{-0.329726,-0.63687,-1.825744},{0.002832,0.053182,0.998581,-0.053107,-0.997168,0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.589825,-0.983079,0.179256},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.716864,-1.162087,0.179256},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.70278,-1.172082,-0.03957},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.575741,-0.993071,-0.03957},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.589825,-0.125005,0.179256},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.716864,-0.304014,0.179256},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.70278,-0.31401,-0.03957},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.575741,-0.135,-0.03957},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.589825,0.733069,0.179256},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.716864,0.554057,0.179256},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.70278,0.544064,-0.03957},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.575741,0.723074,-0.03957},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.589825,1.59114,0.179256},{0.578747,0.812979,0.06416,-0.815507,0.576953,0.045533,0,-0.078675,0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.716864,1.412131,0.179256},{-0.06416,0.812979,0.578747,-0.045533,0.576953,-0.815507,-0.9969,-0.078675,0},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.70278,1.402136,-0.03957},{-0.578747,0.812979,-0.06416,0.815507,0.576953,-0.045533,0,-0.078675,-0.9969},'sandstone',0,0},{'corner','BoneThorn',{0.219506,0.760919,0.219506},5,{1.575741,1.581145,-0.03957},{0.06416,0.812979,-0.578747,0.045533,0.576953,0.815507,0.9969,-0.078675,0},'sandstone',0,0},{'box','SkullBrow',{1.07758,0.458969,0.518835},6,{0.49888,0.937894,-1.436774},{0.936608,-0.304322,0.173648,0.309017,0.951057,0,-0.165149,0.05366,0.984808},'sandstone',0,0},{'box','EyeSocket',{0.798207,0.359194,0.259417},7,{0.538791,0.598656,-1.556505},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'slate',0,0},{'box','AmberEye',{0.598656,0.189575,0.179597},8,{0.558745,0.618611,-1.716145},{0.956305,-0.292372,0,0.292372,0.956305,0,0,0,1.0},'neon',0,0},{'box','CheekBone',{0.399103,0.613439,0.399103},5,{0.957849,0,-1.406841},{-0.980581,0.19518,0.019139,-0.196116,-0.9759,-0.095695,0,-0.09759,0.995227},'sandstone',0,0},{'box','CheekBone',{0.399103,0.980244,0.399103},5,{0.987781,-0.778251,-1.336996},{-0.998053,-0.061072,0.012699,0.062378,-0.977153,0.203177,0,0.203574,0.97906},'sandstone',0,0},{'box','CheekBone',{0.399103,0.678182,0.399103},5,{0.768275,-1.506616,-1.107512},{-0.796162,-0.559065,0.231455,0.605083,-0.735612,0.304547,0,0.382518,0.923948},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{0.548301,-0.660218,-1.606548},{-0.998581,-0.053182,-0.002832,0.053258,-0.997168,-0.053107,0,-0.053182,0.998585},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{0.329105,-0.648526,-1.606548},{0.002832,-0.053182,-0.998581,0.053107,-0.997168,0.053258,-0.998585,-0.053182,0},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{0.329726,-0.63687,-1.825744},{0.998581,-0.053182,0.002832,-0.053258,-0.997168,0.053107,0,-0.053182,-0.998585},'sandstone',0,0},{'corner','SaberFang',{0.219506,1.500889,0.219506},9,{0.548922,-0.64856,-1.825744},{-0.002832,-0.053182,0.998581,-0.053107,-0.997168,-0.053258,0.998585,-0.053182,0},'sandstone',0,0},{'wedge','NoseBridge',{0.558745,0.638565,0.458969},6,{0,0.319282,-1.516594},{-1.0,0,0,0,-1.0,0,0,0,1.0},'sandstone',0,0},{'box','NasalCavity',{0.319282,0.279373,0.159642},10,{0,-0.039911,-1.776011},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','LowerJaw',{0.359194,1.1574,0.359194},5,{0,-1.676236,-1.097534},{0,1.0,0,-1.0,0,0,0,0,1.0},'sandstone',0,0},{'corner','InnerEmber',{0.139686,0.762225,0.139686},8,{-0.038351,-1.185242,-1.338964},{0.996729,0.07854,0.019042,-0.080816,0.968666,0.234851,0,-0.235621,0.971845},'neon',0,0},{'corner','InnerEmber',{0.139686,0.762225,0.139686},8,{0.100877,-1.19653,-1.338964},{-0.019042,0.07854,0.996729,-0.234851,0.968666,-0.080816,-0.971845,-0.235621,0},'neon',0,0},{'corner','InnerEmber',{0.139686,0.762225,0.139686},8,{0.098218,-1.229336,-1.474718},{-0.996729,0.07854,-0.019042,0.080816,0.968666,-0.234851,0,-0.235621,-0.971845},'neon',0,0},{'corner','InnerEmber',{0.139686,0.762225,0.139686},8,{-0.041013,-1.218046,-1.474718},{0.019042,0.07854,-0.996729,0.234851,0.968666,0.080816,0.971845,-0.235621,0},'neon',0,0}},bounds={4.193461,4.375,3.581671}},
['Octophant Egg']={palette={{30,34,26},{157,156,119},{194,189,150},{12,15,10},{199,194,156},{101,103,77},{183,255,35},{10,13,9},{29,30,26},{181,255,37}},parts={{'box','EggShell',{0.241464,0.284381,0.804488},1,{-0.72439,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.281752},1,{-0.482926,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.496765},1,{-0.241464,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.561871},1,{0,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.496765},1,{0.241464,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.281752},1,{0.482926,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.804488},1,{0.72439,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.972578},1,{-1.207319,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.593429},1,{-0.965855,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.932316},1,{-0.72439,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.128474},1,{-0.482926,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.220063},1,{-0.241464,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.220063},1,{0,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.128474},1,{0.241464,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.932316},1,{0.482926,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.593429},1,{0.72439,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.972578},1,{0.965855,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.972578},1,{-1.207319,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.593429},1,{-0.965855,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.932316},1,{-0.72439,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.128474},1,{-0.482926,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.220063},1,{-0.241464,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.220063},1,{0,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.128474},1,{0.241464,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.932316},1,{0.482926,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.593429},1,{0.72439,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.972578},1,{0.965855,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{-1.207319,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{-0.965855,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{-0.72439,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{-0.482926,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{-0.241464,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.45437},1,{0,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.413463},1,{0.241464,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.286347},1,{0.482926,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,2.057107},1,{0.72439,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.684555},1,{0.965855,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,1.022486},1,{1.207319,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.498921},1,{-0.241464,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.669374},1,{0,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.498921},1,{0.241464,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.498921},1,{-0.241464,1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.669374},1,{0,1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.241464,0.284381,0.498921},1,{0.241464,1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0,-1.477692,0.811195},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.407112,-1.477692,0.669469},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.709787,-1.477692,0.423225},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.824675,-1.477692,-0.402244},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.709787,-1.477692,-0.423225},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.407112,-1.477692,-0.669469},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0,-1.477692,-0.811195},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.407112,-1.477692,-0.669469},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.709787,-1.477692,-0.423225},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.824675,-1.477692,-0.402244},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.709787,-1.477692,0.423225},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.407112,-1.477692,0.669469},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.419262,-0.978689,1.094113},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.938781,-0.978689,0.822661},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.24457,-0.978689,0.498629},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.24457,-0.978689,-0.498629},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.938781,-0.978689,-0.822661},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-0.419262,-0.978689,-1.094113},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.1778,-0.978689,-1.094113},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.697317,-0.978689,-0.822661},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.003106,-0.978689,-0.498629},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.003106,-0.978689,0.498629},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.697317,-0.978689,0.822661},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.1778,-0.978689,1.094113},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0,-0.296294,1.257445},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.634088,-0.296294,1.057145},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.102921,-0.296294,0.863258},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.278626,-0.296294,-0.511243},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.102921,-0.296294,-0.863258},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.634088,-0.296294,-1.057145},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0,-0.296294,-1.257445},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.634088,-0.296294,-1.057145},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.102921,-0.296294,-0.863258},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.278626,-0.296294,-0.511243},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.102921,-0.296294,0.863258},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.634088,-0.296294,1.057145},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.327905,0.44162,1.236606},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.898297,0.44162,0.868224},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.233459,0.44162,0.523581},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.233459,0.44162,-0.523581},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.898297,0.44162,-0.868224},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-0.327905,0.44162,-1.236606},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.327905,0.44162,-1.236606},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.898297,0.44162,-0.868224},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.233459,0.44162,-0.523581},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.233459,0.44162,0.523581},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.898297,0.44162,0.868224},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.327905,0.44162,1.236606},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0,1.096782,1.257445},{-1.0,0,0,0,1.0,0,0,0,-1.0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.634088,1.096782,1.057145},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.102921,1.096782,0.863258},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.278626,1.096782,-0.511243},{0,0,1.0,0,1.0,0,-1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.102921,1.096782,-0.863258},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.634088,1.096782,-1.057145},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0,1.096782,-1.257445},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.634088,1.096782,-1.057145},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.102921,1.096782,-0.863258},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.278626,1.096782,-0.511243},{0,0,-1.0,0,1.0,0,1.0,0,0},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.102921,1.096782,0.863258},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.634088,1.096782,1.057145},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.092923,1.506568,0.364563},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.256312,1.506568,0.275407},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.356492,1.506568,0.2618},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.356492,1.506568,-0.2618},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.256312,1.506568,-0.275407},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.092923,1.506568,-0.364563},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.092923,1.506568,-0.364563},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.256312,1.506568,-0.275407},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.356492,1.506568,-0.2618},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.356492,1.506568,0.2618},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.256312,1.506568,0.275407},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'concrete',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.092923,1.506568,0.364563},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'concrete',0,0},{'box','CoilRecess',{1.277618,2.504804,0.20173},4,{0,-0.033621,-1.277618},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.594587,0.319405},2,{-0.882564,-1.201969,-1.084294},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.319405,1.899616,0.319405},2,{-1.042268,-0.008405,-1.143131},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.319405,0.607285,0.319405},2,{-0.874159,1.185158,-1.075889},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,-1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,-1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,-0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,-0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,-0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,-0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{-1.008645,1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{-1.008645,1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.20173,1.714697,1.277618},2,{-1.311239,-0.033621,0.084053},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.226945,0.874159,0.504324},7,{-1.428914,0.43708,0.252161},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{-1.428914,-0.806918,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{-1.428914,-0.605187,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{-1.428914,-0.403458,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{-1.428914,-0.20173,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.594587,0.319405},2,{0.882564,-1.201969,-1.084294},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'concrete',0,0},{'box','CageRail',{0.319405,1.899616,0.319405},2,{1.042268,-0.008405,-1.143131},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','CageRail',{0.319405,0.607285,0.319405},2,{0.874159,1.185158,-1.075889},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'concrete',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,-1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,-1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,-0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,-0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,-0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,-0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},5,{1.008645,1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},6,{1.008645,1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.20173,1.714697,1.277618},2,{1.311239,-0.033621,0.084053},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.226945,0.874159,0.504324},7,{1.428914,0.43708,0.252161},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{1.428914,-0.806918,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{1.428914,-0.605187,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{1.428914,-0.403458,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},8,{1.428914,-0.20173,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,0.954011,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,0.710255,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,0.466499,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,0.222742,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,-0.021014,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,-0.264769,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,-0.508525,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,-0.752281,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},7,{0,-0.996038,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{1.52978,0.319405,0.302594},2,{0,-1.512969,-1.075889},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{-0.504324,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{0,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{0.504324,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{1.52978,0.319405,0.302594},2,{0,1.512969,-1.075889},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{-0.504324,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{0,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},6,{0.504324,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.268971,0.975024,0.975024},9,{0,1.849182,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.470701,0.470701,0.470701},7,{0,2.168588,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.134486,0.773295,0.773295},2,{0,2.45437,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.20173,0.092459,0.20173},10,{0,2.555236,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},7,{-0.369836,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},7,{0,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},7,{0.369836,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={3.126801,4.375,2.851682}},
['Mecha Scrambler Egg']={palette={{21,23,21},{55,58,53},{66,70,62},{43,46,41},{12,15,10},{76,80,71},{137,142,122},{236,250,56},{10,13,9},{29,30,26},{231,248,70}},parts={{'box','EggShell',{0.221342,0.284381,0.74002},1,{-0.774695,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.179042},1,{-0.553355,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.376824},1,{-0.332013,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.436714},1,{-0.11067,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.376824},1,{0.11067,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.179042},1,{0.332013,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.74002},1,{0.553355,-1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{-1.21738,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{-0.996038,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{-0.774695,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{-0.553355,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{-0.332013,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.257693},1,{-0.11067,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{0.11067,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{0.332013,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{0.553355,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{0.774695,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{0.996038,-1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{-1.21738,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{-0.996038,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{-0.774695,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{-0.553355,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{-0.332013,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.257693},1,{-0.11067,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{0.11067,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{0.332013,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{0.553355,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{0.774695,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{0.996038,-0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,-0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,-0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,-0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,0.142191,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,0.426574,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{-1.21738,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{-0.996038,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{-0.774695,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{-0.553355,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{-0.332013,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{-0.11067,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.45437},1,{0.11067,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.38473},1,{0.332013,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.238956},1,{0.553355,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.000478},1,{0.774695,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.62908},1,{0.996038,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.984319},1,{1.21738,0.710955,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{-0.996038,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{-0.774695,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{-0.553355,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{-0.332013,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{-0.11067,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.257693},1,{0.11067,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.220063},1,{0.332013,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,2.103133},1,{0.553355,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.892264},1,{0.774695,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,1.549564},1,{0.996038,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.94055},1,{1.21738,0.995337,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.45894},1,{-0.332013,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.615734},1,{-0.11067,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.45894},1,{0.11067,1.279719,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.355494},1,{-0.11067,1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','OriginalShellCell',{0.221342,0.284381,0.355494},1,{0.11067,1.564101,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.11067,-1.477692,0.748615},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.484682,-1.477692,0.618112},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.763126,-1.477692,0.390993},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{-0.869144,-1.477692,-0.370011},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{-0.763126,-1.477692,-0.390993},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.484682,-1.477692,-0.618112},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{-0.11067,-1.477692,-0.748615},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.26334,-1.477692,-0.618112},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.541786,-1.477692,-0.390993},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.647804,-1.477692,-0.370011},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.541786,-1.477692,0.390993},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.26334,-1.477692,0.618112},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.41165,-0.978689,1.139906},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.935408,-0.978689,0.80073},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.243644,-0.978689,0.482614},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.243644,-0.978689,-0.482614},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.935408,-0.978689,-0.80073},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-0.41165,-0.978689,-1.139906},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.190307,-0.978689,-1.139906},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.714066,-0.978689,-0.80073},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.022304,-0.978689,-0.482614},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{1.022304,-0.978689,0.482614},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.714066,-0.978689,0.80073},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.190307,-0.978689,1.139906},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0,-0.296294,1.257445},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.634088,-0.296294,1.14807},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.102921,-0.296294,0.835522},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.278626,-0.296294,-0.49216},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-1.102921,-0.296294,-0.835522},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.634088,-0.296294,-1.14807},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0,-0.296294,-1.257445},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.634088,-0.296294,-1.14807},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.102921,-0.296294,-0.835522},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.278626,-0.296294,-0.49216},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.102921,-0.296294,0.835522},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.634088,-0.296294,1.14807},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.327905,0.44162,1.22224},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.898297,0.44162,1.026186},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-1.233459,0.44162,0.504499},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-1.233459,0.44162,-0.504499},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.898297,0.44162,-1.026186},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{-0.327905,0.44162,-1.22224},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.327905,0.44162,-1.22224},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.898297,0.44162,-1.026186},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.233459,0.44162,-0.504499},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{1.233459,0.44162,0.504499},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.898297,0.44162,1.026186},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.327905,0.44162,1.22224},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{0.11067,1.096782,1.159106},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-0.471401,1.096782,0.974724},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.902157,1.096782,0.795763},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{-1.063925,1.096782,-0.470275},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.902157,1.096782,-0.795763},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{-0.471401,1.096782,-0.974724},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{0.11067,1.096782,-1.159106},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.692744,1.096782,-0.974724},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},2,{1.1235,1.096782,-0.795763},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{1.285268,1.096782,-0.470275},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},3,{1.1235,1.096782,0.795763},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','ArmorPlate',{0.504324,0.470701,0.151296},4,{0.692744,1.096782,0.974724},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.058654,1.506568,0.207624},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{-0.162689,1.506568,0.203694},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{-0.228601,1.506568,0.190086},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.228601,1.506568,-0.190086},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{-0.162689,1.506568,-0.203694},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{-0.058654,1.506568,-0.207624},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{0.058654,1.506568,-0.207624},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.162689,1.506568,-0.203694},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.228601,1.506568,-0.190086},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},4,{0.228601,1.506568,0.190086},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},3,{0.162689,1.506568,0.203694},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','ArmorPlate',{0.386647,0.470701,0.151296},2,{0.058654,1.506568,0.207624},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','CoilRecess',{1.277618,2.504804,0.20173},5,{0,-0.033621,-1.277618},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.594587,0.319405},2,{-0.882564,-1.201969,-1.084294},{0.836461,-0.537186,-0.10846,0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.319405,1.899616,0.319405},2,{-1.042268,-0.008405,-1.143131},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.607285,0.319405},2,{-0.874159,1.185158,-1.075889},{0.823213,0.553637,-0.125727,-0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,-1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,-1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,-0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,-0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,-0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,-0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{-1.008645,1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{-1.008645,1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.20173,1.714697,1.277618},2,{-1.311239,-0.033621,0.084053},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.226945,0.874159,0.504324},8,{-1.428914,0.43708,0.252161},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{-1.428914,-0.806918,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{-1.428914,-0.605187,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{-1.428914,-0.403458,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{-1.428914,-0.20173,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.594587,0.319405},2,{0.882564,-1.201969,-1.084294},{0.836461,0.537186,0.10846,-0.548026,0.819916,0.165545,0,-0.197911,0.98022},'metal',0,0},{'box','CageRail',{0.319405,1.899616,0.319405},2,{1.042268,-0.008405,-1.143131},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','CageRail',{0.319405,0.607285,0.319405},2,{0.874159,1.185158,-1.075889},{0.823213,-0.553637,0.125727,0.567733,0.802773,-0.182304,0,0.221455,0.975171},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,-1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,-1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,-0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,-0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,-0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,-0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,0.218541,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,0.218541,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,0.65562,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,0.65562,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','RailClamp',{0.453891,0.218541,0.369836},6,{1.008645,1.0927,-1.227186},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','RailRivet',{0.04707,0.117675,0.117675},7,{1.008645,1.0927,-1.43732},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','SideArmor',{0.20173,1.714697,1.277618},2,{1.311239,-0.033621,0.084053},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','PowerWindow',{0.226945,0.874159,0.504324},8,{1.428914,0.43708,0.252161},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{1.428914,-0.806918,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{1.428914,-0.605187,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{1.428914,-0.403458,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','VentSlot',{0.268971,0.092459,0.521132},9,{1.428914,-0.20173,-0.302594},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,0.954011,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,0.710255,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,0.466499,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,0.222742,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,-0.021014,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,-0.264769,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,-0.508525,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,-0.752281,-1.462536},{-0.312988,-0.949757,0,0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','EnergyCoil',{0.075649,0.778802,0.075649},8,{0,-0.996038,-1.462536},{-0.312988,0.949757,0,-0.949757,-0.312988,0,0,0,1.0},'neon',0,0},{'box','CageCrossbar',{1.52978,0.319405,0.302594},2,{0,-1.512969,-1.075889},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{-0.504324,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{0,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{0.504324,-1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'box','CageCrossbar',{1.52978,0.319405,0.302594},2,{0,1.512969,-1.075889},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{-0.504324,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{0,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','CrossbarBolt',{0.042026,0.097504,0.097504},7,{0.504324,1.512969,-1.260806},{0,-1.0,0,0,0,1.0,-1.0,0,0},'metal',0,0},{'cylinder','BatteryFoot',{0.268971,0.975024,0.975024},10,{0,1.849182,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','Battery',{0.470701,0.470701,0.470701},8,{0,2.168588,0},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'cylinder','BatteryCap',{0.134486,0.773295,0.773295},2,{0,2.45437,0},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','BatteryLatch',{0.20173,0.092459,0.20173},11,{0,2.555236,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},8,{-0.369836,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},8,{0,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BaseIndicator',{0.184919,0.168107,0.067244},8,{0.369836,-1.689481,-0.924593},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0}},bounds={3.126801,4.375,2.837315}},
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
    local bodyMin,bodyMax=math.huge,-math.huge
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
        if item[2]=='EggShell' or item[2]=='OriginalShellCell' then
            bodyMin=math.min(bodyMin,pos[2]-size[2]/2)
            bodyMax=math.max(bodyMax,pos[2]+size[2]/2)
        end
        if i%40==0 then task.wait() end
    end
    -- Wings, horns and halos must not make the main egg look undersized.
    -- Every freshly built egg grows at least 20%, with a 4.25-stud minimum
    -- shell height. Scale the entire model once to preserve all its details.
    local bodyHeight=bodyMax-bodyMin
    if bodyHeight>0 and bodyHeight<math.huge then
        local displayScale=math.max(1.20,4.25/bodyHeight)
        m:ScaleTo(displayScale)
        m:SetAttribute('SAE_DISPLAY_SCALE',displayScale)
        m:SetAttribute('SAE_BODY_HEIGHT',bodyHeight*displayScale)
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
label(head,'Larger bodies • consistent egg sizing',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
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