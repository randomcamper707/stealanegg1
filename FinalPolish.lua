-- Final polish layer for Steal An Egg.
-- Does not replace or redraw pet visuals.
-- Adds gentle placed-pet idle motion (maximum 4 studs) and enlarges V7 inventory eggs.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local PETS={
    ['Unicorn']=true,['Kitsune']=true,['Night Flame']=true,['Archangel']=true,
    ['World Burner']=true,['Aetheron']=true,['Cthulhu']=true,['Luminous Cthulhu']=true,
    ['Sabertooth']=true,['Skeletal Sabertooth']=true,['Octophant']=true,['Mecha Scrambler']=true
}

local function allParts(o)
    local t={}
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA('BasePart') then t[#t+1]=d end
    end
    return t
end

-- Inventory egg size pass. Keep the existing artwork and simply make it easier to see/hold.
local eggBusy={}
local function enlargeEggTool(tool)
    if not tool or not tool:IsA('Tool') or eggBusy[tool] then return end
    if tool:GetAttribute('SAE_FINAL_EGG_LARGE') then return end
    if not tool:GetAttribute('SAE_V7_TOOL') then return end
    if not tostring(tool.Name):lower():find('egg',1,true) then return end

    local model=tool:FindFirstChildWhichIsA('Model')
    local handle=tool:FindFirstChild('Handle')
    if not model or not handle or not handle:IsA('BasePart') then return end

    eggBusy[tool]=true
    task.defer(function()
        if not tool.Parent or not model.Parent or not handle.Parent then eggBusy[tool]=nil return end

        local rel=handle.CFrame:ToObjectSpace(model:GetPivot())

        -- Remove only handle-to-visual welds. Internal model welds are left untouched.
        for _,d in ipairs(handle:GetChildren()) do
            if d:IsA('WeldConstraint') then
                local p=d.Part1
                if p and p:IsDescendantOf(model) then d:Destroy() end
            end
        end

        local ok,scale=pcall(function() return model:GetScale() end)
        if ok and scale then
            pcall(function() model:ScaleTo(scale*1.35) end)
        end
        model:PivotTo(handle.CFrame*rel)

        -- Reattach the enlarged visual to the handle robustly.
        for _,p in ipairs(allParts(model)) do
            p.Anchored=false
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Massless=true
            local w=Instance.new('WeldConstraint')
            w.Part0=handle
            w.Part1=p
            w.Parent=handle
        end

        tool:SetAttribute('SAE_FINAL_EGG_LARGE',true)
        eggBusy[tool]=nil
    end)
end

local function watchTools(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') then
            task.wait()
            enlargeEggTool(child)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') then enlargeEggTool(child) end
    end
end

watchTools(BP)
watchTools(P.Character)
P.CharacterAdded:Connect(function(char)
    task.wait(.2)
    watchTools(char)
end)

-- Placed-pet idle motion. The model itself is not rebuilt or recoloured.
local petStates={}
local MAX_RADIUS=4
local MOVE_SPEED=.78

local function randomTarget()
    local a=math.random()*math.pi*2
    local r=math.sqrt(math.random())*MAX_RADIUS
    return Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
end

local function registerPet(model)
    if not model or not model:IsA('Model') or not PETS[model.Name] then return end
    if petStates[model] or model:GetAttribute('SAE_FINAL_PET_MOTION') then return end
    if not model:FindFirstChildWhichIsA('BasePart',true) then return end

    local ok,baseScale=pcall(function() return model:GetScale() end)
    if not ok or not baseScale then baseScale=1 end

    model:SetAttribute('SAE_FINAL_PET_MOTION',true)
    petStates[model]={
        origin=model:GetPivot(),
        current=Vector3.zero,
        target=randomTarget(),
        nextTarget=os.clock()+math.random(220,420)/100,
        phase=math.random()*math.pi*2,
        baseScale=baseScale,
        nextScale=0
    }
end

local function watchPlaced(folder)
    if not folder or not folder:IsA('Folder') or folder.Name~='SAE_V7_PLACED' then return end
    for _,child in ipairs(folder:GetChildren()) do
        if child:IsA('Model') then registerPet(child) end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA('Model') then
            task.wait(.08)
            registerPet(child)
        end
    end)
end

local currentPlaced=workspace:FindFirstChild('SAE_V7_PLACED')
if currentPlaced then watchPlaced(currentPlaced) end
workspace.ChildAdded:Connect(function(child)
    if child.Name=='SAE_V7_PLACED' and child:IsA('Folder') then
        task.wait()
        watchPlaced(child)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    local now=os.clock()
    for model,s in pairs(petStates) do
        if not model.Parent then
            petStates[model]=nil
        else
            if now>=s.nextTarget or (s.target-s.current).Magnitude<.08 then
                s.target=randomTarget()
                s.nextTarget=now+math.random(260,480)/100
            end

            local delta=s.target-s.current
            local distance=delta.Magnitude
            if distance>.001 then
                local step=math.min(distance,MOVE_SPEED*dt)
                s.current=s.current+delta.Unit*step
            end

            -- A very small scale pulse plus vertical rise/fall gives a breathing idle.
            local breath=math.sin(now*2.1+s.phase)
            if now>=s.nextScale then
                s.nextScale=now+.12
                pcall(function()
                    model:ScaleTo(s.baseScale*(1+breath*.006))
                end)
            end

            local offset=s.current
            if offset.Magnitude>MAX_RADIUS then
                offset=offset.Unit*MAX_RADIUS
                s.current=offset
            end

            pcall(function()
                model:PivotTo(s.origin*CFrame.new(offset.X,breath*.07,offset.Z))
            end)
        end
    end
end)

-- Remove the old contradictory '25% smaller' subtitle once the inventory UI appears.
task.spawn(function()
    local pg=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
    if not pg then return end
    local gui=pg:WaitForChild('SAE_ITEMS_V7',15)
    if not gui then return end
    for _,d in ipairs(gui:GetDescendants()) do
        if d:IsA('TextLabel') and tostring(d.Text):find('25%% smaller') then
            d.Text='Larger eggs • exact pets • polished held items'
        end
    end
end)

print('[SAE] Final polish ready: larger inventory eggs + 4-stud pet idle movement.')