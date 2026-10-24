from pathlib import Path

p=Path('Main.lua')
s=p.read_text(encoding='utf-8')

# 1) Items panel: exactly 15% larger than current .575 scale.
assert s.count("winScale.Scale=.575")==1, s.count("winScale.Scale=.575")
s=s.replace("winScale.Scale=.575","winScale.Scale=.66125",1)

# 2) Hotbar icons: locate the game's own item artwork, including Index/inventory cards.
a=s.index('local function itemImage(cat,name)')
b=s.index('\nlocal spawnToastSerial=0',a)
new_item="""local function itemImage(cat,name)
    local key=cat..'|'..name
    local cached=iconCache[key]
    if cached then return cached end
    local want={}for _,alias in ipairs(Aliases[name]or{name})do want[norm(alias)]=true end
    local bestImage,bestScore=nil,-1

    local function containerScore(node)
        local score=hit(node,want)
        for _,child in ipairs(node:GetChildren())do
            if child:IsA('TextLabel')or child:IsA('TextButton')then
                local txt=norm(child.Text)
                if want[txt]then
                    score=math.max(score,950)
                else
                    for alias in pairs(want)do
                        if #alias>=5 and txt:find(alias,1,true)then score=math.max(score,560)end
                    end
                end
            end
        end
        return score
    end

    local function consider(obj,value)
        local image=imageContent(value)
        if not image then return end
        local node=obj
        for depth=0,6 do
            if not node then break end
            local score=containerScore(node)-depth*18
            if score>0 and score>bestScore then bestImage,bestScore=image,score end
            node=node.Parent
        end
    end

    for _,root in ipairs({RS,workspace,PG,game:GetService('StarterGui'),game:GetService('StarterPack'),game:GetService('Lighting')})do
        local list=root:GetDescendants()
        for i,obj in ipairs(list)do
            if obj:IsA('Tool')and not obj:GetAttribute('SAE_V7_TOOL')and not(P.Character and obj:IsDescendantOf(P.Character))and not obj:IsDescendantOf(Placed)then
                consider(obj,obj.TextureId)
            else
                local okImage,imageValue=pcall(function()return obj.Image end)
                if okImage then
                    consider(obj,imageValue)
                elseif obj:IsA('Decal')or obj:IsA('Texture')then
                    consider(obj,obj.Texture)
                end
            end
            if i%3000==0 then task.wait()end
        end
    end
    if not bestImage then bestImage=readItemImage(source(cat,name))end
    if bestImage then iconCache[key]=bestImage end
    return bestImage
end"""
s=s[:a]+new_item+s[b:]

# 3) Star: if replacement happens while already equipped, force a real equip transition
# so Equipped fires and the held reference renderer starts.
star_a=s.index('local EXACT_STAR_SOURCE=')
star_b=s.index('\nlocal FINAL_POLISH_SOURCE=',star_a)
star=s[star_a:star_b]
old="""        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
"""
assert star.count(old)==1, star.count(old)
new="""        tool:Destroy()
        if parent==P.Character then
            new.Parent=BP
            local hum=P.Character and P.Character:FindFirstChildOfClass('Humanoid')
            if hum then pcall(function()hum:EquipTool(new)end) else new.Parent=parent end
            if not usingNative then
                task.defer(function()
                    task.wait()
                    if new.Parent==P.Character and not live[new] then
                        if not startOverlay(new) then warn('[SAE] Star reference could not be rendered.') end
                    end
                end)
            end
        else
            new.Parent=parent
        end
        busy[tool]=nil
"""
star=star.replace(old,new,1)
s=s[:star_a]+star+s[star_b:]

p.write_text(s,encoding='utf-8')

# Structural assertions before the workflow tests.
assert 'winScale.Scale=.66125' in s
assert 'winScale.Scale=.575' not in s
assert 'local function containerScore(node)' in s
assert "local okImage,imageValue=pcall(function()return obj.Image end)" in s
assert 'if bestImage then iconCache[key]=bestImage end' in s
assert 'hum:EquipTool(new)' in s
assert 'new.Parent==P.Character and not live[new]' in s
star=s[s.index('local EXACT_STAR_SOURCE='):s.index('\nlocal FINAL_POLISH_SOURCE=')]
assert 'local NATIVE_TEMPLATE=nil' in star
print('PATCH_OK')
