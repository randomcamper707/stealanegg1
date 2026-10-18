        return makeReferenceVolume(category,item),false
    end
    local exact=findExact(category,item.name)
    if exact then
        local m=cloneExact(exact,item.name)
        if m then
            fitModel(m,category=='Pets' and 16 or category=='Eggs' and 10.5 or 6)
            return m,true
        end
    end
    local ref=makeReferenceVolume(category,item)
    return ref,false
end

local function holdTarget(category,m)
    local char=P.Character
    local hrp=char and char:FindFirstChild('HumanoidRootPart')
    local hand=char and (char:FindFirstChild('RightHand') or char:FindFirstChild('Right Arm'))
    if not hrp or not hand then return nil,nil end
    local target
    if category=='Pets' then
        target=hrp.CFrame*CFrame.new(0,3.8,2.7)
    elseif category=='Eggs' then
        target=hrp.CFrame*CFrame.new(.15,1.45,-3.0)
    else
        target=hrp.CFrame*CFrame.new(1.7,1.55,-1.65)
    end
    return target,hand
end

local statusFn=function() end
local function showHeld(tool,category,item)
    destroyHeld(tool)
    local key=tool:GetAttribute('SAE_V6_ID')
    task.spawn(function()
        statusFn('Finding the exact '..item.name..' 3D model...',C.m)
        local m,isExact=buildVisual(category,item)
        if not m then
            statusFn('Could not build '..item.name..'.',C.r)
            return
        end
        if not tool.Parent or not P.Character or tool.Parent~=P.Character then m:Destroy() return end
        local target,hand=holdTarget(category,m)
        if not target or not hand then m:Destroy() return end
        m:SetAttribute('SAE_V6_TOOLKEY',key)
        m.Parent=P.Character
        for _,q in ipairs(allParts(m)) do q.Anchored=true q.CanCollide=false q.CanTouch=false q.CanQuery=false q.Massless=true end
        centerModelAt(m,target)
        local root=m.PrimaryPart or m:FindFirstChildWhichIsA('BasePart',true)
        if not root then m:Destroy() return end
        if not m.PrimaryPart then m.PrimaryPart=root end
        weldModel(m,root)
        local w=Instance.new('WeldConstraint')
        w.Name='SAE_V6_HAND_WELD'
        w.Part0=hand
        w.Part1=root
        w.Parent=root
        for _,q in ipairs(allParts(m)) do q.Anchored=false end
        heldByKey[key]=m
        if isExact then
            statusFn(item.name..' is using the actual replicated 3D model.',C.g)
        else
            statusFn(item.name..' is using the exact supplied render as a volumetric 3D reference shell because the original model is not replicated.',C.o)
        end
    end)
end

local function anchorAndGround(m,pos,yaw)
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA('WeldConstraint') and d.Name=='SAE_V6_HAND_WELD' then d:Destroy() end
    end
    for _,q in ipairs(allParts(m)) do q.Anchored=true q.CanCollide=false q.CanTouch=false q.CanQuery=true end
    m:PivotTo(CFrame.new(pos)*CFrame.Angles(0,yaw or 0,0))
    local ok,cf,sz=pcall(function() local a,b=m:GetBoundingBox() return a,b end)
    if ok and cf and sz then
        m:PivotTo(m:GetPivot()+Vector3.new(0,pos.Y-(cf.Position.Y-sz.Y/2)+.05,0))
    end
end

local placing={}
local function placePet(tool,item)
    local key=tool:GetAttribute('SAE_V6_ID')
    if placing[key] then return end
    placing[key]=true
    local current=heldByKey[key]
    task.spawn(function()
        local src=current
        if not src then src=select(1,buildVisual('Pets',item)) end
        if not src then placing[key]=nil statusFn('Could not place '..item.name..'.',C.r) return end
        local c=src:Clone()
        c.Name=item.name
        for _,d in ipairs(c:GetDescendants()) do
            if d:IsA('WeldConstraint') and d.Name=='SAE_V6_HAND_WELD' then d:Destroy() end
        end
        c.Parent=Placed
        local mouse=P:GetMouse()
        local hrp=P.Character and P.Character:FindFirstChild('HumanoidRootPart')
        local pos=(mouse and mouse.Hit and mouse.Hit.Position) or (hrp and (hrp.Position+hrp.CFrame.LookVector*8)) or Vector3.zero
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        local ex={Placed}
        if P.Character then ex[#ex+1]=P.Character end
        rp.FilterDescendantsInstances=ex
        local hit=workspace:Raycast(pos+Vector3.new(0,60,0),Vector3.new(0,-140,0),rp)
        if hit then pos=hit.Position end
        local yaw=0
        if hrp then local _,y,_=hrp.CFrame:ToOrientation() yaw=y end
        anchorAndGround(c,pos,yaw)
        destroyHeld(tool)
        tool:Destroy()
        placing[key]=nil
        statusFn(item.name..' placed.',C.g)
    end)
end

local function makeTool(category,item)
    local t=Instance.new('Tool')
    t.Name=item.name
    t.ToolTip='DIVINE • '..item.name
    t.RequiresHandle=false
    t.CanBeDropped=false
    t:SetAttribute('SAE_V6_TOOL',true)
    t:SetAttribute('SAE_V6_CATEGORY',category)
    t:SetAttribute('SAE_V6_ITEM',item.name)
    t:SetAttribute('SAE_V6_ID',Http:GenerateGUID(false))
    t.Equipped:Connect(function() showHeld(t,category,item) end)
    t.Unequipped:Connect(function() destroyHeld(t) end)
    t.AncestryChanged:Connect(function(_,par) if not par then destroyHeld(t) end end)
    if category=='Pets' then t.Activated:Connect(function() placePet(t,item) end) end
    t.Parent=BP
    return t
end

local function corner(o,r)local x=Instance.new('UICorner')x.CornerRadius=UDim.new(0,r or 8)x.Parent=o return x end
local function stroke(o,a)local x=Instance.new('UIStroke')x.Color=C.border x.Transparency=a or .3 x.Thickness=1 x.Parent=o return x end
local function label(p,t,pos,size,z,col)local x=Instance.new('TextLabel')x.BackgroundTransparency=1 x.Position=pos x.Size=size x.Text=t x.TextColor3=col or C.w x.Font=Enum.Font.GothamMedium x.TextSize=z or 11 x.TextXAlignment=Enum.TextXAlignment.Left x.Parent=p return x end
local function button(p,t,pos,size,primary)
    local x=Instance.new('TextButton')x.Position=pos x.Size=size x.BackgroundColor3=primary and C.p or C.card2 x.BorderSizePixel=0 x.AutoButtonColor=false x.Text=t x.TextColor3=C.w x.Font=Enum.Font.GothamBold x.TextSize=11 x.Parent=p corner(x,8)stroke(x,.55)
    local rest=x.BackgroundColor3
    x.MouseEnter:Connect(function() TweenService:Create(x,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(102,52,160)}):Play() end)
    x.MouseLeave:Connect(function() TweenService:Create(x,TweenInfo.new(.12),{BackgroundColor3=rest}):Play() end)
    return x
end

local G=Instance.new('ScreenGui')
G.Name='SAE_ITEMS_V6'
G.ResetOnSpawn=false
G.DisplayOrder=730
G.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
G.Parent=PG

local F=Instance.new('Frame')
F.AnchorPoint=Vector2.new(.5,.5)
F.Position=UDim2.fromScale(.5,.5)
F.Size=UDim2.fromOffset(570,500)
F.BackgroundColor3=C.bg
F.BorderSizePixel=0
F.Parent=G
corner(F,13)stroke(F,.08)

local H=Instance.new('Frame')
H.Size=UDim2.new(1,0,0,64)
H.BackgroundColor3=C.head
H.BorderSizePixel=0
H.Parent=F
corner(H,13)
local ttl=label(H,'DIVINE ITEM SPAWNER',UDim2.fromOffset(16,7),UDim2.new(1,-64,0,25),15,C.w)ttl.Font=Enum.Font.GothamBold
local sub=label(H,'Exact 3D models first • reference-faithful fallback • larger held items',UDim2.fromOffset(16,34),UDim2.new(1,-64,0,18),9,C.m)
local close=button(H,'X',UDim2.new(1,-43,0,12),UDim2.fromOffset(29,29),false)
close.MouseButton1Click:Connect(function() F.Visible=false end)

local drag=false local ds local dp
H.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true ds=i.Position dp=F.Position end end)
UIS.InputChanged:Connect(function(i)if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds F.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)end end)
UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

local launcher=button(G,'ITEMS',UDim2.new(0,12,.5,18),UDim2.fromOffset(105,31),true)
launcher.MouseButton1Click:Connect(function()F.Visible=not F.Visible end)

local tabs=Instance.new('Frame')tabs.BackgroundTransparency=1 tabs.Position=UDim2.fromOffset(12,76)tabs.Size=UDim2.new(1,-24,0,36)tabs.Parent=F
local tb={}
for i,n in ipairs({'Eggs','Pets','Star'})do tb[n]=button(tabs,n:upper(),UDim2.new((i-1)/3,(i-1)*3,0,0),UDim2.new(1/3,-6,1,0),false)end

local card=Instance.new('Frame')card.Position=UDim2.fromOffset(12,122)card.Size=UDim2.new(1,-24,0,286)card.BackgroundColor3=C.card card.BorderSizePixel=0 card.Parent=F corner(card,10)stroke(card,.5)
local scroll=Instance.new('ScrollingFrame')scroll.Position=UDim2.fromOffset(8,8)scroll.Size=UDim2.new(1,-16,1,-16)scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=4 scroll.ScrollBarImageColor3=C.p2 scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y scroll.CanvasSize=UDim2.new()scroll.Parent=card
local grid=Instance.new('UIGridLayout')grid.CellPadding=UDim2.fromOffset(7,7)grid.CellSize=UDim2.new(.5,-4,0,45)grid.SortOrder=Enum.SortOrder.LayoutOrder grid.Parent=scroll

local footer=Instance.new('Frame')footer.Position=UDim2.fromOffset(12,418)footer.Size=UDim2.new(1,-24,0,70)footer.BackgroundColor3=C.card footer.BorderSizePixel=0 footer.Parent=F corner(footer,10)stroke(footer,.5)
local sel=label(footer,'Nothing selected',UDim2.fromOffset(12,7),UDim2.new(1,-182,0,21),12,C.w)sel.Font=Enum.Font.GothamBold
local meta=label(footer,'Choose an item above.',UDim2.fromOffset(12,28),UDim2.new(1,-182,0,17),9,C.m)
local status=label(footer,'',UDim2.fromOffset(12,47),UDim2.new(1,-182,0,16),8,C.m)status.TextTruncate=Enum.TextTruncate.AtEnd
local spawn=button(footer,'ADD TO INVENTORY',UDim2.new(1,-169,0,12),UDim2.fromOffset(155,47),true)

statusFn=function(msg,col)status.Text=tostring(msg or '')status.TextColor3=col or C.m end
local currentCat='Eggs' local current=nil local itemButtons={}
local function setTab(cat)
    for n,b in pairs(tb)do b.BackgroundColor3=(n==cat)and C.p or C.card2 end
end
local function rebuild(cat)
    currentCat=cat current=nil sel.Text='Nothing selected' meta.Text=cat=='Pets' and 'Equip a pet then click to place it.' or 'Choose an item above.' statusFn('')
    for _,b in ipairs(itemButtons)do if b.Parent then b:Destroy()end end itemButtons={}
    setTab(cat)
    for i,item in ipairs(ITEMS[cat])do
        local b=button(scroll,'   '..item.name,UDim2.new(),UDim2.new(),false)b.LayoutOrder=i b.TextXAlignment=Enum.TextXAlignment.Left b.TextSize=10 itemButtons[#itemButtons+1]=b
        b.MouseButton1Click:Connect(function()
            current=item sel.Text=item.name meta.Text='DIVINE • '..(cat=='Eggs' and 'EGG' or cat=='Pets' and 'PET' or 'STAR')
            statusFn('Will use the exact 3D game model when available.',C.m)
            for _,o in ipairs(itemButtons)do o.BackgroundColor3=C.card2 end b.BackgroundColor3=Color3.fromRGB(78,45,107)
        end)
    end
end
for n,b in pairs(tb)do b.MouseButton1Click:Connect(function()rebuild(n)end)end
spawn.MouseButton1Click:Connect(function()
    if not current then statusFn('Select an item first.',C.o)return end
    makeTool(currentCat,current)
    statusFn(current.name..' added. Equip it to hold the larger 3D version.',C.g)
end)
rebuild('Eggs')

P.CharacterAdded:Connect(function()
    for k,m in pairs(heldByKey)do if m then pcall(function()m:Destroy()end)end heldByKey[k]=nil end
end)
RS.DescendantAdded:Connect(function()sourceCache={}end)

print('[SAE] V6 exact/reference-faithful 3D inventory loaded.')
