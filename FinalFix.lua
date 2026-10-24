-- Steal An Egg - requested hotbar/star/UI-only patch
-- Loads the current production Main.lua, then changes only:
-- 1) spawned item hotbar icons, 2) held Star visibility, 3) Items panel scale (+15%).

local env=(getgenv and getgenv()) or _G

-- Allow the user to rerun this final loader in the same session while testing.
env.SAE_SINGLE_MAIN_RUNNING=nil

local MAIN_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/refs/heads/main/Main.lua?v='..tostring(os.time())
local okMain,mainSource=pcall(function() return game:HttpGet(MAIN_URL) end)
if not okMain or type(mainSource)~='string' then
    warn('[SAE] Could not download Main.lua: '..tostring(mainSource))
    return
end
local mainFn,mainCompile=loadstring(mainSource)
if not mainFn then
    warn('[SAE] Main.lua compile error: '..tostring(mainCompile))
    return
end
local ranMain,mainErr=pcall(mainFn)
if not ranMain then
    warn('[SAE] Main.lua runtime error: '..tostring(mainErr))
    return
end

local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local StarterGui=game:GetService('StarterGui')
local StarterPack=game:GetService('StarterPack')
local Lighting=game:GetService('Lighting')

local player=Players.LocalPlayer
if not player then return end
local playerGui=player:FindFirstChildOfClass('PlayerGui') or player:WaitForChild('PlayerGui',10)
local backpack=player:FindFirstChildOfClass('Backpack') or player:WaitForChild('Backpack',10)
if not playerGui or not backpack then return end

local VALID={
    ['Unicorn Egg']=true,['Unicorn']=true,
    ['Kitsune Egg']=true,['Kitsune']=true,
    ['Night Flame Egg']=true,['Night Flame']=true,
    ['Archangel Egg']=true,['Archangel']=true,
    ['World Burner Egg']=true,['World Burner']=true,
    ['Aetheron Egg']=true,['Aetheron']=true,
    ['Cthulhu Egg']=true,['Cthulhu']=true,
    ['Luminous Cthulhu Egg']=true,['Luminous Cthulhu']=true,
    ['Sabertooth Egg']=true,['Sabertooth']=true,
    ['Skeletal Sabertooth Egg']=true,['Skeletal Sabertooth']=true,
    ['Octophant Egg']=true,['Octophant']=true,
    ['Mecha Scrambler Egg']=true,['Mecha Scrambler']=true,
    ['Star']=true,
}

local function norm(s)
    return string.lower(tostring(s or '')):gsub('[^%w]','')
end

local function usableImage(v)
    if type(v)~='string' or v=='' then return nil end
    if v:match('^rbxassetid://') or v:match('^rbxthumb://') or v:match('^rbxasset://') or v:match('^http') or v:match('^https') then
        return v
    end
    return nil
end

local iconCache={}

local function objectNames(obj)
    local out={norm(obj and obj.Name)}
    local p=obj and obj.Parent
    for _=1,3 do
        if not p then break end
        out[#out+1]=norm(p.Name)
        p=p.Parent
    end
    return out
end

local function containsExactName(obj,want)
    for _,n in ipairs(objectNames(obj)) do
        if n==want then return true end
    end
    return false
end

local function nearbyExactText(obj,want)
    local parent=obj and obj.Parent
    if not parent then return false end
    local checked=0
    for _,d in ipairs(parent:GetDescendants()) do
        if d:IsA('TextLabel') or d:IsA('TextButton') then
            checked=checked+1
            if norm(d.Text)==want then return true end
            if checked>=80 then break end
        end
    end
    return false
end

local function readImage(obj)
    if obj:IsA('ImageLabel') or obj:IsA('ImageButton') then
        return usableImage(obj.Image)
    elseif obj:IsA('Decal') or obj:IsA('Texture') then
        return usableImage(obj.Texture)
    elseif obj:IsA('Tool') then
        return usableImage(obj.TextureId)
    end
    return nil
end

local function exactIcon(name)
    if iconCache[name] then
        return iconCache[name]
    end

    local want=norm(name)
    local best,bestScore=nil,-1
    local roots={playerGui,StarterGui,ReplicatedStorage,StarterPack,Lighting,workspace}

    for rootIndex,root in ipairs(roots) do
        local ok,list=pcall(function() return root:GetDescendants() end)
        if ok and list then
            for i,obj in ipairs(list) do
                local image=readImage(obj)
                if image then
                    local score=-1
                    if obj:IsA('Tool') and norm(obj.Name)==want then
                        score=150
                    elseif containsExactName(obj,want) then
                        score=130
                    elseif nearbyExactText(obj,want) then
                        score=145
                    end

                    -- Prefer actual game UI images over world texture maps when scores tie.
                    if score>=0 then
                        if rootIndex<=2 then score=score+20 end
                        if obj:IsA('ImageLabel') or obj:IsA('ImageButton') then score=score+10 end
                        if score>bestScore then
                            best=image
                            bestScore=score
                        end
                    end
                end
                if i%3500==0 then task.wait() end
            end
        end
    end

    -- Last exact fallback: an exact-named replicated object may expose its icon as an attribute.
    if not best then
        for _,root in ipairs({ReplicatedStorage,StarterPack,workspace}) do
            local ok,list=pcall(function() return root:GetDescendants() end)
            if ok and list then
                for i,obj in ipairs(list) do
                    if norm(obj.Name)==want then
                        for _,attr in ipairs({'Icon','IconId','Image','ImageId','Thumbnail','ThumbnailId','TextureId'}) do
                            local okAttr,value=pcall(function() return obj:GetAttribute(attr) end)
                            local image=okAttr and usableImage(value) or nil
                            if image then best=image break end
                        end
                        if best then break end
                    end
                    if i%3500==0 then task.wait() end
                end
            end
            if best then break end
        end
    end

    if best then iconCache[name]=best end
    return best
end

local function findToolLabelContainer(root,name)
    local want=norm(name)
    local ok,list=pcall(function() return root:GetDescendants() end)
    if not ok or not list then return nil end
    for i,obj in ipairs(list) do
        if obj:IsA('TextLabel') or obj:IsA('TextButton') then
            if norm(obj.Text)==want then
                return obj.Parent
            end
        end
        if i%3000==0 then task.wait() end
    end
    return nil
end

local function patchVisibleHotbar(name,image)
    if not image then return end
    local holder=findToolLabelContainer(playerGui,name)
    if not holder then return end

    local p=holder
    local hotbarLike=false
    for _=1,5 do
        if not p then break end
        local n=norm(p.Name)
        if n:find('hotbar',1,true) or n:find('backpack',1,true) or n:find('toolbar',1,true) or n:find('slot',1,true) then
            hotbarLike=true
            break
        end
        p=p.Parent
    end
    if not hotbarLike then return end

    local fallback=nil
    for _,d in ipairs(holder:GetDescendants()) do
        if d:IsA('ImageLabel') or d:IsA('ImageButton') then
            local dn=norm(d.Name)
            if dn:find('icon',1,true) or dn:find('thumbnail',1,true) or dn=='itemimage' or dn=='image' then
                d.Image=image
                return
            end
            if not fallback and (d.Image=='' or d.Image=='rbxassetid://0') then fallback=d end
        end
    end
    if fallback then fallback.Image=image end
end

local function applyIcon(tool)
    if not tool or not tool:IsA('Tool') or not VALID[tool.Name] then return end
    local current=usableImage(tool.TextureId)
    local image=current or exactIcon(tool.Name)
    if image and tool.TextureId~=image then
        pcall(function() tool.TextureId=image end)
    end
    if image then
        task.defer(function()
            task.wait(.08)
            patchVisibleHotbar(tool.Name,image)
        end)
    end
end

local function visibleStarDescendant(tool)
    for _,d in ipairs(tool:GetDescendants()) do
        if d:IsA('BasePart') and d.Name~='Handle' and d.Transparency<0.98 then
            return true
        elseif d:IsA('BillboardGui') or d:IsA('SurfaceGui') then
            if d.Name~='SAE_STAR_VISIBILITY_PATCH' and d.Enabled then return true end
        end
    end
    return false
end

local function clearStarPatch(tool)
    if not tool then return end
    for _,d in ipairs(tool:GetDescendants()) do
        if d.Name=='SAE_STAR_VISIBILITY_PATCH' then
            pcall(function() d:Destroy() end)
        end
    end
end

local function showStar(tool)
    if not tool or not tool.Parent or tool.Name~='Star' then return end
    applyIcon(tool)
    if visibleStarDescendant(tool) then return end

    local handle=tool:FindFirstChild('Handle')
    if not handle or not handle:IsA('BasePart') then return end
    clearStarPatch(tool)

    local image=usableImage(tool.TextureId) or exactIcon('Star')
    if not image then
        warn('[SAE] Star is equipped but no exact replicated Star image was available.')
        return
    end

    local gui=Instance.new('BillboardGui')
    gui.Name='SAE_STAR_VISIBILITY_PATCH'
    gui.Adornee=handle
    gui.AlwaysOnTop=true
    gui.LightInfluence=0
    gui.Size=UDim2.fromOffset(235,235)
    gui.StudsOffsetWorldSpace=Vector3.new(1.45,.55,-.35)
    gui.Parent=handle

    local img=Instance.new('ImageLabel')
    img.Name='StarImage'
    img.BackgroundTransparency=1
    img.Size=UDim2.fromScale(1,1)
    img.ScaleType=Enum.ScaleType.Fit
    img.Image=image
    img.Parent=gui
end

local function bindTool(tool)
    if not tool or not tool:IsA('Tool') or not VALID[tool.Name] then return end
    applyIcon(tool)

    if tool.Name=='Star' and not tool:GetAttribute('SAE_STAR_VISIBILITY_BOUND') then
        tool:SetAttribute('SAE_STAR_VISIBILITY_BOUND',true)
        tool.Equipped:Connect(function()
            task.defer(function()
                task.wait()
                showStar(tool)
            end)
        end)
        tool.Unequipped:Connect(function()
            clearStarPatch(tool)
        end)

        -- Important: replacement Star tools can be inserted directly into Character while already equipped.
        -- In that case Roblox does not necessarily fire Equipped again, so render immediately.
        if player.Character and tool.Parent==player.Character then
            task.defer(function()
                task.wait()
                showStar(tool)
            end)
        end
    end
end

local function bindContainer(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') then
            task.defer(function()
                task.wait()
                bindTool(child)
            end)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') then bindTool(child) end
    end
end

local function resizeItemsPanel(gui)
    if not gui or gui.Name~='SAE_ITEMS_V7' then return end
    for _,d in ipairs(gui:GetDescendants()) do
        if d:IsA('UIScale') then
            -- Current production panel uses 0.575. Increase that panel only by exactly 15%.
            if math.abs(d.Scale-.575)<.02 then
                d.Scale=.66125
                return
            end
        end
    end
end

local existing=playerGui:FindFirstChild('SAE_ITEMS_V7')
if existing then resizeItemsPanel(existing) end
playerGui.ChildAdded:Connect(function(child)
    if child.Name=='SAE_ITEMS_V7' then
        task.defer(function()
            task.wait()
            resizeItemsPanel(child)
        end)
    end
end)

bindContainer(backpack)
bindContainer(player.Character)
player.CharacterAdded:Connect(function(char)
    task.wait(.15)
    bindContainer(char)
end)

-- Re-check a few times because the production script has replacement layers for pets/Star.
task.spawn(function()
    for _=1,16 do
        task.wait(.25)
        for _,holder in ipairs({backpack,player.Character}) do
            if holder then
                for _,tool in ipairs(holder:GetChildren()) do
                    if tool:IsA('Tool') and VALID[tool.Name] then bindTool(tool) end
                end
            end
        end
        local g=playerGui:FindFirstChild('SAE_ITEMS_V7')
        if g then resizeItemsPanel(g) end
    end
end)
