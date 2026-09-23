--[[
    Auto Block Hub — Obsidian UI
    Converted from Rayfield
    Author: Skibidi Shots (original) / converted
]]

-- ============================================================
-- SERVICES
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local StarterGui        = game:GetService("StarterGui")
local Debris            = game:GetService("Debris")
local lp                = Players.LocalPlayer
local PlayerGui         = lp:WaitForChild("PlayerGui")
local Humanoid, Animator

local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
local SayMessageRequest = ChatEvents and ChatEvents:FindFirstChild("SayMessageRequest")
local testRemote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- ============================================================
-- ID TABLES
-- ============================================================
local autoBlockTriggerSounds = {
    ["102228729296384"]=true, ["140242176732868"]=true, ["112809109188560"]=true,
    ["136323728355613"]=true, ["115026634746636"]=true, ["84116622032112"] =true,
    ["108907358619313"]=true, ["127793641088496"]=true, ["86174610237192"] =true,
    ["95079963655241"] =true, ["101199185291628"]=true, ["119942598489800"]=true,
    ["84307400688050"] =true, ["113037804008732"]=true, ["105200830849301"]=true,
    ["75330693422988"] =true, ["82221759983649"] =true, ["81702359653578"] =true,
    ["108610718831698"]=true, ["112395455254818"]=true, ["109431876587852"]=true,
    ["109348678063422"]=true, ["85853080745515"] =true, ["12222216"]      =true,
    ["105840448036441"]=true, ["114742322778642"]=true, ["119583605486352"]=true,
    ["79980897195554"] =true, ["71805956520207"] =true, ["79391273191671"] =true,
    ["89004992452376"] =true, ["101553872555606"]=true, ["101698569375359"]=true,
    ["106300477136129"]=true, ["116581754553533"]=true, ["117231507259853"]=true,
    ["119089145505438"]=true, ["121954639447247"]=true, ["125213046326879"]=true,
    ["131406927389838"]=true,
}

local autoBlockTriggerAnims = {
    "126830014841198","126355327951215","121086746534252","18885909645",
    "98456918873918","105458270463374","83829782357897","125403313786645",
    "118298475669935","82113744478546","70371667919898","99135633258223",
    "97167027849946","109230267448394","139835501033932","126896426760253",
    "109667959938617","126681776859538","129976080405072","121293883585738",
    "81639435858902","137314737492715","92173139187970"
}

local blockAnimIds = { "72722244508749","96959123077498","95802026624883" }
local punchAnimIds = {
    "87259391926321","140703210927645","136007065400978","136007065400978",
    "129843313690921","129843313690921","86709774283672","87259391926321",
    "129843313690921","129843313690921","108807732150251","138040001965654",
    "86096387000557","86096387000557"
}
local chargeAnimIds = { "106014898528300" }

-- ============================================================
-- STATE
-- ============================================================
local lastAimTrigger = {}
local AIM_WINDOW = 0.5
local AIM_COOLDOWN = 0.6

local _lastPunchMessageTime = _lastPunchMessageTime or 0
local MESSAGE_PUNCH_COOLDOWN = 0.6
local _punchPrevPlaying = _punchPrevPlaying or {}

local _lastBlockMessageTime = _lastBlockMessageTime or 0
local MESSAGE_BLOCK_COOLDOWN = 0.6
local _blockPrevPlaying = _blockPrevPlaying or {}

local autoBlockOn = false
local autoBlockAudioOn = false
local doubleblocktech = false
local blockdelay = 0
local looseFacing = true
local detectionRange = 18
local messageWhenAutoBlockOn = false
local messageWhenAutoBlock = ""
local antiFlickOn = false
local antiFlickParts = 4
local antiFlickBaseOffset = 2.7
local antiFlickOffsetStep = 0
local antiFlickDelay = 0
local PRED_SECONDS_FORWARD = 0.25
local PRED_SECONDS_LATERAL = 0.18
local PRED_MAX_FORWARD = 6
local PRED_MAX_LATERAL = 4
local ANG_TURN_MULTIPLIER = 0.6
local SMOOTHING_LERP = 0.22
local killerState = {}
local predictionStrength = 1
local predictionTurnStrength = 1
local blockPartsSizeMultiplier = 1
local autoAdjustDBTFBPS = false
local _savedManualAntiFlickDelay = antiFlickDelay or 0

local killerDelayMap = {
    ["c00lkidd"] = 0,
    ["jason"]    = 0.013,
    ["slasher"]  = 0.01,
    ["1x1x1x1"]  = 0.15,
    ["johndoe"]  = 0.33,
    ["noli"]     = 0.15,
}

local predictiveBlockOn = false
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0
local Dspeed = 5.6
local Ddelay = 0
local killerNames = {"c00lkidd","Jason","JohnDoe","1x1x1x1","Noli","Slasher","Sixer"}
local autoPunchOn = false
local messageWhenAutoPunchOn = false
local messageWhenAutoPunch = ""
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false
local customBlockEnabled = false
local customBlockAnimId = ""
local customblockdelay = 2
local customPunchEnabled = false
local customPunchAnimId = ""
local custompunchdelay = 2.7
local espEnabled = false
local KillersFolder = workspace:WaitForChild("Players"):WaitForChild("Killers")
local lastBlockTime = 0
local lastPunchTime = 0
local stagger = 0.02
local customChargeEnabled = false
local customChargeAnimId = ""
local predictionValue = 4
local hitboxDraggingTech = false
local _hitboxDraggingDebounce = false
local HITBOX_DRAG_DURATION = 1.4
local HITBOX_DETECT_RADIUS = 6

-- ============================================================
-- ANIMATOR
-- ============================================================
local cachedAnimator = nil
local function refreshAnimator()
    local char = lp.Character
    if not char then cachedAnimator = nil; return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        cachedAnimator = hum:FindFirstChildOfClass("Animator") or nil
    else
        cachedAnimator = nil
    end
end

lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    refreshAnimator()
end)

-- ============================================================
-- UI REFS CACHE
-- ============================================================
local cachedPlayerGui = PlayerGui
local cachedPunchBtn, cachedBlockBtn, cachedCharges, cachedCooldown, cachedChargeBtn, cachedCloneBtn = nil,nil,nil,nil,nil,nil
local detectionRangeSq = detectionRange * detectionRange

local function refreshUIRefs()
    cachedPlayerGui = lp:FindFirstChild("PlayerGui") or PlayerGui
    local main = cachedPlayerGui and cachedPlayerGui:FindFirstChild("MainUI")
    if main then
        local ability = main:FindFirstChild("AbilityContainer")
        cachedPunchBtn = ability and ability:FindFirstChild("Punch")
        cachedBlockBtn = ability and ability:FindFirstChild("Block")
        cachedChargeBtn = ability and ability:FindFirstChild("Charge")
        cachedCloneBtn = ability and ability:FindFirstChild("Clone")
        cachedCharges = cachedPunchBtn and cachedPunchBtn:FindFirstChild("Charges")
        cachedCooldown = cachedBlockBtn and cachedBlockBtn:FindFirstChild("CooldownTime")
    else
        cachedPunchBtn,cachedBlockBtn,cachedCharges,cachedCooldown,cachedChargeBtn,cachedCloneBtn = nil,nil,nil,nil,nil,nil
    end
end

refreshUIRefs()

if cachedPlayerGui then
    cachedPlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "MainUI" then
            task.delay(0.02, refreshUIRefs)
        end
    end)
end

lp.CharacterAdded:Connect(function()
    task.delay(0.5, refreshUIRefs)
end)

-- ============================================================
-- NOTIFICATION
-- ============================================================
local function SendNotif(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title or "Hello",
        Text = text or "hi",
        Duration = duration or 4
    })
end

-- ============================================================
-- FACING CHECK
-- ============================================================
local facingCheckEnabled = true
local customFacingDot = -0.3

local function isFacing(localRoot, targetRoot)
    if not facingCheckEnabled then return true end
    local dx = localRoot.Position.X - targetRoot.Position.X
    local dy = localRoot.Position.Y - targetRoot.Position.Y
    local dz = localRoot.Position.Z - targetRoot.Position.Z
    local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mag == 0 then return true end
    local invMag = 1 / mag
    local ux, uy, uz = dx * invMag, dy * invMag, dz * invMag
    local lv = targetRoot.CFrame.LookVector
    local dot = lv.X * ux + lv.Y * uy + lv.Z * uz
    return dot > (customFacingDot or -0.3)
end

-- ============================================================
-- FACING CHECK VISUAL
-- ============================================================
local facingVisualOn = false
local facingVisuals = {}

local function updateFacingVisual(killer, visual)
    if not (killer and visual and visual.Parent) then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dot = math.clamp(customFacingDot or -0.3, -1, 1)
    local angle = math.acos(dot)
    local frac = angle / math.pi
    local minFrac = 0.20
    local radius = math.max(1, detectionRange * (minFrac + (1 - minFrac) * frac))
    visual.Radius = radius
    visual.Height = 0.12

    local forwardDist = detectionRange * (0.35 + 0.15 * frac)
    local yOffset = -(hrp.Size.Y / 2 + 0.05)
    visual.CFrame = CFrame.new(0, yOffset, -forwardDist) * CFrame.Angles(math.rad(90), 0, 0)

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local inRange, facingOkay = false, false
    if myRoot and hrp then
        local dist = (hrp.Position - myRoot.Position).Magnitude
        inRange = dist <= detectionRange
        facingOkay = (not facingCheckEnabled) or isFacing(myRoot, hrp)
    end

    if inRange and facingOkay then
        visual.Color3 = Color3.fromRGB(0, 255, 0)
        visual.Transparency = 0.40
    else
        visual.Color3 = Color3.fromRGB(255, 255, 0)
        visual.Transparency = 0.85
    end
end

local function addFacingVisual(killer)
    if not killer or not killer:IsA("Model") then return end
    if facingVisuals[killer] then return end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local visual = Instance.new("CylinderHandleAdornment")
    visual.Name = "FacingCheckVisual"
    visual.Adornee = hrp
    visual.AlwaysOnTop = true
    visual.ZIndex = 2
    visual.Transparency = 0.55
    visual.Color3 = Color3.fromRGB(0, 255, 0)
    visual.Parent = hrp
    facingVisuals[killer] = visual
    updateFacingVisual(killer, visual)
end

local function removeFacingVisual(killer)
    local v = facingVisuals[killer]
    if v then v:Destroy(); facingVisuals[killer] = nil end
end

local function refreshFacingVisuals()
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if facingVisualOn then
            local hrp = k:FindFirstChild("HumanoidRootPart") or k:WaitForChild("HumanoidRootPart", 5)
            if hrp then addFacingVisual(k) end
        else
            removeFacingVisual(k)
        end
    end
end

RunService.RenderStepped:Connect(function()
    for killer, visual in pairs(facingVisuals) do
        if not killer.Parent or not killer:FindFirstChild("HumanoidRootPart") then
            removeFacingVisual(killer)
        else
            updateFacingVisual(killer, visual)
        end
    end
end)

KillersFolder.ChildAdded:Connect(function(killer)
    if facingVisualOn then
        task.spawn(function()
            local hrp = killer:WaitForChild("HumanoidRootPart", 5)
            if hrp then addFacingVisual(killer) end
        end)
    end
end)
KillersFolder.ChildRemoved:Connect(function(killer) removeFacingVisual(killer) end)

-- ============================================================
-- RANGE VISUAL
-- ============================================================
local detectionCircles = {}
local killerCirclesVisible = false

local function addKillerCircle(killer)
    if not killer:FindFirstChild("HumanoidRootPart") then return end
    if detectionCircles[killer] then return end
    local hrp = killer.HumanoidRootPart
    local circle = Instance.new("CylinderHandleAdornment")
    circle.Name = "KillerDetectionCircle"
    circle.Adornee = hrp
    circle.Color3 = Color3.fromRGB(255, 0, 0)
    circle.AlwaysOnTop = true
    circle.ZIndex = 1
    circle.Transparency = 0.6
    circle.Radius = detectionRange
    circle.Height = 0.12
    local yOffset = -(hrp.Size.Y / 2 + 0.05)
    circle.CFrame = CFrame.new(0, yOffset, 0) * CFrame.Angles(math.rad(90), 0, 0)
    circle.Parent = hrp
    detectionCircles[killer] = circle
end

local function removeKillerCircle(killer)
    if detectionCircles[killer] then
        detectionCircles[killer]:Destroy()
        detectionCircles[killer] = nil
    end
end

local function refreshKillerCircles()
    for _, killer in ipairs(KillersFolder:GetChildren()) do
        if killerCirclesVisible then addKillerCircle(killer) else removeKillerCircle(killer) end
    end
end

RunService.RenderStepped:Connect(function()
    for killer, circle in pairs(detectionCircles) do
        if circle and circle.Parent then circle.Radius = detectionRange end
    end
end)

KillersFolder.ChildAdded:Connect(function(killer)
    if killerCirclesVisible then
        task.spawn(function()
            local hrp = killer:WaitForChild("HumanoidRootPart", 5)
            if hrp then addKillerCircle(killer) end
        end)
    end
end)
KillersFolder.ChildRemoved:Connect(function(killer) removeKillerCircle(killer) end)

-- ============================================================
-- NEAREST KILLER + AUTO-ADJUST DBTFBPS
-- ============================================================
local function getNearestKillerModel()
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    for _, k in ipairs(KillersFolder:GetChildren()) do
        if k and k:IsA("Model") then
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < closestDist then closest, closestDist = k, d end
            end
        end
    end
    return closest
end

local function applyDelayForKillerModel(killerModel)
    if not killerModel then
        if antiFlickDelay ~= _savedManualAntiFlickDelay then
            antiFlickDelay = _savedManualAntiFlickDelay
        end
        return
    end
    local key = (tostring(killerModel.Name) or ""):lower()
    local mapped = killerDelayMap[key]
    if mapped ~= nil then
        if antiFlickDelay ~= mapped then antiFlickDelay = mapped end
    else
        if antiFlickDelay ~= _savedManualAntiFlickDelay then
            antiFlickDelay = _savedManualAntiFlickDelay
        end
    end
end

local adjustTicker = 0
RunService.Heartbeat:Connect(function(dt)
    if not autoAdjustDBTFBPS then return end
    adjustTicker = adjustTicker + dt
    if adjustTicker < 0.15 then return end
    adjustTicker = 0
    applyDelayForKillerModel(getNearestKillerModel())
end)

local function doImmediateUpdate()
    if not autoAdjustDBTFBPS then return end
    applyDelayForKillerModel(getNearestKillerModel())
end

KillersFolder.ChildAdded:Connect(function() task.delay(0.05, doImmediateUpdate) end)
KillersFolder.ChildRemoved:Connect(function() task.delay(0.05, doImmediateUpdate) end)

-- ============================================================
-- REMOTE FIRING
-- ============================================================
local autoblocktype = "Block"

local function fireRemoteBlock()
    local args = {"UseActorAbility", "Block"}
    ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end
local function fireRemotePunch()
    local args = {"UseActorAbility", "Punch"}
    ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end
local function fireGuiBlock()
    testRemote:FireServer("UseActorAbility", {buffer.fromstring("\"Block\"")})
end
local function fireGuiPunch()
    testRemote:FireServer("UseActorAbility", {buffer.fromstring("\"Punch\"")})
end
local function fireGuiCharge()
    testRemote:FireServer("UseActorAbility", {buffer.fromstring("\"Charge\"")})
end
local function fireGuiClone()
    testRemote:FireServer("UseActorAbility", {buffer.fromstring("\"Clone\"")})
end

-- ============================================================
-- CHAT MESSAGE
-- ============================================================
local function sendChatMessage(text)
    if not text or text:match("^%s*$") then return end
    local TextChatService = game:GetService("TextChatService")
    local channel = TextChatService.TextChannels.RBXGeneral
    channel:SendAsync(text)
end

-- ============================================================
-- FLING COROUTINE
-- ============================================================
coroutine.wrap(function()
    local hrp, c, vel, movel = nil, nil, nil, 0.1
    while true do
        RunService.Heartbeat:Wait()
        if hiddenfling then
            while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = lp.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            if hiddenfling then
                vel = hrp.Velocity
                hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end
end)()

-- ============================================================
-- SOUND AUTO BLOCK
-- ============================================================
local soundHooks = {}
local soundBlockedUntil = {}

local string_match = string.match
local tostring_local = tostring

local function extractNumericSoundId(sound)
    if not sound then return nil end
    local sid = sound.SoundId
    if not sid then return nil end
    sid = (type(sid) == "string") and sid or tostring_local(sid)
    local num = string_match(sid, "rbxassetid://(%d+)") or string_match(sid, "://(%d+)") or string_match(sid, "^(%d+)$")
    if num and #num > 0 then return num end
    local hash = string_match(sid, "[&%?]hash=([^&]+)")
    if hash then return "&hash=" .. hash end
    local path = string_match(sid, "rbxasset://sounds/.+")
    if path then return path end
    return nil
end

local KF = KillersFolder

local function getSoundWorldPosition(sound)
    if not sound then return nil end
    local parent = sound.Parent
    if parent then
        if parent:IsA("BasePart") then return parent.Position, parent end
        if parent:IsA("Attachment") then
            local gp = parent.Parent
            if gp and gp:IsA("BasePart") then return gp.Position, gp end
        end
    end
    if KF and sound:IsDescendantOf(KF) then
        local root = parent or sound
        local found = root:FindFirstChildWhichIsA("BasePart", true)
        if found then return found.Position, found end
    end
    return nil, nil
end

local function getCharacterFromDescendant(inst)
    if not inst then return nil end
    local model = inst:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return model end
    return nil
end

local function isPointInsidePart(part, point)
    if not (part and point) then return false end
    local rel = part.CFrame:PointToObjectSpace(point)
    local half = part.Size * 0.5
    return math.abs(rel.X) <= half.X + 0.001 and
           math.abs(rel.Y) <= half.Y + 0.001 and
           math.abs(rel.Z) <= half.Z + 0.001
end

-- killerState tracking
RunService.RenderStepped:Connect(function(dt)
    if dt <= 0 then return end
    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not killersFolder then return end
    for _, killer in ipairs(killersFolder:GetChildren()) do
        if killer and killer.Parent then
            local hrp = killer:FindFirstChild("HumanoidRootPart")
            if hrp then
                local st = killerState[killer] or { prevPos = hrp.Position, prevLook = hrp.CFrame.LookVector, vel = Vector3.new(), angVel = 0 }
                local newVel = (hrp.Position - st.prevPos) / math.max(dt, 1e-6)
                st.vel = st.vel and st.vel:Lerp(newVel, SMOOTHING_LERP) or newVel
                local prevLook = st.prevLook or hrp.CFrame.LookVector
                local look = hrp.CFrame.LookVector
                local dot = math.clamp(prevLook:Dot(look), -1, 1)
                local angle = math.acos(dot)
                local crossY = prevLook:Cross(look).Y
                local angSign = (crossY >= 0) and 1 or -1
                local newAngVel = (angle / math.max(dt, 1e-6)) * angSign
                st.angVel = (st.angVel * (1 - SMOOTHING_LERP)) + (newAngVel * SMOOTHING_LERP)
                st.prevPos = hrp.Position
                st.prevLook = look
                killerState[killer] = st
            end
        end
    end
end)

local _LP = Players.LocalPlayer
local _isFacing = isFacing
local _getSoundWorldPosition = getSoundWorldPosition
local lastLocalBlockTime = 0
local AUDIO_PREDICT_DT = 0.08
local AUDIO_LOCAL_COOLDOWN = 0.35
local AUDIO_SOUND_THROTTLE = 1.0

local function distSq(a, b)
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return dx*dx + dy*dy + dz*dz
end

-- ===== Charge aim =====
local chargeAimActive = false
local chargeAimThread = nil

local function stopChargeAim() chargeAimActive = false end

local function startChargeAimUntilChargeEnds(fallbackSec)
    stopChargeAim()
    chargeAimActive = true
    chargeAimThread = task.spawn(function()
        local fallback = tonumber(fallbackSec) or 1.2
        local function getCharObjects()
            local char = lp.Character
            if not char then return nil, nil, nil end
            return char:FindFirstChildOfClass("Humanoid"),
                   char:FindFirstChild("HumanoidRootPart"),
                   char:FindFirstChildOfClass("Animator")
        end
        local humanoid, myRoot, animator = getCharObjects()
        if humanoid then pcall(function() humanoid.AutoRotate = false end) end
        local seenChargeAnim = false
        local watchStart = tick()
        while chargeAimActive do
            humanoid, myRoot, animator = getCharObjects()
            if not myRoot then break end
            local killerModel = getNearestKillerModel()
            local targetHRP = (killerModel and killerModel:FindFirstChild("HumanoidRootPart")) or nil
            if targetHRP then
                local pred = (type(predictionValue) == "number") and predictionValue or 0
                local predictedPos = targetHRP.Position + (targetHRP.CFrame.LookVector * pred)
                pcall(function() myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos) end)
            end
            local stillPlaying = false
            if animator then
                local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
                if ok and tracks then
                    for _, track in ipairs(tracks) do
                        local animId = nil
                        pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                        if animId and table.find(chargeAnimIds, animId) then
                            stillPlaying = true
                            seenChargeAnim = true
                            break
                        end
                    end
                end
            end
            if seenChargeAnim and not stillPlaying then break end
            if not seenChargeAnim and (tick() - watchStart) > fallback then break end
            task.wait()
        end
        if humanoid then pcall(function() humanoid.AutoRotate = true end) end
        chargeAimActive = false
    end)
end

-- ===== Sound attempt =====
local function _attemptForSound(sound, idParam, mode)
    if not autoBlockAudioOn then return end
    if not sound or not sound:IsA("Sound") then return end
    if not sound.IsPlaying then return end
    local now = tick()
    local hook = soundHooks[sound]
    local id = idParam or (hook and hook.id) or extractNumericSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end
    if soundBlockedUntil[sound] and now < soundBlockedUntil[sound] then return end
    if now - lastLocalBlockTime < AUDIO_LOCAL_COOLDOWN then return end

    if mode == "Block" or mode == "Charge" then
        if not cachedBlockBtn or not cachedCooldown or not cachedCharges then refreshUIRefs() end
    elseif mode == "Clone" then
        if not cachedCloneBtn then refreshUIRefs() end
    end

    local myChar = _LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local char = hook and hook.char
    local hrp = hook and hook.hrp
    if not hrp then
        local soundPos, soundPart = getSoundWorldPosition(sound)
        if not soundPart then return end
        char = getCharacterFromDescendant(soundPart)
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hook then hook.char = char; hook.hrp = hrp
        else soundHooks[sound] = { id = id, char = char, hrp = hrp }; hook = soundHooks[sound] end
    end
    if not hrp then return end

    local v = hrp.Velocity or Vector3.new()
    local px = hrp.Position.X + v.X * AUDIO_PREDICT_DT
    local py = hrp.Position.Y + v.Y * AUDIO_PREDICT_DT
    local pz = hrp.Position.Z + v.Z * AUDIO_PREDICT_DT
    local dx, dy, dz = px - myRoot.Position.X, py - myRoot.Position.Y, pz - myRoot.Position.Z
    local distSqPred = dx*dx + dy*dy + dz*dz

    if detectionRangeSq and distSqPred > detectionRangeSq then
        local dx2 = hrp.Position.X - myRoot.Position.X
        local dy2 = hrp.Position.Y - myRoot.Position.Y
        local dz2 = hrp.Position.Z - myRoot.Position.Z
        local distSqNow = dx2*dx2 + dy2*dy2 + dz2*dz2
        local grace = (detectionRange + 3) * (detectionRange + 3)
        if distSqNow > grace then return end
    end

    local soundPos, soundPart = _getSoundWorldPosition(sound)
    if not soundPart then return end
    local model = soundPart:FindFirstAncestorOfClass("Model")
    if not model then return end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == lp then return end
    if facingCheckEnabled and not _isFacing(myRoot, hrp) then return end

    task.wait(blockdelay)

    if mode == "Block" then
        if cachedCooldown and cachedCooldown.Text == "" then print("yay") else return end
        fireGuiBlock()
        if doubleblocktech == true then fireGuiPunch() end
    elseif mode == "Charge" then
        if cachedChargeBtn and cachedChargeBtn:FindFirstChild("CooldownTime") and cachedChargeBtn.CooldownTime.Text == "" then print("yay") else return end
        fireGuiCharge()
        startChargeAimUntilChargeEnds(0.4)
    elseif mode == "Clone" then
        if cachedCloneBtn and cachedCloneBtn:FindFirstChild("CooldownTime") and cachedCloneBtn.CooldownTime.Text == "" then print("yay") else return end
        fireGuiClone()
        startChargeAimUntilChargeEnds(0.4)
    end

    lastLocalBlockTime = now
    soundBlockedUntil[sound] = now + AUDIO_SOUND_THROTTLE
end

local function attemptBlockForSound(s, id) return _attemptForSound(s, id, "Block") end
local function attemptChargeForSound(s, id) return _attemptForSound(s, id, "Charge") end
local function attemptCloneForSound(s, id) return _attemptForSound(s, id, "Clone") end

-- ===== Anti-flick parts =====
local function attemptBDParts(sound)
    if not autoBlockAudioOn then return end
    if not sound or not sound:IsA("Sound") then return end
    if not sound.IsPlaying then return end
    local id = extractNumericSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end
    local t = tick()
    if soundBlockedUntil[sound] and t < soundBlockedUntil[sound] then return end
    local myChar = lp and lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local soundPos, soundPart = getSoundWorldPosition(sound)
    if not soundPos or not soundPart then return end
    local char = getCharacterFromDescendant(soundPart)
    local plr = char and Players:GetPlayerFromCharacter(char)
    if not plr or plr == lp then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if antiFlickOn then
        local basePartSize = Vector3.new(5.5, 7.5, 8.5)
        local partSize = basePartSize * (blockPartsSizeMultiplier or 1)
        local count = math.max(1, antiFlickParts or 4)
        local base = antiFlickBaseOffset or 2.5
        local step = antiFlickOffsetStep or 0.2
        local lifeTime = 0.2

        task.spawn(function()
            local blocked = false
            task.wait(antiFlickDelay or 0)
            for i = 1, count do
                if not hrp or not myRoot then break end
                local dist = base + (i - 1) * step
                local st = killerState[char] or { vel = hrp.Velocity or Vector3.new(), angVel = 0 }
                local vel = st.vel or hrp.Velocity or Vector3.new()
                local forwardSpeed = vel:Dot(hrp.CFrame.LookVector)
                local lateralSpeed = vel:Dot(hrp.CFrame.RightVector)
                local pStrength = (type(predictionStrength) == "number" and predictionStrength) or 1
                local pTurn = (type(predictionTurnStrength) == "number" and predictionTurnStrength) or 1
                local forwardPredictRaw = forwardSpeed * PRED_SECONDS_FORWARD * pStrength
                local lateralPredictRaw = lateralSpeed * PRED_SECONDS_LATERAL * pStrength
                local turnLateralRaw = st.angVel * ANG_TURN_MULTIPLIER * pTurn
                local forwardClamp = PRED_MAX_FORWARD * pStrength
                local lateralClamp = PRED_MAX_LATERAL * pStrength
                local turnClamp = PRED_MAX_LATERAL * pTurn
                local forwardPredict = math.clamp(forwardPredictRaw, -forwardClamp, forwardClamp)
                local lateralPredict = math.clamp(lateralPredictRaw, -lateralClamp, lateralClamp)
                local turnLateral = math.clamp(turnLateralRaw, -turnClamp, turnClamp)
                local forwardDist = dist + forwardPredict
                local spawnPos = hrp.Position
                    + hrp.CFrame.LookVector * forwardDist
                    + hrp.CFrame.RightVector * (lateralPredict + turnLateral)
                local part = Instance.new("Part")
                part.Name = "AntiFlickZone"
                part.Size = partSize
                part.Transparency = 0.45
                part.Anchored = true
                part.CanCollide = false
                part.CFrame = CFrame.new(spawnPos, hrp.Position)
                part.BrickColor = BrickColor.new("Bright blue")
                part.Parent = workspace
                Debris:AddItem(part, lifeTime)
                if isPointInsidePart(part, myRoot.Position) then
                    blocked = true
                else
                    local touching = {}
                    pcall(function() touching = myRoot:GetTouchingParts() end)
                    for _, p in ipairs(touching) do if p == part then blocked = true break end end
                end
                if blocked then
                    if not (facingCheckEnabled and not isFacing(myRoot, hrp)) then
                        if autoblocktype == "Block" then fireGuiBlock()
                        elseif autoblocktype == "Charge" then fireGuiCharge()
                        elseif autoblocktype == "7n7 Clone" then fireGuiClone() end
                        soundBlockedUntil[sound] = t + 1.2
                    end
                    break
                end
                if stagger and stagger > 0 then task.wait(stagger) else task.wait(0) end
            end
        end)
        return
    end
end

local function hookSound(sound)
    if not sound or not sound:IsA("Sound") then return end
    if soundHooks[sound] then return end
    local preId = extractNumericSoundId(sound)
    soundHooks[sound] = { id = preId, hrp = nil, char = nil }
    local function handleAttempt(snd, id)
        if not autoBlockAudioOn then return end
        if not antiFlickOn then
            local at = autoblocktype
            if at == "Block" then attemptBlockForSound(snd, id)
            elseif at == "Charge" then attemptChargeForSound(snd, id)
            elseif at == "7n7 Clone" then attemptCloneForSound(snd, id) end
        else
            attemptBDParts(snd, id)
        end
    end
    local playedConn = sound.Played:Connect(function() handleAttempt(sound, preId) end)
    local propConn = sound:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if sound.IsPlaying then handleAttempt(sound, preId) end
    end)
    local destroyConn
    destroyConn = sound.Destroying:Connect(function()
        if playedConn and playedConn.Connected then playedConn:Disconnect() end
        if propConn and propConn.Connected then propConn:Disconnect() end
        if destroyConn and destroyConn.Connected then destroyConn:Disconnect() end
        soundHooks[sound] = nil
        soundBlockedUntil[sound] = nil
    end)
    soundHooks[sound].playedConn = playedConn
    soundHooks[sound].propConn = propConn
    soundHooks[sound].destroyConn = destroyConn
    if sound.IsPlaying then handleAttempt(sound, preId) end
end

for _, desc in ipairs(KillersFolder:GetDescendants()) do
    if desc:IsA("Sound") then hookSound(desc) end
end
KillersFolder.DescendantAdded:Connect(function(desc)
    if desc:IsA("Sound") then hookSound(desc) end
end)

-- ============================================================
-- HITBOX DRAGGING
-- ============================================================
local function getKillerHRP(killerModel)
    if not killerModel then return nil end
    if killerModel:FindFirstChild("HumanoidRootPart") then return killerModel:FindFirstChild("HumanoidRootPart") end
    if killerModel.PrimaryPart then return killerModel.PrimaryPart end
    return killerModel:FindFirstChildWhichIsA("BasePart", true)
end

local function beginDragIntoKiller(killerModel)
    if _hitboxDraggingDebounce then return end
    if not killerModel or not killerModel.Parent then return end
    local char = lp and lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    local targetHRP = getKillerHRP(killerModel)
    if not targetHRP then return end
    _hitboxDraggingDebounce = true
    local oldWalk = humanoid.WalkSpeed
    local oldJump = humanoid.JumpPower
    local oldPlatformStand = humanoid.PlatformStand
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.PlatformStand = false
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp
    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not _hitboxDraggingDebounce then
            conn:Disconnect()
            if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            humanoid.WalkSpeed = oldWalk
            humanoid.JumpPower = oldJump
            humanoid.PlatformStand = oldPlatformStand
            return
        end
        if not (char and char.Parent) or not (killerModel and killerModel.Parent) then _hitboxDraggingDebounce = false return end
        targetHRP = getKillerHRP(killerModel)
        if not targetHRP then _hitboxDraggingDebounce = false return end
        local toTarget = (targetHRP.Position - hrp.Position)
        local dist = toTarget.Magnitude
        local horiz = Vector3.new(toTarget.X, 0, toTarget.Z)
        if horiz.Magnitude > 0.01 then
            local dir = horiz.Unit
            bv.Velocity = Vector3.new(dir.X * Dspeed, bv.Velocity.Y, dir.Z * Dspeed)
        else
            bv.Velocity = Vector3.new(0, bv.Velocity.Y, 0)
        end
        local stopDist = 2.0
        if dist <= stopDist then _hitboxDraggingDebounce = false end
    end)
    task.delay(0.4, function()
        if _hitboxDraggingDebounce then _hitboxDraggingDebounce = false end
    end)
end

RunService.RenderStepped:Connect(function()
    if not hitboxDraggingTech then return end
    if not cachedAnimator then refreshAnimator() end
    local animator = cachedAnimator
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            local a = track.Animation
            return a and tostring(a.AnimationId):match("%d+")
        end)
        if ok and animId and table.find(blockAnimIds, animId) then
            local timePos = 0
            pcall(function() timePos = track.TimePosition or 0 end)
            if timePos <= 0.12 then
                local nearest = getNearestKillerModel()
                if nearest then
                    task.wait(Ddelay)
                    task.spawn(function() beginDragIntoKiller(nearest) end)
                    startChargeAimUntilChargeEnds(0.4)
                end
            end
        end
    end
end)

task.spawn(function()
    if not cachedBlockBtn or not cachedCooldown or not cachedCharges then refreshUIRefs() end
    while true do
        RunService.Heartbeat:Wait()
        if not (hitboxDraggingTech and antiFlickOn) then task.wait(0.15) continue end
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then task.wait(0.15) continue end
        local found = nil
        for _, part in ipairs(workspace:GetDescendants()) do
            if not part:IsA("BasePart") then continue end
            if part.Name ~= "AntiFlickZone" then continue end
            if (part.Position - myRoot.Position).Magnitude <= HITBOX_DETECT_RADIUS then
                found = part
                break
            end
        end
        if found and not _hitboxDraggingDebounce then
            local nearest = getNearestKillerModel()
            if nearest then
                task.wait(Ddelay)
                task.spawn(function() beginDragIntoKiller(nearest) end)
                startChargeAimUntilChargeEnds(0.4)
            end
        end
        task.wait(0.12)
    end
end)

-- ============================================================
-- CUSTOM ANIM PLAYER
-- ============================================================
local function playCustomAnim(animId, isPunch)
    if not Humanoid then return end
    if not animId or animId == "" then return end
    local now = tick()
    local lastTime = isPunch and lastPunchTime or lastBlockTime
    if now - lastTime < 1 then return end
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        local animNum = tostring(track.Animation and track.Animation.AnimationId):match("%d+")
        if table.find(isPunch and punchAnimIds or blockAnimIds, animNum) then
            pcall(function() track:Stop() end)
        end
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId
    local success, track = pcall(function() return Humanoid:LoadAnimation(anim) end)
    if success and track then
        track:Play()
        if isPunch then lastPunchTime = now else lastBlockTime = now end
        local duration = isPunch and 2.7 or 2.0
        task.delay(duration, function()
            pcall(function() if track and track.IsPlaying then track:Stop() end end)
        end)
    end
end

-- ============================================================
-- CUSTOM CHARGE ANIM
-- ============================================================
local function playCustomChargeWithAutoStop(animId)
    if not lp or not lp.Character then return end
    local char = lp.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animId)
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return end
    track:Play()
    local stopped = false
    local touchConn, timeoutConn
    local function stopTrack()
        if stopped then return end
        stopped = true
        pcall(function() track:Stop() end)
        if touchConn and touchConn.Connected then pcall(function() touchConn:Disconnect() end) end
        if timeoutConn and timeoutConn.Connected then pcall(function() timeoutConn:Disconnect() end) end
    end
    touchConn = hrp.Touched:Connect(function(part)
        if stopped then return end
        if not part then return end
        if part:IsDescendantOf(char) then return end
        stopTrack()
    end)
    task.spawn(function()
        local start = tick()
        while not stopped and (tick() - start) < 4 do task.wait(0.05) end
        if not stopped then stopTrack() end
    end)
    pcall(function() if track.Stopped then track.Stopped:Connect(stopTrack) end end)
end

-- ============================================================
-- CUSTOM ANIM LOOP
-- ============================================================
local lastReplaceTime = { block = 0, punch = 0, charge = 0 }

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        local char = lp.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then continue end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local animId = tostring(track.Animation.AnimationId):match("%d+")

            if customBlockEnabled and customBlockAnimId ~= "" and table.find(blockAnimIds, animId) then
                if animId == tostring(customBlockAnimId) then continue end
                if tick() - lastReplaceTime.block >= 3 then
                    lastReplaceTime.block = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customBlockAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    newTrack:Play()
                    task.delay(customblockdelay, function()
                        pcall(function() if newTrack and newTrack.IsPlaying then newTrack:Stop() end end)
                    end)
                    break
                end
            end

            if customPunchEnabled and customPunchAnimId ~= "" and table.find(punchAnimIds, animId) then
                if animId == tostring(customPunchAnimId) then continue end
                if tick() - lastReplaceTime.punch >= 3 then
                    lastReplaceTime.punch = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customPunchAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    newTrack:Play()
                    task.delay(custompunchdelay, function()
                        pcall(function() if newTrack and newTrack.IsPlaying then newTrack:Stop() end end)
                    end)
                    break
                end
            end

            if customChargeEnabled and customChargeAnimId ~= "" and table.find(chargeAnimIds, animId) then
                if animId == tostring(customChargeAnimId) then continue end
                if tick() - lastReplaceTime.charge >= 3 then
                    lastReplaceTime.charge = tick()
                    track:Stop()
                    playCustomChargeWithAutoStop(customChargeAnimId)
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- MAIN AUTO BLOCK LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local gui = PlayerGui:FindFirstChild("MainUI")
    local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
    local charges = punchBtn and punchBtn:FindFirstChild("Charges")
    local blockBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Block")
    local cooldown = blockBtn and blockBtn:FindFirstChild("CooldownTime")

    local myChar = lp.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    Humanoid = myChar:FindFirstChildOfClass("Humanoid")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            local animTracks = animator and animator:GetPlayingAnimationTracks()
            if hrp and myRoot and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                for _, track in ipairs(animTracks or {}) do
                    local id = tostring(track.Animation.AnimationId):match("%d+")
                    if table.find(autoBlockTriggerAnims, id) then
                        if autoBlockOn and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                            if isFacing(myRoot, hrp) then
                                if cooldown and cooldown.Text == "" then fireRemoteBlock() end
                                if doubleblocktech == true and charges and charges.Text == "1" then fireRemotePunch() end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Predictive
    if predictiveBlockOn and tick() > predictiveCooldown then
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar:FindFirstChild("Humanoid")
        if killersFolder and myHRP and myHum then
            local killerInRange = false
            for _, killer in ipairs(killersFolder:GetChildren()) do
                local hrp = killer:FindFirstChild("HumanoidRootPart")
                if hrp and (myHRP.Position - hrp.Position).Magnitude <= detectionRange then
                    killerInRange = true
                    break
                end
            end
            if killerInRange then
                if not killerInRangeSince then
                    killerInRangeSince = tick()
                elseif tick() - killerInRangeSince >= edgeKillerDelay then
                    fireRemoteBlock()
                    predictiveCooldown = tick() + 2
                    killerInRangeSince = nil
                end
            else
                killerInRangeSince = nil
            end
        end
    end

    -- Auto Punch
    if autoPunchOn and charges and charges.Text == "1" then
        for _, name in ipairs(killerNames) do
            local killer = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers") and workspace.Players.Killers:FindFirstChild(name)
            if killer and killer:FindFirstChild("HumanoidRootPart") then
                local root = killer.HumanoidRootPart
                if root and myRoot and (root.Position - myRoot.Position).Magnitude <= 10 then
                    fireGuiPunch()
                    if flingPunchOn then
                        hiddenfling = true
                        local targetHRP = root
                        task.spawn(function()
                            local start = tick()
                            while tick() - start < 1 do
                                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and targetHRP and targetHRP.Parent then
                                    local frontPos = targetHRP.Position + (targetHRP.CFrame.LookVector * 2)
                                    lp.Character.HumanoidRootPart.CFrame = CFrame.new(frontPos, targetHRP.Position)
                                end
                                task.wait()
                            end
                            hiddenfling = false
                        end)
                    end
                    if customPunchEnabled and customPunchAnimId ~= "" then playCustomAnim(customPunchAnimId, true) end
                    break
                end
            end
        end
    end

    -- Message when punching
    do
        local animator = cachedAnimator
        if not animator then refreshAnimator(); animator = cachedAnimator end
        if animator then
            local currentPlaying = {}
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local animId
                    pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                    if animId and table.find(punchAnimIds, animId) then
                        currentPlaying[animId] = true
                        if not _punchPrevPlaying[animId] then
                            if messageWhenAutoPunchOn and messageWhenAutoPunch and tostring(messageWhenAutoPunch):match("%S") and (tick() - _lastPunchMessageTime) > MESSAGE_PUNCH_COOLDOWN then
                                pcall(function() sendChatMessage(messageWhenAutoPunch) end)
                                _lastPunchMessageTime = tick()
                            end
                        end
                    end
                end
            end
            _punchPrevPlaying = currentPlaying
        end
    end

    -- Message when blocking
    do
        local animator = cachedAnimator
        if not animator then refreshAnimator(); animator = cachedAnimator end
        if animator then
            local currentPlaying = {}
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local animId
                    pcall(function() animId = tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+") end)
                    if animId and table.find(blockAnimIds, animId) then
                        currentPlaying[animId] = true
                        if not _blockPrevPlaying[animId] then
                            if messageWhenAutoBlockOn and messageWhenAutoBlock and tostring(messageWhenAutoBlock):match("%S") and (tick() - _lastBlockMessageTime) > MESSAGE_BLOCK_COOLDOWN then
                                pcall(function() sendChatMessage(messageWhenAutoBlock) end)
                                _lastBlockMessageTime = tick()
                            end
                        end
                    end
                end
            end
            _blockPrevPlaying = currentPlaying
        end
    end

    -- Punch aimbot
    if aimPunch then
        if not cachedAnimator then refreshAnimator() end
        local animator = cachedAnimator
        if animator and myRoot and myChar then
            for _, name in ipairs(killerNames) do
                local killer = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers") and workspace.Players.Killers:FindFirstChild(name)
                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local animId = tostring(track.Animation.AnimationId):match("%d+")
                        if table.find(punchAnimIds, animId) then
                            local last = lastAimTrigger[track]
                            if not (last and tick() - last < AIM_COOLDOWN) then
                                local timePos = 0
                                pcall(function() timePos = track.TimePosition or 0 end)
                                if timePos <= 0.1 then
                                    lastAimTrigger[track] = tick()
                                    local humanoid = myChar:FindFirstChild("Humanoid")
                                    if humanoid then humanoid.AutoRotate = false end
                                    task.spawn(function()
                                        local start = tick()
                                        while tick() - start < AIM_WINDOW do
                                            if myRoot and root and root.Parent then
                                                local predictedPos = root.Position + (root.CFrame.LookVector * predictionValue)
                                                myRoot.CFrame = CFrame.lookAt(myRoot.Position, predictedPos)
                                            end
                                            task.wait()
                                        end
                                        if humanoid then humanoid.AutoRotate = true end
                                        task.delay(AIM_COOLDOWN - AIM_WINDOW, function() lastAimTrigger[track] = nil end)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local function addESP(obj)
    if not obj:IsA("Model") then return end
    if not obj:FindFirstChild("HumanoidRootPart") then return end
    local plr = Players:GetPlayerFromCharacter(obj)
    if not plr then return end
    if obj:FindFirstChild("ESP_Highlight") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = obj
    highlight.Parent = obj
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Adornee = obj:FindFirstChild("HumanoidRootPart")
    billboard.Parent = obj
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = obj.Name
    textLabel.Parent = billboard
end

local function clearESP(obj)
    if obj:FindFirstChild("ESP_Highlight") then obj.ESP_Highlight:Destroy() end
    if obj:FindFirstChild("ESP_Billboard") then obj.ESP_Billboard:Destroy() end
end

local function refreshESP()
    if not espEnabled then
        for _, killer in pairs(KillersFolder:GetChildren()) do clearESP(killer) end
        return
    end
    for _, killer in pairs(KillersFolder:GetChildren()) do addESP(killer) end
end

KillersFolder.ChildAdded:Connect(function(child)
    if espEnabled then task.wait(0.1); addESP(child) end
end)
KillersFolder.ChildRemoved:Connect(function(child) clearESP(child) end)

RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, killer in pairs(KillersFolder:GetChildren()) do
        local billboard = killer:FindFirstChild("ESP_Billboard")
        if billboard and billboard:FindFirstChild("ESP_Text") and killer:FindFirstChild("HumanoidRootPart") then
            local dist = (killer.HumanoidRootPart.Position - hrp.Position).Magnitude
            billboard.ESP_Text.Text = string.format("%s\n[%d]", killer.Name, dist)
        end
    end
end)

-- ============================================================
-- CONTROL CHARGE
-- ============================================================
local ORIGINAL_DASH_SPEED = 60
local controlChargeEnabled = false
local controlChargeActive = false
local overrideConnection = nil
local savedHumanoidState = {}

local function getHumanoid()
    if not lp or not lp.Character then return nil end
    return lp.Character:FindFirstChildOfClass("Humanoid")
end

local function saveHumState(hum)
    if not hum or savedHumanoidState[hum] then return end
    local s = {}
    pcall(function()
        s.WalkSpeed = hum.WalkSpeed
        local ok, _ = pcall(function() s.JumpPower = hum.JumpPower end)
        if not ok then pcall(function() s.JumpPower = hum.JumpHeight end) end
        local ok2, ar = pcall(function() return hum.AutoRotate end)
        if ok2 then s.AutoRotate = ar end
        s.PlatformStand = hum.PlatformStand
    end)
    savedHumanoidState[hum] = s
end

local function restoreHumState(hum)
    if not hum then return end
    local s = savedHumanoidState[hum]
    if not s then return end
    pcall(function()
        if s.WalkSpeed ~= nil then hum.WalkSpeed = s.WalkSpeed end
        if s.JumpPower ~= nil then
            local ok, _ = pcall(function() hum.JumpPower = s.JumpPower end)
            if not ok then pcall(function() hum.JumpHeight = s.JumpPower end) end
        end
        if s.AutoRotate ~= nil then pcall(function() hum.AutoRotate = s.AutoRotate end) end
        if s.PlatformStand ~= nil then hum.PlatformStand = s.PlatformStand end
    end)
    savedHumanoidState[hum] = nil
end

local function startOverride()
    if controlChargeActive then return end
    local hum = getHumanoid()
    if not hum then return end
    controlChargeActive = true
    saveHumState(hum)
    pcall(function()
        hum.WalkSpeed = ORIGINAL_DASH_SPEED
        hum.AutoRotate = false
    end)
    overrideConnection = RunService.RenderStepped:Connect(function()
        local humanoid = getHumanoid()
        local rootPart = humanoid and humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        pcall(function()
            humanoid.WalkSpeed = ORIGINAL_DASH_SPEED
            humanoid.AutoRotate = false
        end)
        local direction = rootPart.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        if horizontal.Magnitude > 0 then
            humanoid:Move(horizontal.Unit)
        else
            humanoid:Move(Vector3.new(0,0,0))
        end
    end)
end

local function stopOverride()
    if not controlChargeActive then return end
    controlChargeActive = false
    if overrideConnection then
        pcall(function() overrideConnection:Disconnect() end)
        overrideConnection = nil
    end
    local hum = getHumanoid()
    if hum then
        pcall(function()
            restoreHumState(hum)
            hum:Move(Vector3.new(0,0,0))
        end)
    end
end

local detectorChargeIds = chargeAnimIds
local function detectChargeAnimation()
    local hum = getHumanoid()
    if not hum then return false end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        local ok, animId = pcall(function()
            return tostring(track.Animation and track.Animation.AnimationId or ""):match("%d+")
        end)
        if ok and animId and animId ~= "" then
            if detectorChargeIds and table.find(detectorChargeIds, animId) then return true end
            if customChargeEnabled and customChargeAnimId and tostring(customChargeAnimId) ~= "" then
                if tostring(animId) == tostring(customChargeAnimId) then return true end
            end
        end
    end
    return false
end

local function ControlCharge_SetEnabled(val)
    controlChargeEnabled = val and true or false
    if not controlChargeEnabled and controlChargeActive then stopOverride() end
end

RunService.RenderStepped:Connect(function()
    if not controlChargeEnabled then
        if controlChargeActive then stopOverride() end
        return
    end
    local hum = getHumanoid()
    if not hum then
        if controlChargeActive then stopOverride() end
        return
    end
    local isCharging = detectChargeAnimation()
    if isCharging then
        if not controlChargeActive then startOverride() end
    else
        if controlChargeActive then stopOverride() end
    end
end)

_G.ControlCharge_SetEnabled = ControlCharge_SetEnabled

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
    Title = "Auto Block Hub",
    Footer = "by Skibidi Shots (Obsidian port)",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Notice       = Window:AddTab("Notice", "user"),
    AutoBlock    = Window:AddTab("Auto Block", "sword"),
    BD           = Window:AddTab("Better Detection", "sword"),
    Tech         = Window:AddTab("Techs", "sword"),
    Predictive   = Window:AddTab("Predictive AB", "wrench"),
    FakeBlock    = Window:AddTab("Fake Block", "user"),
    AutoPunch    = Window:AddTab("Auto Punch", "wrench"),
    CustomAnim   = Window:AddTab("Custom Anims", "user"),
    Misc         = Window:AddTab("Misc", "swords"),
    ["UI Settings"] = Window:AddTab("Settings", "settings"),
}

-- ============================================================
-- NOTICE TAB
-- ============================================================
local NoticeLeft = Tabs.Notice:AddLeftGroupbox("welcome")
NoticeLeft:AddLabel("thanks for using my wonderful auto block script")
NoticeLeft:AddLabel("some features may only work with guest skins thats using the default anims")
NoticeLeft:AddLabel(".gg/Tmby2GkKJR")

-- ============================================================
-- AUTO BLOCK TAB
-- ============================================================
local ABLeft = Tabs.AutoBlock:AddLeftGroupbox("Auto Block")
local ABRight = Tabs.AutoBlock:AddRightGroupbox("Extra")

ABLeft:AddToggle("AutoBlockAnimation", {
    Text = "Auto Block (Animation)",
    Default = false,
    Tooltip = "auto block animation detection",
    Callback = function(Value) autoBlockOn = Value end,
})

ABLeft:AddToggle("AutoBlockAudio", {
    Text = "Auto Block (Audio)",
    Default = false,
    Tooltip = "auto block audio detection",
    Callback = function(state) autoBlockAudioOn = state end,
})

ABLeft:AddButton("Change auto block type", function()
    if autoblocktype == "Block" then
        autoblocktype = "Charge"
        SendNotif("changed auto block type", "CHARGE", 4)
    elseif autoblocktype == "Charge" then
        autoblocktype = "7n7 Clone"
        SendNotif("changed auto block type", "7N7 CLONE", 4)
    elseif autoblocktype == "7n7 Clone" then
        autoblocktype = "Block"
        SendNotif("changed auto block type", "BLOCK", 4)
    end
end)

ABLeft:AddLabel("Recommendation: use audio auto block and use 20 range for it")

ABLeft:AddToggle("MessageWhenBlockToggle", {
    Text = "Message When Blocking",
    Default = false,
    Callback = function(Value) messageWhenAutoBlockOn = Value end,
})

ABLeft:AddInput("blockdelaynumber", {
    Text = "Block Delay",
    Default = "",
    Placeholder = "0",
    Numeric = true,
    Callback = function(Text)
        blockdelay = tonumber(Text) or blockdelay
    end,
})

ABLeft:AddInput("MessageWhenBlockText", {
    Text = "Message when blocking",
    Default = "",
    Placeholder = "im gonna block ya",
    Callback = function(Text) messageWhenAutoBlock = Text end,
})

ABLeft:AddLabel("Note: face check delays on c00lkidd, dont use face check against c00lkidd")

ABLeft:AddToggle("FacingCheckToggle", {
    Text = "Enable Facing Check",
    Default = true,
    Callback = function(Value) facingCheckEnabled = Value end,
})

ABLeft:AddToggle("FacingCheckVisualToggle", {
    Text = "Facing Check Visual",
    Default = false,
    Callback = function(state) facingVisualOn = state; refreshFacingVisuals() end,
})

ABLeft:AddLabel("Facing check visual isn't accurate — it's there to give you an idea of the facing check")

ABLeft:AddInput("Facingcheckdot", {
    Text = "Facing Check angle (DOT)",
    Default = "-0.3",
    Placeholder = "-0.3",
    Numeric = true,
    Callback = function(Text)
        customFacingDot = tonumber(Text) or customFacingDot
    end,
})

ABLeft:AddLabel("DOT explanation: 0 = must be exactly in front. -0.3/-0.5 = wider cone. -1 = half-circle in front.")

ABLeft:AddInput("DetectionRange", {
    Text = "Detection Range",
    Default = "18",
    Placeholder = "18",
    Numeric = true,
    Callback = function(Text)
        detectionRange = tonumber(Text) or detectionRange
        detectionRangeSq = detectionRange * detectionRange
    end,
})

ABRight:AddToggle("KillerCircleToggle", {
    Text = "Range Visual",
    Default = false,
    Callback = function(state) killerCirclesVisible = state; refreshKillerCircles() end,
})

-- ============================================================
-- BETTER DETECTION TAB
-- ============================================================
local BDLeft = Tabs.BD:AddLeftGroupbox("Better Detection")
local BDRight = Tabs.BD:AddRightGroupbox("Prediction Tuning")

BDLeft:AddLabel("BD delays on c00lkidd — use normal detection against c00lkidd")

BDLeft:AddToggle("AntiFlickToggle", {
    Text = "Better Detection (doesn't use detect range)",
    Default = false,
    Callback = function(state) antiFlickOn = state end,
})

BDLeft:AddSlider("AntiFlickParts", {
    Text = "How many block parts to spawn",
    Default = 4,
    Min = 1,
    Max = 16,
    Rounding = 0,
    Suffix = " parts",
    Callback = function(val) antiFlickParts = math.max(1, math.floor(val)) end,
})

BDLeft:AddSlider("BlockPartsSizeMultiplier", {
    Text = "Block Parts Size Multiplier ×10",
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(val) blockPartsSizeMultiplier = val / 10 end,
})

BDRight:AddSlider("PredictionStrength", {
    Text = "Forward Prediction Strength ×10",
    Default = 10,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(val) predictionStrength = val / 10 end,
})

BDRight:AddSlider("PredictionTurnStrength", {
    Text = "Turn Prediction Strength ×10",
    Default = 10,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(val) predictionTurnStrength = val / 10 end,
})

BDRight:AddInput("AntiFlickDelay", {
    Text = "delay before first block part spawn (s) (DBTFBPS)",
    Default = "0",
    Placeholder = "0",
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then antiFlickDelay = math.max(0, num) end
    end,
})

BDRight:AddToggle("AutoAdjustDBTFBPS", {
    Text = "Auto-adjust DBTFBPS based on killer",
    Default = false,
    Callback = function(state)
        autoAdjustDBTFBPS = state
        if state then
            _savedManualAntiFlickDelay = antiFlickDelay or 0
            doImmediateUpdate()
        else
            antiFlickDelay = _savedManualAntiFlickDelay
        end
    end,
})

BDRight:AddInput("AntiFlickDelayEachParts", {
    Text = "delay before each block part spawns (s)",
    Default = "0.02",
    Placeholder = "0.02",
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then stagger = math.max(0, num) end
    end,
})

BDRight:AddInput("AntiFlickDistanceInfront", {
    Text = "how many studs in front of killer parts spawn",
    Default = "2.7",
    Placeholder = "2.7",
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then antiFlickBaseOffset = math.max(0, num) end
    end,
})

-- ============================================================
-- TECHS TAB
-- ============================================================
local TechLeft = Tabs.Tech:AddLeftGroupbox("Techs")
local TechRight = Tabs.Tech:AddRightGroupbox("Info")

TechLeft:AddToggle("doubleblockTechtoggle", {
    Text = "Double Punch Tech",
    Default = false,
    Callback = function(state) doubleblocktech = state end,
})

TechLeft:AddToggle("HitboxDraggingToggle", {
    Text = "Hitbox Dragging tech (HDT)",
    Default = false,
    Callback = function(state) hitboxDraggingTech = state end,
})

TechLeft:AddInput("HDTspeed", {
    Text = "HDT speed",
    Default = "5.6",
    Placeholder = "5.6",
    Numeric = true,
    Callback = function(Text) Dspeed = tonumber(Text) or Dspeed end,
})

TechLeft:AddInput("HDTdelay", {
    Text = "HDT delay",
    Default = "0",
    Placeholder = "0",
    Numeric = true,
    Callback = function(Text) Ddelay = tonumber(Text) or Ddelay end,
})

TechRight:AddLabel("Hitbox Dragging tech:")
TechRight:AddLabel("recommend a high detection range when using this")

TechLeft:AddButton("Fake Lag Tech", function()
    pcall(function()
        local char = lp.Character or lp.CharacterAdded:Wait()
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            local id = tostring(t.Animation and t.Animation.AnimationId or ""):match("%d+")
            if id == "136252471123500" then pcall(function() t:Stop() end) end
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://136252471123500"
        local track = animator:LoadAnimation(anim)
        track:Play()
    end)
end)

-- ============================================================
-- PREDICTIVE TAB
-- ============================================================
local PredLeft = Tabs.Predictive:AddLeftGroupbox("Predictive Auto Block")

PredLeft:AddToggle("predictiveABtoggle", {
    Text = "Predictive Auto Block",
    Default = false,
    Callback = function(Value) predictiveBlockOn = Value end,
})

PredLeft:AddInput("predictiveABrange", {
    Text = "Detection Range",
    Default = "10",
    Placeholder = "10",
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then detectionRange = num end
    end,
})

PredLeft:AddSlider("edgekillerlmao", {
    Text = "Edge Killer Delay ×10",
    Default = 30,
    Min = 0,
    Max = 70,
    Rounding = 0,
    Callback = function(val) edgeKillerDelay = val / 10 end,
})

PredLeft:AddLabel("Edge Killer: seconds until it blocks (resets when killer leaves range)")

-- ============================================================
-- FAKE BLOCK TAB
-- ============================================================
local FBLeft = Tabs.FakeBlock:AddLeftGroupbox("Fake Block")
FBLeft:AddButton("Load Fake Block", function()
    pcall(function()
        local fakeGui = PlayerGui:FindFirstChild("FakeBlockGui")
        if not fakeGui then
            local success, result = pcall(function()
                return loadstring(game:HttpGet("https://raw.githubusercontent.com/skibidi399/Auto-block-script/refs/heads/main/fakeblock"))()
            end)
            if not success then
                warn("❌ Failed to load Fake Block GUI:", result)
            end
        else
            fakeGui.Enabled = true
            print("✅ Fake Block GUI enabled")
        end
    end)
end)

-- ============================================================
-- AUTO PUNCH TAB
-- ============================================================
local APLeft = Tabs.AutoPunch:AddLeftGroupbox("Auto Punch")

APLeft:AddToggle("AutoPunchToggle", {
    Text = "Auto Punch",
    Default = false,
    Callback = function(Value) autoPunchOn = Value end,
})

APLeft:AddToggle("MessageWhenPunchToggle", {
    Text = "Message When Punching",
    Default = false,
    Callback = function(Value) messageWhenAutoPunchOn = Value end,
})

APLeft:AddInput("MessageWhenPunchText", {
    Text = "Message when punching",
    Default = "",
    Placeholder = "Im not gonna sugarcoat it.",
    Callback = function(Text) messageWhenAutoPunch = Text end,
})

APLeft:AddToggle("flingpunchtoggle", {
    Text = "Fling Punch",
    Default = false,
    Callback = function(Value) flingPunchOn = Value end,
})

APLeft:AddToggle("PunchAimToggle", {
    Text = "Punch Aimbot",
    Default = false,
    Callback = function(Value) aimPunch = Value end,
})

APLeft:AddSlider("PredictionSlider", {
    Text = "Aim Prediction ×10",
    Default = 40,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value) predictionValue = Value / 10 end,
})

APLeft:AddSlider("FlingPower", {
    Text = "Fling Power (millions)",
    Default = 10000,
    Min = 1,
    Max = 50000000,
    Rounding = 0,
    Callback = function(Value) flingPower = Value end,
})

-- ============================================================
-- CUSTOM ANIMATIONS TAB
-- ============================================================
local CALeft = Tabs.CustomAnim:AddLeftGroupbox("Block")
local CARight = Tabs.CustomAnim:AddRightGroupbox("Punch / Charge")

CALeft:AddInput("customblockid", {
    Text = "Custom Block Animation",
    Default = "",
    Placeholder = "AnimationId",
    Numeric = true,
    Callback = function(Text) customBlockAnimId = Text end,
})

CALeft:AddToggle("blockanimtoggle", {
    Text = "Enable Custom Block Animation",
    Default = false,
    Callback = function(Value) customBlockEnabled = Value end,
})

CALeft:AddInput("customblockdelaystop", {
    Text = "delay before stop anim (block)",
    Default = "2",
    Placeholder = "2",
    Numeric = true,
    Callback = function(Text) customblockdelay = tonumber(Text) or customblockdelay end,
})

CARight:AddInput("custompunchid", {
    Text = "Custom Punch Animation (not for M3/M4)",
    Default = "",
    Placeholder = "AnimationId",
    Numeric = true,
    Callback = function(Text) customPunchAnimId = Text end,
})

CARight:AddToggle("punchanimtoggle", {
    Text = "Enable Custom Punch Animation",
    Default = false,
    Callback = function(Value) customPunchEnabled = Value end,
})

CARight:AddInput("custompunchdelaystop", {
    Text = "delay before stop anim (punch)",
    Default = "2",
    Placeholder = "2",
    Numeric = true,
    Callback = function(Text) custompunchdelay = tonumber(Text) or custompunchdelay end,
})

CARight:AddInput("customchargeid", {
    Text = "Charge Animation ID",
    Default = "",
    Placeholder = "Put animation ID here",
    Numeric = true,
    Callback = function(input) customChargeAnimId = input end,
})

CARight:AddToggle("chargeanimtoggle", {
    Text = "Custom Charge Animation",
    Default = false,
    Callback = function(value) customChargeEnabled = value end,
})

-- ============================================================
-- MISC TAB
-- ============================================================
local MiscLeft = Tabs.Misc:AddLeftGroupbox("Universal")
local MiscRight = Tabs.Misc:AddRightGroupbox("Forsaken")

MiscLeft:AddButton("Run Infinite Yield", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

MiscLeft:AddButton("c00lgui (custom stamina, esp)", function()
    loadstring(game:HttpGet("https://rawscripts.net/raw/Forsaken-c00lgui-v15-ESP-EDITABLE-STAMINA-41624"))()
end)

MiscRight:AddToggle("controlcharge", {
    Text = "Control Charge",
    Default = false,
    Tooltip = "lets you control your charge better (only works on default anim charge)",
    Callback = function(val)
        if _G.ControlCharge_SetEnabled then
            pcall(function() _G.ControlCharge_SetEnabled(val) end)
        else
            _G.ControlCharge_WantedEnabled = val
        end
    end,
})

MiscRight:AddLabel("Tip: Run Infinite Yield and type antifling so punch fling works better")

MiscRight:AddToggle("KillerESP_Toggle", {
    Text = "Killer ESP",
    Default = false,
    Callback = function(Value) espEnabled = Value; refreshESP() end,
})

MiscRight:AddButton("Remove Slowness (only the status effect)", function()
    game:GetService("ReplicatedStorage").Modules.StatusEffects.Slowness:Destroy()
end)

MiscRight:AddButton("infinite resistence 100% real not fake trust", function()
    lp:Kick("u got banned from roblxo permandnenly very real not fake trust %100")
end)

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
    Values = {"50%","75%","100%","125%","150%","175%","200%"},
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

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("autoblock")
SaveManager:SetFolder("autoblock/games")
SaveManager:SetSubFolder("Forsaken")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

-- Load saved settings
pcall(function() SaveManager:LoadAutoloadConfig() end)

print("[Auto Block Hub] Obsidian port loaded — RightShift toggles UI")
