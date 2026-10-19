from pathlib import Path
import re

path=Path('Main.lua')
s=path.read_text(encoding='utf-8')

# ----- Star rendering: prefer an uncut BillboardGui attached to the hand anchor -----
star_start=s.index("local EXACT_STAR_SOURCE=[============[")
star_end=s.index("]============]",star_start)
star=s[star_start:star_end]

surface_pattern=re.compile(r"local gui\n    if CUSTOM_ASSET then\n        gui=Instance\.new\('SurfaceGui'\).*?        image\.Parent=gui\n    end",re.S)
new_surface="""local gui
    local guiImage
    if CUSTOM_ASSET then
        gui=Instance.new('BillboardGui')
        gui.Name='ExactStarReference'
        gui.AlwaysOnTop=true
        gui.LightInfluence=0
        gui.Size=UDim2.fromOffset(224,190)
        gui.StudsOffsetWorldSpace=Vector3.zero
        gui.Enabled=false
        gui.Adornee=root
        gui.Parent=root

        local image=Instance.new('ImageLabel')
        image.Name='ReferenceImage'
        image.BackgroundTransparency=1
        image.AnchorPoint=Vector2.new(.5,.5)
        image.Position=UDim2.fromScale(.5,.5)
        image.Size=UDim2.fromScale(1,1)
        image.Image=CUSTOM_ASSET
        image.ScaleType=Enum.ScaleType.Fit
        image.ResampleMode=Enum.ResamplerMode.Default
        image.ClipsDescendants=false
        image.Parent=gui
        guiImage=image
    end"""
star,n=surface_pattern.subn(new_surface,star,count=1)
if n!=1:
    raise SystemExit(f'Billboard replacement count was {n}')

star=star.replace("return m,gui\nend", "return m,gui,guiImage\nend",1)
star=star.replace("local model,surface=makeStarModel()", "local model,surface,guiImage=makeStarModel()",1)
star=star.replace("local state={model=model,surface=surface,drawing=drawing,conn=nil}", "local state={model=model,surface=surface,image=guiImage,drawing=drawing,conn=nil}",1)
star=star.replace("if state.surface then state.surface.Enabled=on and not state.drawing end\n            if state.drawing then state.drawing.Visible=on end", "if state.surface then state.surface.Enabled=on end\n            if state.drawing then state.drawing.Visible=on and not state.surface end",1)

old_pos="""local pos=hand.Position
                +hrp.CFrame.UpVector*1.35
                +hrp.CFrame.RightVector*.02
                +hrp.CFrame.LookVector*.10

            local cf=CFrame.lookAt(pos,cam.CFrame.Position,Vector3.yAxis)
                *CFrame.Angles(0,0,math.rad(-2))
            model:PivotTo(cf)"""
new_pos="""local now=os.clock()
            local bob=math.sin(now*2.1)*.055
            local pos=hand.Position
                +hrp.CFrame.UpVector*(.76+bob)
                -hrp.CFrame.RightVector*.18
                +hrp.CFrame.LookVector*.16

            local cf=CFrame.lookAt(pos,cam.CFrame.Position,Vector3.yAxis)
            model:PivotTo(cf)

            if state.image and state.surface then
                local pulse=1+math.sin(now*2.1)*.015
                state.image.Rotation=-4+math.sin(now*1.8)*1.2
                state.surface.Size=UDim2.fromOffset(math.floor(224*pulse),math.floor(190*pulse))
            end"""
if old_pos not in star:
    raise SystemExit('Star hand-position block not found')
star=star.replace(old_pos,new_pos,1)
star=star.replace("if state.drawing then\n                local v,onScreen=cam:WorldToViewportPoint(pos)", "if state.drawing and not state.surface then\n                local v,onScreen=cam:WorldToViewportPoint(pos)",1)
star=star.replace("local width=math.clamp(cam.ViewportSize.Y*.245,215,310)", "local width=math.clamp(cam.ViewportSize.Y*.205,180,245)",1)

s=s[:star_start]+star+s[star_end:]

# ----- Slightly smaller items panel -----
s=s.replace("win.Size=UDim2.fromOffset(440,380)win.Position=UDim2.new(.5,-220,.5,-190)",
            "win.Size=UDim2.fromOffset(410,350)win.Position=UDim2.new(.5,-205,.5,-175)",1)
s=s.replace("grid.CellSize=UDim2.new(.5,-9,0,42)","grid.CellSize=UDim2.new(.5,-9,0,38)",1)

# ----- Bottom-center inventory announcement instead of Roblox's right-side toast -----
spawn_marker="local function spawnTool(cat,name)"
if spawn_marker not in s:
    raise SystemExit('spawnTool marker not found')

toast="""local spawnToastSerial=0
local function showInventoryToast(name)
    spawnToastSerial+=1
    local serial=spawnToastSerial
    local old=PG:FindFirstChild('SAE_ITEM_SPAWN_TOAST')
    if old then old:Destroy() end

    local sg=Instance.new('ScreenGui')
    sg.Name='SAE_ITEM_SPAWN_TOAST'
    sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true
    sg.DisplayOrder=950
    sg.Parent=PG

    local frame=Instance.new('Frame')
    frame.AnchorPoint=Vector2.new(.5,1)
    frame.Position=UDim2.new(.5,0,1,-32)
    frame.Size=UDim2.fromOffset(350,44)
    frame.BackgroundColor3=Color3.fromRGB(16,13,24)
    frame.BackgroundTransparency=.08
    frame.BorderSizePixel=0
    frame.Parent=sg
    local c=Instance.new('UICorner') c.CornerRadius=UDim.new(0,10) c.Parent=frame
    local st=Instance.new('UIStroke') st.Color=Color3.fromRGB(151,72,235) st.Transparency=.2 st.Thickness=1 st.Parent=frame

    local text=Instance.new('TextLabel')
    text.BackgroundTransparency=1
    text.Size=UDim2.new(1,-20,1,0)
    text.Position=UDim2.fromOffset(10,0)
    text.Text=name..' has been added to your inventory.'
    text.TextColor3=Color3.fromRGB(255,255,255)
    text.Font=Enum.Font.GothamBold
    text.TextSize=13
    text.TextWrapped=true
    text.Parent=frame

    task.delay(2.35,function()
        if serial~=spawnToastSerial or not sg.Parent then return end
        local TS=game:GetService('TweenService')
        TS:Create(frame,TweenInfo.new(.22),{BackgroundTransparency=1}):Play()
        TS:Create(text,TweenInfo.new(.22),{TextTransparency=1}):Play()
        st.Transparency=1
        task.wait(.24)
        if sg.Parent then sg:Destroy() end
    end)
end

"""
s=s.replace(spawn_marker,toast+spawn_marker,1)
old_native="pcall(function() game:GetService('StarterGui'):SetCore('SendNotification',{Title='ITEM SPAWNED',Text=name..' has been added to your inventory.',Duration=3}) end)"
if old_native not in s:
    raise SystemExit('Native spawn notification not found')
s=s.replace(old_native,"showInventoryToast(name)",1)

path.write_text(s,encoding='utf-8')
print('Patched Main.lua: Star hand render/animation, smaller items panel, bottom-center spawn toast.')
