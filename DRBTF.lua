--[[
    Forsaken Hub — Godlike Edition
    ============================================================
    Features:
    [Auto Block]
    - Auto Block (animation blacklist + smart sound)
    - Auto Punch | Fling Punch | Punch Aimbot
    - Predictive Block (linear + angular)
    - Block TP
    - Auto 404 / Raging Pace Parry
    - Hitbox Modifier

    [Automation]
    - Auto Generator
    - Auto Farm (punch nearest killer)
    - Auto Collect Items
    - Anti AFK

    [Movement]
    - Speed Boost
    - Fly
    - Noclip
    - Infinite Jump
    - Teleport to Killer
    - Teleport to Generator

    [Visuals]
    - Killer ESP | Player ESP
    - Range Visualizer
    - Block Indicator
    - Full Bright

    [Server]
    - Server Hop
    - Rejoin
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local KF = workspace:WaitForChild("Players"):WaitForChild("Killers")
local RE = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Auto Block
    AutoBlock           = true,
    AutoPunch           = false,
    Range               = 12,

    PredictiveBlock     = true,
    PredictAhead        = 0.12,
    AngularPrediction   = true,
    AngularStrength     = 0.6,
    EdgeKillerDelay     = 2.5,

    PriorityMode        = "Nearest",

    BlockTP             = false,
    BlockTPRange        = 20,

    HitboxModifier      = false,
    HitboxRange         = 8,

    Auto404Parry        = false,
    AutoRagingPace      = false,

    FlingPunch          = false,
    FlingPower          = 10000,
    PunchAimbot         = false,
    AimPrediction       = 4,

    FacingMode          = "Loose",
    FacingDot           = -0.3,
    AdaptiveRange       = true,

    -- Automation
    AutoGenerator       = false,
    AutoFarm            = false,
    AutoCollect         = false,
    AntiAFK             = true,

    -- Movement
    SpeedBoost          = false,
    SpeedValue          = 32,
    Fly                 = false,
    FlySpeed            = 60,
    Noclip              = false,
    InfiniteJump        = false,

    -- Visuals
    KillerESP           = true,
    PlayerESP           = false,
    Visualizer          = true,
    BlockIndicator      = true,
    FullBright          = false,

    -- Debug
    Debug               = false,
}

-- ============================================================
-- KILLER PROFILES
-- ============================================================
local KillerProfiles = {
    ["c00lkidd"] = { Range = 10, FacingMode = "Strict" },
    ["C00lkidd"] = { Range = 10, FacingMode = "Strict" },
    ["1x1x1x1"]  = { Range = 11 },
    ["Jason"]    = { Range = 12 },
    ["Slasher"]  = { Range = 12 },
    ["JohnDoe"]  = { Range = 14 },
    ["Noli"]     = { Range = 12 },
    ["Sixer"]    = { Range = 12 },
    ["Azure"]    = { Range = 13 },
    ["Guest666"] = { Range = 11, FacingMode = "Strict" },
    ["Nosferatu"]= { Range = 13 },
}

-- ============================================================
-- ABILITY BLACKLIST
-- ============================================================
local ABILITY_IDS = {
    ["126830014841198"]=true, ["126355327951215"]=true, ["121086746534252"]=true,
    ["18885909645"]    =true, ["98456918873918"] =true, ["105458270463374"]=true,
    ["83829782357897"] =true, ["125403313786645"]=true, ["118298475669935"]=true,
    ["82113744478546"] =true, ["70371667919898"] =true, ["99135633258223"] =true,
    ["97167027849946"] =true, ["109230267448394"]=true, ["139835501033932"]=true,
    ["126896426760253"]=true, ["109667959938617"]=true, ["126681776859538"]=true,
    ["129976080405072"]=true, ["121293883585738"]=true, ["81639435858902"] =true,
    ["137314737492715"]=true, ["92173139187970"] =true, ["122709416391"] =true,
    ["879895330952"]   =true, ["71834552297085"] =true, ["805165833096"]   =true,
}

-- ============================================================
-- STATE
-- ============================================================
local state = {
    lastBlock = 0,
    blockQueue = 0,
    savedPosition = nil,
    edgeTimer = nil,
    killerVelocity = {},
    killerPrevPos = {},
    killerAngVel = {},
    killerPrevLook = {},
    killerPrevTime = {},
    activeProfile = nil,
    hitboxParts = {},
    flying = false,
    flyBV = nil,
    flyBG = nil,
    originalLighting = {},
    originalSpeed = 16,
    originalJump = 50,
}

-- ============================================================
-- UTILITIES
-- ============================================================
local function log(msg)
    if Config.Debug then print("[Godlike] " .. msg) end
end

local function numId(anim)
    if not anim then return nil end
    return tostring(anim.AnimationId):match("%d+")
end

local function getMyRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getMyHumanoid()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getAbilityBtn(name)
    local main = PG:FindFirstChild("MainUI")
    local cont = main and main:FindFirstChild("AbilityContainer")
    return cont and cont:FindFirstChild(name)
end

local function isBlockReady()
    local btn = getAbilityBtn("Block")
    local cd = btn and btn:FindFirstChild("CooldownTime")
    return cd and cd.Text == ""
end

local function isPunchReady()
    local btn = getAbilityBtn("Punch")
    local ch = btn and btn:FindFirstChild("Charges")
    return ch and ch.Text == "1"
end

local function canAct()
    local c = LP.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    local s = h:GetState()
    if s == Enum.HumanoidStateType.Dead
        or s == Enum.HumanoidStateType.Ragdoll
        or s == Enum.HumanoidStateType.FallingDown then
        return false
    end
    return true
end

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 3 })
    end)
end

-- ============================================================
-- FACING CHECK
-- ============================================================
local function getFacingDot()
    if Config.FacingMode == "Strict" then return -0.1 end
    return Config.FacingDot
end

local function isFacing(myRoot, targetRoot)
    local dx = myRoot.Position.X - targetRoot.Position.X
    local dy = myRoot.Position.Y - targetRoot.Position.Y
    local dz = myRoot.Position.Z - targetRoot.Position.Z
    local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mag < 0.01 then return true end
    local inv = 1 / mag
    local look = targetRoot.CFrame.LookVector
    local dot = look.X*(dx*inv) + look.Y*(dy*inv) + look.Z*(dz*inv)
    return dot > getFacingDot()
end

-- ============================================================
-- ADAPTIVE RANGE
-- ============================================================
local function getAdaptiveRange()
    if not Config.AdaptiveRange then return Config.Range end
    local ok, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if not ok then return Config.Range end
    if ping > 150 then return Config.Range + 2
    elseif ping > 100 then return Config.Range + 1
    end
    return Config.Range
end

-- ============================================================
-- PREDICTION ENGINE
-- ============================================================
local function updateKillerMotion(killer)
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local now = tick()

    local prevPos = state.killerPrevPos[killer]
    if prevPos and state.killerPrevTime[killer] then
        local dt = now - state.killerPrevTime[killer]
        if dt > 0.01 then
            state.killerVelocity[killer] = (hrp.Position - prevPos) / dt
        end
    end

    if Config.AngularPrediction then
        local prevLook = state.killerPrevLook[killer]
        if prevLook then
            local dot = math.clamp(prevLook:Dot(hrp.CFrame.LookVector), -1, 1)
            local angle = math.acos(dot)
            local crossY = prevLook:Cross(hrp.CFrame.LookVector).Y
            state.killerAngVel[killer] = (angle * (crossY >= 0 and 1 or -1)) / 0.016
        end
    end

    state.killerPrevPos[killer] = hrp.Position
    state.killerPrevLook[killer] = hrp.CFrame.LookVector
    state.killerPrevTime[killer] = now
end

local function predictPosition(killer, aheadTime)
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local basePos = hrp.Position
    local vel = state.killerVelocity[killer]
    if vel then basePos = basePos + vel * aheadTime end

    if Config.AngularPrediction and state.killerAngVel[killer] then
        local angVel = state.killerAngVel[killer]
        local right = hrp.CFrame.RightVector
        basePos = basePos + right * (angVel * Config.AngularStrength * aheadTime)
    end

    return basePos
end

-- ============================================================
-- REMOTE CALLS
-- ============================================================
local function fireBlock()
    RE:FireServer("UseActorAbility", { buffer.fromstring("\"Block\"") })
end

local function firePunch()
    RE:FireServer("UseActorAbility", { buffer.fromstring("\"Punch\"") })
end

local function fire404()
    RE:FireServer("UseActorAbility", { buffer.fromstring("\"404Error\"") })
end

local function fireRagingPace()
    RE:FireServer("UseActorAbility", { buffer.fromstring("\"RagingPace\"") })
end

-- ============================================================
-- BLOCK TP
-- ============================================================
local function savePosition()
    local root = getMyRoot()
    if root then state.savedPosition = root.CFrame end
end

local function restorePosition()
    local root = getMyRoot()
    if root and state.savedPosition then
        root.CFrame = state.savedPosition
        state.savedPosition = nil
    end
end

-- ============================================================
-- HITBOX MODIFIER
-- ============================================================
local function applyHitboxModifier()
    if not Config.HitboxModifier then
        for _, part in pairs(state.hitboxParts) do
            if part and part.Parent then part:Destroy() end
        end
        state.hitboxParts = {}
        return
    end

    local myRoot = getMyRoot()
    if not myRoot then return end

    for _, killer in ipairs(KF:GetChildren()) do
        local er = killer:FindFirstChild("HumanoidRootPart")
        if er and (er.Position - myRoot.Position).Magnitude <= Config.HitboxRange then
            if not state.hitboxParts[killer] then
                local part = Instance.new("Part")
                part.Name = "HitboxExtend"
                part.Size = Vector3.new(4, 4, 4)
                part.Anchored = true
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
                part.Transparency = 1
                part.Parent = workspace
                state.hitboxParts[killer] = part
            end
            local part = state.hitboxParts[killer]
            if part then part.CFrame = CFrame.new((myRoot.Position + er.Position) / 2) end
        else
            if state.hitboxParts[killer] then
                state.hitboxParts[killer]:Destroy()
                state.hitboxParts[killer] = nil
            end
        end
    end
end

-- ============================================================
-- AUTO PARRY
-- ============================================================
local lastParry = 0
local function tryAutoParry()
    local now = tick()
    if now - lastParry < 2 then return end

    local myRoot = getMyRoot()
    if not myRoot then return end

    for _, killer in ipairs(KF:GetChildren()) do
        local er = killer:FindFirstChild("HumanoidRootPart")
        if er and (er.Position - myRoot.Position).Magnitude <= 6 then
            local eh = killer:FindFirstChildOfClass("Humanoid")
            local animator = eh and eh:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local id = numId(track.Animation)
                    if id and not ABILITY_IDS[id] then
                        if Config.Auto404Parry then
                            fire404()
                            lastParry = now
                        elseif Config.AutoRagingPace then
                            fireRagingPace()
                            lastParry = now
                        end
                        return
                    end
                end
            end
        end
    end
end

-- ============================================================
-- TARGETING
-- ============================================================
local function selectTarget(killers, myRoot)
    if #killers == 0 then return nil end

    local best, bestScore = nil, math.huge
    for _, killer in ipairs(killers) do
        local er = killer:FindFirstChild("HumanoidRootPart")
        if er then
            local dist = (er.Position - myRoot.Position).Magnitude
            local score = dist

            if Config.PriorityMode == "LowestHP" then
                local eh = killer:FindFirstChildOfClass("Humanoid")
                if eh then score = eh.Health end
            elseif Config.PriorityMode == "HighestThreat" then
                local vel = state.killerVelocity[killer]
                local approaching = 0
                if vel then
                    local toMe = (myRoot.Position - er.Position).Unit
                    approaching = vel:Dot(toMe)
                end
                score = dist - approaching * 5
            end

            if score < bestScore then
                bestScore = score
                best = killer
            end
        end
    end
    return best
end

-- ============================================================
-- CORE BLOCK
-- ============================================================
local function tryBlock(killer, isPredictive)
    if not canAct() then return end
    if not isBlockReady() then return end

    local myRoot = getMyRoot()
    if not myRoot then return end

    -- Block TP
    if Config.BlockTP and killer then
        local hrp = killer:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - myRoot.Position).Magnitude <= Config.BlockTPRange then
            savePosition()
            local frontPos = hrp.Position + hrp.CFrame.LookVector * 2
            myRoot.CFrame = CFrame.new(frontPos, hrp.Position)
            task.wait(0.02)
        end
    end

    fireBlock()

    -- Block indicator
    if Config.BlockIndicator then
        local indicator = Instance.new("Part")
        indicator.Name = "BlockIndicator"
        indicator.Size = Vector3.new(3, 3, 3)
        indicator.Anchored = true
        indicator.CanCollide = false
        indicator.CanQuery = false
        indicator.CanTouch = false
        indicator.Material = Enum.Material.Neon
        indicator.Color = Color3.fromRGB(0, 255, 100)
        indicator.Transparency = 0.3
        indicator.CFrame = myRoot.CFrame
        indicator.Parent = workspace
        TweenService:Create(indicator, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(6, 6, 6) }):Play()
        game:GetService("Debris"):AddItem(indicator, 0.3)
    end

    -- Auto Punch
    if Config.AutoPunch and isPunchReady() then
        task.wait(0.04)

        if Config.FlingPunch and killer then
            local er = killer:FindFirstChild("HumanoidRootPart")
            if er then
                local myHrp = getMyRoot()
                if myHrp then
                    myHrp.Velocity = (er.Position - myHrp.Position).Unit * Config.FlingPower + Vector3.new(0, Config.FlingPower * 0.5, 0)
                end
            end
        end

        if Config.PunchAimbot and killer then
            local er = killer:FindFirstChild("HumanoidRootPart")
            local myHrp = getMyRoot()
            if er and myHrp then
                local predicted = er.Position + er.CFrame.LookVector * Config.AimPrediction
                myHrp.CFrame = CFrame.lookAt(myHrp.Position, predicted)
            end
        end

        firePunch()
    end

    if Config.BlockTP and state.savedPosition then
        task.wait(0.04)
        restorePosition()
    end
end

-- ============================================================
-- DETECTION
-- ============================================================
local function isM1(track)
    local id = numId(track.Animation)
    if not id then return false end
    return not ABILITY_IDS[id]
end

local function scanKiller(killer)
    local myRoot = getMyRoot()
    if not myRoot then return end

    local er = killer:FindFirstChild("HumanoidRootPart")
    local eh = killer:FindFirstChildOfClass("Humanoid")
    if not er or not eh then return end

    local range = getAdaptiveRange()
    local killerPos = er.Position
    if Config.PredictiveBlock then
        local predicted = predictPosition(killer, Config.PredictAhead)
        if predicted then killerPos = predicted end
    end

    if (killerPos - myRoot.Position).Magnitude > range then return end
    if not isFacing(myRoot, er) then return end

    local animator = eh:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if isM1(track) then
            tryBlock(killer, Config.PredictiveBlock)
            return
        end
    end
end

-- Sound hook
local function hookKillerSound(sound)
    if not sound:IsA("Sound") then return end
    sound.Played:Connect(function()
        if not Config.AutoBlock then return end
        local model = sound:FindFirstAncestorOfClass("Model")
        if not model or model.Parent ~= KF then return end
        if sound:FindFirstAncestor("Abilities") or
           sound:FindFirstAncestor("Effects") or
           sound:FindFirstAncestor("Projectiles") then return end

        local myRoot = getMyRoot()
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not myRoot or not hrp then return end
        if (hrp.Position - myRoot.Position).Magnitude <= getAdaptiveRange() then
            tryBlock(model, false)
        end
    end)
end

for _, d in ipairs(KF:GetDescendants()) do
    if d:IsA("Sound") then hookKillerSound(d) end
end
KF.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then hookKillerSound(d) end
end)

-- ============================================================
-- MAIN HEARTBEAT LOOP
-- ============================================================
RunService.Heartbeat:Connect(function()
    -- Motion tracking
    if Config.AutoBlock or Config.PredictiveBlock then
        for _, k in ipairs(KF:GetChildren()) do
            if k:IsA("Model") then updateKillerMotion(k) end
        end
    end

    -- Auto Block
    if Config.AutoBlock then
        local myRoot = getMyRoot()
        if myRoot then
            local validTargets = {}
            for _, k in ipairs(KF:GetChildren()) do
                if k:IsA("Model") then
                    local er = k:FindFirstChild("HumanoidRootPart")
                    if er and (er.Position - myRoot.Position).Magnitude <= getAdaptiveRange() then
                        table.insert(validTargets, k)
                    end
                end
            end

            if #validTargets > 0 then
                local target = selectTarget(validTargets, myRoot)
                if target then scanKiller(target) end
            end
        end
    end

    -- Edge Blocking
    if Config.AutoBlock and Config.PredictiveBlock then
        local myRoot = getMyRoot()
        if myRoot then
            local inRange = false
            for _, k in ipairs(KF:GetChildren()) do
                local er = k:FindFirstChild("HumanoidRootPart")
                if er and (er.Position - myRoot.Position).Magnitude <= getAdaptiveRange() then
                    inRange = true; break
                end
            end

            if inRange then
                if not state.edgeTimer then
                    state.edgeTimer = tick()
                elseif tick() - state.edgeTimer >= Config.EdgeKillerDelay then
                    local validTargets = {}
                    for _, k in ipairs(KF:GetChildren()) do
                        local er = k:FindFirstChild("HumanoidRootPart")
                        if er and (er.Position - myRoot.Position).Magnitude <= getAdaptiveRange() then
                            table.insert(validTargets, k)
                        end
                    end
                    if #validTargets > 0 then
                        local target = selectTarget(validTargets, myRoot)
                        if target then tryBlock(target, true) end
                    end
                    state.edgeTimer = nil
                end
            else
                state.edgeTimer = nil
            end
        end
    end

    applyHitboxModifier()

    if Config.Auto404Parry or Config.AutoRagingPace then tryAutoParry() end

    -- Auto Generator
    if Config.AutoGenerator then
        local myRoot = getMyRoot()
        if myRoot then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("generator") and obj:IsA("Model") then
                    local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - myRoot.Position).Magnitude > 5 then
                        myRoot.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                    end
                end
            end
        end
    end

    -- Auto Farm
    if Config.AutoFarm then
        local myRoot = getMyRoot()
        local hum = getMyHumanoid()
        if myRoot and hum then
            local nearest, nearestDist = nil, math.huge
            for _, k in ipairs(KF:GetChildren()) do
                local er = k:FindFirstChild("HumanoidRootPart")
                if er then
                    local d = (er.Position - myRoot.Position).Magnitude
                    if d < nearestDist then
                        nearest, nearestDist = er, d
                    end
                end
            end
            if nearest and nearestDist < 15 then
                hum:MoveTo(nearest.Position)
                if isPunchReady() then firePunch() end
            end
        end
    end

    -- Auto Collect
    if Config.AutoCollect then
        local myRoot = getMyRoot()
        if myRoot then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("item") or obj.Name:lower():find("pickup")) then
                    if (obj.Position - myRoot.Position).Magnitude < 30 then
                        myRoot.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end

    -- Noclip
    if Config.Noclip and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- Fly
    if Config.Fly and not state.flying then
        state.flying = true
        local hrp = getMyRoot()
        if hrp then
            state.flyBV = Instance.new("BodyVelocity")
            state.flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            state.flyBV.Velocity = Vector3.zero
            state.flyBV.Parent = hrp

            state.flyBG = Instance.new("BodyGyro")
            state.flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            state.flyBG.P = 1000
            state.flyBG.Parent = hrp
        end
    elseif not Config.Fly and state.flying then
        state.flying = false
        if state.flyBV then state.flyBV:Destroy(); state.flyBV = nil end
        if state.flyBG then state.flyBG:Destroy(); state.flyBG = nil end
    end

    if Config.Fly and state.flyBV and state.flyBG then
        local hrp = getMyRoot()
        local cam = workspace.CurrentCamera
        if hrp and cam then
            local move = Vector3.zero
            local hum = getMyHumanoid()
            if hum then
                local dir = hum.MoveDirection
                move = cam.CFrame.LookVector * dir.Z + cam.CFrame.RightVector * dir.X
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            end
            state.flyBV.Velocity = move * Config.FlySpeed
            state.flyBG.CFrame = cam.CFrame
        end
    end

    -- Speed Boost
    if Config.SpeedBoost then
        local hum = getMyHumanoid()
        if hum and hum.WalkSpeed ~= Config.SpeedValue then
            hum.WalkSpeed = Config.SpeedValue
        end
    end
end)

-- ============================================================
-- INFINITE JUMP
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = getMyHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================================
-- FULL BRIGHT
-- ============================================================
local function applyFullBright()
    if Config.FullBright then
        if not state.originalLighting.Brightness then
            state.originalLighting.Brightness = Lighting.Brightness
            state.originalLighting.ClockTime = Lighting.ClockTime
            state.originalLighting.FogEnd = Lighting.FogEnd
        end
        Lighting.Brightness = 5
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
    else
        if state.originalLighting.Brightness then
            Lighting.Brightness = state.originalLighting.Brightness
            Lighting.ClockTime = state.originalLighting.ClockTime
            Lighting.FogEnd = state.originalLighting.FogEnd
            state.originalLighting = {}
        end
    end
end

-- ============================================================
-- KILLER ESP
-- ============================================================
local function addKillerESP(killer)
    if not killer:IsA("Model") or killer:FindFirstChild("AB_ESP") then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hl = Instance.new("Highlight")
    hl.Name = "AB_ESP"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = killer
    hl.Parent = killer

    local bb = Instance.new("BillboardGui")
    bb.Name = "AB_ESP_BB"
    bb.Size = UDim2.new(0, 140, 0, 40)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = killer

    local lbl = Instance.new("TextLabel")
    lbl.Name = "AB_ESP_Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    lbl.TextStrokeTransparency = 0.3
    lbl.Text = killer.Name
    lbl.Parent = bb
end

local function removeESP(obj)
    local a = obj:FindFirstChild("AB_ESP");      if a then a:Destroy() end
    local b = obj:FindFirstChild("AB_ESP_BB");   if b then b:Destroy() end
end

local function refreshKillerESP()
    for _, k in ipairs(KF:GetChildren()) do
        if Config.KillerESP then addKillerESP(k) else removeESP(k) end
    end
end

KF.ChildAdded:Connect(function(k)
    if Config.KillerESP then task.wait(0.15); addKillerESP(k) end
end)
KF.ChildRemoved:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    if not Config.KillerESP then return end
    local myRoot = getMyRoot()
    if not myRoot then return end
    for _, k in ipairs(KF:GetChildren()) do
        local bb = k:FindFirstChild("AB_ESP_BB")
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if bb and bb:FindFirstChild("AB_ESP_Label") and hrp then
            local d = (hrp.Position - myRoot.Position).Magnitude
            bb.AB_ESP_Label.Text = string.format("%s  [%d]", k.Name, math.floor(d))
        end
    end
end)

-- ============================================================
-- PLAYER ESP
-- ============================================================
local function addPlayerESP(plr)
    if plr == LP or not plr.Character then return end
    if plr.Character:FindFirstChild("PLAYER_ESP") then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hl = Instance.new("Highlight")
    hl.Name = "PLAYER_ESP"
    hl.FillColor = Color3.fromRGB(80, 200, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = plr.Character
    hl.Parent = plr.Character

    local bb = Instance.new("BillboardGui")
    bb.Name = "PLAYER_ESP_BB"
    bb.Size = UDim2.new(0, 120, 0, 30)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = plr.Character

    local lbl = Instance.new("TextLabel")
    lbl.Name = "PLAYER_ESP_Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextColor3 = Color3.fromRGB(120, 220, 255)
    lbl.TextStrokeTransparency = 0.4
    lbl.Text = plr.Name
    lbl.Parent = bb
end

local function removePlayerESP(plr)
    if plr.Character then
        local a = plr.Character:FindFirstChild("PLAYER_ESP");     if a then a:Destroy() end
        local b = plr.Character:FindFirstChild("PLAYER_ESP_BB");  if b then b:Destroy() end
    end
end

local function refreshPlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            if Config.PlayerESP then addPlayerESP(p) else removePlayerESP(p) end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if Config.PlayerESP then p.CharacterAdded:Connect(function() task.wait(0.5); addPlayerESP(p) end) end
end)
Players.PlayerRemoving:Connect(removePlayerESP)

-- ============================================================
-- RANGE VISUALIZER
-- ============================================================
local vizPart
RunService.Heartbeat:Connect(function()
    if Config.Visualizer then
        local myRoot = getMyRoot()
        if myRoot then
            if not vizPart or not vizPart.Parent then
                vizPart = Instance.new("Part")
                vizPart.Name = "AB_RangeViz"
                vizPart.Shape = Enum.PartType.Cylinder
                vizPart.Anchored = true
                vizPart.CanCollide = false
                vizPart.CanQuery = false
                vizPart.CanTouch = false
                vizPart.Material = Enum.Material.ForceField
                vizPart.Color = Color3.fromRGB(90, 170, 255)
                vizPart.Transparency = 0.75
                vizPart.Parent = workspace
            end
            local range = getAdaptiveRange()
            vizPart.Size = Vector3.new(0.2, range * 2, range * 2)
            vizPart.CFrame = myRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))
        end
    elseif vizPart then
        vizPart:Destroy()
        vizPart = nil
    end
end)

-- ============================================================
-- OBSIDIAN UI
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Forsaken Hub",
    Footer = "Godlike Edition",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    AutoBlock   = Window:AddTab("Auto Block", "shield"),
    Prediction  = Window:AddTab("Prediction", "crosshair"),
    Combat      = Window:AddTab("Combat", "sword"),
    Automation  = Window:AddTab("Automation", "zap"),
    Movement    = Window:AddTab("Movement", "activity"),
    Visuals     = Window:AddTab("Visuals", "eye"),
    Server      = Window:AddTab("Server", "globe"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ============================================================
-- AUTO BLOCK TAB
-- ============================================================
local ABLeft = Tabs.AutoBlock:AddLeftGroupbox("Core")
local ABRight = Tabs.AutoBlock:AddRightGroupbox("Advanced")

ABLeft:AddToggle("AutoBlock", {
    Text = "Auto Block",
    Default = Config.AutoBlock,
    Tooltip = "Blocks any animation that isn't a known ability",
    Callback = function(v) Config.AutoBlock = v end,
})

ABLeft:AddToggle("AutoPunch", {
    Text = "Auto Punch",
    Default = Config.AutoPunch,
    Tooltip = "Punches after a successful block",
    Callback = function(v) Config.AutoPunch = v end,
})

ABLeft:AddSlider("Range", {
    Text = "Detection Range",
    Default = Config.Range,
    Min = 5, Max = 25, Rounding = 0,
    Tooltip = "Guesting Hub recommends 10-13",
    Callback = function(v) Config.Range = v end,
})

ABLeft:AddDropdown("FacingMode", {
    Values = {"Loose", "Strict"},
    Default = Config.FacingMode,
    Text = "Facing Mode",
    Tooltip = "Loose = wide cone, Strict = narrow",
    Callback = function(v) Config.FacingMode = v end,
})

ABRight:AddToggle("BlockTP", {
    Text = "Block Teleport",
    Default = Config.BlockTP,
    Tooltip = "TP to killer on attack, block, punch, TP back",
    Callback = function(v) Config.BlockTP = v end,
})

ABRight:AddToggle("AdaptiveRange", {
    Text = "Adaptive Range",
    Default = Config.AdaptiveRange,
    Tooltip = "Auto-adjusts range based on ping",
    Callback = function(v) Config.AdaptiveRange = v end,
})

ABRight:AddDropdown("PriorityMode", {
    Values = {"Nearest", "LowestHP", "HighestThreat"},
    Default = Config.PriorityMode,
    Text = "Target Priority",
    Callback = function(v) Config.PriorityMode = v end,
})

ABRight:AddToggle("HitboxModifier", {
    Text = "Hitbox Modifier",
    Default = Config.HitboxModifier,
    Tooltip = "Extends your hitbox toward killers",
    Callback = function(v) Config.HitboxModifier = v end,
})

ABRight:AddSlider("HitboxRange", {
    Text = "Hitbox Range",
    Default = Config.HitboxRange,
    Min = 3, Max = 15, Rounding = 0,
    Callback = function(v) Config.HitboxRange = v end,
})

-- ============================================================
-- PREDICTION TAB
-- ============================================================
local PLeft = Tabs.Prediction:AddLeftGroupbox("Predictive Block")
local PRight = Tabs.Prediction:AddRightGroupbox("Tuning")

PLeft:AddToggle("PredictiveBlock", {
    Text = "Predictive Auto Block",
    Default = Config.PredictiveBlock,
    Callback = function(v) Config.PredictiveBlock = v end,
})

PLeft:AddToggle("AngularPrediction", {
    Text = "Angular Prediction",
    Default = Config.AngularPrediction,
    Tooltip = "Predicts based on killer's turning rate",
    Callback = function(v) Config.AngularPrediction = v end,
})

PRight:AddSlider("PredictAhead", {
    Text = "Predict Ahead (ms)",
    Default = Config.PredictAhead * 1000,
    Min = 50, Max = 300, Rounding = 0,
    Callback = function(v) Config.PredictAhead = v / 1000 end,
})

PRight:AddSlider("AngularStrength", {
    Text = "Angular Strength ×10",
    Default = Config.AngularStrength * 10,
    Min = 1, Max = 20, Rounding = 0,
    Callback = function(v) Config.AngularStrength = v / 10 end,
})

PRight:AddSlider("EdgeKillerDelay", {
    Text = "Edge Killer Delay (s ×10)",
    Default = Config.EdgeKillerDelay * 10,
    Min = 5, Max = 50, Rounding = 0,
    Callback = function(v) Config.EdgeKillerDelay = v / 10 end,
})

-- ============================================================
-- COMBAT TAB
-- ============================================================
local CLeft = Tabs.Combat:AddLeftGroupbox("Punch")
local CRight = Tabs.Combat:AddRightGroupbox("Parry")

CLeft:AddToggle("FlingPunch", {
    Text = "Fling Punch",
    Default = Config.FlingPunch,
    Callback = function(v) Config.FlingPunch = v end,
})

CLeft:AddToggle("PunchAimbot", {
    Text = "Punch Aimbot",
    Default = Config.PunchAimbot,
    Callback = function(v) Config.PunchAimbot = v end,
})

CLeft:AddSlider("AimPrediction", {
    Text = "Aim Prediction ×10",
    Default = Config.AimPrediction * 10,
    Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) Config.AimPrediction = v / 10 end,
})

CRight:AddToggle("Auto404Parry", {
    Text = "Auto 404 Parry",
    Default = Config.Auto404Parry,
    Callback = function(v) Config.Auto404Parry = v end,
})

CRight:AddToggle("AutoRagingPace", {
    Text = "Auto Raging Pace Parry",
    Default = Config.AutoRagingPace,
    Callback = function(v) Config.AutoRagingPace = v end,
})

-- ============================================================
-- AUTOMATION TAB
-- ============================================================
local AuLeft = Tabs.Automation:AddLeftGroupbox("Auto Tasks")
local AuRight = Tabs.Automation:AddRightGroupbox("Passive")

AuLeft:AddToggle("AutoGenerator", {
    Text = "Auto Generator",
    Default = Config.AutoGenerator,
    Tooltip = "Teleports to active generators",
    Callback = function(v) Config.AutoGenerator = v end,
})

AuLeft:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = Config.AutoFarm,
    Tooltip = "Walks to nearest killer and punches",
    Callback = function(v) Config.AutoFarm = v end,
})

AuLeft:AddToggle("AutoCollect", {
    Text = "Auto Collect Items",
    Default = Config.AutoCollect,
    Tooltip = "Picks up nearby coins/items",
    Callback = function(v) Config.AutoCollect = v end,
})

AuRight:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = Config.AntiAFK,
    Tooltip = "Prevents idle kick",
    Callback = function(v) Config.AntiAFK = v end,
})

-- Anti AFK loop
if Config.AntiAFK then
    LP.Idled:Connect(function()
        if Config.AntiAFK then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    end)
end

-- ============================================================
-- MOVEMENT TAB
-- ============================================================
local MLeft = Tabs.Movement:AddLeftGroupbox("Movement")
local MRight = Tabs.Movement:AddRightGroupbox("Values")

MLeft:AddToggle("SpeedBoost", {
    Text = "Speed Boost",
    Default = Config.SpeedBoost,
    Callback = function(v)
        Config.SpeedBoost = v
        if not v then
            local hum = getMyHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

MLeft:AddToggle("Fly", {
    Text = "Fly",
    Default = Config.Fly,
    Callback = function(v) Config.Fly = v end,
})

MLeft:AddToggle("Noclip", {
    Text = "Noclip",
    Default = Config.Noclip,
    Callback = function(v) Config.Noclip = v end,
})

MLeft:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = Config.InfiniteJump,
    Callback = function(v) Config.InfiniteJump = v end,
})

MRight:AddSlider("SpeedValue", {
    Text = "Speed Value",
    Default = Config.SpeedValue,
    Min = 16, Max = 100, Rounding = 0,
    Callback = function(v) Config.SpeedValue = v end,
})

MRight:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = Config.FlySpeed,
    Min = 20, Max = 200, Rounding = 0,
    Callback = function(v) Config.FlySpeed = v end,
})

-- Teleport buttons
local TPRight = Tabs.Movement:AddRightGroupbox("Teleport")

TPRight:AddButton("Teleport to Killer", function()
    local myRoot = getMyRoot()
    if not myRoot then return end
    local nearest, nearestDist = nil, math.huge
    for _, k in ipairs(KF:GetChildren()) do
        local er = k:FindFirstChild("HumanoidRootPart")
        if er then
            local d = (er.Position - myRoot.Position).Magnitude
            if d < nearestDist then nearest, nearestDist = er, d end
        end
    end
    if nearest then
        myRoot.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0))
        notify("Teleport", "Teleported to killer", 2)
    else
        notify("Teleport", "No killer found", 2)
    end
end)

TPRight:AddButton("Teleport to Generator", function()
    local myRoot = getMyRoot()
    if not myRoot then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("generator") and obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                myRoot.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                notify("Teleport", "Teleported to generator", 2)
                return
            end
        end
    end
    notify("Teleport", "No generator found", 2)
end)

-- ============================================================
-- VISUALS TAB
-- ============================================================
local VisLeft = Tabs.Visuals:AddLeftGroupbox("ESP")
local VisRight = Tabs.Visuals:AddRightGroupbox("Indicators")

VisLeft:AddToggle("KillerESP", {
    Text = "Killer ESP",
    Default = Config.KillerESP,
    Callback = function(v)
        Config.KillerESP = v
        if v then refreshKillerESP()
        else for _, k in ipairs(KF:GetChildren()) do removeESP(k) end end
    end,
})

VisLeft:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = Config.PlayerESP,
    Callback = function(v)
        Config.PlayerESP = v
        if v then refreshPlayerESP()
        else for _, p in ipairs(Players:GetPlayers()) do removePlayerESP(p) end end
    end,
})

VisLeft:AddToggle("Visualizer", {
    Text = "Range Visualizer",
    Default = Config.Visualizer,
    Callback = function(v) Config.Visualizer = v end,
})

VisRight:AddToggle("BlockIndicator", {
    Text = "Block Indicator",
    Default = Config.BlockIndicator,
    Tooltip = "Shows a green flash when blocking",
    Callback = function(v) Config.BlockIndicator = v end,
})

VisRight:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = Config.FullBright,
    Tooltip = "Brightens the entire map",
    Callback = function(v)
        Config.FullBright = v
        applyFullBright()
    end,
})

-- ============================================================
-- SERVER TAB
-- ============================================================
local SLeft = Tabs.Server:AddLeftGroupbox("Server")

SLeft:AddButton("Server Hop", function()
    local servers = {}
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end
    end)
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LP)
    else
        notify("Server Hop", "No servers found", 2)
    end
end)

SLeft:AddButton("Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LP)
end)

SLeft:AddLabel("Server ID: " .. tostring(game.JobId))

-- ============================================================
-- UI SETTINGS TAB
-- ============================================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Settings", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value) Library.ShowCustomCursor = Value end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value) Library:SetNotifySide(Value) end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        Library:SetDPIScale(tonumber(Value))
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
})

MenuGroup:AddButton("Unload Script", function() Library:Unload() end)

-- ============================================================
-- THEME + SAVE MANAGER
-- ============================================================
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("forsaken_hub")
SaveManager:SetFolder("forsaken_hub/games")
SaveManager:SetSubFolder("Forsaken")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- ============================================================
-- INIT
-- ============================================================
refreshKillerESP()
refreshPlayerESP()
print("[Forsaken Hub] loaded — RightShift toggles UI")
notify("Forsaken Hub", "Godlike Edition loaded", 4)
