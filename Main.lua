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
            BackgroundColor3=hovering and Color3.fromRGB(100,49,160) or x:GetAttribute("RestingColor"),
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
    drag(hd,f); return f
end

-- Create every important panel immediately before any game scan.
local Main=window("MainPanel","⚡ ADMIN ABUSE","Developer control panel",344,172,UDim2.new(.22,0,.52,0))
Main.BackgroundTransparency=.12
local Morph=window("MorphPanel","Avatar Morpher","Change your avatar's look",350,290,UDim2.new(.74,0,.28,0))
local BotsPanel=window("BotPanel","NPC COLLECTORS","Collectors, avatars and Sammy",400,505,UDim2.new(.74,0,.68,0))
Morph.BackgroundTransparency=Main.BackgroundTransparency
BotsPanel.BackgroundTransparency=Main.BackgroundTransparency
local Console=window("ConsolePanel","SERVER CONSOLE","TAB opens or closes this window",710,410,UDim2.new(.5,0,.5,0)); Console.Visible=false

-- Remove any overlay left by older versions.
local oldSnow=PG:FindFirstChild("SAE_SnowOverlay")
if oldSnow then oldSnow:Destroy() end

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
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart",true) or o:FindFirstChildWhichIsA("BasePart",true) end
end
local function pivot(o,cf) if o:IsA("Model") then o:PivotTo(cf) elseif o:IsA("BasePart") then o.CFrame=cf end end

local function groundHit(pos,ignore)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder,NPCFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,250,0),Vector3.new(0,-1000,0),rp)
end

local function groundHitNear(pos,ignore)
    -- Short raycast around the active character height. This avoids choosing
    -- roofs/ceilings that a 250-stud-above ray can hit first.
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder,NPCFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
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
    if not o or o==EggFolder or o==NPCFolder then return nil end
    if o:IsDescendantOf(EggFolder) or o:IsDescendantOf(NPCFolder) then return nil end

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
            if not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) and matchObj(o,want) then
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
local Marker=nil
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
        if o:IsA("BasePart") and not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) then
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
local CoownerColor=Color3.fromRGB(112,43,180)
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

    local roleText="["..Role.."]"
    local a=label(g,roleText,UDim2.new(),UDim2.new(1,0,0,27),20)
    a.Font=Enum.Font.GothamBlack
    a.TextXAlignment=Enum.TextXAlignment.Center
    a.TextStrokeTransparency=0
    a.TextStrokeColor3=Color3.new(0,0,0)
    a.TextColor3=Role=="OWNER" and Color3.fromRGB(235,18,35) or (Role=="CO-OWNER" and CoownerColor or C.purple2)
    if Role=="OWNER" or Role=="CO-OWNER" then
        -- Keep the dark outline separate from the moving color highlight.
        local shine=label(g,roleText,a.Position,a.Size,20)
        shine.Font=a.Font
        shine.TextXAlignment=Enum.TextXAlignment.Center
        shine.TextColor3=C.white
        shine.TextStrokeTransparency=1
        local gradient=Instance.new("UIGradient")
        gradient.Color=Role=="CO-OWNER" and ColorSequence.new({
            ColorSequenceKeypoint.new(0,CoownerColor),
            ColorSequenceKeypoint.new(.42,Color3.fromRGB(145,66,205)),
            ColorSequenceKeypoint.new(.5,Color3.fromRGB(225,202,255)),
            ColorSequenceKeypoint.new(.58,Color3.fromRGB(145,66,205)),
            ColorSequenceKeypoint.new(1,CoownerColor)
        }) or ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(225,18,33)),
            ColorSequenceKeypoint.new(.42,Color3.fromRGB(255,36,48)),
            ColorSequenceKeypoint.new(.5,Color3.fromRGB(255,220,220)),
            ColorSequenceKeypoint.new(.58,Color3.fromRGB(255,36,48)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(225,18,33))
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
        selector.owner:SetAttribute("RestingColor",role=="OWNER" and C.red or C.card2)
        selector.coowner:SetAttribute("RestingColor",role=="CO-OWNER" and CoownerColor or C.card2)
        selector.admin:SetAttribute("RestingColor",role=="ADMIN" and C.purple or C.card2)
        if selector.status then
            selector.status.Text=role.." tag applied."
            selector.status.TextColor3=C.green
        end
    end
end
local function addRoleSelector(owner,coowner,admin,status)
    table.insert(RoleSelectors,{owner=owner,coowner=coowner,admin=admin,status=status})
    owner:SetAttribute("RestingColor",Role=="OWNER" and C.red or C.card2)
    coowner:SetAttribute("RestingColor",Role=="CO-OWNER" and CoownerColor or C.card2)
    admin:SetAttribute("RestingColor",Role=="ADMIN" and C.purple or C.card2)
    owner.MouseButton1Click:Connect(function() setRole("OWNER") end)
    coowner.MouseButton1Click:Connect(function() setRole("CO-OWNER") end)
    admin.MouseButton1Click:Connect(function() setRole("ADMIN") end)
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
                params.FilterDescendantsInstances={character,model,EggFolder,NPCFolder}
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
    local r=m:FindFirstChild("HumanoidRootPart")
    local h=m:FindFirstChildOfClass("Humanoid")
    if not r or not h then return end
    local hit=groundHitNear(pos,m)
    local y=hit and hit.Position.Y+h.HipHeight+r.Size.Y/2 or pos.Y
    local d=Vector3.new(dir.X,0,dir.Z)
    if d.Magnitude<.1 then d=Vector3.new(0,0,-1) else d=d.Unit end
    m:PivotTo(CFrame.lookAt(Vector3.new(pos.X,y,pos.Z),Vector3.new(pos.X,y,pos.Z)+d))
    r.AssemblyLinearVelocity=Vector3.zero
    r.AssemblyAngularVelocity=Vector3.zero
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
    if SammySpot then return select(1,visibleSpawnFrame(SammySpot)) end
    if Sammy and Sammy.Parent then
        local r=Sammy:FindFirstChild("HumanoidRootPart")
        if r then
            local hit=groundHitNear(r.Position,Sammy)
            local p=hit and hit.Position or (r.Position-Vector3.new(0,3,0))
            return select(1,visibleSpawnFrame(CFrame.new(p)))
        end
    end
    return select(1,visibleSpawnFrame(nil))
end

local function spawnSammyBatch(refillOnly)
    local target=240
    if not refillOnly then clearSpawnedEggs("SAMMY240") end

    local cf=sammyBatchCenter()
    for attempt=1,3 do
        local current=countBatch("SAMMY240")
        local need=math.max(0,target-current)
        if need<=0 then
            return true,"Sammy batch: 240 / 240 eggs."
        end

        local ok,msg=spawnEggs("MIXED",need,200,"DIAGONAL SEQUENCE",cf,"SAMMY240")
        if not ok and attempt==3 then
            return false,"Sammy batch stopped at "..tostring(countBatch("SAMMY240")).." / 240. "..tostring(msg)
        end
        task.wait()
    end

    local final=countBatch("SAMMY240")
    return final>=target, final>=target and "Sammy batch: 240 / 240 eggs." or ("Sammy batch: "..tostring(final).." / 240 eggs.")
end

local function markSammySpot()
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if not r then return false,"Character unavailable." end
    local hit=groundHitNear(r.Position,nil)
    local p=hit and hit.Position or (r.Position-Vector3.new(0,3,0))
    SammySpot=CFrame.new(p)
    return true,"Sammy egg spot marked."
end

local function sammyBanner(message)
    local msg=tostring(message or "")
    if msg=="" then return end
    local id=P.UserId
    pcall(function() id=Players:GetUserIdFromNameAsync(CFG.SammyUsername) end)
    notice(id,"Sammy","says:","",msg)
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

-- Safe zone and bots. State was declared before the map/layout code so egg
-- spawning can reserve this area before collectors are started.
local function objPos(o) if not o then return nil end; if o:IsA("BasePart") then return o.Position elseif o:IsA("Model") then return o:GetPivot().Position end end
local function safePosition() if SafeObj and SafeObj.Parent then local p=objPos(SafeObj); if p then local hit=groundHitNear(p,nil); SafePos=hit and hit.Position or p end end; return SafePos end
local function marker()
    if Marker then Marker:Destroy(); Marker=nil end; local p=safePosition(); if not p then return end; local x=Instance.new("Part"); x.Name="SAE_SafeZoneMarker"; x.Size=Vector3.new(8,.08,8); x.Anchored=true; x.CanCollide=false; x.CanTouch=false; x.CanQuery=false; x.Material=Enum.Material.Neon; x.Color=Color3.fromRGB(80,255,120); x.Transparency=.82; x.Position=p+Vector3.new(0,.08,0); x.Parent=workspace; Marker=x
end
detectSafe=function()
    local pr=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); local pp=pr and pr.Position or Vector3.zero; local best=nil; local score=-1e9
    for _,o in ipairs(workspace:GetDescendants()) do
        if (o:IsA("BasePart") or o:IsA("Model")) and not o:IsDescendantOf(EggFolder) and not o:IsDescendantOf(NPCFolder) then
            local n=norm(o.Name); local s=0; if n:find("eggdropoff",1,true) then s=7000 elseif n:find("safezone",1,true) then s=6500 elseif n:find("deposit",1,true) then s=6000 elseif n:find("collector",1,true) then s=5200 elseif n:find("playerbase",1,true) then s=4700 elseif n:find("homebase",1,true) then s=4500 elseif n:find("safe",1,true) then s=4000 elseif n:find("base",1,true) then s=2800 elseif n:find("plot",1,true) then s=2500 end
            if s>0 then local p=objPos(o); if p then s=s-(p-pp).Magnitude*.05 end; for _,a in ipairs({"Owner","OwnerName","Player","PlayerName","OwnerId","OwnerUserId","UserId"}) do local v=o:GetAttribute(a); if v and (tostring(v)==P.Name or tostring(v)==P.DisplayName or tonumber(v)==P.UserId) then s=s+5000 end end; if s>score then score=s; best=o end end
        end
    end
    if not best then return false,"Safe zone not auto-detected. Stand in it and press SET HERE." end; SafeObj=best; SafePos=objPos(best); SafeName=best.Name; marker(); return true,SafeName
end
local function setSafeHere() local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart"); if not r then return false,"Character unavailable." end; local hit=groundHitNear(r.Position,nil); SafeObj=nil; SafePos=hit and hit.Position or (r.Position-Vector3.new(0,3,0)); SafeName="Manual Safe Zone"; marker(); return true,SafeName end

local Bots={}

-- Collector bots are generated locally and do NOT depend on how many real
-- players are in the server. Selecting 1-10 always attempts that exact count.
local BaseBotDescription=nil
local function getBaseBotDescription()
    if BaseBotDescription then return BaseBotDescription end
    local desc=nil
    pcall(function() desc=Players:GetHumanoidDescriptionFromUserId(P.UserId) end)
    BaseBotDescription=desc or Instance.new("HumanoidDescription")
    return BaseBotDescription
end

local function fallbackBot(i)
    local d=getBaseBotDescription():Clone()
    local cols={
        Color3.fromRGB(245,205,48),Color3.fromRGB(80,175,255),Color3.fromRGB(255,120,120),
        Color3.fromRGB(125,255,150),Color3.fromRGB(185,120,255),Color3.fromRGB(255,180,90),
        Color3.fromRGB(105,225,220),Color3.fromRGB(220,220,220),Color3.fromRGB(255,115,220),
        Color3.fromRGB(150,195,255)
    }
    local c=cols[((i-1)%arrlen(cols))+1]
    pcall(function()
        d.HeadColor=c
        d.LeftArmColor=c
        d.RightArmColor=c
        d.LeftLegColor=c
        d.RightLegColor=c
        d.TorsoColor=c
        d.HeightScale=.94+((i-1)%4)*.025
        d.WidthScale=.92+((i-1)%3)*.035
        d.HeadScale=.95+((i-1)%3)*.025
    end)

    local model=nil
    local ok=pcall(function()
        model=Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15)
    end)
    if ok and model then return model end

    -- Last-resort clone: still independent of other players in the server.
    local ch=P.Character
    if ch then
        local oldArchivable=ch.Archivable
        ch.Archivable=true
        pcall(function() model=ch:Clone() end)
        ch.Archivable=oldArchivable
        if model then
            for _,o in ipairs(model:GetDescendants()) do
                if o:IsA("Script") or o:IsA("LocalScript") or o:IsA("Tool") then
                    pcall(function() o:Destroy() end)
                end
            end
            return model
        end
    end
    return nil
end

local function botAvatar(i)
    return fallbackBot(i)
end

local function botTag(m,id,trailName,stat)
    local head=m:FindFirstChild("Head")
    if not head then return end

    local g=Instance.new("BillboardGui")
    g.Name="SAE_BotTag"
    g.Size=UDim2.fromOffset(220,46)
    g.StudsOffset=Vector3.new(0,3.25,0)
    g.AlwaysOnTop=true
    g.MaxDistance=70
    g.Parent=head

    local a=label(g,id[1],UDim2.fromOffset(0,0),UDim2.new(1,0,0,23),17)
    a.TextXAlignment=Enum.TextXAlignment.Center
    a.Font=Enum.Font.GothamMedium
    a.TextStrokeTransparency=.55
    a.TextStrokeColor3=Color3.new(0,0,0)

    local b=label(g,"@"..id[2],UDim2.fromOffset(0,23),UDim2.new(1,0,0,18),13)
    b.TextXAlignment=Enum.TextXAlignment.Center
    b.Font=Enum.Font.Gotham
    b.TextColor3=Color3.fromRGB(205,205,210)
    b.TextStrokeTransparency=.72
    b.TextStrokeColor3=Color3.new(0,0,0)
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
                        local hit=groundHitNear(er.Position,m)
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
                    else
                        target=nil
                    end
                end
            end

            local v=r.AssemblyLinearVelocity
            local s=Vector3.new(v.X,0,v.Z).Magnitude
            animate(d.anim,s)
            if d.trail then d.trail.Enabled=s>2 end
        end
    end)
end

local function spawnBots(n)
    if not safePosition() then detectSafe() end
    local safe=safePosition()
    if not safe then return false,"Lock the safe zone first." end

    clearBots()
    CollectorsEnabled=true
    n=math.clamp(n,1,10)
    local eggTarget=nil
    local nearest=nearestEgg(safe,"BOT_SPAWN_LOOK")
    local er=nearest and rootOf(nearest) or nil
    if er then eggTarget=er.Position end
    if not eggTarget then eggTarget=select(1,getMapFrame()).Position end

    local dir=Vector3.new(eggTarget.X-safe.X,0,eggTarget.Z-safe.Z)
    if dir.Magnitude<.1 then dir=Vector3.new(0,0,-1) else dir=dir.Unit end
    local right=Vector3.new(-dir.Z,0,dir.X)

    for i=1,n do
        local ok,m=pcall(function() return botAvatar(i) end)
        if (not ok) or (not m) then
            ok,m=pcall(function() return fallbackBot(i) end)
        end
        if ok and m then
            m.Name="Egg Bot "..i
            m.Parent=NPCFolder
            local h=m:FindFirstChildOfClass("Humanoid")
            local r=m:FindFirstChild("HumanoidRootPart")
            if h and r then
                h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                h.NameDisplayDistance=0
                h.HealthDisplayDistance=0
                h.AutoRotate=true
                r.Anchored=false

                local id=BOT_NAMES[((i-1)%arrlen(BOT_NAMES))+1]
                local tr=TRAILS[math.random(1,arrlen(TRAILS))]
                local stat=math.random(200,270)*1000000
                local speed=90+((stat-200000000)/70000000)*35

                -- Spawn in a small formation INSIDE the safe zone.
                local row=math.floor((i-1)/4)
                local col=(i-1)%4
                local lateral=(col-1.5)*3.4
                local backward=row*3.2
                local spawnPos=safe+right*lateral-dir*backward
                placeNPC(m,spawnPos,dir)

                local trail=addTrail(m,tr)
                local d={model=m,key="BOT_"..i.."_"..id[2],speed=speed,trail=trail,anim=animations(h)}
                botTag(m,id,tr[1],stat)
                table.insert(Bots,d)
                botBrain(d)
            else
                m:Destroy()
            end
        end
        task.wait(.04)
    end
    return true,tostring(arrlen(Bots)).." bots spawned from Safe Zone: "..SafeName
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
local EggIndex=1
local Amount=200
local EggSize=100
local Pattern=PATTERNS[1]

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
        Home=172, ["Spawn eggs"]=398, ["Mixed egg layouts"]=352,
        Announcements=336, ["Admin Abuse"]=286, ["Boost Effects"]=404, Meteor=364,
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
local EggsPage=newAdminPage("Spawn eggs",false)
local PatternPage=newAdminPage("Mixed egg layouts",false)
local AnnouncePage=newAdminPage("Announcements",false)
local AdminAbusePage=newAdminPage("Admin Abuse",false)
local NamesPage=newAdminPage("Names",false)

local Builders={}

function Builders.Home()
-- HOME
local homeItems={
    {"Eggs","Spawn eggs"},{"Announce","Announcements"},
    {"Names","Names"},{"Admin Abuse","Admin Abuse"}
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
    b.MouseButton1Click:Connect(function() showAdminPage(item[2],true) end)
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

function Builders.SpawnEggs()
-- SPAWN EGGS page
local chooseBtn=button(EggsPage,"Choose egg",UDim2.fromOffset(4,4),UDim2.new(.5,-8,0,34),true)
local mixedBtn=button(EggsPage,"Mixed eggs",UDim2.new(.5,4,0,4),UDim2.new(.5,-8,0,34),true)
local selectedEggLabel=label(EggsPage,"Selected: MIXED",UDim2.fromOffset(5,42),UDim2.new(1,-10,0,18),10)
selectedEggLabel.TextColor3=C.purple2
chooseBtn.MouseButton1Click:Connect(function()
    EggIndex=EggIndex+1
    if EggIndex>arrlen(EGGS) then EggIndex=2 end
    if EggIndex==1 then EggIndex=2 end
    selectedEggLabel.Text="Selected: "..EGGS[EggIndex]
end)
mixedBtn.MouseButton1Click:Connect(function() EggIndex=1; selectedEggLabel.Text="Selected: MIXED" end)

local patternBtn=button(EggsPage,"Layout: ORIGINAL 6x20",UDim2.fromOffset(4,64),UDim2.new(1,-8,0,30),true)
patternBtn.MouseButton1Click:Connect(function() showAdminPage("Mixed egg layouts",true) end)

section(EggsPage,"QUANTITY",101)
local amountValues={200,250,300,350,400,450,500}
local amountButtons={}
for i,v in ipairs(amountValues) do
    local value=v
    local b=button(EggsPage,tostring(value),UDim2.new((i-1)/7,3,0,124),UDim2.new(1/7,-6,0,26),true)
    amountButtons[value]=b
    b.MouseButton1Click:Connect(function()
        Amount=value
        for k,x in pairs(amountButtons) do x:SetAttribute("RestingColor",(k==Amount) and C.purple or C.card2) end
    end)
end
amountButtons[200]:SetAttribute("RestingColor",C.purple)

local sizeValue=function() return EggSize end
sizeValue=intSlider(EggsPage,158,25,500,5,100,"Egg scale",function(v) EggSize=v end)
local spawnBtn=button(EggsPage,"Spawn behind me",UDim2.fromOffset(4,210),UDim2.new(.5,-8,0,34),false)
local clearEggBtn=button(EggsPage,"Clear eggs",UDim2.new(.5,4,0,210),UDim2.new(.5,-8,0,34),true)
local spawnStatus=label(EggsPage,"Spawns eggs behind you, facing your direction.",UDim2.fromOffset(5,250),UDim2.new(1,-10,0,36),11)
spawnStatus.TextWrapped=true; spawnStatus.TextColor3=C.muted
spawnBtn.MouseButton1Click:Connect(function()
    spawnBtn.Text="SPAWNING..."
    local en=EGGS[EggIndex]
    -- Each click is one clean batch, so choosing 500 means exactly 500 GENERAL eggs.
    clearSpawnedEggs("GENERAL")
    if callRemote("SpawnEggs",{Egg=en,Quantity=Amount,Size=EggSize,Pattern=Pattern,BehindPlayer=true}) then
        spawnStatus.Text="Server spawn request sent."
        spawnStatus.TextColor3=C.green
    else
        local ok,made,cols,rows,fallbacks=spawnEggs(en,Amount,EggSize,Pattern,nil,"GENERAL")
        if ok then
            spawnStatus.Text=tostring(made).." eggs spawned: "..tostring(rows).." rows, "..tostring(cols).." per row."
            spawnStatus.TextColor3=C.green
            notice(P.UserId,Display,": spawned",tostring(made).." EGGS","")
        else
            spawnStatus.Text=tostring(made); spawnStatus.TextColor3=C.red
        end
    end
    spawnBtn.Text="Spawn behind me"
end)
clearEggBtn.MouseButton1Click:Connect(function() local n=clearSpawnedEggs(); spawnStatus.Text="Cleared "..n.." spawned egg(s)."; spawnStatus.TextColor3=C.green end)

-- mixed layout page from the reference screenshots
local patternDescriptions={
    ["ORIGINAL 6x20"]="20 eggs across; a six-type sequence repeats through each row.",
    ["ONE TYPE PER ROW"]="Every egg in one row is the same type; the next row changes type.",
    ["SPLIT ROWS 3+3"]="Three of one type, then three of the next type, repeating across the row.",
    ["PAIRS 2+2+2"]="Two of type A, two of type B, two of type C, repeating across the row.",
    ["MIRRORED ROWS"]="Every second row reverses the left-to-right sequence.",
    ["ALTERNATING ROWS"]="Whole rows alternate between two egg types.",
    ["DIAGONAL SEQUENCE"]="Each row shifts the sequence by one, making diagonal bands."
}
local patStatus=label(PatternPage,"Choose a mixed egg layout",UDim2.fromOffset(5,0),UDim2.new(1,-10,0,22),11); patStatus.Font=Enum.Font.GothamBold
for i,n in ipairs(PATTERNS) do
    local patternName=n
    local row=math.floor((i-1)/2); local col=(i-1)%2
    local wide=(i==arrlen(PATTERNS) and (arrlen(PATTERNS)%2==1))
    local pos=wide and UDim2.fromOffset(4,30+row*42) or UDim2.new(col*.5,col==0 and 4 or 4,0,30+row*42)
    local sz=wide and UDim2.new(1,-8,0,36) or UDim2.new(.5,-8,0,36)
    local b=button(PatternPage,patternName, pos, sz,true)
    b.TextSize=10
    b.TextWrapped=true
    b.MouseButton1Click:Connect(function()
        Pattern=patternName
        patternBtn.Text="Layout: "..patternName
        patStatus.Text=patternName.." selected"
        showAdminPage("Spawn eggs",false)
    end)
end
local patInfo=label(PatternPage,"Choose how mixed egg types repeat across rows.",UDim2.fromOffset(5,202),UDim2.new(1,-10,0,38),11)
patInfo.TextWrapped=true; patInfo.TextColor3=C.muted

end
Builders.SpawnEggs()
Builders.SpawnEggs=nil

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
    notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,global and ": sent a" or ": sent an",global and "GLOBAL ANNOUNCEMENT" or "ANNOUNCEMENT","- "..msg)
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

function Builders.AdminAbuse()
-- A small menu keeps boosts and meteor controls on separate branches.
local BoostsPage=newAdminPage("Boost Effects",true)
local EventsPage=newAdminPage("Meteor",false)
section(AdminAbusePage,"EVENTS AND EFFECTS",4)
local boostsBtn=button(AdminAbusePage,"Boost Effects",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,34),true)
local boostsHint=label(AdminAbusePage,"Announce or clear any boost effect.",UDim2.fromOffset(9,68),UDim2.new(1,-18,0,24),11)
boostsHint.TextWrapped=true; boostsHint.TextColor3=C.muted
local meteorBtn=button(AdminAbusePage,"Meteor",UDim2.fromOffset(5,102),UDim2.new(1,-10,0,34),true)
local meteorHint=label(AdminAbusePage,"Start a countdown, drop a meteor, or cancel it.",UDim2.fromOffset(9,142),UDim2.new(1,-18,0,28),11)
meteorHint.TextWrapped=true; meteorHint.TextColor3=C.muted
boostsBtn.MouseButton1Click:Connect(function() showAdminPage("Boost Effects",true) end)
meteorBtn.MouseButton1Click:Connect(function() showAdminPage("Meteor",true) end)

local AdminList=Instance.new("UIListLayout")
AdminList.Padding=UDim.new(0,7)
AdminList.SortOrder=Enum.SortOrder.LayoutOrder
AdminList.Parent=BoostsPage

-- METEOR controls.
local eventTitle=label(EventsPage,"DRILL MONSTER METEOR",UDim2.fromOffset(5,2),UDim2.new(1,-10,0,22),12); eventTitle.Font=Enum.Font.GothamBold
local eventDesc=label(EventsPage,"Drops a meteor, 10 Drilla eggs, and up to 4 Drill Monsters.",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,42),11); eventDesc.TextWrapped=true; eventDesc.TextYAlignment=Enum.TextYAlignment.Top
local meteorStatus=label(EventsPage,"No meteor active.",UDim2.fromOffset(5,76),UDim2.new(1,-10,0,20),10); meteorStatus.TextColor3=C.muted
local countdownBtn=button(EventsPage,"Start countdown - 00:50",UDim2.fromOffset(5,102),UDim2.new(1,-10,0,32),false)
local dropMeteorBtn=button(EventsPage,"Drop meteor now",UDim2.fromOffset(5,140),UDim2.new(1,-10,0,32),true)
local timerBox=textbox(EventsPage,"Timer seconds (1-600)",UDim2.fromOffset(5,178),UDim2.new(.5,-8,0,32),"50")
local setTimerBtn=button(EventsPage,"Set timer",UDim2.new(.5,3,0,178),UDim2.new(.5,-8,0,32),true)
local clearMeteorBtn=button(EventsPage,"Clear / cancel",UDim2.fromOffset(5,216),UDim2.new(1,-10,0,30),true)
countdownBtn.MouseButton1Click:Connect(function()
    local seconds=tonumber(timerBox.Text) or 50
    startMeteorCountdown(seconds,function(s) countdownBtn.Text="Countdown - "..string.format("%02d:%02d",math.floor(s/60),s%60); meteorStatus.Text="Meteor countdown active"; meteorStatus.TextColor3=C.orange end)
end)
dropMeteorBtn.MouseButton1Click:Connect(function() local ok,msg=dropMeteorNow(); meteorStatus.Text=msg; meteorStatus.TextColor3=ok and C.green or C.red end)
setTimerBtn.MouseButton1Click:Connect(function() local s=math.clamp(tonumber(timerBox.Text) or 50,1,600); timerBox.Text=tostring(s); countdownBtn.Text="Start countdown - "..string.format("%02d:%02d",math.floor(s/60),s%60) end)
clearMeteorBtn.MouseButton1Click:Connect(function() clearMeteor(); meteorStatus.Text="No meteor active."; meteorStatus.TextColor3=C.muted; countdownBtn.Text="Start countdown - 00:50" end)

-- BOOSTS: every existing effect stays in this scrollable branch.
local boostHeader=label(BoostsPage,"BOOSTS - announce or clear an effect.",UDim2.new(),UDim2.new(1,-8,0,28),11)
boostHeader.TextWrapped=true; boostHeader.TextColor3=C.muted; boostHeader.LayoutOrder=1
for index,name in ipairs(BOOST_NAMES) do
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-8,0,68)
    row.BackgroundColor3=C.card
    row.BorderSizePixel=0
    row.Parent=BoostsPage
    row.LayoutOrder=index+1
    corner(row,10); stroke(row,.62)
    local nm=label(row,name,UDim2.fromOffset(8,4),UDim2.new(1,-20,0,20),11); nm.Font=Enum.Font.GothamBold
    local state=label(row,"OFF",UDim2.fromOffset(8,32),UDim2.fromOffset(50,28),11); state.TextXAlignment=Enum.TextXAlignment.Center; state.Font=Enum.Font.GothamBold
    local announce=button(row,"Announce",UDim2.fromOffset(66,30),UDim2.new(.5,-42,0,30),false)
    local clear=button(row,"Clear",UDim2.new(.5,34,0,30),UDim2.new(.5,-42,0,30),true)
    announce.MouseButton1Click:Connect(function() announceBoost(name,true); state.Text="ON"; state.TextColor3=C.green end)
    clear.MouseButton1Click:Connect(function() announceBoost(name,false); state.Text="OFF"; state.TextColor3=C.white end)
end
local clearAllBoosts=button(BoostsPage,"Clear all boost effects",UDim2.new(),UDim2.new(1,-8,0,32),true)
clearAllBoosts.LayoutOrder=#BOOST_NAMES+2
clearAllBoosts.MouseButton1Click:Connect(function() for _,n in ipairs(BOOST_NAMES) do if BoostState[n] then announceBoost(n,false) end end end)
AdminList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() BoostsPage.CanvasSize=UDim2.fromOffset(0,AdminList.AbsoluteContentSize.Y+12) end)
task.defer(function() BoostsPage.CanvasSize=UDim2.fromOffset(0,AdminList.AbsoluteContentSize.Y+12) end)

end
Builders.AdminAbuse()
Builders.AdminAbuse=nil

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
local morphOwnerRole=button(Morph,"OWNER",UDim2.fromOffset(12,224),UDim2.new(1/3,-12,0,30),true)
local morphCoownerRole=button(Morph,"CO-OWNER",UDim2.new(1/3,6,0,224),UDim2.new(1/3,-12,0,30),true)
local morphAdminRole=button(Morph,"ADMIN",UDim2.new(2/3,0,0,224),UDim2.new(1/3,-12,0,30),true)
addRoleSelector(morphOwnerRole,morphCoownerRole,morphAdminRole)
local morphStatus=label(Morph,"Changes your avatar appearance locally.",UDim2.fromOffset(12,262),UDim2.new(1,-24,0,18),10); morphStatus.TextWrapped=true; morphStatus.TextColor3=C.muted
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

function Builders.Collectors()
-- NPC COLLECTORS panel with Collectors / Avatar / Sammy tabs.
local BotTabs=Instance.new("Frame"); BotTabs.Position=UDim2.fromOffset(12,71); BotTabs.Size=UDim2.new(1,-24,0,36); BotTabs.BackgroundTransparency=1; BotTabs.Parent=BotsPanel
local BotTabButtons={}; local BotPages={}
local function newBotPage(n)
    local f=Instance.new("ScrollingFrame")
    f.Position=UDim2.fromOffset(12,112); f.Size=UDim2.new(1,-24,1,-124); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.ScrollBarThickness=4; f.ScrollBarImageColor3=C.purple; f.CanvasSize=UDim2.new(); f.Visible=false; f.Parent=BotsPanel
    BotPages[n]=f; return f
end
local CollectorsPage=newBotPage("Collectors")
local BotAvatarPage=newBotPage("Avatar")
local BotSammyPage=newBotPage("Sammy")
local function showBotPage(n) for k,p in pairs(BotPages) do p.Visible=(k==n) end; for k,b in pairs(BotTabButtons) do b:SetAttribute("RestingColor",(k==n) and C.purple or C.card2) end end
for i,n in ipairs({"Collectors","Avatar","Sammy"}) do local b=button(BotTabs,n,UDim2.new((i-1)/3,3*(i-1),0,0),UDim2.new(1/3,-6,0,32),true); BotTabButtons[n]=b; b.MouseButton1Click:Connect(function() showBotPage(n) end) end

-- Collectors tab
local SafeCard=card(CollectorsPage,UDim2.fromOffset(0,0),UDim2.new(1,-6,0,111)); section(SafeCard,"SAFE ZONE",7)
local collectorSafeStatus=label(SafeCard,"NOT LOCKED",UDim2.fromOffset(10,29),UDim2.new(1,-20,0,20),10); collectorSafeStatus.Font=Enum.Font.GothamBold; collectorSafeStatus.TextColor3=C.orange
local autoSafe=button(SafeCard,"AUTO DETECT",UDim2.fromOffset(10,61),UDim2.new(.5,-15,0,34),false)
local setSafe=button(SafeCard,"SET HERE",UDim2.new(.5,5,0,61),UDim2.new(.5,-15,0,34),true)
local function refreshSafeUI() if safePosition() then collectorSafeStatus.Text="LOCKED - "..SafeName; collectorSafeStatus.TextColor3=C.green else collectorSafeStatus.Text="NOT LOCKED"; collectorSafeStatus.TextColor3=C.orange end end
autoSafe.MouseButton1Click:Connect(function() local ok,msg=detectSafe(); refreshSafeUI(); if not ok then collectorSafeStatus.Text=msg; collectorSafeStatus.TextColor3=C.red end end)
setSafe.MouseButton1Click:Connect(function() local ok,msg=setSafeHere(); refreshSafeUI(); if not ok then collectorSafeStatus.Text=msg; collectorSafeStatus.TextColor3=C.red end end)
local NPCCount=2
local WaveDelay=5
intSlider(CollectorsPage,125,1,10,1,2,"NPCS PER WAVE",function(v) NPCCount=v end)
intSlider(CollectorsPage,180,1,15,1,5,"WAVE DELAY (SEC)",function(v) WaveDelay=v end)
local collectorsToggle=button(CollectorsPage,"COLLECTORS: OFF",UDim2.fromOffset(0,238),UDim2.new(1,-6,0,38),true)
local clearNPCBtn=button(CollectorsPage,"Stop / clear NPCs",UDim2.fromOffset(0,283),UDim2.new(1,-6,0,36),true)
local collectorInfo=label(CollectorsPage,"Eggs: 0 | NPCs: 0",UDim2.fromOffset(5,326),UDim2.new(1,-16,0,28),9); collectorInfo.TextColor3=C.muted
collectorsToggle.MouseButton1Click:Connect(function()
    if CollectorsEnabled then
        CollectorsEnabled=false; collectorsToggle.Text="COLLECTORS: OFF"; collectorsToggle:SetAttribute("RestingColor",C.card2)
    else
        if arrlen(Bots)==0 then local ok,msg=spawnBots(NPCCount); if not ok then collectorInfo.Text=msg; collectorInfo.TextColor3=C.red; return end else CollectorsEnabled=true end
        collectorsToggle.Text="COLLECTORS: ON"; collectorsToggle:SetAttribute("RestingColor",C.purple); collectorInfo.Text="Collectors bring eggs to the safe zone."; collectorInfo.TextColor3=C.green
    end
end)
clearNPCBtn.MouseButton1Click:Connect(function() clearBots(); collectorsToggle.Text="COLLECTORS: OFF"; collectorsToggle:SetAttribute("RestingColor",C.card2); collectorInfo.Text="NPCs cleared."; collectorInfo.TextColor3=C.muted end)
CollectorsPage.CanvasSize=UDim2.fromOffset(0,366)

task.spawn(function()
    while Gui.Parent do
        task.wait(1)
        if collectorInfo and collectorInfo.Parent then
            local active=0
            for _,b in ipairs(Bots) do if b.model and b.model.Parent then active=active+1 end end
            local eggs=0
            for e,st in pairs(EggState) do if e and e.Parent and not st.delivered then eggs=eggs+1 end end
            if CollectorsEnabled then collectorInfo.Text="Eggs: "..eggs.." | NPCs: "..active.." | collecting" end
        end
    end
end)

-- Avatar tab
local avatarCard=card(BotAvatarPage,UDim2.fromOffset(0,0),UDim2.new(1,-6,0,195))
section(avatarCard,"COLLECTOR APPEARANCE",8)
local av1=label(avatarCard,"Different avatars: ON",UDim2.fromOffset(12,37),UDim2.new(1,-24,0,22),11); av1.TextColor3=C.green
local av2=label(avatarCard,"Random trail per bot: ON",UDim2.fromOffset(12,68),UDim2.new(1,-24,0,22),11); av2.TextColor3=C.green
local av3=label(avatarCard,"Displayed speed stat: 200M - 270M",UDim2.fromOffset(12,99),UDim2.new(1,-24,0,22),11); av3.TextColor3=C.green
local refreshBots=button(avatarCard,"Refresh collector avatars",UDim2.fromOffset(10,139),UDim2.new(1,-20,0,39),false)
local avatarStatus=label(BotAvatarPage,"Refresh to spawn collectors with new avatars.",UDim2.fromOffset(5,211),UDim2.new(1,-16,0,50),9); avatarStatus.TextWrapped=true; avatarStatus.TextColor3=C.muted
refreshBots.MouseButton1Click:Connect(function() if not safePosition() then avatarStatus.Text="Lock the safe zone first."; avatarStatus.TextColor3=C.orange; return end; local ok,msg=spawnBots(NPCCount); avatarStatus.Text=msg; avatarStatus.TextColor3=ok and C.green or C.red; if ok then CollectorsEnabled=true; collectorsToggle.Text="COLLECTORS: ON"; collectorsToggle:SetAttribute("RestingColor",C.purple) end end)
BotAvatarPage.CanvasSize=UDim2.fromOffset(0,275)

-- Sammy tab, closely matching the reference panel.
local sy=0
local sammyHeader=label(BotSammyPage,"SAMMY S7 - 240 MIXED EGGS / 2x",UDim2.fromOffset(5,sy),UDim2.new(1,-16,0,26),11); sammyHeader.Font=Enum.Font.GothamBold; sy=sy+32
local spawnSammyButton=button(BotSammyPage,"Spawn Sammy",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,38),false); sy=sy+45
local markSpotButton=button(BotSammyPage,"Mark this spot",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,34),true); sy=sy+38
local spotStatus=label(BotSammyPage,"No spot marked. Uses the map center.",UDim2.fromOffset(5,sy),UDim2.new(1,-16,0,32),9); spotStatus.TextColor3=C.muted; spotStatus.TextWrapped=true; sy=sy+37
local sammyEggButton=button(BotSammyPage,"Spawn 240 eggs / refill empty spots",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,38),false); sy=sy+45
local clearSammyEggs=button(BotSammyPage,"CLEAR SAMMY EGGS",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,35),true); clearSammyEggs:SetAttribute("RestingColor",Color3.fromRGB(120,30,68)); sy=sy+42
local autoRefillBtn=button(BotSammyPage,"AUTO REFILL: OFF - after 50 gone",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,34),true); sy=sy+41
local testBannerBtn=button(BotSammyPage,"Test banner",UDim2.fromOffset(0,sy),UDim2.new(.5,-8,0,33),true)
local advertiseBtn=button(BotSammyPage,"ADVERTISE: OFF",UDim2.new(.5,3,0,sy),UDim2.new(.5,-9,0,33),true); sy=sy+42
local sammyDirect=textbox(BotSammyPage,"This box always announces as Sammy",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,42),""); sy=sy+48
local sammyRemove=button(BotSammyPage,"Remove Sammy",UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,35),true); sy=sy+42
local tagNone=button(BotSammyPage,"No tag",UDim2.fromOffset(0,sy),UDim2.new(1/3,-6,0,34),false)
local tagAdmin=button(BotSammyPage,"Admin",UDim2.new(1/3,2,0,sy),UDim2.new(1/3,-6,0,34),true)
local tagCreator=button(BotSammyPage,"Creator",UDim2.new(2/3,4,0,sy),UDim2.new(1/3,-10,0,34),true); sy=sy+42
local sammyPanelStatus=label(BotSammyPage,"Ready to spawn Sammy.",UDim2.fromOffset(5,sy),UDim2.new(1,-16,0,33),9); sammyPanelStatus.TextColor3=C.muted; sy=sy+42
section(BotSammyPage,"ADVERTISEMENT MESSAGES - CLICK ONE TO SEND",sy); sy=sy+24
local msg1=button(BotSammyPage,SammyMessages[1],UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,48),true); msg1.TextWrapped=true; sy=sy+55
local msg2=button(BotSammyPage,SammyMessages[2],UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,48),true); msg2.TextWrapped=true; sy=sy+55
local msg3=button(BotSammyPage,SammyMessages[3],UDim2.fromOffset(0,sy),UDim2.new(1,-6,0,48),true); msg3.TextWrapped=true; sy=sy+55
local adHint=label(BotSammyPage,"Click a message to announce it as Sammy.",UDim2.fromOffset(5,sy),UDim2.new(1,-16,0,38),9); adHint.TextColor3=C.muted; adHint.TextWrapped=true; sy=sy+44
BotSammyPage.CanvasSize=UDim2.fromOffset(0,sy)

spawnSammyButton.MouseButton1Click:Connect(function() if callRemote("SpawnSammy") then sammyPanelStatus.Text="Server Sammy request sent."; sammyPanelStatus.TextColor3=C.green else local ok,msg=spawnSammy(); sammyPanelStatus.Text=msg; sammyPanelStatus.TextColor3=ok and C.green or C.red end end)
markSpotButton.MouseButton1Click:Connect(function() local ok,msg=markSammySpot(); spotStatus.Text=msg; spotStatus.TextColor3=ok and C.green or C.red end)
sammyEggButton.MouseButton1Click:Connect(function() local ok,msg=spawnSammyBatch(countBatch("SAMMY240")>0); sammyPanelStatus.Text=msg; sammyPanelStatus.TextColor3=ok and C.green or C.red end)
clearSammyEggs.MouseButton1Click:Connect(function() local n=clearSpawnedEggs("SAMMY240"); sammyPanelStatus.Text="Cleared "..n.." Sammy egg(s)."; sammyPanelStatus.TextColor3=C.green end)
autoRefillBtn.MouseButton1Click:Connect(function() SammyAutoRefill=not SammyAutoRefill; autoRefillBtn.Text=SammyAutoRefill and "AUTO REFILL: ON - after 50 gone" or "AUTO REFILL: OFF - after 50 gone"; autoRefillBtn:SetAttribute("RestingColor",SammyAutoRefill and C.purple or C.card2) end)
testBannerBtn.MouseButton1Click:Connect(function() sammyBanner(SammyMessages[1] or "Sammy test banner") end)
advertiseBtn.MouseButton1Click:Connect(function() SammyAdvertise=not SammyAdvertise; advertiseBtn.Text=SammyAdvertise and "ADVERTISE: ON" or "ADVERTISE: OFF"; advertiseBtn:SetAttribute("RestingColor",SammyAdvertise and C.purple or C.card2) end)
sammyDirect.FocusLost:Connect(function(enter) if enter and sammyDirect.Text~="" then sammyBanner(sammyDirect.Text); sammyDirect.Text="" end end)
sammyRemove.MouseButton1Click:Connect(function() despawnSammy(); sammyPanelStatus.Text="Sammy removed."; sammyPanelStatus.TextColor3=C.muted end)
local function setSammyMode(mode) SammyTagMode=mode; refreshSammyTag(); tagNone:SetAttribute("RestingColor",(mode=="NONE") and C.purple or C.card2); tagAdmin:SetAttribute("RestingColor",(mode=="ADMIN") and C.purple or C.card2); tagCreator:SetAttribute("RestingColor",(mode=="CREATOR") and C.purple or C.card2) end
tagNone.MouseButton1Click:Connect(function() setSammyMode("NONE") end); tagAdmin.MouseButton1Click:Connect(function() setSammyMode("ADMIN") end); tagCreator.MouseButton1Click:Connect(function() setSammyMode("CREATOR") end)
local function sendSammyAd(index)
    local msg=SammyMessages[index]
    if not msg or msg=="" then return end
    sammyBanner(msg)
    adHint.Text="Sammy announced message "..tostring(index).."."
    adHint.TextColor3=C.green
end
msg1.MouseButton1Click:Connect(function() sendSammyAd(1) end)
msg2.MouseButton1Click:Connect(function() sendSammyAd(2) end)
msg3.MouseButton1Click:Connect(function() sendSammyAd(3) end)
showBotPage("Collectors")
refreshSafeUI()


end
Builders.Collectors()
Builders.Collectors=nil

function Builders.Console()
-- Console.
local out=Instance.new("ScrollingFrame"); out.Position=UDim2.fromOffset(11,72); out.Size=UDim2.new(1,-22,1,-152); out.BackgroundColor3=Color3.fromRGB(4,5,11); out.BorderSizePixel=0; out.CanvasSize=UDim2.new(); out.ScrollBarThickness=4; out.ScrollBarImageColor3=C.purple; out.Parent=Console; corner(out,8); local OL=Instance.new("UIListLayout"); OL.Padding=UDim.new(0,2); OL.Parent=out
local function line(t,col) local x=label(out,t,UDim2.new(),UDim2.new(1,-8,0,19),14); x.Font=Enum.Font.Code; x.TextColor3=col or C.green; task.defer(function() out.CanvasSize=UDim2.new(0,0,0,OL.AbsoluteContentSize.Y+8); out.CanvasPosition=Vector2.new(0,OL.AbsoluteContentSize.Y) end) end
local ci=textbox(Console,"enter a command",UDim2.new(0,11,1,-71),UDim2.new(1,-22,0,34),""); ci.Font=Enum.Font.Code; ci.TextXAlignment=Enum.TextXAlignment.Left
local quick=Instance.new("ScrollingFrame"); quick.Position=UDim2.new(0,11,1,-32); quick.Size=UDim2.new(1,-22,0,25); quick.BackgroundTransparency=1; quick.BorderSizePixel=0; quick.ScrollingDirection=Enum.ScrollingDirection.X; quick.CanvasSize=UDim2.fromOffset(950,0); quick.ScrollBarThickness=2; quick.Parent=Console; local QL=Instance.new("UIListLayout"); QL.FillDirection=Enum.FillDirection.Horizontal; QL.Padding=UDim.new(0,5); QL.Parent=quick
local function q(t,w) local b=button(quick,t,UDim2.new(),UDim2.fromOffset(w,23),true); b.Font=Enum.Font.Code; b.TextSize=10; return b end
local qh=q("/help",53); local qa=q("/announcement",105); local qg=q("/globalAnnouncement",138); local qt=q("/teleport",74); local qi=q("/invite",62); local qad=q("/giveadmin",83); local qcow=q("/givecoowner",102); local qv=q("/givevps",76); local qp=q("/players",70)
local function findPlayer(s) s=string.lower(tostring(s)); for _,p in ipairs(Players:GetPlayers()) do if string.lower(p.Name)==s or string.lower(p.DisplayName)==s then return p end end; for _,p in ipairs(Players:GetPlayers()) do if string.sub(string.lower(p.Name),1,string.len(s))==s then return p end end end
local function command(raw)
    raw=tostring(raw or ""); if raw=="" then return end; line("> "..raw,C.muted); local cmd,rest=raw:match("^(%S+)%s*(.*)$"); cmd=string.lower(cmd or ""); rest=rest or ""
    if cmd=="/help" then line("/announcement <message>"); line("/globalAnnouncement <message>"); line("/teleport <player>"); line("/invite <player>"); line("/giveadmin <player>"); line("/givecoowner <player>"); line("/givevps <player> (or /giveps)"); line("/players"); return end
    if cmd=="/players" then local n={}; for _,p in ipairs(Players:GetPlayers()) do table.insert(n,p.Name) end; line("Players: "..table.concat(n,", ")); return end
    if cmd=="/announcement" or cmd=="/globalannouncement" then if rest=="" then line("Enter a message.",C.orange); return end; local global=cmd=="/globalannouncement"; callRemote(global and "GlobalAnnouncement" or "Announcement",rest); notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,global and ": sent a" or ": sent an",global and "GLOBAL ANNOUNCEMENT" or "ANNOUNCEMENT","- "..rest); line("Announcement shown."); return end
    if cmd=="/giveps" then cmd="/givevps" end; local acts={ ["/teleport"]={"Teleport","TELEPORT"}, ["/invite"]={"Invite","INVITE"}, ["/giveadmin"]={"GiveAdmin","ADMIN"}, ["/givecoowner"]={"GiveCoowner","CO-OWNER"}, ["/givevps"]={"GiveVPS","PRIVATE SERVER"} }; local a=acts[cmd]; if a then if rest=="" then line("Enter a player.",C.orange); return end; local pl=findPlayer(rest); local target=pl and pl.DisplayName or rest; callRemote(a[1],rest); notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,": sent an",a[2],"to "..target); line(a[2].." -> "..target); return end; line("Unknown command. Use /help.",C.red)
end
ci.FocusLost:Connect(function(enter) if enter then local t=ci.Text; ci.Text=""; command(t) end end); local function pre(t) ci.Text=t; ci:CaptureFocus() end; qh.MouseButton1Click:Connect(function() command("/help") end); qa.MouseButton1Click:Connect(function() pre("/announcement ") end); qg.MouseButton1Click:Connect(function() pre("/globalAnnouncement ") end); qt.MouseButton1Click:Connect(function() pre("/teleport ") end); qi.MouseButton1Click:Connect(function() pre("/invite ") end); qad.MouseButton1Click:Connect(function() pre("/giveadmin ") end); qcow.MouseButton1Click:Connect(function() pre("/givecoowner ") end); qv.MouseButton1Click:Connect(function() pre("/givevps ") end); qp.MouseButton1Click:Connect(function() command("/players") end); line(P.Name.." has joined the server."); line("TAB = open / close console.",C.blue); line("Quick commands restored.",C.blue)

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
return true
