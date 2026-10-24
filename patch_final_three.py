from pathlib import Path

p=Path('Main.lua')
s=p.read_text()

# 1) Keep redesigned inventory notification two seconds longer.
old="task.delay(2.45,function()"
assert s.count(old)==1, ('toast delay matches', s.count(old))
s=s.replace(old,"task.delay(4.45,function()",1)

# 2) Visually halve Items panel using UIScale so its internal layout stays intact.
old="win.Size=UDim2.fromOffset(410,350)win.Position=UDim2.new(.5,-205,.5,-175)"
assert s.count(old)==1, ('panel geometry matches', s.count(old))
s=s.replace(old,"win.AnchorPoint=Vector2.new(.5,.5)win.Size=UDim2.fromOffset(410,350)win.Position=UDim2.fromScale(.5,.5)",1)
old="win.Parent=gui corner(win,13)stroke(win,.1)"
assert s.count(old)==1, ('panel parent matches', s.count(old))
s=s.replace(old,"win.Parent=gui corner(win,13)stroke(win,.1)local winScale=Instance.new('UIScale')winScale.Scale=.5 winScale.Parent=win",1)

# 3) Star visibility fallback: use its Roblox TextureId in an ImageLabel when custom asset APIs are unavailable.
old="""    local gui,img,drawing
    if CUSTOM_ASSET then
        gui=Instance.new('ScreenGui')"""
assert s.count(old)==1, ('star overlay entry matches', s.count(old))
new="""    local gui,img,drawing
    local imageSource=CUSTOM_ASSET
    if (not imageSource or imageSource=='') and tool.TextureId and tool.TextureId~='' then
        imageSource=tool.TextureId
    end
    if imageSource then
        gui=Instance.new('ScreenGui')"""
s=s.replace(old,new,1)

old="        img.Image=CUSTOM_ASSET"
assert s.count(old)==1, ('star image assignment matches', s.count(old))
s=s.replace(old,"        img.Image=imageSource",1)

old="""    if not NATIVE_TEMPLATE and not CUSTOM_ASSET and not DRAWING_SUPPORTED then
        warn('[SAE] Exact Star renderer unavailable; keeping existing Star tool instead of making it invisible.')
        return
    end"""
assert s.count(old)==1, ('star guard matches', s.count(old))
new="""    local hasToolImage=tool.TextureId and tool.TextureId~=''
    if not NATIVE_TEMPLATE and not CUSTOM_ASSET and not DRAWING_SUPPORTED and not hasToolImage then
        warn('[SAE] Star renderer unavailable; keeping existing Star tool instead of making it invisible.')
        return
    end"""
s=s.replace(old,new,1)

# Verify all requested modifications are present before writing.
assert "task.delay(4.45,function()" in s
assert "winScale.Scale=.5" in s
assert "win.Position=UDim2.fromScale(.5,.5)" in s
assert "local imageSource=CUSTOM_ASSET" in s
assert "img.Image=imageSource" in s
assert "local hasToolImage=tool.TextureId and tool.TextureId~=''" in s

p.write_text(s)
print('PATCH_OK')