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

local VOX={
['Unicorn Egg']={26,40,13,{{4,3,6,0},{3,2,2,0},{5,3,3,0},{15,2,2,0},{20,19,20,0},{227,100,134,0},{241,152,178,1},{193,153,159,0},{239,201,210,0},{209,184,192,0},{249,221,233,0},{252,243,248,0},{72,185,227,1},{253,241,138,1},{84,53,62,0},{25,65,79,0},{89,84,48,0}},{272695309,4836098062,9399500815,13426032656,4567662609,17452564555,4567728204,22288728142,13426032721,4567662674,272695433,8862695562,22016032908,22296985745,13426032786,4567662739,272695495,4567662792,9131065545,26311000266,22301180108,26311000269,22825533647,22284402898,13426032851,4567662804,8862630150,4836098311,22015967496,26315129097,22297051402,22829728013,30878597394,13426032916,8862630165,4567728453,26315194695,23362339151,26323517776,22292791636,13426032981,4567662934,8866824580,4836098437,26327712134,22825468297,26315129233,31700615570,22825468307,22288597397,13426033046,4567662999,8862630339,22284403141,26310934983,22829662664,23358144973,26323583438,30882726358,13426033111,4567663064,4571857411,26319389188,22821274119,26323517961,23089709578,26315260427,36528259601,26315260435,30882726423,13426033176,4567663129,26315129415,26319323722,37056741968,30882726488,9131065945,8871019139,26315129480,26310935179,36784177804,32220709523,40278098580,4597023385,26310935236,35182019269,36511482571,37329371854,26310935247,39489438423,34909258500,35983131400,45122454283,37056742157,37585224463,46183547664,40290616082,39481049880,4571857731,46183547727,45910917969,36515677012,40013792085,8862630851,43499586500,45646742477,49404838864,40538014676,4576052227,50201691151,52084933652,32493339727,52089128021,39732708438,541131864,9131066500,17989436549,48322905222,23106684043,31415665808,52084999318,4567663768,17452565700,4571858117,48054404294,23093904586,272696536,4840293638,48054338823,22305703183,39200163093,8866825496,272696645,52080739655,48322643272,56405132617,272696710,4576052615,56409261448,26315261333,272696728,56375838155,23093904846,4567664088,272696838,56379966987,52101711373,26315195925,4836099607,17452566040,4571858502,56405067335,52093322830,276891223,56375707275,52093322892,52089128591,22284600976,4567729812,8862631574,4571858629,9131067078,52084934347,22284535504,13426034387,4567664340,56396678918,4836099856,22016034577,4567664403,272697156,9131067205,56375707465,4567729994,4571858766,272762703,8862631761,272697170,17452566355,4567664516,56396679045,9131067273,4567664522,4567730060,8862697411,9131067336,4567664585,4571858947,56392484868,4567664648,4576053314,4571859015,8862632008,56388290691,4571859078,272697537,4571859201,56388290818,4836100357,272697606,17452566848,4571859268,272697669,4836100480,56379902337,4571859331,9399503296,4567666765,8862634123,4567667014,8862634436,4592833177,4567667909,4567668103,4567668231,4567668372,4567668554,4567668558,8862635972,4567668803,4567668807,4567668870,4567668930,4567669057,4567669060,4567669123,21747540109,60402245835,60670746829,60406440201,60406505799,61220135248,60419023238,61211746705,60939116999,61757071822,60410634757,61220135433,61480313355,60943442451,60943311431,61484376650,61211746952,61744423563,4588642969,62818165455,43231093701,65506714644,64974038101,64701408406,38931670293,64697214279,69021607241,68992181640,60410701205,69529183691,69017347592,69533312523,64713991693,64709797454,69260617355,64705603212,64701408911,69008959175,64697214667,69008959302,68992182089,69004765125,69004765252,69000571075,68996376898,68996376961,21751738447,21747544206,21747544208,21755932881,21760192779,30341673234,60402250057,21755933002,30337478995,60402315655,21751738772,60414833094,21747544533,30341673494,30341673559,30341673624,34645095110,38948385495,4580258521,38939996952,43231032262,47517480135,47517414664,21764650255,38931608853,68996445513,60406445461,69008963018,69008963081,64709801485,64705607246,21747807823,64701413004,64697218703,21747676816,69000574664,68996380487,68992186310,68992186437,21747548303,60402254030,21751742737,21756002635,30337483090,21751742858,21747548628,30337483350,30337483415,34645033671,38944195287,30337483480,38935806744,4571874073,43230970823,64697222229,47517549703,47517418696,47517353225,21760460047,68992255305,68992189834,69000578570,64705611277,21747811855,64701417038,21747746383,64697222796,68992190153,21751746767,21755941134,21747552528,21751746893,21747552593,21751812491,21747618249,21747552723,21751747080,60406518291,60402258517,38940005079,38931616536,38935876437,43230909384,38927422485,47517488264,30341878928,47517357257,21760398607,68992193866,68992259532,68992259595,64701421069,21747750415,68992194124,64697226830,21747556750,60410651024,60402262481,30350074386,60402262611,38935814804,38940009173,34640847626,38944269074,38931620630,43230782410,38927426642,47517361290,21751948427,30341751952,21752079628,21747819917,21747557838,21747560847,60406460880,60406460941,60402332235,30345884242,38931624660,38940078866,38931624725,38927430674,21747758219,30341690512,21747692748,21751952653,21747561870,60414853583,60410659342,60402270736,60402270797,34645049937,30341694098,30337499859,43243373324,38927565586,38931694418,34632467284,47521629136,38927434706,47517369424,21747696780,21747631309,21747631374,21747565902,60410663439,60406469198,34636665485,34640859793,30337503954,38931698450,38927438738,47517438928,47517373456,30337504335,21747635341,21747569870,60406473295,60402279054,34636669584,34636669649,38931637010,43230798798,47517377488,60402283151,34632479440,34632479505,43222414161,43226612496}},
['Kitsune Egg']={25,28,13,{{183,178,147,0},{204,78,181,1},{194,58,173,1},{217,57,195,0},{190,185,152,0},{63,62,67,0},{225,104,211,1},{195,190,157,0},{198,192,161,0},{199,193,165,0},{195,186,160,0},{205,198,169,0},{68,20,61,0},{71,27,63,0},{79,36,74,0}},{285605898,281149512,281083984,4567662726,276889735,276889745,8862630034,13182763204,8862630085,541130950,541130962,8862630099,13182763220,13161791746,8862630147,4836098309,17993695494,1078001928,22557098249,18811650315,22825533710,17989566736,4836098323,8862630165,13161791766,4580245825,13426032963,9139454277,22825468232,22825468240,18257936721,9139454291,13426032981,4584440151,4567662976,9131131266,9139454342,18526306695,23089709449,18803130762,19071566222,23089709455,18526306705,9139454354,9131131285,26076053952,13979746754,23089709511,18794807752,18794807759,23089709521,13711311317,26071859672,14499774981,18794742279,31960662536,19063177737,19331613199,31688098320,14499774995,9131065921,4840292933,31952339526,32221102665,31948079698,4840292947,14499775105,4836098692,36511482514,4836098708,14231339671,26063471297,9135325892,4836098758,32216515271,32753713865,36511613647,4836098770,9131131603,26063471319,13694468866,9131066115,13715440390,9131066119,40806449928,32485081865,36511744780,9131066129,14235599634,9131131668,13694468886,4571857730,13430227779,8879407940,14231339845,13975487303,4836098888,40806515529,36511744843,14239794000,9139454804,13430227797,8866825046,9131066245,14503969672,4840293257,40542405514,36511482766,9131066255,13707051922,9131066259,8862630851,13694469061,44832981966,4836099023,13694469075,8862630869,9135260677,4836099080,31679710217,40538014731,4836164620,31683904526,4836099088,13962904593,9135260691,4571857940,4836099143,35706307656,4836099147,15036646476,4844487757,35446129744,4836099153,34632434820,4836164741,35173631111,40273773706,14768211083,26310935692,4836099214,35710370959,35173500049,4571923602,34636629189,4836099270,4836099275,14768211148,35974612174,9131066630,4836295943,40277968139,35974677772,4836295950,9131066642,13157598483,13157795142,4840293706,31679645004,40269579597,4840293710,13161989455,8862631302,13426165127,48331097484,13157664199,47790097865,48058402254,38931662287,13157598673,17452566023,47517337096,38927402513,8862631497,13426296394,4567664207,4567664265,13426099850,26046760588,13157598862,272762570,285478923,281088074,281088079,276959368,276893840,272699591,272699601,13178573060,13178573076,13157601602,13157601622,4576055681,26071863744,4576055767,26063475224,26055086785,26055086807,4567667522,8871023428,8862634838,4571862162,13157733703,13161928015,13157602760,38927472079,38927406607,26042570380,272701131,26042504908,285351948,281092171,281092174,276897930,276897935,272769224,272703696,13174382916,51820699973,51820699987,13174382932,51812376962,52357570950,52357570962,51812311445,56111473089,60423217664,56111473175,52349182529,56916779589,56916779603,60414829144,56912585348,56912585364,60410634945,52353442500,57181020870,57181020882,52617683667,60410634967,52080747267,52886053639,52886053649,52080812820,13157606211,51816506180,57181021000,51816506196,13157606229,52080747397,56916779913,52886053775,52080747411,56912585679,56644150280,57181086732,56644150288,56375714887,57181021259,56920974413,56375714897,56107279494,61475988620,56912585870,56912585931,56107476231,56107476238,13161866568,56648344906,56648344910,13161866575,47517476297,38927410639,47517410826,13157738059,13157607051,60402247308,281161804,276902027,276902030,272707786,272707791,17452577040,17452642630,13170192772,51816509829,51816509843,13170192788,13174387157,56107282945,13170192918,60414833216,56107283031,60406444696,60406444737,60406444759,13170193158,51812315972,51812315988,13161804690,34632578183,34632512712,56107414792,56107414798,13161805129,13161805135,47517414858,47517349326,47517349387,13157611084,276971660,272711883,272711886,21751742730,21747548489,13166002628,51812319685,51812319699,13166002644,13166068226,13170197013,13161808470,60406448768,60402254529,13157614275,60402254551,13166002950,51812320020,13166003015,13157614482,34632451152,34632516744,34632451273,56107353353,56107353358,47521613196,47517353419,47517353484,272781516,21751746830,21747552586,21747552591,21747552648,21747552656,51816518086,51816518098,13161812484,13161812500,13157683778,13161812565,13157618307,51812389572,51812324101,13161812742,13157683986,13161812807,13157749584,13157684112,13157618640,34632520777,34632455305,56107291914,56107291918,47517422988,47517357516,17465237836,17460978059,17456783818,17452589519,30345880080,30341685841,56107295365,56107295379,13157622608,56107295625,56107295821,34632459532,17461047692,17456787915,17456787918,17452593674,30345884232,30341689936,30337561222,30337495697,38927627146,38927561675,56107299852,17456857548,17452597771,17452597774,30342021706,30337565320,30337499792,30337499848,34632532687,34632663820,38927434570,34632663883,38927565707,38927434700,17452667404,30341894731,30337503882,30337503887,34632471247,30337569546,34632602380,34632602443,38927438732,30345962060,30345896587,30341702286,30337508042,34632540940,34632475468,30341771916,30337512139,34632479500,30337516236}},
['Night Flame Egg']={28,27,9,{{72,45,13,0},{38,66,8,0},{119,76,22,0},{57,99,15,0},{100,67,19,0},{70,73,18,0},{151,97,30,0},{244,146,13,1},{83,126,32,0},{213,141,41,0},{178,124,39,0},{212,184,93,1},{85,51,5,0},{74,64,33,0}},{277217291,276889674,272695377,4580245586,272695433,9399632011,1354825870,9135390863,4576051347,13157662920,5104533706,9668001995,1619067085,17452630279,13694468361,9668002058,1619067148,1614872847,9668002064,4571922708,8862761287,22552838474,1350631755,27384742221,10204873039,22284534097,272695686,9139519879,5373034889,30618681740,1614872976,22821339537,809632147,22015967637,4567662998,21747532229,9135260102,9936372169,5909840330,30614290891,30618485200,1346503121,18257871315,9135260116,541131221,13157597654,34632434181,18530566665,30605902353,9403761170,34636628501,21747532357,4836164166,17993630280,1359020625,22015967828,21747532422,4836098695,18257871497,1350697610,40269578892,30606033549,1082196626,22292791955,4836098708,21747532437,4567663302,9135325895,1082196681,27384677068,30605968077,44568740559,1635844816,22015967956,272696021,8862630662,1346437898,23089775371,44833047309,5641405202,4571923220,13157597974,17452630854,809567048,5389747017,22821339978,18807325516,1883308877,19067372366,1619067727,13962969937,5104534355,43222500229,5385552776,5909840778,23089709963,19335807885,18798936977,14231339922,1078002579,5104534420,34900870037,38927401878,38944310212,44027675591,23089710026,18803131339,10213262286,1614873554,22821274579,38956827604,47785771990,38944179159,39221003271,1619067914,10477437965,1614873617,23089710098,5641405459,38956762134,38927402051,10204808268,10204808272,26331907153,14499775570,40269579347,38927402072,47517336707,38944179336,27120895113,27120436370,44296111251,47785772184,38931596441,38927467714,38939985107,39195837656,47517467906,38940050693,38939985161,26583958794,39468467474,47517467927,38927598913,38927598935,38927467905,47785772419,38935790980,43490805130,26311263627,47521531282,39200032151,47785772440,38927467929,47517337025,38931662274,47517337031,38927402442,43222369739,34632435148,26310936013,47517533646,38927402453,38931662296,47517337050,38931596801,47517337093,47517402637,47517337111,38931596826,38931596864,38927402562,47517337165,38927402585,38931596891,277090316,272699467,272699472,272699530,4576055442,13157601481,17452568840,4567666963,8862699848,4567667028,4567733012,17452569415,4567667540,43222438790,38956831685,38952637396,38952571926,38935794756,38935794775,38939989128,38927406275,38935794899,47517406467,38935794953,47517406487,38927537474,38927537495,38935795074,38931600772,47517341074,38927406485,38935795097,38927406531,38927406533,47517341134,38927406552,276963341,272703564,272703567,8866898063,8862638289,4567671058,8862638409,8871027080,52630397324,8866832839,52626006475,52630200784,8862638548,52349182481,4567671367,52617749133,8866833096,52886119117,4567671572,43222377351,38952575942,38948447188,38948381703,38948381765,26059285585,38944187478,38935798920,38931604631,38927410372,38931604691,56107279620,38931604745,56107279639,38927476035,38927410517,38927476055,56107279747,38927410564,26042574221,38927410583,56107279768,272773197,8862707852,8866836623,8862642384,21747609937,272707987,8866836936,8866837010,17452577352,21747544851,38944191444,38944191495,38939997254,26055095377,38939997269,38931608712,38935803030,38935803077,38927414483,38927414537,26042905866,38927414546,38927414596,26042578253,38927414615,8862646413,8862646476,8862646479,8862646539,8862646544,21747548497,4567679370,13157614417,4580262793,4576068552,38935807047,26050905169,38931612756,38927418504,38931612821,38927418566,26042582285,276910286,272716171,21747552657,272716241,17456779786,276910731,272716561,21747553099,4576072649,4567684168,26046714961,26042979465,26042520722,26042586317,26042523982,51816653197,51820716492,51820782093,43222393615,17460978572,272720783,17456784331,8866915278,276915152,8862655566,51816526222,51820720589,43222397710,17452594062,17452594124,8862725070,8862725133,17452598221,8862663630}},
['Archangel Egg']={34,25,9,{{205,177,116,1},{211,169,82,0},{220,171,61,0},{252,248,123,1},{207,205,204,0},{216,211,206,0},{223,219,210,0},{224,219,217,0},{218,208,191,0},{224,216,201,0},{227,223,224,0},{201,196,192,0},{88,87,43,0},{72,62,41,0}},{272695309,4567728143,9147842577,272695314,4567662665,4567859276,9424666704,9131065426,4567662675,272695380,4567662679,8879407241,4567662732,9135259789,4836098190,9437249679,13480558738,9131065491,4836098196,272695445,4576051350,9139454103,4567662744,276889802,4571857099,9147842764,9189785806,13467975891,9147908308,8871018712,276889864,5381357837,272695577,17452564806,285278535,5108728138,9424666955,5909840209,8904573270,5372969303,4567728473,17456759173,4836098440,10473243025,9168814487,5104599448,541131162,21747532187,285278664,5108728265,9672131018,10209001933,13434421713,5121311192,9147843033,4836164058,21747532252,17452696065,272761349,5645599244,13426033168,13426098708,5104534042,281149979,17452630593,26042499651,17452630597,541131337,5104534090,5914034765,10221584976,13426033236,9156231765,541131354,272695901,4567663198,272695903,30345855618,541131395,30337467012,26315129481,9399501450,9416278668,6446711441,9684714132,8866824858,4836098717,276890270,30614291139,541131460,30341661381,21747532486,26042499784,4840293066,541131469,9684714193,276890333,30337467137,30882726660,30341661446,4571857673,5104534283,9676325645,541131535,9143649048,4567663385,272696092,34632434463,21747598145,35169305413,26042499911,9135326026,5117117263,272696153,34632500059,26042631005,17452630912,22024422274,26847806341,4836164486,8866890632,545325968,9936372627,4567794585,39464338332,26042565534,17452565441,35437740996,44296111045,5372969926,8875213767,8862630858,4567663563,276890572,4840293325,4580246483,541131732,8871085017,5104534491,39732708316,26579370973,47525790686,4571923456,22552839172,39732708357,9399501830,8866825224,4571857929,5104665616,4567729172,4567729175,9399567387,48322642973,47517336608,4576052290,22284403779,4840293444,8871019589,4836099142,272696397,9131131983,4836164689,4567663700,8866825307,541131868,9135260765,4571923552,4567663745,4836099203,8862631046,4567729294,8862762128,8862631066,9131066524,4571923614,8862696643,272696528,272696540,4567663837,13165987083,272696589,4567663888,272696593,272696598,13158253900,13157664140,4567664015,9131132304,13157860754,4567729616,272696848,4567666704,4567666765,4567666767,4571861206,8871022857,272699658,4567666955,8866828568,272699720,8900383062,4567667033,276894152,276894235,17452569154,272699996,8862634650,30337471234,30337471237,21747536706,30337471302,34632438620,26042504029,17452569473,8866829193,4567667609,4567667611,26042504094,8866894791,272700364,4576056275,8866894809,47525729246,4571862017,4567667732,47521535007,4571862082,8866829381,8862635079,8862700634,4567667808,8862635152,4567733406,13157602637,13157668176,8875221073,51866837138,8862703821,51854254291,8879415508,8875221260,8912969998,8875221269,4567671062,8862638359,8866832713,8896192854,8862638424,8896192919,53162877393,8875221465,4567671258,53422924304,52617683476,53154488916,8883610197,56107278938,4567671498,56912585421,30341669635,56912585487,8862638923,21747606402,4567671686,56648344464,8862639000,21751735235,8866833351,4567671757,4571866067,56107279316,8862639065,21747540994,8862639130,47521539102,4567671874,4567671876,8862639173,8862639184,56107279452,8862639197,47517344863,8871096464,8896196815,51862646994,8908779790,51850064147,8875225364,8871031116,9407902032,8871096661,4567675274,8883614091,8883614103,4584452504,8871031257,8879419926,8879419989,8875225740,30341673796,4576064335,21747544963,4567675859,21747545091,4567675920,8862643228,8866906320,8892006671,51854262546,4571873613,8900395342,51845874003,8871035220,8866840972,8866972053,8866841035,4576068056,8871100950,8875229781,8866841228,8875229844,8875229905,8862646998,8866841357,4571874127,30337483652,8862716176,8887816527,51845878098,4567683469,8892010894,51841683859,8866845076,8862650828,8862781909,4567683596,8866910742,8871039573,8871039636,8862651030,8871039697,4567683919,56107291536,8866849168,8879432143,51829105106,8862654990,51812393491,8875237968,51820716627,8862655061,8862655124,8862655185,8862659024,8862659087,51820720658,8871047760,51816526419,51816530449,51812336210}},
['World Burner Egg']={40,21,8,{{71,32,39,0},{41,22,24,0},{58,29,34,0},{89,72,73,0},{69,49,52,0},{39,28,30,0},{47,24,27,0},{39,21,23,0},{192,105,114,1},{230,136,138,1},{35,19,21,0},{206,85,89,1},{233,98,101,1},{67,37,40,0},{80,48,48,0},{72,30,31,0},{82,34,35,0}},{273088530,4567859281,9936371797,13962903638,17989435479,9131065432,4567662681,21747531866,8862630032,541130897,17989435538,13963034771,26847871126,17989435544,13157728409,26042499278,30337466575,17721000144,13694533841,18526306515,5914099924,27388870870,34900869335,5104599256,13157728474,4567662862,13426163983,9936371986,27384676627,39208419607,27116241176,5372969241,26847805722,17989435675,13161857308,17452564808,30337466702,13430227279,26579370320,9667936593,27116241234,5914034515,44564545876,27653112149,39195836758,39195836760,44296110425,31142773082,26583564635,17452564871,26080248200,17452564874,17452564876,8862630285,43490804110,13967098256,18526306705,10204807570,6182535572,27393065366,5641470360,26847805850,9131065756,13161791901,17452564897,4567663047,4571857354,272826827,5108728270,26847805903,14499840465,10473243091,5909840344,31679644121,9936372186,13698728411,17452564958,8862630367,4567663073,26046693895,26042499593,541196811,13694468621,5641470479,1619067409,14499971602,27384742423,14231405081,545391133,4836098591,17452565024,26071859745,310444614,562102857,26587759178,47785771595,1078067788,9667936846,31142773327,9936372304,1614938706,14499840596,18794807894,14231405144,1078067802,18526306908,26587759199,562102880,17452565125,9412084359,52080738955,47785771660,1078002317,5104534158,43494998671,26847806096,44031869585,31411274386,5641601684,31146967704,5104599705,31142773403,1078067868,52080738974,306250402,17452565188,557908677,26067665611,34900869836,43226628813,30874338000,31411208914,5373100755,26847806166,5641405143,30605968089,43230757595,30874338012,1078002397,47785771742,293667555,13157597952,272696068,817955594,26050888460,30337467151,22015968016,5104534289,9667937042,809894675,8862696217,43490804508,26050954013,817955615,26310935360,13157598017,17452565316,13157598029,43226563408,30605902673,4576052050,541393747,9131066200,4576052057,30337467228,21747532647,5108728704,272892801,27120436103,4836098961,8862630803,272892820,5104534424,21747532698,17452630948,281084838,26059277223,9403696065,545391554,47785771972,47785771977,26055082954,21747532748,4567663568,30605902801,21747532759,30605902808,272696282,21747532765,26050888670,9399501791,47785772000,541197284,26050888704,52084999172,549520391,52084999176,51812369424,43226563608,38935790617,13157598234,26050888735,52084999200,52084933668,813761573,26046694465,809567298,9399501891,4567663696,38931596369,17452565594,52080739427,9131066470,26046825602,39195837573,39195837576,26046694537,43222369424,38927402130,4567663768,26046694560,39195837601,541131939,26042631332,26042696901,26042500305,4567663826,21747533015,30605903064,13157598425,26042762465,21747533074,21747533080,272961555,4567797842,13157666969,13157667034,13161795868,272765388,13157601757,26071863816,4567667210,26042503751,306254470,26063475361,26059281099,43222438605,43226567387,302060258,26046698252,43222373133,8862634777,26046763805,4571861842,272700289,272700292,272700311,4571861913,26046698398,281088931,26055087015,26050892746,276894694,26046698496,38931600409,26046698527,26042504257,26042635394,26042504329,38927406225,26042504352,26042569892,272834580,4567736403,56644149463,13157605594,13157671184,61220135191,61475987798,61207552344,13157605775,272704012,276898333,26067673672,64697213515,272704094,289481353,69260616331,65234084492,43222377103,69260616350,289481376,297870022,26050896587,56375714508,43222377165,30337475289,43222377179,65234084574,26059285217,26042508044,26042573597,4567671634,272704343,26042508126,276898693,285287330,64697213892,64965649353,26042508234,64965649376,276898787,26046702567,26042508288,272770050,68996441092,276898823,68996441096,68996441120,68996375588,272704550,68992181347,272707605,4567674964,13157609682,4567675096,13157609745,13161804251,4567675406,13157610012,272708189,26063483528,26046706314,4567675545,26046706335,8871031495,285291209,26046706379,285291232,276902666,272708375,26042512158,276902687,281097094,26046706593,4567675840,272708549,276902882,68992250884,272708615,68992185352,68992185377,272708643,13157679252,26042515606,13157614032,13157614107,272712283,43222385297,30337483416,272712349,26059293384,26042581706,26042516191,272777993,272712479,272712521,272712646,26042516449,13157617813,4567683480,4567683600,13157618201,13157618264,30337487506,4567683735,4567687445,26046718358,60402262487,13157622290,26042524183,4567691669}},
['Aetheron Egg']={28,25,6,{{68,64,51,0},{206,190,150,0},{226,204,139,1},{65,27,26,0},{119,104,73,0},{101,33,29,0},{61,19,17,0},{222,158,27,1},{129,51,36,0},{242,78,83,1},{160,145,109,0},{249,229,76,1},{94,14,13,0},{78,55,9,0},{79,71,49,0},{87,80,27,0},{85,27,29,0}},{285343747,4567662605,8862629902,13157662743,17456824397,21747531855,26050887767,13161791576,276889733,30341660812,13426032783,34640822416,13157597334,276889794,34632433866,8871018699,30605902029,9135259854,35169304783,26042499281,38948372694,26310934744,13161791705,331415809,809566467,43759239428,47529984261,30362632457,47819325706,9135325452,30610096399,34900869393,38927401234,38944178453,22292857111,13157597466,281084224,9135259970,43801182531,9131065668,47785771342,52080804176,34636628306,22284403033,26310934874,13157597531,43796988292,30614356363,9135260045,30618485134,9143648655,35169370512,51824886163,35169370521,26310934939,43759239618,39200031184,52089192913,22305374679,34934489560,13157663194,4836098562,30337532421,30341661192,30605902349,26042499610,289473088,43776016962,43759239749,272761414,47785771595,30605902412,9143648845,52886045264,26050953812,22292791894,34913452634,13174375003,9139454597,5104534150,541131399,9131065992,9135325835,9143648910,30605902479,35710435984,52617609874,26583564947,9135325894,1078002376,47785771721,47785771727,38969344722,9131131656,30350050059,9131066124,9131066127,35441935120,26852000529,39208616723,47786033989,30350050122,30341727052,34905064271,39195837271,26310935386,549520258,47790031749,30354244487,47785771912,30345855881,35169305486,38935856016,22552839063,13174375322,30345855944,8866890701,38927401935,39208420311,9135326211,47785772037,30354244614,38944179219,52084999188,39195837462,35169305624,13426033689,9135260738,30366827589,51837469782,38944244824,47785837699,47521858698,30337467536,38927402132,51820692629,47521596610,30626874564,47517336784,51833275607,47517533452,47517336898,30350050627,38927402321,30341662082,51816564120,21747533336,17456762958,276893828,17452568717,26046697623,272699587,30337470668,34636632272,272699650,47529922821,8866828555,38944182550,13157601561,281088321,272699776,34632438162,13157601754,30337470981,30345859593,289477185,272699974,30337471048,51812307539,26050892373,281088640,26046698132,13165990555,38948377298,30345859851,30345859914,30337536844,30350054279,30341665673,30337471373,38931665808,30341665736,8862634958,30345860102,38935794707,30350054469,51824890966,38931666008,51812308117,47521535171,47517537484,51829085399,38935794904,30345860419,51816502680,17452572814,56107278541,60674875598,60406505740,56379908367,34632442128,60406440258,60402245956,60402245963,65234084174,51812311376,272703873,56115732875,60943311245,56925168014,60951699855,69264810448,51820700113,34632507864,64713990666,56912585229,34661802520,56111473225,65234084427,56912585292,60683264589,51812311634,34649219673,281092737,60679070341,60402246280,60674941579,60683264654,56912585359,26046702229,34640831130,272704192,60406506182,65234084553,65234084559,69008958162,26042507988,13157606107,60939182856,56111473419,60402246412,60670681871,69273395987,64965911365,56111473482,56107279181,34632442703,69529051991,65238344581,56115667847,64965649288,56107279241,68992246672,56107279304,69273199575,60406506499,65234084869,56111473670,68992181267,51812377620,69529052182,56111473733,51812377685,68996375640,64697279619,51812312214,56111473860,51816506583,60406444301,43230769475,60402250060,21751738712,60402250114,56115671436,34632446352,34632446361,34632446424,56107282955,43239223875,64709800522,51812315729,21760127575,34649223768,43230769794,56107283081,21751739030,34640835225,272708289,60406444742,69004767954,26042512083,26042512085,34632446682,60402250503,56107283211,56107283274,43226575748,56111477639,60406445060,56107283462,51812316181,56107283525,51812316246,64697218180,60402254094,60402254157,56107287052,60410643021,43230839427,64705610378,60402320011,60410643086,21755937431,34640839320,43222385346,60406448837,60402254539,69000577746,21747548886,34632450777,60402254598,34632450832,26042516241,69000577811,69004837653,43222385476,64697418565,68996383572,56107287431,60406452813,60402258511,60402258571,60406452878,34636649104,43222454979,64697225930,34632454865,21751747287,34632454872,43222389508,60402258693,68992193298,68996387606,64697291589,68992193363,68996387669,64697226118}},
['Cthulhu Egg']={25,28,11,{{45,77,101,0},{33,62,72,0},{22,85,43,0},{12,52,27,0},{9,43,21,0},{8,33,15,0},{36,105,59,0},{10,45,22,0},{131,230,131,1},{106,138,59,0},{75,207,75,1},{118,200,104,1},{95,229,94,1},{230,242,232,0},{46,80,46,0},{26,72,26,0},{33,80,33,0},{41,70,36,0}},{281214981,4840357896,276889610,8863088652,272695316,272695364,8862892107,14231339088,9131196497,4571856980,4567728259,1078067336,5104533642,13447004299,17989566604,23098163343,9676390545,813760659,4567662741,272826562,26847936709,31679643848,34909257929,13962903754,22552969420,541196500,38927401174,272826625,26847936772,31683838215,43494998280,43490803978,31415402764,14516551949,31688032526,5641404691,1082196244,13694468373,30610096406,47517335831,4567662913,562102594,26583695683,31679643974,52105904458,23626580303,10204873040,1350697298,30886920533,13161791831,276955520,14499774854,43507581319,52080738696,23374922121,14499774860,27921547663,10473243024,27401453969,34905063828,9131065750,9420472771,27116241348,47785771461,34900869574,34900869576,31948079564,19600048590,41079079375,27921547728,27401454034,1614873043,13694468566,8862695895,4567663105,9684713988,34909258245,47785771526,23362339336,34900935179,32753385998,41079079440,5909905939,18257871382,26315194903,281084481,31683838534,34909258315,15305081420,34905064013,19872678478,47785771599,27133018707,1350632020,13962969685,34900869768,34905064076,23626646159,1078002325,47521596054,26042499736,4840293058,14231339717,18794742470,14503969479,52080739016,34909258441,15577711309,32484950734,23634969295,19063177936,23098098385,26596147924,5108728533,38927401729,9940566789,31679644422,43490804488,43490804490,15573582603,19868484366,23362339600,31679644434,47785771798,26042565399,272827201,26587759428,18794742598,31679644487,47785771848,15040906058,23895147340,22825468754,26319323989,13426033494,26042499927,276956034,26336101253,31411209094,14499775367,31679644552,14768210825,19600114572,40278098830,18798936977,13962904467,21747532694,26596148166,18794742727,14503969736,31948145609,15040840651,32485016524,18526307282,26856195027,38939984854,4567663619,549520388,14231340039,14499841033,15036711948,31679644689,9936372754,5104534548,47785772053,276890691,9940632647,34900870217,52089128010,34905064523,10209133644,40269579343,10209002576,52080804945,39200097364,52080739465,9936372879,34900870289,52084999314,4571858116,47785772231,40005338312,31146968265,13698925771,31146968272,5645599953,9143649492,38927402197,9399502086,26847806727,18526307594,47785772306,43490805011,8866825493,276956484,39464273222,9667937607,34900870472,52080805193,14231405899,9131263309,52080805201,8875214163,8871019862,4840359302,43490936200,52080739723,43490870668,52080739726,8862631311,52080739728,47525725585,8871019922,56648336789,8862631319,276891076,4836099525,26046694856,47517337033,43490870730,52080805324,43226564046,47525725648,56644142548,26046694871,272696837,26042566150,34632435210,43226695179,47517337103,9131066900,26046760469,26042500678,47517337162,34632435279,26042500692,47517337227,43222369932,38927402699,281153542,8863027213,276893765,272699466,8862830668,4567666820,4567666836,272765123,272765186,276894081,8862634455,47517405846,47517340374,26042503959,272765762,276894595,276895045,8871023955,8862635349,47521535377,8866829714,8866829718,26042504648,26042504710,43222504971,47517341200,26042570261,43222439499,281092103,4571865096,8862900238,276897862,4567670857,8862769229,8862703697,272703621,272703684,60947505353,13174382795,272703700,272703747,65506713864,65234084106,69822652746,276898178,65519296903,70334357896,60674875796,74092454341,61207552454,61744423368,60947505669,74092454406,61476053515,26046702103,61752812107,62285488717,75166196303,61475988104,62285488780,73287148182,70065922760,61752812233,65770955528,66307826442,73287148310,272704323,74360890184,26042508117,26059285381,61207553097,69805876298,61480182859,69529117777,38931604564,69797487753,61207553169,68996441234,73555584199,73555584274,64697214227,60670682440,68992247113,8862704973,8862639440,69260682577,8866899283,4567737734,64697214344,64697214346,69260617099,64697279884,73287148945,8862639506,4567672262,64697214411,68992181708,64697214476,8862773263,276901959,4567674952,8862707790,8862642257,272707718,17452642445,272707795,13170192651,26046771524,26042511747,8862642627,30341673429,26050900692,4567675669,26042512196,26046706565,26055095238,68992251026,13157872843,68992185554,13157807371,68992185674,8862643533,8862643539,64697218444,8862643604,8862646288,8862646351,272777351,17452581006,8871035025,26042581190,21747613901,8866840786,26042581253,26046710085,13166002507,26042515844,60402254292,30337483285,13157614165,26042516244,26042516422,68992189586,30337483977,13157811403,30337483984,13157745931,26042519751,21747552462,8866844881,26042519814,60406452489,8862650642,30337487180,276910418,26042519941,13161812363,26046714451,272716372,26042520339,21747553106,8866845768,68992193617,13157749963,13157684491,21747622159,64697229640,30341685582,8862654800,64701424007,13166010765,69008974282,26055107025,26046718482,21747557137,38931686286,13157622794,38927426574,68992197706,8862721100,8862655628,30337495438,21760143817,13161820621,69004784138,60402266636,26046722577,21747561232,38931624846,30337496010,60402267211,8862659660,13157630477,69000593994,60406465163,21747565199,21747565327,13157696330,13161825163,13157630988,38927438351,60402275019,13157634891,21747635020,17452602252,30337504204,17452606030,60402279053,60402279116,13157704460,21747573580}},
['Luminous Cthulhu Egg']={24,28,12,{{49,51,94,0},{19,137,147,0},{8,78,93,0},{5,49,58,0},{6,67,80,0},{66,66,114,0},{105,193,239,1},{69,130,228,1},{18,171,185,1},{138,233,250,1},{4,5,50,0},{10,107,119,0},{248,253,254,0},{37,68,84,0},{24,46,80,0},{48,82,88,0},{6,60,65,0}},{272957445,4572053515,9936371727,13698727952,17720999954,21764309011,272826435,22288597062,26310934599,272826440,14248116303,22036938834,272826498,22284402821,809697415,17721262218,14243922064,18262065297,272695444,21747531925,21776892097,541130946,22284468419,9668001989,30605967559,18257871049,30605902026,18257871051,14231470284,22015967444,34632433877,22016033026,9672130820,39200030981,26315129094,30639456519,39195902216,26310934794,30605902091,10204807436,18828296461,14776598798,22829662481,39204225300,17452564757,541131074,9403695427,39195836744,26331906377,18526437706,30605902163,38931661141,21755920768,9399501186,39195836804,18794807685,44845564296,30631068042,18794807691,18794807695,26319323539,17729454530,26315129284,39200031173,18798936518,39195836875,19331613132,19331678670,10209067472,26310934994,26315129300,17452696021,19335807499,39200031244,19872678414,34909258255,10213196306,26315129365,9135325718,18014601796,26310935109,30610096710,19600048720,10741678673,10204807763,22565421652,22015967874,17997824643,39204225669,39200031368,26311000715,15049228942,34900869776,18811519633,23089709715,39200031381,34900869782,9399501463,276955841,39195837126,39195837129,26310935243,39195837132,14776599247,19331613392,18798936786,9940566739,38931661526,30605902598,26311000840,19868549899,14503969552,26310935317,4567728960,21760115522,9667937091,18270454597,26310935366,19063178055,30605902664,19335938889,15305147212,9676325714,18257871699,9403695956,30605902677,8866825046,4567663488,21747532673,21768504195,39195837318,26310935431,18803131272,19868484492,34905195405,18794742672,9403696019,13426033557,18530567110,18799002569,39195837387,26310935500,9936438224,34645083092,9139454980,34909258763,39195902988,34905195534,9936372753,18257871890,34909258771,9403761733,18526307399,34909389896,34905130060,34900870225,30610097234,34900870279,34913518734,26310935696,30605902993,21768504516,9139455173,34900870342,26315130055,9936504011,34905064656,39195837649,26315195602,47517402324,39195837702,17721197832,9936373004,18257872141,26315130129,17725195540,30337467669,21760116035,30605968710,47517533512,34905130316,47521531216,30605968722,17452631381,809567621,9131066758,47517336967,47517402505,4576052619,34632435086,47517336975,13426034065,17460954514,52349240723,8871085461,21747664325,4580246988,34636629453,17456760273,17725195731,8871019988,21751793157,47517337095,4576052813,8862631507,272830470,4571992076,272699461,272765000,4567666763,272765059,21755924627,38931599701,21755924865,21747536320,17452634581,276894402,38927471318,38927405846,4567667521,21751731010,21755925379,34645021652,21747537092,47517340884,21755925828,47517472073,47517341008,17452569941,4567668107,17456764306,8866829717,21751797189,4571862476,8866829780,272703495,4571930637,56375713863,272703560,4567670860,17452769419,21764317330,60939182279,60402245834,21751734483,21747540227,65238278405,56916779270,61241106695,65234149640,56375714058,60939116811,65502519624,56933556553,60670681427,64701407572,65234084228,61232718218,56384102803,21747540417,17456832962,56648344004,65506714053,65770955211,56912585170,56379908564,17452573141,66312020492,70611182095,56379908629,8866832918,17452573251,56644149829,61211746886,8862638679,65242473093,65775149704,57986392715,70602793616,64969843349,69260616342,65502520006,66039390921,57986327243,66844697292,64697213654,61207552774,57181086472,56107279125,21747540802,56912585542,61744423752,21747540867,65502520198,56912585607,69801812877,66039391179,57717892044,8862639108,69805876235,65771021324,69801813006,69000569875,69000701000,69801747532,69529052241,60674876498,69529052295,69000635534,56644150416,60939117713,8862639301,69260616902,56111473863,68996375760,65234085073,56111539410,64697214214,17452705033,56111473937,8862639429,60402246982,47517345099,68992247116,60670747986,17452574036,68992181644,17452574098,21747541445,17452574163,8862639572,4571869198,13161803792,4567674957,21747544198,272773255,17452707980,21760127186,8862642563,17452642754,17452577283,17473548868,8862642774,8862643091,8866837574,68996510792,68996445326,56107283655,68992251081,68992185552,56111477970,17452578059,56107283729,68992185676,51812316563,4567679054,272711815,17452646541,8862646470,17452581073,21751742802,17452581315,56111481299,56107287060,21755937364,56107287125,64697221781,17452647236,8866841426,17452581765,68992320584,68992255113,68992255118,17452585102,13170200719,60402258119,13157683405,13166006480,64697225480,17452650827,21751746897,56107291076,56107291155,21751747156,8862651091,17452585797,17456780231,8862651344,68992259145,8862651596,17481949517,13157622095,60410651015,17452589452,17452589455,17452589510,56119878089,8866849232,60419039754,8862654993,8866849362,17456784017,13157622544,17452589960,68992328589,17452655561,68992263117,68992197643,68992197708,13161820494,17477759373,60402266567,43226591688,56115687945,8862659088,60414849610,17452593809,13161820879,56107299593,68992267149,68992201677,64697234444,17452663245,17737810445,17452597835,60410659466,13166019214,13157630671,17452729161,17452598155,68992205709,64697242188,68996403791,13161829006,17452602187,13157634892,17452671565,56107311756,17456800397,13157638798,17452606220,17452610189}},
['Sabertooth Egg']={25,28,12,{{219,103,29,0},{89,37,23,0},{191,46,20,0},{51,43,43,0},{146,13,12,0},{64,33,24,0},{243,176,30,1},{207,175,133,0},{70,46,38,0},{66,58,56,0},{116,76,60,0},{107,44,28,0},{195,178,146,0},{85,62,10,0}},{285278218,4571922445,281083977,281083979,4567662668,8871084111,13174374534,17452630151,541130892,9416343693,276955281,13165985989,13426032839,9135259848,9407889612,13166051539,9399501063,5373100297,22552838415,26315260176,17452564758,26050953539,13967098183,5373100360,9936372043,31419597135,17452564821,8871018838,13161791874,26315129221,5641470344,1627586954,31419662736,13962969490,17989435796,9131065749,35706175942,1619067335,23089709512,1623261641,6186729933,35706175954,5377163731,9403695572,4836098517,38927401474,13426033155,22284403204,9667936773,5641404934,1614873096,6182470159,5914034706,22016033301,43222368791,30337598017,35441934916,1346437701,10204807750,18794807879,10209067600,9936372307,35437740628,9399501397,21747597910,30337598080,5372969603,14508163717,26327777926,19331678856,2688615050,6715277963,49664819854,10758455951,10204807826,35710370451,9667936916,809566869,22015967894,30337467031,30605968064,22552904386,14499775172,26319323848,19868484297,6987907786,24431887053,11286938318,10750067408,1614938833,26315260628,541131479,30337467096,30337467136,9131066113,22284403458,17993630467,5641405188,26310935305,11286938381,36511482641,44568740626,1614873363,8866890519,272696129,13434422082,18262065988,40001143621,31969051465,49664885578,7252017996,44832981841,23089709907,1346437972,26315195221,34632434561,9407890307,18526307205,31696421768,32489210762,11282744204,2424374158,23089775504,18798936978,14231339923,26310935444,272696215,8871019457,9667937220,1354826693,35974677446,2688615373,2151744463,6178276304,18794742737,35714565075,1086391252,26310935509,30358504406,39195837442,5372969988,1619067910,31688033287,32489145354,36784112651,15040840716,40814838797,36779918350,40538080271,5909840913,35974611986,30882726933,34900870210,5104534595,35437741124,41074885710,36511482959,23358145616,14499775569,10204808274,30337467521,541131906,30354244739,39464273028,35437741189,14231340166,1627522186,40538014860,15036646542,1354892431,40269579409,14231340178,39732708499,35437741204,30345856194,541197508,5372970182,52886045895,1086457032,14499841228,23358145742,813827281,35169305811,276956372,21747533060,541132037,22284403974,285279495,5909906700,35974612238,22015968531,38927402309,9131066694,5641405772,48595273037,9936438606,809633104,9131066706,272762195,30337467734,272696710,809567624,9667937673,817956234,26310935947,18257872268,1078068622,26310935952,272762257,8871019976,545326537,18257872331,8871151052,272827855,8875214347,276891151,8862696976,26046694985,8866825802,26042500688,8862631505,30337468039,8862697101,272696977,281088074,4567732301,276893833,276893835,8866893967,13170184390,272765137,13161795859,13157601605,13157601620,26046763395,30337536578,21747536470,30337536641,8862700311,8862634839,30358442966,30345860227,272766164,281089287,272700692,272700817,8862635464,8866960844,272766415,8866829835,272700943,8862635536,26042504777,8862635594,8862701133,276897930,272703689,272703691,8862703823,8862638344,56111603984,13161800006,13157605715,56111473029,56107278788,21747540501,30337475139,30337475202,56929428102,30337475265,57189409480,56111604436,57717891849,8862638871,56107344725,56107344788,56107279317,30337475715,272704709,272704724,276899079,56644150667,56107279760,272704969,8862770636,272704975,8862639627,8862705165,272707786,8875290829,8866836748,56111477008,56107348305,13157609862,56107282885,8862642708,56111542996,17452577539,56107283222,56107283285,56107283348,272774353,272708871,272708881,272708944,276903306,8862709197,4571873546,8871100685,4567679305,8862646604,56107286864,13157613959,13157613970,4567679507,34632450692,21747548867,56111481556,56107287317,276972744,272712913,272713033,272713098,272713102,4567683402,8866910541,4567683465,30341747087,30341681617,30605922832,34632454867,56107291412,276976783,272782536,272717065,272717071,47517357389,8862651726,281108938,276914697,276980235,17452589640,8866849360,56115683975,56107295430,272720593,43222393618,30350074760,21747557264,276980874,272721039,13157622989,276918794,4571951629,272724553,272790091,4567691855,56107365063,56107299592,30354273097,38927430671,272790666,272728650,4567761485,17452597897,56107303624,8871051983,8862663440,13157630988,38931629069,4567700109,8862667535,47517373259,30341698443,34632471563,38927438861,4567704266,4567769867,8862737165,8862671693,8862671756,8862675725}},
['Skeletal Sabertooth Egg']={28,28,12,{{46,28,19,0},{51,32,21,0},{185,156,109,0},{159,132,92,0},{216,184,132,0},{82,58,40,0},{231,167,39,1},{136,109,76,0},{250,218,32,1},{62,39,27,0},{181,159,128,0},{40,22,14,0},{40,23,14,0},{23,10,6,0},{81,58,14,0},{88,76,11,0}},{272760842,5104533516,1078067213,9672261647,13694468114,17456824339,8862695495,276955209,22284402763,1078067276,10213195854,18257870930,17456758869,8866824278,8862630023,17721000072,9672130699,22821273740,10209001613,14768210063,10238427280,26311000210,17989435540,8917155991,17456758981,30337466566,13426098375,809566409,9676325066,10213195980,10741678287,34913517778,39732707540,9403695317,17721000150,17456759044,17725260038,13962903816,9672130825,18794742027,19063177485,40810709262,26310934804,9399501078,8891990296,17452564803,9407889733,18526306632,10204807499,40806449485,34900869460,1350631765,39736901974,17452564825,43226562906,17452695936,39195836803,9399501188,9672130950,18526306695,5909840264,48859513225,1619132810,49396384140,53959852429,49933255055,1614872980,8862630297,17452630465,22284403139,34917646788,1615004103,53959852492,41079144910,26310934994,34900869587,40005337556,5372969429,813760982,26067665410,34900869635,18257936901,1614873095,5914034696,49128014345,11018568203,54496657933,40546402834,1619067411,1346437653,8879407641,26310935107,26315129413,40001143366,23089709639,1887502921,49396384330,50201756237,54228222543,1614873172,5373035093,34649211521,34900869763,10204873350,1887502984,2420179594,54496723597,19881067151,23089709715,40269578900,22821274261,5372969622,26315129539,9936437957,40273773255,49396384457,53959787210,19876872907,11546985164,54765093581,20145308366,19608437456,10204938961,5909840596,31411208917,9680519894,8900379396,18526307077,40269579014,6178276104,2151809801,20136919820,41880191757,19335807761,9709880082,40269579027,18798936852,9936372501,17721000728,39464272707,9940632389,23093904199,1883374408,49664820042,10502603596,24700322637,57453642579,18526307157,9139454808,13161792345,9143649155,1883308936,49396384649,41074885514,11022697355,10741941133,9936438164,17452565442,18257871813,22821274566,53154481095,5909906376,10485826506,11010311117,26310935505,10221650899,26310935509,34905064406,8866825177,21747532802,9667937285,5641405446,48859513863,18794742792,10477437961,11546985485,26310935566,34901001231,34900870165,34905064471,17997825048,8866825242,8875279425,22821274693,9940698182,26315129933,34900935758,26310935632,9953150033,9944761429,26310935638,17465148505,8866825344,17456759939,9667937413,18798937225,19331613835,26310935694,9949021327,9407890582,26310935703,17452565658,8862631067,17989436613,9668003014,5909841096,53154481354,10209002699,10477503693,8866890967,8871085317,22552839431,9940698376,9676326163,18257937684,17452565786,43222369601,9667937607,18794939723,9139455316,17721066837,8866825559,17989567879,13962970506,18258199948,8866891157,17452565957,8866891206,17989567944,13962905035,18526373324,9139520974,17989633488,8866825736,17721198089,9143649805,8866825744,17452762641,8862631445,17452566087,8862631497,17452697162,17452697169,21747533451,39195838092,17721001614,8862631567,8862631628,8862631630,272699403,17456762899,276893770,17452568660,272699529,17452568725,8862634134,17452568837,8908771607,17452568900,8866828632,17452569026,8875217432,26059281026,8891994884,8862635033,8871023682,17456763993,8866829441,17452569731,8862700759,8866895109,8862635287,8866829702,8862700949,8866829767,8862635477,8862635528,8862635536,17452701201,17452635723,17452572755,272703626,60670746770,13157605576,65246732498,17456767239,60939116820,17452572998,65502519636,8866832727,64713990596,61207552466,65502519763,8891998743,60674875973,64697213571,60406440643,8887804676,8862638979,61744423889,60939117525,64969843670,62549730318,66307957775,65502520341,64969843735,8862639171,62285489229,66307892302,61744424016,60939117654,8862639234,62012859534,60670682263,8862639319,8866833670,8866833748,17452574037,8862639509,8862639559,8866899406,17452639755,8871028237,17452574284,8862639694,8862642453,17452577095,8866836869,64697217476,272708118,64701411972,8871031556,8862643268,8866837654,8862643540,17452643720,8862709198,17452578316,8862709261,8862643789,272711694,8866906127,272711757,8862646353,60402253970,8862646475,8866840842,8862646601,8862712261,17452581382,4567679573,60402254469,8900395794,64697222166,8862647446,8862647495,8866841875,17452582164,13157614987,17452778892,8862647758,8862647821,8866844687,8862650448,64709808338,64705614099,8862650698,38927421972,8862651078,8896205586,8866845510,8862651284,8862782534,8875234385,8866845781,8862717063,8871105679,8862717193,8862651667,8862651727,17452717452,17452586445,8862654670,8892014800,8892014865,8862654796,64701423954,276914571,272720330,8892015314,4567688137,8871044115,8862655560,8866849873,17452590217,8862721167,8862655691,8862655695,17452590413,8887824656,8866853201,272724427,47517364746,8875242001,272724617,272724809,8887825228,8871048138,8866853906,8862659657,8862659665,8862659727,8862725325,8862659853,38931628303,38927434062,8866857296,8871051792,272728842,8883635020,8862860173,8862663885,38927438159,51812340110,51812340173,38931632590,8871055884,38927438351,8862667403,8879444812,8862667659,8866993037,64697242639,64697242702,38927442446,8862671500,8866865996,8866931597,60402279501,51812348557,8862675853}},
['Octophant Egg']={26,28,13,{{56,55,39,0},{236,243,75,1},{22,23,17,0},{86,85,63,0},{40,41,32,0},{27,28,23,0},{68,68,49,0},{131,125,96,0},{179,173,139,0},{237,249,129,1},{128,235,33,1},{19,21,13,0},{193,235,64,1},{160,154,122,0},{83,85,26,0},{83,87,45,0},{45,82,12,0},{68,82,22,0}},{272695305,4840292362,809566219,9667936268,13962903565,17989435406,21747597327,4571856967,276889672,4836098121,26847805515,14235533388,31142838349,35186081871,30626873424,34657599569,21747531858,272695429,21747531910,809566345,26847805578,14231339147,35974611085,31415402638,272760978,13157597378,26042499267,17456758980,30605967557,809566407,39195967688,35974611147,1614938316,809566418,4836098259,272695508,17456758997,272761090,30874337541,17989697798,1614872843,4836098316,27653112077,35974611214,26860388626,43499258131,17452564758,272695617,26310934850,18002018627,35173564740,9667936582,18526306631,1346437448,14499840329,39200031051,2151743820,19331613005,31948079438,22284403029,541131094,30341661015,26046693761,545325442,48591143302,52080804232,39195836810,15305081228,1883439501,17993630101,26310934934,13157597632,18526306756,31679644101,18794742214,48859578823,4836164041,52080804299,2420244941,23358210511,52084998611,17725260246,26046693848,272695809,13426033154,31142773252,9961538053,48859513350,1614873095,49128014344,4836164106,52080738828,28731048461,19889455630,49664819727,10741678608,23366533649,14499774994,1082196501,26046693953,541131330,13694468675,9667936836,10209002054,39195902535,52080738889,39195902538,2957050444,23895081551,27653112402,1614873171,23093903956,22552838742,52089127511,545325656,26067665497,26042499712,26579436162,18530501252,49132143239,52080738952,39195902601,2957050507,16110387852,20673790605,11546985103,24167645840,15036646034,27653112467,27384677013,48595272342,13178569408,826344129,26856194754,18530501315,1883308742,4836295368,29263790796,24700322511,19868484305,28198372050,10741678803,49127949012,1614873301,26847806168,23093904132,49396384518,28189983495,49933320968,4836164362,52080739084,4840293133,11815420687,50201690896,13996458769,49669014291,10221585172,27384742677,18794742551,1346437912,27384677187,23895016262,49664885575,4844487497,39200097098,4836098892,58259014479,49127949141,1614938966,4844487512,4840293250,35186148227,10741678982,39195837319,52084933512,28726854540,33021887373,1891697554,19331613587,10209002389,18794742678,48591078295,35190277061,18798937030,49127949255,39195837386,4836164555,33021821901,58254820302,15036646352,43494998995,4836099030,18257871831,26310935553,35169305602,1614873607,49127949320,39195837449,4836099082,14772405259,28189983756,35995583501,32484951054,23362339855,48863708176,30610228245,26055083032,272696345,4567663681,13426033730,48859513926,39195903047,4836099145,39195837514,31952274508,10741679182,39195837522,52084933715,22821274708,13165986945,545326210,9936372870,48591078535,43490804872,52080739465,14499775626,35450324107,31679710350,13707052176,52080739474,18530501780,9667937429,30874338454,26310935703,13694469315,35437741252,35173762246,35714565324,35978806478,13971293391,4836099282,27116242131,18257872085,56644142294,13426033879,26310935810,541132035,52080739588,1078002962,13962970387,31142774037,26046760214,272696600,13157664066,26311066948,34901067079,17477731662,30874469713,26315195732,13157598552,13157598596,26042566021,34632435079,17721329032,17989436815,22015968656,541132177,30605903250,26046694803,26042500502,272696776,17452631497,43490805195,4836099532,43490805197,21751727567,17452631504,21747533266,26042500564,13157598677,51812304395,39195837964,52080739853,13157598794,541197899,26579371597,17452566095,276891275,4840294028,545326733,272696975,21747535887,4567666823,272699528,34653409425,272699538,272699651,17452568836,17452568853,26042503617,26042503809,26063475353,13174379200,26042504216,26042570006,17473541454,26042504534,26042504595,21747537359,60402245706,30354251920,64697344200,34649219281,61475987724,69000569107,65775149387,68996374868,74092519816,65770955146,272703938,61476053449,74897826251,73828278739,17456767446,62012924426,75434631692,65502585415,74629325385,66307891786,73295536727,74629325448,66307891849,272704152,62013055688,26055090905,13165994752,62549795594,75971502860,63090795277,61752812361,66312086346,62818165580,60410635096,60674876290,66039391111,74633520008,66039391178,62012924875,69801681875,60939117526,65770955785,61475988490,30337606677,65502585927,61207553097,65502520394,65502520402,74096649299,30337541205,69797487752,74092455049,74092455058,60939117778,73287148804,26042508566,34632574280,17460962638,26042574164,17452705163,60402247116,69260617165,73287149069,272705100,272705165,34645029007,64697282761,30350061776,17452773639,34645029137,34636640581,68996378963,34632446340,68992184724,17452577219,17452577237,26042512003,73291346583,281096961,26046706457,13157610304,60406444888,34640900995,34649224133,30337545237,34636641348,30337479765,13165999248,34632709318,34632578312,17456772430,17452643724,30337482829,64697221322,34640838863,17452646665,30345871632,34640838993,26050904402,34632450437,68992188819,272712277,73287156439,26046710530,13186974481,272712513,60402254680,60402254722,34636710787,34645033925,34632451076,30337483797,34640839819,13161809040,34632582344,13161809103,17452582222,17452582285,13157617804,30337487054,17452585226,34636648719,30341681488,47517356423,34636648849,26046714258,73291354579,8879428229,17452585668,47517356758,17452585731,13182784273,26042520386,34632520579,34632520644,34632455173,34636649611,13157618832,34636649676,13157618895,64697229896,8871043845,13174399761,8871043860,26042524437,21747557188,17452590022,68992197587,34645042189,47517361168,30337492110,64697233803,272789901,60402266570,21747560911,47517364745,21751755345,47517364935,13170209553,8866853652,8862659397,276919186,13157626891,34640851981,21747561487,30337496140,272728461,21747565201,13166019345,60406465353,73287173000,272728978,34636661773,73287176652,272732621,60402274827,64697242187,21747569231,64697242250,60402406089,13161829137,26046731026,47517373256,60402275145,64697307978,56107373391,64697242507,56107307919,60402275276,56107307982,34632471565,17469383246,60402344650,21747573456,47517377289,13157638929,64697246539,56107311951,26042544717,17465193102,60406477515,30337512333,17456808654}},
['Mecha Scrambler Egg']={27,28,13,{{66,65,65,0},{35,35,33,0},{52,52,52,0},{29,29,27,0},{242,247,142,1},{41,41,39,0},{24,24,23,0},{21,21,19,0},{22,22,20,0},{213,239,89,1},{14,14,12,0},{248,249,88,1},{245,248,113,1},{85,86,50,0},{87,87,31,0},{75,84,31,0},{86,87,40,0}},{272695306,4836163595,1082195981,9403760654,13426032656,8862629905,272695367,4567662664,13157662793,5104533579,13962903628,541196368,8862629970,8883601541,272695430,13426163847,17721000074,1082196107,5641404556,14499774605,1346502798,9680519312,809566353,22028550290,4567662739,4567662787,13157597380,9131065542,26579370183,17721065672,31146967242,23089709260,27384676557,10217390286,1623261391,9667936465,13434421459,21747531988,13157662933,4567662850,13426032899,553713924,13694468358,35437871367,5909840139,1614872844,6178275597,1346437393,39195902228,34909258006,26042499351,276889921,13430227266,26579370307,44031869254,31411208519,14231339336,5641404745,23089774922,10473242956,27921547597,10204807505,47785771348,39195836757,8862630231,13694468483,44564545927,52080738696,47785836937,17721000331,6446776716,27921547663,1614938512,5641470354,52089127316,35441934741,13426033047,8862630296,8862630337,26311000514,27384742342,44564545992,52080738761,47785902538,6987841997,32484950479,27921547728,1883308497,5909840338,14499774931,26847805910,35169305047,22015967704,4580245977,272695809,13430227458,35169305091,22557032964,44304564741,31679644167,27653112328,44832981513,52080869898,37048353295,45386629648,32233292305,36247241234,5909840403,31419597333,13975486998,26311000599,8862630465,9399501379,44568740423,17721000520,47785837129,17721066059,16118776397,28726854222,32757580367,14499840595,30874337879,52084933208,21747597952,5104599682,14231339652,47785837192,17721066122,16110387852,37585224334,6182535826,35974611604,44031869591,21747532442,22015967936,5104599745,35706241731,44572934853,14768210630,36511482567,45378241224,47785902793,52080739020,16383017678,37589418703,44573000404,17721000664,13698663129,4588634842,4840358656,13967098626,31679709955,44573000454,45906723593,52084933386,47785837323,24968758029,6987776786,15313470227,35974611734,14243922711,31411208984,5641405251,31679644484,47794160457,17721000779,2957050700,16110388045,7520453454,15841952591,2160132944,11014308689,44568740694,27384677208,5641405273,21747532672,4836164481,826409859,5909840773,52080739208,17721000842,1891697547,11278549900,7252018061,2428568462,10750067599,15305081746,32216515476,44832981909,44296111000,1078002585,13157598145,9131066306,9948955589,14499775430,44564546503,47785771976,52089127882,2420179916,28458419149,2151744465,6446777298,17721000916,27384677333,23089710038,35169371096,21747532801,541131778,31683838982,14499775495,44833047560,6446711820,10481632269,31683838992,27653112849,6178276370,39195837459,47794160660,35714565141,9672131606,1078002711,9143649304,4584440857,8862630977,22015968322,44300305479,17721001032,44564546633,23093904459,1094779980,23626581070,31948080207,35974612049,14499775570,52080739411,9399501911,21755921537,4576052354,14231340166,23089710216,52080739465,10204808330,10473243790,23089710223,5909972112,17721001107,31142773910,817955991,22284403907,813827268,9139455174,549717191,9936372939,1354892493,9940567247,1346438352,22821340369,5641471187,14231340245,26847806678,4836099331,813761803,22288663824,5372970258,13962904851,22552904980,545326358,4571858200,21747533123,4836164932,1078003023,809567570,9399567699,809567573,4571858263,21747533145,21747533188,4567729541,272696711,9131066760,4836099465,34901132682,26579371407,30605903248,26046694801,9131132306,22015968660,4567729557,13157598664,26042566089,34632435147,51816564172,47789966798,30605903311,26042500560,26042500562,8862631379,272762324,26042500623,21747533387,13161793100,52080739917,13434422862,30337467983,4836099725,13157598863,272697036,13426034381,26042500815,13157601354,8879411397,21747536513,4567667353,4584444634,4567667737,4571862146,4567667992,4567668055,26042504593,4567668117,51812373964,51812308493,13157602892,4567670796,272703568,56107278474,56107344072,21755928786,8875221253,13161799955,281092420,60402245972,64697213269,69797486984,61207617929,57181020555,69269004692,34632442262,26042507715,69797487049,61476118986,70334489098,26042507799,57181020744,61744489033,57986392651,61744489096,57986392714,68992180888,62281425609,71676535500,56375714520,4567737088,70875423498,62549795595,4576060186,4567671617,61752812361,57986327371,4567671682,70334358408,57717891978,61475988424,69805876170,57181021140,65770955795,61215941652,8862639128,56912585800,69797487699,69797487753,56912585875,8866833606,277095623,272704790,272835912,34632574348,68992181709,60402247118,68992181837,8866836494,8862642255,21751738642,8871031109,13157609811,276902276,4567675523,4567675586,4567675649,13157610265,4567675738,272774019,289485764,34632446936,272708805,8862643398,272905415,272905480,21747610896,34632512909,272711757,8862646350,272711883,8871035088,30337483018,21747548498,8866840965,43222385030,68996383188,34632450517,13161808534,43222385367,13157614338,272712580,8862647318,285295692,272843976,272715918,8866844944,4567683474,43230777862,68992193044,43222389381,30337487509,34632454852,13157618390,13166007063,34632455189,43222389831,281105484,276976845,8862651599,8871043342,272720207,272720272,43222393479,43230782164,43222524677,43226587925,43222459206,43222393686,43222393735,68996391882,30337491984,272720972,8866853198,60402332107,4571886226,4567691987,43222463238,43226592020,43222397767,43222397781,276919179,68992201674,8866853901,4567695757,8862663054,60402270668,68992270859,60402270794,60402270857,30345888401,4567696082,43222401799,60406465353,276923216,43222401876,272728971,8866857871,8862663693,68992209420,43230794384,30341698257,43222405896,60402275145,272733008,8862667601,13157634899,276927374,8862667663,4567769613,56107311692,56107311755,30337507983,60402344650,43226604240,68992213770,30337508113,272737166,60402283211,60402283276,13161841293}}
}

local function pullBits(n, bits)
    local m = 2 ^ bits
    local v = n % m
    return v, (n - v) / m
end
-- Front of every egg is -Z, centered on the origin, already scaled for the hand.
local function buildVox(name)
    local spec = VOX[name]
    if not spec then return nil end
    local W, H, D, pal, nums = spec[1], spec[2], spec[3], spec[4], spec[5]
    local m = Instance.new('Model')
    m.Name = name
    local stud = 10.5 / math.max(W, H, D)
    local cx, cy, cz = (W - 1) / 2, (H - 1) / 2, (D - 1) / 2
    local root
    for i = 1, #nums do
        local n = nums[i]
        local x, y, z, sx, sy, sz, pi
        x, n = pullBits(n, 6)
        y, n = pullBits(n, 6)
        z, n = pullBits(n, 4)
        sx, n = pullBits(n, 6)
        sy, n = pullBits(n, 6)
        sz, n = pullBits(n, 4)
        pi, n = pullBits(n, 6)
        local c = pal[pi + 1]
        local px = (x + (sx - 1) / 2 - cx) * stud
        local py = (y + (sy - 1) / 2 - cy) * stud
        local pz = (z + (sz - 1) / 2 - cz) * stud
        local mat = (c[4] == 1) and NEON or MAT
        local block = part(m, 'Block', Vector3.new(sx * stud, sy * stud, sz * stud), rgb(c[1], c[2], c[3]), CFrame.new(px, py, pz), mat)
        block.CastShadow = false
        if not root then root = block end
    end
    return finalize(m, root)
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
local function weld(t,m,off)m.Parent=t m:PivotTo(t.Handle.CFrame*off)for _,p in ipairs(allParts(m))do p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true local w=Instance.new('WeldConstraint')w.Part0=t.Handle w.Part1=p w.Parent=t.Handle end end
local function place(t,m)local c=m:Clone()for _,d in ipairs(c:GetDescendants())do if d:IsA('WeldConstraint')or d:IsA('Motor6D')then d:Destroy()end end c.Parent=Placed for _,p in ipairs(allParts(c))do p.Anchored=true p.CanCollide=false p.CanQuery=true end local mouse=P:GetMouse()local pos=mouse and mouse.Hit and mouse.Hit.Position local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')pos=pos or(hrp and(hrp.Position+hrp.CFrame.LookVector*9))or Vector3.zero local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={P.Character,Placed}local ray=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rp)if ray then pos=ray.Position end c:PivotTo(CFrame.new(pos))local cf,sz=c:GetBoundingBox()c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))t:Destroy()end
local function spawnTool(cat,name)local m,exact=model(cat,name)if not m then return false,'No 3D model available'end local t=Instance.new('Tool')t.Name=name t.RequiresHandle=true t.CanBeDropped=false t:SetAttribute('SAE_V7_TOOL',true)t:SetAttribute('SAE_ID',Http:GenerateGUID(false))local h=part(t,'Handle',Vector3.new(.45,.45,.45),Color3.new(),CFrame.new(),MAT,1)h.CanQuery=false if cat=='Eggs'then t.Grip=CFrame.new(0,-.15,-.15)*CFrame.Angles(0,math.rad(180),0)weld(t,m,CFrame.new(0,1.15,-2.6)*CFrame.Angles(0,math.rad(180),0))elseif cat=='Star'then t.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)weld(t,m,CFrame.new(0,.5,-1.55)*CFrame.Angles(0,math.rad(180),0))else weld(t,m,CFrame.new(0,2,-4.4))t.Activated:Connect(function()if t.Parent==P.Character then place(t,m)end end)end t.Parent=BP return true,(cat=='Eggs' and '3D reference model') or (exact and 'Exact loaded 3D model' or 'True 3D reference build')end

local C={bg=rgb(8,8,14),head=rgb(15,11,23),card=rgb(24,18,34),card2=rgb(37,25,50),border=rgb(84,57,110),p=rgb(142,51,236),p2=rgb(184,83,255),w=Color3.new(1,1,1),m=rgb(168,162,181),g=rgb(105,245,135),o=rgb(255,188,82),r=rgb(255,90,90)}
local function corner(o,r)local x=Instance.new('UICorner')x.CornerRadius=UDim.new(0,r or 8)x.Parent=o end
local function stroke(o,a)local x=Instance.new('UIStroke')x.Color=C.border x.Transparency=a or .35 x.Parent=o end
local function label(p,t,pos,size,z,col)local x=Instance.new('TextLabel')x.BackgroundTransparency=1 x.Position=pos x.Size=size x.Text=t x.TextColor3=col or C.w x.Font=Enum.Font.GothamMedium x.TextSize=z or 11 x.TextXAlignment=Enum.TextXAlignment.Left x.Parent=p return x end
local function button(p,t,pos,size)local x=Instance.new('TextButton')x.Position=pos x.Size=size x.BackgroundColor3=C.p x.BorderSizePixel=0 x.Text=t x.TextColor3=C.w x.Font=Enum.Font.GothamBold x.TextSize=11 x.Parent=p corner(x,8)return x end
local gui=Instance.new('ScreenGui')gui.Name='SAE_ITEMS_V7'gui.ResetOnSpawn=false gui.DisplayOrder=730 gui.Parent=PG
local launcher=button(gui,'ITEMS',UDim2.new(0,12,.5,-20),UDim2.fromOffset(74,38))
local win=Instance.new('Frame')win.Size=UDim2.fromOffset(560,470)win.Position=UDim2.new(.5,-280,.5,-235)win.BackgroundColor3=C.bg win.BorderSizePixel=0 win.Visible=false win.Parent=gui corner(win,13)stroke(win,.1)
local head=Instance.new('Frame')head.Size=UDim2.new(1,0,0,62)head.BackgroundColor3=C.head head.BorderSizePixel=0 head.Parent=win corner(head,13)
local title=label(head,'DIVINE ITEM SPAWNER',UDim2.fromOffset(16,8),UDim2.new(1,-70,0,24),15)title.Font=Enum.Font.GothamBold
label(head,'True 3D models • larger held scale • pets place on click',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
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
spawn.MouseButton1Click:Connect(function()if not sel then status.Text='Select an item first' status.TextColor3=C.o return end status.Text='Building '..sel..'...' status.TextColor3=C.m task.spawn(function()local ok,msg=spawnTool(cat,sel)status.Text=(ok and'Spawned: 'or'Failed: ')..sel..' • '..tostring(msg)status.TextColor3=ok and C.g or C.r end)end)
RS.DescendantAdded:Connect(function()cache={}end)P.CharacterAdded:Connect(function()task.wait(.5)cache={}end)
print('[SAE] V7 true-3D inventory loaded: no stacked image fallbacks.')

end)