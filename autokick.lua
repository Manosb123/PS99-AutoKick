-- ============================================================
--  Pet Simulator 99 ⚽ World Cup AutoKick + Auto Collect
--  Made by Manos | Matcha External
--  Toggle UI: Insert Key
-- ============================================================

local Players    = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local PlayerGui  = localPlayer:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local Workspace  = game:GetService("Workspace")

-- ── State ────────────────────────────────────────────────────
local autoKickRunning    = false
local autoCollectRunning = false
local resetDelay         = 2.5
local collectRadius      = 50
local statusLabel        = nil
local collectStatusLabel = nil
local cachedBall         = nil
local cachedPercent      = nil
local kickCount          = 0
local orbsCollected      = 0

-- ── Helpers ──────────────────────────────────────────────────
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local function dbg(msg)
    print("[Manos Script] " .. tostring(msg))
end

-- ── UI Element Finder (Kick) ─────────────────────────────────
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

-- ── Position Validator ───────────────────────────────────────
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

-- ── Read current percent safely ─────────────────────────────
local function readPercent(label)
    local ok, val = pcall(function()
        return tonumber(label.Text:match("%d+"))
    end)
    if ok then return val end
    return nil
end

-- ── Orb Finder ──────────────────────────────────────────────
local function getOrbsFolder()
    local things = Workspace:FindFirstChild("__THINGS")
    if not things then
        dbg("__THINGS not found!")
        return nil
    end
    
    -- The soccer orbs are in SoccerYeetClient (dynamically changing children)
    local soccerYeet = things:FindFirstChild("SoccerYeetClient")
    if soccerYeet then
        dbg("Found SoccerYeetClient with " .. #soccerYeet:GetChildren() .. " children")
        -- Log what's inside on first scan
        for _, child in ipairs(soccerYeet:GetChildren()) do
            local pos = ""
            if child:IsA("BasePart") then
                pos = string.format(" @ (%.0f, %.0f, %.0f) Size: %.1f", child.Position.X, child.Position.Y, child.Position.Z, child.Size.Magnitude)
            elseif child:IsA("Model") then
                local p = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                if p then
                    pos = string.format(" @ (%.0f, %.0f, %.0f)", p.Position.X, p.Position.Y, p.Position.Z)
                end
            end
            dbg("  Yeet child: " .. child.Name .. " [" .. child.ClassName .. "]" .. pos)
        end
        return soccerYeet
    end
    
    -- Fallback: check Ornaments (also has collectibles in PS99)
    local ornaments = things:FindFirstChild("Ornaments")
    if ornaments and #ornaments:GetChildren() > 0 then
        dbg("Fallback: Using Ornaments folder (" .. #ornaments:GetChildren() .. " children)")
        return ornaments
    end
    
    -- Last resort: Orbs folder (sometimes populates late)
    local orbs = things:FindFirstChild("Orbs")
    if orbs and #orbs:GetChildren() > 0 then
        return orbs
    end
    
    dbg("No orb folder found with children!")
    return nil
end

local function getCharacterRoot()
    local char = localPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local orbsFolderCache = nil
local lastFolderScan = 0

local function collectOrbs()
    local hrp = getCharacterRoot()
    if not hrp then return 0 end
    
    -- Re-scan folder every 5 seconds (orbs appear/disappear fast)
    if not orbsFolderCache or not orbsFolderCache.Parent or (tick() - lastFolderScan > 5) then
        orbsFolderCache = getOrbsFolder()
        lastFolderScan = tick()
    end
    
    if not orbsFolderCache then
        return -1
    end
    
    local playerPos = hrp.Position
    local collected = 0
    
    -- Collect all children & descendants, safely checking for position
    local parts = {}
    local loggedOnce = false
    
    for _, obj in ipairs(orbsFolderCache:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Log first part's details for debugging
            if not loggedOnce then
                dbg("First BasePart found: " .. obj.Name .. " [" .. obj.ClassName .. "]")
                local ok, pos = pcall(function() return obj.Position end)
                if ok and pos then
                    dbg("  Position: " .. tostring(pos))
                else
                    dbg("  Position NOT accessible: " .. tostring(pos))
                end
                local ok2, cf = pcall(function() return obj.CFrame end)
                dbg("  CFrame accessible: " .. tostring(ok2))
                loggedOnce = true
            end
            
            local ok, pos = pcall(function() return obj.Position end)
            if ok and pos then
                local dist = (pos - playerPos).Magnitude
                if dist <= collectRadius then
                    table.insert(parts, {part = obj, dist = dist})
                end
            end
        end
    end
    
    -- If no BaseParts found, try with Models directly
    if #parts == 0 then
        for _, obj in ipairs(orbsFolderCache:GetChildren()) do
            -- Log what we're actually dealing with
            if not loggedOnce then
                dbg("Child: " .. obj.Name .. " [" .. obj.ClassName .. "]")
                for _, prop in ipairs({"Position", "CFrame", "PrimaryPart"}) do
                    local ok, val = pcall(function() return obj[prop] end)
                    dbg("  " .. prop .. ": ok=" .. tostring(ok) .. " val=" .. tostring(val))
                end
                loggedOnce = true
            end
            
            -- Try to get a position from Models
            if obj:IsA("Model") then
                local ok, cf = pcall(function() return obj:GetPivot() end)
                if ok and cf then
                    local pos = cf.Position
                    local dist = (pos - playerPos).Magnitude
                    if dist <= collectRadius then
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        if part then
                            table.insert(parts, {part = part, dist = dist, model = obj})
                        end
                    end
                end
            end
        end
    end
    
    -- Sort closest first
    table.sort(parts, function(a, b) return a.dist < b.dist end)
    
    -- Teleport to each one + fire touch interest
    for _, data in ipairs(parts) do
        if not autoCollectRunning then break end
        
        local orb = data.part
        if orb and orb.Parent then
            pcall(function()
                hrp.CFrame = orb.CFrame
            end)
            
            pcall(function()
                firetouchinterest(hrp, orb, 0)
                task.wait(0.05)
                firetouchinterest(hrp, orb, 1)
            end)
            
            collected = collected + 1
            task.wait(0.05)
        end
    end
    
    return collected
end

-- ── UI Library ───────────────────────────────────────────────
local Library = nil
local success, err = pcall(function()
    loadstring(game:HttpGet("https://scripts.wabisabi.mom/wabi-sabi-ui-lib.lua"))()
    Library = WabiSabi
end)

if not success or not Library then
    warn("[Manos Script] UI Library failed: " .. tostring(err))
    notify("AutoKick by Manos", "UI Library failed. Running in auto mode!", 7)
    autoKickRunning = true
else
    local Window = Library:CreateWindow({
        Title       = "Pet Sim 99 ⚽",
        SubTitle    = "by Manos",
        Size        = Vector2.new(520, 460),
        Resize      = true,
        ConfigName  = "ps99_worldcup",
        MinimizeKey = "Insert",
    })

    -- ── AutoKick Tab ─────────────────────────────────────────
    local kickTab     = Window:AddTab({ Title = "AutoKick", Icon = "bot" })
    local kickSection = kickTab:AddSection("AutoKick Settings")

    kickSection:AddToggle({
        Id       = "AutoKickToggle",
        Title    = "Auto Kick",
        Default  = false,
        Callback = function(state)
            autoKickRunning = state
            if not state then
                pcall(mouse1release)
                kickCount = 0
            end
        end,
    })

    kickSection:AddSlider({
        Id        = "ResetDelay",
        Title     = "Reset Delay (Seconds)",
        Min       = 1.0,
        Max       = 5.0,
        Default   = 2.5,
        Rounding  = 1,
        Callback  = function(value)
            resetDelay = value
        end
    })

    statusLabel = kickSection:AddParagraph({
        Title   = "Status",
        Content = "Idle — Toggle Auto Kick to start"
    })

    -- ── Auto Collect Tab ─────────────────────────────────────
    local collectTab     = Window:AddTab({ Title = "Auto Collect", Icon = "phosphor-coins-bold" })
    local collectSection = collectTab:AddSection("Auto Collect Orbs")

    collectSection:AddToggle({
        Id       = "AutoCollectToggle",
        Title    = "Auto Collect Orbs",
        Default  = false,
        Callback = function(state)
            autoCollectRunning = state
            if not state then
                orbsCollected = 0
            end
        end,
    })

    collectSection:AddSlider({
        Id        = "CollectRadius",
        Title     = "Collect Radius (studs)",
        Min       = 20,
        Max       = 200,
        Default   = 50,
        Rounding  = 0,
        Callback  = function(value)
            collectRadius = value
        end
    })

    collectStatusLabel = collectSection:AddParagraph({
        Title   = "Status",
        Content = "Idle — Toggle Auto Collect to start"
    })

    -- ── Credits Tab ──────────────────────────────────────────
    local creditsTab     = Window:AddTab({ Title = "Info", Icon = "phosphor-info-bold" })
    local creditsSection = creditsTab:AddSection("Credits")

    creditsSection:AddParagraph({
        Title   = "Made by",
        Content = "Manos ⚡\n\nFeatures:\n• Auto Kick (100% charge)\n• Auto Collect Orbs\n• Insert to toggle UI\n\nPowered by Matcha External + WabiSabi UI"
    })
    
    Library:Notify("Manos Script loaded! Press [Insert] to toggle UI", "Success", 5)
end

-- ── Status updaters ──────────────────────────────────────────
local function setStatus(text)
    if Library and statusLabel then
        pcall(function() statusLabel:SetContent(text) end)
    end
end

local function setCollectStatus(text)
    if Library and collectStatusLabel then
        pcall(function() collectStatusLabel:SetContent(text) end)
    end
end

-- ── Single Kick Cycle ────────────────────────────────────────
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
    
    -- Wait for bar to reset from previous kick
    local resetStart = tick()
    while autoKickRunning do
        if tick() - resetStart > 3 then break end
        local p = readPercent(percent)
        if p and p < 50 then
            dbg("Bar reset at " .. p .. "%")
            break
        end
        task.wait(0.01)
    end
    
    -- Monitor until 100%
    local startTime = tick()
    while autoKickRunning do
        if tick() - startTime > 6 then
            dbg("Timeout waiting for 100%!")
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
                dbg("Perfect kick #" .. kickCount .. " at 100%!")
                task.wait(resetDelay)
                return true
            end
        end
        task.wait(0.01)
    end
    
    pcall(mouse1release)
    return false
end

-- ── Main Kick Loop ───────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.1)
        if autoKickRunning then
            local ball, percent = getUIElements()
            
            if ball and percent then
                local ok, err = pcall(doKick, ball, percent)
                if not ok then
                    dbg("Kick error: " .. tostring(err))
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

-- ── Orb Collect Loop ─────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.3)
        if autoCollectRunning then
            local ok, result = pcall(collectOrbs)
            if ok then
                if result == -1 then
                    setCollectStatus("⚠️ Orbs folder not found! Make sure you're in the Soccer area.")
                    task.wait(3)
                elseif result > 0 then
                    orbsCollected = orbsCollected + result
                    setCollectStatus("✅ Collected " .. result .. " orbs! (Total: " .. orbsCollected .. ")")
                else
                    setCollectStatus("🔍 Scanning... No orbs nearby (Radius: " .. collectRadius .. " studs) | Total: " .. orbsCollected)
                end
            else
                dbg("Collect error: " .. tostring(result))
                setCollectStatus("⚠️ Error collecting orbs. Retrying...")
                task.wait(1)
            end
        else
            setCollectStatus("Idle — Toggle Auto Collect to start  |  Orbs: " .. orbsCollected)
        end
    end
end)

