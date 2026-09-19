--[[
    Forsaken Auto Block — Strict M1 Edition (v4.3)
    ============================================================
    Strict Facing: 65 degrees
    Loose Facing: 90 degrees
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Stats             = game:GetService("Stats")

local LP = Players.LocalPlayer
if not LP then warn("[AB] No LocalPlayer"); return end

local function safeWait(parent, name, timeout)
    if not parent then return nil end
    local c = parent:FindFirstChild(name)
    if c then return c end
    local ok, r = pcall(function() return parent:WaitForChild(name, timeout or 5) end)
    return ok and r or nil
end

local PG = safeWait(LP, "PlayerGui", 10)
if not PG then warn("[AB] No PlayerGui"); return end
local safeUIParent = (type(gethui) == "function" and gethui()) or PG

local PlayersFolder = safeWait(workspace, "Players", 5)
local KF = PlayersFolder and safeWait(PlayersFolder, "Killers", 5) or nil
if not KF then warn("[AB] No Killers folder") end

local RE = safeWait(safeWait(safeWait(ReplicatedStorage, "Modules", 5), "Network", 5), "RemoteEvent", 5)
if not RE then warn("[AB] No RemoteEvent found!") end

-- ============================================================
-- CONNECTION TRACKER
-- ============================================================
local ConnTracker = {}
local function track(conn)
    table.insert(ConnTracker, conn)
    return conn
end
local function killAllConnections()
    for _, c in ipairs(ConnTracker) do
        if typeof(c) == "Instance" then c:Disconnect() end
    end
    table.clear(ConnTracker)
end

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled           = true,
    AutoBlock         = true,
    AutoPunch         = false,
    Range             = 12,
    AdaptiveRange     = true,
    PredictAhead      = 0.10,
    PredictiveBlock   = true,
    AngularPrediction = true,
    FacingMode        = "Loose",
    KillerESP         = true,
    SurvivorESP       = false,
    Visualizer        = true,
    StatsOverlay      = true,
    Debug             = false,
}

-- ============================================================
-- KILLER PROFILES
-- ============================================================
local KillerProfiles = {
    ["c00lkidd"]  = { Range = 10, FacingMode = "Strict", Predict = 0.08 },
    ["C00lkidd"]  = { Range = 10, FacingMode = "Strict", Predict = 0.08 },
    ["Jason"]     = { Range = 12, FacingMode = "Loose",  Predict = 0.12 },
    ["Slasher"]   = { Range = 12, FacingMode = "Loose",  Predict = 0.12 },
    ["1x1x1x1"]   = { Range = 11, FacingMode = "Loose",  Predict = 0.10 },
    ["JohnDoe"]   = { Range = 14, FacingMode = "Loose",  Predict = 0.10 },
    ["John Doe"]  = { Range = 14, FacingMode = "Loose",  Predict = 0.10 },
    ["Noli"]      = { Range = 12, FacingMode = "Loose",  Predict = 0.12 },
    ["Sixer"]     = { Range = 12, FacingMode = "Loose",  Predict = 0.12 },
    ["Azure"]     = { Range = 13, FacingMode = "Loose",  Predict = 0.12 },
    ["Guest666"]  = { Range = 11, FacingMode = "Strict", Predict = 0.08 },
    ["Nosferatu"] = { Range = 13, FacingMode = "Loose",  Predict = 0.12 },
}

-- ============================================================
-- FILTERS
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

local SOUND_PARENT_WHITELIST = {
    HumanoidRootPart = true, UpperTorso = true, Torso = true,
    RightHand = true, RightArm = true, Weapon = true, Tool = true,
}
local SOUND_PARENT_BLACKLIST = {
    Abilities = true, Effects = true, Projectiles = true,
    Ambient = true, Footsteps = true,
}

-- Facing cone sizes (in degrees)
local FACING_STRICT_DEG = 65     -- Strict: 65 degree cone
local FACING_LOOSE_DEG  = 90     -- Loose: 90 degree cone (full front hemisphere)

-- ============================================================
-- STATE
-- ============================================================
local S = {
    lastBlock      = 0,
    blockCount     = 0,
    punchCount     = 0,
    frameTick      = 0,
    tickRate       = 2,
    killer         = nil,
    killerData     = {},
    killerSounds   = {},
    killerParts    = {},
    myRoot         = nil,
    myHum          = nil,
    myChar         = nil,
    blockBtn       = nil,
    blockCD        = nil,
    punchBtn       = nil,
    punchCD        = nil,
    soundDebounce  = {},
    statsLabel     = nil,
    uiRefs         = {},
    vizPart        = nil,
    blockQueue     = 0,
    sliderRefs     = {},
    currentProfile = nil,
}

local function log(msg) if Config.Debug then print("[AB Debug] " .. msg) end end

-- ============================================================
-- KILL SWITCH
-- ============================================================
local function clearESP(parent)
    if not parent then return end
    for _, c in ipairs(parent:GetChildren()) do
        local hl = c:FindFirstChild("HUB_ESP")
        local bb = c:FindFirstChild("HUB_ESP_BB")
        if hl then hl:Destroy() end
        if bb then bb:Destroy() end
    end
end

local function killSwitch()
    Config.Enabled = false
    killAllConnections()
    for _, obj in pairs(S.uiRefs) do
        if obj and obj.Parent then pcall(function() obj:Destroy() end) end
    end
    table.clear(S.uiRefs)
    if S.vizPart and S.vizPart.Parent then S.vizPart:Destroy() end
    clearESP(KF)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then clearESP(p.Character) end
    end
    print("[AB] Kill switch activated")
end

-- ============================================================
-- CORE HELPERS
-- ============================================================
local CachedPing = 50
local LastPingUpdate = 0
local function getPing()
    local now = os.clock()
    if now - LastPingUpdate > 0.5 then
        LastPingUpdate = now
        local ok, p = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ok then CachedPing = p end
    end
    return CachedPing
end

local function getRange()
    if not Config.AdaptiveRange then return Config.Range end
    local p = getPing()
    if p > 150 then return Config.Range + 2 end
    if p > 100 then return Config.Range + 1 end
    return Config.Range
end

local function getPredictAhead()
    return Config.PredictAhead + math.clamp((getPing() - 50) / 1000, 0, 0.06)
end

local function refreshMyChar()
    local c = LP.Character
    if c ~= S.myChar then
        S.myChar = c
        S.myRoot = c and c:FindFirstChild("HumanoidRootPart")
        S.myHum  = c and c:FindFirstChildOfClass("Humanoid")
    end
end

local function refreshButtonCache()
    local mainUI = PG:FindFirstChild("MainUI")
    local cont = mainUI and mainUI:FindFirstChild("AbilityContainer")
    S.blockBtn = cont and cont:FindFirstChild("Block") or nil
    S.punchBtn = cont and cont:FindFirstChild("Punch") or nil
    S.blockCD  = S.blockBtn and S.blockBtn:FindFirstChild("CooldownTime") or nil
    S.punchCD  = S.punchBtn and S.punchBtn:FindFirstChild("CooldownTime") or nil
end

local function isBlockReady()
    if not S.blockBtn or not S.blockBtn.Parent then refreshButtonCache() end
    if not S.blockCD or not S.blockCD.Parent then refreshButtonCache() end
    return S.blockCD and S.blockCD.Text == ""
end

local function isPunchReady()
    if not S.punchBtn or not S.punchBtn.Parent then refreshButtonCache() end
    if not S.punchCD or not S.punchCD.Parent then refreshButtonCache() end
    if S.punchCD then return S.punchCD.Text == "" end
    local ch = S.punchBtn and S.punchBtn:FindFirstChild("Charges")
    if ch then return ch.Text == "1" end
    return false
end

local function canAct()
    if not S.myHum or S.myHum.Health <= 0 then return false end
    local state = S.myHum:GetState()
    return state ~= Enum.HumanoidStateType.Dead
       and state ~= Enum.HumanoidStateType.Ragdoll
       and state ~= Enum.HumanoidStateType.FallingDown
end

-- ============================================================
-- KILLER CACHE
-- ============================================================
local function getKillerCache(killer)
    local cached = S.killerParts[killer]
    if cached and cached.hrp and cached.hrp.Parent and cached.hum and cached.hum.Parent then
        return cached.hrp, cached.hum
    end
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    local hum = killer:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        S.killerParts[killer] = { hrp = hrp, hum = hum }
        return hrp, hum
    end
    return nil, nil
end

local function clearKillerCache(killer)
    S.killerData[killer] = nil
    S.killerSounds[killer] = nil
    S.killerParts[killer] = nil
end

-- ============================================================
-- FACING
-- ============================================================
local function isFacing(myRoot, targetRoot)
    local diff = myRoot.Position - targetRoot.Position
    if diff.Magnitude < 0.01 then return true end
    local dot = targetRoot.CFrame.LookVector:Dot(diff.Unit)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    local maxAngle = (Config.FacingMode == "Strict") and FACING_STRICT_DEG or FACING_LOOSE_DEG
    return angle <= maxAngle
end

-- ============================================================
-- STRICT M1
-- ============================================================
local AnimIDCache = {}
local ANIM_CACHE_LIMIT = 500

local function extractId(track)
    local anim = track.Animation
    if not anim or not anim.AnimationId then return nil end
    local raw = anim.AnimationId
    local cached = AnimIDCache[raw]
    if cached then return cached end
    local id = raw:match("%d+")
    if next(AnimIDCache) and #AnimIDCache > ANIM_CACHE_LIMIT then table.clear(AnimIDCache) end
    AnimIDCache[raw] = id
    return id
end

local function isStrictM1(track)
    if track.Looped then return false end
    local prio = track.Priority
    if prio == Enum.AnimationPriority.Core
    or prio == Enum.AnimationPriority.Idle
    or prio == Enum.AnimationPriority.Movement then
        return false
    end
    local animName = track.Animation and track.Animation.Name:lower() or ""
    if animName:match("walk") or animName:match("run") or animName:match("idle")
    or animName:match("equip") or animName:match("jump") or animName:match("fall")
    or animName:match("sprint") or animName:match("crouch") then
        return false
    end
    local id = extractId(track)
    if id and ABILITY_IDS[id] then return false end
    return true
end

local function isStrictAttackSound(sound)
    if sound.Looped then return false end
    local parent = sound.Parent
    if not parent then return false end
    if SOUND_PARENT_BLACKLIST[parent.Name] then return false end
    if not SOUND_PARENT_WHITELIST[parent.Name] then return false end
    local sName = sound.Name:lower()
    if sName:match("step") or sName:match("walk") or sName:match("run")
    or sName:match("breath") or sName:match("equip") or sName:match("idle")
    or sName:match("ambient") or sName:match("wind") then
        return false
    end
    return true
end

-- ============================================================
-- SOUND CACHE
-- ============================================================
local function rebuildSoundCache(killer)
    local hrp = killer:FindFirstChild("HumanoidRootPart")
    if not hrp then
        S.killerSounds[killer] = {}
        return S.killerSounds[killer]
    end
    local sounds = {}
    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("Sound") then table.insert(sounds, child) end
    end
    S.killerSounds[killer] = sounds
    return sounds
end

-- ============================================================
-- ACTIONS
-- ============================================================
local function doBlock()
    if not Config.Enabled or not canAct() then return end
    local now = os.clock()
    if now - S.lastBlock < 0.15 then
        S.blockQueue = math.min(S.blockQueue + 1, 1)
        return
    end
    if not isBlockReady() or not S.myRoot then return end

    if RE then
        pcall(function()
            RE:FireServer("UseActorAbility", { buffer.fromstring("\"Block\"") })
        end)
    end
    S.lastBlock = now
    S.blockCount += 1
    log("BLOCK fired")

    if Config.AutoPunch then
        task.delay(0.04, function()
            if Config.Enabled and canAct() and isPunchReady() then
                if RE then
                    pcall(function()
                        RE:FireServer("UseActorAbility", { buffer.fromstring("\"Punch\"") })
                    end)
                end
                S.punchCount += 1
                log("PUNCH fired")
            end
        end)
    end
end

local function checkKiller(killer)
    if not Config.Enabled or not S.myRoot then return end
    local er, eh = getKillerCache(killer)
    if not er or not eh then return end

    if (er.Position - S.myRoot.Position).Magnitude > getRange() then return end
    if not isFacing(S.myRoot, er) then return end

    local animator = eh:FindFirstChildOfClass("Animator")
    if animator then
        local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
        if ok and tracks then
            for _, track in ipairs(tracks) do
                if isStrictM1(track) and (track.TimePosition or 0) <= getPredictAhead() then
                    doBlock()
                    return
                end
            end
        end
    end

    local sounds = S.killerSounds[killer]
    if not sounds then sounds = rebuildSoundCache(killer) end
    for _, sound in ipairs(sounds) do
        if sound.Parent and sound.IsPlaying and isStrictAttackSound(sound) then
            local now = os.clock()
            if (S.soundDebounce[sound] or 0) < now then
                S.soundDebounce[sound] = now + 0.3
                doBlock()
                return
            end
        end
    end
end

-- ============================================================
-- EVENT-DRIVEN CACHE MANAGEMENT
-- ============================================================
if KF then
    track(KF.ChildRemoved:Connect(function(child)
        clearKillerCache(child)
        if S.killer == child then
            S.killer = nil
            S.currentProfile = nil
        end
    end))

    track(KF.DescendantAdded:Connect(function(desc)
        if desc:IsA("Sound") then
            local killer = desc:FindFirstAncestorOfClass("Model")
            if killer and killer.Parent == KF then
                rebuildSoundCache(killer)
            end
        end
    end))
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
track(RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    refreshMyChar()
    if not S.myRoot then return end
    S.frameTick += 1

    if not S.blockBtn or not S.blockBtn.Parent then refreshButtonCache() end

    local killerDist = math.huge
    if S.killer and S.killer.Parent then
        local er = getKillerCache(S.killer)
        if er then killerDist = (er.Position - S.myRoot.Position).Magnitude end
    end

    S.tickRate = killerDist < 25 and 1 or (killerDist < 60 and 2 or 4)
    if S.frameTick % S.tickRate ~= 0 then return end
    if not Config.AutoBlock or not KF then return end

    local foundKiller = false
    for _, k in ipairs(KF:GetChildren()) do
        if k:IsA("Model") then
            local er = getKillerCache(k)
            if er then
                local dist = (er.Position - S.myRoot.Position).Magnitude
                if dist < killerDist then
                    killerDist = dist
                    S.killer = k
                    foundKiller = true
                end
            end
        end
    end

    if not foundKiller then
        S.killer = nil
        S.currentProfile = nil
    end

    if S.killer and S.killer.Parent then
        if S.currentProfile ~= S.killer.Name then
            S.currentProfile = S.killer.Name
            local profile = KillerProfiles[S.killer.Name]
            if profile then
                if profile.Range then Config.Range = profile.Range end
                if profile.FacingMode then Config.FacingMode = profile.FacingMode end
                if profile.Predict then Config.PredictAhead = profile.Predict end

                local sdR = S.sliderRefs["Range"]
                if sdR then
                    sdR.lbl.Text = "Range: " .. Config.Range
                    sdR.fill.Size = UDim2.new((Config.Range - 5) / 20, 0, 1, 0)
                end
                local sdP = S.sliderRefs["PredictAhead"]
                if sdP then
                    local ms = math.floor(Config.PredictAhead * 1000)
                    sdP.lbl.Text = "Predict Ahead (ms): " .. ms
                    sdP.fill.Size = UDim2.new((ms - 50) / 250, 0, 1, 0)
                end
                log("Profile applied: " .. S.killer.Name)
            end
        end
        checkKiller(S.killer)
    end

    if S.blockQueue > 0 and (os.clock() - S.lastBlock) >= 0.15 and isBlockReady() then
        S.blockQueue -= 1
        doBlock()
    end
end))

-- ============================================================
-- VISUALIZER + ESP + STATS
-- ============================================================
local function addESP(obj, color, label)
    if not obj or obj:FindFirstChild("HUB_ESP") then return end
    local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
    if not hrp then return end

    local hl = Instance.new("Highlight")
    hl.Name, hl.FillColor = "HUB_ESP", color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Name, bb.Size = "HUB_ESP_BB", UDim2.new(0, 140, 0, 30)
    bb.AlwaysOnTop, bb.Adornee = true, hrp
    bb.Parent = obj

    local lbl = Instance.new("TextLabel")
    lbl.Name, lbl.Size = "HUB_ESP_Label", UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font, lbl.TextScaled = Enum.Font.GothamBold, true
    lbl.TextColor3, lbl.TextStrokeTransparency = color, 0.3
    lbl.Text = label or obj.Name
    lbl.Parent = bb
end

local function refreshESP()
    if not Config.Enabled then return end
    if KF then
        for _, k in ipairs(KF:GetChildren()) do
            if Config.KillerESP then addESP(k, Color3.fromRGB(255, 50, 50), k.Name)
            else clearESP(k) end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if Config.SurvivorESP then addESP(p.Character, Color3.fromRGB(80, 200, 255), p.Name)
            else clearESP(p.Character) end
        end
    end
end

track(RunService.RenderStepped:Connect(function()
    if not Config.Enabled then return end

    if Config.Visualizer and S.myRoot then
        if not S.vizPart then
            S.vizPart = Instance.new("Part")
            S.vizPart.Name, S.vizPart.Shape = "AB_RangeViz", Enum.PartType.Cylinder
            S.vizPart.Anchored, S.vizPart.CanCollide = true, false
            S.vizPart.CanQuery, S.vizPart.CanTouch = false, false
            S.vizPart.Material = Enum.Material.ForceField
            S.vizPart.Color, S.vizPart.Transparency = Color3.fromRGB(90, 170, 255), 0.75
            S.vizPart.Parent = workspace
        end
        local r = getRange()
        S.vizPart.Size = Vector3.new(0.2, r * 2, r * 2)
        S.vizPart.CFrame = S.myRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))
    elseif S.vizPart then
        S.vizPart:Destroy()
        S.vizPart = nil
    end

    if Config.StatsOverlay and S.statsLabel then
        local blockSt = isBlockReady() and "R" or "CD"
        local punchSt = isPunchReady() and "R" or "CD"
        local queueStr = S.blockQueue > 0 and (" | Q:" .. S.blockQueue) or ""
        S.statsLabel.Text = string.format(
            "Ping:%dms | Blocks:%d | Punch:%d%s\nBlock:%s | Punch:%s | Killer:%s | Range:%d",
            math.floor(getPing()), S.blockCount, S.punchCount, queueStr,
            blockSt, punchSt,
            S.killer and S.killer.Name or "None",
            getRange()
        )
    elseif S.statsLabel then
        S.statsLabel.Text = ""
    end

    if Config.KillerESP and S.myRoot and KF then
        for _, k in ipairs(KF:GetChildren()) do
            local bb = k:FindFirstChild("HUB_ESP_BB")
            local hrp = k:FindFirstChild("HumanoidRootPart")
            if bb and hrp then
                local lbl = bb:FindFirstChild("HUB_ESP_Label")
                if lbl then
                    lbl.Text = string.format("%s  [%d]", k.Name,
                        math.floor((hrp.Position - S.myRoot.Position).Magnitude))
                end
            end
        end
    end
end))

-- ============================================================
-- UI
-- ============================================================
local T = {
    bg      = Color3.fromRGB(18, 18, 22),
    panel   = Color3.fromRGB(28, 28, 34),
    accent  = Color3.fromRGB(140, 100, 255),
    text    = Color3.fromRGB(240, 240, 248),
    subtext = Color3.fromRGB(150, 150, 168),
    border  = Color3.fromRGB(48, 48, 58),
    on      = Color3.fromRGB(65, 185, 100),
    off     = Color3.fromRGB(190, 60, 60),
}

local function mk(cls, prp, prnt)
    local o = Instance.new(cls)
    for k, v in pairs(prp or {}) do o[k] = v end
    if prnt then o.Parent = prnt end
    return o
end
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end
local function stroke(p)
    local s = Instance.new("UIStroke")
    s.Color, s.Thickness, s.Parent = T.border, 1, p
end

local screen = mk("ScreenGui", {
    Name = "AB_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, safeUIParent)
S.uiRefs.screen = screen

local main = mk("Frame", {
    Size = UDim2.new(0, 340, 0, 460),
    Position = UDim2.new(0, 20, 0.5, -230),
    BackgroundColor3 = T.bg, BorderSizePixel = 0, Active = true,
}, screen)
corner(main, 10); stroke(main)
S.uiRefs.main = main

local tb = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, main)
corner(tb, 10)
mk("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = T.panel, BorderSizePixel = 0 }, tb)
mk("Frame", { Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 12, 0.5, -8), BackgroundColor3 = T.accent, BorderSizePixel = 0 }, tb)
mk("TextLabel", { Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 22, 0, 0), BackgroundTransparency = 1, Text = "Auto Block v4.3", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left }, tb)

local killBtn = mk("TextButton", { Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -56, 0, 7), BackgroundColor3 = T.off, Text = "K", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text, BorderSizePixel = 0, AutoButtonColor = false }, tb)
corner(killBtn, 4); killBtn.MouseButton1Click:Connect(killSwitch)

local closeBtn = mk("TextButton", { Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -30, 0, 7), BackgroundColor3 = T.off, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text, BorderSizePixel = 0, AutoButtonColor = false }, tb)
corner(closeBtn, 4); closeBtn.MouseButton1Click:Connect(killSwitch)

-- Smooth drag
local dragToggle, dragStart, startPos
tb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local statsFrame = mk("Frame", {
    Size = UDim2.new(1, -16, 0, 48), Position = UDim2.new(0, 8, 0, 40),
    BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, main)
corner(statsFrame, 6); stroke(statsFrame)
S.statsLabel = mk("TextLabel", {
    Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1, Text = "Waiting...",
    Font = Enum.Font.Code, TextSize = 10, TextColor3 = T.subtext,
    TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
}, statsFrame)

local list = mk("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -184), Position = UDim2.new(0, 8, 0, 96),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local function addToggle(label, key, callback)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.panel, BorderSizePixel = 0,
    }, list)
    corner(row, 6); stroke(row)
    mk("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, Text = label,
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local pill = mk("TextButton", {
        Size = UDim2.new(0, 42, 0, 18), Position = UDim2.new(1, -50, 0.5, -9),
        BackgroundColor3 = Config[key] and T.on or T.off,
        Text = Config[key] and "ON" or "OFF",
        Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = T.text,
        BorderSizePixel = 0, AutoButtonColor = false,
    }, row)
    corner(pill, 9)
    pill.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        pill.BackgroundColor3 = Config[key] and T.on or T.off
        pill.Text = Config[key] and "ON" or "OFF"
        if callback then callback(Config[key]) end
    end)
end

local function addSlider(label, key, min, max)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0,
    }, list)
    corner(row, 6); stroke(row)

    local initVal = key == "PredictAhead" and (Config[key] * 1000) or Config[key]
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 10, 0, 4),
        BackgroundTransparency = 1,
        Text = label .. ": " .. tostring(math.floor(initVal)),
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.subtext,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local trackFrame = mk("Frame", {
        Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = T.border, BorderSizePixel = 0,
    }, row)
    corner(trackFrame, 2)

    local fill = mk("Frame", {
        Size = UDim2.new((initVal-min)/(max-min), 0, 1, 0),
        BackgroundColor3 = T.accent, BorderSizePixel = 0,
    }, trackFrame)
    corner(fill, 2)

    S.sliderRefs[key] = { lbl = lbl, fill = fill, min = min, max = max }

    local dragSlide = false
    local function update(input)
        local rel = math.clamp((input.Position.X - trackFrame.AbsolutePosition.X) / trackFrame.AbsoluteSize.X, 0, 1)
        local val = math.clamp(math.floor(min + rel * (max - min) + 0.5), min, max)
        if key == "PredictAhead" then
            Config[key] = val / 1000
        else
            Config[key] = val
        end
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. ": " .. tostring(val)
    end

    trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragSlide = true; update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragSlide and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragSlide = false
        end
    end)
end

addToggle("Auto Block",         "AutoBlock")
addToggle("Auto Punch",         "AutoPunch")
addToggle("Predictive Block",   "PredictiveBlock")
addToggle("Angular Prediction", "AngularPrediction")
addToggle("Adaptive Range",     "AdaptiveRange")
addToggle("Killer ESP",         "KillerESP",   refreshESP)
addToggle("Survivor ESP",       "SurvivorESP", refreshESP)
addToggle("Range Visualizer",   "Visualizer")
addToggle("Stats Overlay",      "StatsOverlay")
addToggle("Debug Mode",         "Debug")

addSlider("Range",              "Range",        5, 25)
addSlider("Predict Ahead (ms)", "PredictAhead", 50, 300)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ============================================================
-- INIT
-- ============================================================
refreshMyChar()
refreshButtonCache()
pcall(refreshESP)
print("[AB v4.3] loaded — RightShift toggles UI | K = kill switch | Strict cone: 65°")"
