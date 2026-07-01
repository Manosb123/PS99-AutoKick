-- ============================================================
--  Pet Simulator 99 ⚽ World Cup AutoKick + Speed TP Collect
--  Made by Manos | Matcha External
--  Toggle UI: Insert Key
-- ============================================================

local Players     = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local PlayerGui   = localPlayer:WaitForChild("PlayerGui")
local StarterGui  = game:GetService("StarterGui")
local Workspace   = game:GetService("Workspace")
local CoreGui     = game:GetService("CoreGui")

local autoKickRunning    = false
local autoCollectRunning = false
local resetDelay         = 2.5
local kickTimeout        = 10
local collectRadius      = 200
local kickCount          = 0
local orbsCollected      = 0
local statusLabel        = nil
local collectStatusLabel = nil
local cachedBall         = nil
local cachedPercent      = nil
local collecting         = false

local function dbg(msg) print("[Manos Script] " .. tostring(msg)) end
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 5})
    end)
end

local function setStatus(text)
    if statusLabel then pcall(function() statusLabel:SetContent(text) end) end
end
local function setCollectStatus(text)
    if collectStatusLabel then pcall(function() collectStatusLabel:SetContent(text) end) end
end

-- ================================================================
-- AUTO KICK (FROM USER'S PROVIDED SCRIPT)
-- ================================================================
local function findEventUI()
    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local tv = desc.Text
            if tv and type(tv) == "string" then
                local text = tv:lower():gsub("<[^>]+>", "")
                if text:find("hold to kick") then
                    return desc
                end
            end
        end
    end
    for _, name in ipairs({"BasketballButton", "WorldCup", "Soccer", "Kick"}) do
        local found = PlayerGui:FindFirstChild(name, true)
        if found then return found end
    end
    return nil
end

local function getUIElements()
    if cachedBall and cachedBall.Parent and cachedPercent and cachedPercent.Parent then
        return cachedBall, cachedPercent
    end
    
    local element = findEventUI()
    if not element then return nil, nil end
    
    local ballButton = nil
    local percentLabel = nil
    local root = nil
    
    if element:IsA("TextLabel") or element:IsA("TextButton") then
        local container = element.Parent
        if container then
            if container:IsA("GuiButton") then
                ballButton = container
                root = container.Parent
            else
                root = container
            end
        end
    else
        root = element
    end
    
    if not root then return nil, nil end
    
    if not ballButton then
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("GuiButton") then
                ballButton = child
                break
            end
        end
        if not ballButton then
            for _, child in ipairs(root:GetDescendants()) do
                if child:IsA("GuiButton") then
                    ballButton = child
                    break
                end
            end
        end
    end
    
    for _, child in ipairs(root:GetDescendants()) do
        if child:IsA("TextLabel") and type(child.Text) == "string" and child.Text:find("%%") then
            percentLabel = child
            break
        end
    end
    
    if ballButton and percentLabel then
        cachedBall = ballButton
        cachedPercent = percentLabel
    end
    
    return ballButton, percentLabel
end

local function getValidPosition(btn)
    local bx = btn.AbsolutePosition.X
    local by = btn.AbsolutePosition.Y
    local bw = btn.AbsoluteSize.X
    local bh = btn.AbsoluteSize.Y
    
    if bw < 5 or bh < 5 or (bx < 1 and by < 1) then
        return nil, nil
    end
    
    return bx + bw / 2, by + bh / 2
end

local function readPercent(label)
    local ok, val = pcall(function()
        return tonumber(label.Text:match("%d+"))
    end)
    if ok then return val end
    return nil
end

local function doKick(ball, percent)
    local x, y = getValidPosition(ball)
    if not x then
        setStatus("⏳ Ball hidden (throw animation), waiting...")
        task.wait(0.5)
        return false
    end
    
    setStatus("🎯 Moving to Soccer Ball...")
    mousemoveabs(x, y)
    task.wait(0.1)
    
    mouse1press()
    setStatus("⚡ Charging kick...")
    
    local resetStart = tick()
    while autoKickRunning do
        if tick() - resetStart > 3 then break end
        local p = readPercent(percent)
        if p and p < 50 then break end
        task.wait(0.01)
    end
    
    local startTime = tick()
    while autoKickRunning do
        if tick() - startTime > 6 then
            mouse1release()
            return false
        end
        
        local p = readPercent(percent)
        if p then
            setStatus("⚡ Charging: " .. p .. "%")
            if p >= 100 then
                mouse1release()
                kickCount = kickCount + 1
                setStatus("⚽ PERFECT KICK #" .. kickCount .. "! Waiting " .. resetDelay .. "s...")
                task.wait(resetDelay)
                return true
            end
        end
        task.wait(0.01)
    end
    
    pcall(mouse1release)
    return false
end

-- ================================================================
-- ORB COLLECTOR (HIGH-SPEED TP COLLECTOR)
-- ================================================================
local function getCharacterRoot()
    local char = localPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function collectOrbs()
    local hrp = getCharacterRoot()
    if not hrp or not hrp.Position then return 0 end

    local playerPos = hrp.Position
    local targets = {}
    local seen = {}

    local searchFolders = {}
    local things = Workspace:FindFirstChild("__THINGS")
    
    if things then
        table.insert(searchFolders, things)
    end
    if Workspace:FindFirstChild("__DEBRIS") then 
        table.insert(searchFolders, Workspace.__DEBRIS) 
    end

    -- Look for event folders directly in Workspace
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            local cName = child.Name:lower()
            if cName:find("soccer") or cName:find("cup") or cName:find("yeet") or cName:find("event") then
                table.insert(searchFolders, child)
            end
        end
    end

    local checkedCount = 0
    for _, folder in ipairs(searchFolders) do
        for _, obj in ipairs(folder:GetDescendants()) do
            checkedCount = checkedCount + 1
            if checkedCount % 150 == 0 then
                task.wait() -- Yield to keep UI smooth and prevent menu lag
            end

            if obj:IsA("BasePart") then
                local isOrb = false
                local lowerName = obj.Name:lower()
                
                -- Skip the main kickable ball
                if lowerName ~= "ball" and lowerName ~= "soccerball" and lowerName ~= "football" and lowerName ~= "soccer ball" then
                    if tonumber(obj.Name) ~= nil then 
                        isOrb = true
                    elseif lowerName:find("orb") or lowerName:find("soccer") then 
                        isOrb = true
                    elseif obj.Parent and obj.Parent.Name == "Orbs" then 
                        isOrb = true 
                    end
                end

                if isOrb then
                    local char = localPlayer.Character
                    local unwanted = false
                    
                    -- Check if it belongs to any player's character
                    for _, p in ipairs(Players:GetPlayers()) do
                        local pChar = p.Character
                        if pChar and obj:IsDescendantOf(pChar) then
                            unwanted = true
                            break
                        end
                    end

                    if not unwanted then
                        -- Ancestry check to exclude unwanted items like eggs, pets, gifts, chests
                        local current = obj
                        for depth = 1, 4 do
                            if not current then break end
                            local cName = current.Name:lower()
                            if cName:find("egg") or cName:find("pet") or cName:find("gift") or cName:find("box") or cName:find("chest") or cName:find("machine") or cName:find("hatch") or cName:find("shop") or cName:find("teleport") then
                                  unwanted = true
                                  break
                            end
                            current = current.Parent
                        end
                    end

                    if not unwanted then
                        local size = obj.Size
                        local pos = obj.Position
                        if size and pos and typeof(size) == "Vector3" and typeof(pos) == "Vector3" then
                            if size.Magnitude < 15 and not seen[obj] then
                                local dist = (pos - playerPos).Magnitude
                                if dist <= collectRadius then
                                    seen[obj] = true
                                    table.insert(targets, { obj = obj, dist = dist, pos = pos, collected = false })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b) return a.dist < b.dist end)
    if #targets == 0 then return 0 end

    local collectedCount = 0
    local originalCFrame = hrp.CFrame 

    local i = 1
    collecting = true
    while i <= #targets do
        if not autoCollectRunning then break end
        local primary = targets[i]
        
        if not primary.collected then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
            
            -- HEIGHT OFFSET FIX: +1.5 to Y axis so we don't clip into ledges
            hrp.CFrame = CFrame.new(primary.pos.X, primary.pos.Y + 1.5, primary.pos.Z)
            
            pcall(function()
                if typeof(firetouchinterest) == "function" then
                    firetouchinterest(hrp, primary.obj, 0)
                    firetouchinterest(hrp, primary.obj, 1)
                end
            end)
            primary.collected = true
            collectedCount = collectedCount + 1

            -- Collect any nearby neighbors within 15 studs in the same teleport step
            for j = i + 1, #targets do
                local neighbor = targets[j]
                if not neighbor.collected then
                    local distToPrimary = (neighbor.pos - primary.pos).Magnitude
                    if distToPrimary <= 15 then
                        pcall(function()
                            if typeof(firetouchinterest) == "function" then
                                firetouchinterest(hrp, neighbor.obj, 0)
                                firetouchinterest(hrp, neighbor.obj, 1)
                            end
                        end)
                        neighbor.collected = true
                        collectedCount = collectedCount + 1
                    end
                end
            end
            
            task.wait(0.01) -- Tiny delay per cluster teleport
        end
        i = i + 1
    end

    hrp.CFrame = originalCFrame
    collecting = false
    return collectedCount
end

-- ================================================================
-- EVENT-DRIVEN INSTANT ORB COLLECTION (REALTIME SPAWNING)
-- ================================================================
local function handleNewDescendant(obj)
    if not autoCollectRunning or collecting then return end
    if not obj:IsA("BasePart") then return end
    
    local lowerName = obj.Name:lower()
    if lowerName == "ball" or lowerName == "soccerball" or lowerName == "football" or lowerName == "soccer ball" then
        return
    end
    
    local isOrb = false
    if tonumber(obj.Name) ~= nil then 
        isOrb = true
    elseif lowerName:find("orb") or lowerName:find("soccer") then 
        isOrb = true
    elseif obj.Parent and obj.Parent.Name == "Orbs" then 
        isOrb = true 
    end
    
    if not isOrb then return end
    
    local char = localPlayer.Character
    if char and obj:IsDescendantOf(char) then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        local pChar = p.Character
        if pChar and obj:IsDescendantOf(pChar) then
            return
        end
    end
    
    local current = obj
    for depth = 1, 4 do
        if not current then break end
        local cName = current.Name:lower()
        if cName:find("egg") or cName:find("pet") or cName:find("gift") or cName:find("box") or cName:find("chest") or cName:find("machine") or cName:find("hatch") or cName:find("shop") or cName:find("teleport") then
            return
        end
        current = current.Parent
    end
    
    local hrp = getCharacterRoot()
    if not hrp or not hrp.Position then return end
    
    local pos = obj.Position
    local dist = (pos - hrp.Position).Magnitude
    if dist <= collectRadius then
        collecting = true
        local originalCFrame = hrp.CFrame
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(pos.X, pos.Y + 1.5, pos.Z)
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(hrp, obj, 0)
                firetouchinterest(hrp, obj, 1)
            end
        end)
        task.wait(0.01)
        hrp.CFrame = originalCFrame
        orbsCollected = orbsCollected + 1
        setCollectStatus("⚡ Instant Collect! (Total: " .. orbsCollected .. ")")
        collecting = false
    end
end

-- ================================================================
-- WABISABI UI LIBRARY & MAIN LOOPS
-- ================================================================
local Library = nil
local success, err = pcall(function()
    loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
    Library = WabiSabi
end)

if not success or not Library then
    autoKickRunning = true
else
    local Window = Library:CreateWindow({
        Title = "⚽ PS99 World Cup", SubTitle = "by Manos",
        Size = Vector2.new(500, 420), Resize = true,
        ConfigName = "ps99_worldcup", MinimizeKey = "Insert",
    })

    local kickTab = Window:AddTab({ Title = "Auto Kick", Icon = "target" })
    local kickSection = kickTab:AddSection("⚽ Kicker Controls")

    kickSection:AddToggle({
        Id = "AutoKickToggle", Title = "Enable Auto Kick", Default = false,
        Callback = function(state)
            autoKickRunning = state
            if not state then 
                pcall(mouse1release)
                kickCount = 0
            end
        end,
    })
    kickSection:AddSlider({
        Id = "ResetDelay", Title = "Delay Between Kicks (Sec)",
        Min = 1.0, Max = 5.0, Default = 2.5, Rounding = 1,
        Callback = function(value) resetDelay = value end
    })
    statusLabel = kickSection:AddParagraph({ Title = "Live Status", Content = "Waiting to start..." })

    local collectTab = Window:AddTab({ Title = "Auto Collect", Icon = "coins" })
    local collectSection = collectTab:AddSection("✨ Orb Collection")

    collectSection:AddToggle({
        Id = "AutoCollectToggle", Title = "Enable High-Speed TP", Default = false,
        Callback = function(state)
            autoCollectRunning = state
            if not state then orbsCollected = 0 end
        end,
    })
    collectSection:AddSlider({
        Id = "CollectRadius", Title = "Scan Radius (Studs)",
        Min = 50, Max = 500, Default = 250, Rounding = 0,
        Callback = function(value) collectRadius = value end
    })
    collectStatusLabel = collectSection:AddParagraph({ Title = "Collection Status", Content = "Waiting to start..." })

    task.spawn(function()
        task.wait(1)
        pcall(function()
            for _, gui in ipairs(CoreGui:GetDescendants()) do
                if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                    if gui.Size.X.Offset < 60 and gui.Size.Y.Offset < 60 and gui.Parent:IsA("ScreenGui") then
                        gui.Visible = false
                    end
                end
            end
        end)
    end)
end

-- THEIR Auto Kick Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoKickRunning then
            local ball, percent = getUIElements()
            if ball and percent then
                local ok, err = pcall(doKick, ball, percent)
                if not ok then
                    pcall(mouse1release)
                    task.wait(1)
                end
            else
                setStatus("⚠️ Open the World Cup Soccer UI first!")
                task.wait(1.5)
            end
        else
            setStatus("Idle — Toggle Auto Kick to start  |  Kicks: " .. kickCount)
        end
    end
end)

-- MY Orb Collect Loop (Background yield sweep)
task.spawn(function()
    while true do
        task.wait(1.5) -- Slower loop to save CPU, since ChildAdded handles instant collections!
        if autoCollectRunning then
            local ok, result = pcall(collectOrbs)
            if ok then
                if result > 0 then
                    orbsCollected = orbsCollected + result
                    setCollectStatus("✅ Swept " .. result .. " orbs! (Total: " .. orbsCollected .. ")")
                else
                    setCollectStatus("🔍 Scanning " .. collectRadius .. " studs... | Total: " .. orbsCollected)
                end
            else
                setCollectStatus("⚠️ Error: " .. tostring(result))
            end
        else
            setCollectStatus("Idle — Toggle to start | Orbs: " .. orbsCollected)
        end
    end
end)

-- Connect ChildAdded / DescendantAdded events to capture instant spawns
task.spawn(function()
    local things = Workspace:WaitForChild("__THINGS", 10)
    if things then
        things.DescendantAdded:Connect(function(obj)
            pcall(handleNewDescendant, obj)
        end)
    end
end)

task.spawn(function()
    local debris = Workspace:WaitForChild("__DEBRIS", 10)
    if debris then
        debris.DescendantAdded:Connect(function(obj)
            pcall(handleNewDescendant, obj)
        end)
    end
end)
