-- Final reference-model override for the developer inventory.
-- Builds true 3D Roblox geometry from the supplied visual references only.

local RS=game:GetService('ReplicatedStorage')
local old=RS:FindFirstChild('SAE_FinalReferenceModels')
if old then old:Destroy() end

local Folder=Instance.new('Folder')
Folder.Name='SAE_FinalReferenceModels'
Folder.Parent=RS

local function rgb(r,g,b)return Color3.fromRGB(r,g,b)end
local function base(m,name,size,color,cf,mat,shape)
    local p=Instance.new('Part')
    p.Name=name
    p.Size=size
    p.Color=color
    p.CFrame=cf or CFrame.new()
    p.Material=mat or Enum.Material.SmoothPlastic
    p.Shape=shape or Enum.PartType.Block
    p.Anchored=false
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.Massless=true
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=m
    return p
end
local function ball(m,n,s,c,cf,mat)return base(m,n,s,c,cf,mat,Enum.PartType.Ball)end
local function cyl(m,n,s,c,cf,mat)return base(m,n,s,c,cf,mat,Enum.PartType.Cylinder)end
local function wedge(m,n,s,c,cf,mat)
    local p=Instance.new('WedgePart')
    p.Name=n;p.Size=s;p.Color=c;p.CFrame=cf or CFrame.new();p.Material=mat or Enum.Material.SmoothPlastic
    p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.Parent=m
    return p
end
local function seg(m,n,a,b,w,c,mat)
    local d=b-a
    local p=base(m,n,Vector3.new(w,d.Magnitude,w),c,CFrame.new((a+b)/2,b)*CFrame.Angles(math.rad(90),0,0),mat)
    return p
end
local function finalize(m,root)
    root=root or m:FindFirstChildWhichIsA('BasePart',true)
    m.PrimaryPart=root
    m:SetAttribute('SAE_REFERENCE_FINAL',true)
    for _,p in ipairs(m:GetDescendants())do
        if p:IsA('BasePart') then
            p.Anchored=false;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
        end
    end
    return m
end

local function makeNightFlame()
    local m=Instance.new('Model');m.Name='Night Flame'
    local black=rgb(13,17,31)
    local navy=rgb(19,25,52)
    local armor=rgb(27,29,48)
    local purple=rgb(76,48,111)
    local purple2=rgb(102,62,141)
    local blue=rgb(24,86,215)
    local cyan=rgb(203,255,255)
    local red=rgb(115,25,50)
    local white=rgb(245,247,250)

    local root=ball(m,'Torso',Vector3.new(4.15,5.6,3.2),black,CFrame.new(0,.25,0),Enum.Material.Slate)
    ball(m,'ChestMass',Vector3.new(4.7,4.0,3.25),navy,CFrame.new(0,1.35,0),Enum.Material.Slate)
    ball(m,'Waist',Vector3.new(2.8,2.7,2.45),black,CFrame.new(0,-2.25,.05),Enum.Material.Slate)

    -- Wolf/dragon head, blue horns, purple mane, glowing eyes and open toothed mouth.
    ball(m,'Head',Vector3.new(2.8,2.45,2.6),black,CFrame.new(0,4.25,-.28),Enum.Material.Slate)
    ball(m,'Muzzle',Vector3.new(1.8,1.15,1.45),armor,CFrame.new(0,3.9,-1.45),Enum.Material.Slate)
    base(m,'UpperJaw',Vector3.new(1.55,.38,.85),black,CFrame.new(0,3.72,-1.9),Enum.Material.SmoothPlastic)
    base(m,'Mouth',Vector3.new(1.55,.62,.58),red,CFrame.new(0,3.38,-1.95),Enum.Material.SmoothPlastic)
    wedge(m,'LowerJaw',Vector3.new(1.7,.48,1.05),black,CFrame.new(0,3.05,-1.5),Enum.Material.Slate)
    for i=-2,2 do
        local x=i*.31
        wedge(m,'UpperTooth',Vector3.new(.22,.47,.24),white,CFrame.new(x,3.61,-2.18)*CFrame.Angles(math.rad(180),0,0),Enum.Material.SmoothPlastic)
        wedge(m,'LowerTooth',Vector3.new(.22,.43,.24),white,CFrame.new(x,3.19,-2.18),Enum.Material.SmoothPlastic)
    end
    ball(m,'EyeL',Vector3.new(.54,.32,.18),cyan,CFrame.new(-.57,4.35,-1.55),Enum.Material.Neon)
    ball(m,'EyeR',Vector3.new(.54,.32,.18),cyan,CFrame.new(.57,4.35,-1.55),Enum.Material.Neon)
    for _,sx in ipairs({-1,1})do
        wedge(m,'BlueHorn',Vector3.new(.75,2.15,.82),blue,CFrame.new(sx*.82,5.53,-.16)*CFrame.Angles(0,0,math.rad(-sx*22)),Enum.Material.Slate)
        for j=1,3 do
            wedge(m,'ManeSpike',Vector3.new(.72,1.55,.72),j==2 and purple2 or purple,CFrame.new(sx*(1.2+j*.33),4.25-(j-1)*.36,.35)*CFrame.Angles(0,0,math.rad(-sx*(28+8*j))),Enum.Material.Slate)
        end
    end
    for j=1,5 do
        wedge(m,'BackMane',Vector3.new(.78,1.5,.9),j%2==0 and purple2 or purple,CFrame.new(0,4.8-j*.55,1.35)*CFrame.Angles(math.rad(-22),0,math.rad((j%2==0 and 1 or -1)*8)),Enum.Material.Slate)
    end

    -- Four arms. Upper pair raised/outstretched, lower pair wide and lower, with purple inner plates and blue claws.
    local armDefs={{y=1.65,dy=.55,reach=5.25},{y=-.15,dy=-.28,reach=4.65}}
    for _,ad in ipairs(armDefs)do
        for _,sx in ipairs({-1,1})do
            local shoulder=Vector3.new(sx*2.0,ad.y,.05)
            local elbow=Vector3.new(sx*3.55,ad.y+ad.dy,-.05)
            local wrist=Vector3.new(sx*ad.reach,ad.y+ad.dy*.7,-.18)
            ball(m,'Shoulder',Vector3.new(1.55,1.5,1.35),black,CFrame.new(shoulder),Enum.Material.Slate)
            seg(m,'UpperArm',shoulder,elbow,1.18,black,Enum.Material.Slate)
            seg(m,'Forearm',elbow,wrist,1.12,black,Enum.Material.Slate)
            seg(m,'PurpleInset',elbow+Vector3.new(0,0,-.59),wrist+Vector3.new(0,0,-.59),.42,purple2,Enum.Material.Slate)
            ball(m,'Hand',Vector3.new(1.35,1.08,1.0),black,CFrame.new(wrist),Enum.Material.Slate)
            for f=1,4 do
                local fy=(f-2.5)*.28
                local tip=wrist+Vector3.new(sx*(.72+.18*math.abs(f-2.5)),fy,-.18)
                wedge(m,'BlueClaw',Vector3.new(.28,.78,.32),blue,CFrame.new(tip)*CFrame.Angles(0,0,math.rad(sx*100)),Enum.Material.Neon)
            end
        end
    end

    -- Heavy legs and blue toe claws/blue shin markings.
    for _,sx in ipairs({-1,1})do
        ball(m,'Thigh',Vector3.new(1.9,3.15,1.9),navy,CFrame.new(sx*1.14,-3.4,.12),Enum.Material.Slate)
        base(m,'Shin',Vector3.new(1.42,2.55,1.55),black,CFrame.new(sx*1.3,-5.45,-.05)*CFrame.Angles(0,0,math.rad(sx*6)),Enum.Material.Slate)
        ball(m,'Foot',Vector3.new(1.8,.95,2.05),black,CFrame.new(sx*1.35,-6.83,-.48),Enum.Material.Slate)
        for toe=1,3 do
            wedge(m,'ToeClaw',Vector3.new(.34,.72,.58),blue,CFrame.new(sx*1.35+(toe-2)*.48,-6.98,-1.45),Enum.Material.Neon)
        end
        ball(m,'BlueMark',Vector3.new(.48,.68,.24),blue,CFrame.new(sx*1.31,-4.55,-.85),Enum.Material.Neon)
        ball(m,'BlueMark',Vector3.new(.36,.45,.22),blue,CFrame.new(sx*1.48,-5.05,-.88),Enum.Material.Neon)
    end

    -- White/cyan branching chest emblem from the reference.
    ball(m,'RuneCore',Vector3.new(.78,.78,.22),cyan,CFrame.new(0,.52,-1.72),Enum.Material.Neon)
    seg(m,'RuneStem',Vector3.new(0,2.25,-1.72),Vector3.new(0,-1.75,-1.72),.18,cyan,Enum.Material.Neon)
    local rays={
        {Vector3.new(0,.75,-1.72),Vector3.new(-1.35,1.65,-1.72)},
        {Vector3.new(0,.75,-1.72),Vector3.new(1.35,1.65,-1.72)},
        {Vector3.new(0,.35,-1.72),Vector3.new(-1.55,.72,-1.72)},
        {Vector3.new(0,.35,-1.72),Vector3.new(1.55,.72,-1.72)},
        {Vector3.new(0,.05,-1.72),Vector3.new(-1.25,-.65,-1.72)},
        {Vector3.new(0,.05,-1.72),Vector3.new(1.25,-.65,-1.72)},
        {Vector3.new(0,-.45,-1.72),Vector3.new(-.78,-1.55,-1.72)},
        {Vector3.new(0,-.45,-1.72),Vector3.new(.78,-1.55,-1.72)},
    }
    for _,r in ipairs(rays)do seg(m,'RuneBranch',r[1],r[2],.14,cyan,Enum.Material.Neon)end
    return finalize(m,root)
end

local function makeLuminousCthulhu()
    local m=Instance.new('Model');m.Name='Luminous Cthulhu'
    local deep=rgb(18,31,86)
    local navy=rgb(24,46,118)
    local blue=rgb(37,76,170)
    local violet=rgb(70,58,151)
    local membrane=rgb(178,220,255)
    local ice=rgb(228,250,255)
    local cyan=rgb(188,245,255)
    local root=ball(m,'Torso',Vector3.new(4.8,5.6,3.35),navy,CFrame.new(0,.25,0),Enum.Material.Slate)
    ball(m,'Chest',Vector3.new(5.3,4.3,3.5),navy,CFrame.new(0,1.2,0),Enum.Material.Slate)
    ball(m,'Abdomen',Vector3.new(3.1,3.1,2.6),deep,CFrame.new(0,-2.1,.05),Enum.Material.Slate)

    -- Cthulhu head: horns, white eyes and multiple curling face tentacles.
    ball(m,'Head',Vector3.new(3.15,2.85,2.8),deep,CFrame.new(0,4.25,-.15),Enum.Material.Slate)
    ball(m,'EyeL',Vector3.new(.72,.42,.2),ice,CFrame.new(-.65,4.4,-1.52),Enum.Material.Neon)
    ball(m,'EyeR',Vector3.new(.72,.42,.2),ice,CFrame.new(.65,4.4,-1.52),Enum.Material.Neon)
    for _,sx in ipairs({-1,1})do
        wedge(m,'TempleHorn',Vector3.new(.82,2.1,.8),blue,CFrame.new(sx*1.18,5.55,-.05)*CFrame.Angles(0,0,math.rad(-sx*35)),Enum.Material.Slate)
        wedge(m,'SideHorn',Vector3.new(.68,1.65,.72),violet,CFrame.new(sx*1.55,4.55,.12)*CFrame.Angles(0,0,math.rad(-sx*62)),Enum.Material.Slate)
    end
    local tentacles={
        {-.78,3.92,-1.4,-1.35,2.35,-1.65},
        {-.38,3.9,-1.5,-.62,2.0,-1.9},
        {0,3.85,-1.52,0,1.65,-2.0},
        {.38,3.9,-1.5,.62,2.0,-1.9},
        {.78,3.92,-1.4,1.35,2.35,-1.65}
    }
    for _,t in ipairs(tentacles)do
        local a=Vector3.new(t[1],t[2],t[3]);local b=Vector3.new((t[1]+t[4])*.5,(t[2]+t[5])*.5,t[6]);local c=Vector3.new(t[4],t[5],t[6])
        seg(m,'FaceTentacle',a,b,.48,violet,Enum.Material.Slate)
        seg(m,'FaceTentacle',b,c,.42,violet,Enum.Material.Slate)
        ball(m,'TentacleTip',Vector3.new(.46,.46,.46),violet,CFrame.new(c),Enum.Material.Slate)
    end

    -- Large bat/dragon wings with bright translucent-looking pale membranes.
    for _,sx in ipairs({-1,1})do
        local shoulder=Vector3.new(sx*2.0,2.6,.45)
        local elbow=Vector3.new(sx*4.25,4.55,.9)
        local tip=Vector3.new(sx*6.8,5.15,1.15)
        local lower=Vector3.new(sx*5.0,1.6,1.0)
        seg(m,'WingBone',shoulder,elbow,.48,deep,Enum.Material.Slate)
        seg(m,'WingBone',elbow,tip,.45,blue,Enum.Material.Slate)
        seg(m,'WingBone',tip,lower,.38,deep,Enum.Material.Slate)
        wedge(m,'WingMembrane',Vector3.new(3.8,4.5,.32),membrane,CFrame.new(sx*4.45,3.75,1.04)*CFrame.Angles(0,sx==1 and math.rad(180) or 0,math.rad(-sx*22)),Enum.Material.Glass)
        wedge(m,'WingMembrane',Vector3.new(3.2,3.8,.3),membrane,CFrame.new(sx*5.35,3.05,1.05)*CFrame.Angles(0,sx==1 and math.rad(180) or 0,math.rad(-sx*38)),Enum.Material.Glass)
    end

    -- Thick arms, icy growths and huge glowing claw tips.
    for _,sx in ipairs({-1,1})do
        ball(m,'Shoulder',Vector3.new(1.9,1.9,1.65),navy,CFrame.new(sx*2.25,1.45,-.05),Enum.Material.Slate)
        seg(m,'UpperArm',Vector3.new(sx*2.25,1.2,0),Vector3.new(sx*3.0,-.2,-.15),1.38,navy,Enum.Material.Slate)
        seg(m,'Forearm',Vector3.new(sx*3.0,-.2,-.15),Vector3.new(sx*3.35,-2.0,-.28),1.45,blue,Enum.Material.Slate)
        ball(m,'Hand',Vector3.new(1.55,1.35,1.25),navy,CFrame.new(sx*3.45,-2.65,-.38),Enum.Material.Slate)
        for claw=1,3 do
            wedge(m,'GlowClaw',Vector3.new(.5,1.5,.55),ice,CFrame.new(sx*(3.45+(claw-2)*.48),-3.55,-.68),Enum.Material.Neon)
        end
        for j=1,5 do
            wedge(m,'IceGrowth',Vector3.new(.36,.9+j*.05,.36),ice,CFrame.new(sx*(2.0+.22*j),1.25-j*.45,-.92)*CFrame.Angles(0,0,math.rad(sx*(j%2==0 and 18 or -12))),Enum.Material.Ice)
        end
    end

    -- Powerful legs and bright talons.
    for _,sx in ipairs({-1,1})do
        ball(m,'Thigh',Vector3.new(2.0,3.25,2.0),navy,CFrame.new(sx*1.2,-3.5,.1),Enum.Material.Slate)
        base(m,'Shin',Vector3.new(1.45,2.55,1.55),blue,CFrame.new(sx*1.35,-5.55,-.05)*CFrame.Angles(0,0,math.rad(sx*7)),Enum.Material.Slate)
        ball(m,'Foot',Vector3.new(1.8,.95,2.05),deep,CFrame.new(sx*1.4,-6.92,-.5),Enum.Material.Slate)
        for toe=1,3 do
            wedge(m,'FootGlowClaw',Vector3.new(.48,1.2,.6),ice,CFrame.new(sx*1.4+(toe-2)*.5,-7.35,-1.35),Enum.Material.Neon)
        end
        for j=1,4 do
            wedge(m,'LegIce',Vector3.new(.34,.8,.34),ice,CFrame.new(sx*(1.15+.12*j),-3.9-j*.62,-.9)*CFrame.Angles(0,0,math.rad(sx*(j%2==0 and 14 or -10))),Enum.Material.Ice)
        end
    end

    -- White lightning fissures across arms, torso and thighs.
    local lines={
        {Vector3.new(-1.2,1.5,-1.7),Vector3.new(-.55,.45,-1.72)},
        {Vector3.new(.65,1.65,-1.7),Vector3.new(1.25,.55,-1.72)},
        {Vector3.new(-1.05,-.25,-1.65),Vector3.new(-.55,-1.25,-1.66)},
        {Vector3.new(.7,-.4,-1.65),Vector3.new(1.15,-1.35,-1.66)},
        {Vector3.new(-1.15,-3.0,-1.0),Vector3.new(-1.0,-5.0,-1.05)},
        {Vector3.new(1.1,-3.1,-1.0),Vector3.new(1.25,-5.0,-1.05)},
    }
    for _,l in ipairs(lines)do
        local mid=(l[1]+l[2])/2
        seg(m,'Lightning',l[1],mid+Vector3.new(.25,0,0),.13,cyan,Enum.Material.Neon)
        seg(m,'Lightning',mid+Vector3.new(.25,0,0),l[2],.13,cyan,Enum.Material.Neon)
    end
    return finalize(m,root)
end

local function makeStar()
    local m=Instance.new('Model');m.Name='Star'
    local gold=rgb(214,177,79)
    local light=rgb(229,195,96)
    local shadow=rgb(182,142,55)
    local black=rgb(29,27,23)
    local white=rgb(248,248,244)
    local root=ball(m,'StarCenter',Vector3.new(4.1,4.0,1.15),gold,CFrame.new(),Enum.Material.SmoothPlastic)

    -- Five thick rounded-looking points, matching the chunky Roblox star silhouette.
    local points={
        {0,3.0,0},
        {2.9,.9,-72},
        {1.8,-2.55,-144},
        {-1.8,-2.55,144},
        {-2.9,.9,72}
    }
    for _,q in ipairs(points)do
        wedge(m,'StarPoint',Vector3.new(2.75,4.65,1.12),gold,CFrame.new(q[1],q[2],0)*CFrame.Angles(0,0,math.rad(q[3])),Enum.Material.SmoothPlastic)
        wedge(m,'PointEdge',Vector3.new(2.42,4.22,.24),shadow,CFrame.new(q[1],q[2],.69)*CFrame.Angles(0,0,math.rad(q[3])),Enum.Material.SmoothPlastic)
    end

    -- Raised rectangular studs across the face like the supplied reference.
    local studs={
        {-1.15,1.55},{0,1.72},{1.18,1.32},
        {-1.82,.62},{-.62,.58},{.58,.62},{1.8,.48},
        {-1.45,-.48},{-.32,-.42},{.82,-.46},{1.55,-.78},
        {-.9,-1.48},{.25,-1.52}
    }
    for _,s in ipairs(studs)do
        base(m,'RaisedStud',Vector3.new(.58,.48,.24),light,CFrame.new(s[1],s[2],-.69),Enum.Material.SmoothPlastic)
    end

    -- Exact face layout from the image: large oval eyes with tiny white highlights and small kawaii mouth.
    ball(m,'EyeL',Vector3.new(.7,.98,.2),black,CFrame.new(-.88,.05,-.76),Enum.Material.SmoothPlastic)
    ball(m,'EyeR',Vector3.new(.7,.98,.2),black,CFrame.new(.88,.05,-.76),Enum.Material.SmoothPlastic)
    ball(m,'EyeShineL',Vector3.new(.18,.2,.08),white,CFrame.new(-1.0,.28,-.88),Enum.Material.Neon)
    ball(m,'EyeShineR',Vector3.new(.18,.2,.08),white,CFrame.new(.76,.28,-.88),Enum.Material.Neon)
    seg(m,'MouthLeft',Vector3.new(-.5,-.62,-.84),Vector3.new(-.18,-.86,-.84),.13,black,Enum.Material.SmoothPlastic)
    seg(m,'MouthMiddle',Vector3.new(-.18,-.86,-.84),Vector3.new(.18,-.68,-.84),.13,black,Enum.Material.SmoothPlastic)
    seg(m,'MouthRight',Vector3.new(.18,-.68,-.84),Vector3.new(.52,-.88,-.84),.13,black,Enum.Material.SmoothPlastic)
    return finalize(m,root)
end

makeNightFlame().Parent=Folder
makeLuminousCthulhu().Parent=Folder
makeStar().Parent=Folder
