--[[
    Optimized Mobile Auto Block + Anti-Bait + Hitbox Drag
    - Uses VirtualInputManager for Mobile Screen Taps
    - Squared Magnitude distance math for FPS optimization
    - Targeted Forsaken Killer folder scanning
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ⚙️ CONFIGURATION
local Config = {
    AutoBlock = true,
    HitboxVisualizer = false,
    DetectionRange = 15,
    ScanMode = false,
    FaceCheck = true,
    AntiBait = true,
    CommitRange = 8,
    HitboxDrag = true,
    DragDistance = 2.5,
}

-- Pre-calculate squared ranges for optimized math
local DETECT_SQ = Config.DetectionRange * Config.DetectionRange
local COMMIT_SQ = Config.CommitRange * Config.CommitRange

-- ✅ M1 WHITELIST
local M1_Whitelist = {
    ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true, ["136323728355613"] = true,
    ["115026634746636"] = true, ["84116622032112"]  = true, ["108907358619313"] = true, ["127793641088496"] = true,
    ["86174610237192"]  = true, ["95079963655241"]  = true, ["101199185291628"] = true, ["119942598489800"] = true,
    ["84307400688050"]  = true, ["113037804008732"] = true, ["105200830849301"] = true, ["75330693422988"]  = true,
    ["82221759983649"]  = true, ["109348678063422"] = true, ["81702359653578"]  = true, ["85853080745515"]  = true,
}

-- 🚫 ABILITY IDs (unblockable — still filtered out)
local AbilityAnimations = {
    ["126830014841198"] = true, ["126355327951215"] = true, ["121086746534252"] = true, ["18885909645"]     = true,
    ["98456918873918"]  = true, ["105458270463374"] = true, ["83829782357897"]  = true, ["125403313786645"] = true,
    ["118298475669935"] = true, ["82113744478546"]  = true,
}

local blockCooldown = false
local blockQueue = 0
local frameCounter = 0
local visualizers = {}

-- 📱 MOBILE INPUT (Screen Center Tap)
local function sendTouch()
    local vp = workspace.CurrentCamera.ViewportSize
    local x, y = vp.X / 2, vp.Y / 2
    VIM:SendTouchEvent(1, 1, x, y)
    task.wait(0.03)
    VIM:SendTouchEvent(1, 3, x, y)
end

-- 🧍 CAN BLOCK?
local function canBlock(hum)
    if not hum or hum.Health <= 0 then return false end
    local state = hum:GetState()
    return state ~= Enum.HumanoidStateType.Ragdoll 
       and state ~= Enum.HumanoidStateType.FallingDown 
       and state ~= Enum.HumanoidStateType.Physics 
       and state ~= Enum.HumanoidStateType.Dead
end

-- 👁️ VISUALIZER
local function manageVisualizer(char, root)
    if Config.HitboxVisualizer then
        local box = visualizers[char]
        if box and box.Parent then
            box.CFrame = root.CFrame
        else
            box = Instance.new("Part")
            box.Name = "HitboxViz"
            box.Size = root.Size
            box.CFrame = root.CFrame
            box.Anchored = true
            box.CanCollide = false
            box.CanQuery = false
            box.CanTouch = false
            box.Material = Enum.Material.ForceField
            box.Color = Color3.fromRGB(255, 50, 50)
            box.Transparency = 0.6
            box.Parent = workspace
            visualizers[char] = box
        end
    elseif visualizers[char] then
        visualizers[char]:Destroy()
        visualizers[char] = nil
    end
end

-- 🛡️ CORE BLOCK (Anti-Bait + Hitbox Drag)
local function doBlock(enemyRoot)
    if blockCooldown then
        blockQueue = math.min(blockQueue + 1, 1)
        return
    end

    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myChar or not canBlock(myHum) then return end

    blockCooldown = true
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")

    -- 🎯 HITBOX DRAG
    if Config.HitboxDrag and myRoot and enemyRoot then
        local diff = enemyRoot.Position - myRoot.Position
        local flatDistSq = diff.X^2 + diff.Z^2

        if flatDistSq > 0.0025 then -- > 0.05 squared
            local dir = Vector3.new(diff.X, 0, diff.Z).Unit
            myRoot.CFrame = myRoot.CFrame + (dir * Config.DragDistance)
            task.wait(0.015)
        end
    end

    -- 🛡️ TAP BLOCK
    sendTouch()

    task.wait(0.08)
    blockCooldown = false

    if blockQueue > 0 then
        blockQueue -= 1
        task.spawn(doBlock, enemyRoot)
    end
end

-- 👁️ SCAN ONE ENEMY (Squared Math)
local function scanEnemy(char, myRoot)
    local enemyRoot = char:FindFirstChild("HumanoidRootPart")
    local enemyHum = char:FindFirstChildOfClass("Humanoid")
    if not (enemyRoot and enemyHum) then return nil end

    manageVisualizer(char, enemyRoot)

    local diff = enemyRoot.Position - myRoot.Position
    local distSq = diff.X^2 + diff.Y^2 + diff.Z^2
    
    if distSq > DETECT_SQ then return nil end

    -- 🎣 ANTI-BAIT
    if Config.AntiBait and distSq > COMMIT_SQ then
        return nil
    end

    -- FACING CHECK
    if Config.FaceCheck then
        local toMe = -diff.Unit
        if enemyRoot.CFrame.LookVector:Dot(toMe) < 0.3 then return nil end
    end

    local animator = enemyHum:FindFirstChildOfClass("Animator")
    if not animator then return nil end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local id = tostring(track.Animation and track.Animation.AnimationId):match("%d+")
        if id then
            local isM1 = M1_Whitelist[id] or (not AbilityAnimations[id] and track.Length <= 1.2)
            
            if Config.ScanMode then
                local tag = M1_Whitelist[id] and " [M1✅]" or (AbilityAnimations[id] and " [ABILITY🚫]" or " [UNKNOWN❓]")
                print(string.format("[SCAN] %s -> %s (%.2fs)%s", char.Name, id, track.Length, tag))
            end

            if isM1 then
                return enemyRoot
            end
        end
    end
    return nil
end

-- 🔄 MAIN LOOP
RunService.Heartbeat:Connect(function()
    frameCounter += 1
    if frameCounter % 2 ~= 0 or not Config.AutoBlock then return end

    local char = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    -- Scan Forsaken Killers Folder instead of standard players
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if killersFolder then
        for _, killer in ipairs(killersFolder:GetChildren()) do
            if killer:IsA("Model") then
                local targetRoot = scanEnemy(killer, myRoot)
                if targetRoot then
                    task.spawn(doBlock, targetRoot)
                    break -- Only block one attacker per tick
                end
            end
        end
    end
end)

-- 🧹 CLEANUP
workspace.ChildRemoved:Connect(function(child)
    if visualizers[child] then
        visualizers[child]:Destroy()
        visualizers[child] = nil
    end
end)

-- 🖥️ UI (Kept Mobile Friendly)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBlockDrag"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 220, 0, 260)
Main.Position = UDim2.new(0.5, -110, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BackgroundTransparency = 0.15
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true

local C = Instance.new("UICorner", Main)
C.CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Mobile Autoblock"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local function makeToggle(y, label, key)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(0, 180, 0, 30)
    btn.Position = UDim2.new(0.5, -90, 0, y)
    btn.BackgroundColor3 = Config[key] and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(80, 20, 20)
    btn.Text = label .. ": " .. (Config[key] and "ON" or "OFF")
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    
    local cc = Instance.new("UICorner", btn)
    cc.CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        btn.Text = label .. ": " .. (Config[key] and "ON" or "OFF")
        btn.BackgroundColor3 = Config[key] and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(80, 20, 20)
        
        -- Update cached squared math if ranges are toggled/changed
        DETECT_SQ = Config.DetectionRange * Config.DetectionRange
        COMMIT_SQ = Config.CommitRange * Config.CommitRange

        if key == "HitboxVisualizer" and not Config[key] then
            for _, box in pairs(visualizers) do
                if box then box:Destroy() end
            end
            visualizers = {}
        end
    end)
end

makeToggle(40,  "Auto Block",        "AutoBlock")
makeToggle(78,  "Anti-Bait",         "AntiBait")
makeToggle(116, "Hitbox Drag",       "HitboxDrag")
makeToggle(154, "Hitbox Visualizer", "HitboxVisualizer")
makeToggle(192, "Facing Check",      "FaceCheck")
makeToggle(230, "Scanner",           "ScanMode")
