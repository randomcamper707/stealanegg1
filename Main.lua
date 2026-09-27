local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Compatibility bootstrap:
-- Some executors run the chunk before LocalPlayer/PlayerGui exists.
-- The old version silently returned in that case, which looked like "nothing happened."
if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local function waitForValue(fn, timeout)
    local started=os.clock()
    repeat
        local ok,value=pcall(fn)
        if ok and value then return value end
        task.wait(.1)
    until os.clock()-started >= (timeout or 60)
    return nil
end

local P=waitForValue(function()
    return Players.LocalPlayer
end,60)

if not P then
    error("[SAE] LocalPlayer was unavailable after 60 seconds. Execute after joining the game.")
end

local PG=waitForValue(function()
    return P:FindFirstChildOfClass("PlayerGui")
end,60)

-- Executor-compatible fallback. This does not change the UI itself; it only
-- gives the existing ScreenGui somewhere usable to parent if PlayerGui is blocked.
if not PG then
    local ok,hui=pcall(function()
        if type(gethui)=="function" then return gethui() end
        return nil
    end)
    if ok then PG=hui end
end

if not PG then
    error("[SAE] No usable PlayerGui/UI container was available.")
end

local function arrlen(t)
    local n=0
    for _ in ipairs(t) do n=n+1 end
    return n
end

for _,guiName in ipairs({"SAE_BOOT_V9","SAE_BOOT_V8","SAE_BOOT_V7","SAE_BOOT_V6","SAE_BOOT_V5","SAE_FINAL_V9","SAE_FINAL_V8","SAE_FINAL_V7","SAE_FINAL_V6","SAE_FINAL_V5"}) do
    local old = PG:FindFirstChild(guiName)
    if old then old:Destroy() end
end
for _,n in ipairs({"SAE_LocalEggs","SAE_LocalNPCs","SAE_SafeZoneMarker","SAE_MorphShell"}) do
    local x = workspace:FindFirstChild(n)
    if x then x:Destroy() end
end

local CFG = {
    SammyUsername = "SpyderSammy",
    MaxBots = 10,
    Remotes = {
        SpawnEggs=nil, Morph=nil, Announcement=nil, GlobalAnnouncement=nil,
        Teleport=nil, Invite=nil, GiveAdmin=nil, GiveCoowner=nil, GiveVPS=nil,
        SpawnSammy=nil, SpawnBots=nil,
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
local QTY = {200,250,300,350,400,450,500}
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

local BOT_NAMES = {
    {"Nova","NovaRift_73"},{"Vanta","VantaRush"},{"Echo","EchoMint_8"},{"Aero","AeroByte"},{"Volt","VoltMoss"},
    {"Lunar","LunarDash_12"},{"Rift","RiftNovaX"},{"Solar","SolarNox"},{"Pixel","PixelArc_9"},{"Neon","NeonVale"}
}
local TRAILS = {
    {"Eternal Trail",ColorSequence.new(Color3.fromRGB(255,30,255),Color3.fromRGB(120,30,255))},
    {"Divine Trail",ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,220,0)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(55,255,80)),ColorSequenceKeypoint.new(.7,Color3.fromRGB(35,210,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(55,80,255))})},
    {"Moonbloom Trail",ColorSequence.new(Color3.fromRGB(70,255,235),Color3.fromRGB(40,105,255))},
    {"Red Trail",ColorSequence.new(Color3.fromRGB(255,45,25),Color3.fromRGB(120,0,0))},
    {"Galaxy Trail",ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(65,15,170)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(210,35,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(35,75,255))})},
    {"Secret Trail",ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(250,250,250)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(35,35,35)),ColorSequenceKeypoint.new(1,Color3.fromRGB(245,245,245))})}
}

local C = {
    bg=Color3.fromRGB(8,8,14), head=Color3.fromRGB(15,11,23), card=Color3.fromRGB(24,18,34),
    card2=Color3.fromRGB(37,25,50), border=Color3.fromRGB(84,57,110), purple=Color3.fromRGB(142,51,236),
    purple2=Color3.fromRGB(184,83,255), white=Color3.fromRGB(255,255,255), muted=Color3.fromRGB(168,162,181),
    green=Color3.fromRGB(105,245,135), orange=Color3.fromRGB(255,188,82), red=Color3.fromRGB(255,60,60), blue=Color3.fromRGB(45,145,255)
}

local EggFolder=Instance.new("Folder"); EggFolder.Name="SAE_LocalEggs"; EggFolder.Parent=workspace
local NPCFolder=Instance.new("Folder"); NPCFolder.Name="SAE_LocalNPCs"; NPCFolder.Parent=workspace

local function corner(o,r) local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,r or 8); x.Parent=o; return x end
local function stroke(o,a) local x=Instance.new("UIStroke"); x.Color=C.border; x.Thickness=1; x.Transparency=a or .2; x.Parent=o; return x end
local function grad(o) local x=Instance.new("UIGradient"); x.Color=ColorSequence.new(Color3.fromRGB(110,35,205),Color3.fromRGB(177,69,253)); x.Rotation=15; x.Parent=o end
local function label(par,t,p,s,z) local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Position=p; x.Size=s; x.Text=t or ""; x.TextColor3=C.white; x.Font=Enum.Font.GothamMedium; x.TextSize=z or 11; x.TextXAlignment=Enum.TextXAlignment.Left; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=par; return x end
local function button(par,t,p,s,dark) local x=Instance.new("TextButton"); x.Position=p; x.Size=s; x.BackgroundColor3=dark and C.card2 or C.purple; x.BorderSizePixel=0; x.Text=t; x.TextColor3=C.white; x.Font=Enum.Font.GothamBold; x.TextSize=11; x.Parent=par; corner(x,8); if not dark then grad(x) end; return x end
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
    if x:IsA("RemoteEvent") or x:IsA("RemoteFunction") then return x end; return nil
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
    drag(hd,f); return f
end

-- Create every important panel immediately before any game scan.
local Main=window("MainPanel","⚡ ADMIN ABUSE","Developer control panel",380,500,UDim2.new(.22,0,.52,0))
local Morph=window("MorphPanel","Avatar Morpher","Physics-safe client visual morph",390,300,UDim2.new(.74,0,.28,0))
local BotsPanel=window("BotPanel","NPC COLLECTORS","Collectors, avatars and Sammy",400,505,UDim2.new(.74,0,.68,0))
local Console=window("ConsolePanel","SERVER CONSOLE","TAB opens or closes this window",710,410,UDim2.new(.5,0,.5,0)); Console.Visible=false

-- Permanent launchers so closed panels never disappear permanently.
local Launch=Instance.new("Frame"); Launch.Position=UDim2.new(0,12,.5,-58); Launch.Size=UDim2.fromOffset(106,108); Launch.BackgroundTransparency=1; Launch.Parent=Gui
local LL=Instance.new("UIListLayout"); LL.Padding=UDim.new(0,7); LL.Parent=Launch
local bAdmin=button(Launch,"ADMIN",UDim2.new(),UDim2.fromOffset(102,29),false)
local bMorph=button(Launch,"MORPH",UDim2.new(),UDim2.fromOffset(102,29),true)
local bBots=button(Launch,"NPCS",UDim2.new(),UDim2.fromOffset(102,29),true)
bAdmin.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)
bMorph.MouseButton1Click:Connect(function() Morph.Visible=not Morph.Visible end)
bBots.MouseButton1Click:Connect(function() BotsPanel.Visible=not BotsPanel.Visible end)

-- Centered announcement layer.
local Notify=Instance.new("Frame"); Notify.BackgroundTransparency=1; Notify.Size=UDim2.fromScale(1,1); Notify.Parent=Gui
local function nt(par,t,col,z) local x=label(par,t,UDim2.new(),UDim2.fromOffset(0,46),z); x.AutomaticSize=Enum.AutomaticSize.X; x.Font=Enum.Font.GothamBlack; x.TextColor3=col; x.TextStrokeTransparency=0; x.TextStrokeColor3=Color3.new(0,0,0); return x end
local function notice(uid,sender,before,red,after)
    local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.AutomaticSize=Enum.AutomaticSize.X; row.Size=UDim2.fromOffset(0,50); row.AnchorPoint=Vector2.new(.5,0); row.Position=UDim2.new(.5,0,0,-60); row.Parent=Notify
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal; l.HorizontalAlignment=Enum.HorizontalAlignment.Center; l.VerticalAlignment=Enum.VerticalAlignment.Center; l.Padding=UDim.new(0,4); l.Parent=row
    local im=Instance.new("ImageLabel"); im.BackgroundTransparency=1; im.Size=UDim2.fromOffset(40,40); im.Image="rbxthumb://type=AvatarHeadShot&id="..tostring(uid or P.UserId).."&w=150&h=150"; im.Parent=row
    nt(row,sender,C.blue,29); verified(row,26); if before~="" then nt(row,before,C.white,29) end; if red~="" then nt(row,red,C.red,29) end; if after~="" then nt(row,after,C.white,29) end
    TweenService:Create(row,TweenInfo.new(.25,Enum.EasingStyle.Quint),{Position=UDim2.new(.5,0,0,7)}):Play()
    task.delay(4,function() if row.Parent then local tw=TweenService:Create(row,TweenInfo.new(.2),{Position=UDim2.new(.5,0,0,-60)}); tw:Play(); tw.Completed:Wait(); if row.Parent then row:Destroy() end end end)
end

local function norm(s) return string.lower(tostring(s or "")):gsub("[^%w]","") end
local function rootOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart",true) or o:FindFirstChildWhichIsA("BasePart",true) end; return nil
end
local function pivot(o,cf) if o:IsA("Model") then o:PivotTo(cf) elseif o:IsA("BasePart") then o.CFrame=cf end end

local function groundHit(pos,ignore)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder,NPCFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,250,0),Vector3.new(0,-1000,0),rp)
end
local function groundObject(o,pos,yaw)
    local hit=groundHit(pos,o); if not hit then return false end
    local rot=CFrame.Angles(0,math.rad(yaw or 0),0)
    -- First place high enough to calculate the bounding box in its final rotation.
    pivot(o,CFrame.new(pos.X,hit.Position.Y+100,pos.Z)*rot)
    if o:IsA("Model") then
        local cf,sz=o:GetBoundingBox(); local bottom=cf.Position.Y-sz.Y/2; local dy=hit.Position.Y-bottom+.02; o:PivotTo(o:GetPivot()+Vector3.new(0,dy,0))
    else
        local bottom=o.Position.Y-o.Size.Y/2; o.CFrame=o.CFrame+Vector3.new(0,hit.Position.Y-bottom+.02,0)
    end
    return true
end

local function createAvatar(uid)
    local m
    local ok=pcall(function() m=Players:CreateHumanoidModelFromUserIdAsync(uid) end)
    if ok and m then return m end
    local d=Players:GetHumanoidDescriptionFromUserId(uid)
    return Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15)
end
local function animations(h)
    local a=h:FindFirstChildOfClass("Animator") or Instance.new("Animator",h)
    local idle=Instance.new("Animation"); local run=Instance.new("Animation")
    if h.RigType==Enum.HumanoidRigType.R15 then idle.AnimationId="rbxassetid://507766666"; run.AnimationId="rbxassetid://507767714" else idle.AnimationId="rbxassetid://180435571"; run.AnimationId="rbxassetid://180426354" end
    local it,rt; pcall(function() it=a:LoadAnimation(idle); rt=a:LoadAnimation(run) end); if it then it.Looped=true; it:Play(.1) end; if rt then rt.Looped=true end
    return {idle=it,run=rt,moving=false}
end
local function animate(st,speed)
    if not st then return end
    if speed>1.2 then
        if not st.moving then st.moving=true; if st.idle and st.idle.IsPlaying then st.idle:Stop(.1) end; if st.run and not st.run.IsPlaying then st.run:Play(.1) end end
        if st.run then st.run:AdjustSpeed(math.clamp(speed/16,.7,3)) end
    else
        if st.moving then st.moving=false; if st.run and st.run.IsPlaying then st.run:Stop(.12) end; if st.idle and not st.idle.IsPlaying then st.idle:Play(.12) end end
    end
end

-- Egg resolver: no startup scan. Search only when an egg is selected/spawned.
local EggCache={}
local function matchObj(o,want)
    if want[norm(o.Name)] then return true end
    for _,a in ipairs({"EggName","DisplayName","ItemName","Title","Type","PetName"}) do local v=o:GetAttribute(a); if v and want[norm(v)] then return true end end
    return false
end
local function findEgg(name)
    local c=EggCache[name]; if c and c.Parent then return c end
    local want={}; for _,a in ipairs(ALIAS[name] or {name}) do want[norm(a)]=true end
    for _,container in ipairs({ReplicatedStorage,workspace}) do
        local all=container:GetDescendants()
        for _,o in ipairs(all) do
            if o:IsA("Model") and not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) and o:FindFirstChildWhichIsA("BasePart",true) and matchObj(o,want) then EggCache[name]=o; return o end
        end
        for _,o in ipairs(all) do
            if o:IsA("BasePart") and not o:FindFirstAncestorOfClass("Model") and not o:IsDescendantOf(EggFolder) and matchObj(o,want) then EggCache[name]=o; return o end
        end
    end
    return nil
end
local function availableEggs() local a={}; for i=2,arrlen(EGGS) do if findEgg(EGGS[i]) then table.insert(a,EGGS[i]) end end; return a end
-- Map-center detection. General egg spawning is anchored to this map frame, never the player.
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

local function floorCandidateScore(o)
    if not o:IsA("BasePart") or not o.Anchored or not o.CanCollide or o.Transparency>=.98 then return -1 end
    local s=o.Size
    if s.X<20 or s.Z<20 then return -1 end
    local score=s.X*s.Z
    if s.Y<=18 then score=score*1.5 end
    local n=norm(o.Name)
    if n:find("floor",1,true) or n:find("ground",1,true) or n:find("arena",1,true) or n:find("map",1,true) then score=score*1.8 end
    if n:find("wall",1,true) or n:find("roof",1,true) or n:find("ceiling",1,true) then score=score*.08 end
    return score
end

local function detectMapCenter()
    local best=nil
    local bestScore=-1
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) then
            local s=floorCandidateScore(o)
            if s>bestScore then bestScore=s; best=o end
        end
    end
    if not best then
        local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        if not r then return false,"Map floor could not be detected." end
        local hit=groundHit(r.Position,nil)
        local pos=hit and hit.Position or r.Position
        MapFloor=nil
        MapCF=CFrame.new(pos)
        MapSize=Vector3.new(140,1,220)
        MapName="Fallback center"
        updateMapMarker()
        return true,MapName
    end
    MapFloor=best
    MapCF=best.CFrame
    MapSize=best.Size
    MapName=best.Name
    updateMapMarker()
    return true,MapName
end

local function setMapCenterHere()
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not r then return false,"Character unavailable." end
    local hit=groundHit(r.Position,nil)
    local pos=hit and hit.Position or r.Position
    MapFloor=nil
    MapCF=CFrame.new(pos)
    MapSize=Vector3.new(140,1,220)
    MapName="Manual map center"
    updateMapMarker()
    return true,MapName
end

local function getMapFrame()
    if MapFloor and MapFloor.Parent then MapCF=MapFloor.CFrame; MapSize=MapFloor.Size end
    if not MapCF then detectMapCenter() end
    return MapCF or CFrame.new(), MapSize or Vector3.new(140,1,220)
end

local function physicalLayout(count,sizeValue,baseCF,bounds)
    local scale=math.clamp(sizeValue,25,500)/100
    local usableX=math.max(35,bounds.X*.78)
    local usableZ=math.max(45,bounds.Z*.72)
    local desiredX=math.max(6,5+scale*3.8)
    local desiredZ=math.max(7,6+scale*4.2)
    local maxCols=math.max(6,math.floor(usableX/desiredX))
    maxCols=math.min(20,maxCols)
    local maxRows=math.max(1,math.floor(usableZ/desiredZ))
    local cols=math.min(count,maxCols)
    local neededRows=math.ceil(count/cols)
    if neededRows>maxRows then
        local neededCols=math.ceil(count/maxRows)
        cols=math.min(24,math.max(cols,neededCols))
        neededRows=math.ceil(count/cols)
    end
    local rows=neededRows
    local spaceX=math.min(desiredX,usableX/math.max(cols,1))
    local spaceZ=math.min(desiredZ,usableZ/math.max(rows,1))
    spaceX=math.max(4.5,spaceX)
    spaceZ=math.max(4.8,spaceZ)
    return cols,rows,spaceX,spaceZ
end

local function layoutPosition(index,count,sizeValue,baseCF,bounds)
    local cols,rows,sx,sz=physicalLayout(count,sizeValue,baseCF,bounds)
    local row=math.floor((index-1)/cols)
    local col=(index-1)%cols
    local x=(col-(cols-1)/2)*sx
    local z=(row-(rows-1)/2)*sz
    local pos=(baseCF*CFrame.new(x,0,z)).Position
    return pos,row,col,cols,rows,sx,sz
end

local function mixedEggFor(pattern,mix,row,col,index,cols)
    local n=arrlen(mix)
    if n==0 then return nil end
    if pattern=="ONE TYPE PER ROW" then
        return mix[(row%n)+1]
    elseif pattern=="SPLIT ROWS 3+3" then
        local g=math.floor(col/3)
        return mix[((row*2+g)%n)+1]
    elseif pattern=="PAIRS 2+2+2" then
        local g=math.floor(col/2)
        return mix[((row*3+g)%n)+1]
    elseif pattern=="MIRRORED ROWS" then
        local k=(row%2==0) and col or (cols-1-col)
        return mix[(k%n)+1]
    elseif pattern=="ALTERNATING ROWS" then
        return mix[((row%2)%n)+1]
    elseif pattern=="DIAGONAL SEQUENCE" then
        return mix[((row+col)%n)+1]
    end
    return mix[((index-1)%n)+1]
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
    local st=EggState[egg]; if not st or st.carried or st.delivered then return false end
    st.carried=true; st.claim=key; st.carrier=key; if st.prompt then st.prompt.Enabled=false end
    eggPhysics(egg,true); pivot(egg,carrier.CFrame*CFrame.new(1.7,-.35,-2.7)); weldEgg(egg); local er=rootOf(egg); if not er then st.carried=false; st.claim=nil; return false end
    eggPhysics(egg,false); local w=Instance.new("WeldConstraint"); w.Name="SAE_CarryWeld"; w.Part0=carrier; w.Part1=er; w.Parent=er; return true
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
local function registerEgg(egg,name,scale)
    local r=rootOf(egg); if not r then return end; local pr=Instance.new("ProximityPrompt"); pr.ActionText="Pick Up Egg"; pr.ObjectText=name; pr.KeyboardKeyCode=Enum.KeyCode.E; pr.HoldDuration=.05; pr.MaxActivationDistance=12; pr.RequiresLineOfSight=false; pr.Parent=r
    EggState[egg]={name=name,scale=scale,prompt=pr,carried=false,delivered=false,claim=nil}
    pr.Triggered:Connect(function() if HeldEgg then return end; local cr=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); if cr and carryEgg(egg,cr,"PLAYER",P.Character) then HeldEgg=egg; CarryName.Text="CARRYING: "..name; Carry.Visible=true end end)
end
local function spawnEggs(name,count,size,pattern,customCF,batchTag)
    local mix=nil
    if name=="MIXED" then
        mix=availableEggs()
        if arrlen(mix)==0 then return false,"No matching egg models are replicated to this client." end
    elseif not findEgg(name) then
        return false,name.." model is not replicated to this client."
    end

    count=math.clamp(tonumber(count) or 1,1,500)
    size=math.clamp(tonumber(size) or 100,25,500)
    pattern=pattern or PATTERNS[1]

    local baseCF,bounds=getMapFrame()
    if customCF then
        baseCF=customCF
        bounds=Vector3.new(110,1,150)
    end

    local made=0
    local lastCols=0
    local lastRows=0
    for i=1,count do
        local wanted,row,col,cols,rows=layoutPosition(i,count,size,baseCF,bounds)
        lastCols=cols; lastRows=rows
        local en=name
        if name=="MIXED" then en=mixedEggFor(pattern,mix,row,col,i,cols) end
        local t=en and findEgg(en) or nil
        if t then
            pcall(function()
                local c=t:Clone()
                c.Name=en
                if batchTag then c:SetAttribute("SAE_Batch",batchTag) end
                c.Parent=EggFolder
                local s=scaleEgg(c,size)
                eggPhysics(c,true)
                if groundObject(c,wanted,0) then
                    registerEgg(c,en,s)
                    made=made+1
                else
                    c:Destroy()
                end
            end)
        end
        if i%20==0 then task.wait() end
    end
    if made<=0 then return false,"No eggs could be placed on the detected floor." end
    return true,made,lastCols,lastRows
end

local function clearSpawnedEggs(batchTag)
    local removed=0
    for _,e in ipairs(EggFolder:GetChildren()) do
        if (not batchTag) or e:GetAttribute("SAE_Batch")==batchTag then
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
local Role="OWNER"; local Display=P.DisplayName; local Username=P.Name
local function applyTag()
    local ch=P.Character; if not ch then return end; local h=ch:FindFirstChildOfClass("Humanoid"); local head=ch:FindFirstChild("Head"); if h then h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.NameDisplayDistance=0; h.HealthDisplayDistance=0 end; if not head then return end
    local o=head:FindFirstChild("SAE_Tag"); if o then o:Destroy() end; local g=Instance.new("BillboardGui"); g.Name="SAE_Tag"; g.Size=UDim2.fromOffset(235,76); g.StudsOffset=Vector3.new(0,3.8,0); g.AlwaysOnTop=true; g.Parent=head
    local a=label(g,"["..Role.."]",UDim2.new(),UDim2.new(1,0,0,27),20); a.Font=Enum.Font.GothamBlack; a.TextXAlignment=Enum.TextXAlignment.Center; a.TextStrokeTransparency=0; a.TextColor3=Role=="OWNER" and C.red or C.purple2
    local b=label(g,Display,UDim2.fromOffset(0,29),UDim2.new(1,0,0,22),18); b.Font=Enum.Font.GothamBold; b.TextXAlignment=Enum.TextXAlignment.Center; b.TextStrokeTransparency=.1
    local c=label(g,"@"..Username:gsub("^@",""),UDim2.fromOffset(0,52),UDim2.new(1,0,0,18),14); c.TextXAlignment=Enum.TextXAlignment.Center; c.TextColor3=Color3.fromRGB(215,215,220)
end

-- Visual morph is parented under CurrentCamera, never workspace physics.
local MorphShell=nil; local MorphConn=nil; local Hidden={}; local MorphAnim=nil
local function restoreChar() for o,v in pairs(Hidden) do if o and o.Parent then pcall(function() if o:IsA("BasePart") then o.LocalTransparencyModifier=v elseif o:IsA("Decal") or o:IsA("Texture") then o.Transparency=v end end) end end; Hidden={} end
local function hideChar() restoreChar(); local ch=P.Character; if not ch then return end; for _,o in ipairs(ch:GetDescendants()) do if o:IsA("BasePart") then Hidden[o]=o.LocalTransparencyModifier; o.LocalTransparencyModifier=1 elseif o:IsA("Decal") or o:IsA("Texture") then Hidden[o]=o.Transparency; o.Transparency=1 end end end
local function resetMorph() if MorphConn then MorphConn:Disconnect(); MorphConn=nil end; if MorphShell then MorphShell:Destroy(); MorphShell=nil end; MorphAnim=nil; restoreChar() end
local function footOffset(m,r)
    local lowest=nil; for _,n in ipairs({"LeftFoot","RightFoot","Left Leg","Right Leg","LeftLowerLeg","RightLowerLeg"}) do local p=m:FindFirstChild(n,true); if p and p:IsA("BasePart") then local y=p.Position.Y-p.Size.Y/2; if not lowest or y<lowest then lowest=y end end end
    if lowest then return r.Position.Y-lowest end; local h=m:FindFirstChildOfClass("Humanoid"); return h and (h.HipHeight+r.Size.Y/2) or 3
end
local function doMorph(user)
    resetMorph()
    local uid
    if not pcall(function() uid=Players:GetUserIdFromNameAsync(user) end) then return false,"Username not found." end
    local m
    if not pcall(function() m=createAvatar(uid) end) or not m then return false,"Avatar could not be created." end

    local sr=m:FindFirstChild("HumanoidRootPart")
    local sh=m:FindFirstChildOfClass("Humanoid")
    local ch=P.Character
    local rr=ch and ch:FindFirstChild("HumanoidRootPart")
    if not sr or not sh or not rr then m:Destroy(); return false,"Morph root missing." end

    -- The shell is completely isolated from the real character. It is never welded to,
    -- parented under, or used to reposition the player's physical character.
    for _,o in ipairs(m:GetDescendants()) do
        if o:IsA("BasePart") then
            o.CanCollide=false
            o.CanTouch=false
            o.CanQuery=false
            o.Massless=true
            o.AssemblyLinearVelocity=Vector3.zero
            o.AssemblyAngularVelocity=Vector3.zero
            o.Anchored=false
        end
    end
    sr.Anchored=true
    sh.AutoRotate=false
    sh.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    sh.NameDisplayDistance=0
    sh.HealthDisplayDistance=0
    pcall(function() sh.EvaluateStateMachine=false end)

    m.Name="SAE_MorphShell"
    m:PivotTo(rr.CFrame)
    m.Parent=workspace.CurrentCamera or workspace
    MorphShell=m
    MorphAnim=animations(sh)
    hideChar()

    MorphConn=RunService.RenderStepped:Connect(function()
        if not MorphShell or not MorphShell.Parent then return end
        local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        if not r then return end
        -- Root-to-root alignment avoids the old vertical-offset bug that made the morph appear airborne.
        MorphShell:PivotTo(r.CFrame)
        sr.AssemblyLinearVelocity=Vector3.zero
        sr.AssemblyAngularVelocity=Vector3.zero
        local v=r.AssemblyLinearVelocity
        animate(MorphAnim,Vector3.new(v.X,0,v.Z).Magnitude)
    end)
    return true,"Morphed into @"..user
end

-- Trails.
local function addTrail(m,style)
    local r=m:FindFirstChild("HumanoidRootPart"); if not r then return nil end; local a=Instance.new("Attachment"); a.Position=Vector3.new(-1,-1,.55); a.Parent=r; local b=Instance.new("Attachment"); b.Position=Vector3.new(1,-1,.55); b.Parent=r
    local t=Instance.new("Trail"); t.Attachment0=a; t.Attachment1=b; t.Color=style[2]; t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.03),NumberSequenceKeypoint.new(1,1)}); t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}); t.Lifetime=.45; t.LightEmission=1; t.FaceCamera=true; t.Enabled=false; t.Parent=r; return t
end

-- Sammy.
local Sammy=nil
local SammyGen=0
local SammyTagMode="NONE"
local SammySpot=nil
local SammyAutoRefill=false
local SammyAdvertise=false
local SammyMessages={
    "Chat send a heart me for an invite",
    "Chat send a swan for a teleport in",
    "Chat send a boxing gloves for a teleport in"
}

local function sammyTag(m)
    local head=m:FindFirstChild("Head")
    if not head then return end
    local old=head:FindFirstChild("SAE_SammyTag")
    if old then old:Destroy() end

    local g=Instance.new("BillboardGui")
    g.Name="SAE_SammyTag"
    g.Size=UDim2.fromOffset(280,SammyTagMode=="NONE" and 58 or 82)
    g.StudsOffset=Vector3.new(0,3.5,0)
    g.AlwaysOnTop=true
    g.Parent=head

    local y=0
    if SammyTagMode~="NONE" then
        local role=label(g,"["..SammyTagMode.."]",UDim2.fromOffset(0,0),UDim2.new(1,0,0,22),17)
        role.TextXAlignment=Enum.TextXAlignment.Center
        role.Font=Enum.Font.GothamBlack
        role.TextStrokeTransparency=0
        role.TextColor3=(SammyTagMode=="CREATOR") and Color3.fromRGB(255,70,70) or C.purple2
        y=22
    end

    local row=Instance.new("Frame")
    row.BackgroundTransparency=1
    row.Position=UDim2.fromOffset(0,y)
    row.Size=UDim2.new(1,0,0,32)
    row.Parent=g
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    l.VerticalAlignment=Enum.VerticalAlignment.Center
    l.Padding=UDim.new(0,3)
    l.Parent=row
    local n=label(row,"Sammy",UDim2.new(),UDim2.fromOffset(0,30),24)
    n.AutomaticSize=Enum.AutomaticSize.X
    n.Font=Enum.Font.GothamBold
    n.TextStrokeTransparency=0
    -- Keep the exact Roblox verified glyph implementation the user approved.
    verified(row,23)
    local u=label(g,"@SpyderSammy",UDim2.fromOffset(0,y+34),UDim2.new(1,0,0,19),16)
    u.TextXAlignment=Enum.TextXAlignment.Center
    u.TextColor3=Color3.fromRGB(220,220,220)
end

local function refreshSammyTag()
    if Sammy and Sammy.Parent then sammyTag(Sammy) end
end

local function placeNPC(m,pos,dir)
    local r=m:FindFirstChild("HumanoidRootPart"); local h=m:FindFirstChildOfClass("Humanoid"); if not r or not h then return end; local hit=groundHit(pos,m); local y=hit and hit.Position.Y+h.HipHeight+r.Size.Y/2 or pos.Y; local d=Vector3.new(dir.X,0,dir.Z); if d.Magnitude<.1 then d=Vector3.new(0,0,-1) else d=d.Unit end; m:PivotTo(CFrame.lookAt(Vector3.new(pos.X,y,pos.Z),Vector3.new(pos.X,y,pos.Z)+d)); r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
end
local function despawnSammy() SammyGen=SammyGen+1; if Sammy then Sammy:Destroy(); Sammy=nil end end
local function spawnSammy()
    despawnSammy(); local uid; if not pcall(function() uid=Players:GetUserIdFromNameAsync(CFG.SammyUsername) end) then return false,"Sammy could not be resolved." end; local m; if not pcall(function() m=createAvatar(uid) end) or not m then return false,"Sammy avatar failed." end
    m.Name="Sammy"; m.Parent=NPCFolder; local h=m:FindFirstChildOfClass("Humanoid"); local r=m:FindFirstChild("HumanoidRootPart"); if not h or not r then m:Destroy(); return false,"Sammy root missing." end; h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.NameDisplayDistance=0; h.HealthDisplayDistance=0; h.AutoRotate=true; r.Anchored=false
    for _,o in ipairs(m:GetDescendants()) do if o:IsA("BasePart") and o:FindFirstAncestorOfClass("Accessory") then o.CanCollide=false; o.Massless=true end end
    local oroot=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); if oroot then placeNPC(m,oroot.Position-oroot.CFrame.LookVector*5+oroot.CFrame.RightVector*3.5,oroot.CFrame.LookVector) end
    sammyTag(m); local trail=addTrail(m,TRAILS[4]); local anim=animations(h); Sammy=m; SammyGen=SammyGen+1; local gen=SammyGen
    task.spawn(function()
        local side=1; local nextSide=os.clock()+7; local nextIdle=os.clock()+3; local idle=nil
        while Sammy==m and m.Parent and gen==SammyGen do
            task.wait(.08); local ch=P.Character; local pr=ch and ch:FindFirstChild("HumanoidRootPart"); local ph=ch and ch:FindFirstChildOfClass("Humanoid"); r=m:FindFirstChild("HumanoidRootPart"); h=m:FindFirstChildOfClass("Humanoid"); if pr and ph and r and h then
                local pv=pr.AssemblyLinearVelocity; local ps=Vector3.new(pv.X,0,pv.Z).Magnitude; h.WalkSpeed=math.max(tonumber(ph.WalkSpeed) or 16,ps); h.JumpPower=ph.JumpPower; h.JumpHeight=ph.JumpHeight; local now=os.clock(); if now>=nextSide then side=(math.random(0,1)==0) and -1 or 1; nextSide=now+math.random(6,10) end
                if ps>1.5 then idle=nil; local target=pr.Position-pr.CFrame.LookVector*5+pr.CFrame.RightVector*side*3.5; local hit=groundHit(target,m); h:MoveTo(hit and hit.Position or target)
                else if now>=nextIdle then nextIdle=now+math.random(25,55)/10; if math.random()<.75 then local a=math.random()*math.pi*2; local rad=math.random(30,75)/10; idle=pr.Position+Vector3.new(math.cos(a)*rad,0,math.sin(a)*rad) else idle=nil end end; if idle then local hit=groundHit(idle,m); h:MoveTo(hit and hit.Position or idle) end end
                local v=r.AssemblyLinearVelocity; local s=Vector3.new(v.X,0,v.Z).Magnitude; animate(anim,s); if trail then trail.Enabled=s>2 end
            end
        end
    end)
    return true,"Sammy spawned."
end

local function sammyBatchCenter()
    if SammySpot then return SammySpot end
    local cf=getMapFrame()
    return cf
end

local function spawnSammyBatch(refillOnly)
    local current=countBatch("SAMMY240")
    local target=240
    local need=refillOnly and math.max(0,target-current) or target
    if not refillOnly then clearSpawnedEggs("SAMMY240") end
    if need<=0 then return true,"Sammy batch is already full." end
    local cf=sammyBatchCenter()
    local ok,made=spawnEggs("MIXED",need,200,"DIAGONAL SEQUENCE",cf,"SAMMY240")
    if ok then return true,"Sammy batch: "..tostring(countBatch("SAMMY240")).." / 240 eggs." end
    return false,tostring(made)
end

local function markSammySpot()
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not r then return false,"Character unavailable." end
    local hit=groundHit(r.Position,nil)
    local p=hit and hit.Position or r.Position
    SammySpot=CFrame.new(p)
    return true,"Sammy egg spot marked."
end

local function sammyBanner(message)
    local id=P.UserId
    pcall(function() id=Players:GetUserIdFromNameAsync(CFG.SammyUsername) end)
    notice(id,"Sammy",":", "ANNOUNCEMENT", "- "..tostring(message))
end

-- Refill and advertising workers. They are idle unless the related switches are ON.
task.spawn(function()
    while Gui.Parent do
        task.wait(1)
        if SammyAutoRefill and countBatch("SAMMY240")<=190 then
            spawnSammyBatch(true)
        end
    end
end)

task.spawn(function()
    local index=1
    while Gui.Parent do
        task.wait(15)
        if SammyAdvertise then
            local msg=SammyMessages[index] or SammyMessages[1]
            if msg and msg~="" then sammyBanner(msg) end
            index=index+1
            if index>arrlen(SammyMessages) then index=1 end
        end
    end
end)

-- Safe zone and bots.
local SafeObj=nil; local SafePos=nil; local SafeName="Not locked"; local Marker=nil
local function objPos(o) if not o then return nil end; if o:IsA("BasePart") then return o.Position elseif o:IsA("Model") then return o:GetPivot().Position end; return nil end
local function safePosition() if SafeObj and SafeObj.Parent then local p=objPos(SafeObj); if p then local hit=groundHit(p,nil); SafePos=hit and hit.Position or p end end; return SafePos end
local function marker()
    if Marker then Marker:Destroy(); Marker=nil end; local p=safePosition(); if not p then return end; local x=Instance.new("Part"); x.Name="SAE_SafeZoneMarker"; x.Size=Vector3.new(8,.08,8); x.Anchored=true; x.CanCollide=false; x.CanTouch=false; x.CanQuery=false; x.Material=Enum.Material.Neon; x.Color=Color3.fromRGB(80,255,120); x.Transparency=.82; x.Position=p+Vector3.new(0,.08,0); x.Parent=workspace; Marker=x
end
local function detectSafe()
    local pr=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); local pp=pr and pr.Position or Vector3.zero; local best=nil; local score=-1e9
    for _,o in ipairs(workspace:GetDescendants()) do
        if (o:IsA("BasePart") or o:IsA("Model")) and not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) then
            local n=norm(o.Name); local s=0; if n:find("eggdropoff",1,true) then s=7000 elseif n:find("safezone",1,true) then s=6500 elseif n:find("deposit",1,true) then s=6000 elseif n:find("collector",1,true) then s=5200 elseif n:find("playerbase",1,true) then s=4700 elseif n:find("homebase",1,true) then s=4500 elseif n:find("safe",1,true) then s=4000 elseif n:find("base",1,true) then s=2800 elseif n:find("plot",1,true) then s=2500 end
            if s>0 then local p=objPos(o); if p then s=s-(p-pp).Magnitude*.05 end; for _,a in ipairs({"Owner","OwnerName","Player","PlayerName","OwnerId","OwnerUserId","UserId"}) do local v=o:GetAttribute(a); if v and (tostring(v)==P.Name or tostring(v)==P.DisplayName or tonumber(v)==P.UserId) then s=s+5000 end end; if s>score then score=s; best=o end end
        end
    end
    if not best then return false,"Safe zone not auto-detected. Stand in it and press SET HERE." end; SafeObj=best; SafePos=objPos(best); SafeName=best.Name; marker(); return true,SafeName
end
local function setSafeHere() local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); if not r then return false,"Character unavailable." end; local hit=groundHit(r.Position,nil); SafeObj=nil; SafePos=hit and hit.Position or r.Position; SafeName="Manual Safe Zone"; marker(); return true,SafeName end

local Bots={}
local function botPool() local a={}; for _,p in ipairs(Players:GetPlayers()) do if p~=P then table.insert(a,p.UserId) end end; return a end
local function fallbackBot(i)
    local d=Players:GetHumanoidDescriptionFromUserId(P.UserId):Clone(); local cols={Color3.fromRGB(245,205,48),Color3.fromRGB(80,175,255),Color3.fromRGB(255,120,120),Color3.fromRGB(125,255,150),Color3.fromRGB(185,120,255),Color3.fromRGB(255,180,90),Color3.fromRGB(105,225,220),Color3.fromRGB(220,220,220),Color3.fromRGB(255,115,220),Color3.fromRGB(150,195,255)}; local c=cols[((i-1)%arrlen(cols))+1]
    pcall(function() d.HeadColor=c; d.LeftArmColor=c; d.RightArmColor=c; d.LeftLegColor=c; d.RightLegColor=c; d.TorsoColor=c; d.HeightScale=.9+(i%5)*.03; d.WidthScale=.9+(i%3)*.04 end)
    return Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15)
end
local function botAvatar(i,pool) local uid=pool[i]; if uid then local ok,m=pcall(function() return createAvatar(uid) end); if ok and m then return m end end; return fallbackBot(i) end
local function botTag(m,id,trailName,stat)
    local head=m:FindFirstChild("Head"); if not head then return end; local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(270,65); g.StudsOffset=Vector3.new(0,3.5,0); g.AlwaysOnTop=true; g.Parent=head
    local a=label(g,id[1],UDim2.new(),UDim2.new(1,0,0,26),21); a.TextXAlignment=Enum.TextXAlignment.Center; a.Font=Enum.Font.GothamBold; a.TextStrokeTransparency=0
    local b=label(g,"@"..id[2],UDim2.fromOffset(0,27),UDim2.new(1,0,0,18),14); b.TextXAlignment=Enum.TextXAlignment.Center; b.TextColor3=Color3.fromRGB(220,220,225)
    local c=label(g,trailName.." - "..math.floor(stat/1000000).."M",UDim2.fromOffset(0,46),UDim2.new(1,0,0,15),10); c.TextXAlignment=Enum.TextXAlignment.Center; c.TextColor3=C.muted
end
local CollectorsEnabled=false

local function horizontalDistance(a,b)
    local dx=a.X-b.X
    local dz=a.Z-b.Z
    return math.sqrt(dx*dx+dz*dz)
end

local function nearestEgg(pos,key)
    local best=nil
    local dist=math.huge
    local now=os.clock()
    for e,st in pairs(EggState) do
        if e and e.Parent and not st.carried and not st.delivered then
            if st.claim and st.claim~=key and st.claimTime and now-st.claimTime>6 then
                st.claim=nil
                st.claimTime=nil
            end
            if not st.claim or st.claim==key then
                local r=rootOf(e)
                if r then
                    local d=horizontalDistance(r.Position,pos)
                    if d<dist then dist=d; best=e end
                end
            end
        end
    end
    return best
end

local function clearBots()
    CollectorsEnabled=false
    for _,b in ipairs(Bots) do
        if b.model and b.model.Parent then b.model:Destroy() end
    end
    Bots={}
    for _,st in pairs(EggState) do
        if st.claim and string.sub(st.claim,1,4)=="BOT_" then st.claim=nil; st.claimTime=nil end
    end
end

local function botBrain(d)
    task.spawn(function()
        local target=nil
        local carried=nil
        local lastDistance=nil
        local stuckSince=os.clock()
        while d.model and d.model.Parent do
            task.wait(.08)
            local m=d.model
            local h=m:FindFirstChildOfClass("Humanoid")
            local r=m:FindFirstChild("HumanoidRootPart")
            if not h or not r then break end
            h.WalkSpeed=d.speed
            h.AutoRotate=true

            if not CollectorsEnabled then
                h:MoveTo(r.Position)
            elseif carried and carried.Parent then
                local sp=safePosition()
                if sp then
                    h:MoveTo(sp)
                    if horizontalDistance(r.Position,sp)<=10 then
                        dropEgg(carried,sp+Vector3.new(math.random(-35,35)/10,0,math.random(-35,35)/10),true)
                        carried=nil
                        target=nil
                        lastDistance=nil
                        stuckSince=os.clock()
                    end
                end
            else
                carried=nil
                if target then
                    local st=EggState[target]
                    if not target.Parent or not st or st.carried or st.delivered or (st.claim and st.claim~=d.key) then
                        if st and st.claim==d.key then st.claim=nil; st.claimTime=nil end
                        target=nil
                        lastDistance=nil
                    end
                end

                if not target then
                    target=nearestEgg(r.Position,d.key)
                    if target and EggState[target] then
                        EggState[target].claim=d.key
                        EggState[target].claimTime=os.clock()
                        stuckSince=os.clock()
                        lastDistance=nil
                    end
                end

                if target then
                    local er=rootOf(target)
                    if er then
                        local hit=groundHit(er.Position,m)
                        h:MoveTo(hit and hit.Position or er.Position)
                        local hd=horizontalDistance(r.Position,er.Position)
                        if hd<=12 then
                            if carryEgg(target,r,d.key,m) then
                                carried=target
                                target=nil
                                lastDistance=nil
                            else
                                if EggState[target] then EggState[target].claim=nil; EggState[target].claimTime=nil end
                                target=nil
                            end
                        else
                            if lastDistance and hd<lastDistance-1 then stuckSince=os.clock() end
                            lastDistance=hd
                            if os.clock()-stuckSince>4.5 then
                                if EggState[target] then EggState[target].claim=nil; EggState[target].claimTime=nil end
                                target=nil
                                lastDistance=nil
                                stuckSince=os.clock()
                            end
                        end
                    end
                end
            end
        end
    end)
end

(function()
-- Restored UI/control wiring.
-- The original paste ended before this section, so the existing helpers above are left intact
-- and the panels are populated using those same functions/state objects.

local function panelBody(win, canvasHeight)
    local s=Instance.new("ScrollingFrame")
    s.Name="Body"
    s.Position=UDim2.fromOffset(8,68)
    s.Size=UDim2.new(1,-16,1,-76)
    s.BackgroundTransparency=1
    s.BorderSizePixel=0
    s.ScrollBarThickness=5
    s.ScrollBarImageColor3=C.purple2
    s.CanvasSize=UDim2.fromOffset(0,canvasHeight or 700)
    s.ScrollingDirection=Enum.ScrollingDirection.Y
    s.Parent=win
    return s
end

local function setStatus(lbl,msg,good)
    lbl.Text=tostring(msg or "")
    lbl.TextColor3=(good==false) and C.red or ((good==true) and C.green or C.muted)
end

local function selector(par,titleText,values,y,defaultIndex)
    local box=card(par,UDim2.fromOffset(8,y),UDim2.new(1,-16,0,54))
    local cap=label(box,titleText,UDim2.fromOffset(10,4),UDim2.new(1,-20,0,15),9)
    cap.TextColor3=C.muted
    cap.Font=Enum.Font.GothamBold
    local left=button(box,"<",UDim2.fromOffset(9,23),UDim2.fromOffset(30,24),true)
    local right=button(box,">",UDim2.new(1,-39,0,23),UDim2.fromOffset(30,24),true)
    local mid=button(box,"",UDim2.fromOffset(44,23),UDim2.new(1,-88,0,24),true)
    mid.TextSize=10
    local idx=math.clamp(defaultIndex or 1,1,math.max(1,#values))
    local function refresh()
        mid.Text=tostring(values[idx] or "")
    end
    local function step(n)
        if #values<=0 then return end
        idx=((idx-1+n)%#values)+1
        refresh()
    end
    left.MouseButton1Click:Connect(function() step(-1) end)
    right.MouseButton1Click:Connect(function() step(1) end)
    mid.MouseButton1Click:Connect(function() step(1) end)
    refresh()
    return {
        get=function() return values[idx] end,
        setIndex=function(n) idx=math.clamp(n,1,math.max(1,#values)); refresh() end,
        button=mid,
        frame=box
    }
end

local function toggleButton(par,textOff,textOn,pos,size,initial,onChange)
    local state=initial==true
    local b=button(par,"",pos,size,true)
    local function refresh()
        b.Text=state and textOn or textOff
        b.BackgroundColor3=state and C.purple or C.card2
    end
    b.MouseButton1Click:Connect(function()
        state=not state
        refresh()
        if onChange then onChange(state) end
    end)
    refresh()
    return b,function() return state end,function(v) state=v==true; refresh(); if onChange then onChange(state) end end
end

local function safeRemote(key,...)
    if not remote(CFG.Remotes[key]) then
        return false,key.." remote is not configured."
    end
    local ok,err=callRemote(key,...)
    if ok then return true,key.." sent." end
    return false,tostring(err or (key.." failed."))
end

local function spawnCollectors(n)
    clearBots()
    n=math.clamp(tonumber(n) or CFG.MaxBots,1,CFG.MaxBots)
    local pool=botPool()
    local pr=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    local made=0
    for i=1,n do
        local ok,m=pcall(function() return botAvatar(i,pool) end)
        if ok and m then
            m.Name="SAE_Collector_"..i
            m.Parent=NPCFolder
            local h=m:FindFirstChildOfClass("Humanoid")
            local r=m:FindFirstChild("HumanoidRootPart")
            if h and r then
                h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                h.NameDisplayDistance=0
                h.HealthDisplayDistance=0
                h.AutoRotate=true
                for _,o in ipairs(m:GetDescendants()) do
                    if o:IsA("BasePart") and o:FindFirstAncestorOfClass("Accessory") then
                        o.CanCollide=false
                        o.Massless=true
                    end
                end
                local ang=((i-1)/math.max(n,1))*math.pi*2
                local center=pr and pr.Position or getMapFrame().Position
                local pos=center+Vector3.new(math.cos(ang)*7,0,math.sin(ang)*7)
                local dir=pr and (pr.Position-pos) or Vector3.new(0,0,-1)
                placeNPC(m,pos,dir)
                local trailInfo=TRAILS[((i-1)%#TRAILS)+1]
                local tr=addTrail(m,trailInfo)
                if tr then tr.Enabled=true end
                local stat=math.random(120,980)*1000000
                local id=BOT_NAMES[((i-1)%#BOT_NAMES)+1]
                botTag(m,id,trailInfo[1],stat)
                local d={model=m,key="BOT_"..i,speed=18+((i-1)%4)*2,trail=tr,anim=animations(h)}
                table.insert(Bots,d)
                botBrain(d)
                made=made+1
            else
                m:Destroy()
            end
        end
        if i%3==0 then task.wait() end
    end
    return made
end

-- MAIN / ADMIN PANEL ---------------------------------------------------------
local MainBody=panelBody(Main,1040)
section(MainBody,"MAP + EGG SPAWNER",2)
local MapInfo=label(MainBody,"Map: "..MapName,UDim2.fromOffset(10,24),UDim2.new(1,-20,0,20),10)
MapInfo.TextColor3=C.muted
local DetectMapBtn=button(MainBody,"DETECT MAP",UDim2.fromOffset(8,48),UDim2.new(.5,-12,0,30),true)
local SetMapBtn=button(MainBody,"SET CENTER HERE",UDim2.new(.5,4,0,48),UDim2.new(.5,-12,0,30),true)

local EggSel=selector(MainBody,"EGG",EGGS,86,1)
local QtyValues={}
for _,v in ipairs(QTY) do table.insert(QtyValues,tostring(v)) end
local QtySel=selector(MainBody,"QUANTITY",QtyValues,146,1)
local PatternSel=selector(MainBody,"PATTERN",PATTERNS,206,1)
local SizeBox=card(MainBody,UDim2.fromOffset(8,266),UDim2.new(1,-16,0,54))
local SizeCap=label(SizeBox,"SIZE % (25 - 500)",UDim2.fromOffset(10,4),UDim2.new(1,-20,0,15),9); SizeCap.TextColor3=C.muted; SizeCap.Font=Enum.Font.GothamBold
local SizeInput=textbox(SizeBox,"100",UDim2.fromOffset(9,23),UDim2.new(1,-18,0,24),"100")
local SpawnEggBtn=button(MainBody,"SPAWN EGGS",UDim2.fromOffset(8,328),UDim2.new(.64,-12,0,34),false)
local ClearEggBtn=button(MainBody,"CLEAR",UDim2.new(.64,4,0,328),UDim2.new(.36,-12,0,34),true)
local EggStatus=label(MainBody,"Ready.",UDim2.fromOffset(10,367),UDim2.new(1,-20,0,36),10); EggStatus.TextWrapped=true; EggStatus.TextColor3=C.muted

DetectMapBtn.MouseButton1Click:Connect(function()
    local ok,msg=detectMapCenter()
    MapInfo.Text="Map: "..tostring(msg)
    setStatus(EggStatus,ok and ("Detected: "..tostring(msg)) or msg,ok)
end)
SetMapBtn.MouseButton1Click:Connect(function()
    local ok,msg=setMapCenterHere()
    MapInfo.Text="Map: "..tostring(msg)
    setStatus(EggStatus,msg,ok)
end)
SpawnEggBtn.MouseButton1Click:Connect(function()
    local egg=EggSel.get()
    local qty=tonumber(QtySel.get()) or 200
    local size=tonumber(SizeInput.Text) or 100
    local pat=PatternSel.get()
    setStatus(EggStatus,"Spawning "..tostring(qty).." eggs...",nil)
    task.spawn(function()
        local ok,a,b,c=spawnEggs(egg,qty,size,pat)
        if ok then
            setStatus(EggStatus,"Spawned "..tostring(a).." eggs ("..tostring(b).." x "..tostring(c)..").",true)
        else
            setStatus(EggStatus,tostring(a),false)
        end
    end)
end)
ClearEggBtn.MouseButton1Click:Connect(function()
    local n=clearSpawnedEggs()
    setStatus(EggStatus,"Cleared "..tostring(n).." spawned eggs.",true)
end)

section(MainBody,"ANNOUNCEMENTS",414)
local AnnounceInput=textbox(MainBody,"Announcement text",UDim2.fromOffset(8,437),UDim2.new(1,-16,0,34),"")
local LocalAnn=button(MainBody,"LOCAL",UDim2.fromOffset(8,478),UDim2.new(.33,-8,0,30),true)
local ServerAnn=button(MainBody,"SERVER",UDim2.new(.33,0,0,478),UDim2.new(.34,-8,0,30),true)
local GlobalAnn=button(MainBody,"GLOBAL",UDim2.new(.67,0,0,478),UDim2.new(.33,-8,0,30),true)
local AnnStatus=label(MainBody,"",UDim2.fromOffset(10,512),UDim2.new(1,-20,0,31),10); AnnStatus.TextWrapped=true; AnnStatus.TextColor3=C.muted
LocalAnn.MouseButton1Click:Connect(function()
    local t=AnnounceInput.Text
    if t=="" then setStatus(AnnStatus,"Type an announcement first.",false); return end
    notice(P.UserId,P.DisplayName,":","ANNOUNCEMENT","- "..t)
    setStatus(AnnStatus,"Local announcement shown.",true)
end)
ServerAnn.MouseButton1Click:Connect(function()
    local t=AnnounceInput.Text
    if t=="" then setStatus(AnnStatus,"Type an announcement first.",false); return end
    local ok,msg=safeRemote("Announcement",t)
    setStatus(AnnStatus,msg,ok)
end)
GlobalAnn.MouseButton1Click:Connect(function()
    local t=AnnounceInput.Text
    if t=="" then setStatus(AnnStatus,"Type an announcement first.",false); return end
    local ok,msg=safeRemote("GlobalAnnouncement",t)
    setStatus(AnnStatus,msg,ok)
end)

section(MainBody,"SERVER ACTIONS",552)
local TargetInput=textbox(MainBody,"Target username",UDim2.fromOffset(8,575),UDim2.new(1,-16,0,32),"")
local ActionStatus=label(MainBody,"Remotes only run when configured in CFG.Remotes.",UDim2.fromOffset(10,611),UDim2.new(1,-20,0,31),9); ActionStatus.TextWrapped=true; ActionStatus.TextColor3=C.muted
local function actionButton(text,key,x,y,w)
    local b=button(MainBody,text,UDim2.fromOffset(x,y),UDim2.fromOffset(w,30),true)
    b.MouseButton1Click:Connect(function()
        local target=TargetInput.Text
        local ok,msg
        if target~="" then ok,msg=safeRemote(key,target) else ok,msg=safeRemote(key) end
        setStatus(ActionStatus,msg,ok)
    end)
    return b
end
actionButton("BOOST","Boost",8,648,106)
actionButton("CLEAR BOOST","ClearBoost",121,648,116)
actionButton("METEOR","Meteor",244,648,108)
actionButton("TELEPORT","Teleport",8,685,106)
actionButton("INVITE","Invite",121,685,116)
actionButton("GIVE ADMIN","GiveAdmin",244,685,108)
actionButton("COOWNER","GiveCoowner",8,722,106)
actionButton("GIVE VPS","GiveVPS",121,722,116)
actionButton("SPAWN REMOTE","SpawnEggs",244,722,108)

section(MainBody,"YOUR OVERHEAD TAG",765)
local RoleSel=selector(MainBody,"ROLE",{"OWNER","COOWNER","ADMIN","CREATOR"},788,1)
local ApplyRoleBtn=button(MainBody,"APPLY TAG",UDim2.fromOffset(8,850),UDim2.new(1,-16,0,32),false)
local TagStatus=label(MainBody,"",UDim2.fromOffset(10,886),UDim2.new(1,-20,0,28),10); TagStatus.TextColor3=C.muted
ApplyRoleBtn.MouseButton1Click:Connect(function()
    Role=RoleSel.get()
    Display=P.DisplayName
    Username=P.Name
    applyTag()
    setStatus(TagStatus,"Applied ["..Role.."] tag.",true)
end)

-- MORPH PANEL ---------------------------------------------------------------
local MorphBody=panelBody(Morph,360)
section(MorphBody,"AVATAR",2)
local MorphUser=textbox(MorphBody,"Roblox username",UDim2.fromOffset(8,28),UDim2.new(1,-16,0,38),P.Name)
local MorphGo=button(MorphBody,"MORPH",UDim2.fromOffset(8,76),UDim2.new(.62,-12,0,36),false)
local MorphReset=button(MorphBody,"RESET",UDim2.new(.62,4,0,76),UDim2.new(.38,-12,0,36),true)
local MorphSammy=button(MorphBody,"MORPH AS @"..CFG.SammyUsername,UDim2.fromOffset(8,120),UDim2.new(1,-16,0,34),true)
local MorphStatus=label(MorphBody,"Enter a username, then press MORPH.",UDim2.fromOffset(10,164),UDim2.new(1,-20,0,54),10); MorphStatus.TextWrapped=true; MorphStatus.TextColor3=C.muted
MorphGo.MouseButton1Click:Connect(function()
    local user=MorphUser.Text:gsub("^@","")
    if user=="" then setStatus(MorphStatus,"Enter a username.",false); return end
    setStatus(MorphStatus,"Loading avatar...",nil)
    task.spawn(function()
        local ok,msg=doMorph(user)
        setStatus(MorphStatus,msg,ok)
    end)
end)
MorphSammy.MouseButton1Click:Connect(function()
    MorphUser.Text=CFG.SammyUsername
    setStatus(MorphStatus,"Loading avatar...",nil)
    task.spawn(function()
        local ok,msg=doMorph(CFG.SammyUsername)
        setStatus(MorphStatus,msg,ok)
    end)
end)
MorphReset.MouseButton1Click:Connect(function()
    resetMorph()
    setStatus(MorphStatus,"Morph reset.",true)
end)

-- NPC / COLLECTOR PANEL -----------------------------------------------------
local BotsBody=panelBody(BotsPanel,1130)
section(BotsBody,"SAFE ZONE",2)
local SafeInfo=label(BotsBody,"Safe: "..SafeName,UDim2.fromOffset(10,24),UDim2.new(1,-20,0,20),10); SafeInfo.TextColor3=C.muted
local DetectSafeBtn=button(BotsBody,"AUTO DETECT",UDim2.fromOffset(8,48),UDim2.new(.5,-12,0,30),true)
local SetSafeBtn=button(BotsBody,"SET HERE",UDim2.new(.5,4,0,48),UDim2.new(.5,-12,0,30),true)
local SafeStatus=label(BotsBody,"Collectors deliver eggs here.",UDim2.fromOffset(10,82),UDim2.new(1,-20,0,30),9); SafeStatus.TextWrapped=true; SafeStatus.TextColor3=C.muted
DetectSafeBtn.MouseButton1Click:Connect(function()
    local ok,msg=detectSafe(); SafeInfo.Text="Safe: "..tostring(msg); setStatus(SafeStatus,msg,ok)
end)
SetSafeBtn.MouseButton1Click:Connect(function()
    local ok,msg=setSafeHere(); SafeInfo.Text="Safe: "..tostring(msg); setStatus(SafeStatus,msg,ok)
end)

section(BotsBody,"COLLECTORS",120)
local BotCount=textbox(BotsBody,"1 - "..CFG.MaxBots,UDim2.fromOffset(8,145),UDim2.new(.33,-8,0,32),tostring(CFG.MaxBots))
local SpawnBotsBtn=button(BotsBody,"SPAWN NPCS",UDim2.new(.33,0,0,145),UDim2.new(.34,-8,0,32),false)
local ClearBotsBtn=button(BotsBody,"CLEAR",UDim2.new(.67,0,0,145),UDim2.new(.33,-8,0,32),true)
local CollectToggle=button(BotsBody,"COLLECTORS: OFF",UDim2.fromOffset(8,184),UDim2.new(1,-16,0,34),true)
local BotStatus=label(BotsBody,"",UDim2.fromOffset(10,222),UDim2.new(1,-20,0,38),9); BotStatus.TextWrapped=true; BotStatus.TextColor3=C.muted
local function refreshCollectToggle()
    CollectToggle.Text=CollectorsEnabled and "COLLECTORS: ON" or "COLLECTORS: OFF"
    CollectToggle.BackgroundColor3=CollectorsEnabled and C.purple or C.card2
end
SpawnBotsBtn.MouseButton1Click:Connect(function()
    local n=math.clamp(tonumber(BotCount.Text) or CFG.MaxBots,1,CFG.MaxBots)
    setStatus(BotStatus,"Spawning collectors...",nil)
    task.spawn(function()
        local made=spawnCollectors(n)
        setStatus(BotStatus,"Spawned "..made.." / "..n.." collectors.",made>0)
    end)
end)
ClearBotsBtn.MouseButton1Click:Connect(function()
    clearBots(); refreshCollectToggle(); setStatus(BotStatus,"Collectors cleared.",true)
end)
CollectToggle.MouseButton1Click:Connect(function()
    if not SafePos then
        local ok,msg=detectSafe()
        if not ok then setStatus(BotStatus,msg,false); return end
        SafeInfo.Text="Safe: "..tostring(msg)
    end
    CollectorsEnabled=not CollectorsEnabled
    refreshCollectToggle()
    setStatus(BotStatus,CollectorsEnabled and "Collectors are collecting eggs." or "Collectors paused.",true)
end)
refreshCollectToggle()

section(BotsBody,"SAMMY",270)
local SammySpawn=button(BotsBody,"SPAWN SAMMY",UDim2.fromOffset(8,295),UDim2.new(.5,-12,0,32),false)
local SammyDespawn=button(BotsBody,"DESPAWN",UDim2.new(.5,4,0,295),UDim2.new(.5,-12,0,32),true)
local SammyTagSel=selector(BotsBody,"SAMMY TAG",{"NONE","CREATOR","ADMIN","COOWNER"},335,1)
local SammyApplyTag=button(BotsBody,"APPLY SAMMY TAG",UDim2.fromOffset(8,395),UDim2.new(1,-16,0,30),true)
local SammyStatus=label(BotsBody,"",UDim2.fromOffset(10,430),UDim2.new(1,-20,0,34),9); SammyStatus.TextWrapped=true; SammyStatus.TextColor3=C.muted
SammySpawn.MouseButton1Click:Connect(function()
    setStatus(SammyStatus,"Loading Sammy...",nil)
    task.spawn(function() local ok,msg=spawnSammy(); setStatus(SammyStatus,msg,ok) end)
end)
SammyDespawn.MouseButton1Click:Connect(function()
    despawnSammy(); setStatus(SammyStatus,"Sammy despawned.",true)
end)
SammyApplyTag.MouseButton1Click:Connect(function()
    SammyTagMode=SammyTagSel.get(); refreshSammyTag(); setStatus(SammyStatus,"Sammy tag: "..SammyTagMode,true)
end)

section(BotsBody,"SAMMY EGG BATCH",475)
local MarkSpotBtn=button(BotsBody,"MARK SPOT",UDim2.fromOffset(8,500),UDim2.new(.33,-8,0,30),true)
local SpawnBatchBtn=button(BotsBody,"SPAWN 240",UDim2.new(.33,0,0,500),UDim2.new(.34,-8,0,30),false)
local ClearBatchBtn=button(BotsBody,"CLEAR 240",UDim2.new(.67,0,0,500),UDim2.new(.33,-8,0,30),true)
local BatchInfo=label(BotsBody,"Batch: 0 / 240",UDim2.fromOffset(10,536),UDim2.new(1,-20,0,22),9); BatchInfo.TextColor3=C.muted
MarkSpotBtn.MouseButton1Click:Connect(function()
    local ok,msg=markSammySpot(); setStatus(SammyStatus,msg,ok)
end)
SpawnBatchBtn.MouseButton1Click:Connect(function()
    setStatus(SammyStatus,"Spawning Sammy egg batch...",nil)
    task.spawn(function()
        local ok,msg=spawnSammyBatch(false)
        BatchInfo.Text="Batch: "..countBatch("SAMMY240").." / 240"
        setStatus(SammyStatus,msg,ok)
    end)
end)
ClearBatchBtn.MouseButton1Click:Connect(function()
    local n=clearSpawnedEggs("SAMMY240")
    BatchInfo.Text="Batch: 0 / 240"
    setStatus(SammyStatus,"Cleared "..n.." Sammy batch eggs.",true)
end)

local RefillBtn=button(BotsBody,"AUTO REFILL: OFF",UDim2.fromOffset(8,568),UDim2.new(.5,-12,0,32),true)
local AdvertiseBtn=button(BotsBody,"ADVERTISE: OFF",UDim2.new(.5,4,0,568),UDim2.new(.5,-12,0,32),true)
local function refreshSammySwitches()
    RefillBtn.Text=SammyAutoRefill and "AUTO REFILL: ON" or "AUTO REFILL: OFF"
    RefillBtn.BackgroundColor3=SammyAutoRefill and C.purple or C.card2
    AdvertiseBtn.Text=SammyAdvertise and "ADVERTISE: ON" or "ADVERTISE: OFF"
    AdvertiseBtn.BackgroundColor3=SammyAdvertise and C.purple or C.card2
end
RefillBtn.MouseButton1Click:Connect(function() SammyAutoRefill=not SammyAutoRefill; refreshSammySwitches() end)
AdvertiseBtn.MouseButton1Click:Connect(function() SammyAdvertise=not SammyAdvertise; refreshSammySwitches() end)
refreshSammySwitches()

section(BotsBody,"SAMMY AD MESSAGES",613)
local Msg1=textbox(BotsBody,"Message 1",UDim2.fromOffset(8,638),UDim2.new(1,-16,0,30),SammyMessages[1])
local Msg2=textbox(BotsBody,"Message 2",UDim2.fromOffset(8,674),UDim2.new(1,-16,0,30),SammyMessages[2])
local Msg3=textbox(BotsBody,"Message 3",UDim2.fromOffset(8,710),UDim2.new(1,-16,0,30),SammyMessages[3])
local SaveMsgs=button(BotsBody,"SAVE MESSAGES",UDim2.fromOffset(8,748),UDim2.new(1,-16,0,30),true)
SaveMsgs.MouseButton1Click:Connect(function()
    SammyMessages[1]=Msg1.Text; SammyMessages[2]=Msg2.Text; SammyMessages[3]=Msg3.Text
    setStatus(SammyStatus,"Advertising messages updated.",true)
end)

section(BotsBody,"LOCAL CLEANUP",791)
local ClearAllNPC=button(BotsBody,"CLEAR NPCS + SAMMY",UDim2.fromOffset(8,816),UDim2.new(.5,-12,0,32),true)
local ClearAllEgg=button(BotsBody,"CLEAR ALL EGGS",UDim2.new(.5,4,0,816),UDim2.new(.5,-12,0,32),true)
ClearAllNPC.MouseButton1Click:Connect(function() clearBots(); despawnSammy(); refreshCollectToggle(); setStatus(SammyStatus,"NPCs cleared.",true) end)
ClearAllEgg.MouseButton1Click:Connect(function() local n=clearSpawnedEggs(); BatchInfo.Text="Batch: 0 / 240"; setStatus(SammyStatus,"Cleared "..n.." eggs.",true) end)

-- CONSOLE -------------------------------------------------------------------
local ConsoleBody=Instance.new("Frame")
ConsoleBody.BackgroundTransparency=1
ConsoleBody.Position=UDim2.fromOffset(10,70)
ConsoleBody.Size=UDim2.new(1,-20,1,-80)
ConsoleBody.Parent=Console
local ConsoleLog=Instance.new("TextLabel")
ConsoleLog.BackgroundColor3=C.card
ConsoleLog.BorderSizePixel=0
ConsoleLog.Position=UDim2.fromOffset(0,0)
ConsoleLog.Size=UDim2.new(1,0,1,-46)
ConsoleLog.Font=Enum.Font.Code
ConsoleLog.TextSize=12
ConsoleLog.TextColor3=C.white
ConsoleLog.TextXAlignment=Enum.TextXAlignment.Left
ConsoleLog.TextYAlignment=Enum.TextYAlignment.Top
ConsoleLog.TextWrapped=false
ConsoleLog.RichText=false
ConsoleLog.Text=""
ConsoleLog.Parent=ConsoleBody
corner(ConsoleLog,8); stroke(ConsoleLog,.45)
local ConsoleInput=textbox(ConsoleBody,"Command: help",UDim2.new(0,0,1,-38),UDim2.new(1,0,0,34),"")
ConsoleInput.Font=Enum.Font.Code
local ConsoleLines={}
local function consolePrint(msg)
    table.insert(ConsoleLines,"["..os.date("%H:%M:%S").."] "..tostring(msg))
    while #ConsoleLines>22 do table.remove(ConsoleLines,1) end
    ConsoleLog.Text=table.concat(ConsoleLines,"\n")
end
local function cmdWords(s)
    local t={}
    for w in tostring(s):gmatch("%S+") do table.insert(t,w) end
    return t
end
local function runConsole(line)
    local a=cmdWords(line)
    local cmd=string.lower(a[1] or "")
    if cmd=="" then return end
    if cmd=="help" then
        consolePrint("map | setmap | safe | setsafe | eggs <name> <count> <size> | cleareggs")
        consolePrint("morph <user> | unmorph | bots <1-"..CFG.MaxBots.."> | collect on/off | clearbots")
        consolePrint("sammy | unsammy | sammyeggs | clearsammyeggs | role <name>")
    elseif cmd=="map" then
        local ok,msg=detectMapCenter(); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="setmap" then
        local ok,msg=setMapCenterHere(); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="safe" then
        local ok,msg=detectSafe(); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="setsafe" then
        local ok,msg=setSafeHere(); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="cleareggs" then
        consolePrint("Cleared "..clearSpawnedEggs().." eggs")
    elseif cmd=="eggs" then
        local name=a[2] or "MIXED"
        local count=tonumber(a[3]) or 200
        local size=tonumber(a[4]) or 100
        local ok,msg=spawnEggs(name,count,size,PATTERNS[1])
        consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="morph" then
        local u=a[2]
        if not u then consolePrint("Usage: morph <username>") else local ok,msg=doMorph(u:gsub("^@","")); consolePrint(tostring(ok).." - "..tostring(msg)) end
    elseif cmd=="unmorph" then
        resetMorph(); consolePrint("Morph reset")
    elseif cmd=="bots" then
        local n=tonumber(a[2]) or CFG.MaxBots
        consolePrint("Spawned "..spawnCollectors(n).." collectors")
    elseif cmd=="collect" then
        local v=string.lower(a[2] or "")
        if v=="on" then if not SafePos then detectSafe() end; CollectorsEnabled=true elseif v=="off" then CollectorsEnabled=false else CollectorsEnabled=not CollectorsEnabled end
        refreshCollectToggle(); consolePrint("Collectors: "..(CollectorsEnabled and "ON" or "OFF"))
    elseif cmd=="clearbots" then
        clearBots(); refreshCollectToggle(); consolePrint("Collectors cleared")
    elseif cmd=="sammy" then
        local ok,msg=spawnSammy(); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="unsammy" then
        despawnSammy(); consolePrint("Sammy despawned")
    elseif cmd=="sammyeggs" then
        local ok,msg=spawnSammyBatch(false); consolePrint(tostring(ok).." - "..tostring(msg))
    elseif cmd=="clearsammyeggs" then
        consolePrint("Cleared "..clearSpawnedEggs("SAMMY240").." Sammy eggs")
    elseif cmd=="role" then
        Role=string.upper(a[2] or "OWNER"); applyTag(); consolePrint("Role tag: "..Role)
    elseif cmd=="clear" then
        ConsoleLines={}; ConsoleLog.Text=""
    else
        consolePrint("Unknown command: "..cmd)
    end
end
ConsoleInput.FocusLost:Connect(function(enter)
    if not enter then return end
    local s=ConsoleInput.Text
    ConsoleInput.Text=""
    consolePrint("> "..s)
    task.spawn(function()
        local ok,err=pcall(runConsole,s)
        if not ok then consolePrint("ERROR: "..tostring(err)) end
    end)
end)
consolePrint("SAE console ready. Press TAB to show/hide. Type help for commands.")

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Tab then
        Console.Visible=not Console.Visible
    elseif input.KeyCode==Enum.KeyCode.X and not UserInputService:GetFocusedTextBox() then
        dropHeld()
    end
end)

P.CharacterAdded:Connect(function()
    task.delay(.75,function()
        if Gui.Parent then
            resetMorph()
            applyTag()
        end
    end)
end)

task.defer(function()
    applyTag()
    local ok,msg=detectMapCenter()
    MapInfo.Text="Map: "..tostring(msg)
    if ok then setStatus(EggStatus,"Map ready: "..tostring(msg),true) end
end)

end)()
