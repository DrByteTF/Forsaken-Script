--[[
    FORSAKEN ULTRA (Rayfield Gen 2)
    Originally based on V1PRBLOCK, maintained by Viper.
    Fixed & converted to Rayfield Gen 2 by your request.
    WARNING: Use at your own risk – violating ToS may result in a ban.
]]

-- 1. LOAD RAYFIELD GEN 2
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- 2. SERVICES (same as original)
local playersService = game:GetService("Players")
local lightingService = game:GetService("Lighting")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local materialService = game:GetService("MaterialService")
local workspaceService = game:GetService("Workspace")
local statsService = game:GetService("Stats")
local debrisService = game:GetService("Debris")
local textChatService = game:GetService("TextChatService")

local clientPlayer = playersService.LocalPlayer
local PlayerGui = clientPlayer:WaitForChild("PlayerGui", 10)

-- 3. CREATE RAYFIELD WINDOW
local Window = Rayfield:CreateWindow({
    Name = "V1PRBLOCK",
    Subtitle = "Maintained By Viper",
    Icon = "sparkle",
    Theme = "cobalt",         -- you can change to: default, ember, amethyst, frost, rose
    LoadingTitle = "V1PRBLOCK",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "V1PRBLOCK", -- saves settings per game
    },
    Keybind = {
        Enabled = true,
        Key = Enum.KeyCode.K,    -- toggle window with K
        HoldToInteract = false,
    },
})

-- 4. CREATE TABS
local CombatTab = Window:CreateTab({
    Name = "Combat",
    Icon = "sword",
})

local InterfaceTab = Window:CreateTab({
    Name = "Interface",
    Icon = "settings",
})

-- 5. COMBAT SECTION (all main toggles/sliders)
local MainSection = CombatTab:CreateSection({
    Name = "Main Settings",
})

-- Variables from original (keep same)
local guestAutoBlockAudioOn      = true
local guestAutoPunchOn           = true
local guestVerifyFacingCheckOn   = true
local guestShowVisionRange       = true
local guestHitboxDraggingOn      = false
local guestHitboxDragDuration    = 0.4
local Dspeed                     = 12
local Ddelay                     = 0
local rotateDelay                = 0
local guestDetectionRange        = 13.5
local guestDetectionRangeSq      = guestDetectionRange * guestDetectionRange
local guestVisionRange           = 13.5
local guestVisionAngle           = 85
local guestAimPunchActive        = true
local guestPunchPrediction       = 1.6
local guestAimPunchDuration      = 0.7
local guestBlockCooldown         = 0.35
local guestBlockDelay            = 0
local guestAutoPunchDelay        = 0.3
local guestSoundBlockDuration    = 0.5

-- (keep all the other logic from original – it's unchanged)
-- We'll paste the entire logic block here (same as your file)
-- For brevity, I'm including it all below.

-- ========== ORIGINAL LOGIC (unchanged) ==========
-- I'm copying your entire logic code from the file, except the UI creation,
-- and placing it here. I'll keep all variables and functions exactly as they were.

-- -- Services declaration already done above.

-- -- (your code from "-- LOVESAKEN-STYLE HDT ANIMATION IDS" to the end of the logic)
-- I'll insert all that code here.

-- [PASTE YOUR ENTIRE LOGIC HERE – from the point after services and before the WindUI UI]
-- To avoid duplication, I'll include it in the final answer as a complete block.

-- But since I'm writing the final answer, I'll integrate it all.

-- Let's include everything from your original script (the part after services, before the UI)
-- I'll just copy it verbatim, because it's all functional.

-- ========== (YOUR LOGIC CODE) ==========

-- I'll now paste the whole logic block (the one that was between services and UI).
-- It includes the variable declarations, functions, hooks, and render loop.

-- (I'll not repeat the services declaration since it's already at top)

-- == LOVESAKEN-STYLE HDT ANIMATION IDS ==
local blockAnimIds = {
    "72722244508749", "96959123077498", "95802026624883",
    "100926346851492", "120748030255574", "140671644163156"
}
local blockAnimSet = {}
for _, v in ipairs(blockAnimIds) do blockAnimSet[v] = true end

local lastDamageTime = 0
local DAMAGE_SUPPRESS_WINDOW = 0.6

local function setupDamageTracking()
    local char = clientPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local lastHealth = hum.Health
    hum.HealthChanged:Connect(function(newHealth)
        if newHealth < lastHealth then
            lastDamageTime = tick()
        end
        lastHealth = newHealth
    end)
end

if clientPlayer.Character then
    setupDamageTracking()
end
clientPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupDamageTracking()
end)

local guestCenterPart, guestLeftPart, guestRightPart = nil, nil, nil
local guestLeftToKillerPart, guestRightToKillerPart  = nil, nil
local guestLeftToCenterPart, guestCenterToRightPart  = nil, nil

local guestAutoBlockTriggerSounds = {
    ["102228729296384"] = true, ["140242176732868"] = true, ["112809109188560"] = true, ["136323728355613"] = true,
    ["115026634746636"] = true, ["84116622032112"] = true, ["108907358619313"] = true, ["127793641088496"] = true,
    ["86174610237192"] = true, ["95079963655241"] = true, ["101199185291628"] = true, ["119942598489800"] = true,
    ["84307400688050"] = true, ["113037804008732"] = true, ["105200830849301"] = true, ["75330693422988"] = true,
    ["82221759983649"] = true, ["109348678063422"] = true, ["81702359653578"] = true, ["85853080745515"] = true,
    ["108610718831698"] = true, ["112395455254818"] = true, ["109431876587852"] = true, ["12222216"] = true,
    ["79980897195554"] = true, ["119583605486352"] = true, ["71834552297085"] = true, ["116581754553533"] = true,
    ["86833981571073"] = true, ["110372418055226"] = true, ["105840448036441"] = true, ["86494585504534"] = true,
    ["80516583309685"] = true, ["131406927389838"] = true, ["89004992452376"] = true, ["117231507259853"] = true,
    ["101698569375359"] = true, ["101553872555606"] = true, ["140412278320643"] = true, ["106300477136129"] = true,
    ["117173212095661"] = true, ["104910828105172"] = true, ["140194172008986"] = true, ["85544168523099"] = true,
    ["114506382930939"] = true, ["99829427721752"] = true, ["120059928759346"] = true, ["104625283622511"] = true,
    ["105316545074913"] = true, ["126131675979001"] = true, ["82336352305186"] = true, ["93366464803829"] = true,
    ["84069821282466"] = true, ["128856426573270"] = true, ["121954639447247"] = true, ["128195973631079"] = true,
    ["124903763333174"] = true, ["94317217837143"] = true, ["98111231282218"] = true, ["119089145505438"] = true,
    ["136728245733659"] = true, ["71310583817000"] = true, ["107444859834748"] = true, ["76959687420003"] = true,
    ["72425554233832"] = true, ["96594507550917"] = true, ["139996647355899"] = true, ["107345261604889"] = true,
    ["127557531826290"] = true, ["108651070773439"] = true, ["74842815979546"] = true,
    ["124397369810639"] = true,
    ["76467993976301"] = true, ["118493324723683"] = true, ["78298577002481"] = true, ["116527305931161"] = true,
    ["5148302439"] = true, ["98675142200448"] = true, ["128367348686124"] = true, ["71805956520207"] = true,
    ["125213046326879"] = true, ["84353899757208"] = true, ["103684883268194"] = true,
    ["109246041199659"] = true, ["80540530406270"] = true, ["139523195429581"] = true, ["105204810054381"] = true,
}

local guestTrackedPunchAnimations = {
    ["87259391926321"] = true, ["140703210927645"] = true, ["136007065400978"] = true, ["129843313690921"] = true,
    ["86709774283672"] = true, ["108807732150251"] = true, ["138040001965654"] = true, ["86096387000557"] = true,
    ["81905101227053"] = true, ["127777649118195"] = true, ["99100240941590"] = true,
    ["92831180929659"] = true, ["112081768119093"] = true, ["117587689359268"] = true, ["91830732867282"] = true,
    ["91730605416216"] = true, ["100184164753080"] = true,
}

local guestAimTargets = { "Slasher", "c00lkidd", "JohnDoe", "1x1x1x1", "Noli", "Sixer", "Nosferatu" }

local guestHumanoid, guestHRP = nil, nil
local guestPunchAiming         = false
local guestPunchLastTriggerTime = 0
local guestOriginalWS, guestOriginalJP, guestOriginalAutoRotate = nil, nil, nil
local guestAimConnection       = nil
local guestSoundHooks          = {}
local guestSoundBlockedUntil   = {}
local guestLastBlockTime       = 0

local guestRemoteEvent = replicatedStorage
    :WaitForChild("Modules")
    :WaitForChild("Network")
    :WaitForChild("RemoteEvent")

-- ── Helpers ──────────────────────────────────────────────────────────
local function guestGetValidTarget()
    local killersFolder = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if killersFolder then
        for _, name in ipairs(guestAimTargets) do
            local target = killersFolder:FindFirstChild(name)
            if target and target:FindFirstChild("HumanoidRootPart") then
                return target.HumanoidRootPart, target:FindFirstChild("Humanoid")
            end
        end
    end
    return nil, nil
end

local function guestExtractNumericSoundId(sound)
    if not sound then return nil end
    local sid = tostring(sound.SoundId)
    local num = sid:match("%d+")
    if num then return num end
    local hash = sid:match("[&%?]hash=([^&]+)")
    if hash then return "&hash=" .. hash end
    local path = sid:match("rbxasset://sounds/.+")
    if path then return path end
    return nil
end

local function guestGetSoundWorldPosition(sound)
    if not sound then return nil end
    if sound.Parent and sound.Parent:IsA("BasePart") then
        return sound.Parent.Position, sound.Parent
    end
    if sound.Parent and sound.Parent:IsA("Attachment")
        and sound.Parent.Parent and sound.Parent.Parent:IsA("BasePart") then
        return sound.Parent.Parent.Position, sound.Parent.Parent
    end
    local found = sound.Parent and sound.Parent:FindFirstChildWhichIsA("BasePart", true)
    if found then return found.Position, found end
    return nil, nil
end

local function guestGetCharacterFromDescendant(inst)
    if not inst then return nil end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return model end
    return nil
end

local function guestFireRemoteBlock()
    pcall(function()
        guestRemoteEvent:FireServer(
            "UseActorAbility",
            { [1] = buffer.fromstring("\3\5\0\0\0Block") }
        )
    end)
end

local function guestFireRemotePunch()
    pcall(function()
        guestRemoteEvent:FireServer(
            "UseActorAbility",
            { [1] = buffer.fromstring("\3\5\0\0\0Punch") }
        )
    end)
end

------------------------------------------------------------------------
-- LOVESAKEN v4.0.2 HDT (BodyVelocity + rotate snap)
------------------------------------------------------------------------

local _hitboxDragDebounce = false

local function getNearestKillerModel()
    local s, r = pcall(function()
        local myChar = clientPlayer.Character
        if not myChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local pf = workspaceService:FindFirstChild("Players")
        if not pf then return nil end
        local kf = pf:FindFirstChild("Killers")
        if not kf then return nil end
        local best, bestD = nil, math.huge
        for _, k in pairs(kf:GetChildren()) do
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestD then best, bestD = k, d end
            end
        end
        return best
    end)
    return s and r or nil
end

local function startChargeAim(fallback)
    local sw = tick()
    fallback = fallback or 1.2
    local char = clientPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum then hum.AutoRotate = false end
    while tick() - sw < fallback do
        local nk = getNearestKillerModel()
        if nk and root then
            local tHRP = nk:FindFirstChild("HumanoidRootPart")
            if tHRP then
                if rotateDelay > 0 then task.wait(rotateDelay) end
                root.CFrame = CFrame.lookAt(root.Position, tHRP.Position)
            end
        end
        task.wait()
    end
    if hum then hum.AutoRotate = true end
end

local function guestPerformHitboxDrag(killerModel)
    if not guestHitboxDraggingOn then return end
    if _hitboxDragDebounce then return end
    if not killerModel or not killerModel.Parent then return end

    local char = clientPlayer.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local tHRP = killerModel:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    _hitboxDragDebounce = true

    local oldW, oldJ = hum.WalkSpeed, hum.JumpPower
    hum.WalkSpeed = 0
    hum.JumpPower = 0

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp

    local conn
    conn = runService.Heartbeat:Connect(function()
        if not _hitboxDragDebounce then
            conn:Disconnect()
            if bv and bv.Parent then bv:Destroy() end
            hum.WalkSpeed = oldW
            hum.JumpPower = oldJ
            return
        end

        if not (char and char.Parent) or not (killerModel and killerModel.Parent) then
            _hitboxDragDebounce = false
            return
        end

        tHRP = killerModel:FindFirstChild("HumanoidRootPart")
        if not tHRP then _hitboxDragDebounce = false; return end

        local to = tHRP.Position - hrp.Position
        local h2 = Vector3.new(to.X, 0, to.Z)
        bv.Velocity = h2.Magnitude > 0.01 and h2.Unit * Dspeed or Vector3.zero

        if to.Magnitude <= 2.0 then
            _hitboxDragDebounce = false
        end
    end)

    task.delay(guestHitboxDragDuration, function()
        _hitboxDragDebounce = false
    end)
end

-- ── Block attempt ────────────────────────────────────────────────────
local function guestAttemptBlock(char, hrp)
    if not guestAutoBlockAudioOn then return end
    local t = tick()
    if t < guestLastBlockTime + guestBlockCooldown then return end
    
    local justTookDamage = (tick() - lastDamageTime) < DAMAGE_SUPPRESS_WINDOW
    if justTookDamage then return end

    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not hrp then return end

    task.delay(guestBlockDelay, function()
        local stillValid = myChar and myChar:FindFirstChild("HumanoidRootPart") and hrp.Parent
        if not stillValid then return end

        if guestHitboxDraggingOn then
            task.spawn(startChargeAim, 0.4)
        end

        guestFireRemoteBlock()
        guestLastBlockTime = tick()

        if guestAutoPunchOn then
            task.delay(guestAutoPunchDelay, guestFireRemotePunch)
        end
    end)
end

-- ── Sound system ──────────────────────────────────────────────────────
local function guestAttemptBlockForSound(sound, preId)
    if not guestAutoBlockAudioOn then return end
    if not sound or not sound:IsA("Sound") then return end
    local id = preId or guestExtractNumericSoundId(sound)
    if not id or not guestAutoBlockTriggerSounds[id] then return end
    local t = tick()
    if guestSoundBlockedUntil[sound] and t < guestSoundBlockedUntil[sound] then return end
    if t < guestLastBlockTime + guestBlockCooldown then return end
    
    local justTookDamage = (tick() - lastDamageTime) < DAMAGE_SUPPRESS_WINDOW
    if justTookDamage then return end

    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local _, soundPart = guestGetSoundWorldPosition(sound)
    if not soundPart then return end
    local char = guestGetCharacterFromDescendant(soundPart)
    local plr  = char and playersService:GetPlayerFromCharacter(char)
    if not plr or plr == clientPlayer then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distSq   = (hrp.Position - myRoot.Position).Magnitude ^ 2
    local pingComp = 0.2 * guestDetectionRange
    if distSq > guestDetectionRangeSq + pingComp then return end
    if guestVerifyFacingCheckOn then
        local ok, res = pcall(function()
            local dir    = (myRoot.Position - hrp.Position).Unit
            local dot    = hrp.CFrame.LookVector:Dot(dir)
            local cosAng = math.cos(math.rad(guestVisionAngle / 2))
            return distSq < 25 or dot >= cosAng
        end)
        if not ok or not res then return end
    end
    guestAttemptBlock(char, hrp)
    guestSoundBlockedUntil[sound] = t + guestSoundBlockDuration
end

local function guestHookSound(sound)
    if not sound or not sound:IsA("Sound") or guestSoundHooks[sound] then return end
    local preId = guestExtractNumericSoundId(sound)
    if not preId then return end
    local playedConn = sound.Played:Connect(function()
        if guestAutoBlockAudioOn then task.spawn(guestAttemptBlockForSound, sound, preId) end
    end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying and guestAutoBlockAudioOn then
            task.spawn(guestAttemptBlockForSound, sound, preId)
        end
    end)
    local destroyConn
    destroyConn = sound.Destroying:Connect(function()
        pcall(function()
            if playedConn  then playedConn:Disconnect()  end
            if propConn    then propConn:Disconnect()    end
            if destroyConn then destroyConn:Disconnect() end
        end)
        guestSoundHooks[sound]        = nil
        guestSoundBlockedUntil[sound] = nil
    end)
    guestSoundHooks[sound] = { playedConn, propConn, destroyConn, id = preId }
    if sound.IsPlaying then task.spawn(guestAttemptBlockForSound, sound, preId) end
end

local function guestHookExistingSounds()
    local killersFolder = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if killersFolder then
        for _, killer in pairs(killersFolder:GetChildren()) do
            for _, desc in pairs(killer:GetDescendants()) do
                if desc:IsA("Sound") then pcall(guestHookSound, desc) end
            end
        end
    end
end

local function guestSetupSoundHooks()
    local killersFolder = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if killersFolder then
        guestHookExistingSounds()
        killersFolder.DescendantAdded:Connect(function(desc)
            if desc:IsA("Sound") then pcall(guestHookSound, desc) end
        end)
    end
end

-- ── Vision cone ───────────────────────────────────────────────────────
local function guestCreateVisionPart()
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1); part.Shape = Enum.PartType.Ball
    part.Anchored = true; part.CanCollide = false
    part.Transparency = 0.5; part.Color = Color3.fromRGB(255, 0, 0)
    part.Parent = workspaceService; return part
end

local function guestCreateConnectionPart()
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 1); part.Anchored = true
    part.CanCollide = false; part.Transparency = 0.3
    part.Color = Color3.fromRGB(255, 0, 0); part.Parent = workspaceService; return part
end

local function guestCleanupVisionCone()
    if guestCenterPart       then guestCenterPart:Destroy();       guestCenterPart       = nil end
    if guestLeftPart         then guestLeftPart:Destroy();         guestLeftPart         = nil end
    if guestRightPart        then guestRightPart:Destroy();        guestRightPart        = nil end
    if guestLeftToKillerPart then guestLeftToKillerPart:Destroy(); guestLeftToKillerPart = nil end
    if guestRightToKillerPart then guestRightToKillerPart:Destroy(); guestRightToKillerPart = nil end
    if guestLeftToCenterPart then guestLeftToCenterPart:Destroy(); guestLeftToCenterPart = nil end
    if guestCenterToRightPart then guestCenterToRightPart:Destroy(); guestCenterToRightPart = nil end
end

local function guestUpdateVisionCone()
    if not guestShowVisionRange then
        if guestCenterPart then guestCleanupVisionCone() end; return
    end
    local myChar = clientPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then guestCleanupVisionCone(); return end
    local killersFolder = workspaceService:FindFirstChild("Players")
        and workspaceService.Players:FindFirstChild("Killers")
    if not killersFolder then guestCleanupVisionCone(); return end
    local killerHRP = nil
    for _, name in ipairs(guestAimTargets) do
        local target = killersFolder:FindFirstChild(name)
        if target and target:FindFirstChild("HumanoidRootPart") then
            killerHRP = target.HumanoidRootPart; break
        end
    end
    if not killerHRP then guestCleanupVisionCone(); return end
    local fwd = killerHRP.CFrame.LookVector
    local halfAngleRad = math.rad(guestVisionAngle / 2)
    local right = Vector3.new(-fwd.Z, 0, fwd.X).Unit
    local leftDir  = (fwd * math.cos(halfAngleRad) + right * math.sin(halfAngleRad)).Unit
    local rightDir = (fwd * math.cos(halfAngleRad) - right * math.sin(halfAngleRad)).Unit
    local centerPos = killerHRP.Position + fwd      * guestVisionRange
    local leftPos   = killerHRP.Position + leftDir  * guestVisionRange
    local rightPos  = killerHRP.Position + rightDir * guestVisionRange
    if not guestCenterPart then guestCenterPart = guestCreateVisionPart() end
    if not guestLeftPart   then guestLeftPart   = guestCreateVisionPart() end
    if not guestRightPart  then guestRightPart  = guestCreateVisionPart() end
    guestCenterPart.Position = centerPos
    guestLeftPart.Position   = leftPos
    guestRightPart.Position  = rightPos
    if not guestLeftToKillerPart  then guestLeftToKillerPart  = guestCreateConnectionPart() end
    if not guestRightToKillerPart then guestRightToKillerPart = guestCreateConnectionPart() end
    if not guestLeftToCenterPart  then guestLeftToCenterPart  = guestCreateConnectionPart() end
    if not guestCenterToRightPart then guestCenterToRightPart = guestCreateConnectionPart() end
    local function updateLine(part, p1, p2)
        local mid  = (p1 + p2) / 2
        local dist = (p2 - p1).Magnitude
        part.Size  = Vector3.new(0.1, 0.1, dist)
        part.CFrame = CFrame.new(mid, p2)
    end
    updateLine(guestLeftToKillerPart,  killerHRP.Position, leftPos)
    updateLine(guestRightToKillerPart, killerHRP.Position, rightPos)
    updateLine(guestLeftToCenterPart,  leftPos,  centerPos)
    updateLine(guestCenterToRightPart, centerPos, rightPos)
end

-- ── Character setup ──────────────────────────────────────────────────
local function guestSetupCharacter(char)
    guestHumanoid = char:FindFirstChild("Humanoid")
    guestHRP      = char:FindFirstChild("HumanoidRootPart")
    
    if guestAimConnection then guestAimConnection:Disconnect(); guestAimConnection = nil end
    
    local animator = guestHumanoid and guestHumanoid:FindFirstChildOfClass("Animator")
    
    if animator then
        animator.AnimationPlayed:Connect(function(track)
            local animId = track.Animation.AnimationId:match("%d+")
            
            if blockAnimSet[animId] and guestHitboxDraggingOn then
                local justTookDamage = (tick() - lastDamageTime) < DAMAGE_SUPPRESS_WINDOW
                if not justTookDamage then
                    local nearest = getNearestKillerModel()
                    if nearest then
                        local myChar = clientPlayer.Character
                        if myChar then
                            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                            local killerHRP = nearest:FindFirstChild("HumanoidRootPart")
                            if myRoot and killerHRP then
                                local dist = (myRoot.Position - killerHRP.Position).Magnitude
                                if dist <= guestDetectionRange then
                                    guestPerformHitboxDrag(nearest)
                                    task.spawn(startChargeAim, 0.4)
                                end
                            end
                        end
                    end
                end
            end
            
            if guestAimPunchActive and guestTrackedPunchAnimations[animId] then
                guestPunchLastTriggerTime = tick()
                guestPunchAiming = true
            end
        end)
    end
end

-- ── Boot ──────────────────────────────────────────────────────────────
guestSetupSoundHooks()

clientPlayer.CharacterAdded:Connect(function(char)
    task.delay(0.5, function()
        guestCleanupVisionCone()
        _hitboxDragDebounce = false
        guestSetupCharacter(char)
    end)
end)

if clientPlayer.Character then
    guestSetupCharacter(clientPlayer.Character)
end

-- ── Main render loop ──────────────────────────────────────────────────
runService.RenderStepped:Connect(function()
    if guestAimPunchActive and guestHumanoid and guestHRP and guestPunchAiming then
        local elapsed = tick() - guestPunchLastTriggerTime
        if elapsed > guestAimPunchDuration then
            guestPunchAiming = false
            if guestOriginalWS then
                guestHumanoid.WalkSpeed     = guestOriginalWS
                guestHumanoid.JumpPower     = guestOriginalJP
                guestHumanoid.AutoRotate    = guestOriginalAutoRotate
                guestOriginalWS, guestOriginalJP, guestOriginalAutoRotate = nil, nil, nil
            end
            return
        end
        if not guestOriginalWS then
            guestOriginalWS          = guestHumanoid.WalkSpeed
            guestOriginalJP          = guestHumanoid.JumpPower
            guestOriginalAutoRotate  = guestHumanoid.AutoRotate
        end
        guestHumanoid.AutoRotate         = false
        guestHRP.AssemblyAngularVelocity = Vector3.zero
        local targetHRP = guestGetValidTarget()
        if targetHRP then
            local predictPos = targetHRP.Velocity.Magnitude > 0.5
                and (targetHRP.Position + targetHRP.Velocity * (guestPunchPrediction / 60))
                or targetHRP.Position
            local dir = (predictPos - guestHRP.Position).Unit
            local yaw = math.atan2(-dir.X, -dir.Z)
            guestHRP.CFrame = CFrame.new(guestHRP.Position) * CFrame.Angles(0, yaw, 0)
        end
    end
    pcall(guestUpdateVisionCone)
end)

-- ========== END OF ORIGINAL LOGIC ==========

-- 6. NOW CREATE UI ELEMENTS (using Rayfield) inside the CombatTab

-- Auto Block
MainSection:CreateToggle({
    Name = "Auto Block",
    Default = false,
    Callback = function(state)
        guestAutoBlockAudioOn = state
    end
})

-- Block Delay
MainSection:CreateSlider({
    Name = "Block Delay",
    Min = 0,
    Max = 2,
    Default = 0,
    Increment = 0.05,
    Callback = function(value)
        guestBlockDelay = value
    end
})

-- Auto Block Radius
MainSection:CreateSlider({
    Name = "Auto Block Radius",
    Min = 1,
    Max = 20,
    Default = 15,
    Increment = 1,
    Callback = function(value)
        guestDetectionRange = value
        guestDetectionRangeSq = value * value
    end
})

MainSection:CreateDivider() -- Rayfield has a Divider method

-- HDT Toggles
MainSection:CreateToggle({
    Name = "Hitbox Dragging (HDT)",
    Default = false,
    Callback = function(state)
        guestHitboxDraggingOn = state
    end
})

MainSection:CreateSlider({
    Name = "HDT Speed",
    Min = 1,
    Max = 30,
    Default = 12,
    Increment = 0.5,
    Callback = function(value)
        Dspeed = value
    end
})

MainSection:CreateSlider({
    Name = "HDT Delay (s)",
    Min = 0,
    Max = 0.5,
    Default = 0,
    Increment = 0.01,
    Callback = function(value)
        Ddelay = value
    end
})

MainSection:CreateSlider({
    Name = "Rotate Delay (s)",
    Min = 0,
    Max = 0.5,
    Default = 0,
    Increment = 0.01,
    Callback = function(value)
        rotateDelay = value
    end
})

MainSection:CreateToggle({
    Name = "Verify Facing Check",
    Default = false,
    Callback = function(state)
        guestVerifyFacingCheckOn = state
    end
})

MainSection:CreateSlider({
    Name = "Set Vision Range",
    Min = 1,
    Max = 20,
    Default = 15,
    Increment = 1,
    Callback = function(value)
        guestVisionRange = value
    end
})

MainSection:CreateSlider({
    Name = "Set Vision Angle",
    Min = 1,
    Max = 200,
    Default = 90,
    Increment = 1,
    Callback = function(value)
        guestVisionAngle = value
    end
})

MainSection:CreateToggle({
    Name = "Show Vision Range",
    Default = false,
    Callback = function(state)
        guestShowVisionRange = state
        if not state then guestCleanupVisionCone() end
    end
})

MainSection:CreateDivider()

MainSection:CreateToggle({
    Name = "Auto Punch",
    Default = false,
    Callback = function(state)
        guestAutoPunchOn = state
    end
})

MainSection:CreateToggle({
    Name = "Aim Punch",
    Default = false,
    Callback = function(state)
        guestAimPunchActive = state
        if state and clientPlayer.Character then
            guestSetupCharacter(clientPlayer.Character)
        end
    end
})

MainSection:CreateSlider({
    Name = "Punch Prediction",
    Min = 0,
    Max = 10,
    Default = 4,
    Increment = 1,
    Callback = function(value)
        guestPunchPrediction = value
    end
})

-- 7. INTERFACE TAB
local InterfaceSection = InterfaceTab:CreateSection({
    Name = "UI Functions"
})

InterfaceSection:CreateButton({
    Name = "Close UI",
    Callback = function()
        Window:Destroy()
    end
})

-- 8. FINAL TOUCH
print("V1PRBLOCK (Rayfield Gen 2) loaded successfully.")
Window:Show()
