-- STEAL AN EGG - SELF-CONTAINED MAIN
-- All approved Lua logic remains in Main.lua. PNG artwork is cached from this repository.
-- Night Flame and Luminous Cthulhu approved pet rigs are preserved unchanged.

local env=(getgenv and getgenv()) or _G
if env.SAE_SINGLE_MAIN_RUNNING then
    env.SAE_SINGLE_MAIN_RUNNING=nil
end
env.SAE_SINGLE_MAIN_RUNNING=true

local Players=game:GetService('Players')
local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer
local playerGui=player and (player:FindFirstChildOfClass('PlayerGui') or player:WaitForChild('PlayerGui',10))

local statusGui
local statusLabel
if playerGui then
    local old=playerGui:FindFirstChild('SAE_SINGLE_BOOT_STATUS')
    if old then old:Destroy() end
    statusGui=Instance.new('ScreenGui')
    statusGui.Name='SAE_SINGLE_BOOT_STATUS'
    statusGui.ResetOnSpawn=false
    statusGui.DisplayOrder=999999
    statusGui.IgnoreGuiInset=true
    statusGui.Parent=playerGui

    statusLabel=Instance.new('TextLabel')
    statusLabel.AnchorPoint=Vector2.new(.5,.5)
    statusLabel.Position=UDim2.fromScale(.5,.5)
    statusLabel.Size=UDim2.fromOffset(440,110)
    statusLabel.BackgroundColor3=Color3.fromRGB(18,20,27)
    statusLabel.TextColor3=Color3.fromRGB(245,247,255)
    statusLabel.Font=Enum.Font.GothamBold
    statusLabel.TextSize=17
    statusLabel.TextWrapped=true
    statusLabel.Text='STEAL AN EGG\nLoading single-file build...'
    statusLabel.Parent=statusGui
    local corner=Instance.new('UICorner')
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=statusLabel
end

local function setStatus(text,isError)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text=text
        statusLabel.TextColor3=isError and Color3.fromRGB(255,105,105) or Color3.fromRGB(245,247,255)
    end
end

local function executeEmbedded(label,source)
    setStatus('STEAL AN EGG\nLoading '..label..'...')
    local fn,compileErr=loadstring(source)
    if not fn then
        setStatus('FAILED TO COMPILE '..label..'\n'..tostring(compileErr),true)
        warn('[SAE] '..label..' compile error: '..tostring(compileErr))
        return false
    end
    if setfenv and getfenv then
        local parentEnv=getfenv(fn)
        local moduleEnv=setmetatable({}, {__index=parentEnv})
        setfenv(fn,moduleEnv)
    end
    local ok,err=xpcall(fn,function(e)
        return tostring(e)
    end)
    if not ok then
        setStatus(label..' RUNTIME ERROR\n'..tostring(err),true)
        warn('[SAE] '..label..' runtime error: '..tostring(err))
        return false
    end
    return true
end

env.SAE_V7=nil
env.SAE_MAIN_V7_LOADING=nil
env.SAE_FINAL_NATIVE_OVERRIDE=nil
env.SAE_EXACT_PETS=nil
env.SAE_FINAL_POLISH=nil
env.SAE_FINAL_ALL_LOADING=nil

local EXACT_PETS_SOURCE=[============[
-- Exact pet replacement layer for Steal An Egg
-- Uses the game's own replicated pet rig templates rather than redrawing them.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local DEF={
    ['Night Flame']={category='Godzilla',size=18,offset=CFrame.new(0,2.15,-4.85)},
    ['Luminous Cthulhu']={category='Depths Cthulhu',size=19,offset=CFrame.new(0,2.25,-5.15)}
}

local function allParts(m)
    local out={}
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('BasePart') then out[#out+1]=d end
    end
    return out
end

local function prepare(m,name)
    if not m or not m:IsA('Model') then return nil end
    local remove={}
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript')
            or d:IsA('Humanoid') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector')
            or d:IsA('BillboardGui') or d:IsA('SurfaceGui') then
            remove[#remove+1]=d
        elseif d:IsA('BasePart') then
            d.Anchored=false
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=false
            d.Massless=true
        end
    end
    for _,d in ipairs(remove) do pcall(function() d:Destroy() end) end
    local root=m.PrimaryPart or m:FindFirstChild('HumanoidRootPart',true)
        or m:FindFirstChild('Segment1',true) or m:FindFirstChildWhichIsA('BasePart',true)
    if not root then m:Destroy() return nil end
    m.PrimaryPart=root
    m.Name=name
    return m
end

local Factory=nil
pcall(function()
    Factory=require(RS:WaitForChild('Shared',5):WaitForChild('Modules',5):WaitForChild('AssetRigFactory',5))
end)

local templates={}
local function buildExact(name,info)
    if type(Factory)=='table' and type(Factory.Build)=='function' then
        local ok,rig=pcall(function()
            return Factory.Build({Category=info.category,Mutations={},Scale=1},true)
        end)
        if ok and typeof(rig)=='Instance' and rig:IsA('Model') then
            return prepare(rig,name)
        end
    end
    local models=RS:FindFirstChild('AssetModels')
    local src=models and models:FindFirstChild(info.category)
    if src and src:IsA('Model') then
        local ok,rig=pcall(function() return src:Clone() end)
        if ok then return prepare(rig,name) end
    end
end

for name,info in pairs(DEF) do
    local rig=buildExact(name,info)
    if rig then
        rig.Parent=nil
        templates[name]=rig
        print('[SAE] Exact game rig ready: '..name..' ('..info.category..')')
    else
        warn('[SAE] Exact replicated rig unavailable: '..name..' / '..info.category)
    end
end

local function fit(m,target)
    local ok,sz=pcall(function() return m:GetExtentsSize() end)
    if ok and sz then
        local mx=math.max(sz.X,sz.Y,sz.Z)
        if mx>.01 then pcall(function() m:ScaleTo(target/mx) end) end
    end
end

local function placeTool(tool,model)
    local c=model:Clone()
    local folder=workspace:FindFirstChild('SAE_V7_PLACED')
    if not folder then
        folder=Instance.new('Folder')
        folder.Name='SAE_V7_PLACED'
        folder.Parent=workspace
    end
    c.Parent=folder
    for _,p in ipairs(allParts(c)) do
        p.Anchored=true
        p.CanCollide=false
        p.CanTouch=false
        p.CanQuery=true
    end
    local mouse=P:GetMouse()
    local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
    local pos=(mouse and mouse.Hit and mouse.Hit.Position)
        or (hrp and (hrp.Position+hrp.CFrame.LookVector*9)) or Vector3.zero
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={P.Character,folder}
    local hit=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rp)
    if hit then pos=hit.Position end
    c:PivotTo(CFrame.new(pos))
    local cf,sz=c:GetBoundingBox()
    c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))
    tool:Destroy()
end

local busy={}
local function replace(tool)
    if not tool or not tool:IsA('Tool') then return end
    local info=DEF[tool.Name]
    if not info or tool:GetAttribute('SAE_EXACT_PET_FINAL') or busy[tool] then return end
    local template=templates[tool.Name]
    if not template then return end
    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name=tool.Name
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_PET_FINAL',true)

        local handle=Instance.new('Part')
        handle.Name='Handle'
        handle.Size=Vector3.new(.4,.4,.4)
        handle.Transparency=1
        handle.Anchored=false
        handle.CanCollide=false
        handle.CanTouch=false
        handle.CanQuery=false
        handle.Massless=true
        handle.Parent=new

        local model=template:Clone()
        fit(model,info.size)
        model.Parent=new
        model:PivotTo(handle.CFrame*info.offset)
        local root=model.PrimaryPart or model:FindFirstChild('HumanoidRootPart',true)
            or model:FindFirstChildWhichIsA('BasePart',true)
        if not root then new:Destroy() busy[tool]=nil return end
        model.PrimaryPart=root
        for _,p in ipairs(allParts(model)) do
            p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
        end
        local weld=Instance.new('WeldConstraint')
        weld.Part0=handle
        weld.Part1=root
        weld.Parent=handle

        new.Activated:Connect(function()
            if new.Parent==P.Character then placeTool(new,model) end
        end)

        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and DEF[child.Name] then task.wait() replace(child) end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') and DEF[child.Name] then replace(child) end
    end
end

watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(char) task.wait(.2) watch(char) end)
]============]

local EXACT_STAR_SOURCE=[============[
-- Final held Star system.
-- Priority: clone a genuine client-replicated 3D Star if one exists.
-- Otherwise render the exact supplied Star reference image locked to the right hand.

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local StarterPack=game:GetService('StarterPack')
local P=Players.LocalPlayer
if not P then return end
local PG=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not PG or not BP then return end

local EMBEDDED_REFERENCE_B64=[========[
iVBORw0KGgoAAAANSUhEUgAAAHAAAABfCAYAAAAwGkOoAAA4IElEQVR42u29eZhkR3Un+jsn4t7cau19U3ertSCptYtFiE0SMjIGvH1UYRsPg3mMeDYeY8Bgjxm7up7H4+cxzHjheYyNMYufzVRhAWKTEXILs0hgSQhJrb0lJPVe1V1LVmbeJeKc+SMiM6taCyAkuzWfsr/8qiqzOuveOHG23/mdE8Cz/DExMcHd779z/5d23nfHRz9w33ffv//uO//r0o03//XXP/nFz/wcQACAqakpg//DHvRsvnhVJSLSb3/7azvWVG59p3XH3jic6mhRdOB8AalYtMtBPLq46pp/umPjrv/yjrHvTE2NmfHxaf+cAP/NhTfBRJPywJ4bTkvzm/95uHJ4Q3NhHt5DVCw5JfIQgc9pzUiD9mebs288vO4XfvkX/q9P7949YS+7bNI9J8B/M+GBMD3G95//+zY5NnX9UDr/ksXmfCkKqwRSBUQAFUBFkUjLNQYqdi7Zmn/z0R0/99bX/9JnVKcM0fizXhP52XjRN9zwCkPj056OfvQPBitzL1lYWnKeK4kgIRGCCCCiEPWAKgSJXWiWUi/2Vi7YcN8n3//Jj/800bjX/wN84rNOA3VqzND4tN/79d/8xaptf9yVhXi17EVIxENEAChUARUHVQWEQaRwSpI2PB/T9Us3HHnpi943/tN3PdvN6bNqB6pOMJ3957L3xt84t8Ltf1DxqROQKpHzAhGBqkBEoaIgUah3CIL1cETkilI21I5V1g6Vr6qf+55rf+Xn3zY7NjZm7rrrLn3OhD7Tfm8XcN9NbxxS1/wokR/MCydehIqyhPc+mE0RiHcQ7+C8QxBs0EzyHagWPDfHsp73nfaGc2758sSH/+Lln5qe9rosHXlOgM/AY3p6jGlyUri96v31qr1gYcn5UmCc8wAUEBdMpveAF6hETVSF+CBA9gz1BAXz4mzmtlX3bX/h+tm/2PzOR2rYBUD1WedS7LMoZfD3fvUdb65V7H8oMvbDI6PGMMEwQaTE3OwMXNYBAIhGH6gKhUJUQSB4APWkgYGBGoTYZmXmzl9z7MzJS67+HaLJ31bdaQjwz2ng0yw8YFIf/Ma7t8H7P2m1coWxXElqsCaF94qsk6FwBbwovGqMQBVOBU4EooCXkFtYk2BoeC1Gh4cxOrLWpJiXi1Y//M7/9LlPnk007if02WVKnxUaSAS9+yvFOwYH7NDMkUXfbLbNjBwEAHjxyLMlpAnDVtKYAAIKgEQADWZUVWDSFHv2PID9+xZwyqkb0M47pD7XdY3Z6o+n935y9wfufPkunD2HiQmenJyU5zTwR9W+iaB9e65/y7ZKor90+OCMFlmbXVkiyzIUWQ6Xl2gvdVCWClWCCEEVIQJVxJ/Da94LykLx4N5HMXdsEUdnjmGhmfPhOe9PGWzufNeOr/0WEXTnzp30nAl9Oh67gvZZr79WMxg5cvCIAEwiBGMsmABjDABCmReA7/o+goLC7SlBJSim9w5JWoEXhvMeTAQWg44Tbh7d53dWH3rPH/zd310+Pj7uny3AN5/o2nfLp35hm+HkLQ89ckAbjWGupHVACQYEZQaYQMQoiwIqEgMXioJTEBEIDCAIUpXR7hRwTuBF4cSDHFHLM63CQbyk8b0/+rGPH2yM7dmjz4ao9IQV4PTOu4gIWh+o/FpqMXLsWFMGhwapKDowpAAC6EkadE0RkvhgNiVGoiEv1OgUgzwi1KYMqIAgUHEQRzxblH774JELf7Hx+XfR5KRMTU/zcwJ8Co+JiQkeG5uWO6+7amuSVN+yb/8xHR4eZe9LePFQhKAE6qFaBsH1fJ0GKK2rjfG5/JbFUcgTNWhhyBUdcsfUas/plnTmV3/m47et27Nnj+oJroUnpAB3Rd+Xwvwaw4wcPZZJY2CURAyYUxBbgBnKBooEoBSCKLyu0HppSF+ICsB5D6+ArdWQ1qswaQJOLMgaECfsxcuOocPr3rjuW++YnJyU6RNcC0+43aUTE0yTk7r3uqtO8pLc9sDemZE9d+9DvV4nIkHpCFkmcL6ESomiKDA0aHHGGRswPJyCTLgl1pXCgyrIWDz44ALuuPMgdpy2GUNDFXjnoUowlmETg0Yl0S2bGuoHthS7l0698r0//eZ/lnBNJ2RaccLlgdM77yIAosT/kUCjt97ygG91YGaOduBVAGUwKYCwnnlewpoU1lp4VRilnllZbjqD1xSkVUWlanD/AwfAxFAxEB/3shEQiE4/bY1c8fJq9eTK0h8p0YsQronixzyngU+MuoTrueezbxngWnqn93zS/fcf1qRSYSEP5z2AAgwHJgYbAyaLJDGoJAqBBzHHmBOP9YEkEGUcnlnCUquAOII4jimGQMShdIBNgRedt1Hy1QP6ebP2df/tiv/2pQ996KrkbW/7y/I5AT6ZAGOt764vXfX2wUb6wYUlJ6VTLl0LKg5QhiKkC9AEzAQigqhAvEAoCO3xBRgUiFjAnASfKR5QgMAIsY9CiCGqSJl1oGpxKN1w6F8qZ/zsf37VVTdpyEr0OQE+kfYR8OB1Vw11Cn9LrZqc0s69FIXjomxD1YEkXLJSMKVQ7t2CqodSsHEcUwyJuKiqdCE5EIUEXygIGlE7VcP7zBQuhBkGpINpnfbRutYhWfvHJ616/q6ZmRkdHxsXnCCCPHEirOkxJkBbpby2XrOntNq5QJSJCIYMDExYXAaIKTxpuYcDFAQmCmsb3yTSx/hDQMHLItaucIFAxYhQAJSZmq4jo+5wY2Mtfd9s++D54+PjXjFxwmx8PmEswdi0qE6wd+4q50SD9nhAFMQcBcYgIrAaMML3Qauw4vuukLrf9zSr92Yf5O6/Fj6DmXt/h0AgJS5CtVislH/26c9/5JK4Ieg5AcbH1NQYE0G/+7mHX1NJ+eXtrFAgKElvyQkQIggTlAkaFz4gMCu1iB7HM1BPI+NGYAYf9yRmgLqCJigUHh5KbIqyzWnqLx4ctN+49vrtv0xEeiLgpSdUkqqe3poYA/VQaBQMdaVIAEdsM5pPAsEEj9f7mXo+UR9XeMcLtat1zBzAbYp/TjUoqijUl2CahdX9rmpm0LBH3/vFm/5k6ERAav7V/3i4YQJ2TRB23kV7AHP2+HTx4PXvPK+TtW8qXacSBAeCGkAJHh4eZT8NUwVEAYkCi6rapZZRDFyOTyOIGCAf/g8FgQFR4yjmMIiRkBK8D7hqJ89QGx3Ghi3r4H3uhwZqptXKf+vUF//ZH95551i6c+dZDpjUf4sIlX50gYTP2LVrgnbuvIvGxs5STN9FN6w9iwDg0kt3KrAn3tgupW5Usfwzdk/Y/fXs72spv/7wkcO+yHMjXkFgEIAARwtACOlCBK3hpadtIgKyFoa4h5WqUAxMpC9AeDjnogBDQBRMcdgUhICpGjZQEIqiQJ63cd4FZ8KkgqJoq7WsTFyWhf7Y5os//LWVm3PXyjV93LV4/HV4RgTYFRB6kdddBADT08CePWfpD1u53nvz/zs81CDJF+c2GmO2KLlLCPgZEF0oIqo+p8X5BXTaGVKTYHCgjrRaRVqpRNMZNM5LyP0IBOdK5EWOhYVFZHkBAkM0VuaXQWrEgGiJwYFhrF49ClEf0BgVeBGo9yARlCJoNlvIsxLOldi0cQ3WbxhFK2sBTBBRraRMrvRHbJr+91Wjo1cfWbj34Pqzp5d+uI0/xsAYfhSh0uObuGmenp4GAHy/RpDDd04MuAzSWji4MU3qGxqN4Vwg29imp6hIwWQGvaeLAFUnWimL4uxOtgSGjtZqZiBJgdJ5LLUKBTwxeZRlDl84wANpUsOmzRthUsbyoMZ7H4SiABugKAsc2HcI7awE2Kwwo10tJFZ477Bl80nYsHEN8iJblmoQRBSkHsyMhYUW9u87BGMJGzeug/dFAAEMIyqr1uopNZuLODafLZ209aRZcf7uhGwOJoKSgmBF9F5P/hEoVWHSo5YrtyWoPzhy7n+ae3KhjskPIlBaIbjpcabjBKZTU2b2nH+p+3Z+shWplt6fA2Bd7vU8BddF6ew8Fz20//AaV2Jo6/YtGBmqoZpWgkNgC/UhunPe4djcAlrtRYAUIk5BKlAlImZAQVoCkBD2O+C27+zF6Lr1OO/8HfC+hIlBRlAwgfcKqODo3DHkbYe0Vg8stKipEstKRAEjNcZi/6OH0RgawM6zT0aetUNuSQrVENMZBpaWOliYX4RhA2KCRsFydHRMgEkSXZhvC0zFXHjB88DkkRgbjH7PXQtKn8OLQoTRaosymwPG2PuMTW5n5tvSqrmjTNY8OLLtV+ZWCnTKYBrA2Lg8kX+1MYw3ROQB+EfunFrV6dzyWuPzl1YYjUf1pjN0sVglzm1hEVtNGQpBagEngjL3gCc4R9i796BWanVyribinRATgSwAA4KFiKLZXCTnczQGqsTsKUQqBCYPUPBTsVwLZka1MowH985g29YN8NIGqY9CQQC3ocjyEkvNDuqVBpAVwbyq9NCYYD4JibFIU4MsVzx4+/1YvbqBPG/DmJAyUC+oUTSbbVhO0ainIT0x3M0ggwVQgRQlGZOYO+58UAcbda3VEnWu6AMLceNkWYZOp62Dg0NkrTGVNNncaNQ2s9rLvBIWlpzadG7//F2/cV/p8juqtTNuHBh83g1EVxxeIUzsUaKVLsvGHjv/V3/1zlUXn7PxLVl2+9srJttOcGAIvFN455CXJVQEi0ve+14CzACUvLPwpSX1CblCVURY4RjKIAVEfaC4q4crOwApmARMMTiJAQYjCE/BYCawASppAqYKCBbWGHgfEj4VgXqCqIOUijIDOuKQJoTl1M6gCQT1QOk9ijIL2uAZReF7xCdjDKw1vYDGUAqVJNwjhQ0Q1b6HDoQURJFlObWWOsTkkBc54j4AkYE1BkXuUeQKrQNORZ3LtNXJVFXA5ECAGRgY2HJsxm0ZHKpePthYfIfT5sFs/z9+psyWPj2w42evjwoWLeU003jorLJEpB98/7vefOFpld9tmEdOLrMOFnP1nSwHCo9qwkSGQKxERACTYe3uVASAmQjGRO1RQ4lNAxssWmkWhZrIy7QEJwrxCk4IpF0oJa4NMVgVrABzgMTK0qGTd+B8G855kJce+AwieBfxTSUoApKCLv7ZjTDjryspyDCKokCRlRB4qJQwNoG1CmOCMIkSeGcin8YHwJs8oI/NJZkIWV5gZFUKIxx/J2Sk4f9bEFtoWDOiAPNExCeBwmlWlvqNr9+l27adqqf5fWyqfuOW0y75ZfXJLy/tvfqWpQeuvsYj+Xsiuh+A7za32l/4qTefs2XTxr8abByz2WLTEZhRlkayHPAETZK4vtLHOEh7FbYeImCCQEUUgIkLKL3dCITFAwFlWaJ0CdiaPiYciJyAUrduEPMxRZk7ZJ0cYA91kfcSEUtWEwVfBHPZExuD1C9TmG45T2GYoRo00CZB48UpCleCOMBuWeagmsCrBWsfbwVpEFCsfBibgJiRZUW4DdGYrkQwITCpIL7HEQj7jnswPAAlBtOqVWuRZTmsEvZ/7z512pC1607hNLUXpTa5qNXO3tt64NPfaOXZHxPRl1QnmOuN5gdGRur20OEZ32w5m7WVixxwBUJjSLwA7cFL6O2w3j2BwWx7ORXAgUCk3L1+iAAkDHGA9+jijKGcowpS7uEq3YX2CkjkejofPo/AAdsEg5H0iEqBQrgybQgZkAHBxGtCzA0ZqgZOGIABU9A0JgIJR36NQVY4lE6CyVYNn6O93RjulAXGGrTbHRAIAoGHBE3vXhp1643LNr32N5rCQjxQb1Qxv9CCV4s0JZo98pDJskVqd9oyd3TWS5E3rNFXVQx9ceY7H72MaFLswODAjsXmnGYLRzn1JSqmCmsTOBEADjZJwSYBRyfPRMvMV/QxJGADMAPiAaYKlDUEEtFTsiEIe4DyYPepi6Bw/4YkQmcKePXQ3k0rjKkgSQ3KwoEg4AhIS/RH3IPJNEJrBImbLLylEBIwJYEnqgBziqRCUOeXlZsEIIZ1At9pIy8KpKmJESr3C/MaBEQMVJME4hW1Wg1FWfaqGYTgBqwBVDy8FySpXYYOxd/jkHU0Bup4+JEFzDdztDttHDk6h6HBDdi8cQvPN+fBZHWpaV1tsJZ4kT+dvekTL7G1xvDVx2bm3uM64lNlY8iBuW8GWu0l1Oop2CqqFUa9VkFiGdYmYArCUyY4X6KTt/HQ9w4iywoYK0E2wfFEsq2Hczlq9RTqATUEMnEzcuiotcYiTSpgMPJWB2wES60l3LnnIaxaNQBRAyYOOZl6qHIo4pKiVjM9K6HLfV/UDVYCM1D6Au2Ow133HsL6DcPxXm1gVTBgosZ5UeRliSGTghnwvgwmMlZHVAkMxcDgIPbtm8eBQwWMScBGEWKesI5KFqVbRDvrwKY1QBTGMoxNwKToFCXyokCzWeDRfXNYdf8MkrTE3LEOlprzwIaNYFIwHJGxSaedS72ant0sWv/dzi8uPbjUrsG3hGcWF6AiICJUK1WsWj0IIaBsxtiQCliTw1hGtZKgXkuRVgyIDTpZgU7WwcG5BRw8eAQh3+3yNhnEFsyKgcEKNm5chXolQSWpxA7TUDZKq3W0MsLDj8zh0OEZuFwBrqE+vAqPPDKLfQfmoWRiNUjhXIwiXRs7tq3HyTvW9QqzXSMRku6wkAE5DUEO2xQP71vE9/YvRD0ImqkkYDUYqBHOOXcjwCkOHhHUGwlGRqsYrFm0FucDCkQWTIqiyPDQ3mM4fOQW2AQwJvhxLwKFQ1phbD1pNQZHG0gTCxGBc4KlpSU0mxmWWiUAxpEjGY4dc/jeIxnWrK3j6PwsWp0OyrIEGwPTvTdV5J1MiiK7wrYX/W0k1qcmNQu5RpMlICpDOG9MzLVDVOe8R+kEeZZjqZmDGTCW4T2wetVqpJUyEI+YYdjEupuLEZdHmhKSJGyANOHY+uVBpoZbb3sE11z7Hdy/dw6dvIJVo1uw78B+nHfuVvzkj5+LxcWD8AKwcN8vMQPiMNioxOpCn1BNsSTUFSZTqNyvHh3GqTsMOoWDEw9RjtFwgFfVeQwNpbjjrhl84R9vB0yCTnse27atwxWvPBVXXn4mEt9C3smhYrB27QA2b6kjy0NU7r0HiKPvJbgCKApC3iEclQzNxSY6HQcvBJAFowqyBknFYGS0gwMHDuLQEcLgEGN4ZBRFUUSfzhDnUDoHy+Ayzz9CGzdeVH/Pvz/vxq1bknMX5o6KUiAVsAWqFQKzh6qPUWg0UNQLVXp8S1WFlIAiRJfWMCppFbV6DZWqwpiQ90E9LCtqFQYgPb/w1Rvvwv+6+ma0ygrUNPCOd78fV7zqdfjU1DTe9a634x1vfTled+V2dBYXwJwGCoUEaj0Q/FgAvLs8F12WB8ZgiwFGwE/JJAEUj/4RCjAFJz7YMHhgX473TlyL//vXd+F1P/t6XP2pv8XffPjPQOjg4gs34Td+9TLUbRtFVsAmKVqtFjqZoFapoPSEolQUOZDnQFGUsSzmoaIR3TEgMoEeErMTL4wsc2i1C7SzAuvWrcUrXvFiGFWoJ6QmgXOi3jnK2vlROPsCs7R0sNy2tvH8U0/ZeAEbEmOZK2kCawlMYUE0BgzdmIliStBLAYiDfzFBcOAwYMC7DGXRhvc5AA/DiqSSwBjq+aYkSXH7vQ/jb6e+jkxGUaKCodENePt//B2QqeHCF5yH3ddfj91f+Rpe+YqzsWqA4H0Bhg/XQwJS36sbhmwhpiLLhKeEWMQNOFwXMOhVEDmYelaPxkAdH/7ELdh7QPCB//FBrN+4AxdccD6u3/0FqACPPtrCI4/O4BUvPRUqOQCg3qih0aij8B7tTo52uwzFElKwCUEWGxuaccisoIL0rp2BSoUxONiAqGLnznNx2hlnA2zhvKDTydBpdnwlTSgr/PVn/eRv/k8DAM25o9Wtm9aPbd681pfesSEOpbMeShIiRl4OoCqFdLALP8V/Cg2BTRSvE4eicGi3crRaHXTaBTqZQ1Y4iAqWMsH01Tfh4YMMJAPwSpg7tgBVwik7Tsc/3XAddn/1y8jLAhWrOPuMTWi3s64ziHmV4ngGaDeR7wc1GtGebuZlIdrNO/qV/Yq1OHLU4Zp/3IOMclib4rxzzsWtt3wDn/3sNNgIqo0GHtg7i5GhKs45cwPm5zpoNh0OH1nAzEwb7Y6g9BRJVViWejwJs7RXFVEUTgBTwYtfchmqAyMwlSoGhobQGBiQSjVlJlDhind98BNfud9MTEzw1V+4bk89qdtTdmy8tFo14p1nUg/iWCPjmAoQhZSzl6v1EQehbn67vC4ezBKRAYghxHBOkOUei60Ceelx9z0H8bUbH4WjYbheAwrj1ltuwj9++Rp85bovAshhKyl82cKLzj8JkH6C3jWDulx2MSfo+j9SRLITekVb6RV8I+wFQMShmjLuf/AYvnHLI6gMNHDzLd/CdV/5Iq790jXIyw7IhJwWlODgoUM454zNWJxfQrNZwnmGsSmsSYI5JookZD5+ez2mpqCRdcDEaLYLnHvB87HtlNPR7uQQAIX3UqlUuDE6KolNf2fD89/6EdUJtpOTkxpB111bd5x02mUvOnXc0JwXgQkJOvrJNnzX8y2DdYPwEMV6PMzURSO0b8diAkxwkuCBB49hKTNASlAfMyg2qDVqWFycQZKkABN8AXRyh07uYHuIR18DvQaDyEzLFqwPpFHMWwlBMxCRpRDGEhRhmoWqRaudwwnBEKNWS3DwwF5YkyC1Faj3UBYkaYJ9B+Zx5z1HcdrWQZAvAlzWK2EthwdXKl5PiMvKY6RBObJOgTWr1+OsneegkxdQZngvvl6rGefdUnuh9cZVO37mmu6osYBGE0F1Qv6/j332DYeO+D9OK0NGEMDTCHBASSFxYIAs0z6AwNHnPJF5CBqyskuIY3X96HwTThVeBc4rnADea2jAtGkk2hIUBqUTlEUZrkHDJApWBbygmiSoVJJ4sd3OJem1VyvC7BgvClHAsgFTmC3jvIfzoTRVOg+vAQVSZUCAaiUFGwMVH0tZoQpSisH+Iy1wWoHEKLZHmuqC3XEB6TjNUwSBhToRARTAgtwDF77gYsBY+BD9u5GRAVM4d89i4S9dteOnr9GpKdOtSvTaCIgmoar01Wv3//bhY7ijVmsYr+IFCiWBkEJoOTmWop+LZlSXBTXQlRhkZHwRc4SkIsirDO8V3sf5LgBUlsNwDIiAVOBdgcSGioH3PgqC4QUgW8HDB5bw8L4WyNRCuK3c9z1EPZxU1YA4xcxcgcU2wVYqsTxlABh4IdTqKYzpGxmnwVR79ZBeB3AJhQ/+WGNDaTegXdZQ0wX9KYJMfctAywQZOo6brQ7O2Hke1mzciCwvoQJfG6jZZiv7ZqcofmLTttfeort3224l4vjmFpkeHzfTN0131p72S79y3s6h61YNVquFy9XCkMTBAbZL5aPjTIL2L8kj4IckQdMCo1p7XCQGBfyRCfVaJYQ+cSQI1EfcJIZEXkBs4MoCmzdtALRE0WkD1qL0Ho1GHd/+7n78/5+6GYUjvO6KM/FTrz4L7aVOD9oLiJ1A1aNaTXHt7nvxmS/fj2otwZt+/iU4YxujyHKAFN4VWDvawKrBCo60FDYVhH5gRC0J9w8JZm/16uEYMAUhEi8LLnvsuFgK6CJTy3SR4losLLaxbv0WnHPehWh1CjUmleHhATPXbH5qPrO/ePrpP5WHAX2XuSekFY5PT/uJiQk7OTn5mbe96Rd/95ILR/8otYUrSjZMCTGymCwQKILVqgxjCEMjNYyuGkCtmkLEg1QDtmhMjJRD0LC42Mahg0eRZQVO2bYBIwP3Ya7tYKyFX+FIAzusOb+AKy8/D+M//TKk0gaI4UqHgaEavnnzfZhbLKA2xZb1FVz+itPQXDwGMCBcwT9/+2E4r3jBeSehkjq0WvN49at24u5HbsRM22D2aAeNxhpcdPGpaC52ACgGahZrNm/FTbf9BRbbHmnNRhMv0b8ZtFuLOOuUtdi6aRXyzizWbxjG9m1rkeXZMrMUNntReDy6bxadlgfYxvdCDuq84PDsUbzix16DpFZz6tUqUavZbL13y1njf94t4hKR/MD9gZOTk35qasqMj4//cSd/7aWXv+Sk16RVL76EqnrWOMKjWxcDGM4LkiTFyMgoKpUuSTYQZQXSQ0dCC5dHUrFod9pYv3YQz7/gZHx59x6AhmGs7cW3pIROs4XRQcKb3ngF0qSAz1wotiLMQhNvUWYlvO2gunYYq0cHwWUHaW0V/v5zd+DTX74H4AS37TmAd7z1pUj8LGqNGmopIT+8CGs8BIpSECJZw2i2MmzdlOJtb74Uv/f+L4HsaiS2igTBJ+SFhxRtXP6yc2E1Q+aAamUQtVoVA4NJ5J322wm9Z8zNddBeaoOUe5OknBccmZ3DWedeJIMjq+HK0rpS73WS/cqp57/pnwKN4snJTU9GKyQiUlVt/NLP/eTHX/ai0392qK7IsxlhUQ7YaIDYlIBOu42i7GD9+lWo1W3QTmIYpl7MytEOdToZ2u2AIxIRcp/ghq/fjW/d+iA6PoFQ8DmGFcP1FBdfsA2XvuxUVG0eILRYILWJQacw+OI/7sFSOYAH9u7FxRduxyXPfx5uueth/MOXbgVXRsGJRXNuHj/+0m248uWn48ZbHsbXbz6A008/FyPVNl79yu0wWIIrHJglXKd61AZGcf0/78Pnr9+DxXYRghcipFbxmst34oqXno6is4jWUgf7DxzDKadsQKPOKMuiF4VCNfhwV0EpAcgTDYXpo/OL2Hb6Wf7Ms882eelg09qfL5byO5dc8h+O/aADab8fL7SXyv3GVW9/8Zmn1SdGB/IrXbYoAmWlbo4ncK7E7OxRJInB8MgACA4hrotkWTqO0s4BQPbqY6dYBQ8+NIsHH55DKws1uM0b12LzhrVozx1BreKxbu0wvLpI9Q0bvJJW8fDBOXz79iN45EAHh47OgQ0hV0DVwhcZoAK2dYh6VBNGUQBDQwPYsWUNLr94K07emCAv2oF3CvRqkAxFozGE2XmPBx4+isNHj8FYxjnP24qt64eQd+YAYiwtlrh/71Fs3bIOa9ZU4Jzr0fjFE7zzcJ5gqzV4Arw4zM7M6mmnn6mn7TyLj80vHkyr6W9e/Mr3fCKQzKbM+PgPNk34+7VYB+plSPRvHLt47Gcue92Ov96w2v58ns0LlDhULoJjHx4eCYgHMZhMBI6lB711v0hEmRkKhglJueY4a8canHnKJnh4QASsgk5e4NjBNgZqo7C2Anjqk4YQ8rTtm9fhnvuPYOboYeSeURQEUoOq6eBVl56JkcEavnLDHZidFzSz4ItnjxzGzu1DOHnLCFw+C2MZBA0IiomURGW0Oi0M1RkvOm8d2GwCAXBFhk57LnQIgyFShpzPBhdHMegRDamXVwbZBOAE3hU4emzBb99+itmydTsdPHR0Ktfyva99zfsenpqaMmNjY9IlMD0dAkQ30Y+BTeeovu6dr71i06u2bqmP5u1MiZhChEWwNom1OA9RBROF3FFXohFdVMZDYHpVA0JeFGAqetWBEgLnQqVe1K80GRIaPVUB8iWuvOw8nPG8rXjgezOYme9gsFbDBWdvwSlbGoB4XPS8Nbj1zn2Yb+ao1SpITRWnbFsDcS2ICqxaKAAffXVIizwMGN4BZdmKNMHANmPuI0+qHuJdvymm274hCgGDTQXWWjSzjs4tNmXjpk1m1brNB48cXfit17zxv368y7+l8R9+hvcPPORgcnLSxZH9h888/Wemtp18xi+rcYXzpYWaAH27EkoFjA1Rlu9lUB7L+7/6QwgYEk1VINRS37ITeh20AoYngo/sVlKO1ItQjlEA5No4dcsgTj95VcRTBeoKtJoLEBXUqxaXvvgkMAUTumfPAbgigyj18lCh3kyn3qguin2Ghvix8FIXZaIwk3QZS7rHBYAw0lpNljqZLnQKUxscMbmarxyYb131pqs+8FD33IunIrwfSoAAMDY+LRMTE5wfuf99rXa5Y2hkzZVHF5bgWi1UICriSYhA3odbNybCn3GRaEURZUUb2PGtX31ylINIHMjTDXx7MI+PnUUhYs3zApLloQmmy+ExFgaAc0BRBO3Oc0ar5TAwHCAvJYqfqysS7CcfSqG9InGXQkkGvZY4L1BRI2mtwbNNx4ePtkHWzojRP/y1d37kfwCQH8bXPS0CJEB11ySIMLd7auL1zaLxB0PDG16Z6eKZuvgoqbZhqzbMMHMF6tUqiASuLMAgeO13yGq3Itf1ib3qXB+9oAiBiQegJlTNwZFrG0nByj3TRcQwFBCdQIGXfv97RPq7NHovIUdNrIET06sI9HsNsZJF9gQPEYUvQ0U2MSnIWFEhpGnKlsncu/cQPn3dvd8+ttD53PBg+rGb9xx4FAjTqH5U4T3l9rJltBPofVr5yu3Xvqw5c+dH4B85yaOpJrF0bOYoqpUKjOHg2+IkJTYEa0NlnCmAzp66xCNEDmbc/ExYbOZ48KGjaNQHsWHjaERoAjRGMZAhAqzRQPFDv27Zdb6KfgsZEdBuK757+wHUB4awectwr8oSxngFOCwxhEbVILWx+WV5Z81xVmJ2ZhEP3H8Ma9etwpq1w8hzASfmQKmdf/jgn3/pM/cdxe6uOo+NjZnp6WnB0zRz5in3B6qCpqfHeM/4tE4C8o3PX/Nnxt/1qwtzDzhrUnvbd+7G7LFWAIt9ZCHDo9FIsX7tEGpVA8Mhl/R4HAHG11qdEo88Mod2G2CbxmKxxgIsQ9RAxWFkIMX27aNITQlWCQC6IvJZtW/yGCgK4MEHFzC/4ABjIkYZNoKQhxMGice2k4aweUMD0KLXJPzYPIvRXMzxwN4jIo5ZYe7sdPS/HD3Y2f23N95+pOseXv96NWdNQyeX1+FOhAbP3bt325mZGd06gDcbufvDneZDvixhvnPrfVhqC2xaBRkb0goGqilhaDBFNWVYE7TE9dpZloPiATQuPdBcLNHuAB4mvKrSC4JieRa11GLd6hqsdaHcQ30Sdc9sk4a6myo6WfCFKhwr8wFsVlZ4YcArGnVgoBHIWN3KPj3+ZkarXQjUqGV75b9732ev7zYNTU9PY3oaT5vG/Ug+8PEeMzMzOj4+7v/5sx/cX6E2jBUCGKecugntzMdUnpdFlj48SWJqQStWotenHGt4zMDQcIrBQe4FJqGYa3pE3NgRAYaLvrEfgPS1sGv0wyEgjZqiWgt+j2HA3WpIN9IFxyKw/wGGbKkOD1bYC5ZsivumxsbMD9JbeUINORBpvtwmgcWTpgajIwOoJoSKFVRtiYp1SE0Jyw6Gtdef3mVvdxGdkBZEpIVMICIZgrWCxAqsEVQSRWIdrPGwpLAMEHuELnmJedzxNXA9jvLbBRI8gBJKHto15ho+qxsE9ZtV9AngKibnoYmlRpnJzvHpaY+xZ8mUivHxcT8xoWzIX0FSwIRYGnmeQcTFqrgE7qfKinGQ3eKudnsvmFaESX26VGznAgUf2R1eoQJlwFOsT3KMb0l7qUHfhB4/r456gHkg9EQj3uNA0HFeRldai+PCOiIRa5kEvONZM2akm4S+5gUf2W7Fn6F5CVbDEELZ7RGg7nABeizA2lOOmEJEphvHpqx+RaM7SYKWURWoR/9fsd5P6u7pCTTouBj7cfLUJ4nIeyFvrL6c+a8pwB/JB3anu7eK2bNGknxQMidMhr0Ewi51G2GwciKS9qbGKaTXCtZnjFEs6cryxVzWFLQ8ONHl/lOfCBB4vJjtB4speqD0cjBeseK1wK1S8qIAyRld0OOE18AxTMdC7eLpJmlC2alSaAhxTo5Ti8fu7G737PGTlbSrfcuIUz3oarnffZxF/cECb3pSlTp+TPPx9JHlX7tpjxJIREDA1qkPjNUI+P4owIkSxBAvbCcq4FRVSFGULpygEsORni9iWumbqOtbZKW2oX9sDkiAGGl2zafGZy/v6PPjvr+AoP0ph93BedT3f10u6ePT7Pr4J3X9Z99TkwuAzEnWlpuii6ET2oROx6/G5XVNTKi/eaAsQi9cr1+2R7U73uH0uNyPUVLtknYjLNYT9jJSUJd83W34VOqPjXxsoC8runShkYcaqYcBZusGNjFf7FOD+1dJy7icy+iVZVmQqEhiUVnMi1MA7N0ZJv2esAKkkOcQ1PJ5HgTlhIssR1EWYO7TQihqSjjbz0ec0/RgsB4l73hDRxz5nV3kJSpOl87P/SbJcLwAgbuck+NNDfeTblEPLwUMhfzaWAMowzmF9wLvHZgtbGJhDId05gl48aoC0RJDIxbVSqJDA1XTycqTAdDYv0Iq8TTMzCYYGoRSG2QIwyPDWDU6EHM6ijlcaMoUdSjLAgvzS5iZmYN3ukzx6DESDBpjUK2mGBhswJhA87fGIklTpCmHzmAAZV7i0KFZLDVzILZ1rVzorvZZeJ/h1OdtxKmnrQvIjgeyrEBZxCMNRJCmFRydbeGeex+BIRuVVleUkRgE8R5DI3W88OLTwZzrQN2i3S5fCOBDwFl6wgpQJyaIJif1/q9++KTZ+XtOKUrA2pRGhofRaNiAWYaydIg1GQH3FEWSVDC/0ELpiliB6HY8rey5EFE451Cr1bBu3VpUa4D4spdSiwpACsMW1qYwdh5eOstqd/SY4IUI8M6jtZSj3Va0Wy2UZYmicKHFzFBsHO1gabEAke3123cjalBs7IGCrcHBg8fw3e/sxbbtq3j/I20sLZWXffgPLxkkmmw+02Oan7IAd8WvrWy/JS1qvgCWWk1ki21UqgqyYeZY8DOxgkCEonRot0vkuYsmkiMctqwtuhedMlqtEgcOPIKlpRy1OgVgmYJwvfRi1vCaVxClgemhsXdCj1dsRVFYTH/ymzjvgjNQr1t4l4eZadHUh3EpDDaMSmqxfDDBcpZ1txqyMO/xtRvuxeEzNnNZ5FqtVE4esqtfAuDa6ekxBp45SO0pC7DroE1ZbK9bY+fbqgcfnaGyzDE0lMCTg0MMBihOS4qoJcNEWkKPYdrDLwmmh5EqDApnsLDoMLwk4HjQFcXpEyGa7HfDU3fxIxpDy4IOCjNQAjjGCYwZRq02gsFhQlnYOA3muCgFoYkGsRmmyyegZQGMCmBtBWxq8D5FUkmk0UhNOyt/CsC1J2waMRbBPuPNhqqtWe9Y2h2PojQQqoAoASMBUQogBVEKphSGKiCycZcvRyp1RRlpuQUkGDAnMMbE4ayRk9KdnR3HJIdljhNklieGXRsWBm6jLEvAerANzaJQge/1M/ShNSh6bdv9qDlsNqEw4EgYKMsCIh6GCYaYojm+cuqDYwMR0KYTToDdh8t0WEpGWYbOVFFaEXb3mjx0ee/644X5+pjB5IDGlq9Qleh1GnWfkJhvdjcA9yr53VEjKxCgwKFDnjsYMqikBhAf4bs4J4b6bWsrc5uV+WVfJ2OTjzBIGQzPzjlNUzpZyuIlsazEJ64AIeeDBKUv1Hu/TJ/6Y6+Y4kzqbj8fIYJl+rh4Y888KeCdxNEetGLY0HKdCH7U9PJNxL99PLoTDohUlKWHIQs2FNrIqA/jKXXP4CX0G3j7LWOPKQQisNS8ShiVQgQPSGIsjOKlJzASE9J4dUKlK1GWJZxzMc+yUDHHYVC0zAB1k2mJR8BpYHivMKUcO4s4th9312v5wJ3laIysEGsQFq841Uxj4TYvCiRp7LOKkw97E3s9AOmeScHR5x1XmVg2wyQM8wkWCMwh1UBYE4F/zc0fuigZD7gonUgCJBoPZ6+X3p2f5yXyvOSyLCFeI9XBAhSGvIFMGMUVfV8fpVpeG0LsQ+tzWDzCjE2FifOuDYQsQAlA4fMFHMZnx+WUOM3Xi6CU0PMg0q/eK+LPzDCWkKYJkiSFSSxsxSJJLNIk6Q12XRnF9poE4vAi9Pytd4SisCDUAdSpUybwWjv37sWt5wNQfYZgtR8pkafJ/0e+8bFfT+Ed4AXiHbK8g9KPgE2KsggjJokZhgJy0qWv84r9s4xaqH14jIi7/eFYbGVQ2wi+hoJWQbqjuDzSNPRhSBzy6uNEQ47nSXA8styVQO4InYLwvX0tGCZ4kUjT6p4IIxhopGjUAUb2hFWKvp/3cKXDvffsR5Km3YqkTyybVid7HYB/Gb/rmYHVnhorLSan133oN4cpXfxOmujJM4cX5e57HuLMA9WBIRhrkBcFROIcNQ0LWW8YjI5WUEv7c8cIeMwBHAKg9AYzhzs4cGgJxIxqNe3PpNEAY6n3SFODkVV1NCoGIA/nChRFGAzLzDCGAxrEhLxQHD6Sobkk8K5r9mIHMYWh6Y0KYfO6KtassSAUoO9jp5YWMhydXYL3NkySCg0tUq1XWcR/58JG64WXTX7V4Rk4Ae0paeCuXRMETGqbdIsVbHW5hxJoeHQIaUHIRZHlHVgbmiZVuhP/GOItSBOsGORCeEzIr3GowsCQxSazCkUBeHWBri7xiBwReGbkZY4jM3OoJHHGKBTWGDFsofCk6kjQL/hXqgb1WhXWGBhrwYZhE4Y1DMOCSsJIrEK07A156IU5x9WtSBVDg1U0GhWohKkcsf+dYVgTpXNnfe0iAN/qolcnjAldaHJer9Zzpk7dscXajcOhGuEVXsqYF1Gv7iexb87aOESVBP1JEn1EtJt6MATVGpBUCE4I4hOU3qMsPcpS4IoSeV7CSQYlhU3rMjg8qKOjq3jNmjWcpAlaS20sLbV8c2EenXZOeZmz+gKF60C9AVMVSWJRYYvEGhijAAOeQlhl4kA76qICulKIIScMfNcuMzugNQIVL/VGzbSa7hIA39qFGxhPM63wKQlwMu6i6k0XPpS/4r77K6Z6npAoU0kJlTAmjDDtdvD20BPqcrLdcQShfu4ovRNT+gVbFQf1HmXhkOUOpVcwJ6gPDurajQM6PDIqA0NDZmhokKu1KpwXZEX5PRF/aLQxcs6m7ZUGkSLLC3Q6HZSl80W7wNJSk1vNJrWbi8habSSWkVpCkiRIUgtjKHRAxoqK6Z2Opsv8dFewkTPTHfZKYR6AV0CewQN6fiQN3PGbO/ieb+2twyRhzKJYqBaxVipYOY1Bjhu3oSvyLkE32ZdoIkPoX7gSeenhPUFhkVSHdPXwGhkdXY3a4LCpD9QITLzU6qCZ6d2tvPwiEa6TxPzLj7/6vcd2X/uBUxda/vLCu5eK6AuVas+rDlZMOkiorfYYyQvJOy1pzh3jpcV5zrM2Op0CJmuhmhqkqY0jmKOmhbwhDvChZQMtu4cvB7BUu0GOOig0OaEEODU1xePj4/6bX5p604YNo6cWviNMjpkCkSk0e9ATck9o2RxmUYXrnjgdw3/nw4Tb0gcyr0kGdWB4VCqNEVRqdZNWa0aYcaTZKWWh9W0VvcGVxfVf++aBGz/2sY+tCBsv+/F3PwDgAQB/OTFxVX3T1rUXMrdfYYl/TIHza7XKcKU2yiOVIdRXlarOiS9a1G4ucNGaR6dsg32B1BgkTPAcZrpIl3jVyxJ5xa0ShdKXwsHAPz+8eqkAXz2R6oF0cqVaobJFvpsTdJlofYKsxhax/sgpJe31iXuJAoyF1Nx1Jx4OaG1gSCu1Qa03hk11YNAIGyy1svmlQr4r5L7MwBf+/Zt3ffe4zWUAIDZKYmJigrrkq/Hx8TaAr8fn70999k9PRp69uFPIJRC9PLGVM6sDQ8a5YaSD60RcrmV7nluLRyhrzwJWwYhn9XIYHmuWFZjRYxz4PnsDrKCs+kxp4FNuboEqpv/yL4dKv/CZauouLTpHJNUFVmnBQfqOXqU35KDrPUQRz3aIFXAnKL3ACWCrQ1If2qADQ2tMpT4Am6RotjptMP6JvF5jUvry61//noeXX8/ExITdufMuHRubliervXX7OYAxjI+Pr6C77979N9Wjh4+9WJhfp4pXJ4k5gzgUeqVo+daxA5wtHERqQqRpLZE1oRGmf+qZ9hs8A6jgh+pqOll7avzXv/wGfQZOw7ZPUeo6sWsXT05OLnzif/7J2wuPWxOuJeTaCiQEhD68/syb2NOA4N+8dPHGMOqq8F6VUhles5GH127mpDGCdtu7doGbUZSfB+zVP/+Gd969/BKmpqZ4z549Ojk5qZOTk+4Hg4+goTY33RU8d7XzssvGMwC7Aey+5poP/eei6LxaHL0Fhq8cGFptarUa5jSDdI7BcAmIKgkLmXjuIKM7ByTOPVJJTYm8pLwlA396QmngcnM1Pj7uP/pnH/ilIbv0EZT7nZeW8VoSOJz9EBpKws4s4mgNCdonrhR1IqSmyqvWb0d9eANy4XthzBdY6RPj4++8bZmW8c6dOykK7WnnXAbtnOJoan3/Ht9/Efn0F5n82K3/8u3V1Qqy1WvrQw0LrlMG1gLEComH31lKoMgBJph0NR46mP3eO973d7+rz9BZ9E/D8XNhat5H//T3Preq0X7tUvNRQTgTiaCGQYqEFRCnTr1451AKDBKLpFKHIEXuKwertTWfqQ2NTj+8Hze9+93v7izfJM+U0L6fMMeWnVn02b/7q/W//fufWPXAbK3zUz9x/vCZm6snsRy7vGaKjZVqsomtbBX1atP07rxVrF7sdIpHZ5LP//VfLf7xxMS0m5x80mmh/3YC7NLrt2zZMkLFoU+m3P4xKwUgHWR5pmSNWi0ptUzWAvAFciRAfeg+m1ZvJE6+2BhZu/snfuIdM48jtGfkpn/YDTo9vZO+fzftuxvh6wdawAQD/zob7mkBWLsdu1d96ObkbPnmBSiT88Tlb63y/hcSeUAsbJIebNTMnUazG9KB6j89/2VX3b558+Z2X2hjMXp88kDk306QSrt27aLJyUlMTExgOefzDW+Y9v3TysJQRgLwyf81ZmIpSU9oAXZvcPlIqHd+4JurNhRTnyN1R5O009/X16++4W3/7m0HV/rQMQOMdUP+E05oT3Edl1Pqn/F7+t8uakKZJmZPCwAAAABJRU5ErkJggg==
]========]

local B64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function pureBase64Decode(data)
    data=data:gsub('[^'..B64..'=]','')
    return (data:gsub('.',function(x)
        if x=='=' then return '' end
        local r,f='',(B64:find(x,1,true)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(x)
        if #x~=8 then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local RAW_BYTES
pcall(function()
    if crypt and crypt.base64 and crypt.base64.decode then
        RAW_BYTES=crypt.base64.decode(EMBEDDED_REFERENCE_B64)
    elseif syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then
        RAW_BYTES=syn.crypt.base64.decode(EMBEDDED_REFERENCE_B64)
    end
end)
if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 then
    local ok,v=pcall(pureBase64Decode,EMBEDDED_REFERENCE_B64)
    if ok then RAW_BYTES=v end
end

local function makeCustomAsset()
    if type(RAW_BYTES)~='string' or #RAW_BYTES<1000 or type(writefile)~='function' then return nil end
    local loader=getcustomasset or getsynasset
    if not loader and syn then loader=syn.getcustomasset or syn.getsynasset end
    if type(loader)~='function' then return nil end
    local file='sae_exact_star_reference.png'
    local okWrite=pcall(function() writefile(file,RAW_BYTES) end)
    if not okWrite then return nil end
    local ok,a=pcall(function() return loader(file) end)
    if ok and type(a)=='string' and a~='' then return a end
end
local CUSTOM_ASSET=makeCustomAsset()

local DRAWING_SUPPORTED=false
local function newDrawingImage()
    if not Drawing or type(Drawing.new)~='function' or type(RAW_BYTES)~='string' or #RAW_BYTES<1000 then return nil end
    local ok,img=pcall(function()
        local d=Drawing.new('Image')
        d.Data=RAW_BYTES
        d.Size=Vector2.new(230,195)
        d.Position=Vector2.new(0,0)
        d.Transparency=1
        d.Visible=false
        return d
    end)
    if ok and img then return img end
end

do
    local test=newDrawingImage()
    if test then
        DRAWING_SUPPORTED=true
        pcall(function() test.Visible=false test:Remove() end)
    end
end

local function cleanClone(src)
    local c=src:Clone()
    local model
    if c:IsA('Model') then
        model=c
    elseif c:IsA('Tool') then
        model=Instance.new('Model')
        model.Name='Star'
        for _,ch in ipairs(c:GetChildren()) do ch.Parent=model end
        c:Destroy()
    elseif c:IsA('BasePart') then
        model=Instance.new('Model')
        model.Name='Star'
        c.Parent=model
    else
        c:Destroy()
        return nil
    end
    local parts={}
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA('Script') or d:IsA('LocalScript') or d:IsA('ModuleScript') or d:IsA('Humanoid')
            or d:IsA('BillboardGui') or d:IsA('SurfaceGui') or d:IsA('ProximityPrompt') or d:IsA('ClickDetector') then
            pcall(function() d:Destroy() end)
        elseif d:IsA('BasePart') then
            d.Anchored=false
            d.CanCollide=false
            d.CanTouch=false
            d.CanQuery=false
            d.Massless=true
            parts[#parts+1]=d
        end
    end
    if #parts==0 then model:Destroy() return nil end
    model.PrimaryPart=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart',true)
    model.Name='Star'
    return model
end

local function norm(s)
    return tostring(s or ''):lower():gsub('[^%w]','')
end

local function nativeScore(x)
    if not (x:IsA('Model') or x:IsA('Tool') or x:IsA('MeshPart') or x:IsA('Part')) then return -math.huge end
    if x:IsDescendantOf(P) then return -math.huge end
    if x:GetAttribute('SAE_V7_TOOL') or x:GetAttribute('SAE_EXACT_STAR_OVERLAY') then return -math.huge end
    local n=norm(x.Name)
    if n~='star' and n~='staritem' and n~='heldstar' and n~='goldstar' then return -math.huge end
    local ancestry=norm(x.Parent and x.Parent.Name)
    if ancestry:find('egg',1,true) or ancestry:find('gui',1,true) or ancestry:find('icon',1,true) then return -math.huge end
    local score=(n=='star' and 100 or 60)
    if x:IsA('MeshPart') then score=score+90 end
    local meshCount=0
    local partCount=0
    for _,d in ipairs(x:GetDescendants()) do
        if d:IsA('MeshPart') then meshCount=meshCount+1 end
        if d:IsA('BasePart') then partCount=partCount+1 end
    end
    score=score+math.min(meshCount,12)*18+math.min(partCount,30)
    if x:IsDescendantOf(RS) then score=score+50 end
    return score
end

local function findNativeStar()
    local best,bestScore=nil,-math.huge
    local function consider(x)
        local sc=nativeScore(x)
        if sc>bestScore then best,bestScore=x,sc end
    end
    for _,root in ipairs({RS,Lighting,StarterPack,workspace}) do
        consider(root)
        for _,x in ipairs(root:GetDescendants()) do consider(x) end
    end
    if type(getinstances)=='function' then
        local ok,list=pcall(getinstances)
        if ok and type(list)=='table' then
            for _,x in ipairs(list) do if typeof(x)=='Instance' then consider(x) end end
        end
    end
    if type(getnilinstances)=='function' then
        local ok,list=pcall(getnilinstances)
        if ok and type(list)=='table' then
            for _,x in ipairs(list) do if typeof(x)=='Instance' then consider(x) end end
        end
    end
    if best and bestScore>=100 then
        local ok,c=pcall(cleanClone,best)
        if ok then return c end
    end
end

-- The supplied Star reference is authoritative. Never substitute another in-game Star.
local NATIVE_TEMPLATE=nil

local function fitModel(model,target)
    local ok,sz=pcall(function() return model:GetExtentsSize() end)
    if not ok or not sz then return end
    local mx=math.max(sz.X,sz.Y,sz.Z)
    if mx>.01 then pcall(function() model:ScaleTo(target/mx) end) end
end

local busy={}
local live={}

local function destroyOverlay(tool)
    local st=live[tool]
    if not st then return end
    if st.conn then pcall(function() st.conn:Disconnect() end) end
    if st.gui and st.gui.Parent then pcall(function() st.gui:Destroy() end) end
    if st.drawing then pcall(function() st.drawing.Visible=false st.drawing:Remove() end) end
    live[tool]=nil
end

local function handScreenGeometry(char)
    local cam=workspace.CurrentCamera
    local hand=char and (char:FindFirstChild('RightHand') or char:FindFirstChild('Right Arm'))
    local hrp=char and char:FindFirstChild('HumanoidRootPart')
    if not cam or not hand or not hrp then return nil end

    -- Reference: the hand grips the lower-left/centre of the Star and the Star sits beside the face.
    local gripWorld=hand.Position + hrp.CFrame.UpVector*.62 + hrp.CFrame.LookVector*.10
    local p,on=cam:WorldToViewportPoint(gripWorld)
    if not on or p.Z<=0 then return nil end

    local top=cam:WorldToViewportPoint(gripWorld+hrp.CFrame.UpVector*2.55)
    local h=math.clamp(math.abs(top.Y-p.Y),135,230)
    local w=h*(112/95)
    return p,w,h
end

local function startOverlay(tool)
    destroyOverlay(tool)

    local gui,img,drawing
    local imageSource=(tool.TextureId and tool.TextureId~='') and tool.TextureId or CUSTOM_ASSET
    if (not imageSource or imageSource=='') and tool.TextureId and tool.TextureId~='' then
        imageSource=tool.TextureId
    end
    if imageSource then
        gui=Instance.new('ScreenGui')
        gui.Name='SAE_HELD_STAR'
        gui.ResetOnSpawn=false
        gui.IgnoreGuiInset=true
        gui.DisplayOrder=1000000
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.Parent=PG

        img=Instance.new('ImageLabel')
        img.Name='Star'
        img.BackgroundTransparency=1
        img.AnchorPoint=Vector2.new(.34,.79)
        img.Image=imageSource
        img.ScaleType=Enum.ScaleType.Fit
        img.ResampleMode=Enum.ResamplerMode.Default
        img.ClipsDescendants=false
        img.ZIndex=100
        img.Parent=gui
    elseif DRAWING_SUPPORTED then
        drawing=newDrawingImage()
        if not drawing then return false end
    else
        return false
    end

    local st={gui=gui,img=img,drawing=drawing,conn=nil}
    live[tool]=st
    st.conn=RunService.RenderStepped:Connect(function()
        if not tool.Parent or tool.Parent~=P.Character then destroyOverlay(tool) return end
        local g,w,h=handScreenGeometry(P.Character)
        if not g then
            if img then img.Visible=false end
            if drawing then drawing.Visible=false end
            return
        end
        local t=os.clock()
        local pulse=1+math.sin(t*2.0)*.01
        w=w*pulse
        h=h*pulse
        local rot=-2.5+math.sin(t*1.6)*.55

        if img then
            img.Size=UDim2.fromOffset(math.floor(w),math.floor(h))
            img.Position=UDim2.fromOffset(g.X,g.Y)
            img.Rotation=rot
            img.Visible=true
        elseif drawing then
            -- Drawing images cannot rotate, but use the exact supplied pixels and track the hand.
            drawing.Size=Vector2.new(w,h)
            drawing.Position=Vector2.new(g.X-w*.34,g.Y-h*.79)
            drawing.Transparency=1
            drawing.Visible=true
        end
    end)
    return true
end

local function attachNative(new,handle)
    if not NATIVE_TEMPLATE then return false end
    local model=NATIVE_TEMPLATE:Clone()
    fitModel(model,4.35)
    model.Parent=new
    local root=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart',true)
    if not root then model:Destroy() return false end
    model.PrimaryPart=root
    model:PivotTo(handle.CFrame*CFrame.new(-.55,.92,-.12)*CFrame.Angles(0,math.rad(180),math.rad(-3)))
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA('BasePart') then
            d.Anchored=false d.CanCollide=false d.CanTouch=false d.CanQuery=false d.Massless=true
            if d~=root then
                local w=Instance.new('WeldConstraint')
                w.Part0=root w.Part1=d w.Parent=root
            end
        end
    end
    local hw=Instance.new('WeldConstraint')
    hw.Part0=handle hw.Part1=root hw.Parent=handle
    return true
end

local function replace(tool)
    if not tool or not tool:IsA('Tool') or tool.Name~='Star' or tool:GetAttribute('SAE_EXACT_STAR_OVERLAY') or busy[tool] then return end

    -- Never replace a visible existing Star with an invisible tool if this executor cannot render the supplied reference.
    local hasToolImage=tool.TextureId and tool.TextureId~=''
    if not NATIVE_TEMPLATE and not CUSTOM_ASSET and not DRAWING_SUPPORTED and not hasToolImage then
        warn('[SAE] Star renderer unavailable; keeping existing Star tool instead of making it invisible.')
        return
    end

    busy[tool]=true
    task.defer(function()
        if not tool.Parent then busy[tool]=nil return end
        local parent=tool.Parent
        local new=Instance.new('Tool')
        new.Name='Star'
        new.RequiresHandle=true
        new.CanBeDropped=false
        new.TextureId=tool.TextureId or ''
        new.Grip=CFrame.new()
        new:SetAttribute('SAE_V7_TOOL',true)
        new:SetAttribute('SAE_EXACT_STAR_OVERLAY',true)

        local h=Instance.new('Part')
        h.Name='Handle'
        h.Size=Vector3.new(.35,.35,.35)
        h.Transparency=1
        h.CanCollide=false h.CanTouch=false h.CanQuery=false h.Massless=true
        h.Parent=new

        local usingNative=attachNative(new,h)
        if not usingNative then
            new.Equipped:Connect(function()
                task.defer(function()
                    if not startOverlay(new) then
                        warn('[SAE] Star reference could not be rendered by this executor.')
                    end
                end)
            end)
            new.Unequipped:Connect(function() destroyOverlay(new) end)
            new.AncestryChanged:Connect(function(_,par) if not par then destroyOverlay(new) end end)
        end

        tool:Destroy()
        new.Parent=parent
        busy[tool]=nil
    end)
end

local function watch(c)
    if not c then return end
    c.ChildAdded:Connect(function(x)
        if x:IsA('Tool') and x.Name=='Star' then task.wait() replace(x) end
    end)
    for _,x in ipairs(c:GetChildren()) do
        if x:IsA('Tool') and x.Name=='Star' then replace(x) end
    end
end
watch(BP)
watch(P.Character)
P.CharacterAdded:Connect(function(c) task.wait(.2) watch(c) end)
]============]

local FINAL_POLISH_SOURCE=[============[
-- Final polish layer for Steal An Egg.
-- Keeps approved pet visuals untouched while improving grounding/walking,
-- equipped breathing, 15-stud roaming, and egg scale.

local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local P=Players.LocalPlayer
if not P then return end
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not BP then return end

local PETS={
    ['Unicorn']=true,['Kitsune']=true,['Night Flame']=true,['Archangel']=true,
    ['World Burner']=true,['Aetheron']=true,['Cthulhu']=true,
    ['Luminous Cthulhu']=true,['Sabertooth']=true,['Skeletal Sabertooth']=true,
    ['Octophant']=true,['Mecha Scrambler']=true
}

local function firstModel(tool)
    if not tool then return nil end
    for _,child in ipairs(tool:GetChildren()) do
        if child:IsA('Model') then return child end
    end
    return tool:FindFirstChildWhichIsA('Model',true)
end

local function enlargeEggTool(tool)
    if not tool or not tool:IsA('Tool') then return end
    if tool:GetAttribute('SAE_FINAL_EGG_ENLARGED') then return end
    if not tostring(tool.Name):lower():find('egg',1,true) then return end
    task.defer(function()
        task.wait(.05)
        if not tool.Parent or tool:GetAttribute('SAE_FINAL_EGG_ENLARGED') then return end
        local model=firstModel(tool)
        if not model then return end
        local ok,scale=pcall(function() return model:GetScale() end)
        if not ok or not scale then scale=1 end
        pcall(function() model:ScaleTo(scale*1.35) end)
        tool:SetAttribute('SAE_FINAL_EGG_ENLARGED',true)
    end)
end

local equipped={}
local function registerPetTool(tool)
    if not tool or not tool:IsA('Tool') or not PETS[tool.Name] or equipped[tool] then return end
    task.defer(function()
        task.wait(.06)
        if not tool.Parent or equipped[tool] then return end
        local model=firstModel(tool)
        if not model then return end
        local ok,base=pcall(function() return model:GetScale() end)
        if not ok or not base then base=1 end
        equipped[tool]={model=model,base=base,phase=math.random()*math.pi*2,last=base}
    end)
end

local function watchTools(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') then
            task.wait()
            enlargeEggTool(child)
            registerPetTool(child)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') then
            enlargeEggTool(child)
            registerPetTool(child)
        end
    end
end

watchTools(BP)
watchTools(P.Character)
P.CharacterAdded:Connect(function(char) task.wait(.2); watchTools(char) end)

local placed={}
local MAX_RADIUS=15

local function chooseTarget(state,now)
    local a=math.random()*math.pi*2
    local r=math.sqrt(math.random())*(MAX_RADIUS-.5)
    state.target=Vector3.new(state.home.X+math.cos(a)*r,0,state.home.Z+math.sin(a)*r)
    state.pauseUntil=now
end

local function groundAt(model,x,z,yHint)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local exclude={model}
    if P.Character then exclude[#exclude+1]=P.Character end
    params.FilterDescendantsInstances=exclude
    return workspace:Raycast(Vector3.new(x,yHint+65,z),Vector3.new(0,-180,0),params)
end

local function registerPlaced(model)
    if not model or not model:IsA('Model') or not PETS[model.Name] then return end
    if placed[model] or model:GetAttribute('SAE_FINAL_PET_MOTION') then return end
    if not model:FindFirstChildWhichIsA('BasePart',true) then return end

    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') then
            part.Anchored=true
            part.CanCollide=false
            part.CanTouch=false
        end
    end

    local pivot=model:GetPivot()
    local ok,base=pcall(function() return model:GetScale() end)
    if not ok or not base then base=1 end

    local state={
        home=pivot.Position,
        pos=Vector3.new(pivot.Position.X,0,pivot.Position.Z),
        target=Vector3.new(pivot.Position.X,0,pivot.Position.Z),
        velocity=Vector3.zero,
        look=Vector3.new(pivot.LookVector.X,0,pivot.LookVector.Z),
        baseScale=base,
        phase=math.random()*math.pi*2,
        pauseUntil=os.clock()+math.random()*1.4,
        speed=2.25+math.random()*.55
    }
    if state.look.Magnitude<.05 then state.look=Vector3.new(0,0,-1) else state.look=state.look.Unit end
    chooseTarget(state,state.pauseUntil)
    model:SetAttribute('SAE_FINAL_PET_MOTION',true)
    placed[model]=state
end

local function watchPlaced(folder)
    if not folder or not folder:IsA('Folder') or folder.Name~='SAE_V7_PLACED' then return end
    for _,child in ipairs(folder:GetChildren()) do
        if child:IsA('Model') then registerPlaced(child) end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA('Model') then task.wait(.08); registerPlaced(child) end
    end)
end

local current=workspace:FindFirstChild('SAE_V7_PLACED')
if current then watchPlaced(current) end
workspace.ChildAdded:Connect(function(child)
    if child:IsA('Folder') and child.Name=='SAE_V7_PLACED' then task.wait(); watchPlaced(child) end
end)

RunService.Heartbeat:Connect(function(dt)
    local now=os.clock()

    -- Same subtle breathing while equipped, without changing approved pet geometry.
    for tool,state in pairs(equipped) do
        if not tool.Parent or not state.model.Parent then
            equipped[tool]=nil
        else
            local desired=state.base
            if tool.Parent==P.Character then
                desired=state.base*(1+.008*math.sin(now*2.15+state.phase))
            end
            if math.abs(desired-state.last)>.00015 then
                pcall(function() state.model:ScaleTo(desired) end)
                state.last=desired
            end
        end
    end

    for model,state in pairs(placed) do
        if not model.Parent then
            placed[model]=nil
        else
            local delta=state.target-state.pos
            delta=Vector3.new(delta.X,0,delta.Z)
            local distance=delta.Magnitude

            if now>=state.pauseUntil then
                if distance<.25 then
                    state.velocity=Vector3.zero
                    state.pauseUntil=now+1+math.random()*1.35
                    chooseTarget(state,state.pauseUntil)
                else
                    local dir=delta.Unit
                    local desired=dir*state.speed
                    state.velocity=state.velocity:Lerp(desired,1-math.exp(-5.5*dt))
                    state.pos=state.pos+state.velocity*dt

                    local fromHome=Vector3.new(state.pos.X-state.home.X,0,state.pos.Z-state.home.Z)
                    if fromHome.Magnitude>MAX_RADIUS then
                        fromHome=fromHome.Unit*MAX_RADIUS
                        state.pos=Vector3.new(state.home.X+fromHome.X,0,state.home.Z+fromHome.Z)
                    end
                    if state.velocity.Magnitude>.08 then state.look=state.velocity.Unit end
                end
            else
                state.velocity=state.velocity:Lerp(Vector3.zero,1-math.exp(-8*dt))
            end

            pcall(function()
                model:ScaleTo(state.baseScale*(1+.005*math.sin(now*2+state.phase)))
            end)

            local hit=groundAt(model,state.pos.X,state.pos.Z,state.home.Y)
            if hit then
                local look=state.look
                if look.Magnitude<.05 then look=Vector3.new(0,0,-1) end
                look=Vector3.new(look.X,0,look.Z).Unit

                local walkAmount=math.clamp(state.velocity.Magnitude/math.max(state.speed,.01),0,1)
                local sway=math.rad(1.25)*math.sin(now*7.5+state.phase)*walkAmount
                local lean=math.rad(-1.4)*walkAmount
                local basePos=Vector3.new(state.pos.X,hit.Position.Y,state.pos.Z)
                local cf=CFrame.lookAt(basePos,basePos+look,Vector3.yAxis)*CFrame.Angles(lean,0,sway)
                model:PivotTo(cf)

                -- Re-ground after scale/tilt so feet stay on the floor instead of floating.
                local box,size=model:GetBoundingBox()
                local bottom=box.Position.Y-size.Y/2
                model:PivotTo(model:GetPivot()+Vector3.new(0,hit.Position.Y-bottom+.025,0))
            end
        end
    end
end)

print('[SAE] Final polish ready: grounded natural pet walking, equipped breathing, 15-stud roaming, larger eggs.')

]============]

local CONTROL_PANEL_SOURCE=[============[
-- Steal An Egg - Combined Main (Control Panel + V7 3D Inventory)
-- All functionality in one file. No external loads.

Players = game:GetService("Players")
ReplicatedStorage = game:GetService("ReplicatedStorage")
TweenService = game:GetService("TweenService")
TextService = game:GetService("TextService")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")

P = Players.LocalPlayer
if not P then return end
PG = P:FindFirstChildOfClass("PlayerGui") or P:WaitForChild("PlayerGui",10)
if not PG then return end

function arrlen(t)
    local n=0
    for _ in ipairs(t) do n=n+1 end
    return n
end

for _,guiName in ipairs({"SAE_BOOT_V9","SAE_BOOT_V8","SAE_BOOT_V7","SAE_BOOT_V6","SAE_BOOT_V5","SAE_FINAL_V9","SAE_FINAL_V8","SAE_FINAL_V7","SAE_FINAL_V6","SAE_FINAL_V5","SAE_GIFTING_PANEL"}) do
    local old = PG:FindFirstChild(guiName)
    if old then old:Destroy() end
end
for _,n in ipairs({"SAE_LocalEggs","SAE_LocalNPCs","SAE_SafeZoneMarker"}) do
    local x = workspace:FindFirstChild(n)
    if x then x:Destroy() end
end
-- Earlier versions placed the morph under CurrentCamera. Remove every stale
-- display rig and undo the local invisibility they left on the real character.
hadStaleMorph=false
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

CFG = {
    AnnouncementProfile = {Name=P.DisplayName, Username=P.Name, UserId=P.UserId},
    Remotes = {
        Morph=nil, Announcement=nil, GiveVPS=nil,
        GiveTreadmill=nil, GiveEggs=nil, GivePets=nil, GiveStars=nil, GiveEverything=nil,
        Boost=nil, ClearBoost=nil, Meteor=nil
    }
}

EGGS = {
    "MIXED","Skeleton Horse","World Burner","Equinox egg","Aetheron egg",
    "Gorilla King egg","Nightflame egg","Eternal Lunar Dragon egg","Unicorn egg",
    "Nibbles #013 Egg","Experiment #001 Egg","Scorched Dragon egg","Drilla egg",
    "Void Dragon egg","Rifborn egg","Riftbeasts egg","Shattered Rift egg",
    "Pegasus","ArchAngel","Oni Tiger egg","Kitsune egg"
}
PATTERNS = {"ORIGINAL 6x20","ONE TYPE PER ROW","SPLIT ROWS 3+3","PAIRS 2+2+2","MIRRORED ROWS","ALTERNATING ROWS","DIAGONAL SEQUENCE"}
ALIAS = {
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

C = {
    bg=Color3.fromRGB(8,8,14), head=Color3.fromRGB(15,11,23), card=Color3.fromRGB(24,18,34),
    card2=Color3.fromRGB(37,25,50), border=Color3.fromRGB(84,57,110), purple=Color3.fromRGB(142,51,236),
    purple2=Color3.fromRGB(184,83,255), white=Color3.fromRGB(255,255,255), muted=Color3.fromRGB(168,162,181),
    green=Color3.fromRGB(105,245,135), orange=Color3.fromRGB(255,188,82), red=Color3.fromRGB(255,60,60), blue=Color3.fromRGB(45,145,255)
}

EggFolder=Instance.new("Folder"); EggFolder.Name="SAE_LocalEggs"; EggFolder.Parent=workspace

function corner(o,r) local x=Instance.new("UICorner"); x.CornerRadius=UDim.new(0,r or 8); x.Parent=o; return x end
function stroke(o,a) local x=Instance.new("UIStroke"); x.Color=C.border; x.Thickness=1; x.Transparency=a or .2; x.Parent=o; return x end
function grad(o) local x=Instance.new("UIGradient"); x.Color=ColorSequence.new(Color3.fromRGB(110,35,205),Color3.fromRGB(177,69,253)); x.Rotation=15; x.Parent=o end
function label(par,t,p,s,z) local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Position=p; x.Size=s; x.Text=t or ""; x.TextColor3=C.white; x.Font=Enum.Font.GothamMedium; x.TextSize=z or 11; x.TextXAlignment=Enum.TextXAlignment.Left; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=par; return x end
function button(par,t,p,s,dark)
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
function textbox(par,ph,p,s,txt) local x=Instance.new("TextBox"); x.Position=p; x.Size=s; x.BackgroundColor3=C.card2; x.BorderSizePixel=0; x.Text=txt or ""; x.PlaceholderText=ph or ""; x.PlaceholderColor3=C.muted; x.TextColor3=C.white; x.Font=Enum.Font.GothamMedium; x.TextSize=11; x.ClearTextOnFocus=false; x.Parent=par; corner(x,8); stroke(x,.45); return x end
function card(par,p,s) local x=Instance.new("Frame"); x.Position=p; x.Size=s; x.BackgroundColor3=C.card; x.BorderSizePixel=0; x.Parent=par; corner(x,10); stroke(x,.55); return x end
function section(par,t,y) local x=label(par,t,UDim2.fromOffset(8,y),UDim2.new(1,-16,0,17),9); x.TextColor3=C.muted; x.Font=Enum.Font.GothamBold; return x end
function drag(handle,win)
    local on=false; local start; local pos
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=true; start=i.Position; pos=win.Position end end)
    UserInputService.InputChanged:Connect(function(i) if on and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-start; win.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=false end end)
end

-- User-approved Roblox verified glyph. Do not change.
VERIFIED=utf8.char(0xE000)
function verified(par,size)
    local h=Instance.new("Frame"); h.BackgroundTransparency=1; h.Size=UDim2.fromOffset(size+2,size+4); h.Parent=par
    local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Size=UDim2.fromScale(1,1); x.Position=UDim2.fromOffset(0,1); x.Text=VERIFIED; x.Font=Enum.Font.GothamBold; x.TextSize=size; x.TextColor3=C.white; x.TextXAlignment=Enum.TextXAlignment.Center; x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=h
    return h
end

function remote(path)
    if type(path)~="table" then return nil end
    local x=ReplicatedStorage
    for _,n in ipairs(path) do x=x:FindFirstChild(n); if not x then return nil end end
    if x:IsA("RemoteEvent") or x:IsA("RemoteFunction") then return x end
end
function callRemote(key,...)
    local r=remote(CFG.Remotes[key]); if not r then return false end
    local a={...}
    return pcall(function() if r:IsA("RemoteEvent") then r:FireServer(table.unpack(a)) else r:InvokeServer(table.unpack(a)) end end)
end

Gui=Instance.new("ScreenGui"); Gui.Name="SAE_FINAL_V9"; Gui.ResetOnSpawn=false; Gui.IgnoreGuiInset=false; Gui.DisplayOrder=700; Gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; Gui.Parent=PG

function window(name,title,sub,w,h,pos)
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
Main=window("MainPanel","DEVELOPER CONTROL PANEL","Main control panel",344,118,UDim2.new(.22,0,.52,0))
Main.BackgroundTransparency=.12
Morph=window("MorphPanel","Avatar Morpher","Change your avatar's look",350,360,UDim2.new(.74,0,.28,0))
Morph.BackgroundTransparency=Main.BackgroundTransparency
MorphColorsPage=window("MorphColorsPanel","OVERHEAD TEXT COLORS","Choose a text color",350,250,UDim2.new(.74,0,.36,0))
MorphColorsPage.BackgroundTransparency=Main.BackgroundTransparency
MorphColorsPage.Visible=false
MorphColorsPage:GetPropertyChangedSignal("Visible"):Connect(function()
    if not MorphColorsPage.Visible then Morph.Visible=true end
end)
Console=window("ConsolePanel","SERVER CONSOLE","TAB opens or closes this window",690,380,UDim2.new(.5,0,.5,0)); Console.Visible=false

-- Remove any overlay left by older versions.
oldSnow=PG:FindFirstChild("SAE_SnowOverlay")
if oldSnow then oldSnow:Destroy() end

-- Permanent launchers so closed panels never disappear permanently.
Launch=Instance.new("Frame"); Launch.Position=UDim2.new(0,12,.5,-170); Launch.Size=UDim2.fromOffset(106,70); Launch.BackgroundTransparency=1; Launch.Parent=Gui
LL=Instance.new("UIListLayout"); LL.Padding=UDim.new(0,7); LL.Parent=Launch
bAdmin=button(Launch,"ADMIN",UDim2.new(),UDim2.fromOffset(102,29),false)
bMorph=button(Launch,"MORPH",UDim2.new(),UDim2.fromOffset(102,29),true)
bAdmin.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)
bMorph.MouseButton1Click:Connect(function()
    if MorphColorsPage.Visible then
        MorphColorsPage.Visible=false
        Morph.Visible=true
    else
        Morph.Visible=not Morph.Visible
    end
end)
-- Centered announcement layer.
Notify=Instance.new("Frame"); Notify.BackgroundTransparency=1; Notify.Size=UDim2.fromScale(1,1); Notify.Parent=Gui
function nt(par,t,col,z,font) local x=label(par,t,UDim2.new(),UDim2.fromOffset(0,46),z); x.AutomaticSize=Enum.AutomaticSize.X; x.Font=font or Enum.Font.GothamBlack; x.TextColor3=col; x.TextStrokeTransparency=0; x.TextStrokeColor3=Color3.new(0,0,0); return x end
local noticeStack=Instance.new("Frame")
noticeStack.Name="AnnouncementStack"
noticeStack.BackgroundTransparency=1
noticeStack.Position=UDim2.fromOffset(0,7)
noticeStack.Size=UDim2.new(1,0,1,-14)
noticeStack.Parent=Notify
local noticeLayout=Instance.new("UIListLayout")
noticeLayout.FillDirection=Enum.FillDirection.Vertical
noticeLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
noticeLayout.VerticalAlignment=Enum.VerticalAlignment.Top
noticeLayout.SortOrder=Enum.SortOrder.LayoutOrder
noticeLayout.Padding=UDim.new(0,5)
noticeLayout.Parent=noticeStack
local noticeSerial=0
function notice(uid,sender,before,red,after,font)
    noticeSerial+=1
    local row=Instance.new("CanvasGroup")
    row.Name="Announcement"..noticeSerial
    row.BackgroundTransparency=1
    row.AutomaticSize=Enum.AutomaticSize.X
    row.Size=UDim2.fromOffset(0,50)
    row.LayoutOrder=noticeSerial
    row.GroupTransparency=1
    row.Parent=noticeStack
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Horizontal
    layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
    layout.VerticalAlignment=Enum.VerticalAlignment.Center
    layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,4)
    layout.Parent=row
    local avatar=Instance.new("ImageLabel")
    avatar.BackgroundTransparency=1
    avatar.Size=UDim2.fromOffset(40,40)
    avatar.Image="rbxthumb://type=AvatarHeadShot&id="..tostring(uid or P.UserId).."&w=150&h=150"
    avatar.LayoutOrder=1
    avatar.Parent=row
    local order=2
    local function text(value,color)
        if not value or value=="" then return end
        local caption=nt(row,value,color,29,font)
        caption.LayoutOrder=order
        order+=1
    end
    text(sender,C.blue)
    local badge=verified(row,26)
    badge.LayoutOrder=order
    order+=1
    text(before,C.white)
    text(red,C.red)
    text(after,C.white)
    -- Layout positions each live message below the previous one. Fade only:
    -- competing Position tweens cannot pull multiple announcements onto one line.
    TweenService:Create(row,TweenInfo.new(.15),{GroupTransparency=0}):Play()
    task.delay(4,function()
        if not row.Parent then return end
        local fade=TweenService:Create(row,TweenInfo.new(.2),{GroupTransparency=1})
        fade:Play()
        fade.Completed:Wait()
        if row.Parent then row:Destroy() end
    end)
end

function norm(s) return string.lower(tostring(s or "")):gsub("[^%w]","") end
function rootOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o end
    if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChild("HumanoidRootPart",true) or o:FindFirstChildWhichIsA("BasePart",true) end
end
function pivot(o,cf) if o:IsA("Model") then o:PivotTo(cf) elseif o:IsA("BasePart") then o.CFrame=cf end end

function groundHit(pos,ignore)
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,250,0),Vector3.new(0,-1000,0),rp)
end

function groundHitNear(pos,ignore)
    -- Short raycast around the active character height. This avoids choosing
    -- roofs/ceilings that a 250-stud-above ray can hit first.
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude
    local ex={EggFolder}; if P.Character then table.insert(ex,P.Character) end; if ignore then table.insert(ex,ignore) end; rp.FilterDescendantsInstances=ex
    return workspace:Raycast(pos+Vector3.new(0,10,0),Vector3.new(0,-80,0),rp)
end
function groundObject(o,pos,yaw)
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

function createAvatar(uid)
    local m
    local ok=pcall(function() m=Players:CreateHumanoidModelFromUserIdAsync(uid) end)
    if ok and m then return m end
    local d=Players:GetHumanoidDescriptionFromUserId(uid)
    return Players:CreateHumanoidModelFromDescription(d,Enum.HumanoidRigType.R15)
end
-- Egg resolver. Games often store egg visuals inside nested Models, Tools or Folders,
-- so resolve the matching visual instead of requiring the named object itself to be a Model.
EggCache={}

function eggTextMatches(value,want)
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

function matchObj(o,want)
    if eggTextMatches(o.Name,want) then return true end
    for _,a in ipairs({"EggName","DisplayName","ItemName","Title","Type","PetName","Name"}) do
        local v=o:GetAttribute(a)
        if v~=nil and eggTextMatches(v,want) then return true end
    end
    if o:IsA("StringValue") and eggTextMatches(o.Value,want) then return true end
    return false
end

function usableEggSource(o,container)
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

function findEgg(name)
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
EggTemplateCache={}

function stripEggTemplate(o)
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

function templateInfo(name)
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

function availableEggs()
    local a={}
    for i=2,arrlen(EGGS) do
        local name=EGGS[i]
        if templateInfo(name) then table.insert(a,name) end
    end
    return a
end

-- Safe-zone state is declared before map/layout code so GENERAL egg spawning
-- can always reserve a no-spawn band around the Safe Zone.
SafeObj=nil
SafePos=nil
SafeName="Not locked"
detectSafe=nil

-- Map-center detection. General egg spawning is anchored to the map frame.
MapFloor=nil
MapCF=nil
MapSize=nil
MapName="Not detected"
MapMarker=nil

function updateMapMarker()
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

function reservedZoneName(value)
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

function floorCandidateScore(o)
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

function detectMapCenter()
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

function setMapCenterHere()
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

function getMapFrame()
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

COMPACT_SPAWN_BOUNDS=Vector3.new(155,1,250)

function safeClearanceRadius()
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

function playableGroundHit(pos,referenceY)
    local hit=groundHitNear(pos,nil)
    if not hit then return nil end
    if referenceY and math.abs(hit.Position.Y-referenceY)>16 then return nil end
    return hit
end

function findPlayableSpawnFrame()
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
local consoleJoinLabel
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
    -- Let the rendered font determine the name width so the badge hugs its edge.
    local b=label(nameRow,Display,UDim2.new(),UDim2.fromOffset(0,22),18)
    b.LayoutOrder=1
    b.Font=Enum.Font.GothamBold
    b.AutomaticSize=Enum.AutomaticSize.X
    b.TextXAlignment=Enum.TextXAlignment.Right
    b.TextYAlignment=Enum.TextYAlignment.Center
    b.TextWrapped=false
    b.TextTruncate=Enum.TextTruncate.AtEnd
    b.TextStrokeTransparency=.1
    local nameLimit=Instance.new("UISizeConstraint")
    nameLimit.MaxSize=Vector2.new(205,22)
    nameLimit.Parent=b
    local badge=verified(nameRow,18)
    badge.LayoutOrder=2
    badge.Size=UDim2.fromOffset(20,22)
    local mark=badge:FindFirstChildOfClass("TextLabel")
    if mark then mark.Position=UDim2.fromOffset(0,0) end

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
local function isHeldToolDescendant(o,ch)
    local ancestor=o
    while ancestor and ancestor~=ch do
        if ancestor:IsA("Tool") then return true end
        ancestor=ancestor.Parent
    end
    return false
end
local function keepHidden(o,ch)
    -- Tools are parented to the character when equipped. Keep their handles,
    -- decals, and textures visible while hiding the avatar underneath.
    if isHeldToolDescendant(o,ch) then return end
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
    for _,o in ipairs(ch:GetDescendants()) do keepHidden(o,ch) end
    MorphDescConn=ch.DescendantAdded:Connect(function(o)
        if not MorphShell or P.Character~=ch then return end
        keepHidden(o,ch)
        for _,child in ipairs(o:GetDescendants()) do keepHidden(child,ch) end
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
        Home=118,
        Announcements=312, Preset=336,
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
        showAdminPage(item[2],true)
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
section(AnnouncePage,"ANNOUNCEMENTS",4)
local annBox=textbox(AnnouncePage,"Type your announcement...",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,42),"")
local annSend=button(AnnouncePage,"Send announcement",UDim2.fromOffset(5,78),UDim2.new(1,-10,0,34),false)
local presetMenu=button(AnnouncePage,"Preset",UDim2.fromOffset(5,120),UDim2.new(1,-10,0,34),true)
local annStatus=label(AnnouncePage,"Uses the name and picture saved in Names.",UDim2.fromOffset(7,162),UDim2.new(1,-14,0,32),11)
annStatus.TextWrapped=true
annStatus.TextColor3=C.muted

local presetPage=newAdminPage("Preset",false)
section(presetPage,"PRESET",4)
local presetInput=textbox(presetPage,"Type a preset and press Enter",UDim2.fromOffset(5,28),UDim2.new(1,-10,0,36),"")
local presetList=Instance.new("ScrollingFrame")
presetList.Name="SavedPresets"
presetList.Position=UDim2.fromOffset(5,76)
presetList.Size=UDim2.new(1,-10,1,-108)
presetList.BackgroundColor3=C.card
presetList.BorderSizePixel=0
presetList.CanvasSize=UDim2.new()
presetList.AutomaticCanvasSize=Enum.AutomaticSize.Y
presetList.ScrollBarThickness=4
presetList.ScrollBarImageColor3=C.purple
presetList.ScrollingDirection=Enum.ScrollingDirection.Y
presetList.Parent=presetPage
corner(presetList,8)
local listLayout=Instance.new("UIListLayout")
listLayout.SortOrder=Enum.SortOrder.LayoutOrder
listLayout.Padding=UDim.new(0,6)
listLayout.Parent=presetList
local listPadding=Instance.new("UIPadding")
listPadding.PaddingTop=UDim.new(0,6)
listPadding.PaddingBottom=UDim.new(0,6)
listPadding.PaddingLeft=UDim.new(0,6)
listPadding.Parent=presetList
local presetStatus=label(presetPage,"Enter saves. Click a preset to announce it.",UDim2.new(0,7,1,-28),UDim2.new(1,-14,0,26),11)
presetStatus.TextColor3=C.muted
presetStatus.TextWrapped=true

-- Presets are private local data, separated by Roblox account.
local presetEnv=(getgenv and getgenv()) or _G
if type(presetEnv.SAE_ANNOUNCEMENT_PRESETS_BY_USER)~="table" then presetEnv.SAE_ANNOUNCEMENT_PRESETS_BY_USER={} end
local accountKey=tostring(P.UserId)
local presetFile="SAE_AnnouncementPresets_"..accountKey..".json"
local codec=game:GetService("HttpService")
local saved=presetEnv.SAE_ANNOUNCEMENT_PRESETS_BY_USER[accountKey]
if type(saved)~="table" then
    saved={}
    if type(readfile)=="function" then
        local ok,data=pcall(function() return codec:JSONDecode(readfile(presetFile)) end)
        if ok and type(data)=="table" and data.version==1 and type(data.messages)=="table" then
            for _,message in ipairs(data.messages) do
                if type(message)=="string" and message:match("%S") then saved[#saved+1]=message end
            end
        end
    end
    presetEnv.SAE_ANNOUNCEMENT_PRESETS_BY_USER[accountKey]=saved
end
local function persistPresets()
    if type(writefile)~="function" then return false end
    return pcall(function()
        writefile(presetFile,codec:JSONEncode({version=1,messages=saved}))
    end)
end
local function sendAnnouncement(message,targetStatus)
    local msg=(message or annBox.Text):match("^%s*(.-)%s*$")
    local feedback=targetStatus or annStatus
    if msg=="" then
        feedback.Text="Type an announcement first."
        feedback.TextColor3=C.orange
        return
    end
    callRemote("Announcement",msg)
    notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,":","",msg,Enum.Font.FredokaOne)
    feedback.Text="Announcement shown."
    feedback.TextColor3=C.green
end
local function renderPresets()
    for _,child in ipairs(presetList:GetChildren()) do
        if child:IsA("TextButton") or child.Name=="PresetRow" or child.Name=="EmptyPresetHint" then child:Destroy() end
    end
    if #saved==0 then
        local empty=label(presetList,"Your saved announcements appear here.",UDim2.new(),UDim2.new(1,-12,0,42),11)
        empty.Name="EmptyPresetHint"
        empty.TextColor3=C.muted
        empty.TextWrapped=true
        return
    end
    for index,message in ipairs(saved) do
        local presetMessage=message
        local row=Instance.new("Frame")
        row.Name="PresetRow"
        row.Size=UDim2.new(1,-12,0,38)
        row.BackgroundTransparency=1
        row.LayoutOrder=index
        row.Parent=presetList
        local entry=button(row,message,UDim2.new(),UDim2.fromScale(1,1),true)
        entry.Name="AnnouncePreset"
        entry.TextSize=12
        entry.TextWrapped=true
        entry.TextTruncate=Enum.TextTruncate.AtEnd
        entry.MouseButton1Click:Connect(function()
            sendAnnouncement(presetMessage,presetStatus)
        end)
        local remove=button(row,"",UDim2.new(1,-32,0,4),UDim2.fromOffset(30,30),true)
        remove.Name="DeletePreset"
        remove.BackgroundColor3=C.red
        remove:SetAttribute("RestingColor",C.red)
        remove:SetAttribute("HoverColor",C.red:Lerp(C.white,.16))
        -- Draw a compact trash-can symbol without relying on emoji font support.
        local function trashPart(x,y,w,h,color)
            local part=Instance.new("Frame")
            part.Position=UDim2.fromOffset(x,y)
            part.Size=UDim2.fromOffset(w,h)
            part.BackgroundColor3=color or C.white
            part.BorderSizePixel=0
            part.Active=false
            part.Parent=remove
            corner(part,1)
        end
        trashPart(10,11,10,12)
        trashPart(8,8,14,2)
        trashPart(12,5,6,2)
        trashPart(12,13,1,7,C.red)
        trashPart(16,13,1,7,C.red)
        remove.Visible=true
        entry.Size=UDim2.new(1,-38,1,0)
        local deleting=false
        remove.MouseButton1Click:Connect(function()
            if deleting then return end
            deleting=true
            -- Resolve the message again so a stale row cannot delete another preset.
            for savedIndex,savedMessage in ipairs(saved) do
                if savedMessage==presetMessage then
                    table.remove(saved,savedIndex)
                    local persisted=persistPresets()
                    renderPresets()
                    presetStatus.Text=persisted and "Preset deleted." or "Deleted for this session; saved file could not be updated."
                    presetStatus.TextColor3=persisted and C.muted or C.orange
                    return
                end
            end
        end)
    end
end
local function savePreset()
    local message=presetInput.Text:match("^%s*(.-)%s*$")
    if message=="" then
        presetStatus.Text="Type a preset before pressing Enter."
        presetStatus.TextColor3=C.orange
        return
    end
    for _,existing in ipairs(saved) do
        if existing:lower()==message:lower() then
            presetStatus.Text="That preset is already saved."
            presetStatus.TextColor3=C.muted
            return
        end
    end
    saved[#saved+1]=message
    local persisted=persistPresets()
    presetInput.Text=""
    renderPresets()
    presetStatus.Text=persisted and "Preset saved. Click it to announce." or "Saved for this session. Click it to announce."
    presetStatus.TextColor3=C.green
end
annSend.MouseButton1Click:Connect(function() sendAnnouncement() end)
annBox.FocusLost:Connect(function(enter) if enter then sendAnnouncement() end end)
presetMenu.MouseButton1Click:Connect(function() showAdminPage("Preset",true) end)
presetInput.FocusLost:Connect(function(enter) if enter then savePreset() end end)
renderPresets()
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
applyNameBtn.MouseButton1Click:Connect(function() if displayInput.Text~="" then Display=displayInput.Text end; if usernameInput.Text~="" then Username=usernameInput.Text:gsub("^@","") end; applyTag(); if consoleJoinLabel and consoleJoinLabel.Parent then consoleJoinLabel.Text=Display.." has joined the server." end; nameStatus.Text="Custom display updated."; nameStatus.TextColor3=C.green end)

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
    return x
end
OL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    out.CanvasSize=UDim2.fromOffset(0,OL.AbsoluteContentSize.Y+6)
    out.CanvasPosition=Vector2.new(0,math.max(0,OL.AbsoluteContentSize.Y-out.AbsoluteSize.Y+6))
end)

local prompt=Instance.new("Frame")
prompt.Position=UDim2.new(0,12,1,-38); prompt.Size=UDim2.new(1,-24,0,28)
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
local showCommands,chooseItem
local activeCommand=nil
local commandSerial=0
local errorInput=nil
ci:GetPropertyChangedSignal("Text"):Connect(function()
    local prefix=ci.Text:match("^%s*(/%S+)")
    if activeCommand and (not prefix or prefix:lower()~=activeCommand) then
        showCommands()
        return
    end
    if errorInput and ci.Text==errorInput then return end
    errorInput=nil
    ci.TextColor3=consoleText
    promptMark.TextColor3=consoleText
end)

local quick=Instance.new("ScrollingFrame")
quick.Position=UDim2.new(0,12,1,-66); quick.Size=UDim2.new(1,-24,0,22)
quick.BackgroundTransparency=1; quick.BorderSizePixel=0
quick.ScrollingDirection=Enum.ScrollingDirection.X; quick.CanvasSize=UDim2.new()
quick.ScrollBarThickness=2; quick.ScrollBarImageColor3=Color3.fromRGB(90,90,90)
quick.Parent=Console
local QL=Instance.new("UIListLayout")
QL.FillDirection=Enum.FillDirection.Horizontal
QL.SortOrder=Enum.SortOrder.LayoutOrder
QL.Padding=UDim.new(0,4); QL.Parent=quick
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
local shortcuts={
    "/announcements", "/givetreadmill", "/giveeggs", "/givepets", "/givestars", "/giveeverything", "/giveps"
}
local branchItems={
    ["/givepets"]={
        "Mecha Scrambler", "Octophant", "Unicorn", "Kitsune",
        "ArchAngel", "World Burner", "Skeletal Sabertooth"
    },
    ["/giveeggs"]={
        "Mecha Scrambler", "Unicorn", "Kitsune", "Nightflame",
        "ArchAngel", "Luminous Cthulhu", "Skeletal Sabertooth"
    },
    ["/givetreadmill"]={"Ben's Treadmill","Brockodile Treadmill"}
}
local remoteActions={
    ["/givetreadmill"]="GiveTreadmill", ["/giveeggs"]="GiveEggs",
    ["/givepets"]="GivePets", ["/givestars"]="GiveStars", ["/giveeverything"]="GiveEverything"
}
local choiceOrder=0
local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end
local function findPlayer(s)
    s=string.lower(trim(s)):gsub("^@","")
    if s=="" then return nil end
    for _,p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name)==s or string.lower(p.DisplayName)==s then return p end
    end

end
local function resolveRecipient(value,raw)
    value=trim(value):gsub("^@+","")
    local serial=commandSerial
    local inputAtStart=ci.Text
    local player=findPlayer(value)
    if player then return {name=player.Name,display=player.DisplayName,id=player.UserId} end
    local ok,id=false,nil
    local timedOut=false
    if value~="" and value:match("^[%w_]+$") then
        local finished=false
        task.spawn(function()
            ok,id=pcall(function() return Players:GetUserIdFromNameAsync(value) end)
            finished=true
        end)
        local deadline=os.clock()+8
        while not finished do
            if not Console.Parent or serial~=commandSerial or ci.Text~=inputAtStart then return nil end
            if os.clock()>=deadline then timedOut=true; break end
            task.wait(.05)
        end
    end
    -- Discard a lookup if the user has started another command or edited the input.
    if not Console.Parent or serial~=commandSerial or ci.Text~=inputAtStart then return nil end
    if timedOut or not ok or type(id)~="number" or id<=0 then
        errorInput=raw
        ci.Text=raw
        ci.TextColor3=C.red promptMark.TextColor3=C.red
        line(timedOut and "Username check timed out. Try again or clear the command." or "Username not found. Check it and try again.",C.red)
        ci:CaptureFocus()
        ci.CursorPosition=#ci.Text+1
        return nil
    end
    return {name=value,display=value,id=id}
end
local function clearChoices()
    for _,child in ipairs(quick:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    quick.CanvasPosition=Vector2.zero
    quick.Visible=true
    choiceOrder=0
end
local function choice(text,callback)
    local b=q(text)
    choiceOrder+=1
    b.LayoutOrder=choiceOrder
    b.MouseButton1Click:Connect(callback)
end
local function prefill(text)
    activeCommand=(text:match("^(%S+)") or ""):lower()
    commandSerial+=1
    ci.Text=text
    ci:CaptureFocus()
end
local function itemPrefix(cmd,item)
    return cmd..' "'..item..'" '
end
local function recipientChoices(cmd,item)
    clearChoices()
    quick.Visible=false
    local prefix=(cmd=="/givestars" or cmd=="/giveeverything") and (cmd.." ") or itemPrefix(cmd,item)
    prefill(prefix)
end
chooseItem=function(cmd)
    activeCommand=cmd
    commandSerial+=1
    clearChoices()
    ci.Text=cmd.." "
    line(cmd=="/givetreadmill" and "Choose a treadmill below." or "Choose an item below.",consoleMuted)
    for _,name in ipairs(branchItems[cmd]) do
        local item=name
        local caption=cmd=="/giveeggs" and (item.." Egg") or item
        choice(caption,function()
            recipientChoices(cmd,item)
        end)
    end
end
showCommands=function()
    activeCommand=nil
    commandSerial+=1
    errorInput=nil
    ci.Text=""
    ci.TextColor3=consoleText promptMark.TextColor3=consoleText
    clearChoices()
    for _,shortcut in ipairs(shortcuts) do
        local cmd=shortcut
        choice(cmd,function()
            if branchItems[cmd] then chooseItem(cmd)
            elseif cmd=="/givestars" or cmd=="/giveeverything" then recipientChoices(cmd,nil)
            else clearChoices(); quick.Visible=false; prefill(cmd.." ") end
        end)
    end
end
local function canonicalItem(cmd,value)
    for _,item in ipairs(branchItems[cmd] or {}) do
        if item:lower()==value:lower() then return item end
    end
end
local function command(raw)
    raw=trim(raw)
    if raw=="" then return end
    commandSerial+=1
    line("> "..raw,consoleText)
    local cmd,rest=raw:match("^(%S+)%s*(.*)$")
    cmd=string.lower(cmd or "")
    rest=trim(rest)
    if cmd=="/back" or cmd=="/cancel" then showCommands(); return end
    if cmd=="/announcements" or cmd=="/announcement" then
        if rest=="" then line("Enter a message.",C.red); return end
        Console.Visible=false
        callRemote("Announcement",rest)
        notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,":","",rest,Enum.Font.FredokaOne)
        line("Announcement shown.")
        showCommands()
        return
    end
    if cmd=="/giveps" then
        if rest=="" then line("Enter a player.",C.red); return end
        local account=resolveRecipient(rest,raw)
        if not account then return end
        local target=account.display
        Console.Visible=false
        callRemote("GiveVPS",account.name)
        notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,": sent","PRIVATE SERVER","to "..target)
        line("PRIVATE SERVER -> "..target)
        showCommands()
        return
    end
    if not remoteActions[cmd] then
        line("Unknown command. Choose a shortcut below.",C.red)
        return
    end
    local item,recipient
    local quantity=(cmd=="/givetreadmill" or cmd=="/giveeverything") and 1 or 3
    if branchItems[cmd] then
        if rest=="" then chooseItem(cmd); return end
        local supplied,tail=rest:match('^"([^"]+)"%s*(.*)$')
        if not supplied then chooseItem(cmd); return end
        item=canonicalItem(cmd,supplied)
        if not item then line("Choose one of the listed items.",C.red); chooseItem(cmd); return end
        recipient=trim(tail)
    else
        recipient=rest
    end
    if recipient=="" then recipientChoices(cmd,item); return end
    recipient=recipient:gsub("^@+","")
    if recipient=="" then
        line("Enter a player.",C.red)
        recipientChoices(cmd,item)
        return
    end
    local account=resolveRecipient(recipient,raw)
    if not account then return end
    local target=account.display
    local description
    if cmd=="/giveeggs" then description=item..(quantity==1 and " Egg" or " Eggs")
    elseif cmd=="/givepets" then description=item..(quantity==1 and " Pet" or " Pets")
    elseif cmd=="/givestars" then description=quantity==1 and "Star" or "Stars"
    else description=item end
    local sent=cmd=="/giveeverything" and "Everything" or (quantity.."× "..description)
    Console.Visible=false
    callRemote(remoteActions[cmd],account.name,item,quantity)
    notice(CFG.AnnouncementProfile.UserId,CFG.AnnouncementProfile.Name,": sent",sent,"to "..target)
    line(sent.." -> "..target)
    local delivery=((getgenv and getgenv()) or _G).SAE_PACKAGE_DELIVERY
    if type(delivery)=="function" then
        delivery(cmd,item,account.name,quantity,account.id,function(message)
            if Console.Parent then line("Parcel animation: "..message,C.red) end
        end)
    else
        line("Parcel animation is still loading. Try again in a moment.",C.red)
    end
    showCommands()
end
local function submit(raw)
    local ok,err=xpcall(function() command(raw) end,debug.traceback)
    if not ok and Console.Parent then
        -- Restore a usable prompt even if a game remote or UI callback fails.
        Console.Visible=true
        showCommands()
        errorInput=raw
        ci.Text=raw ci.TextColor3=C.red promptMark.TextColor3=C.red
        line("Command could not finish. Try again or clear the command.",C.red)
        ci:CaptureFocus()
        warn("[SAE] Console command: "..tostring(err))
    end
end
ci.FocusLost:Connect(function(enter)
    if enter then submit(ci.Text) end
end)
showCommands()
consoleJoinLabel=line(Display.." has joined the server.")
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
E.SAE_ITEM_ICON_RESOLVER=nil

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local P=Players.LocalPlayer
local PG=P and (P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10))
local BP=P and (P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10))
if not P or not PG or not BP then E.SAE_V7=nil return end

for _,n in ipairs({'SAE_ITEMS_HOTBAR_V7','SAE_ITEMS_V7','SAE_ITEMS_V6','SAE_ITEMS_V5','SAE_ITEMS_V4','SAE_ITEMS_V3'}) do local g=PG:FindFirstChild(n) if g then g:Destroy() end end
for _,holder in ipairs({BP,P.Character}) do if holder then for _,o in ipairs(holder:GetChildren()) do if o:IsA('Tool') and (o:GetAttribute('SAE_V6_TOOL') or o:GetAttribute('SAE_V5_TOOL') or o:GetAttribute('SAE_V7_TOOL')) then o:Destroy() end end end end
local oldPlaced=workspace:FindFirstChild('SAE_V7_PLACED') if oldPlaced then oldPlaced:Destroy() end
local Placed=Instance.new('Folder') Placed.Name='SAE_V7_PLACED' Placed.Parent=workspace

local GiftCatalog={
    Eggs={
        'Unicorn Egg','Kitsune Egg','Night Flame Egg','Archangel Egg',
        'World Burner Egg','Aetheron Egg','Cthulhu Egg','Luminous Cthulhu Egg',
        'Sabertooth Egg','Skeletal Sabertooth Egg','Octophant Egg','Mecha Scrambler Egg'
    },
    Pets={
        'Unicorn','Kitsune','Night Flame','Archangel',
        'World Burner','Aetheron','Cthulhu','Luminous Cthulhu',
        'Sabertooth','Skeletal Sabertooth','Octophant','Mecha Scrambler'
    },
    Star={'Star',"Ben's Treadmill","Brocodile's Treadmill"}
}

local Eggs=GiftCatalog.Eggs
local Pets=GiftCatalog.Pets
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
['Unicorn Egg']={palette={{244,184,207},{255,230,241},{253,210,230},{244,166,203},{255,232,241},{231,156,191},{255,218,234},{53,222,228},{245,77,112},{182,119,233},{232,90,179},{183,119,235},{193,150,238},{255,235,243},{255,238,161},{255,245,187},{232,194,99},{239,142,181},{240,151,187},{241,160,192},{242,169,198},{243,179,204},{244,188,210},{245,197,215},{246,206,221}},parts={{'box','EggShell',{0.275467,0.31237,0.514973},18,{-0.275467,-1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.690909},18,{0,-1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.514973},18,{0.275467,-1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.763828},19,{-0.8264,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.196689},19,{-0.550934,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.36249},19,{-0.275467,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.36249},19,{0,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.196689},19,{0.275467,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.763828},19,{0.550934,-0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},20,{-0.8264,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},20,{-0.550934,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},20,{-0.275467,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.61212},20,{0,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},20,{0.275467,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},20,{0.550934,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},20,{0.8264,-0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},21,{-0.8264,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},21,{-0.550934,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},21,{-0.275467,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.61212},21,{0,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},21,{0.275467,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},21,{0.550934,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},21,{0.8264,-0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},22,{-0.8264,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},22,{-0.550934,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},22,{-0.275467,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.61212},22,{0,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},22,{0.275467,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},22,{0.550934,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},22,{0.8264,0.156185,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},23,{-0.8264,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},23,{-0.550934,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},23,{-0.275467,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.61212},23,{0,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.544919},23,{0.275467,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.322989},23,{0.550934,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.830369},23,{0.8264,0.468555,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.763828},24,{-0.550934,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.196689},24,{-0.275467,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.36249},24,{0,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.36249},24,{0.275467,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.196689},24,{0.550934,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.763828},24,{0.8264,0.780925,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.690909},25,{-0.550934,1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.05538},25,{-0.275467,1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.151514},25,{0,1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,1.05538},25,{0.275467,1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','OriginalShellCell',{0.275467,0.31237,0.690909},25,{0.550934,1.093295,0},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0.035},{'box','CrystalPrism',{0.537567,0.686226,0.424678},8,{-0.581154,1.477757,0.188875},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.06,0.055},{'corner','CrystalPoint',{0.268784,0.486077,0.268784},8,{-0.715545,2.063909,0.323267},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.268784,0.486077,0.268784},8,{-0.446762,2.063909,0.323267},{0,0,1.0,0,1.0,0,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.268784,0.486077,0.268784},8,{-0.446762,2.063909,0.054483},{-1.0,0,0,0,1.0,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.268784,0.486077,0.268784},8,{-0.715545,2.063909,0.054483},{0,0,-1.0,0,1.0,0,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.668327,0.878704,0.527978},9,{0.24699,1.520879,0.145288},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.06,0.055},{'box','CrystalVioletRoot',{0.668327,0.366127,0.527978},10,{0.24699,0.898463,0.145288},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.07,0.04},{'box','CrystalRoseBand',{0.668327,0.329514,0.527978},11,{0.24699,1.154752,0.145288},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.06,0},{'corner','CrystalPoint',{0.334163,0.622415,0.334163},9,{0.079909,2.271439,0.31237},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.334163,0.622415,0.334163},9,{0.414072,2.271439,0.31237},{0,0,1.0,0,1.0,0,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.334163,0.622415,0.334163},9,{0.414072,2.271439,-0.021793},{-1.0,0,0,0,1.0,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.334163,0.622415,0.334163},9,{0.079909,2.271439,-0.021793},{0,0,-1.0,0,1.0,0,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.523038,0.627646,0.4132},12,{0.697384,1.397674,-0.145288},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.06,0.055},{'corner','CrystalPoint',{0.261519,0.444582,0.261519},12,{0.566625,1.933789,-0.014529},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.261519,0.444582,0.261519},12,{0.828144,1.933789,-0.014529},{0,0,1.0,0,1.0,0,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.261519,0.444582,0.261519},12,{0.828144,1.933789,-0.276048},{-1.0,0,0,0,1.0,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.261519,0.444582,0.261519},12,{0.566625,1.933789,-0.276048},{0,0,-1.0,0,1.0,0,1.0,0,0},'glass',0,0},{'box','CrystalPrism',{0.450394,0.485379,0.355811},13,{-0.145288,1.257151,-0.508509},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0.06,0.055},{'corner','CrystalPoint',{0.225197,0.34381,0.225197},13,{-0.257887,1.671746,-0.395911},{1.0,0,0,0,1.0,0,0,0,1.0},'glass',0,0},{'corner','CrystalPoint',{0.225197,0.34381,0.225197},13,{-0.03269,1.671746,-0.395911},{0,0,1.0,0,1.0,0,-1.0,0,0},'glass',0,0},{'corner','CrystalPoint',{0.225197,0.34381,0.225197},13,{-0.03269,1.671746,-0.621108},{-1.0,0,0,0,1.0,0,0,0,-1.0},'glass',0,0},{'corner','CrystalPoint',{0.225197,0.34381,0.225197},13,{-0.257887,1.671746,-0.621108},{0,0,-1.0,0,1.0,0,1.0,0,0},'glass',0,0},{'corner','IvoryHorn',{0.210668,2.094623,0.210668},15,{-1.078975,2.010024,-0.163472},{0.874157,-0.485538,0.010106,0.485643,0.873968,-0.01819,0,0.020809,0.999783},'plastic',0,0},{'corner','IvoryHorn',{0.210668,2.094623,0.210668},15,{-0.894818,2.112334,-0.163472},{-0.010106,-0.485538,0.874157,0.01819,0.873968,0.485643,-0.999783,0.020809,0},'plastic',0,0},{'corner','IvoryHorn',{0.210668,2.094623,0.210668},15,{-0.896947,2.116166,-0.374095},{-0.874157,-0.485538,-0.010106,-0.485643,0.873968,0.01819,0,0.020809,-0.999783},'plastic',0,0},{'corner','IvoryHorn',{0.210668,2.094623,0.210668},15,{-1.081104,2.013856,-0.374095},{0.010106,-0.485538,-0.874157,-0.01819,0.873968,-0.485643,0.999783,0.020809,0},'plastic',0,0},{'corner','HornTip',{0.039954,0.363221,0.039954},16,{-1.496096,2.936603,-0.227773},{0.874157,-0.485538,0.010106,0.485643,0.873968,-0.01819,0,0.020809,0.999783},'plastic',0,0},{'corner','HornTip',{0.039954,0.363221,0.039954},16,{-1.46117,2.956006,-0.227773},{-0.010106,-0.485538,0.874157,0.01819,0.873968,0.485643,-0.999783,0.020809,0},'plastic',0,0},{'corner','HornTip',{0.039954,0.363221,0.039954},16,{-1.461573,2.956733,-0.267719},{-0.874157,-0.485538,-0.010106,-0.485643,0.873968,0.01819,0,0.020809,-0.999783},'plastic',0,0},{'corner','HornTip',{0.039954,0.363221,0.039954},16,{-1.4965,2.937329,-0.267719},{0.010106,-0.485538,-0.874157,-0.01819,0.873968,-0.485643,0.999783,0.020809,0},'plastic',0,0},{'box','HornSpiral',{0.370776,0.036322,0.255708},17,{-0.601494,1.367454,-0.285346},{0.874157,-0.485538,0.010106,0.485643,0.873968,-0.01819,0,0.020809,0.999783},'metal',0,0},{'box','HornSpiral',{0.311789,0.036322,0.215027},17,{-0.743877,1.623743,-0.279244},{0.701268,-0.485538,0.521992,0.403585,0.873968,0.270738,-0.587658,0.020809,0.808842},'metal',0,0},{'box','HornSpiral',{0.252802,0.036322,0.174346},17,{-0.886259,1.880032,-0.273142},{0.260518,-0.485538,0.834496,0.167372,0.873968,0.456253,-0.950851,0.020809,0.30895},'metal',0,0},{'box','HornSpiral',{0.193815,0.036322,0.133665},17,{-1.028642,2.136321,-0.26704},{-0.27974,-0.485538,0.82825,-0.132772,0.873968,0.467495,-0.950851,0.020809,-0.30895},'metal',0,0},{'box','HornSpiral',{0.134828,0.036322,0.092985},17,{-1.171024,2.392609,-0.260938},{-0.713148,-0.485538,0.505641,-0.382201,0.873968,0.30017,-0.587658,0.020809,-0.808842},'metal',0,0}},bounds={2.64689,4.375,1.61212},displayScale=1.369078},
['Kitsune Egg']={palette={{194,186,154},{135,126,94},{222,48,196},{27,28,35},{240,74,216},{223,48,194},{255,235,246}},parts={{'box','EggShell',{0.284961,0.351511,0.863432},1,{-0.854882,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{-0.569921,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{-0.284961,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{0,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{0.284961,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{0.569921,-1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.134771},1,{-1.424805,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.859161},1,{-1.139844,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.254564},1,{-0.854882,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.483435},1,{-0.569921,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.590296},1,{-0.284961,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.590296},1,{0,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.483435},1,{0.284961,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.254564},1,{0.569921,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.859161},1,{0.854882,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.134771},1,{1.139844,-1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,-0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-1.424805,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{-1.139844,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{-0.854882,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{-0.569921,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{-0.284961,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.863681},1,{0,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.815949},1,{0.284961,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.667636},1,{0.569921,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.400166},1,{0.854882,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.965483},1,{1.139844,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{1.424805,0.175755,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{-1.139844,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.625789},1,{-0.854882,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.930694},1,{-0.569921,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.066342},1,{-0.284961,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,2.066342},1,{0,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.930694},1,{0.284961,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.625789},1,{0.569921,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{0.854882,0.527266,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.93865},1,{-0.854882,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.495507},1,{-0.569921,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.746379},1,{-0.284961,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.822342},1,{0,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.746379},1,{0.284961,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.495507},1,{0.569921,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.93865},1,{0.854882,0.878776,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{-0.854882,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{-0.569921,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{-0.284961,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.540161},1,{0,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.352737},1,{0.284961,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.863432},1,{0.569921,1.230286,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.781004},1,{-0.569921,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{-0.284961,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.301674},1,{0,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.193004},1,{0.284961,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.781004},1,{0.569921,1.581796,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.688781},1,{-0.569921,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{-0.284961,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,1.008271},1,{0,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','OriginalShellCell',{0.284961,0.351511,0.688781},1,{0.284961,1.933306,0},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.509684,-1.567339,1.297211},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.607985,-1.652475,1.275744},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.257694,-1.567339,0.664037},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.32746,-1.652475,0.591536},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.523234,-1.567339,-0.480673},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.494864,-1.652475,-0.577206},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.108906,-1.567339,-0.915444},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.019038,-1.652475,-0.960689},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,-1.567339,-1.329976},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,-1.652475,-1.329976},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.644208,-1.567339,-1.005934},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.734076,-1.652475,-0.960689},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.181534,-1.567339,-0.673739},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.209904,-1.652475,-0.577206},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.112262,-1.567339,0.519034},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.042499,-1.652475,0.591536},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.421323,-1.567339,1.254276},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.323024,-1.652475,1.275744},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.413013,-0.721342,1.389311},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.511311,-0.806478,1.367844},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.231201,-0.721342,1.079392},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.300968,-0.806478,1.006891},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.51265,-0.721342,-0.509788},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.484281,-0.806478,-0.606322},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.052516,-0.721342,-1.185946},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.962647,-0.806478,-1.231192},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.100616,-0.721342,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0,-0.806478,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.872777,-0.721342,-1.276438},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.962647,-0.806478,-1.231192},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.455913,-0.721342,-0.702855},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.484281,-0.806478,-0.606322},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.370731,-0.721342,0.934389},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.300968,-0.806478,1.006891},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.609611,-0.721342,1.346378},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.511311,-0.806478,1.367844},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.413013,0.293525,1.389311},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.511311,0.208388,1.367844},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.231201,0.293525,1.079392},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.300968,0.208388,1.006891},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.51265,0.293525,-0.509788},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-1.484281,0.208388,-0.606322},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-1.052516,0.293525,-1.185946},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.962647,0.208388,-1.231192},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.100616,0.293525,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0,0.208388,-1.466669},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.872777,0.293525,-1.276438},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.962647,0.208388,-1.231192},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.455913,0.293525,-0.702855},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.484281,0.208388,-0.606322},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{1.370731,0.293525,0.934389},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{1.300968,0.208388,1.006891},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.609611,0.293525,1.346378},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.511311,0.208388,1.367844},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.326456,1.239675,0.825574},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.424755,1.154539,0.804106},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.793742,1.239675,0.528367},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.863506,1.154539,0.455866},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.995646,1.239675,-0.345003},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.967276,1.154539,-0.441536},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.764549,1.239675,-0.662233},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.67468,1.154539,-0.707479},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,1.239675,-0.804909},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,1.154539,-0.804909},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.29985,1.239675,-0.752724},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.389719,1.154539,-0.707479},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.653948,1.239675,-0.53807},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.682316,1.154539,-0.441536},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.64831,1.239675,0.383364},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.578545,1.154539,0.455866},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.238094,1.239675,0.78264},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.139794,1.154539,0.804106},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.23484,1.862191,0.55963},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.333141,1.777055,0.538162},{-0.976975,0,0.213354,0,1.0,0,-0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.561765,1.862191,0.44104},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.63153,1.777055,0.368539},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.731854,1.862191,-0.257676},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.703483,1.777055,-0.354211},{0.281955,0,0.959428,0,1.0,0,-0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.592369,1.862191,-0.330254},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.5025,1.777055,-0.375499},{0.893188,0,0.449684,0,1.0,0,-0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{-0.243096,1.862191,-0.538964},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{-0.14248,1.777055,-0.538964},{1.0,0,0,0,1.0,0,0,0,1.0},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.12767,1.862191,-0.420744},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.217539,1.777055,-0.375499},{0.893188,0,-0.449684,0,1.0,0,0.449684,0,0.893188},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.390154,1.862191,-0.450744},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.418521,1.777055,-0.354211},{0.281955,0,-0.959428,0,1.0,0,0.959428,0,0.281955},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.416332,1.862191,0.296038},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.346569,1.777055,0.368539},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'concrete',0,0},{'box','ShellEmboss',{0.030959,0.203168,0.034829},2,{0.146477,1.862191,0.516695},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','ShellEmboss',{0.21284,0.030959,0.034829},2,{0.04818,1.777055,0.538162},{-0.976975,0,-0.213354,0,1.0,0,0.213354,0,-0.976975},'concrete',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.890215,0.510229,-0.843289},{0.872689,0,0.488277,0,1.0,0,-0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.716029,0.790069,-0.776737},{0.832165,0,0.554528,0,1.0,0,-0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.80595,1.054531,-0.458962},{0.782307,0,0.622894,0,1.0,0,-0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{-0.848086,1.298469,-0.456839},{0.721315,0,0.692607,0,1.0,0,-0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,1.141603,0.69657},3,{-0.812666,0.541778,-0.928989},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,0.677222,0.48373},3,{-1.102905,0.928761,-0.620231},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.522427,0.232191,0.145119},3,{-0.599825,1.470539,-0.44855},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.619174,0.174142,0.12577},4,{-0.48373,-0.928761,-1.440239},{0.913545,-0.406737,0,0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.580475,0.800119,0.580475},3,{-0.725595,-1.751101,-1.10137},{0.27146,-0.943133,-0.19186,0.96245,0.266012,0.054114,0,-0.199346,0.979929},'plastic',0,0},{'box','FoxTail',{0.475991,0.798099,0.475991},3,{-1.354444,-1.383467,-1.01458},{0.72032,-0.630347,0.289485,0.693642,0.654591,-0.300619,0,0.417341,0.90875},'plastic',0,0},{'box','FoxTail',{0.371505,0.650432,0.371505},3,{-1.731754,-0.822341,-0.84804},{0.922194,-0.386727,0,0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.267019,0.684096,0.267019},3,{-1.80915,-0.183817,-0.84804},{0.989949,0.141421,0,-0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.162532,0.332896,0.162532},3,{-1.664031,0.290238,-0.84804},{0.813733,0.581238,0,-0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.541778,0.348286,0.580475},5,{-1.102905,-1.644681,-1.18112},{0.949092,0.201736,-0.241922,-0.207912,0.978148,0,0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.493405,0.348286,0.532104},5,{-1.605983,-1.122254,-0.84804},{0.905849,0.347723,-0.241922,-0.358368,0.93358,0,0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.445031,0.348286,0.48373},5,{-1.857521,-0.522427,-0.84804},{0.840301,0.485148,-0.241922,-0.5,0.866025,0,0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.396657,0.348286,0.435356},5,{-1.760776,0.154794,-0.84804},{0.754061,0.610627,-0.241922,-0.62932,0.777146,0,0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.751869,0.453832,-0.716069},{0.957826,0.282587,-0.052091,-0.287348,0.941956,-0.173638,0,0.181283,0.983431},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.603605,0.409354,-0.716069},{0.052091,0.282587,0.957826,0.173638,0.941956,-0.287348,-0.983431,0.181283,0},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.595541,0.436231,-0.868299},{-0.957826,0.282587,0.052091,0.287348,0.941956,0.173638,0,0.181283,-0.983431},'plastic',0,0},{'corner','TailTip',{0.154794,0.616245,0.154794},3,{-1.743806,0.480711,-0.868299},{-0.052091,0.282587,-0.957826,-0.173638,0.941956,0.287348,0.983431,0.181283,0},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.605255,0.510229,-0.843289},{0.872689,0,-0.488277,0,1.0,0,0.488277,0,0.872689},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.716029,0.790069,-0.776737},{0.832165,0,-0.554528,0,1.0,0,0.554528,0,0.832165},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.520989,1.054531,-0.458962},{0.782307,0,-0.622894,0,1.0,0,0.622894,0,0.782307},'plastic',0,0},{'box','MagentaCheek',{0.50308,0.48373,0.087071},3,{0.563125,1.298469,-0.456839},{0.721315,0,-0.692607,0,1.0,0,0.692607,0,0.721315},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,1.141603,0.69657},3,{0.812666,0.541778,-0.620231},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'wedge','FoxCheekFlame',{0.164469,0.677222,0.48373},3,{1.102905,0.928761,-0.58542},{0,0,1.0,0.207912,0.978148,0,-0.978148,0.207912,0},'plastic',0,0},{'box','UpperPinkMark',{0.522427,0.232191,0.145119},3,{0.599825,1.470539,-0.44855},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','FoxEye',{0.619174,0.174142,0.12577},4,{0.48373,-0.928761,-1.440239},{0.913545,0.406737,0,-0.406737,0.913545,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.580475,0.791599,0.580475},3,{0.725595,-1.751101,-0.873417},{0.27146,0.953285,-0.132505,-0.96245,0.268875,-0.037373,0,0.137675,0.990478},'plastic',0,0},{'box','FoxTail',{0.475991,0.725856,0.475991},3,{1.354444,-1.383467,-0.833483},{0.72032,0.693083,0.027823,-0.693642,0.71974,0.028893,0,-0.040112,0.999195},'plastic',0,0},{'box','FoxTail',{0.371505,0.650432,0.371505},3,{1.731754,-0.822341,-0.84804},{0.922194,0.386727,0,-0.386727,0.922194,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.267019,0.684096,0.267019},3,{1.80915,-0.183817,-0.84804},{0.989949,-0.141421,0,0.141421,0.989949,0,0,0,1.0},'plastic',0,0},{'box','FoxTail',{0.162532,0.332896,0.162532},3,{1.664031,0.290238,-0.84804},{0.813733,-0.581238,0,0.581238,0.813733,0,0,0,1.0},'plastic',0,0},{'box','TailTuft',{0.541778,0.348286,0.580475},5,{1.102905,-1.644681,-0.818925},{0.949092,-0.201736,0.241922,0.207912,0.978148,0,-0.236635,0.050298,0.970296},'plastic',0,0},{'box','TailTuft',{0.493405,0.348286,0.532104},5,{1.605983,-1.122254,-0.84804},{0.905849,-0.347723,0.241922,0.358368,0.93358,0,-0.225854,0.086697,0.970296},'plastic',0,0},{'box','TailTuft',{0.445031,0.348286,0.48373},5,{1.857521,-0.522427,-0.84804},{0.840301,-0.485148,0.241922,0.5,0.866025,0,-0.209511,0.120961,0.970296},'plastic',0,0},{'box','TailTuft',{0.396657,0.348286,0.435356},5,{1.760776,0.154794,-0.84804},{0.754061,-0.610627,0.241922,0.62932,0.777146,0,-0.188009,0.152246,0.970296},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.600283,0.420426,-0.761009},{0.957826,-0.287202,0.00917,0.287348,0.957338,-0.030565,0,0.031911,0.999491},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.748546,0.464906,-0.761009},{-0.00917,-0.287202,0.957826,0.030565,0.957338,0.287348,-0.999491,0.031911,0},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.747129,0.469637,-0.915724},{-0.957826,-0.287202,-0.00917,-0.287348,0.957338,0.030565,0,0.031911,-0.999491},'plastic',0,0},{'corner','TailTip',{0.154794,0.606344,0.154794},3,{1.598863,0.425157,-0.915724},{0.00917,-0.287202,-0.957826,-0.030565,0.957338,-0.287348,0.999491,0.031911,0},'plastic',0,0},{'box','CrownPatch',{0.832016,0.193492,0.677222},3,{0,1.992968,-0.038699},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CrownFrontPatch',{0.832016,0.193492,0.116095},3,{0,1.857521,-0.571858},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilBezel',{0.445031,0.445031,0.270889},6,{0,0.832016,-1.046615},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','ForeheadSigilGem',{0.311521,0.311521,0.290238},7,{0,0.832016,-1.220757},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0},{'box','ForeheadSigilFacet',{0.133509,0.133509,0.067721},7,{-0.048374,0.880387,-1.385226},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'plastic',0,0}},bounds={4.375,4.26163,2.967437}},
['Night Flame Egg']={palette={{82.0,46.0,18.0},{162.0,104.0,35.0},{145.0,91.0,29.0},{111.0,65.0,22.0},{219.0,149.0,36.0},{237.0,170.0,48.0},{238.0,171.0,46.0},{43.0,100.0,22.0},{51.0,112.0,22.0},{59.0,124.0,22.0},{38.0,79.0,19.0},{60.0,123.0,25.0},{135.0,82.0,25.0},{114.0,190.0,38.0},{111.0,62.0,20.0},{223.0,146.0,31.0},{183.0,74.0,16.0},{255.0,146.0,13.0},{255.0,200.0,49.0},{176.0,114.0,33.0}},parts={{'box','EggShell',{0.070843,0.226982,0.779559},1.0,{-0.177108,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.070843,0.226982,1.221335},1.0,{-0.106265,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.070843,0.226982,1.390552},1.0,{-0.035422,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.070843,0.226982,1.390552},1.0,{0.035422,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.070843,0.226982,1.221335},1.0,{0.106265,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.070843,0.226982,0.779559},1.0,{0.177108,-1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,0.847471},1.0,{-0.300107,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,1.350237},1.0,{-0.180065,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,1.576737},1.0,{-0.060021,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,1.645322},1.0,{0.060021,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,1.576737},1.0,{0.180065,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,1.350237},1.0,{0.300107,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.120043,0.226982,0.847471},1.0,{0.42015,-1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,0.910329},1.0,{-0.639019,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.467862},1.0,{-0.456442,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.743148},1.0,{-0.273865,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.86562},1.0,{-0.091288,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.86562},1.0,{0.091288,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.743148},1.0,{0.273865,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,1.467862},1.0,{0.456442,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.182577,0.226982,0.910329},1.0,{0.639019,-0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{-0.826505,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{-0.59036,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{-0.354217,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{-0.118072,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{0.118072,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{0.354217,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{0.59036,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{0.826505,-0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{-0.826505,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{-0.59036,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{-0.354217,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{-0.118072,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{0.118072,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{0.354217,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{0.59036,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{0.826505,-0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{-0.826505,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{-0.59036,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{-0.354217,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{-0.118072,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.86562},1.0,{0.118072,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.743148},1.0,{0.354217,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.467862},1.0,{0.59036,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.910329},1.0,{0.826505,-0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.96912},1.0,{-1.062649,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.576737},1.0,{-0.826505,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.895002},1.0,{-0.59036,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.062521},1.0,{-0.354217,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.115414},1.0,{-0.118072,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.062521},1.0,{0.118072,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.895002},1.0,{0.354217,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.576737},1.0,{0.59036,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,0.96912},1.0,{0.826505,0.113491,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.024542},1.0,{-1.062649,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.678564},1.0,{-0.826505,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.035559},1.0,{-0.59036,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.242197},1.0,{-0.354217,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.338679},1.0,{-0.118072,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.338679},1.0,{0.118072,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.242197},1.0,{0.354217,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,2.035559},1.0,{0.59036,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.678564},1.0,{0.826505,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.236145,0.226982,1.024542},1.0,{1.062649,0.340473,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,1.077116},1.0,{-1.107145,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,1.774558},1.0,{-0.905846,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.167018},1.0,{-0.704547,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.408505},1.0,{-0.503247,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.542412},1.0,{-0.301949,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.585507},1.0,{-0.100649,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.542412},1.0,{0.100649,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.408505},1.0,{0.301949,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,2.167018},1.0,{0.503247,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,1.774558},1.0,{0.704547,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.2013,0.226982,1.077116},1.0,{0.905846,0.567455,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,1.127241},1.0,{-0.907101,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,1.86562},1.0,{-0.742173,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.290945},1.0,{-0.577246,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.564049},1.0,{-0.412318,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.730988},1.0,{-0.247391,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.810741},1.0,{-0.082463,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.810741},1.0,{0.082463,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.730988},1.0,{0.247391,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.564049},1.0,{0.412318,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,2.290945},1.0,{0.577246,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,1.86562},1.0,{0.742173,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.164928,0.226982,1.127241},1.0,{0.907101,0.794436,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.910329},1.0,{-0.769999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.467862},1.0,{-0.629999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.743148},1.0,{-0.489999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.86562},1.0,{-0.349999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.86562},1.0,{-0.21,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.743148},1.0,{-0.07,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,1.467862},1.0,{0.07,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.910329},1.0,{0.21,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.525579},1.0,{0.489999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.705138},1.0,{0.629999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.525579},1.0,{0.769999,1.021418,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.25855},1.0,{-0.769999,1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.25855},1.0,{-0.07,1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.407112},1.0,{0.629999,1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','OriginalShellCell',{0.14,0.226982,0.407112},1.0,{0.769999,1.2484,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0,-1.179432,0.479908},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{-0.245193,-1.179432,0.423006},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{-0.428141,-1.179432,0.272028},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{-0.498152,-1.179432,-0.256434},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{-0.428141,-1.179432,-0.272028},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{-0.245193,-1.179432,-0.423006},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{0,-1.179432,-0.479908},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.245193,-1.179432,-0.423006},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.428141,-1.179432,-0.272028},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{0.498152,-1.179432,-0.256434},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.428141,-1.179432,0.272028},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{0.245193,-1.179432,0.423006},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.167717,-0.781149,0.635896},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{-0.46003,-0.781149,0.502134},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.633141,-0.781149,0.308621},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.633141,-0.781149,-0.308621},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{-0.46003,-0.781149,-0.502134},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.167717,-0.781149,-0.635896},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{0.167717,-0.781149,-0.635896},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.46003,-0.781149,-0.502134},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.633141,-0.781149,-0.308621},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.633141,-0.781149,0.308621},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.46003,-0.781149,0.502134},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.167717,-0.781149,0.635896},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0,-0.23649,0.636181},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.32447,-0.23649,0.594655},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.565453,-0.23649,0.315045},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.656706,-0.23649,-0.299451},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.565453,-0.23649,-0.315045},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.32447,-0.23649,-0.594655},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0,-0.23649,-0.636181},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.32447,-0.23649,-0.594655},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.565453,-0.23649,-0.315045},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{0.656706,-0.23649,-0.299451},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{0.565453,-0.23649,0.315045},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.32447,-0.23649,0.594655},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.208754,0.352483,0.75977},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.572144,0.352483,0.571445},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.786293,0.352483,0.346191},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.786293,0.352483,-0.346191},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.572144,0.352483,-0.571445},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{-0.208754,0.352483,-0.75977},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.208754,0.352483,-0.75977},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.572144,0.352483,-0.571445},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.786293,0.352483,-0.346191},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{0.786293,0.352483,0.346191},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.572144,0.352483,0.571445},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.208754,0.352483,0.75977},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0,0.875407,0.947076},{-1.0,0,0,0,1.0,0,0,0,-1.0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{-0.483024,0.875407,0.864689},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{-0.840077,0.875407,0.629285},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.973814,0.875407,-0.370803},{0,0,1.0,0,1.0,0,-1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},4.0,{-0.840077,0.875407,-0.629285},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{-0.483024,0.875407,-0.864689},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0,0.875407,-0.947076},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.483024,0.875407,-0.864689},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.840077,0.875407,-0.629285},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.973814,0.875407,-0.370803},{0,0,-1.0,0,1.0,0,1.0,0,0},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},2.0,{0.840077,0.875407,0.629285},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'wood',0,0},{'box','BarkPanel',{0.374832,0.349844,0.11245},3.0,{0.483024,0.875407,0.864689},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{-0.249791,1.202478,0.635896},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{-0.684259,1.202478,0.592689},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{-0.939444,1.202478,0.09422},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{-0.939444,1.202478,-0.09422},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{-0.684259,1.202478,-0.592689},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{-0.249791,1.202478,-0.635896},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},4.0,{0.249791,1.202478,-0.321655},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.684259,1.202478,-0.192173},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{0.939444,1.202478,-0.143089},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},3.0,{0.939444,1.202478,0.143089},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.684259,1.202478,0.192173},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'wood',0,0},{'box','BarkPanel',{0.287371,0.349844,0.11245},2.0,{0.249791,1.202478,0.321655},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'wood',0,0},{'box','GoldenPinion',{0.087461,0.573247,0.149933},5.0,{-1.012047,0.630968,0.11245},{0.283346,-0.959018,0,0.959018,0.283346,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.352329,0.738281,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.321475,0.773543,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.321475,0.773543,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.352329,0.738281,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.675767,0.149933},5.0,{-1.108879,0.843373,0.11245},{0.24036,-0.970684,0,0.970684,0.24036,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.502262,0.950686,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.471408,0.985948,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.471408,0.985948,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.502262,0.950686,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.779275,0.149933},5.0,{-1.205711,1.055778,0.11245},{0.208434,-0.978036,0,0.978036,0.208434,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.652195,1.163091,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.621341,1.198353,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.621341,1.198353,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.652195,1.163091,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.883422,0.149933},5.0,{-1.302542,1.268183,0.11245},{0.183862,-0.982952,0,0.982952,0.183862,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.802128,1.375496,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.771274,1.410758,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.771274,1.410758,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.802128,1.375496,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.988007,0.149933},5.0,{-1.399374,1.480588,0.11245},{0.164399,-0.986394,0,0.986394,0.164399,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.952059,1.587901,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.921205,1.623163,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.921205,1.623163,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-1.952059,1.587901,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,1.092904,0.149933},5.0,{-1.496206,1.692993,0.11245},{0.14862,-0.988894,0,0.988894,0.14862,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-2.101992,1.800306,0.135877},{0.658505,-0.752577,0,0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-2.071138,1.835565,0.135877},{0,-0.752577,0.658505,0,0.658505,0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-2.071138,1.835565,0.089023},{-0.658505,-0.752577,0,-0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{-2.101992,1.800306,0.089023},{0,-0.752577,-0.658505,0,0.658505,-0.752577,1.0,0,0},'metal',0,0},{'box','WingRidge',{0.106202,0.806349,0.106202},7.0,{-1.030789,1.124497,0.162427},{0.650791,-0.759257,0,0.759257,0.650791,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.106202,0.945374,0.106202},7.0,{-1.749218,1.618026,0.162427},{0.489006,-0.872281,0,0.872281,0.489006,0,0,0,1.0},'metal',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.687601,-1.029133,-0.635993},{0.98503,0.169129,0.03332,-0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.576835,-1.048518,-0.635993},{-0.03332,0.169129,0.98503,-0.190397,0.966454,-0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.580582,-1.069928,-0.746322},{-0.98503,0.169129,-0.03332,0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.691348,-1.050544,-0.746322},{0.03332,0.169129,-0.98503,0.190397,0.966454,0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.904174,-0.822563,-0.708057},{0.771373,-0.628942,-0.09703,0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.817433,-0.751002,-0.708057},{0.09703,-0.628942,0.771373,-0.117612,0.762354,0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.806522,-0.764227,-0.819191},{-0.771373,-0.628942,0.09703,-0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.893263,-0.835788,-0.819191},{-0.09703,-0.628942,-0.771373,0.117612,0.762354,-0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.739128,-0.516863,-0.708459},{0.98503,0.169129,0.03332,-0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.628362,-0.536247,-0.708459},{-0.03332,0.169129,0.98503,-0.190397,0.966454,-0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.632109,-0.557657,-0.818789},{-0.98503,0.169129,-0.03332,0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.742875,-0.538273,-0.818789},{0.03332,0.169129,-0.98503,0.190397,0.966454,0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{-0.739115,-0.310292,-0.708057},{0.771373,-0.628942,-0.09703,0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{-0.652375,-0.238731,-0.708057},{0.09703,-0.628942,0.771373,-0.117612,0.762354,0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{-0.641464,-0.251956,-0.819191},{-0.771373,-0.628942,0.09703,-0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{-0.728204,-0.323518,-0.819191},{-0.09703,-0.628942,-0.771373,0.117612,0.762354,-0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{-0.599295,-0.004592,-0.708459},{0.98503,0.169129,0.03332,-0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{-0.488529,-0.023976,-0.708459},{-0.03332,0.169129,0.98503,-0.190397,0.966454,-0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{-0.492276,-0.045386,-0.818789},{-0.98503,0.169129,-0.03332,0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{-0.603042,-0.026002,-0.818789},{0.03332,0.169129,-0.98503,0.190397,0.966454,0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{-0.829364,0.201979,-0.772826},{0.771373,-0.628942,-0.09703,0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{-0.742623,0.27354,-0.772826},{0.09703,-0.628942,0.771373,-0.117612,0.762354,0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{-0.731712,0.260314,-0.883961},{-0.771373,-0.628942,0.09703,-0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{-0.818453,0.188753,-0.883961},{-0.09703,-0.628942,-0.771373,0.117612,0.762354,-0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.787411,0.507679,-0.864071},{0.98503,0.169129,0.03332,-0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.676644,0.488295,-0.864071},{-0.03332,0.169129,0.98503,-0.190397,0.966454,-0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.680391,0.466885,-0.9744},{-0.98503,0.169129,-0.03332,0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{-0.791158,0.486269,-0.9744},{0.03332,0.169129,-0.98503,0.190397,0.966454,0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.839757,0.71425,-0.930685},{0.771373,-0.628942,-0.09703,0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.753016,0.785811,-0.930685},{0.09703,-0.628942,0.771373,-0.117612,0.762354,0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.742105,0.772585,-1.04182},{-0.771373,-0.628942,0.09703,-0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{-0.828846,0.701024,-1.04182},{-0.09703,-0.628942,-0.771373,0.117612,0.762354,-0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.604856,1.01995,-0.577618},{0.98503,0.169129,0.03332,-0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.494089,1.000566,-0.577618},{-0.03332,0.169129,0.98503,-0.190397,0.966454,-0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.497836,0.979156,-0.687947},{-0.98503,0.169129,-0.03332,0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{-0.608602,0.99854,-0.687947},{0.03332,0.169129,-0.98503,0.190397,0.966454,0.17238,0.981142,-0.193291,0},'plastic',0,0},{'box','IvyVine',{0.059973,0.752827,0.059973},11.0,{-0.718429,-0.818384,-0.641757},{0.967075,-0.24895,-0.052828,0.254493,0.94601,0.200747,0,-0.207581,0.978218},'wood',0,0},{'box','IvyVine',{0.059973,0.778284,0.059973},11.0,{-0.799642,-0.081214,-0.797699},{0.999463,0.032108,0.006552,-0.032769,0.979282,0.199834,0,-0.199942,0.979808},'wood',0,0},{'box','IvyVine',{0.059973,0.804957,0.059973},11.0,{-0.712181,0.668451,-0.732278},{0.979937,0.186262,-0.070926,-0.199309,0.915789,-0.348722,0,0.355861,0.934539},'wood',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.545716,0.839571,-1.019361},{0.543251,-0.823653,-0.162709,0.83957,0.532952,0.105282,0,-0.193801,0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.484628,0.93398,-1.019361},{0.162709,-0.823653,0.543251,-0.105282,0.532952,0.83957,-0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.466331,0.922141,-1.129678},{-0.543251,-0.823653,0.162709,-0.83957,0.532952,-0.105282,0,-0.193801,-0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.52742,0.827732,-1.129678},{-0.162709,-0.823653,-0.543251,0.105282,0.532952,-0.83957,0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.720638,1.076965,-0.577624},{0.543251,-0.823653,-0.162709,0.83957,0.532952,0.105282,0,-0.193801,0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.65955,1.171374,-0.577624},{0.162709,-0.823653,0.543251,-0.105282,0.532952,0.83957,-0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.641253,1.159535,-0.687941},{-0.543251,-0.823653,0.162709,-0.83957,0.532952,-0.105282,0,-0.193801,-0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{-0.702341,1.065126,-0.687941},{-0.162709,-0.823653,-0.543251,0.105282,0.532952,-0.83957,0.981041,-0.193801,0},'plastic',0,0},{'box','GoldenPinion',{0.087461,0.573247,0.149933},5.0,{1.012047,0.630968,0.11245},{0.283346,0.959018,0,-0.959018,0.283346,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.321475,0.773543,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.352329,0.738281,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.352329,0.738281,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.321475,0.773543,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.675767,0.149933},5.0,{1.108879,0.843373,0.11245},{0.24036,0.970684,0,-0.970684,0.24036,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.471408,0.985948,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.502262,0.950686,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.502262,0.950686,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.471408,0.985948,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.779275,0.149933},5.0,{1.205711,1.055778,0.11245},{0.208434,0.978036,0,-0.978036,0.208434,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.621341,1.198353,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.652195,1.163091,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.652195,1.163091,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.621341,1.198353,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.883422,0.149933},5.0,{1.302542,1.268183,0.11245},{0.183862,0.982952,0,-0.982952,0.183862,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.771274,1.410758,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.802128,1.375496,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.802128,1.375496,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.771274,1.410758,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,0.988007,0.149933},5.0,{1.399374,1.480588,0.11245},{0.164399,0.986394,0,-0.986394,0.164399,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.921205,1.623163,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.952059,1.587901,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.952059,1.587901,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{1.921205,1.623163,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','GoldenPinion',{0.087461,1.092904,0.149933},5.0,{1.496206,1.692993,0.11245},{0.14862,0.988894,0,-0.988894,0.14862,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{2.071138,1.835565,0.135877},{0.658505,0.752577,0,-0.752577,0.658505,0,0,0,1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{2.101992,1.800306,0.135877},{0,0.752577,0.658505,0,0.658505,-0.752577,-1.0,0,0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{2.101992,1.800306,0.089023},{-0.658505,0.752577,0,0.752577,0.658505,0,0,0,-1.0},'metal',0,0},{'corner','PinionTip',{0.046854,0.132817,0.046854},6.0,{2.071138,1.835565,0.089023},{0,0.752577,-0.658505,0,0.658505,0.752577,1.0,0,0},'metal',0,0},{'box','WingRidge',{0.106202,0.806349,0.106202},7.0,{1.030789,1.124497,0.162427},{0.650791,0.759257,0,-0.759257,0.650791,0,0,0,1.0},'metal',0,0},{'box','WingRidge',{0.106202,0.945374,0.106202},7.0,{1.749218,1.618026,0.162427},{0.489006,0.872281,0,-0.872281,0.489006,0,0,0,1.0},'metal',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.576835,-1.048518,-0.635993},{0.98503,-0.169129,-0.03332,0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.687601,-1.029133,-0.635993},{0.03332,-0.169129,0.98503,-0.190397,0.966454,0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.691348,-1.050544,-0.746322},{-0.98503,-0.169129,0.03332,-0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.580582,-1.069928,-0.746322},{-0.03332,-0.169129,-0.98503,0.190397,0.966454,-0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.817433,-0.751002,-0.708057},{0.771373,0.628942,0.09703,-0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.904174,-0.822563,-0.708057},{-0.09703,0.628942,0.771373,-0.117612,0.762354,-0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.893263,-0.835788,-0.819191},{-0.771373,0.628942,-0.09703,0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.806522,-0.764227,-0.819191},{0.09703,0.628942,-0.771373,0.117612,0.762354,0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.628362,-0.536247,-0.708459},{0.98503,-0.169129,-0.03332,0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.739128,-0.516863,-0.708459},{0.03332,-0.169129,0.98503,-0.190397,0.966454,0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.742875,-0.538273,-0.818789},{-0.98503,-0.169129,0.03332,-0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.632109,-0.557657,-0.818789},{-0.03332,-0.169129,-0.98503,0.190397,0.966454,-0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{0.652375,-0.238731,-0.708057},{0.771373,0.628942,0.09703,-0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{0.739115,-0.310292,-0.708057},{-0.09703,0.628942,0.771373,-0.117612,0.762354,-0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{0.728204,-0.323518,-0.819191},{-0.771373,0.628942,-0.09703,0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},8.0,{0.641464,-0.251956,-0.819191},{0.09703,0.628942,-0.771373,0.117612,0.762354,0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{0.488529,-0.023976,-0.708459},{0.98503,-0.169129,-0.03332,0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{0.599295,-0.004592,-0.708459},{0.03332,-0.169129,0.98503,-0.190397,0.966454,0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{0.603042,-0.026002,-0.818789},{-0.98503,-0.169129,0.03332,-0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},9.0,{0.492276,-0.045386,-0.818789},{-0.03332,-0.169129,-0.98503,0.190397,0.966454,-0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{0.742623,0.27354,-0.772826},{0.771373,0.628942,0.09703,-0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{0.829364,0.201979,-0.772826},{-0.09703,0.628942,0.771373,-0.117612,0.762354,-0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{0.818453,0.188753,-0.883961},{-0.771373,0.628942,-0.09703,0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},10.0,{0.731712,0.260314,-0.883961},{0.09703,0.628942,-0.771373,0.117612,0.762354,0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.676644,0.488295,-0.864071},{0.98503,-0.169129,-0.03332,0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.787411,0.507679,-0.864071},{0.03332,-0.169129,0.98503,-0.190397,0.966454,0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.791158,0.486269,-0.9744},{-0.98503,-0.169129,0.03332,-0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},8.0,{0.680391,0.466885,-0.9744},{-0.03332,-0.169129,-0.98503,0.190397,0.966454,-0.17238,0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.753016,0.785811,-0.930685},{0.771373,0.628942,0.09703,-0.636383,0.762354,0.117612,0,-0.152471,0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.839757,0.71425,-0.930685},{-0.09703,0.628942,0.771373,-0.117612,0.762354,-0.636383,-0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.828846,0.701024,-1.04182},{-0.771373,0.628942,-0.09703,0.636383,0.762354,-0.117612,0,-0.152471,-0.988308},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.327785,0.11245},9.0,{0.742105,0.772585,-1.04182},{0.09703,0.628942,-0.771373,0.117612,0.762354,0.636383,0.988308,-0.152471,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.494089,1.000566,-0.577618},{0.98503,-0.169129,-0.03332,0.17238,0.966454,0.190397,0,-0.193291,0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.604856,1.01995,-0.577618},{0.03332,-0.169129,0.98503,-0.190397,0.966454,0.17238,-0.981142,-0.193291,0},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.608602,0.99854,-0.687947},{-0.98503,-0.169129,0.03332,-0.17238,0.966454,-0.190397,0,-0.193291,-0.981142},'plastic',0,0},{'corner','IvyLeaf',{0.11245,0.258562,0.11245},10.0,{0.497836,0.979156,-0.687947},{-0.03332,-0.169129,-0.98503,0.190397,0.966454,-0.17238,0.981142,-0.193291,0},'plastic',0,0},{'box','IvyVine',{0.059973,0.752827,0.059973},11.0,{0.718429,-0.818384,-0.641757},{0.967075,0.24895,0.052828,-0.254493,0.94601,0.200747,0,-0.207581,0.978218},'wood',0,0},{'box','IvyVine',{0.059973,0.778284,0.059973},11.0,{0.799642,-0.081214,-0.797699},{0.999463,-0.032108,-0.006552,0.032769,0.979282,0.199834,0,-0.199942,0.979808},'wood',0,0},{'box','IvyVine',{0.059973,0.804957,0.059973},11.0,{0.712181,0.668451,-0.732278},{0.979937,-0.186262,0.070926,0.199309,0.915789,-0.348722,0,0.355861,0.934539},'wood',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.484628,0.93398,-1.019361},{0.543251,0.823653,0.162709,-0.83957,0.532952,0.105282,0,-0.193801,0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.545716,0.839571,-1.019361},{-0.162709,0.823653,0.543251,-0.105282,0.532952,-0.83957,-0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.52742,0.827732,-1.129678},{-0.543251,0.823653,-0.162709,0.83957,0.532952,-0.105282,0,-0.193801,-0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.466331,0.922141,-1.129678},{0.162709,0.823653,-0.543251,0.105282,0.532952,0.83957,0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.65955,1.171374,-0.577624},{0.543251,0.823653,0.162709,-0.83957,0.532952,0.105282,0,-0.193801,0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.720638,1.076965,-0.577624},{-0.162709,0.823653,0.543251,-0.105282,0.532952,-0.83957,-0.981041,-0.193801,0},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.702341,1.065126,-0.687941},{-0.543251,0.823653,-0.162709,0.83957,0.532952,-0.105282,0,-0.193801,-0.981041},'plastic',0,0},{'corner','CrownLeaf',{0.11245,0.257882,0.11245},12.0,{0.641253,1.159535,-0.687941},{0.162709,0.823653,-0.543251,0.105282,0.532952,0.83957,0.981041,-0.193801,0},'plastic',0,0},{'box','CarvedDiamondFrame',{0.96207,0.96207,0.093708},15.0,{0,-0.074966,-0.96207},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'wood',0,0},{'box','DiamondInnerRim',{0.824631,0.824631,0.081214},16.0,{0,-0.074966,-1.024542},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','EmberHeartBezel',{0.662204,0.662204,0.068719},17.0,{0,-0.074966,-1.068272},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'metal',0,0},{'box','EmberHeartGem',{0.474788,0.474788,0.056225},18.0,{0,-0.074966,-1.11825},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','EmberHeartFacet',{0.199911,0.199911,0.027488},19.0,{0,-0.074966,-1.155733},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownBand',{1.524318,0.274877,0.174922},13.0,{0,1.299419,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownRim',{1.574296,0.068719,0.212405},20.0,{0,1.43061,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{-0.637215,1.568049,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{-0.637215,1.736723,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{0,1.568049,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{0,1.736723,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{0.637215,1.568049,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{0.637215,1.736723,-0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBand',{1.524318,0.274877,0.174922},13.0,{0,1.299419,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownRim',{1.574296,0.068719,0.212405},20.0,{0,1.43061,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{-0.637215,1.568049,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{-0.637215,1.736723,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{0,1.568049,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{0,1.736723,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.274877,0.31236,0.212405},13.0,{0.637215,1.568049,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.299866,0.056225,0.237394},20.0,{0.637215,1.736723,0.487282},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBand',{0.174922,0.274877,0.974564},13.0,{-0.674698,1.299419,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownRim',{0.212405,0.068719,0.974564},20.0,{-0.674698,1.43061,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.212405,0.31236,0.274877},13.0,{-0.674698,1.568049,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.237394,0.056225,0.299866},20.0,{-0.674698,1.736723,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownBand',{0.174922,0.274877,0.974564},13.0,{0.674698,1.299419,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownRim',{0.212405,0.068719,0.974564},20.0,{0.674698,1.43061,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownMerlon',{0.212405,0.31236,0.274877},13.0,{0.674698,1.568049,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'box','CrownCap',{0.237394,0.056225,0.299866},20.0,{0.674698,1.736723,0},{1.0,0,0,0,1.0,0,0,0,1.0},'wood',0,0},{'corner','CrownEmerald',{0.181169,0.587237,0.181169},14.0,{-0.090584,1.692993,0.065596},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'corner','CrownEmerald',{0.181169,0.587237,0.181169},14.0,{0.090584,1.692993,0.065596},{0,0,1.0,0,1.0,0,-1.0,0,0},'plastic',0,0},{'corner','CrownEmerald',{0.181169,0.587237,0.181169},14.0,{0.090584,1.692993,-0.115573},{-1.0,0,0,0,1.0,0,0,0,-1.0},'plastic',0,0},{'corner','CrownEmerald',{0.181169,0.587237,0.181169},14.0,{-0.090584,1.692993,-0.115573},{0,0,-1.0,0,1.0,0,1.0,0,0},'plastic',0,0}},bounds={4.375,3.348502,2.810741},displayScale=1.428639},
['Archangel Egg']={palette={{207.0,144.0,29.0},{241.0,185.0,52.0},{191.0,121.0,20.0},{225.0,163.0,38.0},{246.0,195.0,62.0},{248.0,245.0,229.0},{255.0,237.0,112.0},{255.0,224.0,78.0},{255.0,255.0,183.0},{255.0,236.0,107.0},{255.0,243.0,152.0}},parts={{'box','EggShell',{0.17183,0.280279,0.474969},1.0,{-0.429577,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.744132},1.0,{-0.257748,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.847233},1.0,{-0.085915,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.847233},1.0,{0.085915,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.744132},1.0,{0.257748,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.474969},1.0,{0.429577,-1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.554644},1.0,{-0.601407,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.894336},1.0,{-0.429577,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.062063},1.0,{-0.257748,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{-0.085915,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{0.085915,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.062063},1.0,{0.257748,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.894336},1.0,{0.429577,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.554644},1.0,{0.601407,-0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.624231},1.0,{-0.94507,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.022712},1.0,{-0.773239,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.240221},1.0,{-0.601407,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.366122},1.0,{-0.429577,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.424906},1.0,{-0.257748,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.424906},1.0,{-0.085915,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.366122},1.0,{0.085915,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.240221},1.0,{0.257748,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.022712},1.0,{0.429577,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.624231},1.0,{0.601407,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{-0.94507,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.0812},1.0,{-0.773239,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.320318},1.0,{-0.601407,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.46745},1.0,{-0.429577,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.549036},1.0,{-0.257748,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.575294},1.0,{-0.085915,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.549036},1.0,{0.085915,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.46745},1.0,{0.257748,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.320318},1.0,{0.429577,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.0812},1.0,{0.601407,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{0.773239,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{-0.94507,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.0812},1.0,{-0.773239,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.320318},1.0,{-0.601407,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.46745},1.0,{-0.429577,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.549036},1.0,{-0.257748,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.575294},1.0,{-0.085915,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.549036},1.0,{0.085915,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.46745},1.0,{0.257748,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.320318},1.0,{0.429577,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.0812},1.0,{0.601407,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{0.773239,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.686804},1.0,{-0.94507,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{-0.773239,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.395824},1.0,{-0.601407,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.56222},1.0,{-0.429577,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.66393},1.0,{-0.257748,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.712523},1.0,{-0.085915,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.712523},1.0,{0.085915,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.66393},1.0,{0.257748,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.56222},1.0,{0.429577,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.395824},1.0,{0.601407,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{0.773239,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.686804},1.0,{0.94507,0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.686804},1.0,{-0.94507,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{-0.773239,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.395824},1.0,{-0.601407,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.56222},1.0,{-0.429577,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.66393},1.0,{-0.257748,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.712523},1.0,{-0.085915,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.712523},1.0,{0.085915,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.66393},1.0,{0.257748,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.56222},1.0,{0.429577,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.395824},1.0,{0.601407,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.136681},1.0,{0.773239,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.686804},1.0,{0.94507,0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.429625},1.0,{-0.429577,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{-0.257748,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.716042},1.0,{-0.085915,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{0.085915,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.429625},1.0,{0.257748,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.248044},1.0,{-0.085915,1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.248044},1.0,{0.085915,1.121112,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{0,-1.092275,0.444444},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{-0.249781,-1.092275,0.391746},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{-0.436152,-1.092275,0.251926},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{-0.507475,-1.092275,-0.237484},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{-0.436152,-1.092275,-0.251926},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{-0.249781,-1.092275,-0.391746},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{0,-1.092275,-0.444444},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{0.249781,-1.092275,-0.391746},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{0.436152,-1.092275,-0.251926},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{0.507475,-1.092275,-0.237484},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{0.436152,-1.092275,0.251926},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{0.249781,-1.092275,0.391746},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.170856,-0.723424,0.588905},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.468638,-0.723424,0.465028},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.644988,-0.723424,0.285816},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.644988,-0.723424,-0.285816},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.468638,-0.723424,-0.465028},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.170856,-0.723424,-0.588905},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.170856,-0.723424,-0.588905},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.468638,-0.723424,-0.465028},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.644988,-0.723424,-0.285816},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.644988,-0.723424,0.285816},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.468638,-0.723424,0.465028},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.170856,-0.723424,0.588905},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.085915,-0.219014,0.808475},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.537597,-0.219014,0.679839},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.871772,-0.219014,0.555042},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.997193,-0.219014,-0.328131},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.871772,-0.219014,-0.555042},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.537597,-0.219014,-0.679839},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.085915,-0.219014,-0.808475},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.365766,-0.219014,-0.679839},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.69994,-0.219014,-0.555042},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.825362,-0.219014,-0.328131},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.69994,-0.219014,0.555042},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.365766,-0.219014,0.679839},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.254464,0.326436,0.85253},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.697063,0.326436,0.715772},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.957025,0.326436,0.351895},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.957025,0.326436,-0.351895},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.697063,0.326436,-0.715772},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.254464,0.326436,-0.85253},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{0.254464,0.326436,-0.85253},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.697063,0.326436,-0.715772},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.957025,0.326436,-0.351895},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.957025,0.326436,0.351895},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.697063,0.326436,0.715772},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.254464,0.326436,0.85253},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.085915,0.810715,0.378849},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.295316,0.810715,0.347812},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.452127,0.810715,0.229255},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.512628,0.810715,-0.214813},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},3.0,{-0.452127,0.810715,-0.229255},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{-0.295316,0.810715,-0.347812},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{-0.085915,0.810715,-0.378849},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.123485,0.810715,-0.347812},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.280296,0.810715,-0.229255},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},2.0,{0.340799,0.810715,-0.214813},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.280296,0.810715,0.229255},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'metal',0,0},{'box','GildedPlate',{0.381846,0.32399,0.10414},4.0,{0.123485,0.810715,0.347812},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{-0.045442,1.113619,0.144586},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{-0.125999,1.113619,0.141881},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{-0.176936,1.113619,0.132515},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{-0.176936,1.113619,-0.132515},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{-0.125999,1.113619,-0.141881},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{-0.045442,1.113619,-0.144586},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{0.045442,1.113619,-0.144586},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},3.0,{0.125999,1.113619,-0.141881},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{0.176936,1.113619,-0.132515},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{0.176936,1.113619,0.132515},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},2.0,{0.125999,1.113619,0.141881},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'metal',0,0},{'box','GildedPlate',{0.29275,0.32399,0.10414},4.0,{0.045442,1.113619,0.144586},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'metal',0,0},{'box','HolyRuneStem',{0.151869,1.643096,0.086782},9.0,{0,0.057856,-0.890975},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','HolyRuneCross',{0.141748,0.786836,0.080999},9.0,{0,0.115711,-0.937259},{0,1.0,0,-1.0,0,0,0,0,1.0},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7.0,{-0.037606,0.936939,-0.809014},{1.0,0,0,0,0.948683,-0.316228,0,0.316228,0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7.0,{0.037606,0.936939,-0.809014},{0,0,1.0,0.316228,0.948683,0,-0.948683,0.316228,0},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7.0,{0.037606,0.960724,-0.880367},{-1.0,0,0,0,0.948683,0.316228,0,0.316228,-0.948683},'neon',0,0},{'corner','RuneUpperPoint',{0.075213,0.292729,0.075213},7.0,{-0.037606,0.960724,-0.880367},{0,0,-1.0,-0.316228,0.948683,0,0.948683,0.316228,0},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7.0,{0.037606,-0.843674,-0.788738},{-1.0,0,0,0,-0.872506,0.488603,0,0.488603,0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7.0,{-0.037606,-0.843674,-0.788738},{0,0,-1.0,-0.488603,-0.872506,0,-0.872506,0.488603,0},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7.0,{-0.037606,-0.880422,-0.854361},{1.0,0,0,0,-0.872506,-0.488603,0,0.488603,-0.872506},'neon',0,0},{'corner','RuneLowerPoint',{0.075213,0.331549,0.075213},7.0,{0.037606,-0.880422,-0.854361},{0,0,1.0,0.488603,-0.872506,0,0.872506,0.488603,0},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.568699,1.619955,0.07487},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.529942,1.619955,0.219509},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.455072,1.619955,0.349189},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.349189,1.619955,0.455072},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.219509,1.619955,0.529942},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.07487,1.619955,0.568699},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.07487,1.619955,0.568699},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.219509,1.619955,0.529942},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.349189,1.619955,0.455072},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.455072,1.619955,0.349189},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.529942,1.619955,0.219509},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.568699,1.619955,0.07487},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.568699,1.619955,-0.07487},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.529942,1.619955,-0.219509},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.455072,1.619955,-0.349189},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.349189,1.619955,-0.455072},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.219509,1.619955,-0.529942},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{-0.07487,1.619955,-0.568699},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.07487,1.619955,-0.568699},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.219509,1.619955,-0.529942},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.349189,1.619955,-0.455072},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.455072,1.619955,-0.349189},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.529942,1.619955,-0.219509},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.099972,0.151033,0.05554},10.0,{0.568699,1.619955,-0.07487},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5.0,{-0.555412,1.492674,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5.0,{0.555412,1.492674,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5.0,{0,1.492674,0.555412},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','HaloDroplet',{0.05207,0.161995,0.05207},5.0,{0,1.492674,-0.555412},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},11.0,{-0.05207,1.805092,0.05207},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},11.0,{0.05207,1.805092,0.05207},{0,0,1.0,0,1.0,0,-1.0,0,0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},11.0,{0.05207,1.805092,-0.05207},{-1.0,0,0,0,1.0,0,0,0,-1.0},'metal',0,0},{'corner','HaloStar',{0.10414,0.41656,0.10414},11.0,{-0.05207,1.805092,-0.05207},{0,0,-1.0,0,1.0,0,1.0,0,0},'metal',0,0},{'box','OriginalShellCell',{0.17183,0.280279,0.624231},1.0,{0.94507,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,1.022712},1.0,{0.773239,-0.560556,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{0.94507,-0.280279,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.656264},1.0,{0.94507,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','OriginalShellCell',{0.17183,0.280279,0.429625},1.0,{0.429577,0.840834,0},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0.03},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.7775,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-0.8925,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.0075,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.1225,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.2375,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.3525,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.3525,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.4675,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.4675,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.4675,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.4675,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.4675,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.5825,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.5825,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.5825,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.5825,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.5825,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.6975,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.6975,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.8125,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.8125,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.8125,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.8125,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.8125,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.8125,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-1.9275,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.9275,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.9275,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-1.9275,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.0425,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-2.0425,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-2.0425,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-2.0425,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.1575,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-2.1575,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.2725,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{-2.2725,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{-2.3875,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.7775,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{0.8925,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.0075,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.1225,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.2375,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.3525,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.3525,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.4675,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.4675,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.4675,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.4675,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.4675,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.5825,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.5825,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.5825,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.5825,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.5825,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.6975,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.6975,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.8125,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.8125,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.8125,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.8125,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.8125,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.8125,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{1.9275,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.9275,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.9275,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{1.9275,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.0425,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{2.0425,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{2.0425,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{2.0425,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.1575,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{2.1575,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.2725,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},5,{2.2725,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelWingTile',{0.14,0.14,0.14},6,{2.3875,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.62,0.27,0.06},5,{-1.28,0.55,-0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.62,0.27,0.06},5,{-1.28,0.55,0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},5,{-1.68,0.48,-0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},5,{-1.68,0.48,0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},6,{-2.08,0.34,-0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},6,{-2.08,0.34,0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.66,0.27,0.06},6,{-2.48,0.16,-0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.66,0.27,0.06},6,{-2.48,0.16,0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.58,0.27,0.06},6,{-2.86,-0.02,-0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.58,0.27,0.06},6,{-2.86,-0.02,0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.62,0.27,0.06},5,{1.28,0.55,-0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.62,0.27,0.06},5,{1.28,0.55,0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},5,{1.68,0.48,-0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},5,{1.68,0.48,0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},6,{2.08,0.34,-0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.7,0.27,0.06},6,{2.08,0.34,0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.66,0.27,0.06},6,{2.48,0.16,-0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.66,0.27,0.06},6,{2.48,0.16,0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.58,0.27,0.06},6,{2.86,-0.02,-0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.58,0.27,0.06},6,{2.86,-0.02,0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.38,0.2,0.06},5,{-1.02,0.37,-0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.38,0.2,0.06},5,{-1.02,0.37,0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{-1.29,0.31,-0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{-1.29,0.31,0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{-1.56,0.22,-0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{-1.56,0.22,0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.4,0.2,0.06},6,{-1.83,0.1,-0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.4,0.2,0.06},6,{-1.83,0.1,0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.34,0.2,0.06},6,{-2.08,-0.03,-0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.34,0.2,0.06},6,{-2.08,-0.03,0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.38,0.2,0.06},5,{1.02,0.37,-0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.38,0.2,0.06},5,{1.02,0.37,0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{1.29,0.31,-0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{1.29,0.31,0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{1.56,0.22,-0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.43,0.2,0.06},5,{1.56,0.22,0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.4,0.2,0.06},6,{1.83,0.1,-0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.4,0.2,0.06},6,{1.83,0.1,0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.34,0.2,0.06},6,{2.08,-0.03,-0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ArchangelFeatherPlate',{0.34,0.2,0.06},6,{2.08,-0.03,0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0}},bounds={4.375,3.274624,1.912004}},
['World Burner Egg']={palette={{49.0,14.0,25.0},{101.0,29.0,43.0},{78.0,22.0,36.0},{53.0,15.0,27.0},{113.0,38.0,55.0},{239.0,88.0,117.0},{38.0,17.0,24.0},{82.0,21.0,37.0},{32.0,15.0,21.0},{91.0,79.0,85.0},{83.0,75.0,85.0},{113.0,105.0,118.0},{244.0,79.0,111.0},{82.0,22.0,36.0},{102.0,27.0,43.0},{54.0,15.0,27.0},{67.0,18.0,30.0},{255.0,70.0,117.0},{112.0,22.0,43.0},{151.0,35.0,58.0},{255.0,91.0,132.0},{135.0,24.0,46.0},{171.0,37.0,61.0},{64.0,17.0,26.0},{86.0,21.0,31.0},{143.0,31.0,47.0},{248.0,55.0,78.0},{47.0,11.0,19.0},{78.0,17.0,28.0},{101.0,22.0,34.0},{77.0,16.0,27.0},{43.0,10.0,17.0},{113.0,23.0,37.0},{157.0,31.0,47.0},{174.0,168.0,180.0},{112.0,108.0,120.0},{255.0,58.0,112.0},{104.0,24.0,38.0},{255.0,72.0,112.0},{112.0,24.0,36.0},{83.0,17.0,28.0},{35.0,8.0,15.0},{61.0,12.0,22.0},{132.0,30.0,44.0},{72.0,13.0,25.0},{29.0,6.0,13.0},{40.0,8.0,16.0},{100.0,20.0,34.0},{30,7,14},{96,19,33},{126,26,41},{47,10,19},{69,13,25}},parts={{'box','WorldBurnerFeatherPlate',{0.62,0.27,0.06},33.0,{-1.28,0.55,-0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.62,0.27,0.06},33.0,{-1.28,0.55,0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},31.0,{-1.68,0.48,-0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},31.0,{-1.68,0.48,0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},33.0,{-2.08,0.34,-0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},33.0,{-2.08,0.34,0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.66,0.27,0.06},31.0,{-2.48,0.16,-0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.66,0.27,0.06},31.0,{-2.48,0.16,0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.58,0.27,0.06},33.0,{-2.86,-0.02,-0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.58,0.27,0.06},33.0,{-2.86,-0.02,0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.62,0.27,0.06},33.0,{1.28,0.55,-0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.62,0.27,0.06},33.0,{1.28,0.55,0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},31.0,{1.68,0.48,-0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},31.0,{1.68,0.48,0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},33.0,{2.08,0.34,-0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.7,0.27,0.06},33.0,{2.08,0.34,0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.66,0.27,0.06},31.0,{2.48,0.16,-0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.66,0.27,0.06},31.0,{2.48,0.16,0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.58,0.27,0.06},33.0,{2.86,-0.02,-0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.58,0.27,0.06},33.0,{2.86,-0.02,0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,-0.4,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0.4,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossBar',{0.62,0.17,0.1},37.0,{0,0,-0.825},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,-0.4,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0.4,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossBar',{0.62,0.17,0.1},37.0,{0,0,0.825},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'ball','EggShell',{2.08,2.38,1.34},28.0,{0,0,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',1,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.7775,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.7775,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.7775,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.7775,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.7775,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.7775,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.7775,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.7775,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.8925,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.8925,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.8925,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.8925,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.8925,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.8925,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-0.8925,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-0.8925,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-0.8925,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-0.8925,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.0075,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.0075,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.0075,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.0075,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.0075,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.0075,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.0075,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.1225,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.1225,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.1225,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.1225,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.1225,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.1225,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.2375,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.2375,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.2375,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.2375,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.2375,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.2375,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.2375,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.3525,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.3525,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.3525,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.3525,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.3525,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.3525,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.4675,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.4675,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.4675,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.4675,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.4675,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.4675,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.5825,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.5825,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.5825,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.5825,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.5825,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.5825,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.5825,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.5825,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.6975,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.6975,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.6975,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.6975,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.6975,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.6975,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.6975,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.8125,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.8125,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.9275,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-1.9275,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.9275,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-1.9275,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-1.9275,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.9275,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-1.9275,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.0425,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.0425,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.0425,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.0425,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-2.0425,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-2.0425,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.1575,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.1575,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.1575,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.1575,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.1575,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.1575,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-2.2725,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.2725,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.2725,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.2725,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.2725,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.2725,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.2725,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{-2.2725,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-2.2725,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-2.2725,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.3875,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.3875,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.3875,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.3875,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.3875,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.3875,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{-2.3875,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{-2.3875,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-2.3875,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{-2.3875,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.7775,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.7775,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.7775,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.7775,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.7775,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.7775,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.7775,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.7775,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.8925,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.8925,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.8925,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.8925,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.8925,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.8925,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{0.8925,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{0.8925,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{0.8925,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{0.8925,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.0075,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.0075,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.0075,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.0075,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.0075,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.0075,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.0075,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.1225,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.1225,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.1225,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.1225,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.1225,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.1225,0.9475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.2375,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.2375,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.2375,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.2375,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.2375,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.2375,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.2375,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.3525,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.3525,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.3525,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.3525,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.3525,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.3525,0.8325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.4675,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.4675,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.4675,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.4675,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.4675,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.4675,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.5825,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.5825,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.5825,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.5825,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.5825,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.5825,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.5825,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.5825,0.7175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.6975,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.6975,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.6975,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.6975,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.6975,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.6975,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.6975,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.8125,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.8125,0.6025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.9275,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{1.9275,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.9275,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{1.9275,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{1.9275,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.9275,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{1.9275,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.0425,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.0425,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.0425,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.0425,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{2.0425,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{2.0425,0.4875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,-0.8925,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.1575,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.1575,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.1575,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.1575,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.1575,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.1575,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{2.2725,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.2725,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.2725,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.2725,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.2725,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.2725,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.2725,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},34.0,{2.2725,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{2.2725,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{2.2725,0.3725,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.3875,-0.7775,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.3875,-0.6625,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.3875,-0.5475,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.3875,-0.4325,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.3875,-0.3175,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.3875,-0.2025,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},32.0,{2.3875,-0.0875,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},31.0,{2.3875,0.0275,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{2.3875,0.1425,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerBatWingTile',{0.14,0.14,0.14},33.0,{2.3875,0.2575,0.132},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.38,0.2,0.06},33.0,{-1.02,0.37,-0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.38,0.2,0.06},33.0,{-1.02,0.37,0.075},{0.866025,-0.5,0,0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},31.0,{-1.29,0.31,-0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},31.0,{-1.29,0.31,0.075},{0.920505,-0.390731,0,0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},33.0,{-1.56,0.22,-0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},33.0,{-1.56,0.22,0.075},{0.965926,-0.258819,0,0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.4,0.2,0.06},31.0,{-1.83,0.1,-0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.4,0.2,0.06},31.0,{-1.83,0.1,0.075},{0.996195,-0.087156,0,0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.34,0.2,0.06},33.0,{-2.08,-0.03,-0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.34,0.2,0.06},33.0,{-2.08,-0.03,0.075},{0.992546,0.121869,0,-0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.38,0.2,0.06},33.0,{1.02,0.37,-0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.38,0.2,0.06},33.0,{1.02,0.37,0.075},{0.866025,0.5,0,-0.5,0.866025,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},31.0,{1.29,0.31,-0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},31.0,{1.29,0.31,0.075},{0.920505,0.390731,0,-0.390731,0.920505,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},33.0,{1.56,0.22,-0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.43,0.2,0.06},33.0,{1.56,0.22,0.075},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.4,0.2,0.06},31.0,{1.83,0.1,-0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.4,0.2,0.06},31.0,{1.83,0.1,0.075},{0.996195,0.087156,0,-0.087156,0.996195,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.34,0.2,0.06},33.0,{2.08,-0.03,-0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','WorldBurnerFeatherPlate',{0.34,0.2,0.06},33.0,{2.08,-0.03,0.075},{0.992546,-0.121869,0,0.121869,0.992546,0,0,0,1.0},'slate',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.77,-0.01,-0.785},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.765158,0.050461,-0.785},{-0.158629,-0.987338,0,0.987338,-0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.750694,0.110161,-0.785},{-0.30948,-0.950906,0,0.950906,-0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.72679,0.168351,-0.785},{-0.446464,-0.894802,0,0.894802,-0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.693746,0.224297,-0.785},{-0.566075,-0.824354,0,0.824354,-0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.651978,0.277297,-0.785},{-0.667304,-0.744785,0,0.744785,-0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.60201,0.326684,-0.785},{-0.750937,-0.660374,0,0.660374,-0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.544472,0.371838,-0.785},{-0.818732,-0.574176,0,0.574176,-0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.480087,0.412189,-0.785},{-0.872779,-0.488116,0,0.488116,-0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.409665,0.447231,-0.785},{-0.915094,-0.403241,0,0.403241,-0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.33409,0.476523,-0.785},{-0.947427,-0.319972,0,0.319972,-0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.254315,0.499697,-0.785},{-0.971186,-0.238324,0,0.238324,-0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.171341,0.516461,-0.785},{-0.98743,-0.158055,0,0.158055,-0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.086213,0.526605,-0.785},{-0.996893,-0.078772,0,0.078772,-0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0,0.53,-0.785},{-1.0,0,0,0,-1.0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.086213,0.526605,-0.785},{-0.996893,0.078772,0,-0.078772,-0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.171341,0.516461,-0.785},{-0.98743,0.158055,0,-0.158055,-0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.254315,0.499697,-0.785},{-0.971186,0.238324,0,-0.238324,-0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.33409,0.476523,-0.785},{-0.947427,0.319972,0,-0.319972,-0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.409665,0.447231,-0.785},{-0.915094,0.403241,0,-0.403241,-0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.480087,0.412189,-0.785},{-0.872779,0.488116,0,-0.488116,-0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.544472,0.371838,-0.785},{-0.818732,0.574176,0,-0.574176,-0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.60201,0.326684,-0.785},{-0.750937,0.660374,0,-0.660374,-0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.651978,0.277297,-0.785},{-0.667304,0.744785,0,-0.744785,-0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.693746,0.224297,-0.785},{-0.566075,0.824354,0,-0.824354,-0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.72679,0.168351,-0.785},{-0.446464,0.894802,0,-0.894802,-0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.750694,0.110161,-0.785},{-0.30948,0.950906,0,-0.950906,-0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.765158,0.050461,-0.785},{-0.158629,0.987338,0,-0.987338,-0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.77,-0.01,-0.785},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.765158,-0.070461,-0.785},{0.158629,0.987338,0,-0.987338,0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.750694,-0.130161,-0.785},{0.30948,0.950906,0,-0.950906,0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.72679,-0.188351,-0.785},{0.446464,0.894802,0,-0.894802,0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.693746,-0.244297,-0.785},{0.566075,0.824354,0,-0.824354,0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.651978,-0.297297,-0.785},{0.667304,0.744785,0,-0.744785,0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.60201,-0.346684,-0.785},{0.750937,0.660374,0,-0.660374,0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.544472,-0.391838,-0.785},{0.818732,0.574176,0,-0.574176,0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.480087,-0.432189,-0.785},{0.872779,0.488116,0,-0.488116,0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.409665,-0.467231,-0.785},{0.915094,0.403241,0,-0.403241,0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.33409,-0.496523,-0.785},{0.947427,0.319972,0,-0.319972,0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.254315,-0.519697,-0.785},{0.971186,0.238324,0,-0.238324,0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.171341,-0.536461,-0.785},{0.98743,0.158055,0,-0.158055,0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.086213,-0.546605,-0.785},{0.996893,0.078772,0,-0.078772,0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0,-0.55,-0.785},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.086213,-0.546605,-0.785},{0.996893,-0.078772,0,0.078772,0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.171341,-0.536461,-0.785},{0.98743,-0.158055,0,0.158055,0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.254315,-0.519697,-0.785},{0.971186,-0.238324,0,0.238324,0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.33409,-0.496523,-0.785},{0.947427,-0.319972,0,0.319972,0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.409665,-0.467231,-0.785},{0.915094,-0.403241,0,0.403241,0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.480087,-0.432189,-0.785},{0.872779,-0.488116,0,0.488116,0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.544472,-0.391838,-0.785},{0.818732,-0.574176,0,0.574176,0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.60201,-0.346684,-0.785},{0.750937,-0.660374,0,0.660374,0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.651978,-0.297297,-0.785},{0.667304,-0.744785,0,0.744785,0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.693746,-0.244297,-0.785},{0.566075,-0.824354,0,0.824354,0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.72679,-0.188351,-0.785},{0.446464,-0.894802,0,0.894802,0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.750694,-0.130161,-0.785},{0.30948,-0.950906,0,0.950906,0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.765158,-0.070461,-0.785},{0.158629,-0.987338,0,0.987338,0.158629,0,0,0,1.0},'metal',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,-0.4,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0.4,-0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossBar',{0.62,0.17,0.1},37.0,{0,0,-0.825},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.77,-0.01,0.785},{0,-1.0,0,1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.765158,0.050461,0.785},{-0.158629,-0.987338,0,0.987338,-0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.750694,0.110161,0.785},{-0.30948,-0.950906,0,0.950906,-0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.72679,0.168351,0.785},{-0.446464,-0.894802,0,0.894802,-0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.693746,0.224297,0.785},{-0.566075,-0.824354,0,0.824354,-0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.651978,0.277297,0.785},{-0.667304,-0.744785,0,0.744785,-0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.60201,0.326684,0.785},{-0.750937,-0.660374,0,0.660374,-0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.544472,0.371838,0.785},{-0.818732,-0.574176,0,0.574176,-0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.480087,0.412189,0.785},{-0.872779,-0.488116,0,0.488116,-0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.409665,0.447231,0.785},{-0.915094,-0.403241,0,0.403241,-0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.33409,0.476523,0.785},{-0.947427,-0.319972,0,0.319972,-0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.254315,0.499697,0.785},{-0.971186,-0.238324,0,0.238324,-0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.171341,0.516461,0.785},{-0.98743,-0.158055,0,0.158055,-0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.086213,0.526605,0.785},{-0.996893,-0.078772,0,0.078772,-0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0,0.53,0.785},{-1.0,0,0,0,-1.0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.086213,0.526605,0.785},{-0.996893,0.078772,0,-0.078772,-0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.171341,0.516461,0.785},{-0.98743,0.158055,0,-0.158055,-0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.254315,0.499697,0.785},{-0.971186,0.238324,0,-0.238324,-0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.33409,0.476523,0.785},{-0.947427,0.319972,0,-0.319972,-0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.409665,0.447231,0.785},{-0.915094,0.403241,0,-0.403241,-0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.480087,0.412189,0.785},{-0.872779,0.488116,0,-0.488116,-0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.544472,0.371838,0.785},{-0.818732,0.574176,0,-0.574176,-0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.60201,0.326684,0.785},{-0.750937,0.660374,0,-0.660374,-0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.651978,0.277297,0.785},{-0.667304,0.744785,0,-0.744785,-0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.693746,0.224297,0.785},{-0.566075,0.824354,0,-0.824354,-0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.72679,0.168351,0.785},{-0.446464,0.894802,0,-0.894802,-0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.750694,0.110161,0.785},{-0.30948,0.950906,0,-0.950906,-0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.765158,0.050461,0.785},{-0.158629,0.987338,0,-0.987338,-0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.77,-0.01,0.785},{0,1.0,0,-1.0,0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.765158,-0.070461,0.785},{0.158629,0.987338,0,-0.987338,0.158629,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.750694,-0.130161,0.785},{0.30948,0.950906,0,-0.950906,0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.72679,-0.188351,0.785},{0.446464,0.894802,0,-0.894802,0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.693746,-0.244297,0.785},{0.566075,0.824354,0,-0.824354,0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.651978,-0.297297,0.785},{0.667304,0.744785,0,-0.744785,0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.60201,-0.346684,0.785},{0.750937,0.660374,0,-0.660374,0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.544472,-0.391838,0.785},{0.818732,0.574176,0,-0.574176,0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.480087,-0.432189,0.785},{0.872779,0.488116,0,-0.488116,0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.409665,-0.467231,0.785},{0.915094,0.403241,0,-0.403241,0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.33409,-0.496523,0.785},{0.947427,0.319972,0,-0.319972,0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.254315,-0.519697,0.785},{0.971186,0.238324,0,-0.238324,0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{-0.171341,-0.536461,0.785},{0.98743,0.158055,0,-0.158055,0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{-0.086213,-0.546605,0.785},{0.996893,0.078772,0,-0.078772,0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0,-0.55,0.785},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.086213,-0.546605,0.785},{0.996893,-0.078772,0,0.078772,0.996893,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.171341,-0.536461,0.785},{0.98743,-0.158055,0,0.158055,0.98743,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.254315,-0.519697,0.785},{0.971186,-0.238324,0,0.238324,0.971186,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.33409,-0.496523,0.785},{0.947427,-0.319972,0,0.319972,0.947427,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.409665,-0.467231,0.785},{0.915094,-0.403241,0,0.403241,0.915094,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.480087,-0.432189,0.785},{0.872779,-0.488116,0,0.488116,0.872779,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.544472,-0.391838,0.785},{0.818732,-0.574176,0,0.574176,0.818732,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.60201,-0.346684,0.785},{0.750937,-0.660374,0,0.660374,0.750937,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.651978,-0.297297,0.785},{0.667304,-0.744785,0,0.744785,0.667304,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},35.0,{0.693746,-0.244297,0.785},{0.566075,-0.824354,0,0.824354,0.566075,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.72679,-0.188351,0.785},{0.446464,-0.894802,0,0.894802,0.446464,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.750694,-0.130161,0.785},{0.30948,-0.950906,0,0.950906,0.30948,0,0,0,1.0},'metal',0,0},{'box','ChainLink',{0.13,0.075,0.065},36.0,{0.765158,-0.070461,0.785},{0.158629,-0.987338,0,0.987338,0.158629,0,0,0,1.0},'metal',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,-0.4,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossStem',{0.22,0.48,0.09},37.0,{0,0.4,0.805},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','BurnerCrossBar',{0.62,0.17,0.1},37.0,{0,0,0.825},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'wedge','DemonHorn',{0.24,0.46,0.2},38.0,{-0.18,1.32,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','HornGlow',{0.07,0.09,0.12},39.0,{-0.18,1.49,0},{0.951057,0.309017,0,-0.309017,0.951057,0,0,0,1.0},'neon',0,0},{'wedge','DemonHorn',{0.24,0.46,0.2},38.0,{0.18,1.32,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','HornGlow',{0.07,0.09,0.12},39.0,{0.18,1.49,0},{0.951057,-0.309017,0,0.309017,0.951057,0,0,0,1.0},'neon',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,-1.08,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,-1.08,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-1.08,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,-0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,-0.9,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,-0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,-0.9,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,-0.72,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,-0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,-0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,-0.72,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,-0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,-0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,-0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,-0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,-0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,-0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,-0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,-0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,-0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.84,-0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.84,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,-0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,-0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,-0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,-0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.84,-0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,0,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,0,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.84,0,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,0.18,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0.18,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.84,0.18,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.84,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,0.36,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0.36,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.84,0.36,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.54,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.54,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,0.54,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,0.72,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,0.72,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.72,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,0.72,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,0.9,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,0.9,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.9,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.9,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,1.08,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,1.08,-0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,1.08,-0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,1.08,-0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,-1.08,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,-1.08,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-1.08,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,-0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,-0.9,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,-0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,-0.9,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,-0.72,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,-0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,-0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,-0.72,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,-0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,-0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,-0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,-0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,-0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,-0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,-0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,-0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,-0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.84,-0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.84,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,-0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,-0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,-0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,-0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.84,-0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,0,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,0,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.84,0,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.84,0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,0.18,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0.18,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.84,0.18,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.84,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.84,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.63,0.36,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.84,0.36,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.84,0.36,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.63,0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.42,0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.54,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.54,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.63,0.54,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.63,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.63,0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.42,0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{-0.21,0.72,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0,0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{0.42,0.72,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.63,0.72,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},49,{0.63,0.72,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.42,0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{-0.42,0.9,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},52,{-0.21,0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0,0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.21,0.9,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.42,0.9,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},53,{0.42,0.9,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{-0.21,1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{-0.21,1.08,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0,1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},51,{0,1.08,0.6},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockBacking',{0.235,0.205,0.15},49,{0.21,1.08,0.485},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerBlockPlate',{0.205,0.17,0.17},50,{0.21,1.08,0.57},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,-0.9,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,-0.9,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,-0.9,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,-0.9,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.435,-0.9,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,-0.72,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.645,-0.72,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.645,-0.72,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,-0.72,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,-0.72,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.825,-0.54,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.825,-0.54,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.825,-0.54,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.825,-0.54,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.825,-0.54,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,-0.36,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,-0.36,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,-0.36,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,-0.36,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.945,-0.36,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,-0.18,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-1.025,-0.18,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-1.025,-0.18,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,-0.18,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,-0.18,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.045,0,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-1.045,0,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-1.045,0,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.045,0,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-1.045,0,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,0.18,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,0.18,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,0.18,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-1.025,0.18,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-1.025,0.18,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,0.36,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.945,0.36,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.945,0.36,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,0.36,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.945,0.36,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.825,0.54,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.825,0.54,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.825,0.54,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.825,0.54,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.825,0.54,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,0.72,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,0.72,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,0.72,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.645,0.72,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{-0.645,0.72,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,0.9,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.435,0.9,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{-0.435,0.9,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,0.9,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{-0.435,0.9,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,-0.9,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,-0.9,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,-0.9,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,-0.9,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.435,-0.9,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,-0.72,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.645,-0.72,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.645,-0.72,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,-0.72,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,-0.72,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.825,-0.54,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.825,-0.54,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.825,-0.54,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.825,-0.54,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.825,-0.54,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,-0.36,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,-0.36,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,-0.36,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,-0.36,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.945,-0.36,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,-0.18,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{1.025,-0.18,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{1.025,-0.18,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,-0.18,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,-0.18,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.045,0,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{1.045,0,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{1.045,0,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.045,0,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{1.045,0,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,0.18,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,0.18,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,0.18,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{1.025,0.18,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{1.025,0.18,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,0.36,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.945,0.36,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.945,0.36,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,0.36,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.945,0.36,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.825,0.54,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.825,0.54,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.825,0.54,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.825,0.54,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.825,0.54,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,0.72,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,0.72,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,0.72,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.645,0.72,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},50,{0.645,0.72,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,0.9,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.435,0.9,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},53,{0.435,0.9,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,0.9,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerSidePlate',{0.205,0.205,0.245},52,{0.435,0.9,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,-0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,-0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,-0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,-0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,-0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,-0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.42,-0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,-0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,-0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.42,-0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,-0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,-0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,-0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,-0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,-0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,-0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,-0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,-0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.42,-0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,-0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,-0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.42,-0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,-0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.99,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.99,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,0.99,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.99,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.99,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.42,0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.42,0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.42,0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{-0.21,0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{-0.21,0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0,0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0,0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.21,0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.21,0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.42,0.79,-0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,0.79,-0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,0.79,0},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},50,{0.42,0.79,0.24},{1,0,0,0,1,0,0,0,1},'slate',0,0},{'box','BurnerEdgePlate',{0.22,0.205,0.245},53,{0.42,0.79,0.48},{1,0,0,0,1,0,0,0,1},'slate',0,0}},bounds={6.2,3.7,2.0}},
['Aetheron Egg']={palette={{203.0,151.0,43.0},{239.0,192.0,65.0},{119.0,18.0,33.0},{232.0,175.0,36.0},{244.0,233.0,186.0},{136.0,20.0,37.0},{94.0,14.0,27.0},{255.0,226.0,82.0},{245.0,234.0,190.0},{99.0,30.0,25.0},{219.0,170.0,42.0},{239.0,192.0,55.0},{199.0,145.0,30.0},{174.0,28.0,38.0},{137.0,20.0,30.0},{205.0,43.0,47.0},{225.0,174.0,39.0},{244.0,197.0,55.0},{183.0,132.0,25.0},{157.0,20.0,31.0},{194.0,31.0,43.0},{120.0,15.0,26.0},{223.0,164.0,35.0},{228.0,220.0,194.0},{245.0,239.0,218.0},{247.0,193.0,71.0},{218.0,157.0,40.0},{124.0,116.0,96.0},{121.0,18.0,28.0},{247.0,74.0,68.0},{166.0,25.0,36.0},{223.0,48.0,53.0},{198.0,143.0,34.0},{232.0,176.0,48.0},{247.0,244.0,232.0},{232.0,229.0,214.0},{250.0,248.0,239.0},{236.0,232.0,216.0},{238.0,185.0,56.0},{190.0,132.0,29.0},{126.0,16.0,29.0},{171.0,27.0,39.0},{78.0,11.0,20.0},{255.0,231.0,84.0},{235,232,218}},parts={{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.2,-1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0,-1.4,-0.471457},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.2,-1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-1.2,-0.643474},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-1.0,-0.757286},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,-1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,-0.8,-0.838353},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.4,-0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,-0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,-0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,-0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.6,-0.896083},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,-0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.4,-0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.4,-0.935029},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,-0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.2,-0.9576},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,-0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,0,-0.576383},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0,-0.772415},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0,-0.884876},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0,-0.945638},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,0,-0.965},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0,-0.945638},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0,-0.884876},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0,-0.772415},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0,-0.576383},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.2,-0.9576},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.4,-0.935029},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.4,0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.6,-0.896083},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.4,0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,0.8,-0.838353},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,1.0,-0.757286},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,1.2,-0.643474},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.2,1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0,1.4,-0.471457},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.2,1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.2,-1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0,-1.4,0.471457},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.2,-1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-1.2,0.643474},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-1.0,0.757286},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,-1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,-0.8,0.838353},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.4,-0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,-0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,-0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,-0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.6,0.896083},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,-0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.4,-0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.4,0.935029},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,-0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,-0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,-0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,-0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,-0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,-0.2,0.9576},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,-0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,-0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,-0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,0,0.576383},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0,0.772415},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0,0.884876},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0,0.945638},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,0,0.965},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0,0.945638},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0,0.884876},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0,0.772415},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0,0.576383},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.2,0.9576},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.4,0.935029},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.4,0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.8,0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,0.6,0.896083},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0.2,0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.8,0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.4,0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{0,0.8,0.838353},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},36.0,{-0.2,1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,1.0,0.757286},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.6,1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{-0.2,1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0,1.2,0.643474},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},35.0,{0.2,1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.6,1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.4,1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{-0.2,1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0,1.4,0.471457},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.2,1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},33.0,{0.4,1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1.0},'metal',0,0},{'ball','EggShell',{1.96,3.16,1.84},45.0,{0,0,0},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,-1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,-1.4,-0.471457},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-1.2,-0.643474},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-1.0,-0.757286},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,-0.8,-0.838353},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,-0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,-0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.6,-0.896083},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,-0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.4,-0.935029},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,-0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.2,-0.9576},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0,-0.576383},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0,-0.772415},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0,-0.884876},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0,-0.945638},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,0,-0.965},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0,-0.945638},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0,-0.884876},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0,-0.772415},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0,-0.576383},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.2,-0.9576},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.2,-0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.2,-0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.2,-0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.2,-0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.4,-0.935029},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.4,-0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.4,-0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.4,-0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.4,-0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.6,-0.896083},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,0.6,-0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.6,-0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,0.6,-0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.6,-0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,0.8,-0.838353},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.8,-0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.8,-0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.8,-0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.8,-0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,1.0,-0.757286},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,1.0,-0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.0,-0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,1.0,-0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,1.2,-0.643474},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,1.2,-0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.2,-0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,1.2,-0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,1.4,-0.471457},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,1.4,-0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.4,-0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,-1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,-1.4,0.471457},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-1.2,0.643474},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-1.0,0.757286},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,-0.8,0.838353},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,-0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,-0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.6,0.896083},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,-0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,-0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.4,0.935029},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,-0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,-0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,-0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,-0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,-0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,-0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,-0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,-0.2,0.9576},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,-0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,-0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,-0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,-0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0,0.576383},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0,0.772415},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0,0.884876},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0,0.945638},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,0,0.965},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0,0.945638},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0,0.884876},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0,0.772415},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0,0.576383},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.2,0.9576},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.2,0.938077},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.2,0.876763},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.2,0.763032},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.2,0.563465},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.4,0.935029},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.4,0.915},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.4,0.851935},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.4,0.734119},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.8,0.4,0.52262},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{-0.8,0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,0.6,0.896083},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,0.6,0.875115},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.6,0.808764},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{0.6,0.6,0.683024},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.6,0.445389},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.8,0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,0.8,0.838353},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,0.8,0.815816},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,0.8,0.743857},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,0.8,0.603696},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},40.0,{0.8,0.8,0.30069},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},34.0,{-0.6,1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,1.0,0.757286},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,1.0,0.732095},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.0,0.650263},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,1.0,0.480986},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.6,1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{-0.2,1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0,1.2,0.643474},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},37.0,{0.2,1.2,0.613259},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.2,0.511007},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.6,1.2,0.247244},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.4,1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{-0.2,1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0,1.4,0.471457},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.2,1.4,0.427901},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronShellFacet',{0.205,0.205,0.13},45.0,{0.4,1.4,0.247133},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-0.85,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-0.85,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-0.85,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-0.85,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.03,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.03,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.03,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.03,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.03,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.03,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.03,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.21,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.21,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.21,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.21,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.21,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.21,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.21,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.21,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-1.21,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.21,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.21,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.39,-0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.39,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.39,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.39,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.39,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.39,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.39,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-1.39,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.39,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,-0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,-0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.57,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.57,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.57,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-1.57,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.57,1.71,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,-0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.75,-0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.75,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.75,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-1.75,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.75,1.71,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,-0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-1.93,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-1.93,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-1.93,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-1.93,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.11,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.11,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.11,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.11,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.11,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.11,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.11,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.11,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.11,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-2.11,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.11,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.11,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.29,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.29,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.29,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.29,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.29,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.29,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.29,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-2.29,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.29,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.29,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.47,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.47,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.47,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.47,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.47,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.47,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-2.47,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.47,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.47,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.65,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.65,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.65,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.65,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-2.65,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.65,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.65,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.65,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.83,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.83,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},37.0,{-2.83,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-2.83,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.83,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.83,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.83,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-2.83,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.01,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.01,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.01,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.01,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.01,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-3.01,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.01,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.01,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.01,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.19,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.19,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.19,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},40.0,{-3.19,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.19,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.19,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.19,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.37,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.37,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},38.0,{-3.37,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.37,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.37,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},39.0,{-3.37,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{0.85,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{0.85,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{0.85,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{0.85,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{0.85,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{0.85,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.03,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.03,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.03,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.03,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.03,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.03,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.03,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.03,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.03,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.21,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.21,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.21,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.21,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.21,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.21,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.21,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,-0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.39,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.39,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.39,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.39,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.39,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.39,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.39,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.39,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.57,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.57,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.57,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.57,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.57,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.57,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.57,1.71,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.75,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.75,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.75,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.75,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.75,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.75,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.75,1.71,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.75,1.89,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.93,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.93,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.93,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{1.93,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{1.93,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.93,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{1.93,1.71,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.11,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.11,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.11,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.11,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.11,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.11,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.11,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.11,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.11,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.11,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.11,1.53,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.29,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.29,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.29,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.29,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.29,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.29,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.29,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.29,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.29,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.29,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.29,1.35,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.47,-0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.47,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.47,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.47,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.47,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.47,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.47,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.47,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.47,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.47,1.17,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.65,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.65,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.65,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.65,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.65,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.65,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.65,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.65,0.99,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.83,-0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.83,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.83,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{2.83,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{2.83,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.83,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{2.83,0.81,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{3.01,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{3.01,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{3.01,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.01,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.01,0.63,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},43.0,{3.19,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{3.19,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.19,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.19,0.45,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},41.0,{3.37,-0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.37,0.09,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronWingTile',{0.195,0.195,0.12},42.0,{3.37,0.27,0},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.58,0.25,0.06},37.0,{-1.24,0.33,-0.085},{0.848048,0.529919,0,-0.529919,0.848048,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.58,0.25,0.06},37.0,{-1.24,0.33,0.085},{0.848048,0.529919,0,-0.529919,0.848048,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.67,0.25,0.06},37.0,{-1.62,0.46,-0.085},{0.913545,0.406737,0,-0.406737,0.913545,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.67,0.25,0.06},37.0,{-1.62,0.46,0.085},{0.913545,0.406737,0,-0.406737,0.913545,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.7,0.25,0.06},39.0,{-2.02,0.57,-0.085},{0.970296,0.241922,0,-0.241922,0.970296,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.7,0.25,0.06},39.0,{-2.02,0.57,0.085},{0.970296,0.241922,0,-0.241922,0.970296,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.66,0.25,0.06},39.0,{-2.42,0.61,-0.085},{0.999391,0.034899,0,-0.034899,0.999391,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.66,0.25,0.06},39.0,{-2.42,0.61,0.085},{0.999391,0.034899,0,-0.034899,0.999391,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.56,0.25,0.06},39.0,{-2.8,0.52,-0.085},{0.978148,-0.207912,0,0.207912,0.978148,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.56,0.25,0.06},39.0,{-2.8,0.52,0.085},{0.978148,-0.207912,0,0.207912,0.978148,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.58,0.25,0.06},42.0,{1.24,0.33,-0.085},{0.848048,-0.529919,0,0.529919,0.848048,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.58,0.25,0.06},42.0,{1.24,0.33,0.085},{0.848048,-0.529919,0,0.529919,0.848048,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.67,0.25,0.06},42.0,{1.62,0.46,-0.085},{0.913545,-0.406737,0,0.406737,0.913545,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.67,0.25,0.06},42.0,{1.62,0.46,0.085},{0.913545,-0.406737,0,0.406737,0.913545,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.7,0.25,0.06},42.0,{2.02,0.57,-0.085},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.7,0.25,0.06},42.0,{2.02,0.57,0.085},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.66,0.25,0.06},42.0,{2.42,0.61,-0.085},{0.999391,-0.034899,0,0.034899,0.999391,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.66,0.25,0.06},42.0,{2.42,0.61,0.085},{0.999391,-0.034899,0,0.034899,0.999391,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.56,0.25,0.06},42.0,{2.8,0.52,-0.085},{0.978148,0.207912,0,-0.207912,0.978148,0,0,0,1},'metal',0,0},{'box','AetheronFeatherFacet',{0.56,0.25,0.06},42.0,{2.8,0.52,0.085},{0.978148,0.207912,0,-0.207912,0.978148,0,0,0,1},'metal',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.576938,2.177846,-0.04761},{0,-0.130526,0.991445,1.0,0,0,0,0.991445,0.130526},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.53762,2.177846,0.099123},{0,-0.382683,0.92388,1.0,0,0,0,0.92388,0.382683},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.461665,2.177846,0.230681},{0,-0.608761,0.793353,1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.354248,2.177846,0.338099},{0,-0.793353,0.608761,1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.222688,2.177846,0.414055},{0,-0.92388,0.382683,1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.075954,2.177846,0.453373},{0,-0.991445,0.130526,1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.075954,2.177846,0.453373},{0,-0.991445,-0.130526,1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.222688,2.177846,0.414055},{0,-0.92388,-0.382683,1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.354248,2.177846,0.338099},{0,-0.793353,-0.608761,1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.461665,2.177846,0.230681},{0,-0.608761,-0.793353,1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.53762,2.177846,0.099123},{0,-0.382683,0.92388,-1.0,0,0,0,-0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.576938,2.177846,-0.04761},{0,-0.130526,0.991445,-1.0,0,0,0,-0.991445,-0.130526},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.576938,2.177846,-0.19952},{0,0.130526,0.991445,-1.0,0,0,0,-0.991445,0.130526},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.53762,2.177846,-0.346254},{0,0.382683,0.92388,-1.0,0,0,0,-0.92388,0.382683},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.461665,2.177846,-0.477814},{0,0.608761,0.793353,-1.0,0,0,0,-0.793353,0.608761},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.354248,2.177846,-0.585231},{0,0.793353,0.608761,-1.0,0,0,0,-0.608761,0.793353},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.222688,2.177846,-0.661186},{0,0.92388,0.382683,-1.0,0,0,0,-0.382683,0.92388},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{-0.075954,2.177846,-0.700504},{0,0.991445,0.130526,-1.0,0,0,0,-0.130526,0.991445},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.075954,2.177846,-0.700504},{0,0.991445,-0.130526,-1.0,0,0,0,0.130526,0.991445},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.222688,2.177846,-0.661186},{0,0.92388,-0.382683,-1.0,0,0,0,0.382683,0.92388},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.354248,2.177846,-0.585231},{0,0.793353,-0.608761,-1.0,0,0,0,0.608761,0.793353},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.461665,2.177846,-0.477814},{0,0.608761,-0.793353,-1.0,0,0,0,0.793353,0.608761},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.53762,2.177846,-0.346254},{0,0.382683,0.92388,1.0,0,0,0,0.92388,-0.382683},'neon',0,0},{'box','Halo',{0.069506,0.153222,0.069506},8.0,{0.576938,2.177846,-0.19952},{0,0.130526,0.991445,1.0,0,0,0,0.991445,-0.130526},'neon',0,0},{'corner','AetheronCrownPoint',{0.27,0.72,0.27},37.0,{-0.13,1.72,-0.13},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','AetheronCrownPoint',{0.27,0.72,0.27},37.0,{-0.13,1.72,0.13},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','AetheronCrownPoint',{0.27,0.72,0.27},37.0,{0.13,1.72,-0.13},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','AetheronCrownPoint',{0.27,0.72,0.27},37.0,{0.13,1.72,0.13},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','BasePoint',{0.24,0.68,0.24},45.0,{-0.1,-1.69,-0.1},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','BasePoint',{0.24,0.68,0.24},45.0,{-0.1,-1.69,0.1},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','BasePoint',{0.24,0.68,0.24},45.0,{0.1,-1.69,-0.1},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'corner','BasePoint',{0.24,0.68,0.24},45.0,{0.1,-1.69,0.1},{1,0,0,0,1,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.15,0.38,0.14},37.0,{0,0.22,-1.101038},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.3,0.14},45.0,{-0.17,0.22,-1.086951},{0.882948,0.469472,0,-0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.3,0.14},37.0,{0.17,0.22,-1.086951},{0.882948,-0.469472,0,0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.28,0.14},45.0,{-0.14,-0.08,-1.099372},{0.927184,0.374607,0,-0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.28,0.14},37.0,{0.14,-0.08,-1.099372},{0.927184,-0.374607,0,0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.24,0.14},45.0,{0,-0.3,-1.093264},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{-0.24,0.3,-1.034713},{0.882948,0.469472,0,-0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{0.24,0.3,-1.034713},{0.882948,-0.469472,0,0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{-0.22,-0.12,-1.053791},{0.927184,0.374607,0,-0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{0.22,-0.12,-1.053791},{0.927184,-0.374607,0,0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.15,0.38,0.14},37.0,{0,0.22,1.101038},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.3,0.14},45.0,{-0.17,0.22,1.086951},{0.882948,0.469472,0,-0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.3,0.14},37.0,{0.17,0.22,1.086951},{0.882948,-0.469472,0,0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.28,0.14},45.0,{-0.14,-0.08,1.099372},{0.927184,0.374607,0,-0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.28,0.14},37.0,{0.14,-0.08,1.099372},{0.927184,-0.374607,0,0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronIvoryFeather',{0.13,0.24,0.14},45.0,{0,-0.3,1.093264},{1.0,0,0,0,1.0,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{-0.24,0.3,1.034713},{0.882948,0.469472,0,-0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{0.24,0.3,1.034713},{0.882948,-0.469472,0,0.469472,0.882948,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{-0.22,-0.12,1.053791},{0.927184,0.374607,0,-0.374607,0.927184,0,0,0,1},'metal',0,0},{'box','AetheronGoldQuill',{0.075,0.22,0.1},34.0,{0.22,-0.12,1.053791},{0.927184,-0.374607,0,0.374607,0.927184,0,0,0,1},'metal',0,0}},bounds={7.2,4.4,2.2}},
['Cthulhu Egg']={palette={{11,59,26},{14,66,28},{35,108,49},{25,89,40},{33,48,69},{108,147,70},{113,139,42},{112,255,47},{62,124,32},{5,29,12},{4,32,12}},parts={{'box','EggShell',{0.239011,0.29483,0.900305},1,{-0.956044,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{-1.195055,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{-0.956044,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{-0.717032,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{-0.478021,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{-0.239011,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.401914},1,{0,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.361877},1,{0.239011,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.237481},1,{0.478021,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.013141},1,{0.717032,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.64855},1,{0.956044,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.000631},1,{1.195055,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-1.195055,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.956044,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.717032,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.478021,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{-0.239011,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.239011,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.478021,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.717032,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{0.956044,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{-0.956044,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{-0.956044,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{-0.717032,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{-0.478021,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{-0.239011,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.965201},1,{0,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.916064},1,{0.239011,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.76044},1,{0.478021,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.464775},1,{0.717032,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.900305},1,{0.956044,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-0.956044,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.717032,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.478021,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.239011,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0.239011,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.478021,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.717032,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.956044,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{1.195055,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{-0.956044,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{-0.717032,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{-0.478021,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{-0.239011,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.172613},1,{0.239011,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,2.082981},1,{0.478021,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.891018},1,{0.717032,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,1.559373},1,{0.956044,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.95179},1,{1.195055,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.378202},1,{-0.239011,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.239011,0.29483,0.378202},1,{0,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0,-1.53198,1.011814},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.51507,-1.53198,0.907824},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.896615,-1.53198,0.470407},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.04023,-1.53198,-0.450151},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.896615,-1.53198,-0.470407},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.51507,-1.53198,-0.907824},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0,-1.53198,-1.011814},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.51507,-1.53198,-0.907824},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.896615,-1.53198,-0.470407},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{1.04023,-1.53198,-0.450151},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.896615,-1.53198,0.470407},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.51507,-1.53198,0.907824},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,1.209781},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,0.849325},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,0.512227},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,-0.512227},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,-0.849325},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,-1.209781},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.324456,-1.014644,-1.209781},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,-0.849325},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.220256,-1.014644,-0.512227},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.220256,-1.014644,0.512227},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,0.849325},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.324456,-1.014644,1.209781},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0,-0.30718,1.230169},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.627406,-0.30718,1.034174},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,0.84453},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.2649,-0.30718,-0.500316},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,-0.84453},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.627406,-0.30718,-1.034174},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0,-0.30718,-1.230169},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,-1.034174},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.091186,-0.30718,-0.84453},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.2649,-0.30718,-0.500316},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.091186,-0.30718,0.84453},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,1.034174},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.266308,0.457845,0.986874},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.729926,0.457845,0.757437},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.003241,0.457845,0.462064},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-1.003241,0.457845,-0.462064},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.729926,0.457845,-0.757437},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.266308,0.457845,-0.986874},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.266308,0.457845,-0.986874},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.729926,0.457845,-0.757437},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.003241,0.457845,-0.462064},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.003241,0.457845,0.462064},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.729926,0.457845,0.757437},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.266308,0.457845,0.986874},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.119506,1.137076,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.451732,1.137076,0.973111},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.874395,1.137076,0.49615},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.03306,1.137076,-0.475895},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.874395,1.137076,-0.49615},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.451732,1.137076,-0.973111},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.119506,1.137076,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.690744,1.137076,-0.973111},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{1.113406,1.137076,-0.49615},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.27207,1.137076,-0.475895},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.113406,1.137076,0.49615},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.690744,1.137076,0.973111},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.182292,1.561914,0.217944},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.293401,1.561914,0.214151},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.363194,1.561914,0.201014},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.363194,1.561914,-0.201014},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.293401,1.561914,-0.214151},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.182292,1.561914,-0.217944},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.05672,1.561914,-0.217944},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.054391,1.561914,-0.214151},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.124183,1.561914,-0.201014},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.124183,1.561914,0.201014},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.054391,1.561914,0.214151},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.05672,1.561914,0.217944},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.259665,0.580183,0.259665},5,{-0.835801,-1.395706,-1.23784},{0.483077,-0.811201,-0.329529,0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{-1.071124,-1.265874,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.71353,0.246682},5,{-1.176613,-0.925061,-1.347019},{0.955286,-0.295684,0,0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{-1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.804925,0.2337},5,{-1.257759,-0.186636,-1.289694},{0.998131,0.060487,-0.008704,-0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{-1.233416,0.210979,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.822739,0.220715},5,{-1.079238,0.592364,-1.232369},{0.92711,0.374789,0,-0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{-0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.133868,0.207732},5,{-0.803342,1.298331,-0.783765},{0.936329,0.214696,-0.277836,-0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.681624,1.622914,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{-0.876374,1.850121,-0.335164},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{-1.071124,2.077331,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{-1.257759,1.98807,-0.335164},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{-1.444394,1.89881,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{-1.42005,1.728405,-0.335164},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{-1.395706,1.557999,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{-1.24153,1.517425,-0.335164},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-1.087354,1.476851,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.600477,-1.525539,-1.277971},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.071124,-1.265874,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.233416,0.210979,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.681624,1.622914,-0.484472},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.352071,-0.5307,0.267669},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.285001,-0.365258,0.267669},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.293279,-0.361904,0.089371},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.36035,-0.527345,0.089371},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.390753,0.291331,0.267695},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.312486,0.451781,0.267695},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.319514,0.455209,0.089345},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.397781,0.29476,0.089345},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.427911,1.113131,0.267714},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.341214,1.269187,0.267714},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.347271,1.272552,0.089328},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.43397,1.116498,0.089328},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{-0.681624,1.590456,-0.448769},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.259665,0.580183,0.259665},5,{0.835801,-1.395706,-1.23784},{0.483077,0.811201,0.329529,-0.875578,0.447559,0.181809,0,-0.376356,0.926475},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{1.071124,-1.265874,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.71353,0.246682},5,{1.176613,-0.925061,-1.347019},{0.955286,0.295684,0,-0.295684,0.955286,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.804925,0.2337},5,{1.257759,-0.186636,-1.289694},{0.998131,-0.060487,0.008704,0.06111,0.987954,-0.14217,0,0.142436,0.989804},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{1.233416,0.210979,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.822739,0.220715},5,{1.079238,0.592364,-1.232369},{0.92711,-0.374789,0,0.374789,0.92711,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.133868,0.207732},5,{0.803342,1.298331,-0.783765},{0.936329,-0.214696,0.277836,0.351123,0.572524,-0.740897,0,0.791279,0.611456},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.681624,1.622914,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{0.876374,1.850121,-0.335164},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{1.071124,2.077331,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{1.257759,1.98807,-0.335164},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{1.444394,1.89881,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{1.42005,1.728405,-0.335164},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{1.395706,1.557999,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{1.24153,1.517425,-0.335164},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{1.087354,1.476851,-0.335164},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.600477,-1.525539,-1.277971},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.071124,-1.265874,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.233416,0.210979,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.681624,1.622914,-0.484472},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.285001,-0.365258,0.267669},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.352071,-0.5307,0.267669},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.36035,-0.527345,0.089371},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.293279,-0.361904,0.089371},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.312486,0.451781,0.267695},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.390753,0.291331,0.267695},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.397781,0.29476,0.089345},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.319514,0.455209,0.089345},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.341214,1.269187,0.267714},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.427911,1.113131,0.267714},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.43397,1.116498,0.089328},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.347271,1.272552,0.089328},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{0.681624,1.590456,-0.448769},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.020789,1.98229,0.27125},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.330756,1.918474,0.27125},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.336251,1.945162,-0.044042},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},9,{0.026285,2.00898,-0.044042},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{1.022436,1.574226,0.227208},10,{0,-0.162293,-1.226924},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.068163,0.51038,0.068163},8,{-0.129832,-0.819572,-1.411936},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.068163,0.828322,0.068163},8,{-0.275895,-0.186636,-1.428164},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.640589,0.068163},8,{-0.146062,0.511219,-1.403822},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.068163,0.626452,0.068163},8,{0.129832,0.511219,-1.403822},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.068163,0.827845,0.068163},8,{0.251551,-0.186636,-1.428164},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.502317,0.068163},8,{0.121719,-0.819572,-1.411936},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.17852,1.038665,0.17852},11,{0,-0.129832,-1.395706},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,0.081145,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.535807,0.056801},8,{-0.365156,1.971841,-0.162293},{0.817806,-0.575493,0,0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.347319,0.056801},8,{-0.413844,2.328882,-0.162293},{0.794358,0.60745,0,-0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.23066,0.056801},8,{-0.219094,2.393799,-0.162293},{-0.633238,0.773957,0,-0.773957,-0.633238,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,0.081145,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.535807,0.056801},8,{0.365156,1.971841,-0.162293},{0.817806,0.575493,0,-0.575493,0.817806,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.347319,0.056801},8,{0.413844,2.328882,-0.162293},{0.794358,-0.60745,0,0.60745,0.794358,0,0,0,1.0},'neon',0,0},{'box','CrownWisp',{0.056801,0.23066,0.056801},8,{0.219094,2.393799,-0.162293},{-0.633238,-0.773957,0,0.773957,-0.633238,0,0,0,1.0},'neon',0,0}},bounds={3.691006,4.375,2.837143}},
['Luminous Cthulhu Egg']={palette={{8,72,85},{8,76,91},{24,125,134},{14,104,118},{64,42,111},{85,176,194},{39,154,173},{78,225,255},{4,23,44},{2,16,31}},parts={{'box','EggShell',{0.262912,0.29483,0.995324},1,{-1.183105,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.920192,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.65728,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.394369,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{-0.131456,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.131456,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.394369,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.65728,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{0.920192,-1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{-1.183105,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.920192,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.65728,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.394369,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{-0.131456,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.131456,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.394369,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.65728,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{0.920192,-1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,-0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{-1.183105,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{-0.920192,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{-0.65728,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{-0.394369,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{-0.131456,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.401914},1,{0.131456,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.302821},1,{0.394369,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.090597},1,{0.65728,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.723951},1,{0.920192,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.052244},1,{1.183105,0.147414,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{-0.920192,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{-0.65728,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{-0.394369,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{-0.131456,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{0.131456,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{0.394369,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{0.65728,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{0.920192,0.442244,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{-0.920192,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{-0.65728,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{-0.394369,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{-0.131456,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.916064},1,{0.131456,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.790281},1,{0.394369,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.507551},1,{0.65728,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.934944},1,{0.920192,0.737074,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{-0.920192,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{-0.65728,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{-0.394369,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{-0.131456,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.172613},1,{0.131456,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,2.118289},1,{0.394369,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.946241},1,{0.65728,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,1.61937},1,{0.920192,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.995324},1,{1.183105,1.031902,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.920192,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.65728,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{-0.131456,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.418119},1,{0.131456,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.539791},1,{0.65728,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.724205},1,{0.920192,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.539791},1,{1.183105,1.326732,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.262912,0.29483,0.265543},1,{0.131456,1.621563,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-0.131456,-1.53198,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.697076,-1.53198,1.000724},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.115627,-1.53198,0.517918},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{-1.272787,-1.53198,-0.497663},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-1.115627,-1.53198,-0.517918},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.697076,-1.53198,-1.000724},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.131456,-1.53198,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.434165,-1.53198,-1.000724},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.852717,-1.53198,-0.517918},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{1.009875,-1.53198,-0.497663},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.852717,-1.53198,0.517918},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.434165,-1.53198,1.000724},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,1.180252},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,0.887025},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,0.538034},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-1.220256,-1.014644,-0.538034},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.888793,-1.014644,-0.887025},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.324456,-1.014644,-1.180252},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.324456,-1.014644,-1.180252},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,-0.887025},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.220256,-1.014644,-0.538034},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.220256,-1.014644,0.538034},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.888793,-1.014644,0.887025},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.324456,-1.014644,1.180252},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0,-0.30718,1.230169},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.627406,-0.30718,1.072901},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,0.546379},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.2649,-0.30718,-0.526123},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.091186,-0.30718,-0.546379},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.627406,-0.30718,-1.072901},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0,-0.30718,-1.230169},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,-1.072901},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.091186,-0.30718,-0.546379},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.2649,-0.30718,-0.526123},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.091186,-0.30718,0.546379},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.627406,-0.30718,1.072901},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.260493,0.457845,0.986874},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.714041,0.457845,0.778825},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-0.981539,0.457845,0.479385},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.981539,0.457845,-0.479385},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.714041,0.457845,-0.778825},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.260493,0.457845,-0.986874},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.260493,0.457845,-0.986874},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.714041,0.457845,-0.778825},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.981539,0.457845,-0.479385},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.981539,0.457845,0.479385},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{0.714041,0.457845,0.778825},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.260493,0.457845,0.986874},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.131456,1.137076,1.115519},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.434165,1.137076,1.000724},{-0.944911,0,0.327327,0,1.0,0,-0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.852717,1.137076,0.517918},{-0.693375,0,0.720577,0,1.0,0,-0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{-1.009875,1.137076,-0.497663},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{-0.852717,1.137076,-0.517918},{0.693375,0,0.720577,0,1.0,0,-0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{-0.434165,1.137076,-1.000724},{0.944911,0,0.327327,0,1.0,0,-0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.131456,1.137076,-1.115519},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{0.697076,1.137076,-1.000724},{0.944911,0,-0.327327,0,1.0,0,0.327327,0,0.944911},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},2,{1.115627,1.137076,-0.517918},{0.693375,0,-0.720577,0,1.0,0,0.720577,0,0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{1.272787,1.137076,-0.497663},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},4,{1.115627,1.137076,0.517918},{-0.693375,0,-0.720577,0,1.0,0,0.720577,0,-0.693375},'slate',0,0},{'box','CarvedStone',{0.486875,0.454415,0.146062},3,{0.697076,1.137076,1.000724},{-0.944911,0,-0.327327,0,1.0,0,0.327327,0,-0.944911},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.094838,1.561914,0.161612},{-0.987322,0,0.158731,0,1.0,0,-0.158731,0,-0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.02905,1.561914,0.15782},{-0.857493,0,0.514496,0,1.0,0,-0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{-0.014575,1.561914,0.144682},{-0.407768,0,0.913086,0,1.0,0,-0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{-0.014575,1.561914,-0.144682},{0.407768,0,0.913086,0,1.0,0,-0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.02905,1.561914,-0.15782},{0.857493,0,0.514496,0,1.0,0,-0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.094838,1.561914,-0.161612},{0.987322,0,0.158731,0,1.0,0,-0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.168075,1.561914,-0.161612},{0.987322,0,-0.158731,0,1.0,0,0.158731,0,0.987322},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},3,{0.233863,1.561914,-0.15782},{0.857493,0,-0.514496,0,1.0,0,0.514496,0,0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.277487,1.561914,-0.144682},{0.407768,0,-0.913086,0,1.0,0,0.913086,0,0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.277487,1.561914,0.144682},{-0.407768,0,-0.913086,0,1.0,0,0.913086,0,-0.407768},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},4,{0.233863,1.561914,0.15782},{-0.857493,0,-0.514496,0,1.0,0,0.514496,0,-0.857493},'slate',0,0},{'box','CarvedStone',{0.37327,0.454415,0.146062},2,{0.168075,1.561914,0.161612},{-0.987322,0,-0.158731,0,1.0,0,0.158731,0,-0.987322},'slate',0,0},{'box','CurledTentacle',{0.259665,0.537525,0.259665},5,{-0.835801,-1.395706,-1.205206},{0.483077,-0.875578,0,0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{-1.071124,-1.265874,-1.205206},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.727484,0.246682},5,{-1.176613,-0.925061,-1.276112},{0.955286,-0.290011,-0.057639,0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{-1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.796717,0.2337},5,{-1.257759,-0.186636,-1.347019},{0.998131,0.06111,0,-0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{-1.233416,0.210979,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.830689,0.220715},5,{-1.079238,0.592364,-1.289694},{0.92711,0.371202,-0.051728,-0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{-0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.178944,0.207732},5,{-0.803342,1.298331,-0.755601},{0.936329,0.206488,-0.28399,-0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{-0.681624,1.622914,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{-0.876374,1.850121,-0.278832},{0.759257,-0.650791,0,0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{-1.071124,2.077331,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{-1.257759,1.98807,-0.278832},{-0.431455,-0.902134,0,0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{-1.444394,1.89881,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{-1.42005,1.728405,-0.278832},{-0.989949,0.141421,0,-0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{-1.395706,1.557999,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{-1.24153,1.517425,-0.278832},{-0.254493,0.967075,0,-0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{-1.087354,1.476851,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.600477,-1.525539,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.071124,-1.265874,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-1.233416,0.210979,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{-0.681624,1.622914,-0.42814},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.352071,-0.5307,0.267669},{0.375705,-0.925579,0.046366,0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.285001,-0.365258,0.267669},{-0.046366,-0.925579,0.375705,0.018797,0.375235,0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.293279,-0.361904,0.089371},{-0.375705,-0.925579,-0.046366,-0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{-1.36035,-0.527345,0.089371},{0.046366,-0.925579,-0.375705,-0.018797,0.375235,-0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.390753,0.291331,0.267695},{0.438424,-0.897906,0.039366,0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.312486,0.451781,0.267695},{-0.039366,-0.897906,0.438424,0.019203,0.438003,0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.319514,0.455209,0.089345},{-0.438424,-0.897906,-0.039366,-0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{-1.397781,0.29476,0.089345},{0.039366,-0.897906,-0.438424,-0.019203,0.438003,-0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.427911,1.113131,0.267714},{0.485643,-0.873498,0.033937,0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.341214,1.269187,0.267714},{-0.033937,-0.873498,0.485643,0.018854,0.485277,0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.347271,1.272552,0.089328},{-0.485643,-0.873498,-0.033937,-0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{-1.43397,1.116498,0.089328},{0.033937,-0.873498,-0.485643,-0.018854,0.485277,-0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{-0.681624,1.590456,-0.392437},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'box','CurledTentacle',{0.259665,0.537525,0.259665},5,{0.835801,-1.395706,-1.205206},{0.483077,0.875578,0,-0.875578,0.483077,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.259665,0.259665,0.259665},5,{1.071124,-1.265874,-1.205206},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.246682,0.727484,0.246682},5,{1.176613,-0.925061,-1.276112},{0.955286,0.290011,0.057639,-0.295684,0.93696,0.186219,0,-0.194935,0.980816},'plastic',0,0},{'ball','CurledTentacleJoint',{0.246682,0.246682,0.246682},5,{1.282104,-0.58425,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.2337,0.796717,0.2337},5,{1.257759,-0.186636,-1.347019},{0.998131,-0.06111,0,0.06111,0.998131,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.2337,0.2337,0.2337},5,{1.233416,0.210979,-1.347019},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.220715,0.830689,0.220715},5,{1.079238,0.592364,-1.289694},{0.92711,-0.371202,0.051728,0.374789,0.918237,-0.127958,0,0.138019,0.99043},'plastic',0,0},{'ball','CurledTentacleJoint',{0.220715,0.220715,0.220715},5,{0.925061,0.973749,-1.232369},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.207732,1.178944,0.207732},5,{0.803342,1.298331,-0.755601},{0.936329,-0.206488,0.28399,0.351123,0.550634,-0.757308,0,0.808805,0.588077},'plastic',0,0},{'ball','CurledTentacleJoint',{0.207732,0.207732,0.207732},5,{0.681624,1.622914,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.19475,0.598501,0.19475},5,{0.876374,1.850121,-0.278832},{0.759257,0.650791,0,-0.650791,0.759257,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.19475,0.19475,0.19475},5,{1.071124,2.077331,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.181767,0.413764,0.181767},5,{1.257759,1.98807,-0.278832},{-0.431455,0.902134,0,-0.902134,-0.431455,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.181767,0.181767,0.181767},5,{1.444394,1.89881,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.168783,0.344271,0.168783},5,{1.42005,1.728405,-0.278832},{-0.989949,-0.141421,0,0.141421,-0.989949,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.168783,0.168783,0.168783},5,{1.395706,1.557999,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'box','CurledTentacle',{0.1558,0.318851,0.1558},5,{1.24153,1.517425,-0.278832},{-0.254493,-0.967075,0,0.967075,-0.254493,0,0,0,1.0},'plastic',0,0},{'ball','CurledTentacleJoint',{0.1558,0.1558,0.1558},5,{1.087354,1.476851,-0.278832},{1.0,0,0,0,1.0,0,0,0,1.0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.600477,-1.525539,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.071124,-1.265874,-1.354514},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.282104,-0.58425,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{1.233416,0.210979,-1.496326},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.925061,0.973749,-1.381676},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'cylinder','TentacleSucker',{0.040574,0.146062,0.146062},6,{0.681624,1.622914,-0.42814},{0,-1.0,0,0,0,1.0,-1.0,0,0},'plastic',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.285001,-0.365258,0.267669},{0.375705,0.925579,-0.046366,-0.926739,0.375235,-0.018797,0,0.050031,0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.352071,-0.5307,0.267669},{0.046366,0.925579,0.375705,0.018797,0.375235,-0.926739,-0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.36035,-0.527345,0.089371},{-0.375705,0.925579,0.046366,0.926739,0.375235,0.018797,0,0.050031,-0.998748},'slate',0,0},{'corner','SideSpike',{0.17852,0.64876,0.17852},7,{1.293279,-0.361904,0.089371},{-0.046366,0.925579,-0.375705,-0.018797,0.375235,0.926739,0.998748,0.050031,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.312486,0.451781,0.267695},{0.438424,0.897906,-0.039366,-0.898768,0.438003,-0.019203,0,0.0438,0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.390753,0.291331,0.267695},{0.039366,0.897906,0.438424,0.019203,0.438003,-0.898768,-0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.397781,0.29476,0.089345},{-0.438424,0.897906,0.039366,0.898768,0.438003,0.019203,0,0.0438,-0.99904},'slate',0,0},{'corner','SideSpike',{0.17852,0.741051,0.17852},7,{1.319514,0.455209,0.089345},{-0.039366,0.897906,-0.438424,-0.019203,0.438003,0.898768,0.99904,0.0438,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.341214,1.269187,0.267714},{0.485643,0.873498,-0.033937,-0.874157,0.485277,-0.018854,0,0.038822,0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.427911,1.113131,0.267714},{0.033937,0.873498,0.485643,0.018854,0.485277,-0.874157,-0.999246,0.038822,0},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.43397,1.116498,0.089328},{-0.485643,0.873498,0.033937,0.874157,0.485277,0.018854,0,0.038822,-0.999246},'slate',0,0},{'corner','SideSpike',{0.17852,0.836076,0.17852},7,{1.347271,1.272552,0.089328},{-0.033937,0.873498,-0.485643,-0.018854,0.485277,0.874157,0.999246,0.038822,0},'slate',0,0},{'ball','CrownLamp',{0.37327,0.405727,0.37327},8,{0.681624,1.590456,-0.392437},{1.0,0,0,0,1.0,0,0,0,1.0},'neon',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.020789,1.98229,0.27125},{0.979457,0.200904,-0.017363,-0.201653,0.97582,-0.084333,0,0.086102,0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.330756,1.918474,0.27125},{0.017363,0.200904,0.979457,0.084333,0.97582,-0.201653,-0.996286,0.086102,0},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.336251,1.945162,-0.044042},{-0.979457,0.200904,0.017363,0.201653,0.97582,0.084333,0,0.086102,-0.996286},'slate',0,0},{'corner','CrownSpire',{0.316469,1.130929,0.316469},7,{0.026285,2.00898,-0.044042},{-0.017363,0.200904,-0.979457,-0.084333,0.97582,0.201653,0.996286,0.086102,0},'slate',0,0},{'ball','RuneSocket',{1.022436,1.574226,0.227208},9,{0,-0.162293,-1.226924},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','EyeRune',{0.068163,0.51038,0.068163},8,{-0.129832,-0.819572,-1.411936},{0.860292,-0.50877,-0.032422,0.509802,0.85855,0.054711,0,-0.063596,0.997976},'neon',0,0},{'box','EyeRune',{0.068163,0.828322,0.068163},8,{-0.275895,-0.186636,-1.428164},{0.999232,-0.039186,0,0.039186,0.999232,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.640589,0.068163},8,{-0.146062,0.511219,-1.403822},{0.889288,0.456025,-0.03476,-0.457348,0.886716,-0.06759,0,0.076004,0.997107},'neon',0,0},{'box','EyeRune',{0.068163,0.626452,0.068163},8,{0.129832,0.511219,-1.403822},{-0.909474,0.414502,0.032313,-0.41576,-0.906724,-0.070684,0,-0.077719,0.996975},'neon',0,0},{'box','EyeRune',{0.068163,0.827845,0.068163},8,{0.251551,-0.186636,-1.428164},{-0.999808,-0.019604,0,0.019604,-0.999808,0,0,0,1.0},'neon',0,0},{'box','EyeRune',{0.068163,0.502317,0.068163},8,{0.121719,-0.819572,-1.411936},{-0.874157,-0.484628,0.031381,0.485643,-0.87233,0.056485,0,0.064617,0.99791},'neon',0,0},{'box','RunePupil',{0.17852,1.038665,0.17852},10,{0,-0.129832,-1.395706},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.681624,0.081145,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{-0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,-0.892604,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.681624,0.081145,-1.363249},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0},{'box','SmallRune',{0.121719,0.121719,0.056801},8,{0.551791,0.95752,-1.248599},{0.707107,-0.707107,0,0.707107,0.707107,0,0,0,1.0},'neon',0,0}},bounds={3.691006,4.375,2.819814}},
['Sabertooth Egg']={palette={{31,27,25},{171,43,18},{218,64,13},{239,100,16},{107,31,24},{52,44,36},{166,28,21},{208,42,15},{225,72,14},{193,32,19},{236,221,174},{170,73,13},{255,195,17},{255,158,13},{255,176,13},{255,194,13},{168,46,13},{255,204,16},{255,214,16},{203,39,15},{230,60,13},{171,27,21}},parts={{'box','EggShell',{0.246486,0.304051,0.746855},1,{-0.739459,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.170096},1,{-0.492973,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.332213},1,{-0.246486,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.332213},1,{0,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.170096},1,{0.246486,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.746855},1,{0.492973,-1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.872138},1,{-0.739459,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.406281},1,{-0.492973,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.670018},1,{-0.246486,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.787351},1,{0,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.787351},1,{0.246486,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.670018},1,{0.492973,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.406281},1,{0.739459,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.872138},1,{0.985946,-1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.981559},1,{-1.232432,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.608143},1,{-0.985946,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.95016},1,{-0.739459,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.148129},1,{-0.492973,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.240564},1,{-0.246486,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.240564},1,{0,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.148129},1,{0.246486,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.95016},1,{0.492973,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.608143},1,{0.739459,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.981559},1,{0.985946,-1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,-0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,-0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,-0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,0.152025,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,0.456076,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-1.232432,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{-0.985946,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{-0.739459,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{-0.492973,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{-0.246486,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.477036},1,{0,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.435749},1,{0.246486,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.307461},1,{0.492973,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.076104},1,{0.739459,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.70011},1,{0.985946,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{1.232432,0.760127,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.981559},1,{-1.232432,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.608143},1,{-0.985946,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.95016},1,{-0.739459,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.148129},1,{-0.492973,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.240564},1,{-0.246486,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.240564},1,{0,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,2.148129},1,{0.246486,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.95016},1,{0.492973,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.608143},1,{0.739459,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.981559},1,{0.985946,1.064177,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.675555},1,{-0.492973,1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-0.246486,1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.125926},1,{0,1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{0.246486,1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.675555},1,{0.492973,1.368228,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.675555},1,{-0.492973,1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{-0.246486,1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.125926},1,{0,1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,1.031928},1,{0.246486,1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','OriginalShellCell',{0.246486,0.304051,0.675555},1,{0.492973,1.672278,0},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'box','VolcanicPlate',{0.47084,0.447908,0.167367},2,{-0.042622,-1.475893,0.940278},{-0.987786,0.114938,0.105209,0.115579,0.993298,0,-0.104504,0.01216,-0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.447298,0.380722,0.251051},3,{-0.05442,-1.475893,1.051792},{-0.914803,-0.389957,0.105209,-0.392134,0.919908,0,-0.096783,-0.041256,-0.99445},'slate',0,0},{'box','VolcanicPlate',{0.554244,0.464674,0.167367},3,{-0.519174,-1.475893,0.744371},{-0.830712,0.289817,0.475314,0.329406,0.944188,0,-0.448786,0.156571,-0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.526532,0.394973,0.251051},4,{-0.572474,-1.475893,0.84303},{-0.846882,0.238469,0.475314,0.271044,0.962567,0,-0.457522,0.128831,-0.879816},'slate',0,0},{'box','VolcanicPlate',{0.482422,0.437593,0.167367},4,{-0.809926,-1.475893,0.456276},{-0.419301,0.100587,0.902258,0.233274,0.972411,0,-0.877365,0.210473,-0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.458301,0.371954,0.251051},2,{-0.911102,-1.475893,0.504629},{-0.349749,0.252204,0.902258,0.584893,0.811111,0,-0.731831,0.527724,-0.431197},'slate',0,0},{'box','VolcanicPlate',{0.491909,0.450445,0.167367},5,{-0.809926,-1.475893,-0.456276},{0.407441,-0.141148,0.902258,0.32734,0.944906,0,-0.852549,0.295345,0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.467313,0.382878,0.251051},3,{-0.911102,-1.475893,-0.504629},{0.35106,-0.250376,0.902258,0.580653,0.814151,0,-0.734574,0.523899,0.431197},'slate',0,0},{'box','VolcanicPlate',{0.519041,0.451701,0.167367},6,{-0.519174,-1.475893,-0.744371},{0.866277,-0.153754,0.475314,0.174757,0.984612,0,-0.468,0.083064,0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.493089,0.383946,0.251051},4,{-0.572474,-1.475893,-0.84303},{0.65004,-0.592895,0.475314,0.673885,0.738836,0,-0.351179,0.320307,0.879816},'slate',0,0},{'box','VolcanicPlate',{0.484004,0.52976,0.167367},2,{-0.042622,-1.475893,-0.940278},{0.961638,-0.253345,0.105209,0.254758,0.967005,0,-0.101738,0.026803,0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.459804,0.450296,0.251051},2,{-0.05442,-1.475893,-1.051792},{0.918815,-0.380408,0.105209,0.382531,0.923943,0,-0.097207,0.040246,0.99445},'slate',0,0},{'box','VolcanicPlate',{0.617904,0.605774,0.167367},3,{0.481465,-1.475893,-0.880553},{0.954753,0.181504,-0.235592,-0.186761,0.982405,0,0.231447,0.043999,0.971852},'slate',0,0},{'corner','JaggedLavaScale',{0.587009,0.514908,0.251051},3,{0.507883,-1.475893,-0.989532},{0.738216,-0.632086,-0.235592,0.650393,0.759598,0,0.178955,-0.153228,0.971852},'slate',0,0},{'box','VolcanicPlate',{0.59465,0.679052,0.167367},4,{0.902872,-1.475893,-0.472203},{0.765922,0.088863,-0.636763,-0.115248,0.993337,0,0.63252,0.073386,0.771059},'slate',0,0},{'corner','JaggedLavaScale',{0.564917,0.577194,0.251051},4,{0.974276,-1.475893,-0.558667},{0.73453,0.234515,-0.636763,-0.304147,0.952625,0,0.606597,0.19367,0.771059},'slate',0,0},{'box','VolcanicPlate',{0.630436,0.697127,0.167367},5,{1.094322,-1.475893,-0.441494},{0.111258,0.031975,-0.993277,-0.276214,0.961096,0,0.954635,0.274357,0.115761},'slate',0,0},{'corner','JaggedLavaScale',{0.598914,0.592558,0.251051},2,{1.205705,-1.475893,-0.454475},{0.091392,0.07105,-0.993277,-0.613768,0.789487,0,0.784179,0.609641,0.115761},'slate',0,0},{'box','VolcanicPlate',{0.447415,0.617652,0.167367},6,{0.976622,-1.475893,0.46715},{-0.653225,-0.114773,-0.748414,-0.173052,0.984913,0,0.737123,0.129514,-0.663232},'slate',0,0},{'corner','JaggedLavaScale',{0.425044,0.525005,0.251051},3,{1.060546,-1.475893,0.541522},{-0.574836,-0.330818,-0.748414,-0.498796,0.866719,0,0.648665,0.373306,-0.663232},'slate',0,0},{'box','VolcanicPlate',{0.531403,0.708533,0.167367},2,{0.601977,-1.475893,0.87929},{-0.944814,-0.013537,-0.327327,-0.014327,0.999897,0,0.327293,0.004689,-0.944911},'slate',0,0},{'corner','JaggedLavaScale',{0.504833,0.602253,0.251051},4,{0.638682,-1.475893,0.985249},{-0.748729,-0.576421,-0.327327,-0.610027,0.792381,0,0.259367,0.199678,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.448789,0.508553,0.167367},5,{-0.488415,-0.88444,1.199274},{-0.965287,-0.112769,0.235592,-0.116035,0.993245,0,-0.234001,-0.027337,-0.971852},'slate',0,0},{'corner','JaggedLavaScale',{0.42635,0.43227,0.251051},4,{-0.514833,-0.88444,1.308254},{-0.872342,-0.428387,0.235592,-0.440794,0.897608,0,-0.211469,-0.103848,-0.971852},'slate',0,0},{'box','VolcanicPlate',{0.436291,0.520808,0.167367},6,{-1.060799,-0.88444,0.886189},{-0.756206,-0.150615,0.636763,-0.195335,0.980737,0,-0.624497,-0.124382,-0.771059},'slate',0,0},{'corner','JaggedLavaScale',{0.414476,0.442686,0.251051},2,{-1.132203,-0.88444,0.972653},{-0.690382,-0.343372,0.636763,-0.445326,0.895369,0,-0.570138,-0.283567,-0.771059},'slate',0,0},{'box','VolcanicPlate',{0.436872,0.589087,0.167367},2,{-1.317778,-0.88444,0.521389},{-0.113907,0.020635,0.993277,0.178255,0.983984,0,-0.977369,0.177056,-0.115761},'slate',0,0},{'corner','JaggedLavaScale',{0.415029,0.500724,0.251051},3,{-1.429161,-0.88444,0.53437},{-0.112647,-0.026669,0.993277,-0.230378,0.973101,0,-0.966559,-0.228829,-0.115761},'slate',0,0},{'box','VolcanicPlate',{0.442143,0.545898,0.167367},3,{-1.160244,-0.88444,-0.547045},{0.63427,0.193849,0.748414,-0.29228,0.956333,0,-0.715733,-0.218746,0.663232},'slate',0,0},{'corner','JaggedLavaScale',{0.420036,0.464013,0.251051},4,{-1.244168,-0.88444,-0.621417},{0.556964,0.360094,0.748414,-0.542939,0.839772,0,-0.628498,-0.406343,0.663232},'slate',0,0},{'box','VolcanicPlate',{0.475365,0.690524,0.167367},4,{-0.652507,-0.88444,-1.082333},{0.899958,0.287981,0.327327,-0.304771,0.952426,0,-0.311754,-0.09976,0.944911},'slate',0,0},{'corner','JaggedLavaScale',{0.451596,0.586946,0.251051},2,{-0.689212,-0.88444,-1.188292},{0.944713,0.019356,0.327327,-0.020485,0.99979,0,-0.327258,-0.006705,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.421499,0.525506,0.167367},5,{0.045455,-0.88444,-1.285371},{0.944106,-0.328976,-0.020948,0.329048,0.944313,0,0.019781,-0.006893,0.999781},'slate',0,0},{'corner','JaggedLavaScale',{0.400424,0.44668,0.251051},3,{0.047804,-0.88444,-1.397482},{0.85928,-0.511077,-0.020948,0.511189,0.859468,0,0.018004,-0.010708,0.999781},'slate',0,0},{'box','VolcanicPlate',{0.520565,0.497925,0.167367},6,{0.730179,-0.88444,-1.081492},{0.914353,0.152391,-0.375148,-0.164398,0.986394,0,0.370043,0.061673,0.926965},'slate',0,0},{'corner','JaggedLavaScale',{0.494537,0.423236,0.251051},4,{0.772247,-0.88444,-1.185439},{0.924823,-0.062981,-0.375148,0.067943,0.997689,0,0.374281,-0.025489,0.926965},'slate',0,0},{'box','VolcanicPlate',{0.513931,0.498027,0.167367},2,{1.201796,-0.88444,-0.54389},{0.564725,0.190233,-0.803055,-0.319234,0.947676,0,0.761036,0.256362,0.595905},'slate',0,0},{'corner','JaggedLavaScale',{0.488235,0.423323,0.251051},2,{1.291848,-0.88444,-0.610712},{0.538545,-0.255092,-0.803055,0.428074,0.903743,0,0.725756,-0.343767,0.595905},'slate',0,0},{'box','VolcanicPlate',{0.635836,0.708231,0.167367},3,{1.307561,-0.88444,0.526652},{-0.228059,0.001173,-0.973647,0.005142,0.999987,0,0.973634,-0.005007,-0.228062},'slate',0,0},{'corner','JaggedLavaScale',{0.604044,0.601996,0.251051},3,{1.416742,-0.88444,0.552226},{-0.225317,-0.035276,-0.973647,-0.154679,0.987965,0,0.961929,0.150602,-0.228062},'slate',0,0},{'box','VolcanicPlate',{0.443698,0.716284,0.167367},4,{1.003455,-0.88444,0.888175},{-0.812666,-0.035433,-0.581651,-0.043559,0.999051,0,0.581099,0.025336,-0.813438},'slate',0,0},{'corner','JaggedLavaScale',{0.421513,0.608841,0.251051},4,{1.068679,-0.88444,0.979391},{-0.634635,-0.508842,-0.581651,-0.625545,0.780188,0,0.453797,0.363849,-0.813438},'slate',0,0},{'box','VolcanicPlate',{0.629378,0.614737,0.167367},5,{0.402758,-0.88444,1.199727},{-0.96746,0.165549,-0.191349,0.168666,0.985673,0,0.188608,-0.032274,-0.981522},'slate',0,0},{'corner','JaggedLavaScale',{0.597909,0.522527,0.251051},2,{0.424215,-0.88444,1.309791},{-0.979863,0.057035,-0.191349,0.058109,0.99831,0,0.191026,-0.011119,-0.981522},'slate',0,0},{'box','VolcanicPlate',{0.464936,0.659896,0.167367},3,{-0.226216,-0.127257,1.264478},{-0.979912,0.16942,0.105209,0.170366,0.985381,0,-0.103671,0.017924,-0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.441689,0.560911,0.251051},2,{-0.238014,-0.127257,1.375991},{-0.994312,0.016571,0.105209,0.016664,0.999861,0,-0.105194,0.001753,-0.99445},'slate',0,0},{'box','VolcanicPlate',{0.623044,0.47234,0.167367},4,{-0.874971,-0.127257,1.079283},{-0.834951,0.277369,0.475314,0.315258,0.949006,0,-0.451076,0.149847,-0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.591892,0.401489,0.251051},3,{-0.928271,-0.127257,1.177942},{-0.872754,0.111249,0.475314,0.126445,0.991974,0,-0.471499,0.060101,-0.879816},'slate',0,0},{'box','VolcanicPlate',{0.44262,0.670542,0.167367},5,{-1.267252,-0.127257,0.536171},{-0.417494,0.107842,0.902258,0.250098,0.96822,0,-0.873584,0.225653,-0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.420489,0.56996,0.251051},4,{-1.368427,-0.127257,0.584524},{-0.377881,0.207694,0.902258,0.481668,0.876354,0,-0.790697,0.434589,-0.431197},'slate',0,0},{'box','VolcanicPlate',{0.514193,0.600606,0.167367},6,{-1.267252,-0.127257,-0.536171},{0.430031,-0.031692,0.902258,0.073498,0.997295,0,-0.899818,0.066314,0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.488483,0.510515,0.251051},2,{-1.368427,-0.127257,-0.584524},{0.406451,-0.143975,0.902258,0.333896,0.94261,0,-0.850477,0.301261,0.431197},'slate',0,0},{'box','VolcanicPlate',{0.508885,0.454679,0.167367},2,{-0.874971,-0.127257,-1.079283},{0.874113,0.100019,0.475314,-0.113682,0.993517,0,-0.472233,-0.054035,0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.48344,0.386477,0.251051},3,{-0.928271,-0.127257,-1.177942},{0.857296,0.197786,0.475314,-0.224804,0.974404,0,-0.463148,-0.106852,0.879816},'slate',0,0},{'box','VolcanicPlate',{0.42787,0.471312,0.167367},3,{-0.226216,-0.127257,-1.264478},{0.987479,-0.117547,0.105209,0.118203,0.992989,0,-0.104471,0.012436,0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.406476,0.400615,0.251051},4,{-0.238014,-0.127257,-1.375991},{0.994103,-0.026262,0.105209,0.026408,0.999651,0,-0.105172,0.002778,0.99445},'slate',0,0},{'box','VolcanicPlate',{0.45946,0.673855,0.167367},4,{0.488415,-0.127257,-1.199274},{0.923815,0.301764,-0.235592,-0.310504,0.950572,0,0.223947,0.073152,0.971852},'slate',0,0},{'corner','JaggedLavaScale',{0.436487,0.572777,0.251051},2,{0.514833,-0.127257,-1.308254},{0.688074,0.686331,-0.235592,-0.706209,0.708003,0,0.1668,0.166377,0.971852},'slate',0,0},{'box','VolcanicPlate',{0.561255,0.687961,0.167367},5,{1.060799,-0.127257,-0.886189},{0.747129,-0.190606,-0.636763,0.2472,0.968964,0,0.617001,-0.157408,0.771059},'slate',0,0},{'corner','JaggedLavaScale',{0.533192,0.584767,0.251051},3,{1.132203,-0.127257,-0.972653},{0.752433,-0.168454,-0.636763,0.218471,0.975843,0,0.621381,-0.139114,0.771059},'slate',0,0},{'box','VolcanicPlate',{0.516696,0.495888,0.167367},6,{1.317778,-0.127257,-0.521389},{0.1104,-0.034821,-0.993277,0.300801,0.953687,0,0.947275,-0.298779,0.115761},'slate',0,0},{'corner','JaggedLavaScale',{0.490861,0.421505,0.251051},4,{1.429161,-0.127257,-0.53437},{0.112179,-0.028575,-0.993277,0.246843,0.969056,0,0.962541,-0.245183,0.115761},'slate',0,0},{'box','VolcanicPlate',{0.461691,0.683436,0.167367},2,{1.160244,-0.127257,0.547045},{-0.653472,0.113363,-0.748414,0.170925,0.985284,0,0.737401,-0.127922,-0.663232},'slate',0,0},{'corner','JaggedLavaScale',{0.438607,0.58092,0.251051},2,{1.244168,-0.127257,0.621417},{-0.491,0.445865,-0.748414,0.672261,0.740314,0,0.554062,-0.50313,-0.663232},'slate',0,0},{'box','VolcanicPlate',{0.500898,0.550374,0.167367},3,{0.652507,-0.127257,1.082333},{-0.943551,0.050674,-0.327327,0.053628,0.998561,0,0.326856,-0.017554,-0.944911},'slate',0,0},{'corner','JaggedLavaScale',{0.475853,0.467818,0.251051},3,{0.689212,-0.127257,1.188292},{-0.897303,-0.296149,-0.327327,-0.313415,0.949616,0,0.310835,0.102589,-0.944911},'slate',0,0},{'box','VolcanicPlate',{0.483131,0.698376,0.167367},6,{-0.488415,0.653772,1.199274},{-0.947082,0.218018,0.235592,0.224332,0.974513,0,-0.229588,0.052851,-0.971852},'slate',0,0},{'corner','JaggedLavaScale',{0.458974,0.59362,0.251051},3,{-0.514833,0.653772,1.308254},{-0.798236,0.55436,0.235592,0.570416,0.821356,0,-0.193505,0.134386,-0.971852},'slate',0,0},{'box','VolcanicPlate',{0.582197,0.615055,0.167367},2,{-1.060799,0.653772,0.886189},{-0.731752,-0.243046,0.636763,-0.315211,0.949022,0,-0.604302,-0.200715,-0.771059},'slate',0,0},{'corner','JaggedLavaScale',{0.553087,0.522797,0.251051},4,{-1.132203,0.653772,0.972653},{-0.676129,0.370651,0.636763,0.480703,0.876883,0,-0.558367,0.306094,-0.771059},'slate',0,0},{'box','VolcanicPlate',{0.4617,0.608591,0.167367},3,{-1.317778,0.653772,0.521389},{-0.115143,0.01195,0.993277,0.103234,0.994657,0,-0.98797,0.10254,-0.115761},'slate',0,0},{'corner','JaggedLavaScale',{0.438615,0.517303,0.251051},2,{-1.429161,0.653772,0.53437},{-0.103212,-0.05242,0.993277,-0.452827,0.891599,0,-0.885604,-0.449782,-0.115761},'slate',0,0},{'box','VolcanicPlate',{0.573822,0.442421,0.167367},4,{-1.160244,0.653772,-0.547045},{0.638501,0.179423,0.748414,-0.270528,0.962712,0,-0.720507,-0.202467,0.663232},'slate',0,0},{'corner','JaggedLavaScale',{0.545131,0.376058,0.251051},3,{-1.244168,0.653772,-0.621417},{0.608103,-0.264739,0.748414,0.399166,0.916879,0,-0.686205,0.298741,0.663232},'slate',0,0},{'box','VolcanicPlate',{0.488712,0.569864,0.167367},5,{-0.652507,0.653772,-1.082333},{0.940663,-0.089498,0.327327,0.094716,0.995504,0,-0.325855,0.031003,0.944911},'slate',0,0},{'corner','JaggedLavaScale',{0.464277,0.484384,0.251051},4,{-0.689212,0.653772,-1.188292},{0.94324,-0.056176,0.327327,0.059451,0.998231,0,-0.326748,0.01946,0.944911},'slate',0,0},{'box','VolcanicPlate',{0.604221,0.663026,0.167367},6,{0.045455,0.653772,-1.285371},{0.985636,0.167582,-0.020948,-0.167619,0.985852,0,0.020651,0.003511,0.999781},'slate',0,0},{'corner','JaggedLavaScale',{0.57401,0.563572,0.251051},2,{0.047804,0.653772,-1.397482},{0.806795,0.59046,-0.020948,-0.59059,0.806972,0,0.016904,0.012372,0.999781},'slate',0,0},{'box','VolcanicPlate',{0.522595,0.699025,0.167367},2,{0.730179,0.653772,-1.081492},{0.911739,0.167322,-0.375148,-0.180506,0.983574,0,0.368985,0.067716,0.926965},'slate',0,0},{'corner','JaggedLavaScale',{0.496465,0.594171,0.251051},3,{0.772247,0.653772,-1.185439},{0.834211,-0.404174,-0.375148,0.436018,0.899938,0,0.337609,-0.163571,0.926965},'slate',0,0},{'box','VolcanicPlate',{0.517407,0.705648,0.167367},3,{1.201796,0.653772,-0.54389},{0.567307,0.182388,-0.803055,-0.30607,0.952009,0,0.764516,0.245791,0.595905},'slate',0,0},{'corner','JaggedLavaScale',{0.491537,0.599801,0.251051},4,{1.291848,0.653772,-0.610712},{0.531173,0.270107,-0.803055,-0.453272,0.891372,0,0.715821,0.364002,0.595905},'slate',0,0},{'box','VolcanicPlate',{0.586578,0.71289,0.167367},4,{1.307561,0.653772,0.526652},{-0.216895,0.07049,-0.973647,0.309082,0.951035,0,0.925972,-0.300937,-0.228062},'slate',0,0},{'corner','JaggedLavaScale',{0.557249,0.605957,0.251051},2,{1.416742,0.653772,0.552226},{-0.192362,0.122511,-0.973647,0.537182,0.843466,0,0.821238,-0.523026,-0.228062},'slate',0,0},{'box','VolcanicPlate',{0.480844,0.579953,0.167367},5,{1.003455,0.653772,0.888175},{-0.765107,-0.276212,-0.581651,-0.339561,0.940584,0,0.547092,0.197506,-0.813438},'slate',0,0},{'corner','JaggedLavaScale',{0.456801,0.49296,0.251051},3,{1.068679,0.653772,0.979391},{-0.812101,-0.04662,-0.581651,-0.057312,0.998356,0,0.580695,0.033336,-0.813438},'slate',0,0},{'box','VolcanicPlate',{0.525886,0.446901,0.167367},6,{0.402758,0.653772,1.199727},{-0.957938,-0.213869,-0.191349,-0.217895,0.975972,0,0.186752,0.041694,-0.981522},'slate',0,0},{'corner','JaggedLavaScale',{0.499591,0.379866,0.251051},4,{0.424215,0.653772,1.309791},{-0.816942,0.544051,-0.191349,0.554293,0.832321,0,0.159264,-0.106064,-0.981522},'slate',0,0},{'box','VolcanicPlate',{0.534499,0.620193,0.167367},4,{-0.105515,1.334211,0.609566},{-0.965057,0.23999,0.105209,0.241329,0.970443,0,-0.102099,0.02539,-0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.507774,0.527164,0.251051},4,{-0.117313,1.334211,0.721079},{-0.768075,0.631658,0.105209,0.635184,0.772361,0,-0.081259,0.066827,-0.99445},'slate',0,0},{'box','VolcanicPlate',{0.62544,0.489978,0.167367},5,{-0.409864,1.334211,0.379008},{-0.877137,0.068607,0.475314,0.077979,0.996955,0,-0.473867,0.037064,-0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.594168,0.416481,0.251051},2,{-0.463164,1.334211,0.477668},{-0.693799,-0.541035,0.475314,-0.614941,0.788573,0,-0.37482,-0.29229,-0.879816},'slate',0,0},{'box','VolcanicPlate',{0.470787,0.532472,0.167367},6,{-0.599087,1.334211,0.357985},{-0.409517,-0.135006,0.902258,-0.313095,0.949722,0,-0.856894,-0.282493,-0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.447247,0.452601,0.251051},3,{-0.700262,1.334211,0.406338},{-0.358432,-0.239702,0.902258,-0.5559,0.831249,0,-0.750001,-0.501565,-0.431197},'slate',0,0},{'box','VolcanicPlate',{0.557319,0.663747,0.167367},2,{-0.599087,1.334211,-0.357985},{0.429634,0.036678,0.902258,-0.085062,0.996376,0,-0.898988,-0.076748,0.431197},'slate',0,0},{'corner','JaggedLavaScale',{0.529453,0.564185,0.251051},4,{-0.700262,1.334211,-0.406338},{0.371196,0.219418,0.902258,-0.508859,0.86085,0,-0.776709,-0.459122,0.431197},'slate',0,0},{'box','VolcanicPlate',{0.559883,0.463351,0.167367},3,{-0.409864,1.334211,-0.379008},{0.849002,-0.230808,0.475314,0.262337,0.964976,0,-0.458667,0.124692,0.879816},'slate',0,0},{'corner','JaggedLavaScale',{0.531889,0.393848,0.251051},2,{-0.463164,1.334211,-0.477668},{0.644887,0.598496,0.475314,-0.680251,0.732979,0,-0.348395,-0.323333,0.879816},'slate',0,0},{'box','VolcanicPlate',{0.467367,0.693455,0.167367},4,{-0.105515,1.334211,-0.609566},{0.98376,-0.145419,0.105209,0.146231,0.98925,0,-0.104078,0.015385,0.99445},'slate',0,0},{'corner','JaggedLavaScale',{0.443999,0.589437,0.251051},3,{-0.117313,1.334211,-0.721079},{0.952264,0.286575,0.105209,-0.288174,0.957578,0,-0.100746,-0.030319,0.99445},'slate',0,0},{'box','VolcanicPlate',{0.433675,0.61288,0.167367},5,{0.228029,1.334211,-0.561508},{0.97155,0.024237,-0.235592,-0.024939,0.999689,0,0.235519,0.005875,0.971852},'slate',0,0},{'corner','JaggedLavaScale',{0.411991,0.520948,0.251051},4,{0.254447,1.334211,-0.670487},{0.74264,0.626883,-0.235592,-0.645039,0.764149,0,0.180028,0.151966,0.971852},'slate',0,0},{'box','VolcanicPlate',{0.61942,0.44927,0.167367},6,{0.498458,1.334211,-0.373912},{0.75844,-0.138929,-0.636763,0.18018,0.983634,0,0.626342,-0.114732,0.771059},'slate',0,0},{'corner','JaggedLavaScale',{0.588449,0.381879,0.251051},2,{0.569862,1.334211,-0.460375},{0.770779,0.020803,-0.636763,-0.026979,0.999636,0,0.636532,0.017179,0.771059},'slate',0,0},{'box','VolcanicPlate',{0.562192,0.448248,0.167367},2,{0.62438,1.334211,-0.343203},{0.112066,-0.029017,-0.993277,0.250659,0.968076,0,0.961567,-0.248974,0.115761},'slate',0,0},{'corner','JaggedLavaScale',{0.534082,0.381011,0.251051},3,{0.735762,1.334211,-0.356184},{0.084041,-0.07961,-0.993277,0.687711,0.725985,0,0.721104,-0.683087,0.115761},'slate',0,0},{'box','VolcanicPlate',{0.420016,0.526335,0.167367},3,{0.546514,1.334211,0.368859},{-0.660263,0.06268,-0.748414,0.094508,0.995524,0,0.745064,-0.070731,-0.663232},'slate',0,0},{'corner','JaggedLavaScale',{0.399015,0.447385,0.251051},4,{0.630438,1.334211,0.443231},{-0.660742,0.057406,-0.748414,0.086555,0.996247,0,0.745606,-0.064779,-0.663232},'slate',0,0},{'box','VolcanicPlate',{0.60858,0.578989,0.167367},4,{0.304961,1.334211,0.560245},{-0.939224,-0.103511,-0.327327,-0.109546,0.993982,0,0.325357,0.035857,-0.944911},'slate',0,0},{'corner','JaggedLavaScale',{0.578151,0.49214,0.251051},2,{0.341666,1.334211,0.666204},{-0.672055,0.664228,-0.327327,0.702953,0.711236,0,0.232807,-0.230095,-0.944911},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580057,0.217578},7,{-0.108789,1.652579,0.865902},{1.0,0,0,0,0.981022,-0.193896,0,0.193896,0.981022},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580057,0.217578},7,{0.108789,1.652579,0.865902},{0,0,1.0,0.193896,0.981022,0,-0.981022,0.193896,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580057,0.217578},7,{0.108789,1.694767,0.652454},{-1.0,0,0,0,0.981022,0.193896,0,0.193896,-0.981022},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580057,0.217578},7,{-0.108789,1.694767,0.652454},{0,0,-1.0,-0.193896,0.981022,0,0.981022,0.193896,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{0.47571,1.728582,0.644878},{0.992822,0.118802,-0.013839,-0.119605,0.986154,-0.114872,0,0.115703,0.993284},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{0.691726,1.702559,0.644878},{0.013839,0.118802,0.992822,0.114872,0.986154,-0.119605,-0.993284,0.115703,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{0.694737,1.727553,0.428762},{-0.992822,0.118802,0.013839,0.119605,0.986154,0.114872,0,0.115703,-0.993284},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{0.478721,1.753576,0.428762},{-0.013839,0.118802,-0.992822,-0.114872,0.986154,0.119605,0.993284,0.115703,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.795058,0.217578},9,{0.719996,1.798264,0.108789},{0.989395,0.145252,0,-0.145252,0.989395,0,0,0,1.0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.795058,0.217578},9,{0.935266,1.76666,0.108789},{0,0.145252,0.989395,0,0.989395,-0.145252,-1.0,0,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.795058,0.217578},9,{0.935266,1.76666,-0.108789},{-0.989395,0.145252,0,0.145252,0.989395,0,0,0,-1.0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.795058,0.217578},9,{0.719996,1.798264,-0.108789},{0,0.145252,-0.989395,0,0.989395,0.145252,1.0,0,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580353,0.217578},7,{0.479656,1.703883,-0.429058},{0.98986,0.140706,0.019465,-0.142046,0.980522,0.135646,0,-0.137035,0.990566},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580353,0.217578},7,{0.695027,1.672977,-0.429058},{-0.019465,0.140706,0.98986,-0.135646,0.980522,-0.142046,-0.990566,-0.137035,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580353,0.217578},7,{0.690792,1.643463,-0.644582},{-0.98986,0.140706,-0.019465,0.142046,0.980522,-0.135646,0,-0.137035,-0.990566},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580353,0.217578},7,{0.475421,1.674369,-0.644582},{0.019465,0.140706,-0.98986,0.135646,0.980522,0.142046,0.990566,-0.137035,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687105,0.217578},8,{-0.108789,1.745875,-0.651857},{1.0,0,0,0,0.986512,0.163688,0,-0.163688,0.986512},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687105,0.217578},8,{0.108789,1.745875,-0.651857},{0,0,1.0,-0.163688,0.986512,0,-0.986512,-0.163688,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687105,0.217578},8,{0.108789,1.71026,-0.8665},{-1.0,0,0,0,0.986512,-0.163688,0,-0.163688,-0.986512},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687105,0.217578},8,{-0.108789,1.71026,-0.8665},{0,0,-1.0,0.163688,0.986512,0,0.986512,-0.163688,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.794842,0.217578},9,{-0.694555,1.782056,-0.428577},{0.994655,-0.102736,-0.010331,0.103254,0.989664,0.099521,0,-0.100056,0.994982},'slate',0,0},{'corner','LavaCrown',{0.217578,0.794842,0.217578},9,{-0.47814,1.804522,-0.428577},{0.010331,-0.102736,0.994655,-0.099521,0.989664,0.103254,-0.994982,-0.100056,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.794842,0.217578},9,{-0.475893,1.782868,-0.645063},{-0.994655,-0.102736,0.010331,-0.103254,0.989664,-0.099521,0,-0.100056,-0.994982},'slate',0,0},{'corner','LavaCrown',{0.217578,0.794842,0.217578},9,{-0.692307,1.760402,-0.645063},{-0.010331,-0.102736,-0.994655,0.099521,0.989664,-0.103254,0.994982,-0.100056,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580649,0.217578},7,{-0.934247,1.652037,0.108789},{0.980022,-0.198887,0,0.198887,0.980022,0,0,0,1.0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580649,0.217578},7,{-0.721016,1.69531,0.108789},{0,-0.198887,0.980022,0,0.980022,0.198887,-1.0,0,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580649,0.217578},7,{-0.721016,1.69531,-0.108789},{-0.980022,-0.198887,0,-0.198887,0.980022,0,0,0,-1.0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.580649,0.217578},7,{-0.934247,1.652037,-0.108789},{0,-0.198887,-0.980022,0,0.980022,-0.198887,1.0,0,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{-0.691726,1.702559,0.644878},{0.992822,-0.118802,0.013839,0.119605,0.986154,-0.114872,0,0.115703,0.993284},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{-0.47571,1.728582,0.644878},{-0.013839,-0.118802,0.992822,0.114872,0.986154,0.119605,-0.993284,0.115703,0},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{-0.478721,1.753576,0.428762},{-0.992822,-0.118802,-0.013839,-0.119605,0.986154,0.114872,0,0.115703,-0.993284},'slate',0,0},{'corner','LavaCrown',{0.217578,0.687355,0.217578},8,{-0.694737,1.727553,0.428762},{0.013839,-0.118802,-0.992822,-0.114872,0.986154,-0.119605,0.993284,0.115703,0},'slate',0,0},{'corner','LavaCrown',{0.209209,0.853573,0.209209},10,{-0.104605,2.05025,0.104605},{1.0,0,0,0,1.0,0,0,0,1.0},'slate',0,0},{'corner','LavaCrown',{0.209209,0.853573,0.209209},10,{0.104605,2.05025,0.104605},{0,0,1.0,0,1.0,0,-1.0,0,0},'slate',0,0},{'corner','LavaCrown',{0.209209,0.853573,0.209209},10,{0.104605,2.05025,-0.104605},{-1.0,0,0,0,1.0,0,0,0,-1.0},'slate',0,0},{'corner','LavaCrown',{0.209209,0.853573,0.209209},10,{-0.104605,2.05025,-0.104605},{0,0,-1.0,0,1.0,0,1.0,0,0},'slate',0,0},{'box','IvoryHorn',{0.435155,0.550025,0.435155},11,{-1.087888,0.836837,-1.221781},{0.894427,-0.426006,-0.136083,0.447214,0.852013,0.272166,0,-0.30429,0.952579},'sandstone',0,0},{'box','IvoryHorn',{0.295905,0.264101,0.295905},11,{-1.263623,1.188308,-1.322202},{0.894427,-0.443607,-0.056682,0.447214,0.887214,0.113364,0,-0.126745,0.991935},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{-1.426793,1.483079,-1.284827},{0.98387,-0.178174,-0.015936,0.178885,0.979958,0.08765,0,-0.089087,0.996024},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{-1.286825,1.508528,-1.284827},{0.015936,-0.178174,0.98387,-0.08765,0.979958,0.178885,-0.996024,-0.089087,0},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{-1.284558,1.496059,-1.426524},{-0.98387,-0.178174,0.015936,-0.178885,0.979958,-0.08765,0,-0.089087,-0.996024},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{-1.424525,1.47061,-1.426524},{-0.015936,-0.178174,-0.98387,0.08765,0.979958,-0.178885,0.996024,-0.089087,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{-1.04355,-1.271121,-1.257295},{-0.934488,-0.332972,-0.125945,0.355995,-0.874052,-0.330606,0,-0.353783,0.935328},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{-1.223413,-1.202601,-1.257295},{0.125945,-0.332972,-0.934488,0.330606,-0.874052,0.355995,-0.935328,-0.353783,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{-1.199172,-1.138969,-1.437319},{0.934488,-0.332972,0.125945,-0.355995,-0.874052,0.330606,0,-0.353783,-0.935328},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{-1.019309,-1.207488,-1.437319},{-0.125945,-0.332972,0.934488,-0.330606,-0.874052,-0.355995,0.935328,-0.353783,0},'sandstone',0,0},{'box','IvoryHorn',{0.435155,0.550025,0.435155},11,{1.087888,0.836837,-1.221781},{0.894427,0.426006,0.136083,-0.447214,0.852013,0.272166,0,-0.30429,0.952579},'sandstone',0,0},{'box','IvoryHorn',{0.295905,0.264101,0.295905},11,{1.263623,1.188308,-1.322202},{0.894427,0.443607,0.056682,-0.447214,0.887214,0.113364,0,-0.126745,0.991935},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{1.286825,1.508528,-1.284827},{0.98387,0.178174,0.015936,-0.178885,0.979958,0.08765,0,-0.089087,0.996024},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{1.426793,1.483079,-1.284827},{-0.015936,0.178174,0.98387,-0.08765,0.979958,-0.178885,-0.996024,-0.089087,0},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{1.424525,1.47061,-1.426524},{-0.98387,0.178174,-0.015936,0.178885,0.979958,-0.08765,0,-0.089087,-0.996024},'sandstone',0,0},{'corner','IvoryHornTip',{0.142262,0.375739,0.142262},11,{1.284558,1.496059,-1.426524},{0.015936,0.178174,-0.98387,0.08765,0.979958,0.178885,0.996024,-0.089087,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{1.223413,-1.202601,-1.257295},{-0.934488,0.332972,0.125945,-0.355995,-0.874052,-0.330606,0,-0.353783,0.935328},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{1.04355,-1.271121,-1.257295},{-0.125945,0.332972,-0.934488,0.330606,-0.874052,-0.355995,-0.935328,-0.353783,0},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{1.019309,-1.207488,-1.437319},{0.934488,0.332972,-0.125945,0.355995,-0.874052,0.330606,0,-0.353783,-0.935328},'sandstone',0,0},{'corner','IvoryTusk',{0.192472,0.804234,0.192472},11,{1.199172,-1.138969,-1.437319},{0.125945,0.332972,0.934488,-0.330606,-0.874052,0.355995,0.935328,-0.353783,0},'sandstone',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},2,{0.317998,-1.305465,-1.02757},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},3,{-0.351471,-1.305465,-0.968903},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},4,{0.317998,-0.76989,-1.351769},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},2,{-0.351471,-0.76989,-1.351769},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},3,{0.317998,-0.234314,-1.351769},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},4,{-0.351471,-0.234314,-1.351769},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},2,{0.317998,0.301261,-1.351769},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},3,{-0.351471,0.301261,-1.351769},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},4,{0.317998,0.836837,-1.351769},{0.819152,-0.573576,0,0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MagmaFacet',{0.518839,0.552312,0.284524},2,{-0.351471,0.836837,-1.351769},{0.819152,0.573576,0,-0.573576,0.819152,0,0,0,1.0},'slate',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{-0.389481,-0.8201,1.438255},{-0.951057,0.309017,0,0.309017,0.951057,0,0,0,-1.0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{-0.330903,-1.004204,1.597254},{-0.970296,0.241922,0,0.241922,0.970296,0,0,0,-1.0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{-0.409565,-0.728048,1.597254},{-0.978148,-0.207912,0,-0.207912,0.978148,0,0,0,-1.0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{-0.359355,-0.535575,1.597254},{-0.970296,0.241922,0,0.241922,0.970296,0,0,0,-1.0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{-1.6402,0.535575,0.322015},{0,0,1.0,-0.258819,0.965926,0,-0.965926,-0.258819,0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{-1.799199,0.351471,0.380593},{0,0,1.0,0.241922,0.970296,0,-0.970296,0.241922,0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{-1.799199,0.627627,0.301931},{0,0,1.0,-0.207912,0.978148,0,-0.978148,-0.207912,0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{-1.799199,0.8201,0.352141},{0,0,1.0,0.241922,0.970296,0,-0.970296,0.241922,0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{-1.6402,-0.267788,-0.111835},{0,0,1.0,0.309017,0.951057,0,-0.951057,0.309017,0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{-1.799199,-0.451892,-0.053256},{0,0,1.0,0.241922,0.970296,0,-0.970296,0.241922,0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{-1.799199,-0.175736,-0.131919},{0,0,1.0,-0.207912,0.978148,0,-0.978148,-0.207912,0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{-1.799199,0.016737,-0.081708},{0,0,1.0,0.241922,0.970296,0,-0.970296,0.241922,0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{-0.731985,-0.8201,-1.322577},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{-0.790564,-1.004204,-1.481575},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{-0.711901,-0.728048,-1.481575},{0.978148,0.207912,0,-0.207912,0.978148,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{-0.762112,-0.535575,-1.481575},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{0,0.535575,-1.523043},{0.951057,-0.309017,0,0.309017,0.951057,0,0,0,1.0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{-0.058579,0.351471,-1.682042},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{0.020084,0.627627,-1.682042},{0.978148,0.207912,0,-0.207912,0.978148,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{-0.030126,0.8201,-1.682042},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{0.731985,-0.267788,-1.322577},{0.965926,0.258819,0,-0.258819,0.965926,0,0,0,1.0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{0.673407,-0.451892,-1.481575},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{0.75207,-0.175736,-1.481575},{0.978148,0.207912,0,-0.207912,0.978148,0,0,0,1.0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{0.701859,0.016737,-1.481575},{0.970296,-0.241922,0,0.241922,0.970296,0,0,0,1.0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{1.6402,-0.8201,-0.111835},{0,0,-1.0,0.309017,0.951057,0,0.951057,-0.309017,0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{1.799199,-1.004204,-0.170413},{0,0,-1.0,0.241922,0.970296,0,0.970296,-0.241922,0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{1.799199,-0.728048,-0.09175},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{1.799199,-0.535575,-0.141961},{0,0,-1.0,0.241922,0.970296,0,0.970296,-0.241922,0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{1.6402,0.535575,0.322015},{0,0,-1.0,-0.258819,0.965926,0,0.965926,0.258819,0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{1.799199,0.351471,0.263436},{0,0,-1.0,0.241922,0.970296,0,0.970296,-0.241922,0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{1.799199,0.627627,0.342099},{0,0,-1.0,-0.207912,0.978148,0,0.978148,0.207912,0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{1.799199,0.8201,0.291889},{0,0,-1.0,0.241922,0.970296,0,0.970296,-0.241922,0},'neon',0,0},{'corner','MoltenBorder',{0.384945,0.8201,0.251051},17,{0.389481,-0.267788,1.438255},{-0.951057,0.309017,0,0.309017,0.951057,0,0,0,-1.0},'slate',0,0},{'box','MoltenSeam',{0.133894,0.368208,0.075315},18,{0.44806,-0.451892,1.597254},{-0.970296,0.241922,0,0.241922,0.970296,0,0,0,-1.0},'neon',0,0},{'box','MoltenSeam',{0.175736,0.301261,0.075315},19,{0.369397,-0.175736,1.597254},{-0.978148,-0.207912,0,-0.207912,0.978148,0,0,0,-1.0},'neon',0,0},{'box','MoltenSeam',{0.108789,0.184104,0.075315},18,{0.419607,0.016737,1.597254},{-0.970296,0.241922,0,0.241922,0.970296,0,0,0,-1.0},'neon',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-0.731985,-1.154834,1.159184},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{-0.731985,-0.502102,1.222156},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{-0.731985,0.167367,1.222156},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-0.731985,0.887047,1.222156},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-1.539779,-1.154834,0.111835},{0,0,1.0,0.48481,0.87462,0,-0.87462,0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{-1.539779,-0.502102,0.111835},{0,0,1.0,-0.390731,0.920505,0,-0.920505,-0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{-1.539779,0.167367,0.111835},{0,0,1.0,0.48481,0.87462,0,-0.87462,0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-1.539779,0.887047,0.111835},{0,0,1.0,-0.390731,0.920505,0,-0.920505,-0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-1.539779,-1.154834,-0.111835},{0,0,1.0,0.48481,0.87462,0,-0.87462,0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{-1.539779,-0.502102,-0.111835},{0,0,1.0,-0.390731,0.920505,0,-0.920505,-0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{-1.539779,0.167367,-0.111835},{0,0,1.0,0.48481,0.87462,0,-0.87462,0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{-1.539779,0.887047,-0.111835},{0,0,1.0,-0.390731,0.920505,0,-0.920505,-0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{1.293293,-1.154834,-0.111835},{0,0,-1.0,0.48481,0.87462,0,0.87462,-0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{1.539779,-0.502102,-0.111835},{0,0,-1.0,-0.390731,0.920505,0,0.920505,0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{1.539779,0.167367,-0.111835},{0,0,-1.0,0.48481,0.87462,0,0.87462,-0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{1.539779,0.887047,-0.111835},{0,0,-1.0,-0.390731,0.920505,0,0.920505,0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{1.293293,-1.154834,0.111835},{0,0,-1.0,0.48481,0.87462,0,0.87462,-0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{1.539779,-0.502102,0.111835},{0,0,-1.0,-0.390731,0.920505,0,0.920505,0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{1.539779,0.167367,0.111835},{0,0,-1.0,0.48481,0.87462,0,0.87462,-0.48481,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{1.539779,0.887047,0.111835},{0,0,-1.0,-0.390731,0.920505,0,0.920505,0.390731,0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{0.731985,-1.154834,0.988176},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{0.731985,-0.502102,1.222156},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{0.731985,0.167367,1.222156},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{0.731985,0.887047,1.222156},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{0,-1.154834,1.304386},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},21,{0,-0.502102,1.422622},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},22,{0,0.167367,1.422622},{-0.87462,0.48481,0,0.48481,0.87462,0,0,0,-1.0},'slate',0,0},{'corner','RedSideShard',{0.485365,0.635996,0.284524},20,{0,0.887047,1.422622},{-0.920505,-0.390731,0,-0.390731,0.920505,0,0,0,-1.0},'slate',0,0}},bounds={3.673713,4.375,3.354611},displayScale=1.2},
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
    local buildSlice=os.clock()
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
        if i%40==0 and os.clock()-buildSlice>.006 then
            task.wait()
            buildSlice=os.clock()
        end
    end
    -- Wings, horns and halos must not make the main egg look undersized.
    -- Retain the prior body-based display sizing, then reduce every egg
    -- uniformly by 25%. Scale once so details and shell stay attached.
    local bodyHeight=bodyMax-bodyMin
    if bodyHeight>0 and bodyHeight<math.huge then
        local displayScale=(design.displayScale or math.max(1.20,4.25/bodyHeight))*0.75
        m:ScaleTo(displayScale)
        m:SetAttribute('SAE_DISPLAY_SCALE',displayScale)
        m:SetAttribute('SAE_BODY_HEIGHT',bodyHeight*displayScale)
    end
    m:SetAttribute('SAE_REFERENCE_DETAIL','Sculpted3D')
    m:SetAttribute('SAE_APPEARANCE','Native 3D features; no image projection')
    return finalize(m,root)
end

local function nightPet()
    local m=Instance.new('Model')
    m.Name='Night Flame'
    local skin=rgb(36,37,55)
    local shadow=rgb(19,20,32)
    local armor=rgb(42,42,61)
    local armor2=rgb(55,53,75)
    local edge=rgb(73,80,112)
    local cyan=rgb(177,255,247)
    local cyanDim=rgb(84,194,205)
    local root=ball(m,'Core',Vector3.new(3.25,5.1,2.35),skin,CFrame.new(),Enum.Material.Slate)

    -- Broad, armored chest tapering into a compact waist.
    ball(m,'Chest',Vector3.new(3.45,3.5,2.55),skin,CFrame.new(0,.85,.05),Enum.Material.Slate)
    ball(m,'Waist',Vector3.new(2.2,2.15,1.9),shadow,CFrame.new(0,-1.48,.02),Enum.Material.Slate)
    part(m,'SternumArmor',Vector3.new(2.35,2.9,.36),armor,CFrame.new(0,.62,-1.18),Enum.Material.Metal)
    for _,sx in ipairs({-1,1}) do
        wedge(m,'PectoralPlate',Vector3.new(1.42,1.15,.45),armor2,CFrame.new(sx*.66,1.28,-1.38)*CFrame.Angles(0,0,math.rad(-sx*8)),Enum.Material.Metal)
        wedge(m,'HipGuard',Vector3.new(1.12,1.35,.42),armor,CFrame.new(sx*.78,-1.82,-.72)*CFrame.Angles(0,0,math.rad(sx*10)),Enum.Material.Metal)
    end
    for row=0,2 do
        for _,sx in ipairs({-1,1}) do
            part(m,'AbdominalScale',Vector3.new(.72,.42,.2),row==1 and armor2 or armor,CFrame.new(sx*.43,-.38-row*.48,-1.0),Enum.Material.Metal)
        end
    end

    -- A snarling wolf head with swept ears, layered cheek fur, muzzle and visible teeth.
    ball(m,'WolfSkull',Vector3.new(2.45,2.35,2.1),shadow,CFrame.new(0,3.42,-.06),Enum.Material.Slate)
    ball(m,'Mane',Vector3.new(2.95,2.25,1.65),armor,CFrame.new(0,3.2,.27),Enum.Material.Slate)
    wedge(m,'EarL',Vector3.new(.72,1.28,.68),shadow,CFrame.new(-.82,4.53,-.1)*CFrame.Angles(0,0,math.rad(13)),Enum.Material.Slate)
    wedge(m,'EarR',Vector3.new(.72,1.28,.68),shadow,CFrame.new(.82,4.53,-.1)*CFrame.Angles(0,0,math.rad(-13)),Enum.Material.Slate)
    wedge(m,'ManeTuftL',Vector3.new(.82,1.22,.72),armor2,CFrame.new(-.82,4.0,.62)*CFrame.Angles(0,0,math.rad(22)),Enum.Material.Slate)
    wedge(m,'ManeTuftR',Vector3.new(.82,1.22,.72),armor2,CFrame.new(.82,4.0,.62)*CFrame.Angles(0,0,math.rad(-22)),Enum.Material.Slate)
    part(m,'HeavyBrow',Vector3.new(1.88,.42,.42),armor2,CFrame.new(0,3.85,-1.08),Enum.Material.Metal)
    eye(m,-.55,3.58,-1.16,cyanDim,Vector3.new(.36,.22,.15))
    eye(m,.55,3.58,-1.16,cyanDim,Vector3.new(.36,.22,.15))
    wedge(m,'UpperMuzzle',Vector3.new(1.15,.74,.95),armor,CFrame.new(0,3.02,-1.03),Enum.Material.Slate)
    part(m,'OpenJaw',Vector3.new(1.03,.6,.18),rgb(7,8,14),CFrame.new(0,2.67,-1.47),Enum.Material.SmoothPlastic)
    wedge(m,'LowerJaw',Vector3.new(1.18,.44,.64),shadow,CFrame.new(0,2.42,-1.08),Enum.Material.Slate)
    for _,sx in ipairs({-1,1}) do
        wedge(m,'Fang',Vector3.new(.2,.48,.24),rgb(177,198,213),CFrame.new(sx*.31,2.79,-1.56)*CFrame.Angles(math.rad(180),0,0),Enum.Material.SmoothPlastic)
        wedge(m,'CheekFur',Vector3.new(.72,1.08,.65),armor2,CFrame.new(sx*1.0,3.1,-.62)*CFrame.Angles(0,0,math.rad(-sx*20)),Enum.Material.Slate)
    end

    -- Exactly four arms: a long upper pair and a lower pair, all built from connected anatomy.
    for _,arm in ipairs({{y=1.5,spread=1},{y=-.28,spread=.88}}) do
        for _,sx in ipairs({-1,1}) do
            local y=arm.y
            local midX=sx*2.78
            local wristX=sx*4.15
            local handX=sx*4.78
            local down=arm.spread
            ball(m,'Shoulder',Vector3.new(1.48,1.5,1.28),skin,CFrame.new(sx*1.82,y+.12,-.02),Enum.Material.Slate)
            wedge(m,'ShoulderArmor',Vector3.new(1.62,1.28,1.0),armor2,CFrame.new(sx*2.03,y+.35,-.63)*CFrame.Angles(0,0,math.rad(-sx*13)),Enum.Material.Metal)
            part(m,'Bicep',Vector3.new(2.05,.94,1.02),skin,CFrame.new(sx*2.55,y,-.04)*CFrame.Angles(0,0,math.rad(sx*11)),Enum.Material.Slate)
            ball(m,'Elbow',Vector3.new(.95,.92,.9),shadow,CFrame.new(midX,y-.14*down,-.06),Enum.Material.Slate)
            part(m,'Bracer',Vector3.new(1.75,.82,.91),armor,CFrame.new(sx*3.52,y-.25*down,-.1)*CFrame.Angles(0,0,math.rad(sx*8)),Enum.Material.Metal)
            for tile=1,3 do
                wedge(m,'BracerScale',Vector3.new(.56,.48,.26),tile==2 and armor2 or edge,CFrame.new(sx*(3.03+tile*.34),y+.14*down,-.62)*CFrame.Angles(0,0,math.rad(sx*8)),Enum.Material.Metal)
            end
            ball(m,'Wrist',Vector3.new(.7,.72,.7),shadow,CFrame.new(wristX,y-.34*down,-.12),Enum.Material.Slate)
            ball(m,'ClawPalm',Vector3.new(1.12,.94,.84),armor,CFrame.new(handX,y-.4*down,-.16),Enum.Material.Slate)
            for finger=1,3 do
                local fx=handX+sx*(.22+(finger-2)*.35)
                local fy=y-.25*down-(finger-2)*.28
                wedge(m,'DarkClaw',Vector3.new(.27,.72,.3),edge,CFrame.new(fx,fy,-.34)*CFrame.Angles(0,0,math.rad(sx*105)),Enum.Material.Metal)
            end
            wedge(m,'ThumbClaw',Vector3.new(.3,.65,.32),edge,CFrame.new(sx*(handX-.42),y-.76*down,-.3)*CFrame.Angles(0,0,math.rad(-sx*50)),Enum.Material.Metal)
        end
    end

    -- Heavy bent legs, plated knees and wolf-like feet with clear forward claws.
    for _,sx in ipairs({-1,1}) do
        part(m,'Thigh',Vector3.new(1.55,2.25,1.55),skin,CFrame.new(sx*.84,-2.62,.08)*CFrame.Angles(0,0,math.rad(-sx*5)),Enum.Material.Slate)
        wedge(m,'ThighPlate',Vector3.new(1.28,1.42,.38),armor,CFrame.new(sx*.88,-2.38,-.79)*CFrame.Angles(0,0,math.rad(-sx*7)),Enum.Material.Metal)
        ball(m,'Knee',Vector3.new(1.18,.86,1.0),shadow,CFrame.new(sx*.9,-3.6,-.04),Enum.Material.Slate)
        part(m,'Greave',Vector3.new(1.1,1.85,1.18),armor,CFrame.new(sx*1.02,-4.45,-.05)*CFrame.Angles(0,0,math.rad(sx*8)),Enum.Material.Metal)
        wedge(m,'ShinPlate',Vector3.new(.9,1.25,.32),armor2,CFrame.new(sx*1.02,-4.38,-.68)*CFrame.Angles(0,0,math.rad(sx*8)),Enum.Material.Metal)
        ball(m,'WolfFoot',Vector3.new(1.55,.82,1.72),shadow,CFrame.new(sx*1.07,-5.52,-.35),Enum.Material.Slate)
        for toe=1,3 do
            wedge(m,'FootClaw',Vector3.new(.3,.58,.5),edge,CFrame.new(sx*1.07+(toe-2)*.43,-5.62,-1.05),Enum.Material.Metal)
        end
    end

    -- Bright branching chest sigil with a central knot and long downward ray.
    part(m,'RuneStem',Vector3.new(.23,1.72,.15),cyan,CFrame.new(0,.62,-1.54),Enum.Material.Neon)
    part(m,'RuneCrossbar',Vector3.new(1.72,.2,.15),cyan,CFrame.new(0,1.05,-1.56),Enum.Material.Neon)
    for _,ray in ipairs({
        {x=-.48,y=.74,a=-42},{x=.48,y=.74,a=42},
        {x=-.66,y=.28,a=-28},{x=.66,y=.28,a=28},
        {x=-.34,y=-.12,a=36},{x=.34,y=-.12,a=-36},
    }) do
        part(m,'RuneBranch',Vector3.new(.15,.78,.13),cyan,CFrame.new(ray.x,ray.y,-1.57)*CFrame.Angles(0,0,math.rad(ray.a)),Enum.Material.Neon)
    end
    for _,sx in ipairs({-1,1}) do
        part(m,'RuneTail',Vector3.new(.12,.62,.12),cyanDim,CFrame.new(sx*.12,-.53,-1.55)*CFrame.Angles(0,0,math.rad(sx*8)),Enum.Material.Neon)
    end
    return finalize(m,root)
end
local function luminousPet()
    local m=Instance.new('Model')
    m.Name='Luminous Cthulhu'
    local navy=rgb(16,34,80)
    local deep=rgb(10,22,58)
    local blue=rgb(31,63,133)
    local mid=rgb(48,91,173)
    local membrane=rgb(91,171,235)
    local ice=rgb(190,239,255)
    local cyan=rgb(76,208,255)
    local root=ball(m,'Core',Vector3.new(4.25,5.3,2.9),navy,CFrame.new(),Enum.Material.Slate)

    -- Hunched shoulders, compact waist and bent legs create the monster's broad stance.
    ball(m,'Ribcage',Vector3.new(4.15,4.1,2.75),navy,CFrame.new(0,.62,.02),Enum.Material.Slate)
    ball(m,'Abdomen',Vector3.new(2.75,2.35,2.15),deep,CFrame.new(0,-1.92,.02),Enum.Material.Slate)
    for _,sx in ipairs({-1,1}) do
        ball(m,'ShoulderMass',Vector3.new(1.72,1.85,1.62),navy,CFrame.new(sx*1.88,1.62,.02),Enum.Material.Slate)
        wedge(m,'ShoulderArmor',Vector3.new(1.35,1.1,.62),blue,CFrame.new(sx*1.95,2.06,-.64)*CFrame.Angles(0,0,math.rad(-sx*16)),Enum.Material.Metal)
        part(m,'UpperArm',Vector3.new(1.18,2.25,1.24),navy,CFrame.new(sx*2.52,.25,-.02)*CFrame.Angles(0,0,math.rad(sx*15)),Enum.Material.Slate)
        ball(m,'Elbow',Vector3.new(1.02,1.0,.95),deep,CFrame.new(sx*2.85,-.92,-.08),Enum.Material.Slate)
        part(m,'Forearm',Vector3.new(1.05,1.65,1.03),blue,CFrame.new(sx*2.95,-1.72,-.11)*CFrame.Angles(0,0,math.rad(-sx*8)),Enum.Material.Slate)
        ball(m,'ClawPalm',Vector3.new(.95,.92,.82),navy,CFrame.new(sx*3.0,-2.68,-.16),Enum.Material.Slate)
        for claw=1,3 do
            wedge(m,'IceClaw',Vector3.new(.29,.72,.3),ice,CFrame.new(sx*(3.0+(claw-2)*.39),-3.24,-.33),Enum.Material.Ice)
        end
        part(m,'Thigh',Vector3.new(1.42,2.2,1.4),navy,CFrame.new(sx*1.0,-3.2,.12)*CFrame.Angles(0,0,math.rad(-sx*11)),Enum.Material.Slate)
        ball(m,'Knee',Vector3.new(1.1,.95,1.0),deep,CFrame.new(sx*1.15,-4.08,-.04),Enum.Material.Slate)
        part(m,'LowerLeg',Vector3.new(1.12,1.55,1.2),blue,CFrame.new(sx*1.26,-4.86,-.02)*CFrame.Angles(0,0,math.rad(sx*9)),Enum.Material.Slate)
        ball(m,'TalonedFoot',Vector3.new(1.45,.78,1.5),deep,CFrame.new(sx*1.3,-5.78,-.32),Enum.Material.Slate)
        for claw=1,3 do
            wedge(m,'FootTalons',Vector3.new(.28,.6,.52),ice,CFrame.new(sx*(1.3+(claw-2)*.4),-5.92,-.95),Enum.Material.Ice)
        end
    end

    -- Tentacled cephalopod head: crown lobes, recessed face, and five long curling tendrils.
    ball(m,'Head',Vector3.new(2.75,2.5,2.25),deep,CFrame.new(0,3.22,-.02),Enum.Material.Slate)
    for i=-2,2 do
        local sx=i*.48
        local h=(i==0) and 1.75 or 1.35
        wedge(m,'CrownLobe',Vector3.new(.8,h,.72),i%2==0 and blue or navy,CFrame.new(sx,4.3+(i==0 and .28 or 0),.02)*CFrame.Angles(0,0,math.rad(-i*9)),Enum.Material.Slate)
    end
    part(m,'FaceRecess',Vector3.new(1.3,1.12,.16),deep,CFrame.new(0,3.18,-1.18),Enum.Material.SmoothPlastic)
    eye(m,-.43,3.3,-1.31,cyan,Vector3.new(.3,.22,.13))
    eye(m,.43,3.3,-1.31,cyan,Vector3.new(.3,.22,.13))
    local tentaclePaths={
        {{-.78,3.2,-1.32},{-1.15,2.6,-1.45},{-1.32,1.85,-1.52},{-1.1,1.05,-1.55},{-.62,.72,-1.58}},
        {{-.42,3.05,-1.4},{-.68,2.35,-1.55},{-.62,1.62,-1.6},{-.28,1.04,-1.62},{.16,.85,-1.62}},
        {{0,3.02,-1.43},{.12,2.3,-1.58},{.48,1.72,-1.62},{.92,1.25,-1.6},{1.08,.62,-1.58}},
        {{.4,3.05,-1.4},{.82,2.42,-1.52},{1.1,1.8,-1.58},{.98,1.15,-1.62},{.62,.7,-1.62}},
        {{.8,3.18,-1.3},{1.22,2.62,-1.42},{1.42,2.02,-1.5},{1.28,1.45,-1.56},{1.52,1.08,-1.58}},
    }
    for index,path in ipairs(tentaclePaths) do
        for point=1,#path do
            local v=path[point]
            local width=point==1 and .66 or (point==#path and .42 or .54)
            ball(m,'FaceTendril',Vector3.new(width,.72,width),index%2==0 and blue or navy,CFrame.new(v[1],v[2],v[3]),Enum.Material.Slate)
        end
        for point=1,#path-1 do
            local a,b=path[point],path[point+1]
            local dx,dy=b[1]-a[1],b[2]-a[2]
            local length=math.sqrt(dx*dx+dy*dy)
            part(m,'TendrilBridge',Vector3.new(.42,length,.42),index%2==0 and blue or navy,CFrame.new((a[1]+b[1])/2,(a[2]+b[2])/2,(a[3]+b[3])/2)*CFrame.Angles(0,0,-math.atan2(dx,dy)),Enum.Material.Slate)
        end
        local last=path[#path]
        wedge(m,'TendrilPoint',Vector3.new(.4,.62,.38),ice,CFrame.new(last[1],last[2]-.3,last[3]),Enum.Material.Ice)
    end

    -- Large up-swept bat wings with a dark rim, broad blue membrane, scallops and luminous veins.
    for _,sx in ipairs({-1,1}) do
        local wingAngle=math.rad(-sx*27)
        wedge(m,'WingBase',Vector3.new(2.25,4.45,.52),navy,CFrame.new(sx*3.32,3.45,.24)*CFrame.Angles(0,0,wingAngle),Enum.Material.Slate)
        wedge(m,'WingMembrane',Vector3.new(1.82,3.92,.24),membrane,CFrame.new(sx*3.25,3.5,-.08)*CFrame.Angles(0,0,wingAngle),Enum.Material.Ice)
        wedge(m,'WingOuterRim',Vector3.new(.48,4.7,.58),blue,CFrame.new(sx*4.48,3.65,.13)*CFrame.Angles(0,0,wingAngle+math.rad(sx*3)),Enum.Material.Slate)
        wedge(m,'WingHook',Vector3.new(.68,1.65,.5),navy,CFrame.new(sx*4.68,5.55,.12)*CFrame.Angles(0,0,math.rad(-sx*45)),Enum.Material.Slate)
        for feather=1,4 do
            local x=sx*(2.35+feather*.45)
            local y=2.15-(feather%2)*.36
            wedge(m,'WingScallop',Vector3.new(.78,1.48,.32),feather%2==0 and membrane or rgb(117,198,247),CFrame.new(x,y,-.25)*CFrame.Angles(0,0,math.rad(-sx*(38+feather*5))),Enum.Material.Ice)
        end
        part(m,'WingVein',Vector3.new(.14,3.45,.12),cyan,CFrame.new(sx*3.22,3.25,-.29)*CFrame.Angles(0,0,wingAngle),Enum.Material.Neon)
        for vein=1,3 do
            part(m,'WingBranch',Vector3.new(.1,1.42,.1),cyan,CFrame.new(sx*(2.65+vein*.34),3.8-vein*.6,-.3)*CFrame.Angles(0,0,math.rad(-sx*(48+vein*9))),Enum.Material.Neon)
        end

        -- Icy flower-like crystals cluster at shoulders, elbows, wrists and outer forearms.
        for cluster=1,4 do
            local cx=sx*(2.0+cluster*.25)
            local cy=1.7-(cluster-1)*.82
            for shard=1,3 do
                wedge(m,'IceBloomShard',Vector3.new(.3,.78,.3),shard==2 and cyan or ice,CFrame.new(cx+sx*(shard-2)*.22,cy+(shard==2 and .15 or 0),-.78)*CFrame.Angles(0,0,math.rad(-sx*(20+(shard-2)*30))),Enum.Material.Ice)
            end
        end
    end

    -- Bright branching frost veins are inlaid across the chest and limbs.
    for _,sx in ipairs({-1,1}) do
        for line=1,4 do
            part(m,'FrostCrack',Vector3.new(.12,1.02,.1),cyan,CFrame.new(sx*(.38+line*.19),.9-line*.48,-1.31)*CFrame.Angles(0,0,math.rad(sx*(24+line*10))),Enum.Material.Neon)
        end
        part(m,'ArmFrostCrack',Vector3.new(.11,1.45,.1),cyan,CFrame.new(sx*2.95,-1.45,-.66)*CFrame.Angles(0,0,math.rad(-sx*8)),Enum.Material.Neon)
    end
    return finalize(m,root)
end
local function star()
    local m=Instance.new('Model') m.Name='Star'
    local gold,edge,dark=rgb(255,233,63),rgb(229,188,24),rgb(50,43,20)
    local root=part(m,'StarCore',Vector3.new(1,1,.8),gold,CFrame.new(),MAT)
    -- A true upright five-point outline with a shallow, studded toy surface.
    local corners={}
    for index=0,9 do
        local angle=math.pi*.5+index*math.pi/5
        local radius=index%2==0 and 3.35 or 1.70
        corners[#corners+1]=Vector2.new(math.cos(angle)*radius,math.sin(angle)*radius)
    end
    -- Round both the five outer tips and the valleys with quadratic fillets.
    local vertices={}
    for index,corner in ipairs(corners) do
        local previous=corners[(index-2)%#corners+1]
        local following=corners[index%#corners+1]
        local trim=index%2==1 and .26 or .16
        local entry=corner+(previous-corner)*trim
        local exit=corner+(following-corner)*trim
        for sample=0,12 do
            local t=sample/12
            local point=entry*((1-t)^2)+corner*(2*(1-t)*t)+exit*(t*t)
            vertices[#vertices+1]=point
        end
    end
    local function intersections(y)
        local xs={}
        for index,p in ipairs(vertices) do
            local q=vertices[index%#vertices+1]
            if (p.Y<=y and q.Y>y) or (q.Y<=y and p.Y>y) then
                xs[#xs+1]=p.X+(y-p.Y)*(q.X-p.X)/(q.Y-p.Y)
            end
        end
        table.sort(xs)
        return xs
    end
    local function inside(x,y)
        local xs=intersections(y)
        for index=1,#xs-1,2 do
            if x>=xs[index] and x<=xs[index+1] then return true end
        end
        return false
    end
    local step=6.7/96
    for row=0,95 do
        local y=-3.35+(row+.5)*step
        local xs=intersections(y)
        for index=1,#xs-1,2 do
            local width=xs[index+1]-xs[index]
            local x=(xs[index]+xs[index+1])*.5
            if width>.05 then
                part(m,'StarOutline',Vector3.new(width,step+.006,1.18),edge,CFrame.new(x,y,.04),MAT)
                part(m,'StarFace',Vector3.new(math.max(.05,width-.045),step+.008,1.12),gold,CFrame.new(x,y,-.05),MAT)
            end
        end
    end
    for ix=-3,3 do
        for iy=-3,3 do
            local x,y=ix*.74,iy*.74
            local onFace=math.abs(x)<1.32 and y>-.95 and y<.85
            if not onFace and inside(x-.25,y-.25) and inside(x+.25,y+.25)
                and inside(x-.25,y+.25) and inside(x+.25,y-.25) then
                part(m,'StudEdge',Vector3.new(.46,.40,.045),edge,CFrame.new(x,y,-.64),MAT)
                part(m,'Stud',Vector3.new(.38,.33,.10),rgb(255,242,92),CFrame.new(x,y,-.70),MAT)
            end
        end
    end
    for _,side in ipairs({-1,1}) do
        eye(m,side*.77,.12,-.73,dark,Vector3.new(.54,.69,.14))
        ball(m,'EyeShine',Vector3.new(.14,.17,.06),rgb(255,252,205),CFrame.new(side*.77-.08,.28,-.82),MAT)
    end
    local mouth={Vector3.new(-.43,-.47,-.78),Vector3.new(-.22,-.65,-.78),
        Vector3.new(0,-.48,-.78),Vector3.new(.22,-.65,-.78),Vector3.new(.43,-.47,-.78)}
    for index=1,#mouth-1 do
        local p,q=mouth[index],mouth[index+1]
        part(m,'CuteSmile',Vector3.new(.085,.085,(q-p).Magnitude+.035),dark,CFrame.lookAt((p+q)*.5,q),MAT)
    end
    local attachment=Instance.new('Attachment') attachment.Position=Vector3.new(0,3.45,0) attachment.Parent=root
    local sparkle=Instance.new('ParticleEmitter') sparkle.Name='StarGlints'
    sparkle.Texture='rbxasset://textures/particles/sparkles_main.dds'
    sparkle.Color=ColorSequence.new(rgb(255,248,178),rgb(255,255,245))
    sparkle.Size=NumberSequence.new(.15,0) sparkle.Transparency=NumberSequence.new(.15,1)
    sparkle.Rate=3 sparkle.Lifetime=NumberRange.new(.35,.7) sparkle.Speed=NumberRange.new(.3,.7)
    sparkle.SpreadAngle=Vector2.new(35,35) sparkle.LightEmission=.6 sparkle.Parent=attachment
    m:SetAttribute('SAE_STAR_REFERENCE','Rounded yellow five-point studded smiling star')
    return finalize(m,root)
end

local function refEgg(name) return function() return buildSculptedEgg(name) end end
-- Custom treadmill geometry follows the supplied shop art, with a full running deck.
local function detailTreadmill(m,croc)
    -- Replace the simple face blocks with layered eyes, masks, ears and sculpture.
    local removeNames={RabbitEar=true,EarInset=true,RabbitHead=true,RabbitMuzzle=true,EyeSocket=true,BlueEye=true,Pupil=true,RedBrow=true,Nose=true,Smile=true,ShoulderArmor=true,ConsoleArmor=true,ConsoleEdgeLight=true,ArmorFoot=true,FootRedTrim=true,PawPad=true,PawToe=true,CrocodileHead=true,CrocodileSnout=true,LowerJaw=true,CrocodileEye=true,CrocodilePupil=true,EyeShine=true,Nostril=true,CrocodileTooth=true,ExplorerHatBrim=true,ExplorerHatCrown=true,HatBand=true,HatBadge=true,PortalStone=true,ArchStone=true,JungleLeaf=true,CrystalPlinth=true,EmeraldCrystal=true,WaterfallChannel=true,Waterfall=true,PoolRim=true,WaterPool=true,SpeedArrow=true}
    for _,child in ipairs(m:GetChildren()) do if removeNames[child.Name] then child:Destroy() end end
    local white=rgb(240,243,248)
    local black=rgb(15,22,31)
    local red=rgb(224,23,32)
    local cyan=rgb(0,215,255)
    local lime=rgb(111,255,9)
    local stone=rgb(151,155,116)
    local function box(n,size,color,x,y,z,material,rotation)
        return part(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),material or MAT)
    end
    local function orb(n,size,color,x,y,z,material,rotation)
        return ball(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),material or MAT)
    end
    local function bar(n,a,b,width,color,material)
        local delta=b-a
        if math.abs(delta.Unit.Y)>.99 then return part(m,n,Vector3.new(width,delta.Magnitude,width),color,CFrame.new((a+b)*.5),material or MAT) end
        return part(m,n,Vector3.new(width,width,delta.Magnitude),color,CFrame.lookAt((a+b)*.5,b),material or MAT)
    end
    local function glow(anchor,color,diameter,power)
        local light=Instance.new('PointLight')
        light.Color=color light.Brightness=power or .7 light.Range=diameter or 5 light.Shadows=false light.Parent=anchor
        local halo=Instance.new('BillboardGui')
        halo.Name='LocalLightHalo' halo.Adornee=anchor halo.AlwaysOnTop=false
        halo.LightInfluence=0 halo.Size=UDim2.fromScale((diameter or 5)*.48,(diameter or 5)*.48)
        halo.MaxDistance=100 halo.Parent=anchor
        local image=Instance.new('ImageLabel')
        image.BackgroundTransparency=1 image.Size=UDim2.fromScale(1,1)
        image.Image='rbxasset://textures/glow.png'
        image.ImageColor3=color image.ImageTransparency=.72 image.Parent=halo
    end
    local function chevron(y,color)
        -- Broad arrow faces instead of thin diagonal rods.
        for _,side in ipairs({-1,1}) do
            part(m,'ArrowFace',Vector3.new(1.16,.42,.13),color,CFrame.new(side*.43,y,-3.83)*CFrame.Angles(0,0,math.rad(-side*35)),NEON)
        end
    end
    chevron(3.75,croc and lime or cyan)
    chevron(2.75,croc and lime or cyan)
    local arrowGlow=box('DisplayGlow',Vector3.new(.13,.13,.13),croc and lime or cyan,0,3.3,-3.75,NEON)
    arrowGlow.Transparency=1
    glow(arrowGlow,croc and lime or cyan,5,.65)
    if not croc then
        local function ear(x,y,z,height,angle)
            local rot=CFrame.Angles(0,0,math.rad(angle))
            orb('EarWhiteArmor',Vector3.new(1.1,height,.56),white,x,y,z,MAT,rot)
            orb('EarRedRim',Vector3.new(.82,height*.87,.21),red,x,y,z+.31,NEON,rot)
            orb('EarBlackInset',Vector3.new(.65,height*.78,.13),black,x,y,z+.43,MAT,rot)
        end
        ear(1.13,8.0,-4.02,3.35,-24)
        ear(-.92,7.35,-4.04,2.25,20)
        ear(-1.62,8.14,-4.0,1.95,72)
        box('BentEarCap',Vector3.new(.95,.18,1.0),white,-2.23,8.39,-3.97,MAT,CFrame.Angles(0,0,math.rad(15)))
        orb('RabbitCranium',Vector3.new(3.66,1.9,1.75),white,0,6.05,-4.05)
        orb('RabbitJaw',Vector3.new(2.92,.91,1.25),rgb(216,224,230),0,5.48,-3.75)
        for _,side in ipairs({-1,1}) do
            local tilt=CFrame.Angles(0,0,math.rad(side*9))
            orb('RedEyeMask',Vector3.new(1.72,.96,.44),red,side*.88,6.13,-3.29,MAT,tilt)
            orb('EyeRecess',Vector3.new(1.34,.77,.32),black,side*.88,6.12,-3.03,MAT,tilt)
            orb('EyeWhite',Vector3.new(1.10,.66,.20),white,side*.88,6.11,-2.84,MAT,tilt)
            orb('BlueIris',Vector3.new(.56,.61,.15),cyan,side*.82,6.09,-2.71,NEON)
            orb('EyePupil',Vector3.new(.30,.46,.12),rgb(4,15,26),side*.80,6.1,-2.61)
            orb('EyeCatchlight',Vector3.new(.19,.19,.08),white,side*.80-.11,6.28,-2.53)
            orb('SmallEyeCatchlight',Vector3.new(.075,.075,.06),white,side*.80+.12,5.98,-2.53)
            part(m,'AngledWhiteBrow',Vector3.new(1.51,.48,.65),white,CFrame.new(side*.91,6.61,-3.13)*CFrame.Angles(0,0,math.rad(side*17)),MAT)
            bar('MaskEdge',Vector3.new(side*.2,6.39,-2.88),Vector3.new(side*1.65,6.62,-3.02),.11,red)
            orb('MuzzleLobe',Vector3.new(1.55,.73,.64),white,side*.49,5.64,-3.02)
            wedge(m,'CheekArmor',Vector3.new(.7,.7,.8),white,CFrame.new(side*1.55,5.86,-3.46)*CFrame.Angles(0,0,math.rad(side*25)),MAT)
        end
        orb('RabbitNose',Vector3.new(.55,.26,.25),black,0,5.79,-2.61)
        bar('Philtrum',Vector3.new(0,5.68,-2.57),Vector3.new(0,5.43,-2.58),.045,black)
        local smile={{-.78,5.69},{-.62,5.54},{-.38,5.45},{0,5.41},{.38,5.45},{.62,5.54},{.78,5.69}}
        for i=1,#smile-1 do bar('CurvedSmile',Vector3.new(smile[i][1],smile[i][2],-2.61),Vector3.new(smile[i+1][1],smile[i+1][2],-2.61),.052,black) end
        for _,side in ipairs({-1,1}) do
            box('ColumnRedSpine',Vector3.new(.74,4.25,1.13),red,side*2.04,3.35,-4.12)
            box('ColumnWhiteFace',Vector3.new(.52,3.7,.23),white,side*2.04,3.3,-3.43)
            local strip=box('RedNeonColumn',Vector3.new(.13,3.15,.14),rgb(255,35,30),side*1.66,3.13,-3.64,NEON)
            if side==1 then glow(strip,rgb(255,35,30),3,.45) end
            for _,y in ipairs({1.72,4.95}) do
                part(m,'RedShoulderFin',Vector3.new(.95,1.35,.74),red,CFrame.new(side*2.43,y,-4.18)*CFrame.Angles(0,0,math.rad(-side*27)),MAT)
                bar('FinLight',Vector3.new(side*2.4,y-.46,-3.75),Vector3.new(side*2.79,y+.39,-3.75),.085,rgb(255,49,41),NEON)
            end
            part(m,'ShoulderWhiteHousing',Vector3.new(.72,1.1,.42),white,CFrame.new(side*2.18,5.05,-3.59)*CFrame.Angles(0,0,math.rad(-side*24)),MAT)
            box('ShoulderDarkScreen',Vector3.new(.38,.69,.12),black,side*2.18,5.02,-3.27)
            for k=0,1 do box('ShoulderCyanScreen',Vector3.new(.31,.12,.08),cyan,side*2.18,4.86+k*.29,-3.17,NEON) end
            -- Octagonal white/red badge frame with a rabbit silhouette.
            cyl(m,'ArmBadgeBack',Vector3.new(.16,1.33,1.33),black,CFrame.new(side*2.04,3.55,-3.18)*CFrame.Angles(0,math.pi/2,0),MAT)
            for i=1,8 do
                local t=(i-1)*math.pi/4+math.pi/8
                local u=i*math.pi/4+math.pi/8
                bar('BadgeWhiteBevel',Vector3.new(side*2.04+math.cos(t)*.73,3.55+math.sin(t)*.73,-3.12),Vector3.new(side*2.04+math.cos(u)*.73,3.55+math.sin(u)*.73,-3.12),.15,white)
                bar('BadgeRedInset',Vector3.new(side*2.04+math.cos(t)*.59,3.55+math.sin(t)*.59,-3.03),Vector3.new(side*2.04+math.cos(u)*.59,3.55+math.sin(u)*.59,-3.03),.07,red)
            end
            orb('RabbitBadgeHead',Vector3.new(.43,.34,.08),red,side*2.04,3.34,-2.99)
            for _,earSide in ipairs({-1,1}) do orb('RabbitBadgeEar',Vector3.new(.14,.55,.08),red,side*2.04+earSide*.15,3.68,-2.99,MAT,CFrame.Angles(0,0,math.rad(-earSide*23))) end
            box('LowerArmScreen',Vector3.new(.39,.76,.13),black,side*2.04,2.12,-3.24)
            for k=0,1 do box('ArmCyanLight',Vector3.new(.28,.12,.09),cyan,side*2.04,1.95+k*.31,-3.14,NEON) end
            -- Thick angled side armor and illuminated channels down to the front paws.
            bar('WhiteSideArmor',Vector3.new(side*2.56,.92,3.6),Vector3.new(side*2.56,2.02,-2.5),.61,white)
            bar('RedSideSpine',Vector3.new(side*2.84,.76,3.5),Vector3.new(side*2.84,1.85,-2.45),.30,red)
            bar('SideBlackChannel',Vector3.new(side*2.58,1.18,2.8),Vector3.new(side*2.58,1.89,-1.7),.30,black)
            bar('SideCyanChannel',Vector3.new(side*2.6,1.2,2.7),Vector3.new(side*2.6,1.91,-1.6),.10,cyan,NEON)
            box('PawHousingRed',Vector3.new(1.23,1.15,.93),red,side*2.48,.91,4.61)
            box('PawHousingWhite',Vector3.new(1.07,1.06,.25),white,side*2.48,.99,5.15)
            orb('PawDarkInset',Vector3.new(.88,.86,.13),black,side*2.48,1.01,5.32)
            local pad=orb('CyanPawPad',Vector3.new(.39,.34,.10),cyan,side*2.48,.84,5.41,NEON)
            for toe=0,3 do
                local x=(toe-1.5)*.19
                orb('CyanPawToe',Vector3.new(.20,.26,.10),cyan,side*2.48+x,1.11+(.5-math.abs(x))*.22,5.41,NEON)
            end
            glow(pad,cyan,3,.6)
            box('PawBottomBumper',Vector3.new(1.28,.18,.43),red,side*2.48,.38,5.2)
            for _,z in ipairs({-2.4,.2,2.8}) do
                box('DeckWhiteSegment',Vector3.new(.61,.48,1.6),white,side*2.7,.30,z)
                box('DeckRedCorner',Vector3.new(.21,.23,1.3),red,side*3.02,.28,z)
            end
        end
    else
        -- Rounded safari hat and oversized glossy eyes from the crocodile reference.
        orb('CrocHeadSculpt',Vector3.new(3.55,1.7,1.80),rgb(112,185,46),0,6.64,-4.06)
        box('ShortRoundedSnout',Vector3.new(2.86,.63,.96),rgb(132,198,55),0,6.30,-3.03)
        orb('SnoutRoundLip',Vector3.new(2.91,.56,.40),rgb(132,198,55),0,6.31,-2.54)
        box('CrocMouthLine',Vector3.new(2.45,.10,.08),rgb(52,91,30),0,6.01,-2.33)
        for _,side in ipairs({-1,1}) do
            orb('OversizedCrocEye',Vector3.new(1.31,1.48,.57),rgb(253,253,239),side*.92,7.11,-3.10)
            orb('GlossyBlackCrocEye',Vector3.new(1.03,1.21,.28),rgb(5,11,17),side*.92,7.13,-2.78)
            orb('BigEyeCatchlight',Vector3.new(.32,.36,.10),white,side*.92-.19,7.45,-2.61)
            orb('TinyEyeCatchlight',Vector3.new(.12,.14,.08),white,side*.92+.23,6.90,-2.60)
            orb('CrocNostril',Vector3.new(.23,.12,.08),rgb(60,105,31),side*.78,6.55,-2.32)
        end
        for i=0,5 do wedge(m,'SmallCrocTooth',Vector3.new(.25,.23,.16),rgb(243,238,210),CFrame.new(-.94+i*.38,5.94,-2.32),MAT) end
        cyl(m,'SafariHatBrim',Vector3.new(.16,4.55,2.55),rgb(26,57,35),CFrame.new(0,7.97,-4.07)*CFrame.Angles(0,0,math.pi/2),MAT)
        cyl(m,'SafariHatCrown',Vector3.new(.65,2.91,1.79),rgb(37,70,41),CFrame.new(0,8.35,-4.07)*CFrame.Angles(0,0,math.pi/2),MAT)
        orb('HatSoftTop',Vector3.new(2.89,.36,1.77),rgb(37,70,41),0,8.68,-4.07)
        cyl(m,'SafariHatBand',Vector3.new(.14,3.0,1.85),rgb(69,88,49),CFrame.new(0,8.09,-4.07)*CFrame.Angles(0,0,math.pi/2),MAT)
        local gold=rgb(243,211,109)
        orb('HatAnimalBadge',Vector3.new(.30,.26,.07),gold,0,8.40,-3.12)
        bar('HatBadgeTail',Vector3.new(-.05,8.36,-3.1),Vector3.new(-.47,8.48,-3.1),.07,gold)
        bar('HatBadgeNeck',Vector3.new(.09,8.46,-3.1),Vector3.new(.19,8.62,-3.1),.07,gold)
        for _,side in ipairs({-1,1}) do bar('HatBadgeLeg',Vector3.new(side*.06,8.34,-3.1),Vector3.new(side*.25,8.25,-3.1),.055,gold) end
        for _,side in ipairs({-1,1}) do
            for i=0,3 do
                local p=box('CarvedPortalStone',Vector3.new(.81,.84,1.08),stone,side*2.04,1.34+i*.84,-4.09,Enum.Material.Cobblestone)
                p.TopSurface=Enum.SurfaceType.Studs
                box('StoneJoint',Vector3.new(.84,.045,.08),rgb(90,101,71),side*2.04,.94+i*.84,-3.49)
            end
        end
        for i=0,8 do
            local theta=i*math.pi/8
            box('CurvedArchBlock',Vector3.new(.82,.57,1.08),stone,math.cos(theta)*2.04,4.17+math.sin(theta)*1.40,-4.09,Enum.Material.Cobblestone,CFrame.Angles(0,0,theta-math.pi/2))
        end
        for _,side in ipairs({-1,1}) do
            for level=0,3 do
                box('JungleOuterStone',Vector3.new(.79,.68,.9),level%2==0 and rgb(113,132,69) or stone,side*(2.62+(level%2)*.14),1.4+level*.89,-4.3)
                box('MossPatch',Vector3.new(.53,.15,.22),rgb(93,150,37),side*(2.62+(level%2)*.14),1.78+level*.89,-3.8)
            end
            box('TotemFace',Vector3.new(.65,.85,.37),stone,side*2.65,4.21,-3.67)
            for _,eye in ipairs({-.16,.16}) do box('TotemEye',Vector3.new(.13,.12,.08),rgb(228,240,44),side*2.65+eye,4.41,-3.43,NEON) end
            box('TotemNose',Vector3.new(.18,.38,.16),rgb(105,120,76),side*2.65,4.05,-3.36)
            box('WaterSpoutStone',Vector3.new(.95,.72,.94),stone,side*2.69,2.56,-2.46)
            box('WaterSpoutOpening',Vector3.new(.62,.26,.13),rgb(45,89,70),side*2.69,2.47,-1.94)
            local waterfall=box('TurquoiseWaterfall',Vector3.new(.62,1.45,.17),rgb(52,216,239),side*2.69,1.66,-1.89,NEON)
            waterfall.Transparency=.20
            for i=0,3 do
                local highlight=box('WaterfallHighlights',Vector3.new(.07,.20,.04),rgb(166,253,255),side*2.69-.20+(i%2)*.32,1.15+i*.32,-1.78,NEON)
                highlight.Transparency=.32
            end
            box('WaterTrough',Vector3.new(1.12,.22,1.62),stone,side*2.69,.80,-1.08)
            cyl(m,'RoundWaterPool',Vector3.new(.06,.78,1.15),rgb(13,204,225),CFrame.new(side*2.69,.95,-1.02)*CFrame.Angles(0,0,math.pi/2),NEON)
            for _,z in ipairs({-3.72,3.82}) do
                box('GemStonePedestal',Vector3.new(.79,.35,.79),stone,side*2.62,.81,z)
                local crystal=box('EmeraldCrystalBody',Vector3.new(.47,.73,.47),lime,side*2.62,1.35,z,NEON,CFrame.Angles(0,math.pi/4,0))
                for _,turn in ipairs({0,math.pi}) do wedge(m,'CrystalTip',Vector3.new(.48,.39,.48),lime,CFrame.new(side*2.62,1.88,z)*CFrame.Angles(0,turn,0),NEON) end
                glow(crystal,lime,4,.8)
            end
            bar('PalmTrunk',Vector3.new(side*3.06,.9,-3.0),Vector3.new(side*3.19,4.7,-4.46),.18,rgb(83,99,41))
            for tier=0,2 do
                local cy=2.6+tier*.88
                for leaf=0,3 do
                    local angle=math.rad(side*(25+leaf*28))
                    wedge(m,'PalmLeaf',Vector3.new(.31,.23,1.89),rgb(18,116+tier*15,41),CFrame.new(side*(3.02+leaf*.17),cy,-4.05+leaf*.11)*CFrame.Angles(math.rad(-10+leaf*7),angle,math.rad(-side*20)),MAT)
                end
            end
            for j=0,5 do
                local moss=box('DeckMoss',Vector3.new(.46,.16,.52),rgb(82,151,35),side*2.80,.61,-2.5+j*1.0)
                moss.TopSurface=Enum.SurfaceType.Studs
            end
        end
    end
    -- Small studs on the belt and segmented side panels retain the toy-like style.
    for row=0,12 do
        for col=-1,1 do box('RaisedBeltCell',Vector3.new(.38,.035,.21),rgb(37,44,52),col*.92,.55,-3.85+row*.63) end
    end
end


local function refineTreadmill(m,croc)
    local white=rgb(241,244,248)
    local red=rgb(222,25,35)
    local black=rgb(17,24,33)
    local cyan=rgb(0,215,255)
    local stone=rgb(149,154,116)
    local remove={FrontRailSupport=true,RearRailSupport=true,LowerHandrail=true,RisingHandrail=true,RearHandrail=true,RailGlow=true}
    if croc then
        for _,n in ipairs({'CrocHeadSculpt','ShortRoundedSnout','SnoutRoundLip','CrocMouthLine','OversizedCrocEye','GlossyBlackCrocEye','BigEyeCatchlight','TinyEyeCatchlight','CrocNostril','SmallCrocTooth','SafariHatBrim','SafariHatCrown','HatSoftTop','SafariHatBand','HatAnimalBadge','HatBadgeTail','HatBadgeNeck','HatBadgeLeg','PalmTrunk','PalmLeaf'}) do remove[n]=true end
    else
        remove.AngledWhiteBrow=true
        remove.WhiteSideArmor=true
        remove.RedSideSpine=true
        remove.SideBlackChannel=true
        remove.SideCyanChannel=true
        remove.PawHousingWhite=true
    end
    for _,child in ipairs(m:GetChildren()) do if remove[child.Name] then child:Destroy() end end
    local function box(n,size,color,x,y,z,rotation,mat)
        return part(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),mat or MAT)
    end
    local function sphere(n,size,color,x,y,z,rotation,mat)
        return ball(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),mat or MAT)
    end
    local function beam(n,a,b,width,color,mat)
        local d=b-a
        if math.abs(d.Unit.Y)>.99 then return part(m,n,Vector3.new(width,d.Magnitude,width),color,CFrame.new((a+b)*.5),mat or MAT) end
        return part(m,n,Vector3.new(width,width,d.Magnitude),color,CFrame.lookAt((a+b)*.5,b),mat or MAT)
    end
    if not croc then
        -- The white eye armor is tapered on its inner edge, not a thick bar.
        for _,side in ipairs({-1,1}) do
            wedge(m,'TaperedBrowPlate',Vector3.new(.34,.51,1.42),white,CFrame.new(side*.89,6.53,-2.97)*CFrame.Angles(0,side*math.pi/2,0),MAT)
            box('BrowOuterBevel',Vector3.new(.40,.25,.36),rgb(220,227,235),side*1.44,6.65,-3.15,CFrame.Angles(0,0,math.rad(side*12)))
            -- Broad, sloped armor beams match the red/white side silhouette.
            local front=Vector3.new(side*2.54,1.02,3.57)
            local back=Vector3.new(side*2.54,2.06,-2.47)
            beam('SideArmorWhiteShell',front,back,.76,white)
            beam('SideArmorRedUnderlay',front+Vector3.new(side*.11,-.30,0),back+Vector3.new(side*.11,-.30,0),.57,red)
            local tilt=CFrame.Angles(math.rad(9.8),0,0)
            box('SideInsetBlackWindow',Vector3.new(.13,.43,3.07),black,side*2.96,1.53,.60,tilt)
            box('SideInsetCyanWindow',Vector3.new(.04,.17,2.48),cyan,side*3.035,1.55,.60,tilt,NEON)
            for _,z in ipairs({-.99,2.18}) do
                box('WhiteWindowEndBevel',Vector3.new(.20,.56,.30),white,side*2.98,1.53-(z-.6)*.171,z,tilt)
            end
            for _,spec in ipairs({{-2.8,2.31},{.15,1.74}}) do
                local z,y=spec[1],spec[2]
                local rot=CFrame.Angles(0,math.rad(side*7),math.rad(-side*28))
                wedge(m,'RedOuterBlade',Vector3.new(.50,1.40,1.25),red,CFrame.new(side*3.02,y,z)*rot,MAT)
                wedge(m,'BladeDarkInset',Vector3.new(.13,1.03,.91),black,CFrame.new(side*3.30,y+.04,z+.05)*rot,MAT)
                beam('BladeEdgeRedLight',Vector3.new(side*3.29,y-.42,z+.45),Vector3.new(side*3.55,y+.48,z-.10),.07,rgb(255,48,39),NEON)
            end
            box('RearArmorPod',Vector3.new(1.08,.65,1.44),red,side*2.95,.78,-2.95)
            box('RearArmorWhiteCap',Vector3.new(1.10,.21,1.48),white,side*2.95,1.19,-2.95)
            box('RearPodDarkPanel',Vector3.new(.07,.30,.92),black,side*3.52,.83,-2.95)
            box('RearPodCyanPanel',Vector3.new(.035,.12,.64),cyan,side*3.57,.83,-2.95,nil,NEON)
            box('FrontRedLink',Vector3.new(.74,.40,1.05),red,side*2.56,1.10,3.56,tilt)
            box('FrontWhiteLink',Vector3.new(.76,.20,.66),white,side*2.56,1.39,3.48,tilt)
            for point=1,8 do
                local a=(point-1)*math.pi/4+math.pi/8
                local b=point*math.pi/4+math.pi/8
                beam('OctagonalPawBevel',
                    Vector3.new(side*2.48+math.cos(a)*.58,1.01+math.sin(a)*.58,5.36),
                    Vector3.new(side*2.48+math.cos(b)*.58,1.01+math.sin(b)*.58,5.36),
                    .16,white)
            end
            for _,spec in ipairs({{4.15,.78},{1.62,.48},{-1.05,.48}}) do
                local z,y=spec[1],spec[2]
                box('DeckBlackArmorSeam',Vector3.new(.08,.22,.08),black,side*3.13,y,z)
                sphere('SmallMetalFastener',Vector3.new(.07,.09,.09),rgb(164,177,190),side*3.18,y+.1,z)
            end
        end
        -- A central forehead plate joins the brows without obscuring the eyes.
        box('ForeheadCenterPlate',Vector3.new(.63,.68,.25),rgb(224,230,237),0,6.65,-3.25,CFrame.Angles(0,0,math.rad(45)))
    else
        -- The neck bridges the arch and muzzle; the skull physically meets the brim.
        box('CrocodileNeck',Vector3.new(2.08,.66,1.16),rgb(104,163,43),0,5.79,-4.10)
        box('BroadCrocodileSkull',Vector3.new(3.19,1.60,1.38),rgb(119,185,47),0,6.91,-4.04)
        sphere('SkullLeftCorner',Vector3.new(.55,1.31,1.34),rgb(119,185,47),-1.48,6.88,-4.03)
        sphere('SkullRightCorner',Vector3.new(.55,1.31,1.34),rgb(119,185,47),1.48,6.88,-4.03)
        box('WideShortMuzzle',Vector3.new(2.81,.61,.80),rgb(139,199,58),0,6.31,-3.05)
        sphere('SoftMuzzleLip',Vector3.new(2.83,.43,.30),rgb(139,199,58),0,6.27,-2.65)
        box('FineMouthLine',Vector3.new(2.34,.045,.07),rgb(72,112,34),0,6.05,-2.47)
        for _,side in ipairs({-1,1}) do
            sphere('CrocEyeWhite',Vector3.new(1.02,1.20,.43),rgb(252,252,237),side*.86,7.10,-3.10)
            sphere('CrocEyeBlack',Vector3.new(.78,.98,.24),rgb(8,15,22),side*.86,7.12,-2.86)
            sphere('CrocEyeHighlight',Vector3.new(.23,.28,.08),white,side*.86-.15,7.39,-2.71)
            sphere('CrocEyeSmallHighlight',Vector3.new(.085,.10,.06),white,side*.86+.18,6.93,-2.71)
            box('RaisedNostrilScale',Vector3.new(.31,.22,.19),rgb(107,172,41),side*.73,6.62,-2.80)
            sphere('NostrilOpening',Vector3.new(.14,.07,.07),rgb(58,103,32),side*.73,6.68,-2.67)
        end
        for i=0,5 do
            wedge(m,'SmallIvoryTooth',Vector3.new(.18,.15,.15),rgb(232,225,188),CFrame.new(-.87+i*.35,5.99,-2.48),MAT)
        end
        -- Slice-built oval hat: explicit coordinates avoid cylinder-axis artifacts.
        local hat=rgb(33,62,39)
        local function ovalLayer(name,cx,cy,cz,rx,rz,height,color,count)
            local step=2*rx/count
            for i=1,count do
                local x=-rx+(i-.5)*step
                local depth=2*rz*math.sqrt(math.max(0,1-(x/rx)^2))
                box(name,Vector3.new(step+.015,height,depth),color,cx+x,cy,cz)
            end
        end
        ovalLayer('SafariBrim',0,7.76,-4.04,2.13,1.28,.14,hat,21)
        ovalLayer('SafariCrownLower',0,8.005,-4.06,1.42,.91,.37,hat,17)
        ovalLayer('SafariCrownUpper',0,8.285,-4.10,1.32,.84,.23,rgb(39,72,43),17)
        ovalLayer('SafariCrownTop',0,8.435,-4.10,1.22,.77,.10,rgb(43,77,46),17)
        ovalLayer('SafariBand',0,7.91,-4.06,1.46,.94,.13,rgb(72,91,50),17)
        box('CrownCrease',Vector3.new(.06,.025,1.07),rgb(26,49,33),0,8.49,-4.1)
        local gold=rgb(239,212,119)
        sphere('HatAnimalBody',Vector3.new(.25,.21,.055),gold,0,8.21,-3.16)
        beam('HatAnimalTail',Vector3.new(-.05,8.17,-3.14),Vector3.new(-.39,8.29,-3.14),.055,gold)
        beam('HatAnimalNeck',Vector3.new(.06,8.25,-3.14),Vector3.new(.18,8.39,-3.14),.055,gold)
        sphere('HatAnimalHead',Vector3.new(.13,.10,.05),gold,.20,8.39,-3.14)
        for _,side in ipairs({-1,1}) do beam('HatAnimalLeg',Vector3.new(0,8.14,-3.14),Vector3.new(side*.19,8.09,-3.14),.045,gold) end
        for _,side in ipairs({-1,1}) do
            -- Continuous stepped stone sidewalls, with moss instead of white rails.
            for step=0,5 do
                local z=3.85-step*1.27
                local height=.43+step*.18
                local p=box('StoneSideStep',Vector3.new(.88,height,1.23),stone,side*2.70,.33+height/2,z,nil,Enum.Material.Cobblestone)
                p.TopSurface=Enum.SurfaceType.Studs
                box('SideMossCap',Vector3.new(.70,.13,.94),rgb(102,161,39),side*2.79,.42+height,z)
                if step%2==0 then box('OuterMossBlock',Vector3.new(.33,.32,.55),rgb(86,143,33),side*3.21,.47+height*.5,z+.18) end
            end
            -- Palm fronds curve outwards, with individual tapered leaflets.
            beam('HiddenPalmStem',Vector3.new(side*2.48,1.08,-4.75),Vector3.new(side*2.55,4.95,-4.75),.16,rgb(84,100,44))
            for tier=0,1 do
                local origin=Vector3.new(side*2.55,4.86-tier*1.38,-4.73)
                for ray=0,2 do
                    local endPoint=origin+Vector3.new(side*(.85+ray*.06),.30-ray*.41,.24+ray*.08)
                    local middle=(origin+endPoint)*.5+Vector3.new(0,.21,0)
                    beam('FrondStem',origin,middle,.052,rgb(35,121,46))
                    beam('FrondStem',middle,endPoint,.045,rgb(35,121,46))
                    for leaflet=1,4 do
                        local t=leaflet/5
                        local point=origin:Lerp(endPoint,t)+Vector3.new(0,.21*math.sin(t*math.pi),0)
                        for _,leafSide in ipairs({-1,1}) do
                            local tip=point+Vector3.new(side*.24,leafSide*(.33-.08*t),.025)
                            local center=(point+tip)*.5
                            wedge(m,'TaperedPalmLeaflet',Vector3.new(.065,.30,(tip-point).Magnitude*1.75),rgb(20,125+tier*13+ray*5,42),CFrame.lookAt(center,tip),MAT)
                        end
                    end
                end
            end
        end
    end
    m:SetAttribute('SAE_TREADMILL_DETAIL_REVISION',3)
end


local function luxuryTreadmill(m,croc)
    -- Static detail only: no per-frame effects or global Lighting changes.
    local white,red,black=rgb(245,247,250),rgb(226,23,33),rgb(16,23,31)
    local cyan,lime,gold=rgb(0,221,255),rgb(125,255,12),rgb(241,193,66)
    local stone=rgb(149,154,116)
    local remove={}
    local names=croc and {'SmallIvoryTooth','TurquoiseWaterfall','WaterfallHighlights'} or {
        'EarWhiteArmor','EarRedRim','EarBlackInset','BentEarCap',
        'RedEyeMask','EyeRecess','EyeWhite','BlueIris','EyePupil','EyeCatchlight','SmallEyeCatchlight','MaskEdge',
        'TaperedBrowPlate','BrowOuterBevel','ForeheadCenterPlate','CheekArmor'}
    for _,name in ipairs(names) do remove[name]=true end
    for _,child in ipairs(m:GetChildren()) do if remove[child.Name] then child:Destroy() end end
    local function box(n,size,color,x,y,z,rotation,material)
        return part(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),material or MAT)
    end
    local function orb(n,size,color,x,y,z,rotation,material)
        return ball(m,n,size,color,CFrame.new(x,y,z)*(rotation or CFrame.new()),material or MAT)
    end
    local function beam(n,a,b,width,color,material)
        local d=b-a
        if math.abs(d.Unit.Y)>.99 then
            return box(n,Vector3.new(width,d.Magnitude,width),color,(a.X+b.X)/2,(a.Y+b.Y)/2,(a.Z+b.Z)/2,nil,material)
        end
        return part(m,n,Vector3.new(width,width,d.Magnitude),color,CFrame.lookAt((a+b)*.5,b),material or MAT)
    end
    local function light(p,color,range)
        local l=Instance.new('PointLight')
        l.Color=color l.Brightness=.6 l.Range=range or 3.5 l.Shadows=false l.Parent=p
        local halo=Instance.new('BillboardGui')
        halo.Name='LocalLightHalo' halo.Adornee=p halo.AlwaysOnTop=false
        halo.LightInfluence=0 halo.MaxDistance=95 halo.Size=UDim2.fromScale(1.35,1.35) halo.Parent=p
        local image=Instance.new('ImageLabel')
        image.Size=UDim2.fromScale(1,1) image.BackgroundTransparency=1
        image.Image='rbxasset://textures/glow.png' image.ImageColor3=color image.ImageTransparency=.78 image.Parent=halo
    end
    -- A wider, layered chassis gives the machines weight without enlarging the belt.
    box('HeavyChassisSkirt',Vector3.new(6.36,.32,10.90),croc and rgb(87,109,65) or black,0,-.35,0)
    box('HeavyChassisPlinth',Vector3.new(6.64,.24,10.52),croc and stone or white,0,-.60,.03)
    for _,side in ipairs({-1,1}) do
        box('WideSideFoundation',Vector3.new(1.11,.48,8.70),croc and stone or red,side*2.84,.09,.16)
        box('FoundationOuterTrim',Vector3.new(.10,.11,8.15),croc and lime or cyan,side*3.42,.14,.15,nil,NEON)
        for _,z in ipairs({-4.28,4.20}) do
            box('HeavyCornerFoot',Vector3.new(1.20,.38,1.28),croc and rgb(109,126,80) or black,side*2.83,-.63,z)
        end
    end
    if not croc then
        -- Straight, upright ears. All three layers share the same axis.
        for _,side in ipairs({-1,1}) do
            local rot=CFrame.Angles(0,0,math.rad(-side*16))
            orb('UprightWhiteEar',Vector3.new(1.10,3.44,.62),white,side*1.03,8.01,-4.08,rot)
            orb('UprightRedEarRim',Vector3.new(.82,3.04,.24),rgb(255,28,35),side*1.03,8.01,-3.73,rot,NEON)
            orb('UprightDarkEarInset',Vector3.new(.62,2.74,.15),black,side*1.03,8.01,-3.58,rot)
            -- Thin, recessed lenses sit inside the mask instead of on stalks.
            local tilt=CFrame.Angles(0,0,math.rad(side*10))
            orb('CleanRedEyeMask',Vector3.new(1.68,.72,.14),red,side*.85,6.22,-3.13,tilt)
            orb('CleanEyeSocket',Vector3.new(1.32,.48,.065),black,side*.85,6.20,-3.043,tilt)
            orb('CleanWhiteEye',Vector3.new(1.15,.46,.055),rgb(255,255,255),side*.85,6.20,-2.998,tilt)
            orb('CleanBlueIris',Vector3.new(.43,.39,.035),rgb(0,170,228),side*.77,6.19,-2.961)
            orb('CleanCyanIrisRim',Vector3.new(.32,.34,.025),cyan,side*.77,6.19,-2.936)
            orb('CleanBlackPupil',Vector3.new(.20,.29,.020),rgb(5,14,25),side*.77,6.19,-2.916)
            orb('CleanEyeShine',Vector3.new(.09,.11,.015),white,side*.77-.06,6.29,-2.898)
            orb('WhiteUpperEyelid',Vector3.new(1.45,.22,.17),white,side*.89,6.48,-3.11,tilt)
            orb('SmoothEyeCheek',Vector3.new(.70,.55,.42),white,side*1.40,5.88,-3.20,tilt)
            beam('MaskTempleConnector',Vector3.new(side*1.46,6.30,-3.17),Vector3.new(side*1.73,6.30,-3.61),.19,red)
        end
        orb('MaskNoseBridge',Vector3.new(.40,.20,.13),red,0,6.25,-3.13)
        for _,side in ipairs({-1,1}) do
            -- Wide pods with inset panels support the layered red shard silhouette.
            box('HeavyRearRedHousing',Vector3.new(1.28,.81,2.02),red,side*3.02,.73,-3.25)
            box('HeavyRearWhiteCap',Vector3.new(1.30,.23,1.97),white,side*3.02,1.25,-3.25)
            box('HeavyRearBlackInset',Vector3.new(.09,.37,1.34),black,side*3.69,.78,-3.25)
            box('HeavyRearCyanInset',Vector3.new(.045,.15,1.04),cyan,side*3.75,.80,-3.25,nil,NEON)
            for _,spec in ipairs({
                {3.08,5.03,-4.47,2.14,1.44,32},
                {3.49,3.83,-4.32,1.89,1.39,40},
                {3.60,2.20,-3.00,2.07,1.62,36},
                {3.51,1.74,-.30,1.65,1.40,40},
                {3.31,1.42,2.20,1.18,1.15,35},
                {2.82,5.40,-5.13,1.42,1.08,25}
            }) do
                local x,y,z,h,depth,angle=unpack(spec)
                local rot=CFrame.Angles(0,0,math.rad(-side*angle))*CFrame.Angles(0,side*math.pi/2,0)
                wedge(m,'LuxuryRedArmorShard',Vector3.new(.95,h,depth),red,CFrame.new(side*x,y,z)*rot,MAT)
                wedge(m,'ShardDarkRecess',Vector3.new(.065,h*.72,depth*.68),black,CFrame.new(side*x,y-.03,z+.53)*rot,MAT)
                local face=CFrame.new(side*x,y,z)*rot
                beam('ShardRedLightEdge',
                    (face*CFrame.new(-side*.51,-h*.48,-depth*.48)).Position,
                    (face*CFrame.new(-side*.51,h*.48,depth*.48)).Position,
                    .065,rgb(255,43,38),NEON)
                box('ShardWhiteRoot',Vector3.new(.63,.25,depth*.80),white,side*(x-.17),y-h*.34,z+.07,rot)
            end
            -- Separate angular plates along the rail, with cyan technology windows.
            for _,spec in ipairs({{2.44,1.62},{.71,1.33},{-1.15,1.68}}) do
                local z,y=spec[1],spec[2]
                box('LayeredRailRedPanel',Vector3.new(.25,.60,1.38),red,side*3.15,y,z,CFrame.Angles(math.rad(10),0,0))
                box('LayeredRailWhiteBevel',Vector3.new(.27,.17,1.39),white,side*3.16,y+.35,z,CFrame.Angles(math.rad(10),0,0))
                box('LayeredRailDarkInset',Vector3.new(.05,.28,.96),black,side*3.30,y,z)
                box('LayeredRailCyanInset',Vector3.new(.035,.11,.70),cyan,side*3.34,y,z,nil,NEON)
            end
        end
    else
        local ivory=rgb(255,247,214)
        -- Two tapered canines replace the row of little square teeth.
        for _,side in ipairs({-1,1}) do
            for _,half in ipairs({-1,1}) do
                wedge(m,'IvoryCrocodileFang',Vector3.new(.24,.57,.17),ivory,
                    CFrame.new(side*.91+half*.085,5.88,-2.47)*CFrame.Angles(0,-half*math.pi/2,math.pi),MAT)
            end
            -- Gold cords attach at the brim, follow the cheeks and end in tassels.
            local cord={
                Vector3.new(side*1.93,7.75,-3.58),Vector3.new(side*1.87,7.42,-3.20),
                Vector3.new(side*1.80,7.03,-2.98),Vector3.new(side*1.77,6.66,-2.91),
                Vector3.new(side*1.86,6.28,-3.03)}
            for i=1,#cord-1 do beam('AttachedGoldHatCord',cord[i],cord[i+1],.065,gold,Enum.Material.Metal) end
            orb('GoldCordKnot',Vector3.new(.15,.17,.15),gold,side*1.86,6.27,-3.03,nil,Enum.Material.Metal)
            for strand=-1,1 do
                beam('GoldHatTassel',Vector3.new(side*1.86+strand*.045,6.23,-3.03),
                    Vector3.new(side*1.87+strand*.065,5.95,-3.01),.036,gold,Enum.Material.Metal)
            end
            -- Thick stone shoulder towers and wider stepped foundations.
            box('HeavyTotemShoulder',Vector3.new(1.23,.51,1.33),stone,side*2.68,4.83,-4.10,nil,Enum.Material.Cobblestone)
            box('ShoulderMossCrown',Vector3.new(1.17,.17,1.26),rgb(95,158,34),side*2.68,5.16,-4.10)
            for step=0,4 do
                local z=3.72-step*1.42
                local h=.52+step*.16
                box('OuterStoneButtress',Vector3.new(.64,h,1.22),stone,side*3.14,.31+h*.5,z,nil,Enum.Material.Cobblestone)
                box('ButtressMossTop',Vector3.new(.61,.13,1.06),rgb(99,161,32),side*3.14,.36+h,z)
            end
            local function crystal(x,y,z,scale)
                box('LuxuryLampStoneSocket',Vector3.new(.67*scale,.24,.67*scale),stone,x,y-.43*scale,z)
                box('LuxuryLampGoldCollar',Vector3.new(.48*scale,.10,.48*scale),gold,x,y-.27*scale,z,nil,Enum.Material.Metal)
                local body=box('LuxuryEmeraldLamp',Vector3.new(.34*scale,.65*scale,.34*scale),lime,x,y+.07*scale,z,CFrame.Angles(0,math.pi/4,0),NEON)
                for _,turn in ipairs({0,math.pi}) do
                    wedge(m,'LuxuryLampPoint',Vector3.new(.34*scale,.32*scale,.34*scale),rgb(181,255,61),
                        CFrame.new(x,y+.55*scale,z)*CFrame.Angles(0,turn+math.pi/4,0),NEON)
                end
                light(body,lime,3.4)
            end
            crystal(side*2.12,6.11,-4.01,.97)
            crystal(side*3.05,5.17,-3.91,.76)
            local topLamp=box('TopArchWarmLight',Vector3.new(.24,.23,.17),gold,side*1.64,5.52,-3.48,nil,NEON)
            light(topLamp,gold,2.4)
            -- Continuous falling water: a sloped ribbon runs from spout to pool.
            local angle=math.atan2(-.36,1.48)
            local water=box('FullHeightWaterfall',Vector3.new(.73,1.59,.17),rgb(42,222,242),
                side*2.69,1.76,-1.66,CFrame.Angles(angle,0,0),NEON)
            water.Transparency=.17
            for stripe=0,2 do
                local p=box('LongWaterfallHighlight',Vector3.new(.045,1.52,.035),rgb(184,255,255),
                    side*2.69-.24+stripe*.24,1.76,-1.56,CFrame.Angles(angle,0,0),NEON)
                p.Transparency=.38
            end
            local landing=box('ConnectedWaterLanding',Vector3.new(.76,.075,.97),rgb(30,213,237),side*2.69,1.01,-1.16,nil,NEON)
            landing.Transparency=.13
            orb('WaterfallFoam',Vector3.new(.70,.10,.33),rgb(187,255,255),side*2.69,1.06,-1.45)
        end
    end

    -- Substantial rear housings make the console a complete volume from every side.
    box('DeepConsoleHousing',Vector3.new(4.10,4.43,1.62),croc and rgb(94,110,70) or black,0,3.30,-4.91)
    box('RearConsolePanel',Vector3.new(3.45,3.38,.18),croc and stone or white,0,3.23,-5.80)
    box('RearRecessPanel',Vector3.new(2.62,2.48,.11),croc and rgb(79,97,55) or black,0,3.22,-5.94)
    box('HeavyRearBumper',Vector3.new(5.76,.43,1.06),croc and stone or red,0,.10,-5.35)
    for _,side in ipairs({-1,1}) do
        box('DeepShoulderBody',Vector3.new(1.12,3.72,1.38),croc and stone or red,side*2.24,3.18,-4.83)
        box('ShoulderRearBevel',Vector3.new(1.20,.33,1.44),croc and rgb(104,145,56) or white,side*2.24,5.11,-4.83)
        if not croc then
            for row=0,4 do
                box('RearCoolingVent',Vector3.new(.67,.11,.055),black,side*2.24,2.36+row*.28,-5.56)
            end
            box('ShoulderSideDarkPanel',Vector3.new(.12,2.08,.94),black,side*2.84,3.44,-4.82)
            box('ShoulderSideRedLight',Vector3.new(.065,1.62,.13),rgb(255,38,37),side*2.92,3.44,-4.78,nil,NEON)
            beam('ShardSupportStrut',Vector3.new(side*2.80,1.06,-3.90),Vector3.new(side*3.38,4.73,-4.63),.33,red)
            for _,z in ipairs({-2.05,.13,2.36}) do
                box('RailOuterVolume',Vector3.new(.60,.62,1.40),red,side*3.23,.83,z)
                box('RailArmorChamfer',Vector3.new(.64,.20,1.44),white,side*3.23,1.24,z)
                for _,offset in ipairs({-.41,.41}) do
                    orb('ArmorRecessedBolt',Vector3.new(.06,.10,.10),rgb(156,173,189),side*3.56,.88,z+offset)
                end
            end
        else
            -- A connected stone lip catches the cascade and leads into the pool.
            for _,edge in ipairs({-.48,.48}) do
                box('WaterfallStoneCheek',Vector3.new(.18,1.45,.66),stone,side*2.69+edge,1.77,-1.92)
                box('PoolSideCoping',Vector3.new(.17,.22,1.42),stone,side*2.69+edge,.98,-1.08)
            end
            box('SpoutWaterBridge',Vector3.new(.74,.10,.49),rgb(45,220,242),side*2.69,2.48,-1.93,nil,NEON).Transparency=.17
            box('WaterTopMouth',Vector3.new(.87,.21,.28),stone,side*2.69,2.71,-1.89)
            beam('ShoulderLampPillar',Vector3.new(side*3.05,3.83,-3.91),Vector3.new(side*3.05,4.82,-3.91),.34,stone)
            beam('UpperLampBrace',Vector3.new(side*2.12,5.35,-4.01),Vector3.new(side*2.12,5.75,-4.01),.36,stone)
            -- Gold hardware joins the cords to the hat brim rather than floating.
            orb('HatCordAttachment',Vector3.new(.18,.16,.18),gold,side*1.93,7.75,-3.58,nil,Enum.Material.Metal)
            box('SafariHatStitch',Vector3.new(.032,.15,.025),gold,side*.93,8.22,-3.22)
            -- Extra palms grow from stone pockets at the rear and middle sides.
            for _,tree in ipairs({{3.23,-4.77,5.28},{3.34,-2.77,3.62},{3.38,.38,2.01}}) do
                local x,z,top=side*tree[1],tree[2],tree[3]
                box('PalmStonePlanter',Vector3.new(.67,.43,.70),stone,x,.68,z)
                box('PalmSoilPocket',Vector3.new(.48,.07,.50),rgb(63,77,36),x,.94,z)
                local bottom=Vector3.new(x,.94,z)
                local crown=Vector3.new(x+side*.12,top,z-.12)
                beam('PalmTexturedTrunk',bottom,crown,.18,rgb(100,101,42))
                for ring=1,5 do
                    local point=bottom:Lerp(crown,ring/6)
                    box('PalmTrunkRidge',Vector3.new(.23,.07,.23),rgb(128,122,54),point.X,point.Y,point.Z)
                end
                for frond=0,4 do
                    local angle=frond*math.pi*2/5
                    local span=top>4 and 1.05 or .76
                    local tip=crown+Vector3.new(math.cos(angle)*span,-.23,math.sin(angle)*span)
                    local hump=(crown+tip)*.5+Vector3.new(0,.28,0)
                    beam('PalmFrondSpine',crown,hump,.055,rgb(43,141,45))
                    beam('PalmFrondSpine',hump,tip,.04,rgb(36,123,39))
                    for _,section in ipairs({{crown,hump},{hump,tip}}) do
                        local middle=(section[1]+section[2])*.5
                        ball(m,'BroadPalmFrond',Vector3.new(.31,.10,(section[2]-section[1]).Magnitude*1.12),
                            rgb(25,139,44),CFrame.lookAt(middle,section[2]),MAT)
                    end
                    for leaf=1,3 do
                        local point=crown:Lerp(tip,leaf/4)+Vector3.new(0,.20*math.sin(leaf*math.pi/4),0)
                        for _,edge in ipairs({-1,1}) do
                            local endPoint=point+Vector3.new(-math.sin(angle)*edge*.27,-.10,math.cos(angle)*edge*.27)
                            wedge(m,'SculptedPalmLeaf',Vector3.new(.17,.19,(endPoint-point).Magnitude*2.15),
                                rgb(26,143+leaf*7,47),CFrame.lookAt((point+endPoint)*.5,endPoint),MAT)
                        end
                    end
                end
            end
            for row=0,3 do
                for col=-1,1 do
                    box('RearStoneTile',Vector3.new(.88,.59,.16),row%2==0 and stone or rgb(126,140,91),
                        col*.98,1.87+row*.72,-6.04)
                end
            end
        end
    end
    m:SetAttribute('SAE_TREADMILL_DETAIL_REVISION',5)

end

local function stabilizeTreadmillShapes(m)
    -- Native Ball parts render as stretched ellipsoids under a Humanoid, but
    -- revert to spheres outside it. A block carrier with a Sphere mesh keeps
    -- the same three dimensions in the Tool, Backpack and placed Model.
    for _,p in ipairs(allParts(m)) do
        if p:IsA('Part') and p.Shape==Enum.PartType.Ball then
            local dimensions=p.Size
            local transform=p.CFrame
            p.Shape=Enum.PartType.Block
            p.Size=dimensions
            p.CFrame=transform
            local mesh=Instance.new('SpecialMesh')
            mesh.Name='SAE_STABLE_ELLIPSOID'
            mesh.MeshType=Enum.MeshType.Sphere
            mesh.Scale=Vector3.new(1,1,1)
            mesh.Offset=Vector3.zero
            mesh.Parent=p
            p:SetAttribute('SAE_STABLE_CURVED_DETAIL',true)
        end
    end
    m:SetAttribute('SAE_TREADMILL_SHAPE_VERSION',2)
end

local function customTreadmill(name,crocodile)
    local m=Instance.new('Model')
    m.Name=name
    local shell=crocodile and rgb(135,145,102) or rgb(239,242,246)
    local dark=crocodile and rgb(48,69,45) or rgb(37,43,54)
    local accent=crocodile and rgb(106,245,20) or rgb(226,39,45)
    local light=crocodile and rgb(101,255,12) or rgb(30,218,255)
    local stone=rgb(157,162,122)
    local root=part(m,'DeckFrame',Vector3.new(5.6,.55,11),shell,CFrame.new(0,0,0),MAT)
    root.TopSurface=Enum.SurfaceType.Studs
    local function block(n,size,color,x,y,z,material,transparency)
        return part(m,n,size,color,CFrame.new(x,y,z),material or MAT,transparency)
    end
    local function beam(n,a,b,width,color,material)
        local delta=b-a
        if math.abs(delta.Unit.Y)>.99 then
            return part(m,n,Vector3.new(width,delta.Magnitude,width),color,CFrame.new((a+b)*.5),material or MAT)
        end
        return part(m,n,Vector3.new(width,width,delta.Magnitude),color,CFrame.lookAt((a+b)*.5,b),material or MAT)
    end
    block('RunningBelt',Vector3.new(4.2,.2,9.3),rgb(25,30,36),0,.39,.15)
    for i=0,19 do
        block('BeltTread',Vector3.new(4.0,.045,.11),rgb(48,55,61),0,.515,-4.25+i*.46)
    end
    for _,z in ipairs({-4.75,4.85}) do
        cyl(m,'BeltRoller',Vector3.new(4.5,.55,.55),dark,CFrame.new(0,.26,z),Enum.Material.Metal)
    end
    for _,side in ipairs({-1,1}) do
        local x=side*2.55
        block('SideStep',Vector3.new(.68,.34,10.3),shell,x,.27,.05).TopSurface=Enum.SurfaceType.Studs
        block('BeltLightStrip',Vector3.new(.11,.1,9.7),light,side*2.16,.53,.1,NEON)
        block('SideAccent',Vector3.new(.16,.24,9.5),accent,side*2.88,.22,.1)
        beam('FrontRailSupport',Vector3.new(x,.55,3.3),Vector3.new(x,1.75,2.8),.25,shell)
        beam('RearRailSupport',Vector3.new(x,.55,-3.8),Vector3.new(x,3.45,-3.8),.32,shell)
        beam('LowerHandrail',Vector3.new(x,1.75,2.8),Vector3.new(x,2.1,1.9),.3,shell)
        beam('RisingHandrail',Vector3.new(x,2.1,1.9),Vector3.new(x,3.45,-2.7),.3,shell)
        beam('RearHandrail',Vector3.new(x,3.45,-2.7),Vector3.new(x,3.45,-3.8),.3,shell)
        beam('RailGlow',Vector3.new(x-side*.06,2.15,1.8),Vector3.new(x-side*.06,3.43,-2.7),.095,light,NEON)
        block('FrontFoot',Vector3.new(.82,.45,1.05),dark,x,-.36,4.25)
        block('RearFoot',Vector3.new(.82,.45,1.05),dark,x,-.36,-4.25)
    end
    block('RearConsole',Vector3.new(3.8,4.2,.58),dark,0,3.35,-4.35)
    block('ConsoleDisplay',Vector3.new(2.9,3.45,.12),rgb(14,23,28),0,3.48,-3.98)
    for _,y in ipairs({2.7,3.65}) do
        beam('SpeedArrow',Vector3.new(-.8,y,-3.88),Vector3.new(0,y+.48,-3.88),.19,light,NEON)
        beam('SpeedArrow',Vector3.new(0,y+.48,-3.88),Vector3.new(.8,y,-3.88),.19,light,NEON)
    end
    if not crocodile then
        -- White rabbit face, red armor, tall ears and blue eyes.
        for _,side in ipairs({-1,1}) do
            block('ConsoleArmor',Vector3.new(.46,4.5,.9),accent,side*2.0,3.4,-4.18)
            block('ConsoleEdgeLight',Vector3.new(.10,3.5,.12),light,side*1.77,3.3,-3.66,NEON)
            wedge(m,'ShoulderArmor',Vector3.new(1.15,1.2,1.1),accent,CFrame.new(side*2.0,5.4,-4.2)*CFrame.Angles(0,0,math.rad(side*20)),MAT)
            ball(m,'RabbitEar',Vector3.new(1.0,3.0,.7),shell,CFrame.new(side*1.05,8.0,-4.15)*CFrame.Angles(0,0,math.rad(-side*20)),MAT)
            ball(m,'EarInset',Vector3.new(.58,2.35,.2),accent,CFrame.new(side*1.05,8.05,-3.76)*CFrame.Angles(0,0,math.rad(-side*20)),MAT)
            block('ArmorFoot',Vector3.new(1.0,.8,1.0),shell,side*2.5,.68,4.55)
            block('FootRedTrim',Vector3.new(.84,.18,.2),accent,side*2.5,.37,5.12)
            ball(m,'PawPad',Vector3.new(.42,.34,.13),light,CFrame.new(side*2.5,.65,5.1),NEON)
            for toe=-1,1 do
                ball(m,'PawToe',Vector3.new(.19,.2,.12),light,CFrame.new(side*2.5+toe*.19,.95,5.1),NEON)
            end
        end
        ball(m,'RabbitHead',Vector3.new(3.8,2.1,1.85),shell,CFrame.new(0,6.05,-4.0),MAT)
        ball(m,'RabbitMuzzle',Vector3.new(2.1,.86,.8),rgb(220,228,232),CFrame.new(0,5.62,-3.08),MAT)
        for _,side in ipairs({-1,1}) do
            ball(m,'EyeSocket',Vector3.new(1.12,.72,.25),dark,CFrame.new(side*.95,6.12,-3.1),MAT)
            ball(m,'BlueEye',Vector3.new(.66,.54,.19),light,CFrame.new(side*.95,6.12,-2.94),NEON)
            ball(m,'Pupil',Vector3.new(.23,.45,.13),rgb(8,17,27),CFrame.new(side*.95,6.12,-2.83),MAT)
            beam('RedBrow',Vector3.new(side*.3,6.53,-2.99),Vector3.new(side*1.65,6.4,-3.0),.18,accent)
        end
        ball(m,'Nose',Vector3.new(.42,.27,.2),dark,CFrame.new(0,5.86,-2.59),MAT)
        beam('Smile',Vector3.new(-.52,5.49,-2.65),Vector3.new(0,5.37,-2.62),.06,dark)
        beam('Smile',Vector3.new(0,5.37,-2.62),Vector3.new(.52,5.49,-2.65),.06,dark)
    else
        -- Stone portal, explorer crocodile, jungle plants and side waterfalls.
        for _,side in ipairs({-1,1}) do
            for row=0,4 do
                local p=block('PortalStone',Vector3.new(.88,.86,1.0),row%2==0 and stone or shell,side*2.02,1.3+row*.86,-4.1)
                p.TopSurface=Enum.SurfaceType.Studs
            end
            for step=0,2 do
                local x=side*(1.55-step*.55)
                part(m,'ArchStone',Vector3.new(.88,.72,1),stone,CFrame.new(x,5.3+step*.22,-4.1)*CFrame.Angles(0,0,math.rad(-side*(24-step*8))),MAT)
            end
            for _,z in ipairs({-3.7,3.7}) do
                block('CrystalPlinth',Vector3.new(.72,.34,.72),stone,side*2.65,.9,z)
                ball(m,'EmeraldCrystal',Vector3.new(.4,.85,.4),light,CFrame.new(side*2.65,1.48,z),NEON)
                for leaf=1,3 do
                    wedge(m,'JungleLeaf',Vector3.new(.25,.9,.75),rgb(26,130+leaf*18,44),CFrame.new(side*(2.68+leaf*.14),.9,-2.3+leaf*.3)*CFrame.Angles(math.rad(18),math.rad(side*leaf*25),math.rad(-side*35)),MAT)
                end
            end
            block('WaterfallChannel',Vector3.new(.78,.25,1.6),stone,side*2.75,1.85,-2.4)
            block('Waterfall',Vector3.new(.56,1.12,.14),rgb(62,223,249),side*2.75,1.22,-1.6,NEON,.22)
            block('PoolRim',Vector3.new(1.0,.18,1.3),stone,side*2.75,.6,-1.0)
            block('WaterPool',Vector3.new(.76,.08,1.05),rgb(56,217,237),side*2.75,.72,-1.0,NEON,.18)
        end
        ball(m,'CrocodileHead',Vector3.new(3.9,2.1,2.0),rgb(113,183,45),CFrame.new(0,6.65,-4.0),MAT)
        block('CrocodileSnout',Vector3.new(3.1,.68,1.65),rgb(133,199,57),0,6.26,-2.95)
        block('LowerJaw',Vector3.new(2.8,.22,1.2),rgb(225,220,150),0,5.85,-2.8)
        for _,side in ipairs({-1,1}) do
            ball(m,'CrocodileEye',Vector3.new(1.04,1.12,.5),rgb(250,250,232),CFrame.new(side*1.03,7.12,-3.08),MAT)
            ball(m,'CrocodilePupil',Vector3.new(.55,.75,.24),rgb(9,16,13),CFrame.new(side*1.03,7.12,-2.81),MAT)
            ball(m,'EyeShine',Vector3.new(.17,.2,.09),rgb(255,255,255),CFrame.new(side*1.03-.10,7.31,-2.65),MAT)
            ball(m,'Nostril',Vector3.new(.24,.13,.12),dark,CFrame.new(side*.79,6.55,-2.1),MAT)
            for tooth=0,2 do
                wedge(m,'CrocodileTooth',Vector3.new(.26,.33,.19),rgb(250,245,217),CFrame.new(side*(.45+tooth*.4),5.98,-2.07),MAT)
            end
        end
        block('ExplorerHatBrim',Vector3.new(4.5,.18,2.7),rgb(37,64,40),0,7.91,-4.1)
        block('ExplorerHatCrown',Vector3.new(2.9,.83,1.95),rgb(43,77,44),0,8.37,-4.1)
        block('HatBand',Vector3.new(3.0,.18,2.0),rgb(73,88,48),0,8.1,-4.1)
        block('HatBadge',Vector3.new(.67,.32,.09),rgb(244,210,101),0,8.37,-3.09)
    end
    detailTreadmill(m,crocodile)
    refineTreadmill(m,crocodile)
    luxuryTreadmill(m,crocodile)
    stabilizeTreadmillShapes(m)
    m.PrimaryPart=root
    m:ScaleTo(1.18)
    m:SetAttribute('SAE_TREADMILL_MODEL_SCALE',1.18)
    m:SetAttribute('SAE_TREADMILL',true)
    m:SetAttribute('SAE_REFERENCE_DETAIL','CustomTreadmill')
    return finalize(m,root)
end


local Built={['Unicorn Egg']=refEgg('Unicorn Egg'),['Kitsune Egg']=refEgg('Kitsune Egg'),['Night Flame Egg']=refEgg('Night Flame Egg'),['Archangel Egg']=refEgg('Archangel Egg'),['World Burner Egg']=refEgg('World Burner Egg'),['Aetheron Egg']=refEgg('Aetheron Egg'),['Cthulhu Egg']=refEgg('Cthulhu Egg'),['Luminous Cthulhu Egg']=refEgg('Luminous Cthulhu Egg'),['Sabertooth Egg']=refEgg('Sabertooth Egg'),['Skeletal Sabertooth Egg']=refEgg('Skeletal Sabertooth Egg'),['Octophant Egg']=refEgg('Octophant Egg'),['Mecha Scrambler Egg']=refEgg('Mecha Scrambler Egg'),['Night Flame']=nightPet,['Luminous Cthulhu']=luminousPet,['Star']=star}

local cache={}
local function badPet(o)local x=o while x and x~=workspace and x~=RS do if norm(x.Name):find('egg',1,true)then return true end x=x.Parent end return false end
local function hit(o,want)if want[norm(o.Name)]then return 1000 end local n=norm(o.Name)for a in pairs(want)do if #a>=5 and n:find(a,1,true)then return 420 end end for _,k in ipairs({'ItemName','DisplayName','PetName','EggName','Title','Type'})do local ok,v=pcall(function()return o:GetAttribute(k)end)if ok and v and want[norm(v)]then return 850 end end return 0 end
local function source(cat,name)local key=cat..'|'..name if cache[key]and cache[key].Parent then return cache[key]end local want={}for _,a in ipairs(Aliases[name]or{name})do want[norm(a)]=true end local best,bs=nil,-1 local function scan(o,bonus)if not(o:IsA('Model')or o:IsA('Tool'))then return end if P.Character and o:IsDescendantOf(P.Character)then return end if o:IsDescendantOf(Placed)then return end if cat=='Pets'and badPet(o)then return end local h=hit(o,want)if h<=0 then return end local count=0 for _,d in ipairs(o:GetDescendants())do if d:IsA('BasePart')then count+=1 end end if count<1 then return end local sc=h+bonus+math.min(count,100)if sc>bs then best,bs=o,sc end end for _,r in ipairs({{RS,220},{workspace,80}})do local list=r[1]:GetDescendants()for i,o in ipairs(list)do scan(o,r[2])if i%1500==0 then task.wait()end end end if type(getnilinstances)=='function'then local ok,list=pcall(getnilinstances)if ok then for i,o in ipairs(list)do if typeof(o)=='Instance'then scan(o,120)end if i%1500==0 then task.wait()end end end end cache[key]=best return best end
local function clone(src,name)if not src then return nil end local ok,c=pcall(function()return src:Clone()end)if not ok or not c then return nil end local m=c if c:IsA('Tool')then m=Instance.new('Model')m.Name=name for _,q in ipairs(c:GetChildren())do if not(q:IsA('Script')or q:IsA('LocalScript')or q:IsA('ModuleScript'))then q.Parent=m end end c:Destroy()end if not m:IsA('Model')then return nil end local kill={}for _,d in ipairs(m:GetDescendants())do if d:IsA('Script')or d:IsA('LocalScript')or d:IsA('ModuleScript')or d:IsA('Humanoid')or d:IsA('Animator')or d:IsA('ProximityPrompt')or d:IsA('ClickDetector')or d:IsA('SurfaceGui')or d:IsA('BillboardGui')then kill[#kill+1]=d end end for _,d in ipairs(kill)do d:Destroy()end if not m:FindFirstChildWhichIsA('BasePart',true)then m:Destroy()return nil end m.Name=name return m end
local function fit(m,target)local ok,s=pcall(function()return m:GetExtentsSize()end)if ok then local mx=math.max(s.X,s.Y,s.Z)if mx>.01 then pcall(function()m:ScaleTo(target/mx)end)end end end
-- Prefer the actual held/backpack star; source() intentionally skips character models.
local function inventoryStar()
    local names={star=true,stars=true,startool=true,goldenstar=true,goldenstars=true,goldstar=true,divinestar=true}
    local holders={}
    if P.Character then holders[#holders+1]=P.Character end
    if BP then holders[#holders+1]=BP end
    for _,holder in ipairs(holders) do
        for _,tool in ipairs(holder:GetChildren()) do
            if tool:IsA('Tool') and not tool:GetAttribute('SAE_V7_TOOL') then
                local matched=names[norm(tool.Name):gsub('%d','')]==true
                for _,attribute in ipairs({'ItemName','DisplayName','Title','Type'}) do
                    if names[norm(tool:GetAttribute(attribute))] then matched=true end
                end
                if not matched then
                    for _,object in ipairs(tool:GetDescendants()) do
                        if (object:IsA('Model') or object:IsA('BasePart')) and names[norm(object.Name)] then
                            matched=true; break
                        end
                    end
                end
                if matched then
                    local copy=clone(tool,'Star')
                    if copy then
                        local handle=copy:FindFirstChild('Handle',true) or copy:FindFirstChildWhichIsA('BasePart',true)
                        if handle then copy.PrimaryPart=handle copy:PivotTo(CFrame.new()) end
                        copy:SetAttribute('SAE_STAR_SOURCE','Actual inventory star')
                        return copy
                    end
                end
            end
        end
    end
end
local function buildModel(cat,name)
    if cat=='Star' and name=='Star' then local m=star(); fit(m,7.5); return m,false end
    if name=="Ben's Treadmill" then return customTreadmill(name,false),false end
    if name=="Brocodile's Treadmill" then return customTreadmill(name,true),false end
    if cat=='Eggs' and EGG_DESIGNS[name] then local m=buildSculptedEgg(name) if m then return m,false end end if cat=='Pets' and (name=='Night Flame' or name=='Luminous Cthulhu') then local f=Built[name] if f then local m=f() fit(m,16) return m,false end end local src=source(cat,name)if src then local m=clone(src,name)if m then fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,true end end local f=Built[name]if f then local m=f()fit(m,cat=='Pets'and 16 or cat=='Eggs'and 10.5 or 7.5)return m,false end return nil,false end
-- Keep the prepared geometry between spawns; each Tool receives its own clone.
local preparedModels={}
local preparingModels={}
local function model(cat,name)
    if cat=='Star' and name=='Star' then
        local actual=inventoryStar()
        if actual then fit(actual,7.5); return actual,true end
    end
    local key=cat..'|'..name
    while preparingModels[key] do task.wait() end
    local entry=preparedModels[key]
    if not entry then
        preparingModels[key]=true
        local ok,template,exact=pcall(buildModel,cat,name)
        preparingModels[key]=nil
        if not ok then error(template) end
        if not template then return nil,false end
        entry={template=template,exact=exact}
        preparedModels[key]=entry
    end
    return entry.template:Clone(),entry.exact
end

-- Cinematic parcels use isolated clones of the same 3D inventory models.
do
    local previous=E.SAE_PACKAGE_RUNTIME
    if previous and type(previous.Destroy)=='function' then pcall(function() previous:Destroy() end) end
    local runtime={queue={},dead=false,active=nil,generation=0}
    E.SAE_PACKAGE_RUNTIME=runtime
    local TS=game:GetService('TweenService')
    local Run=game:GetService('RunService')
    local Debris=game:GetService('Debris')
    local purple=Color3.fromRGB(48,20,72)
    local cardboard=Color3.fromRGB(171,119,65)
    local function clamp01(value) return math.clamp(value,0,1) end
    local function smooth(value) value=clamp01(value); return value*value*(3-2*value) end
    local function resolveModel(cmd,item)
        local aliases={Nightflame='Night Flame',ArchAngel='Archangel',
            ['Brockodile Treadmill']="Brocodile's Treadmill"}
        local name=aliases[item] or item
        if cmd=='/giveeggs' then return 'Eggs',name..' Egg' end
        if cmd=='/givepets' then return 'Pets',name end
        if cmd=='/giveeverything' then return 'Bundle','Everything' end
        if cmd=='/givetreadmill' then return 'Star',name end
        if cmd=='/givestars' then return 'Star','Star' end
        error('Unsupported parcel item')
    end
    local function makePart(parent,name,size,color,material)
        local p=Instance.new('Part')
        p.Name=name p.Size=size p.Color=color p.Material=material or Enum.Material.SmoothPlastic
        p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
        p.CastShadow=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
        p.Parent=parent
        return p
    end
    -- Fit every corner of the closed parcel inside the sticker shot, including narrow screens.
    local function frameParcel(base,floor,width,height,depth,aspect,fov,yaw)
        local target=floor+Vector3.new(0,height*.5,0)
        yaw=yaw or 0
        local toward=base.LookVector*math.cos(yaw)+base.RightVector*math.sin(yaw)
        local right=base.RightVector*math.cos(yaw)-base.LookVector*math.sin(yaw)
        local direction=(toward+right*.18+Vector3.new(0,.4,0)).Unit
        local axes=CFrame.lookAt(target+direction,target)
        local vertical=math.tan(math.rad(fov*.5))*.86
        local horizontal=vertical*math.max(.2,aspect)
        local distance=1
        for _,x in ipairs({-width*.5,width*.5}) do
            for _,y in ipairs({0,height+.12}) do
                for _,z in ipairs({-depth*.5-.16,depth*.5}) do
                    local relative=(base*CFrame.new(x,y,z)).Position-target
                    local toward=relative:Dot(direction)
                    distance=math.max(distance,toward+math.abs(relative:Dot(axes.RightVector))/horizontal,
                        toward+math.abs(relative:Dot(axes.UpVector))/vertical)
                end
            end
        end
        return CFrame.lookAt(target+direction*distance,target)
    end
    local function restoreCamera(state,force)
        local camera=state.camera
        if camera and workspace.CurrentCamera==camera and (force or camera.CameraType==Enum.CameraType.Scriptable) then
            camera.CFrame=state.cframe camera.Focus=state.focus camera.FieldOfView=state.fov
            camera.CameraSubject=state.subject camera.CameraType=state.cameraType
        end
    end
    local function cleanup(state,force)
        if state.cleaned then return end
        state.cleaned=true
        if state.visibilityConnections then
            for _,connection in ipairs(state.visibilityConnections) do connection:Disconnect() end
        end
        if state.hidden then
            for object,saved in pairs(state.hidden) do
                if object.Parent then pcall(function() object[saved.property]=saved.value end) end
            end
        end
        if state.connection then state.connection:Disconnect() end
        restoreCamera(state,force)
        if state.console and state.console.Parent then state.console.Visible=state.consoleVisible end
        if state.stopPreview then state.stopPreview(); state.stopPreview=nil end
        if state.itemStickerGui then state.itemStickerGui:Destroy() end
        if state.scene then state.scene:Destroy() end
        if state.finished then state.finished:Fire() end
    end
    -- Reset queued and active preparation when the runtime is destroyed.
    function runtime:Reset()
        self.generation+=1
        table.clear(self.queue)
        if self.active then cleanup(self.active,true) end
        if self.dispatchGui then self.dispatchGui:Destroy(); self.dispatchGui=nil end
        for _,object in ipairs(workspace:GetChildren()) do
            if object.Name=='SAE_DELIVERY_PARCEL' then object:Destroy() end
        end
        for _,object in ipairs(PG:GetChildren()) do
            if object.Name=='SAE_PACKAGE_DISPATCH' then object:Destroy() end
        end
        local camera=workspace.CurrentCamera
        if camera then
            local character=P.Character
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            if humanoid then camera.CameraSubject=humanoid end
            camera.CameraType=Enum.CameraType.Custom
        end
    end
    function runtime:Destroy()
        if self.dead then return end
        self.dead=true
        self:Reset()
        if self.guiConnection then self.guiConnection:Disconnect() end
        if E.SAE_PACKAGE_RUNTIME==self then
            E.SAE_PACKAGE_DELIVERY=nil E.SAE_PACKAGE_RUNTIME=nil
        end
    end
    runtime.guiConnection=Gui.Destroying:Connect(function() runtime:Destroy() end)
    local function dispatchCaption()
        local sg=Instance.new('ScreenGui')
        sg.Name='SAE_PACKAGE_DISPATCH' sg.ResetOnSpawn=false sg.IgnoreGuiInset=true
        sg.DisplayOrder=960 sg.Parent=PG
        runtime.dispatchGui=sg
        local caption=Instance.new('TextLabel')
        caption.AnchorPoint=Vector2.new(.5,1) caption.Position=UDim2.new(.5,0,1,-72)
        caption.Size=UDim2.fromOffset(300,30) caption.BackgroundTransparency=1
        caption.Text='PACKAGE ON ITS WAY' caption.Font=Enum.Font.GothamBold caption.TextSize=16
        caption.TextColor3=Color3.fromRGB(232,208,255)
        caption.TextStrokeColor3=Color3.fromRGB(20,8,30) caption.TextStrokeTransparency=.25
        caption.Parent=sg
        TS:Create(caption,TweenInfo.new(.9,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
            Position=UDim2.new(.5,0,1,-92),TextTransparency=1,TextStrokeTransparency=1
        }):Play()
        Debris:AddItem(sg,1.2)
    end
    local function conceal(state,object)
        local property,value
        if object:IsA('BasePart') then property='LocalTransparencyModifier'; value=1
        elseif object:IsA('Decal') then property='Transparency'; value=1
        elseif object:IsA('BillboardGui') or object:IsA('SurfaceGui') or object:IsA('ParticleEmitter')
            or object:IsA('Beam') or object:IsA('Trail') or object:IsA('PointLight')
            or object:IsA('SpotLight') or object:IsA('SurfaceLight') then property='Enabled'; value=false end
        if not property then return end
        if not state.hidden[object] then state.hidden[object]={property=property,value=object[property]} end
        object[property]=value
    end
    local function concealTree(state,root,watch)
        if not root then return end
        conceal(state,root)
        for _,object in ipairs(root:GetDescendants()) do conceal(state,object) end
        if watch then
            state.visibilityConnections[#state.visibilityConnections+1]=root.DescendantAdded:Connect(function(object)
                if not state.cleaned then conceal(state,object) end
            end)
        end
    end
    local function clearView(state,scene,character,treadmill,targets)
        -- Run after Roblox's camera update so first-person transparency cannot reveal the head.
        for object,saved in pairs(state.hidden) do
            if object.Parent then
                if saved.property=='Enabled' then object[saved.property]=false else object[saved.property]=1 end
            end
        end
        local ignore={scene,character}
        if treadmill then ignore[#ignore+1]=treadmill end
        local ok,obstructions=pcall(function()
            return state.camera:GetPartsObscuringTarget(targets,ignore)
        end)
        if ok then
            for _,object in ipairs(obstructions) do concealTree(state,object,false) end
        end
    end
    local function sanitizeParcelModel(template)
        for _,object in ipairs(template:GetDescendants()) do
            if object:IsA('LuaSourceContainer') or object:IsA('Humanoid') or object:IsA('AnimationController')
                or object:IsA('BillboardGui') or object:IsA('SurfaceGui') or object:IsA('Sound') then
                object:Destroy()
            elseif object:IsA('BasePart') then
                if object.Transparency>=.99 and not object:FindFirstChildWhichIsA('BasePart',true) then
                    -- Invisible rig handles must not shrink the visible pet or egg.
                    object:Destroy()
                else
                    object.Anchored=true object.CanCollide=false object.CanTouch=false object.CanQuery=false
                end
            end
        end
    end
    local function mixedParcel(request)
        local bundle=Instance.new('Model') bundle.Name='Everything'
        bundle:SetAttribute('SAE_MIXED_PARCEL',true)
        local specs={
            {category='Pets',name='Unicorn',maximum=3.8},
            {category='Pets',name='Kitsune',maximum=3.8},
            {category='Eggs',name='Unicorn Egg',maximum=3.8},
            {category='Eggs',name='Kitsune Egg',maximum=3.8},
            {category='Star',name="Ben's Treadmill",maximum=5.8}
        }
        local entries={}
        for _,spec in ipairs(specs) do
            local ok,item=pcall(model,spec.category,spec.name)
            if runtime.dead or request.generation~=runtime.generation then
                if ok and item then item:Destroy() end
                bundle:Destroy(); return nil
            end
            if not ok or not item then
                bundle:Destroy(); error('Mixed parcel model unavailable: '..spec.name)
            end
            item.Parent=bundle
            sanitizeParcelModel(item)
            local size=item:GetExtentsSize()
            local maximum=math.max(size.X,size.Y,size.Z)
            if maximum<=.001 then bundle:Destroy(); error('Empty mixed parcel model: '..spec.name) end
            local factor=spec.maximum/maximum
            local shellHeight=item:GetAttribute('SAE_BODY_HEIGHT')
            if spec.category=='Eggs' and type(shellHeight)=='number' and shellHeight>.01 then
                factor=math.min(2.4/shellHeight,factor)
            end
            item:ScaleTo(item:GetScale()*factor)
            item.Name=spec.name item:SetAttribute('SAE_PARCEL_CATEGORY',spec.category)
            local boxCf,bounds=item:GetBoundingBox()
            entries[#entries+1]={model=item,size=bounds,correction=item:GetPivot():ToObjectSpace(boxCf):Inverse()}
        end
        local petLeft,petRight,eggLeft,eggRight,machine=table.unpack(entries)
        local backDepth=math.max(petLeft.size.Z,petRight.size.Z,machine.size.Z)
        local frontDepth=math.max(eggLeft.size.Z,eggRight.size.Z)
        local backZ=frontDepth*.5+.2
        local frontZ=-backDepth*.5-.2
        local positions={
            Vector3.new(-(machine.size.X+petLeft.size.X)*.5-.35,0,backZ),
            Vector3.new((machine.size.X+petRight.size.X)*.5+.35,0,backZ),
            Vector3.new(-(eggLeft.size.X+eggRight.size.X)*.25-.2,0,frontZ),
            Vector3.new((eggLeft.size.X+eggRight.size.X)*.25+.2,0,frontZ),
            Vector3.new(0,0,backZ)
        }
        for index,entry in ipairs(entries) do
            local position=positions[index]+Vector3.new(0,entry.size.Y*.5,0)
            local yaw=index==5 and math.pi or 0
            entry.model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yaw,0)*entry.correction)
        end
        return bundle
    end
    local function play(request)
        local character=P.Character
        local runner=E.SAE_TREADMILL_RUNTIME
        local treadmill=runner and type(runner.GetActiveModel)=='function' and runner:GetActiveModel() or nil
        local root=character and character:FindFirstChild('HumanoidRootPart')
        local camera=workspace.CurrentCamera
        if not root or not camera then error('Character or camera is unavailable') end
        local category,name=resolveModel(request.cmd,request.item)
        local isTreadmill=request.cmd=='/givetreadmill'
        local template
        if category=='Bundle' then template=mixedParcel(request) else template=model(category,name) end
        if runtime.dead or request.generation~=runtime.generation then
            if template then template:Destroy() end
            return
        end
        if not template then error('3D model unavailable: '..tostring(name)) end
        -- The preparatory clone is never parented into the live world.
        sanitizeParcelModel(template)
        local bounds=template:GetExtentsSize()
        local maxSize=math.max(bounds.X,bounds.Y,bounds.Z)
        if maxSize<=.001 then template:Destroy(); error('Empty parcel model') end
        local bodyHeight=template:GetAttribute('SAE_BODY_HEIGHT')
        local displayFactor
        if category=='Bundle' then
            displayFactor=1
        elseif category=='Eggs' and type(bodyHeight)=='number' and bodyHeight>.01 then
            -- Size the shell itself; decorative horns must not miniaturize the egg.
            displayFactor=math.min(2.9/bodyHeight,4.8/maxSize)
        elseif category=='Pets' then
            displayFactor=6/maxSize
        else
            displayFactor=(request.quantity==1 and 3.8 or 3.5)/maxSize
        end
        local nativeScale=template:GetScale()
        template:ScaleTo(nativeScale*displayFactor)
        local itemBounds=template:GetExtentsSize()
        local slotWidth=itemBounds.X+.25
        local slotDepth=itemBounds.Z+.25
        local boxWidth=math.max(6.4,itemBounds.X*(request.quantity==1 and 1 or 2)+.75)
        local boxDepth=math.max(4.8,itemBounds.Z*(request.quantity==1 and 1 or 2)+.75)
        local boxHeight=math.max(3.3,itemBounds.Y+.45)
        local halfWidth,halfDepth=boxWidth*.5,boxDepth*.5
        local portalRadius=math.max(5.2,math.sqrt(math.max(boxWidth,boxDepth)^2+boxHeight^2)*.5+.8)
        local portalHeight=math.max(48,boxHeight*5+25)
        local pickupHeight=boxHeight+13
        local saucerWidth=math.max(12,boxWidth*1.45)
        local recipientId=request.userId
        if not recipientId then
            local ok,id=pcall(function() return Players:GetUserIdFromNameAsync(request.recipient) end)
            if runtime.dead or request.generation~=runtime.generation then template:Destroy(); return end
            if not ok or type(id)~='number' or id<=0 then
                template:Destroy(); error('Recipient account could not be found')
            end
            recipientId=id
        end
        if runtime.dead or request.generation~=runtime.generation then template:Destroy(); return end
        local previewAvatar,previewMachine
        local function discardPreparedPreview()
            if previewAvatar then previewAvatar:Destroy() end
            if previewMachine then previewMachine:Destroy() end
        end
        if isTreadmill then
            local ok,avatar=pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(recipientId) end)
            if runtime.dead or request.generation~=runtime.generation then
                if ok and avatar then avatar:Destroy() end
                template:Destroy(); return
            end
            if not ok or not avatar then template:Destroy(); error('Recipient avatar could not be prepared') end
            previewAvatar=avatar
            previewAvatar.Name='RecipientRunner'
            local previewHumanoid=previewAvatar:FindFirstChildOfClass('Humanoid')
            if runner and type(runner.PreparePreview)=='function' and previewHumanoid then
                runner:PreparePreview(previewAvatar,previewHumanoid)
            end
            previewMachine=template:Clone() previewMachine.Name='TreadmillRunningPreview'
            previewMachine:ScaleTo(nativeScale)
            for _,object in ipairs(previewAvatar:GetDescendants()) do
                if object:IsA('LuaSourceContainer') or object:IsA('Sound') then object:Destroy()
                elseif object:IsA('BasePart') then
                    object.Anchored=false object.CanCollide=false object.CanTouch=false object.CanQuery=false
                end
            end
        end
        -- Fetch meshes, textures, portal particles and the portrait before the camera takes over.
        local portrait=Instance.new('ImageLabel')
        portrait.Image='rbxthumb://type=AvatarHeadShot&id='..recipientId..'&w=420&h=420'
        local preloadOk,preloadError=pcall(function()
            local assets={template,portrait,
                'rbxasset://textures/particles/sparkles_main.dds',
                'rbxasset://textures/particles/smoke_main.dds'}
            if previewAvatar then assets[#assets+1]=previewAvatar end
            game:GetService('ContentProvider'):PreloadAsync(assets)
        end)
        portrait:Destroy()
        if runtime.dead or request.generation~=runtime.generation then discardPreparedPreview(); template:Destroy(); return end
        if not preloadOk then discardPreparedPreview(); template:Destroy(); error('Parcel assets could not be prepared: '..tostring(preloadError)) end
        -- Place the scene on the floor in front of the sender, excluding their character.
        local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
        if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) else forward=forward.Unit end
        local point=root.Position+forward*9
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local floorIgnore={character,Placed}
        if treadmill then floorIgnore[#floorIgnore+1]=treadmill end
        params.FilterDescendantsInstances=floorIgnore
        local hit=workspace:Raycast(point+Vector3.new(0,20,0),Vector3.new(0,-128,0),params)
        if not hit then discardPreparedPreview(); template:Destroy(); error('No floor found for parcel landing') end
        local floor=hit.Position+Vector3.new(0,.06,0)
        local base=CFrame.lookAt(floor,floor-forward)
        local scene=Instance.new('Model') scene.Name='SAE_DELIVERY_PARCEL' scene.Parent=workspace
        local state={scene=scene,camera=camera,cframe=camera.CFrame,focus=camera.Focus,
            fov=camera.FieldOfView,subject=camera.CameraSubject,cameraType=camera.CameraType,
            console=Console,consoleVisible=Console.Visible,hidden={},visibilityConnections={},
            finished=Instance.new('BindableEvent')}
        runtime.active=state
        if previewAvatar then previewAvatar.Parent=scene previewMachine.Parent=scene end
        concealTree(state,character,true)
        concealTree(state,treadmill,true)
        for _,object in ipairs(PG:GetDescendants()) do
            if object:IsA('BillboardGui') and object.Adornee and object.Adornee:IsDescendantOf(character) then
                conceal(state,object)
            end
        end
        -- Any construction or frame failure is caught by the queue worker and restores the camera.
        local pieces,flaps,contents,portal={},{},{},{}
        local contentParts={}
        local parcelRig=nil
        local rigidParts,rigidOffsets,rigidFrames={},{},{}
        local portalWasVisible=true
        local ufoWasVisible=false
        local lastParcelAlpha=nil
        local function piece(name,size,offset,color)
            local object=makePart(scene,name,size,color or cardboard)
            pieces[#pieces+1]={part=object,offset=offset}
            return object
        end
        piece('BoxBase',Vector3.new(boxWidth,.18,boxDepth),CFrame.new(0,.09,0))
        piece('FrontWall',Vector3.new(boxWidth,boxHeight-.1,.13),CFrame.new(0,boxHeight*.5,-halfDepth))
        piece('BackWall',Vector3.new(boxWidth,boxHeight-.1,.13),CFrame.new(0,boxHeight*.5,halfDepth))
        piece('LeftWall',Vector3.new(.13,boxHeight-.1,boxDepth),CFrame.new(-halfWidth,boxHeight*.5,0))
        piece('RightWall',Vector3.new(.13,boxHeight-.1,boxDepth),CFrame.new(halfWidth,boxHeight*.5,0))
        -- Thin kraft-paper edges make the parcel read as folded cardboard.
        for _,x in ipairs({-halfWidth+.05,halfWidth-.05}) do
            piece('FoldedEdge',Vector3.new(.06,boxHeight-.1,.06),CFrame.new(x,boxHeight*.5,-halfDepth-.08),Color3.fromRGB(208,154,89))
        end
        for _,side in ipairs({-1,1}) do
            local lid=makePart(scene,'LongFlap',Vector3.new(boxWidth,.10,halfDepth),cardboard)
            flaps[#flaps+1]={part=lid,side=side,axis='x'}
            local endLid=makePart(scene,'EndFlap',Vector3.new(halfWidth,.08,boxDepth),Color3.fromRGB(153,103,57))
            flaps[#flaps+1]={part=endLid,side=side,axis='z'}
        end
        local sources={}
        if category=='Bundle' then
            local bundleBox=template:GetBoundingBox()
            for _,source in ipairs(template:GetChildren()) do
                if source:IsA('Model') then
                    local childBox=source:GetBoundingBox()
                    local position=bundleBox:PointToObjectSpace(childBox.Position)
                    sources[#sources+1]={source=source,x=position.X,z=position.Z,
                        yaw=source:GetAttribute('SAE_PARCEL_CATEGORY')=='Star' and math.pi or 0}
                end
            end
        else
            for index=1,request.quantity do
                sources[#sources+1]={source=template,
                    x=request.quantity==1 and 0 or (index==1 and -slotWidth*.5 or index==2 and slotWidth*.5 or 0),
                    z=request.quantity==1 and 0 or (index<3 and slotDepth*.5 or -slotDepth*.5),yaw=0}
            end
        end
        for index,source in ipairs(sources) do
            local item=source.source:Clone() item.Name='ParcelItem'..index
            local itemParts={}
            for _,object in ipairs(item:GetDescendants()) do
                if object:IsA('BasePart') then
                    object.LocalTransparencyModifier=1
                    itemParts[#itemParts+1]=object contentParts[object]=true
                end
            end
            item.Parent=scene
            local boxCf,size=item:GetBoundingBox()
            local pivotToBounds=item:GetPivot():ToObjectSpace(boxCf)
            contents[#contents+1]={model=item,parts=itemParts,alpha=1,size=size,correction=pivotToBounds:Inverse(),
                x=source.x,z=source.z,yaw=source.yaw,index=index}
        end
        local stickerModel=template:Clone()
        if category=='Bundle' then
            for _,item in ipairs(stickerModel:GetChildren()) do
                if item:IsA('Model') and item:GetAttribute('SAE_PARCEL_CATEGORY')=='Star' then
                    -- The fixed picture camera needs the machine's front, not its rear console.
                    item:PivotTo(item:GetPivot()*CFrame.Angles(0,math.pi,0))
                end
            end
        end
        template:Destroy()
        local glow=makePart(scene,'RevealGlow',Vector3.new(.1,.1,.1),purple,Enum.Material.Neon)
        glow.Transparency=1
        local light=Instance.new('PointLight') light.Color=Color3.fromRGB(204,174,235) light.Range=math.max(11,boxWidth*1.8) light.Brightness=0 light.Parent=glow
        local portalEffects={}
        for index=1,64 do
            local angle=(index-1)/32*math.pi*2
            local segment=makePart(scene,'PortalArc',Vector3.new(.15,.13,.98),index<=32 and purple or Color3.fromRGB(72,39,94),Enum.Material.Neon)
            segment.CastShadow=false
            portal[#portal+1]={part=segment,angle=angle,band=index<=32 and 1 or .83}
            portalEffects[segment]=true
        end
        -- A luminous interior and rotating rings read as a portal rather than a bare hoop.
        local iris=makePart(scene,'PortalIris',Vector3.new(.08,portalRadius*1.84,portalRadius*1.84),Color3.fromRGB(5,2,11),Enum.Material.SmoothPlastic)
        iris.Shape=Enum.PartType.Cylinder
        iris.CastShadow=false
        portalEffects[iris]=true
        local sparks=Instance.new('ParticleEmitter')
        sparks.Name='PortalSparks'
        sparks.Texture='rbxasset://textures/particles/sparkles_main.dds'
        sparks.Color=ColorSequence.new(Color3.fromRGB(128,108,151),purple)
        sparks.Size=NumberSequence.new(.16,0)
        sparks.Transparency=NumberSequence.new(.5,1)
        sparks.LightEmission=.15 sparks.Rate=5
        sparks.Lifetime=NumberRange.new(.35,.8) sparks.Speed=NumberRange.new(.4,1.3)
        sparks.SpreadAngle=Vector2.new(180,180)
        sparks.Acceleration=Vector3.new(0,-2,0)
        sparks.Parent=iris
        local mist=Instance.new('ParticleEmitter')
        mist.Name='PortalMist' mist.Texture='rbxasset://textures/particles/smoke_main.dds'
        mist.Color=ColorSequence.new(Color3.fromRGB(3,2,7),Color3.fromRGB(24,12,36))
        mist.Size=NumberSequence.new(1.3,2.7) mist.Transparency=NumberSequence.new(.32,1)
        mist.Lifetime=NumberRange.new(.8,1.4) mist.Speed=NumberRange.new(.3,.9)
        mist.Rate=12 mist.LightEmission=0 mist.LightInfluence=.6
        mist.Rotation=NumberRange.new(-180,180) mist.RotSpeed=NumberRange.new(-15,15)
        mist.SpreadAngle=Vector2.new(180,180) mist.EmissionDirection=Enum.NormalId.Right
        mist.Parent=iris
        local portalStars={}
        for index=1,11 do
            local angle=index*2.39996
            local radius=portalRadius*math.sqrt(index/12)*.76
            local size=index%3==0 and .17 or .10
            local star=makePart(scene,'PortalStar',Vector3.new(size,size,size),
                Color3.fromRGB(159,143,179),Enum.Material.Neon)
            star.Shape=Enum.PartType.Ball star.CastShadow=false star.Transparency=1
            portalStars[#portalStars+1]={part=star,x=math.cos(angle)*radius,z=math.sin(angle)*radius,phase=index}
            portalEffects[star]=true
        end
        -- The collector is separate from the parcel: no ground ring or exit portal.
        local ufoParts={}
        local function saucerPart(name,size,offset,color,material,shape)
            local part=makePart(scene,name,size,color,material)
            if shape then part.Shape=shape end
            part.CastShadow=false part.Transparency=1
            portalEffects[part]=true
            ufoParts[#ufoParts+1]={part=part,offset=offset}
            return part
        end
        local metal=Color3.fromRGB(37,40,49)
        local green=Color3.fromRGB(38,145,55)
        saucerPart('UFOHull',Vector3.new(1.25,saucerWidth,saucerWidth),
            CFrame.Angles(0,0,math.pi*.5),metal,Enum.Material.Metal,Enum.PartType.Cylinder)
        saucerPart('UFORim',Vector3.new(.16,saucerWidth*1.02,saucerWidth*1.02),
            CFrame.new(0,-.35,0)*CFrame.Angles(0,0,math.pi*.5),green,Enum.Material.Neon,Enum.PartType.Cylinder)
        saucerPart('UFODome',Vector3.new(saucerWidth*.44,saucerWidth*.22,saucerWidth*.44),
            CFrame.new(0,.9,0),Color3.fromRGB(54,88,77),Enum.Material.Glass,Enum.PartType.Ball)
        saucerPart('UFOTractorAperture',Vector3.new(.18,3,3),
            CFrame.new(0,-.72,0)*CFrame.Angles(0,0,math.pi*.5),green,Enum.Material.Neon,Enum.PartType.Cylinder)
        -- A raised, layered roof gives the craft a readable silhouette from above and below.
        for index=1,4 do
            local diameter=saucerWidth*(.88-index*.115)
            saucerPart('UFORoofTier'..index,Vector3.new(.40,diameter,diameter),
                CFrame.new(0,.65+index*.32,0)*CFrame.Angles(0,0,math.pi*.5),
                Color3.fromRGB(62+index*5,65+index*5,78+index*5),Enum.Material.Metal,Enum.PartType.Cylinder)
        end
        saucerPart('UFORoofCrown',Vector3.new(saucerWidth*.28,2.1,saucerWidth*.28),
            CFrame.new(0,2.15,0),Color3.fromRGB(85,139,116),Enum.Material.Glass,Enum.PartType.Ball)
        saucerPart('UFOAntenna',Vector3.new(.12,1.15,.12),
            CFrame.new(0,3.35,0),metal,Enum.Material.Metal)
        saucerPart('UFOBeacon',Vector3.new(.32,.32,.32),
            CFrame.new(0,3.98,0),green,Enum.Material.Neon,Enum.PartType.Ball)
        for index=1,8 do
            local angle=index/8*math.pi*2
            saucerPart('UFOCabinWindow',Vector3.new(.8,.32,.13),
                CFrame.new(math.sin(angle)*saucerWidth*.25,1.52,math.cos(angle)*saucerWidth*.25)
                    *CFrame.Angles(0,angle,0),Color3.fromRGB(122,219,174),Enum.Material.Neon)
        end
        for index=1,10 do
            local angle=index/10*math.pi*2
            saucerPart('UFOLamp',Vector3.new(.35,.16,.35),
                CFrame.new(math.cos(angle)*saucerWidth*.39,-.67,math.sin(angle)*saucerWidth*.39),
                green,Enum.Material.Neon,Enum.PartType.Ball)
        end
        local beamTop=makePart(scene,'TractorTop',Vector3.new(.1,.1,.1),green)
        local beamBottom=makePart(scene,'TractorBottom',Vector3.new(.1,.1,.1),green)
        beamTop.Transparency=1 beamBottom.Transparency=1
        portalEffects[beamTop]=true portalEffects[beamBottom]=true
        local topAttachment=Instance.new('Attachment') topAttachment.Parent=beamTop
        local bottomAttachment=Instance.new('Attachment') bottomAttachment.Parent=beamBottom
        local tractor=Instance.new('Beam')
        tractor.Name='GreenTractorBeam' tractor.Attachment0=topAttachment tractor.Attachment1=bottomAttachment
        tractor.FaceCamera=true tractor.Width0=2.8 tractor.Width1=math.max(boxWidth,boxDepth)+2
        tractor.Color=ColorSequence.new(Color3.fromRGB(23,116,35),Color3.fromRGB(42,157,50))
        tractor.Transparency=NumberSequence.new(.38,.76)
        tractor.LightEmission=.35 tractor.LightInfluence=0 tractor.Enabled=false tractor.Parent=beamTop
        local tractorLight=Instance.new('PointLight')
        tractorLight.Color=Color3.fromRGB(32,134,42) tractorLight.Range=pickupHeight+5 tractorLight.Brightness=0 tractorLight.Parent=beamTop
        local portalLight=Instance.new('PointLight')
        portalLight.Color=purple portalLight.Range=15 portalLight.Brightness=.7 portalLight.Parent=portal[1].part
        local tape=piece('YellowSealTape',Vector3.new(1.25,.06,boxDepth+.08),CFrame.new(0,boxHeight+.07,0),Color3.fromRGB(255,208,48))
        tape.Transparency=1
        local labelWidth=math.min(boxWidth*.88,boxHeight*.62*680/300)
        local labelHeight=labelWidth*300/680
        local sticker=makePart(scene,'CourierSticker',Vector3.new(labelWidth,labelHeight,.03),Color3.fromRGB(255,212,52))
        sticker.Transparency=1
        local shipping=Instance.new('SurfaceGui')
        shipping.Name='RecipientLabel' shipping.Face=Enum.NormalId.Front
        shipping.CanvasSize=Vector2.new(680,300) shipping.LightInfluence=0
        shipping.Enabled=false shipping.Parent=sticker
        local avatar=Instance.new('ImageLabel')
        avatar.BackgroundTransparency=1 avatar.Position=UDim2.fromOffset(24,28)
        avatar.Size=UDim2.fromOffset(244,244)
        avatar.Image='rbxthumb://type=AvatarHeadShot&id='..recipientId..'&w=420&h=420'
        avatar.Parent=shipping
        local to=Instance.new('TextLabel')
        to.BackgroundTransparency=1 to.Position=UDim2.fromOffset(292,32) to.Size=UDim2.fromOffset(364,42)
        to.Text='DELIVER TO' to.TextColor3=Color3.fromRGB(61,37,12)
        to.Font=Enum.Font.GothamBold to.TextSize=28 to.TextXAlignment=Enum.TextXAlignment.Left to.Parent=shipping
        local user=to:Clone() user.Position=UDim2.fromOffset(292,92) user.Size=UDim2.fromOffset(364,180)
        user.Text='@'..request.recipient user.TextSize=44 user.TextWrapped=true user.Parent=shipping
        -- A separate cream badge keeps the item picture clear of the name and avatar.
        local badgeWidth=math.min(2.1,boxWidth*.20,boxHeight*.23)
        local itemBadge=makePart(scene,'ItemPictureSticker',Vector3.new(badgeWidth,badgeWidth,.035),
            Color3.fromRGB(255,246,223))
        itemBadge.Transparency=1 -- Invisible carrier: only the item picture is drawn.
        local badgeGui=Instance.new('SurfaceGui')
        badgeGui.Name='ItemPictureLabel' badgeGui.Adornee=itemBadge
        badgeGui.Face=Enum.NormalId.Front badgeGui.CanvasSize=Vector2.new(192,192)
        badgeGui.LightInfluence=0 badgeGui.Enabled=false badgeGui.Parent=PG
        state.itemStickerGui=badgeGui
        local viewport=Instance.new('ViewportFrame')
        viewport.Name='SelectedItemPicture' viewport.Size=UDim2.fromScale(1,1)
        viewport.BackgroundTransparency=1 viewport.Ambient=Color3.fromRGB(210,205,220)
        viewport.LightColor=Color3.fromRGB(255,245,226)
        viewport.LightDirection=Vector3.new(-1,-1,-2) viewport.Parent=badgeGui
        local world=Instance.new('WorldModel') world.Parent=viewport
        stickerModel.Name='StickerItem' stickerModel.Parent=world
        local stickerBounds=stickerModel:GetExtentsSize()
        local boundsFrame=stickerModel:GetBoundingBox()
        local correction=stickerModel:GetPivot():ToObjectSpace(boundsFrame):Inverse()
        stickerModel:PivotTo(CFrame.Angles(0,isTreadmill and math.pi or 0,0)*correction)
        local pictureCamera=Instance.new('Camera')
        pictureCamera.FieldOfView=32
        local pictureDistance=math.max(stickerBounds.X,stickerBounds.Y,stickerBounds.Z)*2.25
        pictureCamera.CFrame=CFrame.lookAt(Vector3.new(pictureDistance*.18,pictureDistance*.12,-pictureDistance),Vector3.zero)
        pictureCamera.Parent=viewport viewport.CurrentCamera=pictureCamera
        local fragileWidth=math.min(3,boxWidth*.32)
        local fragileHeight=math.min(.65,boxHeight*.17)
        local fragile=makePart(scene,'FragileSticker',Vector3.new(fragileWidth,fragileHeight,.035),
            Color3.fromRGB(255,241,214))
        fragile.Transparency=1
        local fragileGui=Instance.new('SurfaceGui')
        fragileGui.Name='FragileLabel' fragileGui.Face=Enum.NormalId.Front
        fragileGui.CanvasSize=Vector2.new(480,128) fragileGui.LightInfluence=0
        fragileGui.Enabled=false fragileGui.Parent=fragile
        local fragileText=Instance.new('TextLabel')
        fragileText.Size=UDim2.new(1,-16,1,-16) fragileText.Position=UDim2.fromOffset(8,8)
        fragileText.BackgroundColor3=Color3.fromRGB(255,241,214)
        fragileText.BorderSizePixel=5 fragileText.BorderColor3=Color3.fromRGB(166,40,40)
        fragileText.Text='FRAGILE' fragileText.TextColor3=Color3.fromRGB(166,40,40)
        fragileText.Font=Enum.Font.GothamBold fragileText.TextSize=72 fragileText.Parent=fragileGui
        local parcelParts={}
        for _,object in ipairs(scene:GetDescendants()) do
            if object:IsA('BasePart') and not portalEffects[object] and not contentParts[object] and object~=glow
                and not (previewAvatar and object:IsDescendantOf(previewAvatar))
                and not (previewMachine and object:IsDescendantOf(previewMachine)) then
                parcelParts[#parcelParts+1]=object
            end
        end
        local previewDuration=isTreadmill and 2.6 or 0
        local previewFocus,previewRadius,previewHidden
        local sequenceStart=state.cframe
        if previewAvatar then
            local machineBounds=previewMachine:GetExtentsSize()
            local machineBox=previewMachine:GetBoundingBox()
            local correction=previewMachine:GetPivot():ToObjectSpace(machineBox):Inverse()
            previewMachine:PivotTo(base*CFrame.new(0,machineBounds.Y*.5,0)*CFrame.Angles(0,math.pi,0)*correction)
            local belt=previewMachine:FindFirstChild('RunningBelt',true)
            local previewRoot=previewAvatar:FindFirstChild('HumanoidRootPart')
            local humanoid=previewAvatar:FindFirstChildOfClass('Humanoid')
            if not belt or not previewRoot or not humanoid then error('Recipient treadmill preview is unavailable') end
            previewAvatar.PrimaryPart=previewRoot
            local leg=humanoid.RigType==Enum.HumanoidRigType.R6 and previewAvatar:FindFirstChild('Left Leg')
            local standing=humanoid.HipHeight+previewRoot.Size.Y*.5+(leg and leg.Size.Y or 0)
            local position=belt.Position+Vector3.new(0,belt.Size.Y*.5+standing,0)
            previewAvatar:PivotTo(CFrame.lookAt(position,position+belt.CFrame.LookVector))
            previewRoot.Anchored=true humanoid.AutoRotate=false humanoid.WalkSpeed=0
            humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
            if runner and type(runner.StartPreview)=='function' then
                state.stopPreview=runner:StartPreview(previewAvatar,humanoid,previewMachine,belt)
            else error('Treadmill preview animator is unavailable') end
            previewFocus=belt.Position+Vector3.new(0,standing*.7,0)
            previewRadius=math.max(machineBounds.X,machineBounds.Y,machineBounds.Z,standing*2)*1.35
            previewHidden={}
            for _,object in ipairs(scene:GetDescendants()) do
                if object:IsA('BasePart') and not object:IsDescendantOf(previewAvatar)
                    and not object:IsDescendantOf(previewMachine) then
                    previewHidden[object]=object.LocalTransparencyModifier
                    object.LocalTransparencyModifier=1
                end
            end
            sparks.Enabled=false mist.Enabled=false portalLight.Brightness=0
        end
        local started=os.clock()
        local dispatched=false
        Console.Visible=false
        camera.CameraType=Enum.CameraType.Scriptable
        local renderName='SAE_PARCEL_CAMERA'
        state.connection={Disconnect=function() Run:UnbindFromRenderStep(renderName) end}
        Run:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value+5,function()
            local ok,err=xpcall(function()
                if runtime.dead or not scene.Parent or not character.Parent or P.Character~=character
                    or not root.Parent or workspace.CurrentCamera~=camera or camera.CameraType~=Enum.CameraType.Scriptable then
                    cleanup(state) return
                end
                local t=os.clock()-started
                if previewAvatar then
                    if t<previewDuration then
                        local angle=-.35+math.pi*2*smooth((t-.35)/(previewDuration-.45))
                        local aspect=camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y)
                        local distance=previewRadius*math.max(1,1/math.max(.45,aspect))
                        local previewShot=CFrame.lookAt(previewFocus
                            +base.LookVector*(distance*math.cos(angle))
                            +base.RightVector*(distance*math.sin(angle))
                            +Vector3.new(0,distance*.32,0),previewFocus)
                        camera.CFrame=state.cframe:Lerp(previewShot,smooth(t/.35))
                        camera.FieldOfView=state.fov+(48-state.fov)*smooth(t/.35)
                        camera.Focus=CFrame.new(previewFocus)
                        sequenceStart=camera.CFrame
                        clearView(state,scene,character,treadmill,{
                            previewFocus,previewFocus+Vector3.new(0,2,0),
                            previewFocus+base.RightVector*3,previewFocus-base.RightVector*3
                        })
                        return
                    end
                    if state.stopPreview then state.stopPreview(); state.stopPreview=nil end
                    previewAvatar:Destroy() previewMachine:Destroy()
                    previewAvatar=nil previewMachine=nil
                    for object,value in pairs(previewHidden) do
                        if object.Parent then object.LocalTransparencyModifier=value end
                    end
                    previewHidden=nil
                end
                -- Film a long vertical fall from below, then settle before opening.
                local flight=clamp01((t-.55)/1.4)
                local roll=math.sin(flight*math.pi)*.12
                local x=0
                local y=(portalHeight-boxHeight)*(1-flight*flight)
                if t>=1.95 then y=math.sin(clamp01((t-1.95)/.35)*math.pi)*.3 end
                local departure=smooth((t-7.1)/.55)
                if t>=7.1 then y=(pickupHeight-boxHeight*.5-.85)*departure end
                local centerHeight=math.abs(math.cos(roll))*boxHeight*.5+math.abs(math.sin(roll))*halfWidth
                local parcel=base*CFrame.new(x,y+centerHeight,0)*CFrame.Angles(0,0,roll)
                    *CFrame.new(0,-boxHeight*.5,0)
                local opening=smooth((t-2.35)/.45)*(1-smooth((t-4.45)/.45))
                if parcelRig then
                    for index,offset in ipairs(rigidOffsets) do rigidFrames[index]=parcel*offset end
                    workspace:BulkMoveTo(rigidParts,rigidFrames,Enum.BulkMoveMode.FireCFrameChanged)
                else
                for _,entry in ipairs(pieces) do entry.part.CFrame=parcel*entry.offset end
                for _,flap in ipairs(flaps) do
                    local angle=opening*math.rad(205)
                    if flap.axis=='x' then
                        flap.part.CFrame=parcel*CFrame.new(0,boxHeight,flap.side*halfDepth)
                            *CFrame.Angles(flap.side*angle,0,0)*CFrame.new(0,0,-flap.side*halfDepth*.5)
                    else
                        flap.part.CFrame=parcel*CFrame.new(flap.side*halfWidth,boxHeight-.07,0)
                            *CFrame.Angles(0,0,-flap.side*angle)*CFrame.new(-flap.side*halfWidth*.5,0,0)
                    end
                end
                end
                local placement=smooth((t-3.55)/.75)
                local glowAmount=smooth((t-2.85)/.3)*(1-smooth((t-4.45)/.35))
                local emerge=smooth((t-.55)/.25)
                local fade=smooth((t-7.55)/.13)
                local parcelAlpha=math.max(1-emerge,fade)
                if parcelAlpha~=lastParcelAlpha then
                    for _,object in ipairs(parcelParts) do object.LocalTransparencyModifier=parcelAlpha end
                    lastParcelAlpha=parcelAlpha
                end
                for _,entry in ipairs(contents) do
                    if not parcelRig then
                    local mixed=category=='Bundle'
                    local lowerStart=mixed and (3.25+(entry.index-1)*.17)
                        or ((isTreadmill and 3.9 or 3.55)+(entry.index-1)*.12)
                    local lowering=smooth((t-lowerStart)/(mixed and .45 or .5))
                    local hovering=boxHeight+1.1
                    local approach=smooth((t-(2.55+(entry.index-1)*(mixed and .09 or .08)))/(mixed and .6 or .9))
                    local incoming=hovering+math.max(mixed and 18 or 30,entry.size.Y*(mixed and 3 or 5))*(1-approach)
                    local bottom=incoming+(.28-incoming)*lowering
                    local floating=mixed and approach*(1-lowering) or 0
                    local side=entry.index%2==0 and 1 or -1
                    local position=Vector3.new(entry.x+floating*math.sin(t*1.7+entry.index)*.24,
                        bottom+entry.size.Y*.5+floating*math.sin(t*2+entry.index)*.1,
                        entry.z+floating*math.cos(t*1.4+entry.index)*.16)
                    local turn=isTreadmill and (math.pi+math.pi*2*smooth((t-2.75)/1.1))
                        or (entry.yaw+(1-lowering)*(mixed and math.sin(t*1.8+entry.index)*.22 or .16))
                    entry.model:PivotTo(parcel*CFrame.new(position)
                        *CFrame.Angles(floating*.035*side,turn,floating*math.sin(t+entry.index)*.045)*entry.correction)
                    end
                    local visible=t>=(2.55+(category=='Bundle' and (entry.index-1)*.09 or 0)) and 1 or 0
                    local alpha=math.max(1-visible,fade)
                    if entry.alpha~=alpha then
                        for _,object in ipairs(entry.parts) do object.LocalTransparencyModifier=alpha end
                        entry.alpha=alpha
                    end
                end
                if not parcelRig then glow.CFrame=parcel*CFrame.new(0,boxHeight*.7,0) end
                light.Brightness=glowAmount*1.5
                local portalAmount=smooth((t-.05)/.4)*(1-smooth((t-1.35)/.5))
                if portalAmount>.001 or portalWasVisible then
                for _,entry in ipairs(portal) do
                    local angle=entry.angle+t*(entry.band==1 and .8 or -.65)
                    local radius=portalRadius*entry.band*math.max(.05,portalAmount)*(1+.015*math.sin(t*5))
                    entry.part.CFrame=base*CFrame.new(math.cos(angle)*radius,portalHeight,math.sin(angle)*radius)
                        *CFrame.Angles(0,-angle,0)
                    entry.part.Transparency=1-portalAmount*.92
                end
                iris.CFrame=base*CFrame.new(0,portalHeight,0)*CFrame.Angles(0,0,math.pi*.5)
                iris.Transparency=1-portalAmount*.985
                sparks.Enabled=portalAmount>.15
                mist.Enabled=portalAmount>.15
                portalLight.Brightness=portalAmount*.3
                for _,entry in ipairs(portalStars) do
                    entry.part.CFrame=base*CFrame.new(entry.x,portalHeight-.15,entry.z)
                    entry.part.Transparency=1-portalAmount*(.32+.10*math.sin(t*1.5+entry.phase))
                end
                portalWasVisible=portalAmount>.001
                end
                local ufoArrival=smooth((t-6.6)/.35)
                local ufoExit=smooth((t-7.65)/.3)
                local ufoPosition=Vector3.new((1-ufoArrival)*saucerWidth*2+ufoExit*saucerWidth*.6,
                    pickupHeight+(1-ufoArrival)*8+ufoExit*24,0)
                local ufoFrame=base*CFrame.new(ufoPosition)
                local ufoVisibility=smooth((t-6.6)/.25)*(1-smooth((t-7.9)/.1))
                if ufoVisibility>.001 or ufoWasVisible then
                for _,entry in ipairs(ufoParts) do
                    entry.part.CFrame=ufoFrame*entry.offset
                    entry.part.Transparency=1-ufoVisibility
                end
                ufoWasVisible=ufoVisibility>.001
                end
                beamTop.CFrame=ufoFrame*CFrame.new(0,-.85,0)
                beamBottom.CFrame=base*CFrame.new(0,.2,0)
                local beamAmount=smooth((t-6.95)/.15)*(1-smooth((t-7.63)/.1))
                tractor.Enabled=beamAmount>.01
                tractor.Width1=(math.max(boxWidth,boxDepth)+2)*math.max(.15,beamAmount)
                tractorLight.Brightness=beamAmount*1.1
                local sealed=t>=4.95
                local labeled=t>=4.85
                tape.Transparency=sealed and 0 or 1
                local tapeLength=math.max(.01,(boxDepth+.08)*smooth((t-4.95)/.25))
                if not parcelRig then
                    tape.Size=Vector3.new(1.25,.06,tapeLength)
                    tape.CFrame=parcel*CFrame.new(0,boxHeight+.07,-halfDepth-.04+tapeLength*.5)
                end
                sticker.Transparency=labeled and 0 or 1
                if shipping.Enabled~=labeled then shipping.Enabled=labeled end
                local slap=1-smooth((t-4.85)/.25)
                if not parcelRig then
                    sticker.CFrame=parcel*CFrame.new(0,boxHeight*.38,-halfDepth-.24-slap*1.1)
                        *CFrame.Angles(0,0,slap*-.12)
                end
                local parcelCenter=(parcel*CFrame.new(0,boxHeight*.5,0)).Position
                local aspect=camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y)
                -- Ground-level camera tracks the fall. Widen first; close in only after landing.
                local arrivalZoom=smooth((t-.25)/.4)
                local arrivalDistance=math.max(25,boxWidth*2.8)*math.max(1,.9/math.max(.45,aspect))
                    *(1+.18*arrivalZoom)
                itemBadge.Transparency=1
                if badgeGui.Enabled~=labeled then badgeGui.Enabled=labeled end
                if not parcelRig then
                itemBadge.CFrame=parcel*CFrame.new(boxWidth*.28,boxHeight*.84,-halfDepth-.27-slap*.7)
                    *CFrame.Angles(0,0,math.rad(9)-slap*.12)
                end
                fragile.Transparency=labeled and 0 or 1
                if fragileGui.Enabled~=labeled then fragileGui.Enabled=labeled end
                if not parcelRig then
                fragile.CFrame=parcel*CFrame.new(-boxWidth*.23,boxHeight*.84,-halfDepth-.28-slap*.7)
                    *CFrame.Angles(0,0,math.rad(-4)*slap)
                end
                if t>=5.3 and not parcelRig then
                    -- One transform moves the sealed package and every attached label in lockstep.
                    parcelRig=Instance.new('Model') parcelRig.Name='SealedParcel' parcelRig.Parent=scene
                    for _,entry in ipairs(pieces) do entry.part.Parent=parcelRig end
                    for _,entry in ipairs(flaps) do entry.part.Parent=parcelRig end
                    for _,entry in ipairs(contents) do entry.model.Parent=parcelRig end
                    sticker.Parent=parcelRig itemBadge.Parent=parcelRig fragile.Parent=parcelRig glow.Parent=parcelRig
                    parcelRig.WorldPivot=parcel
                    for _,part in ipairs(parcelRig:GetDescendants()) do
                        if part:IsA('BasePart') then
                            rigidParts[#rigidParts+1]=part
                            rigidOffsets[#rigidOffsets+1]=parcel:ToObjectSpace(part.CFrame)
                        end
                    end
                end
                local arrivalFocus=parcelCenter+Vector3.new(0,2*(1-flight),0)
                local arrival=CFrame.lookAt(floor+base.LookVector*arrivalDistance
                    +base.RightVector*(boxWidth*.25)+Vector3.new(0,3,0),arrivalFocus)
                local revealTarget=(boxHeight+1.1+itemBounds.Y*.5)*(1-placement)+(.28+itemBounds.Y*.5)*placement
                local framing=math.max(boxWidth,boxDepth)*1.18*math.max(1,.95/math.max(.45,aspect))
                local revealShot=CFrame.lookAt(floor+base.LookVector*(framing*.60)
                    +Vector3.new(.25,revealTarget+framing*1.15,0),floor+Vector3.new(0,revealTarget,0))
                -- Return to the original front label, viewed from a raised three-quarter angle.
                local labelWide=frameParcel(base,floor,boxWidth,boxHeight,boxDepth,aspect,48)
                local labelBase=base*CFrame.new(0,boxHeight*.38-labelHeight*.5,-halfDepth-.13)
                local labelClose=frameParcel(labelBase,labelBase.Position,labelWidth,labelHeight,.06,aspect,48)
                -- Read the avatar and username, then return to the full parcel before collection.
                local portraitZoom=smooth((t-5.15)/.35)*(1-smooth((t-6.2)/.45))
                local labelShot=labelWide:Lerp(labelClose,portraitZoom)
                local shot=arrival:Lerp(revealShot,smooth((t-2.3)/.55))
                if category=='Bundle' then
                    -- A complete camera orbit shows the independently floating and packing items.
                    local orbit=smooth((t-2.9)/1.8)*math.pi*2
                    local lowering=smooth((t-3.25)/1.13)
                    local displayHeight=boxHeight+(1-lowering)*(1.4+itemBounds.Y)
                    local mixedShot=frameParcel(base,floor,boxWidth,displayHeight,boxDepth,aspect,48,orbit)
                    local blend=smooth((t-2.7)/.2)*(1-smooth((t-4.7)/.15))
                    shot=shot:Lerp(mixedShot,blend)
                end
                if category=='Pets' then
                    -- A close tracking shot makes the enlarged front pet clearly readable.
                    local lowering=smooth((t-(3.55+(request.quantity-1)*.12))/.5)
                    local petBottom=(boxHeight+1.1)+(.28-boxHeight-1.1)*lowering
                    local petFocus=floor+base.LookVector*(slotDepth*.5)+Vector3.new(0,petBottom+itemBounds.Y*.5,0)
                    local petView=math.max(itemBounds.X,itemBounds.Y,itemBounds.Z)
                        *math.max(1,1/math.max(.45,aspect))
                    local petShot=CFrame.lookAt(petFocus+base.LookVector*(petView*.95)
                        +Vector3.new(petView*.08,petView*1.8,0),petFocus)
                    local petZoom=smooth((t-3.05)/.25)*(1-smooth((t-4.25)/.3))
                    shot=shot:Lerp(petShot,petZoom)
                end
                shot=shot:Lerp(labelShot,smooth((t-(category=='Bundle' and 4.75 or 4.5))/(category=='Bundle' and .35 or .55)))
                -- Pull back to show the whole saucer and its beam from the ground.
                local exitFocus=floor+Vector3.new(0,pickupHeight*.55+ufoExit*10,0)
                local exitDistance=math.max(saucerWidth*2.5,pickupHeight*1.7)
                    *math.max(1,.95/math.max(.45,aspect))
                local exitShot=CFrame.lookAt(floor+base.LookVector*exitDistance
                    +base.RightVector*(boxWidth*.35)+Vector3.new(0,pickupHeight+7,0),exitFocus)
                shot=shot:Lerp(exitShot,smooth((t-6.8)/.3))
                camera.CFrame=sequenceStart:Lerp(shot,smooth((t-previewDuration)/.45))
                local fov=62+4*arrivalZoom-18*smooth((t-2.3)/.6)+12*smooth((t-6.8)/.3)
                camera.FieldOfView=state.fov+(fov-state.fov)*smooth(t/.35)
                local focus=t<2.3 and arrivalFocus or (t>=6.8 and exitFocus or floor+Vector3.new(0,boxHeight*.65,0))
                camera.Focus=CFrame.new(focus)
                if t>7.75 then
                    local back=smooth((t-7.75)/.25)
                    camera.CFrame=camera.CFrame:Lerp(state.cframe,back)
                    camera.FieldOfView=fov+(state.fov-fov)*back
                end
                clearView(state,scene,character,treadmill,{
                    focus,parcelCenter,
                    parcelCenter+base.RightVector*halfWidth,
                    parcelCenter-base.RightVector*halfWidth
                })
                if t>=7.7 and not dispatched then dispatched=true; dispatchCaption() end
                if t>=8 then cleanup(state) end
            end,debug.traceback)
            if not ok then state.error=err; cleanup(state) end
        end)
        state.finished.Event:Wait()
        state.finished:Destroy()
        runtime.active=nil
        if state.error then error(state.error) end
    end
    E.SAE_PACKAGE_DELIVERY=function(cmd,item,recipient,quantity,userId,onError)
        if runtime.dead then return false end
        runtime.queue[#runtime.queue+1]={cmd=cmd,item=item,recipient=recipient,
            quantity=(cmd=='/givetreadmill' or cmd=='/giveeverything') and 1 or 3,userId=userId,onError=onError,generation=runtime.generation}
        if runtime.working then return true end
        runtime.working=true
        task.spawn(function()
            while #runtime.queue>0 and not runtime.dead do
                local request=table.remove(runtime.queue,1)
                local ok,err=xpcall(function() play(request) end,debug.traceback)
                if not ok then
                    if runtime.active then
                        local state=runtime.active cleanup(state)
                        if state.finished then state.finished:Destroy() end
                        runtime.active=nil
                    end
                    warn('[SAE] Parcel animation: '..tostring(err))
                    if request.onError then pcall(request.onError,tostring(err)) end
                end
            end
            runtime.working=false
        end)
        return true
    end
end

local function weld(t,m,off)m.Parent=t m:PivotTo(t.Handle.CFrame*off)if m:GetAttribute('SAE_REFERENCE_DETAIL') and m.PrimaryPart then local w=Instance.new('WeldConstraint')w.Part0=t.Handle w.Part1=m.PrimaryPart w.Parent=t.Handle else for _,p in ipairs(allParts(m))do p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true local w=Instance.new('WeldConstraint')w.Part0=t.Handle w.Part1=p w.Parent=t.Handle end end end
local function createTreadmillRuntime()
    local previous=E.SAE_TREADMILL_RUNTIME
    if previous and type(previous.Destroy)=='function' then pcall(function() previous:Destroy() end) end
    local api={}
    local entries,connections,tracks={},{},setmetatable({},{__mode='k'})
    local popups={}
    local popupSerial=0
    local popupClock=0
    local active=nil
    local dismounted=nil
    local cooldown=0
    local dead=false
    local UIS=game:GetService('UserInputService')
    local Run=game:GetService('RunService')
    local function connect(signal,fn)
        local c=signal:Connect(fn)
        connections[#connections+1]=c
        return c
    end
    local stale=PG:FindFirstChild('SAE_TREADMILL_RUNNING')
    if stale then stale:Destroy() end

    local function stopRunning(jump)
        local state=active
        if not state then return end
        active=nil cooldown=os.clock()+.6
        if jump then dismounted=state.entry.model end
        if state.track then pcall(function() state.track:Stop(.18) end) end
        if state.headphones then state.headphones:Destroy() end
        if state.aura then state.aura:Destroy() end
        for _,popup in ipairs(popups) do popup.started=nil popup.gui.Enabled=false end
        for joint,original in pairs(state.joints or {}) do
            if joint.Parent then joint.Transform=original end
        end
        if state.root.Parent then
            state.root.Anchored=state.anchored
            state.root.AssemblyLinearVelocity=Vector3.zero
            state.root.AssemblyAngularVelocity=Vector3.zero
        end
        if state.humanoid.Parent then
            state.humanoid.WalkSpeed=state.speed
            state.humanoid.AutoRotate=state.rotate
            if jump then state.humanoid.Jump=true end
        end
    end

    local function headphones(character,color)
        local head=character:FindFirstChild('Head')
        if not head then return nil end
        local old=character:FindFirstChild('SAE_TREADMILL_HEADPHONES')
        if old then old:Destroy() end
        local model=Instance.new('Model') model.Name='SAE_TREADMILL_HEADPHONES'
        model.Parent=character
        local function piece(name,size,col,cf,rounded,material)
            local p=part(model,name,size,col,head.CFrame*cf,material or MAT)
            if rounded then
                local mesh=Instance.new('SpecialMesh') mesh.MeshType=Enum.MeshType.Sphere mesh.Parent=p
            end
            local weld=Instance.new('WeldConstraint') weld.Part0=head weld.Part1=p weld.Parent=p
            return p
        end
        local rx=head.Size.X*.5+.22
        local ry=head.Size.Y*.5+.32
        for i=0,9 do
            local a=-math.pi/2+i*math.pi/10
            local b=-math.pi/2+(i+1)*math.pi/10
            local p=Vector3.new(math.sin(a)*rx,.04+math.cos(a)*ry,0)
            local q=Vector3.new(math.sin(b)*rx,.04+math.cos(b)*ry,0)
            piece('PaddedHeadband',Vector3.new(.14,.18,(q-p).Magnitude+.04),rgb(244,247,250),CFrame.lookAt((p+q)*.5,q))
        end
        for _,side in ipairs({-1,1}) do
            piece('EarCushion',Vector3.new(.24,.61,.54),rgb(19,24,33),CFrame.new(side*rx,-.06,0),true)
            piece('HeadphoneShell',Vector3.new(.22,.65,.59),rgb(243,246,250),CFrame.new(side*(rx+.16),-.06,0),true)
            piece('HeadphoneAccent',Vector3.new(.08,.46,.43),color,CFrame.new(side*(rx+.28),-.06,0),true)
            piece('HeadphoneLight',Vector3.new(.035,.23,.09),color,CFrame.new(side*(rx+.33),-.06,.02),true,NEON)
        end
        return model
    end

    local function runTrack(character,humanoid)
        local cached=tracks[humanoid]
        if cached then return cached end
        local animate=character:FindFirstChild('Animate')
        local animation=nil
        local function usable(value)
            return value and value:IsA('Animation') and value.AnimationId:match('%d+')~=nil
        end
        if animate then
            for _,name in ipairs({'run','Run','walk','Walk'}) do
                local group=animate:FindFirstChild(name)
                local candidate=group and group:FindFirstChildWhichIsA('Animation',true)
                if usable(candidate) then animation=candidate break end
            end
        end
        if not animation then
            for _,v in ipairs(character:GetDescendants()) do
                if usable(v) and (v.Name:lower():find('run',1,true) or v.Name:lower():find('walk',1,true)) then
                    animation=v break
                end
            end
        end
        local animator=humanoid:FindFirstChildOfClass('Animator')
        if not animator or not animation or animation.AnimationId=='' then return nil end
        local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
        if not ok then return nil end
        track.Looped=true track.Priority=Enum.AnimationPriority.Action
        tracks[humanoid]=track
        return track
    end

    -- Keep a playable run asset outside Animate before the delivery strips scripts.
    function api:PreparePreview(character,humanoid)
        local animation=nil
        local function choose(source)
            if animation or not source then return end
            local animate=source:FindFirstChild('Animate')
            if animate then
                for _,name in ipairs({'run','Run','walk','Walk'}) do
                    local group=animate:FindFirstChild(name)
                    local candidate=group and group:FindFirstChildWhichIsA('Animation',true)
                    if candidate and candidate.AnimationId:match('%d+') then animation=candidate:Clone(); return end
                end
            end
            for _,candidate in ipairs(source:GetDescendants()) do
                if candidate:IsA('Animation') and candidate.AnimationId:match('%d+')
                    and (candidate.Name:lower():find('run',1,true) or candidate.Name:lower():find('walk',1,true)) then
                    animation=candidate:Clone(); return
                end
            end
        end
        local sender=P.Character
        local senderHumanoid=sender and sender:FindFirstChildOfClass('Humanoid')
        -- Prefer the same running cycle seen on the real treadmill when the rigs match.
        if senderHumanoid and senderHumanoid.RigType==humanoid.RigType then choose(sender) end
        choose(character)
        if not animation then
            animation=Instance.new('Animation')
            local id=0
            if humanoid.RigType~=Enum.HumanoidRigType.R6 then
                local ok,description=pcall(function() return humanoid:GetAppliedDescription() end)
                if ok and description then id=description.RunAnimation or 0; description:Destroy() end
            end
            if id<=0 then id=humanoid.RigType==Enum.HumanoidRigType.R6 and 180426354 or 507767714 end
            animation.AnimationId='rbxassetid://'..id
        end
        animation.Name='SAE_DeliveryRun' animation.Parent=character
        if not humanoid:FindFirstChildOfClass('Animator') then
            local animator=Instance.new('Animator') animator.Parent=humanoid
        end
    end

    -- Pooled visual step gains. These never write to the game's stats.
    local function makeStepPopup()
        local gui=Instance.new('BillboardGui')
        gui.Name='SAE_TREADMILL_STEP_POPUP' gui.Size=UDim2.fromOffset(188,66)
        gui.AlwaysOnTop=true gui.LightInfluence=0 gui.MaxDistance=85 gui.Enabled=false gui.Parent=PG
        local canvas=Instance.new('Frame')
        canvas.AnchorPoint=Vector2.new(.5,.5) canvas.Position=UDim2.fromScale(.5,.5)
        canvas.Size=UDim2.fromScale(1,1) canvas.BackgroundTransparency=1 canvas.Parent=gui
        local scale=Instance.new('UIScale') scale.Parent=canvas
        local fade={}
        local icon=Instance.new('ImageLabel')
        icon.Name='ReferenceShoeIcon'
        icon.Size=UDim2.fromOffset(46,46) icon.Position=UDim2.fromOffset(0,10)
        icon.BackgroundTransparency=1 icon.ScaleType=Enum.ScaleType.Fit
        icon.Image=E.SAE_STEP_ICON_ASSET or '' icon.ZIndex=2 icon.Parent=canvas
        fade[#fade+1]={object=icon,property='ImageTransparency',base=0}
        local halo=Instance.new('ImageLabel')
        halo.BackgroundTransparency=1 halo.Image='rbxasset://textures/glow.png'
        halo.Position=UDim2.fromOffset(43,3) halo.Size=UDim2.fromOffset(143,60)
        halo.ImageTransparency=.94 halo.ZIndex=1 halo.Parent=canvas
        fade[#fade+1]={object=halo,property='ImageTransparency',base=.94}
        local number=Instance.new('TextLabel')
        number.Position=UDim2.fromOffset(48,0) number.Size=UDim2.fromOffset(140,66)
        number.BackgroundTransparency=1 number.Font=Enum.Font.FredokaOne number.TextSize=41
        number.Text='+10B' number.TextXAlignment=Enum.TextXAlignment.Left
        number.TextColor3=rgb(195,49,55) number.TextStrokeColor3=rgb(15,20,28)
        number.TextStrokeTransparency=0 number.ZIndex=2 number.Parent=canvas
        local shading=Instance.new('UIGradient')
        shading.Color=ColorSequence.new(rgb(255,255,255),rgb(196,202,198))
        shading.Rotation=90 shading.Parent=number
        local edge=Instance.new('UIStroke') edge.Color=rgb(15,20,28) edge.Thickness=1.6 edge.Parent=number
        fade[#fade+1]={object=number,property='TextTransparency',base=0}
        fade[#fade+1]={object=number,property='TextStrokeTransparency',base=0}
        fade[#fade+1]={object=edge,property='Transparency',base=0}
        return {gui=gui,scale=scale,number=number,icon=icon,halo=halo,fade=fade}
    end
    local function emitStep(state,now)
        if #popups<6 then popups[#popups+1]=makeStepPopup() end
        popupSerial+=1
        local popup=popups[(popupSerial-1)%#popups+1]
        local side=popupSerial%2==0 and 1 or -1
        popup.started=now popup.x=side*(.45+(popupSerial%3)*.33)
        popup.drift=side*.50 popup.y=.15+(popupSerial%3)*.22
        popup.gui.Adornee=state.character:FindFirstChild('Head') or state.root
        popup.number.TextColor3=state.entry.rewardColor
        popup.halo.ImageColor3=state.entry.rewardColor
        popup.icon.Image=E.SAE_STEP_ICON_ASSET or popup.icon.Image
        popup.scale.Scale=.66
        popup.gui.StudsOffset=Vector3.new(popup.x,popup.y,0)
        for _,item in ipairs(popup.fade) do item.object[item.property]=item.base end
        popup.gui.Enabled=true
    end
    local function updateSteps(now)
        if E.SAE_PACKAGE_RUNTIME and E.SAE_PACKAGE_RUNTIME.active then
            for _,popup in ipairs(popups) do popup.started=nil popup.gui.Enabled=false end
            return
        end
        for _,popup in ipairs(popups) do
            if popup.started then
                local t=(now-popup.started)/1.15
                if t>=1 then popup.started=nil popup.gui.Enabled=false
                else
                    local fade=math.clamp((t-.52)/.48,0,1)
                    local settle=math.min(1,t/.17)
                    popup.scale.Scale=.66+.42*math.sin(settle*math.pi/2)-.10*t
                    popup.gui.StudsOffset=Vector3.new(popup.x+popup.drift*t,popup.y+t*2.85,0)
                    for _,item in ipairs(popup.fade) do
                        item.object[item.property]=item.base+(1-item.base)*fade
                    end
                end
            end
        end
    end
    local function runningAura(root,standing,color)
        local attachment=Instance.new('Attachment')
        attachment.Name='SAE_RUNNING_STEP_AURA' attachment.Position=Vector3.new(0,-standing+.12,0)
        attachment.Parent=root
        local emitter=Instance.new('ParticleEmitter')
        emitter.Texture='rbxasset://textures/particles/sparkles_main.dds'
        emitter.Color=ColorSequence.new(color,color:Lerp(rgb(255,255,255),.70))
        emitter.LightEmission=.65 emitter.LightInfluence=0 emitter.Rate=7
        emitter.Lifetime=NumberRange.new(.5,.9) emitter.Speed=NumberRange.new(.7,1.5)
        emitter.SpreadAngle=Vector2.new(65,65) emitter.EmissionDirection=Enum.NormalId.Top
        emitter.Acceleration=Vector3.new(0,.5,0) emitter.Drag=.6
        emitter.Size=NumberSequence.new({
            NumberSequenceKeypoint.new(0,.03),NumberSequenceKeypoint.new(.25,.19),NumberSequenceKeypoint.new(1,0)})
        emitter.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.10),NumberSequenceKeypoint.new(1,1)})
        emitter.Parent=attachment
        return attachment
    end

    local function startRunning(entry,character,humanoid,root)
        if active or humanoid.Health<=0 or root.Anchored then return end
        local scale=entry.model:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
        local leg=humanoid.RigType==Enum.HumanoidRigType.R6 and character:FindFirstChild('Left Leg')
        local standing=humanoid.HipHeight+root.Size.Y*.5+(leg and leg.Size.Y or 0)
        local cf=entry.model:GetPivot()
        local position=(cf*CFrame.new(0,.49*scale+standing,.40*scale)).Position
        local toward=(cf*CFrame.new(0,.49*scale+standing,-3*scale)).Position
        local state={
            entry=entry,character=character,humanoid=humanoid,root=root,
            anchored=root.Anchored,speed=humanoid.WalkSpeed,rotate=humanoid.AutoRotate,
            started=os.clock(),joints={},
        }
        for _,joint in ipairs(character:GetDescendants()) do
            if joint:IsA('Motor6D') then
                local name=joint.Name:lower():gsub('%s','')
                if name:find('shoulder',1,true) or name:find('hip',1,true) or
                    name:find('knee',1,true) or name:find('elbow',1,true) then
                    state.joints[joint]=joint.Transform
                end
            end
        end
        active=state
        humanoid.WalkSpeed=0 humanoid.AutoRotate=false
        root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
        root.CFrame=CFrame.lookAt(position,toward)
        root.Anchored=true
        popupClock=0
        state.headphones=headphones(character,entry.color)
        state.aura=runningAura(root,standing,entry.rewardColor)
        state.track=runTrack(character,humanoid)
        if active~=state then return end
        if state.track then pcall(function() state.track:Play(.18,1,1.35) end) end
    end

    function api:Watch(model)
        if dead or entries[model] or not model:GetAttribute('SAE_TREADMILL') then return end
        local belt=model:FindFirstChild('RunningBelt',true)
        if not belt then return end
        local old=belt:FindFirstChild('SAE_MOVING_BELT_ARROWS')
        if old then old:Destroy() end
        local oldPlane=model:FindFirstChild('SAE_TREADMILL_ARROW_SURFACE')
        if oldPlane then oldPlane:Destroy() end
        local scale=model:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
        local plane=part(model,'SAE_TREADMILL_ARROW_SURFACE',
            Vector3.new(belt.Size.X*.98,belt.Size.Z*.98,.01),rgb(0,0,0),
            belt.CFrame*CFrame.new(0,belt.Size.Y*.5+.115*scale,0)*CFrame.Angles(math.pi/2,0,0),MAT,1)
        plane.CastShadow=false
        plane.Anchored=model:GetAttribute('SAE_PLACED_TREADMILL')==true
        if not plane.Anchored then
            local weld=Instance.new('WeldConstraint') weld.Part0=model.PrimaryPart weld.Part1=plane weld.Parent=plane
        end
        local color=model.Name=="Brocodile's Treadmill" and rgb(139,255,38) or rgb(35,230,255)
        local surface=Instance.new('SurfaceGui')
        surface.Name='SAE_MOVING_BELT_ARROWS' surface.Adornee=plane surface.Face=Enum.NormalId.Front
        surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize surface.CanvasSize=Vector2.new(512,1024)
        surface.AlwaysOnTop=false surface.LightInfluence=0 surface.Brightness=1.6
        surface.MaxDistance=110 surface.ZOffset=.025 surface.Parent=plane
        local canvas=Instance.new('Frame')
        canvas.Size=UDim2.fromScale(1,1) canvas.BackgroundTransparency=1 canvas.ClipsDescendants=true canvas.Parent=surface
        local entry={model=model,belt=belt,plane=plane,surface=surface,rows={},sparks={},gradients={},emitters={},color=color,
            rewardColor=model.Name=="Brocodile's Treadmill" and rgb(31,171,68) or rgb(195,49,55)}
        for i=1,4 do
            local row=Instance.new('Frame')
            row.AnchorPoint=Vector2.new(.5,.5) row.Size=UDim2.fromScale(1,.15)
            row.BackgroundTransparency=1 row.Parent=canvas
            local pieces={}
            for _,side in ipairs({-1,1}) do
                for layer=1,4 do
                    local arm=Instance.new('Frame')
                    arm.AnchorPoint=Vector2.new(.5,.5)
                    arm.Position=UDim2.fromScale(.5+side*.218,.50)
                    arm.Size=UDim2.fromScale(.47,({.86,.53,.28,.13})[layer])
                    arm.Rotation=side*22 arm.BorderSizePixel=0
                    arm.BackgroundColor3=layer>=3 and rgb(255,255,255) or color
                    arm.BackgroundTransparency=({.94,.77,.10,.035})[layer]
                    arm.ZIndex=layer arm.Parent=row
                    local corner=Instance.new('UICorner') corner.CornerRadius=UDim.new(1,0) corner.Parent=arm
                    if layer>=3 then
                        local gradient=Instance.new('UIGradient')
                        local base=layer==4 and color:Lerp(rgb(255,255,255),.68) or color
                        gradient.Color=ColorSequence.new({
                            ColorSequenceKeypoint.new(0,base),
                            ColorSequenceKeypoint.new(.38,base),
                            ColorSequenceKeypoint.new(.50,rgb(255,255,255)),
                            ColorSequenceKeypoint.new(.62,base),
                            ColorSequenceKeypoint.new(1,base)})
                        gradient.Parent=arm
                        entry.gradients[#entry.gradients+1]=gradient
                    end
                    pieces[#pieces+1]={frame=arm,alpha=arm.BackgroundTransparency}
                end
            end
            entry.rows[#entry.rows+1]={frame=row,pieces=pieces}
        end
        for i=1,10 do
            local star=Instance.new('ImageLabel')
            star.BackgroundTransparency=1 star.Image='rbxasset://textures/particles/sparkles_main.dds'
            star.ImageColor3=rgb(222,255,255) star.AnchorPoint=Vector2.new(.5,.5)
            star.Size=UDim2.fromOffset(32,32) star.ZIndex=4 star.Parent=canvas
            entry.sparks[#entry.sparks+1]=star
        end
        -- Small world-space glints float above the belt edges.
        for _,side in ipairs({-1,1}) do
            for _,endSide in ipairs({-1,1}) do
                local attachment=Instance.new('Attachment')
                attachment.Position=Vector3.new(side*plane.Size.X*.43,endSide*plane.Size.Y*.30,-.035)
                attachment.Parent=plane
                local emitter=Instance.new('ParticleEmitter')
                emitter.Name='BeltEdgeTwinkle'
                emitter.Texture='rbxasset://textures/particles/sparkles_main.dds'
                emitter.Color=ColorSequence.new(color:Lerp(rgb(255,255,255),.70))
                emitter.LightEmission=1 emitter.LightInfluence=0
                emitter.Rate=3 emitter.Lifetime=NumberRange.new(.45,.95)
                emitter.Speed=NumberRange.new(.18,.48) emitter.Drag=1
                emitter.EmissionDirection=Enum.NormalId.Front
                emitter.SpreadAngle=Vector2.new(18,18)
                emitter.Size=NumberSequence.new({
                    NumberSequenceKeypoint.new(0,.035*scale),
                    NumberSequenceKeypoint.new(.25,.19*scale),
                    NumberSequenceKeypoint.new(1,0)})
                emitter.Transparency=NumberSequence.new({
                    NumberSequenceKeypoint.new(0,1),
                    NumberSequenceKeypoint.new(.18,.10),
                    NumberSequenceKeypoint.new(.68,.32),
                    NumberSequenceKeypoint.new(1,1)})
                emitter.Rotation=NumberRange.new(-20,20)
                emitter.RotSpeed=NumberRange.new(-18,18)
                emitter.Parent=attachment
                entry.emitters[#entry.emitters+1]=emitter
            end
        end
        entries[model]=entry
        if model:GetAttribute('SAE_PLACED_TREADMILL') then
            belt.CanCollide=true belt.CanQuery=true
            local ramp=model:FindFirstChild('SAE_TREADMILL_ENTRY_RAMP')
            if not ramp then
                local scale=model:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
                ramp=Instance.new('WedgePart') ramp.Name='SAE_TREADMILL_ENTRY_RAMP'
                ramp.Size=Vector3.new(4.05,1.31,1.65)*scale
                ramp.CFrame=model:GetPivot()*CFrame.new(0,-.165*scale,5.48*scale)*CFrame.Angles(0,math.pi,0)
                ramp.Anchored=true ramp.CanCollide=true ramp.CanTouch=false ramp.CanQuery=true
                ramp.Transparency=1 ramp.CastShadow=false ramp.Parent=model
            end
        end
    end

    local function watchFolder(folder)
        if not folder:IsA('Folder') or folder.Name~='SAE_V7_PLACED' then return end
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA('Model') then api:Watch(model) end
        end
        connect(folder.ChildAdded,function(model) if model:IsA('Model') then api:Watch(model) end end)
    end
    for _,folder in ipairs(workspace:GetChildren()) do watchFolder(folder) end
    connect(workspace.ChildAdded,watchFolder)
    connect(UIS.JumpRequest,function() if active then stopRunning(true) end end)
    connect(P.CharacterRemoving,function() stopRunning(false) end)
    local function poseRunner(state,now)
        if state.track and state.track.IsPlaying and state.track.Length>0 then return end
        -- R6/R15 fallback when the experience does not expose a run Animation.
        local phase=(now-state.started)*10
        for joint in pairs(state.joints) do
            if joint.Parent then
                local name=joint.Name:lower()
                local side=name:find('left',1,true) and 1 or -1
                local swing=math.sin(phase)*side
                if name:find('shoulder',1,true) then
                    joint.Transform=CFrame.Angles(math.rad(-18)+swing*.72,0,0)
                elseif name:find('hip',1,true) then
                    joint.Transform=CFrame.Angles(-swing*.90,0,0)
                elseif name:find('knee',1,true) then
                    joint.Transform=CFrame.Angles(math.max(0,swing)*1.05,0,0)
                elseif name:find('elbow',1,true) then
                    joint.Transform=CFrame.Angles(-.65,0,0)
                end
            end
        end
    end
    connect(Run.PreSimulation,function()
        if active then poseRunner(active,os.clock()) end
    end)
    -- Isolated delivery previews share the normal treadmill's run track and fallback gait.
    function api:StartPreview(character,humanoid,machine,belt)
        local state={started=os.clock(),joints={},track=runTrack(character,humanoid)}
        for _,joint in ipairs(character:GetDescendants()) do
            if joint:IsA('Motor6D') then state.joints[joint]=joint.Transform end
        end
        if state.track then pcall(function() state.track:Play(.18,1,1.35) end) end
        local marks={}
        for index=1,9 do
            local mark=Instance.new('Part')
            mark.Name='PreviewBeltTread' mark.Size=Vector3.new(belt.Size.X*.87,.016,.055)
            mark.Color=rgb(82,92,92) mark.Material=MAT
            mark.Anchored=true mark.CanCollide=false mark.CanTouch=false mark.CanQuery=false
            mark.Parent=machine marks[#marks+1]=mark
        end
        local connection=Run.PreSimulation:Connect(function()
            if not character.Parent or not machine.Parent then return end
            local now=os.clock()
            poseRunner(state,now)
            for index,mark in ipairs(marks) do
                local phase=((now-state.started)*.9+index/#marks)%1
                mark.CFrame=belt.CFrame*CFrame.new(0,belt.Size.Y*.5+.018,(phase-.5)*belt.Size.Z*.94)
            end
        end)
        local stopped=false
        return function()
            if stopped then return end stopped=true
            connection:Disconnect()
            if state.track then
                pcall(function() state.track:Stop(0); state.track:Destroy() end)
                tracks[humanoid]=nil
            end
            for joint,transform in pairs(state.joints) do if joint.Parent then joint.Transform=transform end end
            for _,mark in ipairs(marks) do mark:Destroy() end
        end
    end
    local sample=0
    connect(Run.Heartbeat,function(dt)
        if dead then return end
        local character=P.Character
        local root=character and character:FindFirstChild('HumanoidRootPart')
        local humanoid=character and character:FindFirstChildOfClass('Humanoid')
        local now=os.clock()
        for model,entry in pairs(entries) do
            if not model.Parent or not entry.belt.Parent then
                if active and active.entry==entry then stopRunning(false) end
                entries[model]=nil
            else
                local visible=not (E.SAE_PACKAGE_RUNTIME and E.SAE_PACKAGE_RUNTIME.active)
                    and root and (entry.belt.Position-root.Position).Magnitude<110
                entry.surface.Enabled=not not visible
                if entry.visible~=visible then
                    entry.visible=visible
                    for _,emitter in ipairs(entry.emitters) do emitter.Enabled=not not visible end
                end
                if visible then
                    for i,row in ipairs(entry.rows) do
                        local p=(now*.38+(i-1)/4)%1
                        -- Front face: decreasing canvas Y maps to the belt's +Z end.
                        row.frame.Position=UDim2.fromScale(.5,1-p)
                        local fade=1-math.min(1,p/.10,(1-p)/.10)
                        for _,piece in ipairs(row.pieces) do
                            piece.frame.BackgroundTransparency=piece.alpha+(1-piece.alpha)*fade
                        end
                    end
                    local sweep=Vector2.new(((now*.58)%1)*2.8-1.4,0)
                    for _,gradient in ipairs(entry.gradients) do gradient.Offset=sweep end
                    for i,spark in ipairs(entry.sparks) do
                        local phase=(now*.21+i*.137)%1
                        local pulse=math.max(0,math.sin(now*2.7+i*1.9))^3
                        local edge=math.min(1,phase/.12,(1-phase)/.12)
                        local size=18+pulse*23
                        spark.Position=UDim2.fromScale(.10+((i*37)%80)/100,1-phase)
                        spark.Size=UDim2.fromOffset(size,size)
                        spark.ImageTransparency=1-(.14+.80*pulse)*edge
                        spark.Rotation=math.sin(now*.7+i)*12
                    end
                end
            end
        end
        updateSteps(now)
        if active then
            if active.character~=character or not root or not humanoid or humanoid.Health<=0 or
                not active.entry.model.Parent or not active.root.Parent then stopRunning(false)
            else
                popupClock-=dt
                if popupClock<=0 and not (E.SAE_PACKAGE_RUNTIME and E.SAE_PACKAGE_RUNTIME.active) then
                    emitStep(active,now) popupClock=.22
                end
            end
            return
        end
        sample+=dt
        if sample<.10 then return end
        sample=0
        if now<cooldown or not root or not humanoid or humanoid.Health<=0 or humanoid.Sit or root.Anchored then return end
        if dismounted then
            if not dismounted.Parent then dismounted=nil
            else
                local p=dismounted:GetPivot():PointToObjectSpace(root.Position)
                local scale=dismounted:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
                if math.abs(p.X)>2.05*scale or p.Z<-3*scale or p.Z>4.6*scale then dismounted=nil end
            end
        end
        local leg=humanoid.RigType==Enum.HumanoidRigType.R6 and character:FindFirstChild('Left Leg')
        local standing=humanoid.HipHeight+root.Size.Y*.5+(leg and leg.Size.Y or 0)
        for model,entry in pairs(entries) do
            if model~=dismounted and model:GetAttribute('SAE_PLACED_TREADMILL') then
                local localPos=model:GetPivot():PointToObjectSpace(root.Position)
                local scale=model:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
                local beltY=.49*scale+standing
                if math.abs(localPos.X)<1.85*scale and localPos.Z>-2.8*scale and localPos.Z<4.25*scale
                    and math.abs(localPos.Y-beltY)<.85 and humanoid.FloorMaterial~=Enum.Material.Air then
                    startRunning(entry,character,humanoid,root)
                    break
                end
            end
        end
    end)
    function api:Destroy()
        if dead then return end
        dead=true stopRunning(false)
        for _,connection in ipairs(connections) do connection:Disconnect() end
        for _,entry in pairs(entries) do if entry.plane.Parent then entry.plane:Destroy() end end
        for _,track in pairs(tracks) do pcall(function() track:Stop(0); track:Destroy() end) end
        for _,popup in ipairs(popups) do popup.gui:Destroy() end
    end
    function api:GetActiveModel() return active and active.entry.model end
    E.SAE_TREADMILL_RUNTIME=api
    return api
end
local treadmillRuntime=createTreadmillRuntime()

local function placeTreadmill(t,m)
    local function reject(message)
        t.ToolTip=message
        local last=t:GetAttribute('SAE_LAST_PLACEMENT_NOTICE') or -10
        if os.clock()-last>2 then
            t:SetAttribute('SAE_LAST_PLACEMENT_NOTICE',os.clock())
            pcall(function()
                game:GetService('StarterGui'):SetCore('SendNotification',{
                    Title='Treadmill placement',Text=message,Duration=2})
            end)
        end
        return false
    end
    local character=P.Character
    local hrp=character and character:FindFirstChild('HumanoidRootPart')
    local mouse=P:GetMouse()
    if not hrp or not mouse or t.Parent~=character then return false end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character,Placed}
    params.IgnoreWater=true
    params.RespectCanCollide=true
    local function isFloor(hit)
        if not hit or hit.Normal.Y<.97 then return false end
        return hit.Instance==workspace.Terrain or
            (hit.Instance:IsA('BasePart') and hit.Instance.Anchored and hit.Instance.CanCollide)
    end
    -- Sky clicks have no valid hit and never fall back to mouse.Hit.
    local unit=mouse.UnitRay
    local hit=workspace:Raycast(unit.Origin,unit.Direction*180,params)
    if not isFloor(hit) or (hit.Position-hrp.Position).Magnitude>100 then
        return reject('Click a flat floor to place the treadmill.')
    end
    local look=m:GetPivot().LookVector
    look=Vector3.new(look.X,0,look.Z)
    if look.Magnitude<.05 then look=Vector3.new(hrp.CFrame.LookVector.X,0,hrp.CFrame.LookVector.Z) end
    if look.Magnitude<.05 then look=Vector3.new(0,0,-1) end
    local target=CFrame.lookAt(hit.Position,hit.Position+look.Unit)
    local scale=m:GetAttribute('SAE_TREADMILL_MODEL_SCALE') or 1
    -- All four feet need support at the same height: no ledges or suspended builds.
    for _,x in ipairs({-2.83,2.83}) do
        for _,z in ipairs({-4.20,4.20}) do
            local point=(target*CFrame.new(x*scale,0,z*scale)).Position
            local support=workspace:Raycast(point+Vector3.new(0,3,0),Vector3.new(0,-6,0),params)
            if not isFloor(support) or math.abs(support.Position.Y-hit.Position.Y)>.18 then
                return reject('Choose a flat floor with room under all four feet.')
            end
        end
    end
    -- Preserve the held build itself, including scale, detail and light attachments.
    local placed=m:Clone()
    stabilizeTreadmillShapes(placed)
    for _,p in ipairs(allParts(placed)) do
        p.Anchored=true
        p.CanCollide=false
        p.CanTouch=false
        p.CanQuery=false
    end
    placed:PivotTo(CFrame.new())
    local bounds,size=placed:GetBoundingBox()
    local bottom=bounds.Position.Y-size.Y*.5
    placed:PivotTo(target*CFrame.new(0,-bottom+.025,0))
    placed:SetAttribute('SAE_PLACED_TREADMILL',true)
    placed.Parent=Placed
    treadmillRuntime:Watch(placed)
    t:Destroy()
    return true
end
local function place(t,m)if m:GetAttribute('SAE_TREADMILL') then return placeTreadmill(t,m) end local c=m:Clone()for _,d in ipairs(c:GetDescendants())do if d:IsA('WeldConstraint')or d:IsA('Motor6D')then d:Destroy()end end c.Parent=Placed for _,p in ipairs(allParts(c))do p.Anchored=true p.CanCollide=false p.CanQuery=true end local mouse=P:GetMouse()local pos=mouse and mouse.Hit and mouse.Hit.Position local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')pos=pos or(hrp and(hrp.Position+hrp.CFrame.LookVector*9))or Vector3.zero local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={P.Character,Placed}local ray=workspace:Raycast(pos+Vector3.new(0,35,0),Vector3.new(0,-100,0),rp)if ray then pos=ray.Position end c:PivotTo(CFrame.new(pos))local cf,sz=c:GetBoundingBox()c:PivotTo(c:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.08,0))t:Destroy()end
local iconCache={}
local function imageContent(value)
    if type(value)~='string' then return nil end
    value=value:match('^%s*(.-)%s*$')
    if value=='' then return nil end
    if value:match('^%d+$')then return 'rbxassetid://'..value end
    if value:match('^rbxassetid://')or value:match('^rbxthumb://')or value:match('^rbxasset://')then return value end
    return nil
end
local function readItemImage(obj)
    if not obj then return nil end
    if obj:IsA('Tool')then local ok,v=pcall(function()return obj.TextureId end)if ok then local image=imageContent(v)if image then return image end end end
    for _,attribute in ipairs({'Icon','IconId','Image','ImageId','Thumbnail','ThumbnailId','TextureId'})do
        local ok,value=pcall(function()return obj:GetAttribute(attribute)end)
        if ok then local image=imageContent(value)if image then return image end end
    end
    local ok,assetId=pcall(function()return obj.SourceAssetId end)
    if ok and type(assetId)=='number'and assetId>0 then return 'rbxthumb://type=Asset&id='..tostring(assetId)..'&w=150&h=150'end
    for _,d in ipairs(obj:GetDescendants())do
        if d:IsA('Tool')then local image=imageContent(d.TextureId)if image then return image end
        elseif d:IsA('Decal')or d:IsA('Texture')then local image=imageContent(d.Texture)if image then return image end
        elseif d:IsA('MeshPart')then local image=imageContent(d.TextureID)if image then return image end
        elseif d:IsA('SpecialMesh')then local image=imageContent(d.TextureId)if image then return image end
        elseif d:IsA('SurfaceAppearance')then local image=imageContent(d.ColorMap)if image then return image end end
    end
    return nil
end
local function itemImage(cat,name)
    local key=cat..'|'..name
    if iconCache[key] then return iconCache[key] end
    local resolver=E.SAE_ITEM_ICON_RESOLVER
    if type(resolver)~='function' then return nil end
    local image=resolver(name)
    if image then iconCache[key]=image end
    return image
end
local function prepareSelectedItem(cat,name)
    task.spawn(function()
        pcall(function()
            itemImage(cat,name)
            local preview=model(cat,name)
            if preview then preview:Destroy() end
        end)
    end)
end
local spawnToastSerial=0
local function showInventoryToast(name)
    spawnToastSerial+=1
    local serial=spawnToastSerial
    local old=PG:FindFirstChild('SAE_ITEM_SPAWN_TOAST')
    if old then old:Destroy() end

    local TS=game:GetService('TweenService')
    local sg=Instance.new('ScreenGui')
    sg.Name='SAE_ITEM_SPAWN_TOAST'
    sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true
    sg.DisplayOrder=950
    sg.Parent=PG

    local shadow=Instance.new('Frame')
    shadow.AnchorPoint=Vector2.new(.5,1)
    shadow.Position=UDim2.new(.5,4,1,-156)
    shadow.Size=UDim2.fromOffset(396,64)
    shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
    shadow.BackgroundTransparency=.45
    shadow.BorderSizePixel=0
    shadow.Parent=sg
    local shadowCorner=Instance.new('UICorner')
    shadowCorner.CornerRadius=UDim.new(0,14)
    shadowCorner.Parent=shadow

    local frame=Instance.new('Frame')
    frame.AnchorPoint=Vector2.new(.5,1)
    frame.Position=UDim2.new(.5,0,1,-150)
    frame.Size=UDim2.fromOffset(396,64)
    frame.BackgroundColor3=Color3.fromRGB(76,238,52)
    frame.BackgroundTransparency=0
    frame.BorderSizePixel=0
    frame.Parent=sg

    local corner=Instance.new('UICorner')
    corner.CornerRadius=UDim.new(0,14)
    corner.Parent=frame

    local outline=Instance.new('UIStroke')
    outline.Color=Color3.fromRGB(16,16,20)
    outline.Thickness=4
    outline.Transparency=0
    outline.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    outline.Parent=frame

    local grad=Instance.new('UIGradient')
    grad.Rotation=0
    grad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(102,245,45)),
        ColorSequenceKeypoint.new(.55,Color3.fromRGB(38,229,105)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(27,213,221))
    })
    grad.Parent=frame

    local shine=Instance.new('Frame')
    shine.Size=UDim2.new(1,-12,0,18)
    shine.Position=UDim2.fromOffset(6,5)
    shine.BackgroundColor3=Color3.fromRGB(255,255,255)
    shine.BackgroundTransparency=.84
    shine.BorderSizePixel=0
    shine.Parent=frame
    local shineCorner=Instance.new('UICorner')
    shineCorner.CornerRadius=UDim.new(0,10)
    shineCorner.Parent=shine

    local badge=Instance.new('Frame')
    badge.AnchorPoint=Vector2.new(0,.5)
    badge.Position=UDim2.new(0,12,.5,0)
    badge.Size=UDim2.fromOffset(42,42)
    badge.BackgroundColor3=Color3.fromRGB(21,24,29)
    badge.BorderSizePixel=0
    badge.Parent=frame
    local badgeCorner=Instance.new('UICorner')
    badgeCorner.CornerRadius=UDim.new(1,0)
    badgeCorner.Parent=badge
    local badgeStroke=Instance.new('UIStroke')
    badgeStroke.Color=Color3.fromRGB(255,255,255)
    badgeStroke.Thickness=2
    badgeStroke.Transparency=.05
    badgeStroke.Parent=badge

    local check=Instance.new('TextLabel')
    check.BackgroundTransparency=1
    check.Size=UDim2.fromScale(1,1)
    check.Text='✓'
    check.TextColor3=Color3.fromRGB(255,255,255)
    check.TextStrokeColor3=Color3.fromRGB(0,0,0)
    check.TextStrokeTransparency=0
    check.Font=Enum.Font.FredokaOne
    check.TextSize=25
    check.Parent=badge

    local item=Instance.new('TextLabel')
    item.BackgroundTransparency=1
    item.Position=UDim2.fromOffset(66,5)
    item.Size=UDim2.new(1,-78,0,33)
    item.Text=name
    item.TextColor3=Color3.fromRGB(255,255,255)
    item.TextStrokeColor3=Color3.fromRGB(0,0,0)
    item.TextStrokeTransparency=0
    item.Font=Enum.Font.FredokaOne
    item.TextSize=21
    item.TextXAlignment=Enum.TextXAlignment.Left
    item.TextYAlignment=Enum.TextYAlignment.Bottom
    item.TextTruncate=Enum.TextTruncate.AtEnd
    item.Parent=frame

    local sub=Instance.new('TextLabel')
    sub.BackgroundTransparency=1
    sub.Position=UDim2.fromOffset(67,36)
    sub.Size=UDim2.new(1,-80,0,20)
    sub.Text='ADDED TO YOUR INVENTORY!'
    sub.TextColor3=Color3.fromRGB(255,255,255)
    sub.TextStrokeColor3=Color3.fromRGB(0,0,0)
    sub.TextStrokeTransparency=.08
    sub.Font=Enum.Font.FredokaOne
    sub.TextSize=12
    sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Parent=frame

    local scale=Instance.new('UIScale')
    scale.Scale=.88
    scale.Parent=frame
    local shadowScale=Instance.new('UIScale')
    shadowScale.Scale=.88
    shadowScale.Parent=shadow

    TS:Create(frame,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(.5,0,1,-164)}):Play()
    TS:Create(shadow,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(.5,4,1,-160)}):Play()
    TS:Create(scale,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    TS:Create(shadowScale,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()

    task.delay(4.45,function()
        if serial~=spawnToastSerial or not sg.Parent then return end
        TS:Create(frame,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(.5,0,1,-150),BackgroundTransparency=1}):Play()
        TS:Create(shadow,TweenInfo.new(.2),{BackgroundTransparency=1}):Play()
        TS:Create(item,TweenInfo.new(.16),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        TS:Create(sub,TweenInfo.new(.16),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        TS:Create(check,TweenInfo.new(.16),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        TS:Create(badge,TweenInfo.new(.16),{BackgroundTransparency=1}):Play()
        outline.Transparency=1
        badgeStroke.Transparency=1
        shine.BackgroundTransparency=1
        task.wait(.22)
        if sg.Parent then sg:Destroy() end
    end)
end

local function spawnTool(cat,name)local image=itemImage(cat,name) if not image then return false,'Exact item image is not ready'end local m,exact=model(cat,name)if not m then return false,'No 3D model available'end local t=Instance.new('Tool')t.Name=name t.TextureId=image t:SetAttribute('SAE_EXACT_REFERENCE_ICON',image) t.RequiresHandle=true t.CanBeDropped=false t:SetAttribute('SAE_V7_TOOL',true)t:SetAttribute('SAE_ID',Http:GenerateGUID(false))local h=part(t,'Handle',Vector3.new(.45,.45,.45),Color3.new(),CFrame.new(),MAT,1)h.CanQuery=false if m:GetAttribute('SAE_TREADMILL') then
    t.ToolTip='Equip and click a flat floor to place this treadmill.'
    t.Grip=CFrame.new(0,-.5,0)
    weld(t,m,CFrame.new(0,-1.2,-7.2))
    treadmillRuntime:Watch(m)
    t.Activated:Connect(function() if t.Parent==P.Character then place(t,m) end end)
elseif cat=='Eggs'then t.Grip=CFrame.new(0,-.1,-.25)*CFrame.Angles(math.rad(-12),math.rad(180),0)weld(t,m,CFrame.new(0,.45,-.75)*CFrame.Angles(0,math.rad(180),0))elseif cat=='Star'then t.Grip=CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(180),0)weld(t,m,CFrame.new(0,.5,-1.55)*CFrame.Angles(0,math.rad(180),0))else weld(t,m,CFrame.new(0,2,-4.4))t.Activated:Connect(function()if t.Parent==P.Character then place(t,m)end end)end t.Parent=BP showInventoryToast(name) return true,(m:GetAttribute('SAE_TREADMILL') and 'Custom 3D treadmill') or (cat=='Eggs' and '3D reference model') or (exact and 'Exact loaded 3D model' or 'True 3D reference build')end

local C={bg=rgb(8,8,14),head=rgb(15,11,23),card=rgb(24,18,34),card2=rgb(37,25,50),border=rgb(84,57,110),p=rgb(142,51,236),p2=rgb(184,83,255),w=Color3.new(1,1,1),m=rgb(168,162,181),g=rgb(105,245,135),o=rgb(255,188,82),r=rgb(255,90,90)}
local function corner(o,r)local x=Instance.new('UICorner')x.CornerRadius=UDim.new(0,r or 8)x.Parent=o end
local function stroke(o,a)local x=Instance.new('UIStroke')x.Color=C.border x.Transparency=a or .35 x.Parent=o end
local function label(p,t,pos,size,z,col)local x=Instance.new('TextLabel')x.BackgroundTransparency=1 x.Position=pos x.Size=size x.Text=t x.TextColor3=col or C.w x.Font=Enum.Font.GothamMedium x.TextSize=z or 11 x.TextXAlignment=Enum.TextXAlignment.Left x.Parent=p return x end
local function button(p,t,pos,size)local x=Instance.new('TextButton')x.Position=pos x.Size=size x.BackgroundColor3=C.p x.BorderSizePixel=0 x.Text=t x.TextColor3=C.w x.Font=Enum.Font.GothamBold x.TextSize=11 x.Parent=p corner(x,8)return x end
local gui=Instance.new('ScreenGui')gui.Name='SAE_ITEMS_V7'gui.ResetOnSpawn=false gui.DisplayOrder=730 gui.Parent=PG
gui.Destroying:Connect(function()
    for _,entry in pairs(preparedModels) do entry.template:Destroy() end
    table.clear(preparedModels)
end)
local StarterGui=game:GetService('StarterGui')
pcall(function()StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)end)
local launcher=button(gui,'ITEMS',UDim2.new(0,12,.5,-20),UDim2.fromOffset(74,38))
local win=Instance.new('Frame')win.AnchorPoint=Vector2.new(.5,.5)win.Size=UDim2.fromOffset(410,350)win.Position=UDim2.fromScale(.5,.5)win.BackgroundColor3=C.bg win.BorderSizePixel=0 win.Visible=false win.Parent=gui corner(win,13)stroke(win,.1)local winScale=Instance.new('UIScale')winScale.Scale=.575 winScale.Parent=win
local head=Instance.new('Frame')head.Size=UDim2.new(1,0,0,62)head.BackgroundColor3=C.head head.BorderSizePixel=0 head.Parent=win corner(head,13)
local title=label(head,'DIVINE ITEM SPAWNER · REFERENCE EGGS',UDim2.fromOffset(16,8),UDim2.new(1,-70,0,24),15)title.Font=Enum.Font.GothamBold
label(head,'25% smaller • refined Unicorn, Night Flame, Sabertooth',UDim2.fromOffset(16,31),UDim2.new(1,-70,0,18),10,C.m)
local close=button(head,'X',UDim2.new(1,-43,0,13),UDim2.fromOffset(28,28))close.BackgroundColor3=C.card2
launcher.MouseButton1Click:Connect(function()win.Visible=not win.Visible end)close.MouseButton1Click:Connect(function()win.Visible=false end)
local dragging=false local dragStart local startPos
head.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true dragStart=i.Position startPos=win.Position end end)
UIS.InputChanged:Connect(function(i)if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)end end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
local tabs=Instance.new('Frame')tabs.BackgroundTransparency=1 tabs.Position=UDim2.fromOffset(14,72)tabs.Size=UDim2.new(1,-28,0,38)tabs.Parent=win
local content=Instance.new('ScrollingFrame')content.Position=UDim2.fromOffset(14,118)content.Size=UDim2.new(1,-28,1,-190)content.BackgroundColor3=C.card content.BorderSizePixel=0 content.ScrollBarThickness=5 content.CanvasSize=UDim2.fromOffset(0,0)content.Parent=win corner(content,10)stroke(content,.5)
local grid=Instance.new('UIGridLayout')grid.CellSize=UDim2.new(.5,-9,0,38)grid.CellPadding=UDim2.fromOffset(8,8)grid.SortOrder=Enum.SortOrder.LayoutOrder grid.Parent=content
local pad=Instance.new('UIPadding')pad.PaddingTop=UDim.new(0,8)pad.PaddingLeft=UDim.new(0,8)pad.PaddingRight=UDim.new(0,8)pad.Parent=content
grid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()content.CanvasSize=UDim2.fromOffset(0,grid.AbsoluteContentSize.Y+16)end)
local status=label(win,'Select an item',UDim2.new(0,16,1,-61),UDim2.new(1,-200,0,18),10,C.m)
local cat,sel='Eggs',nil local tabButtons={}
local function paint()for n,b in pairs(tabButtons)do b.BackgroundColor3=(n==cat)and C.p or C.card2 end end
local function render()for _,c in ipairs(content:GetChildren())do if c:IsA('TextButton')then c:Destroy()end end local list=cat=='Eggs'and Eggs or cat=='Pets'and Pets or GiftCatalog.Star for i,name in ipairs(list)do local b=button(content,name,UDim2.new(),UDim2.new())b.LayoutOrder=i b.BackgroundColor3=(sel==name and C.p2 or C.card2)b.MouseButton1Click:Connect(function()sel=name prepareSelectedItem(cat,name) status.Text='Selected: '..name status.TextColor3=C.w render()end)end end
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
task.spawn(function()
    local artworkOk,artworkError=xpcall(function()
-- Shared exact artwork for the main inventory; no gifting GUI or Q binding.
local GiftProducts={
    Eggs={
        {imageKey='unicorn',name='Unicorn Egg',model='Unicorn Egg',rate='0.04%'},
        {imageKey='kitsune',name='Kitsune Egg',model='Kitsune Egg',rate='0.18%'},
        {imageKey='nightflame',name='Nightflame Egg',model='Night Flame Egg',rate='0.22%'},
        {imageKey='archangel',name='ArchAngel Egg',model='Archangel Egg',rate='0.06%'},
        {imageKey='mecha-scrambler',name='Mecha Scrambler Egg',model='Mecha Scrambler Egg',rate='0.11%'},
        {imageKey='octophant',name='Octophant Egg',model='Octophant Egg',rate='0.41%'},
        {imageKey='skeletal-sabertooth',name='Skeletal Sabertooth Egg',model='Skeletal Sabertooth Egg',rate='0.08%'},
        {imageKey='sabertooth',name='Sabertooth Egg',model='Sabertooth Egg',rate='0.15%'},
        {imageKey='luminous-cthulhu',name='Luminous Cthulhu Egg',model='Luminous Cthulhu Egg',rate='0.03%'},
        {imageKey='cthulhu',name='Cthulhu Egg',model='Cthulhu Egg',rate='0.12%'},
        {imageKey='aetheron',name='Aetheron Egg',model='Aetheron Egg',rate='0.05%'},
        {imageKey='world-burner',name='World Burner Egg',model='World Burner Egg',rate='0.37%'},
    },
    Pets={
        {imageKey='unicorn-pet',name='Unicorn',model='Unicorn',rate='0.05%'},
        {imageKey='kitsune-pet',name='Kitsune',model='Kitsune',rate='0.16%'},
        {imageKey='nightflame-pet',name='Nightflame',model='Night Flame',rate='0.20%'},
        {imageKey='archangel-pet',name='ArchAngel',model='Archangel',rate='0.04%'},
        {imageKey='world-burner-pet',name='World Burner',model='World Burner',rate='0.35%'},
        {imageKey='aetheron-pet',name='Aetheron',model='Aetheron',rate='0.03%'},
        {imageKey='mecha-scrambler-pet',name='Mecha Scrambler',model='Mecha Scrambler',rate='0.12%'},
        {imageKey='octophant-pet',name='Octophant',model='Octophant',rate='0.40%'},
        {imageKey='skeletal-sabertooth-pet',name='Skeletal Sabertooth',model='Skeletal Sabertooth',rate='0.07%'},
        {imageKey='sabertooth-pet',name='Sabertooth',model='Sabertooth',rate='0.14%'},
        {imageKey='luminous-cthulhu-pet',name='Luminous Cthulhu',model='Luminous Cthulhu',rate='0.02%'},
        {imageKey='cthulhu-pet',name='Cthulhu',model='Cthulhu',rate='0.10%'},
    },
    Others={
        {imageKey='ben-treadmill',name='Ben Treadmill',model='Ben Treadmill',rate='0.25%',imageCategory='Others'},
        {imageKey='brockodile-treadmill',name='Brockodile Treadmill',model='Brockodile Treadmill',rate='0.28%',imageCategory='Others'},
        {imageKey='3-stars',name='3 Stars',model='Star',rate='0.45%',imageCategory='Star'},
        {imageKey='2-stars',name='2 Stars',model='Star',rate='0.62%',imageCategory='Star'},
        {imageKey='1-star',name='1 Star',model='Star',rate='0.90%',imageCategory='Star'},
    },
}

local GiftImageData={
    ['send-button-symbol']={byteLength=1831,fileName='SAE_SendPaperPlane_v1.png',path='assets/gifting/962e926588fc43355eb93505db3d514e1e1ebb3d.png'},
    ['treadmill-step-shoe']={byteLength=57840,fileName='SAE_StepShoeReference_v1.png',path='assets/gifting/7fda5963fcd68bf1aa53e0190bf112e17c221e88.png'},
    ['shop-wordmark']={byteLength=25820,fileName='SAE_Shop_wordmark_506b730e41b76ba4.png',path='assets/gifting/772a6da9442178df81eedbca306c843048591157.png'},
    ['unicorn']={byteLength=46482,fileName='SAE_Gift_unicorn_32f69a9b1b54edc6.png',path='assets/gifting/740d224e45266d43a81dc72a8f45b3e06d37af34.png'},
    ['kitsune']={byteLength=56561,fileName='SAE_Gift_kitsune_50fffc9384f66d99.png',path='assets/gifting/e9e4887a2e1ad578373127b09082897c6d24f5d1.png'},
    ['nightflame']={byteLength=60594,fileName='SAE_Gift_nightflame_9cdabefb41118114.png',path='assets/gifting/f42c40ec967b0a3cbe96ab6f35d0eed97f9de34f.png'},
    ['archangel']={byteLength=50266,fileName='SAE_Gift_archangel_1bb9fce6ddf92a4c.png',path='assets/gifting/77634ea30e07a09e0988486c7c4f694d9e77c9d2.png'},
    ['mecha-scrambler']={byteLength=45172,fileName='SAE_Gift_mecha-scrambler_035c50b0088ea2d3.png',path='assets/gifting/95c5dc05166eb0f01c76886a58116373b9cde629.png'},
    ['octophant']={byteLength=87822,fileName='SAE_Gift_octophant_c96e4b2d3ed30484.png',path='assets/gifting/af20d39de01cebf42609fd3b8916690db197d176.png'},
    ['skeletal-sabertooth']={byteLength=69827,fileName='SAE_Gift_skeletal-sabertooth_c2cfa34eaf60cdd0.png',path='assets/gifting/ea8a0c8d4d32909957eda5c9e3a1a53e6c5ed67d.png'},
    ['sabertooth']={byteLength=64680,fileName='SAE_Gift_sabertooth_e5336c65647b025c.png',path='assets/gifting/2aa559daf65dcdb5f70a00c35e2c7150cdc179b6.png'},
    ['luminous-cthulhu']={byteLength=67103,fileName='SAE_Gift_luminous-cthulhu_462c075aad0ed913.png',path='assets/gifting/2aabfd8e9c972fd68ffb474d36c68e834ee294c4.png'},
    ['cthulhu']={byteLength=67287,fileName='SAE_Gift_cthulhu_634d9288c81e51aa.png',path='assets/gifting/ea64d569df2f25f1ade991eeb62f91eb23825453.png'},
    ['aetheron']={byteLength=61123,fileName='SAE_Gift_aetheron_cac61e8af6017dbb.png',path='assets/gifting/b4a98f277a45366f7a524b35cc939af8a1c5053b.png'},
    ['world-burner']={byteLength=40442,fileName='SAE_Gift_world-burner_eecd31ccbbd7aa8c.png',path='assets/gifting/8f334ce3a3cd93713effa2d7e1ca7b07149a9e31.png'},
    ['unicorn-pet']={byteLength=55814,fileName='SAE_Gift_unicorn-pet_7e47c2fa45ef968e.png',path='assets/gifting/15f93f96205d38b7189e4baede7a1daddd7b9eda.png'},
    ['kitsune-pet']={byteLength=74125,fileName='SAE_Gift_kitsune-pet_243f8fc2c04627f9.png',path='assets/gifting/fe61824eeb5152096bc77de0cae87a441b2fedff.png'},
    ['nightflame-pet']={byteLength=97882,fileName='SAE_Gift_nightflame-pet_93cf4f46cc3c86f8.png',path='assets/gifting/25acdefa447b191634c1f816d6fd05fac59468df.png'},
    ['archangel-pet']={byteLength=111998,fileName='SAE_Gift_archangel-pet_0ebf112a41fd9ae0.png',path='assets/gifting/fce16ae64079098766cc299737ad4c2841530c4b.png'},
    ['world-burner-pet']={byteLength=91493,fileName='SAE_Gift_world-burner-pet_c2e1dd49315289d5.png',path='assets/gifting/05bdf0cfaa5664628d328aa3c36ebeffe1c50e3f.png'},
    ['aetheron-pet']={byteLength=116826,fileName='SAE_Gift_aetheron-pet_fdd1ae7a6b5bb5a9.png',path='assets/gifting/bb6c58b67711f9095e596a6e882fd197bf44747a.png'},
    ['mecha-scrambler-pet']={byteLength=118907,fileName='SAE_Gift_mecha-scrambler-pet_5bb66c3942f379d4.png',path='assets/gifting/17a311c2078b3052942897a4d006d44239d5656e.png'},
    ['octophant-pet']={byteLength=118728,fileName='SAE_Gift_octophant-pet_8dffe96b96cc4a3c.png',path='assets/gifting/44d73c3cc3fb533e84fa75bbb84328b9363dacdc.png'},
    ['skeletal-sabertooth-pet']={byteLength=90914,fileName='SAE_Gift_skeletal-sabertooth-pet_d2e13380b218b2da.png',path='assets/gifting/6874a78a096794de5635e11af08a1eb25768bb76.png'},
    ['sabertooth-pet']={byteLength=86881,fileName='SAE_Gift_sabertooth-pet_368860dd7100354b.png',path='assets/gifting/00dc77118fc3a619459af46a621ee99cdb8a4824.png'},
    ['luminous-cthulhu-pet']={byteLength=134120,fileName='SAE_Gift_luminous-cthulhu-pet_e1e3db69b2088d07.png',path='assets/gifting/367342b75bd05961a126de506b099f600585a57e.png'},
    ['cthulhu-pet']={byteLength=113991,fileName='SAE_Gift_cthulhu-pet_dfa69a011fd70f37.png',path='assets/gifting/0d1a6119bd5713d5aaa8b957550d3f0ff25ebae8.png'},
    ['ben-treadmill']={byteLength=169719,fileName='SAE_Gift_ben-treadmill_bb9c1dfd96060716.png',path='assets/gifting/a44aad3858af7d55df7e63d640b52ac0dccbd220.png'},
    ['brockodile-treadmill']={byteLength=173520,fileName='SAE_Gift_brockodile-treadmill_22050b0957ec758d.png',path='assets/gifting/9636bd3aec0b8e4630c9035bcb2bfe28571b57a6.png'},
    ['3-stars']={byteLength=148675,fileName='SAE_Gift_3-stars_73ed2ff8c9f00da1.png',path='assets/gifting/ea257c3ef17fd23cede313ff0861f93b18a10f19.png'},
    ['2-stars']={byteLength=110224,fileName='SAE_Gift_2-stars_98e33c761b61e5df.png',path='assets/gifting/654d60712365ee058ebc51f46e0e1641c0559142.png'},
    ['1-star']={byteLength=127550,fileName='SAE_Gift_1-star_e4c3ae21a6b7575b.png',path='assets/gifting/93287331b83033f583f301985a44f75cdf0aaa42.png'},
    ['gift-button-symbol']={byteLength=1499,fileName='SAE_Gift_button_symbol_4c6c9dd4da00517f.png',path='assets/gifting/80bf4b12dca58aad9d1b098bf6f19d539d3df2c6.png'},
}
-- Artwork is served as immutable PNG assets from this same repository.
local GiftImageBase='https://raw.githubusercontent.com/randomcamper707/stealanegg167/refs/heads/main/'
local GiftImageAssets={}
local GiftImagePending={}
local GiftImageRetryAt={}
local GiftPngSignature=string.char(137,80,78,71,13,10,26,10)
local function giftImages(category,product)
    local key=product.imageKey
    if GiftImageAssets[key] then return GiftImageAssets[key] end
    local entry=GiftImageData[key]
    if not entry then return nil end
    if GiftImageRetryAt[key] and os.clock()<GiftImageRetryAt[key] then return nil end
    if GiftImagePending[key] then
        local started=os.clock()
        while GiftImagePending[key] and os.clock()-started<15 do task.wait(.05) end
        return GiftImageAssets[key]
    end
    GiftImagePending[key]=true
    local ok,result=pcall(function()
        local register=(type(getcustomasset)=='function' and getcustomasset)
            or (type(getsynasset)=='function' and getsynasset)
        assert(type(writefile)=='function' and register,
            'Exact artwork requires writefile and getcustomasset/getsynasset')
        local function valid(raw)
            return type(raw)=='string' and #raw==entry.byteLength and raw:sub(1,8)==GiftPngSignature
        end
        local raw=nil
        if type(readfile)=='function' then
            local cached,value=pcall(readfile,entry.fileName)
            if cached and valid(value) then raw=value end
        end
        if not raw then
            for attempt=1,2 do
                local downloaded,value=pcall(function()
                    return game:HttpGet(GiftImageBase..entry.path)
                end)
                if downloaded and valid(value) then raw=value break end
                if attempt<2 then task.wait(.25) end
            end
            assert(valid(raw),'Could not download PNG artwork: '..key)
            writefile(entry.fileName,raw)
        end
        local asset=register(entry.fileName)
        assert(type(asset)=='string' and asset~='','Could not register PNG artwork: '..key)
        return asset
    end)
    GiftImagePending[key]=nil
    if not ok then
        GiftImageRetryAt[key]=os.clock()+3
        warn('[SAE] Artwork '..key..': '..tostring(result))
        return nil
    end
    GiftImageRetryAt[key]=nil
    GiftImageAssets[key]=result
    return result
end
-- Inventory and Gifting share these exact repository PNGs; no world textures.
local inventoryProducts={}
for category,products in pairs(GiftProducts) do
    for _,product in ipairs(products) do
        inventoryProducts[product.model]={category=category,product=product}
        inventoryProducts[product.name]={category=category,product=product}
    end
end
inventoryProducts.Star={category='Others',product={imageKey='1-star'}}
inventoryProducts["Ben's Treadmill"]={category='Others',product={imageKey='ben-treadmill'}}
inventoryProducts["Brocodile's Treadmill"]={category='Others',product={imageKey='brockodile-treadmill'}}
E.SAE_ITEM_ICON_RESOLVER=function(name)
    local entry=inventoryProducts[name]
    if not entry then return nil end
    return giftImages(entry.category,entry.product)
end
E.SAE_STEP_ICON_ASSET=nil
E.SAE_STEP_ICON_RESOLVER=function()
    local image=giftImages('Others',{imageKey='treadmill-step-shoe'})
    if image then E.SAE_STEP_ICON_ASSET=image end
    return image
end
task.spawn(function() pcall(E.SAE_STEP_ICON_RESOLVER) end)

    end,debug.traceback)
    if not artworkOk then warn('[SAE] Inventory artwork error: '..tostring(artworkError)) end
end)

RS.DescendantAdded:Connect(function(object)
    if object:IsA('Model') or object:IsA('Tool') then cache={} end
end)
P.CharacterAdded:Connect(function() cache={} end)
print('[SAE] V7 true-3D inventory loaded: no stacked image fallbacks.')

end)
]============]

local allOkay=true
allOkay=executeEmbedded('approved exact pets',EXACT_PETS_SOURCE) and allOkay
allOkay=executeEmbedded('held Star',EXACT_STAR_SOURCE) and allOkay
allOkay=executeEmbedded('pet/egg polish',FINAL_POLISH_SOURCE) and allOkay
allOkay=executeEmbedded('control panel',CONTROL_PANEL_SOURCE) and allOkay

env.SAE_SINGLE_MAIN_RUNNING=nil

if allOkay then
    setStatus('STEAL AN EGG\nLoaded successfully')
    task.delay(1.0,function()
        if statusGui and statusGui.Parent then statusGui:Destroy() end
    end)
else
    pcall(function()
        StarterGui:SetCore('SendNotification',{
            Title='Steal An Egg',
            Text='A module failed to load. The error is shown on screen.',
            Duration=8
        })
    end)
end

-- SAE_INTEGRATED_FINAL_FIXES_20261024
-- Integrated from FinalFix.lua so Main.lua alone includes the requested panel +15% and Star visibility fixes.
(function()
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
    ["Ben's Treadmill"]=true,
    ["Brocodile's Treadmill"]=true,
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
    local shared=((getgenv and getgenv()) or _G).SAE_ITEM_ICON_RESOLVER
    if type(shared)=='function' then
        local image=shared(name)
        if image then return image end
    end
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
                d.ImageRectOffset=Vector2.zero
                d.ImageRectSize=Vector2.zero
                d.Image=image
                return
            end
            if not fallback and (d.Image=='' or d.Image=='rbxassetid://0') then fallback=d end
        end
    end
    if fallback then
        fallback.ImageRectOffset=Vector2.zero
        fallback.ImageRectSize=Vector2.zero
        fallback.Image=image
    end
end

local patchedToolImages=setmetatable({},{__mode='k'})
local function applyIcon(tool)
    if not tool or not tool:IsA('Tool') or not VALID[tool.Name] then return end
    local current=tool:GetAttribute('SAE_EXACT_REFERENCE_ICON') or usableImage(tool.TextureId)
    local image=current or exactIcon(tool.Name)
    if image and patchedToolImages[tool]==image and tool.TextureId==image then return end
    if image then patchedToolImages[tool]=image end
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
end)();

-- Integrated from FinalExactIcons.lua so Main.lua alone installs the exact supplied egg/pet/Star hotbar renders.
(function()
local Players=game:GetService('Players')
local P=Players.LocalPlayer
if not P then return end
local PG=P:FindFirstChildOfClass('PlayerGui') or P:WaitForChild('PlayerGui',10)
local BP=P:FindFirstChildOfClass('Backpack') or P:WaitForChild('Backpack',10)
if not PG or not BP then return end

local IMAGE_KEY={
    ["Ben's Treadmill"]='ben-treadmill',
    ["Brocodile's Treadmill"]='brockodile-treadmill',
    ['Unicorn Egg']='unicorn_egg',
    ['Unicorn']='unicorn_pet',
    ['Kitsune Egg']='kitsune_egg',
    ['Kitsune']='kitsune_pet',
    ['Night Flame Egg']='night_flame_egg',
    ['Night Flame']='night_flame_pet',
    ['Archangel Egg']='archangel_egg',
    ['Archangel']='archangel_pet',
    ['World Burner Egg']='world_burner_egg',
    ['World Burner']='world_burner_pet',
    ['Aetheron Egg']='aetheron_egg',
    ['Aetheron']='aetheron_pet',
    ['Cthulhu Egg']='cthulhu_egg',
    ['Cthulhu']='cthulhu_pet',
    ['Luminous Cthulhu Egg']='luminous_cthulhu_egg',
    ['Luminous Cthulhu']='luminous_cthulhu_pet',
    ['Sabertooth Egg']='sabertooth_egg',
    ['Sabertooth']='sabertooth_pet',
    ['Skeletal Sabertooth Egg']='skeletal_sabertooth_egg',
    ['Skeletal Sabertooth']='skeletal_sabertooth_pet',
    ['Octophant Egg']='octophant_egg',
    ['Octophant']='octophant_pet',
    ['Mecha Scrambler Egg']='mecha_scrambler_egg',
    ['Mecha Scrambler']='mecha_scrambler_pet',
    ['Star']='star',
}

local function exactAsset(name)
    local resolver=((getgenv and getgenv()) or _G).SAE_ITEM_ICON_RESOLVER
    if type(resolver)~='function' then return nil end
    return resolver(name)
end

local function norm(s)
    return tostring(s or ''):lower():gsub('[^%w]','')
end

-- Patch the game's visible hotbar image too, not only Tool.TextureId.
local function patchVisibleSlot(name,asset)
    if not asset or not PG then return end
    local want=norm(name)
    for _,obj in ipairs(PG:GetDescendants()) do
        if (obj:IsA('TextLabel') or obj:IsA('TextButton')) and norm(obj.Text)==want then
            local holder=obj.Parent
            local ancestor=holder
            local hotbar=false
            for _=1,6 do
                if not ancestor then break end
                local n=norm(ancestor.Name)
                if n:find('hotbar',1,true) or n:find('backpack',1,true)
                    or n:find('inventory',1,true) or n:find('toolbar',1,true)
                    or n:find('slot',1,true) then hotbar=true break end
                ancestor=ancestor.Parent
            end
            if hotbar and holder then
                for depth=1,2 do
                    for _,image in ipairs(holder:GetDescendants()) do
                        if image:IsA('ImageLabel') or image:IsA('ImageButton') then
                            local n=norm(image.Name)
                            if n:find('icon',1,true) or n:find('thumbnail',1,true) or n=='itemimage' or n=='image' then
                                image.ImageRectOffset=Vector2.zero
                                image.ImageRectSize=Vector2.zero
                                image.Image=asset
                                return
                            end
                        end
                    end
                    holder=holder.Parent
                    if not holder then break end
                end
            end
        end
    end
end

local function applyExact(tool)
    if not tool or not tool:IsA('Tool') then return end
    if not IMAGE_KEY[tool.Name] then return end

    local asset=exactAsset(tool.Name)
    if not asset then return end
    if tool.TextureId==asset and tool:GetAttribute('SAE_EXACT_ICON_BOUND') then return end
    tool:SetAttribute('SAE_EXACT_ICON_BOUND',true)

    pcall(function()
        tool.TextureId=asset
        tool:SetAttribute('SAE_EXACT_REFERENCE_ICON',asset)
    end)

    task.defer(function()
        task.wait(.1)
        patchVisibleSlot(tool.Name,asset)
    end)
end

local function bind(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and IMAGE_KEY[child.Name] then
            task.defer(function()
                task.wait(.05)
                applyExact(child)
            end)
        end
    end)
    for _,child in ipairs(container:GetChildren()) do
        if child:IsA('Tool') and IMAGE_KEY[child.Name] then
            applyExact(child)
        end
    end
end

bind(BP)
bind(P.Character)
P.CharacterAdded:Connect(function(char)
    task.wait(.1)
    bind(char)
end)

-- Replacement layers can swap Tools for a short period after spawning/equipping.
-- Reapply the exact reference after those replacements finish.
task.spawn(function()
    for _=1,24 do
        task.wait(.25)
        for _,holder in ipairs({BP,P.Character}) do
            if holder then
                for _,tool in ipairs(holder:GetChildren()) do
                    if tool:IsA('Tool') and IMAGE_KEY[tool.Name] then
                        applyExact(tool)
                    end
                end
            end
        end
    end
end)

print('[SAE] Exact supplied hotbar references installed for all eggs, pets and Star.')
end)()

