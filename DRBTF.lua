--[[
    ForsakenPlus — Rayfield Edition (v1.8 port)
    ============================================================
    Rebuilt from naikoexploit.vercel.app/ForsakenPlus
    All features from the original FeatureLoadout table.
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ============================================================
-- FOLDER REFERENCES (from source)
-- ============================================================
local PlayersFolder    = workspace:FindFirstChild("Players")
local KillersFolder    = PlayersFolder and PlayersFolder:FindFirstChild("Killers")
local SurvivorsFolder  = PlayersFolder and PlayersFolder:FindFirstChild("Survivors")
local Hitboxes         = workspace:FindFirstChild("Hitboxes")
local InGame           = workspace:FindFirstChild("Map") and workspace:FindFirstChild("Map"):FindFirstChild("Ingame")
local GameMap          = InGame and InGame:FindFirstChild("Map") or nil
local MainUI           = PG:FindFirstChild("MainUI") or PG:WaitForChild("MainUI", 80)
local TempUI           = PG:FindFirstChild("TemporaryUI") or PG:WaitForChild("TemporaryUI", 5)

local AssetsFolder     = ReplicatedStorage:FindFirstChild("Assets")
local KillerAssets     = AssetsFolder and AssetsFolder:FindFirstChild("Killers")

local Network = ReplicatedStorage:FindFirstChild("Modules") and 
    ReplicatedStorage.Modules:FindFirstChild("Network", true) and
    ReplicatedStorage.Modules.Network:FindFirstChild("Network") or nil

local function getLocalChar() return LP.Character end
local function getLocalRoot()
    local c = getLocalChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getLocalHum()
    local c = getLocalChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============================================================
-- LOAD RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "ForsakenPlus",
    LoadingTitle = "ForsakenPlus v1.8",
    LoadingSubtitle = "by Naiko (Rayfield port)",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ForsakenPlus",
        FileName = "Config",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ============================================================
-- STATE
-- ============================================================
local State = {
    AutoBlock = false,
    AutoPunch = false,
    AutoGenerator = false,
    AutoPickup = false,
    AutoEscape = false,
    AutoDisarm = false,
    Invincible = false,
    SpeedUpNobodysNear = false,
    GeneratorCooldown = 1.5,
    EscapeCooldown = 0.5,
    ShowHitboxes = false,
    IsFixingGenerator = false,
    IsUnderground = false,
    watchedKillers = {},
}

-- ============================================================
-- ⭐ AUTO BLOCK (whitelist-based, from the module)
-- ============================================================
local BlockableAttacks = {
    ["slash"]=true, ["enragedslash"]=true, ["stab"]=true,
    ["attack"]=true, ["punch"]=true, ["swing"]=true, ["golemslash"]=true,
}

local CustomHitboxes = {
    ["golemslash"] = { Size = Vector3.new(6,2,7), Offset = CFrame.new(0,0,-5.5) },
}

local DefaultSize = Vector3.new(5,5,6)
local DefaultOffset = CFrame.new(0,0,-3)
local SizeMultiplier = 2.2

local function fireBlock()
    local main = PG:FindFirstChild("MainUI")
    local btn = main and main.AbilityContainer and main.AbilityContainer.Block
    if type(firesignal) == "function" and btn then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        return
    end
    if Network then
        pcall(function()
            local RE = Network:FindFirstChildOfClass("RemoteEvent")
            if RE then RE:FireServer("UseActorAbility", {"Block"}) end
        end)
    end
end

local function firePunch()
    local main = PG:FindFirstChild("MainUI")
    local btn = main and main.AbilityContainer and main.AbilityContainer.Punch
    if type(firesignal) == "function" and btn then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        return
    end
    if Network then
        pcall(function()
            local RE = Network:FindFirstChildOfClass("RemoteEvent")
            if RE then RE:FireServer("UseActorAbility", {"Punch"}) end
        end)
    end
end

local function checkOverlap(part, targetHitbox)
    local params = OverlapParams.new()
    params.MaxParts = 1
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { targetHitbox }
    return #workspace:GetPartsInPart(part, params) > 0
end

local function handleKiller(Killer)
    if not Killer:IsA("Model") then return end
    if State.watchedKillers[Killer] then return end
    State.watchedKillers[Killer] = true

    local Humanoid = Killer:FindFirstChildOfClass("Humanoid") or Killer:WaitForChild("Humanoid", 5)
    local QueryHitbox = Killer:FindFirstChild("QueryHitbox") or Killer:WaitForChild("QueryHitbox", 5)
    if not Humanoid or not QueryHitbox then return end

    local KillerAnimator = Humanoid:FindFirstChildOfClass("Animator")
    if not KillerAnimator then return end

    KillerAnimator.AnimationPlayed:Connect(function(Track)
        if not State.AutoBlock then return end
        if not Players:GetPlayerFromCharacter(Killer) then return end

        -- whitelist check
        local animName = Track.Animation and string.lower(Track.Animation.Name) or ""
        if not BlockableAttacks[animName] then return end

        local myChar = getLocalChar()
        if not myChar then return end
        local myQH = myChar:FindFirstChild("QueryHitbox")
        if not myQH then return end

        local Custom = CustomHitboxes[animName]
        local Size = (Custom and Custom.Size or DefaultSize) * SizeMultiplier
        local Offset = Custom and Custom.Offset or DefaultOffset

        for i = 1, 12 do
            if not State.AutoBlock then break end
            if not myChar.Parent then break end
            if not QueryHitbox.Parent then break end

            local Part = Instance.new("Part")
            Part.Name = "KillerDetectHitbox"
            Part.Size = Size
            Part.CFrame = QueryHitbox.CFrame * Offset
            Part.CanCollide = false
            Part.Anchored = true
            Part.CastShadow = false
            Part.Material = Enum.Material.ForceField
            Part.Color = Color3.new(0,0,0)
            Part.Transparency = State.ShowHitboxes and 0.5 or 1
            Part.Parent = Hitboxes or workspace
            Debris:AddItem(Part, 0.4)

            if checkOverlap(Part, myQH) then
                fireBlock()
                break
            end
            task.wait(0.02)
        end
    end)
end

if KillersFolder then
    for _, k in ipairs(KillersFolder:GetChildren()) do handleKiller(k) end
    KillersFolder.ChildAdded:Connect(handleKiller)
end

-- ============================================================
-- ⭐ AUTO PUNCH
-- ============================================================
local function setupAutoPunch()
    local myChar = getLocalChar()
    local myHum = getLocalHum()
    if not myChar or not myHum then return end

    myChar:GetAttributeChangedSignal("TimesHit"):Connect(function()
        if not State.AutoPunch then return end
        local SpeedMults = myChar:FindFirstChild("SpeedMultipliers")
        if not SpeedMults or not SpeedMults:FindFirstChild("GuestBlocking") then return end
        local Overheal = myHum:GetAttribute("Overheal")
        if not Overheal or Overheal < 10 then return end

        local KF = KillersFolder
        local myRoot = getLocalRoot()
        if not KF or not myRoot then return end

        local closest, closestDist = nil, 55
        for _, v in ipairs(KF:GetChildren()) do
            if Players:GetPlayerFromCharacter(v) then
                local vr = v:FindFirstChild("HumanoidRootPart")
                if vr then
                    local d = (vr.Position - myRoot.Position).Magnitude
                    if d < closestDist then closest, closestDist = v, d end
                end
            end
        end
        if not closest then return end

        task.wait(0.08)
        myChar:SetAttribute("DisableShiftLockMovement", true)
        firePunch()

        local conn
        local lastVel
        conn = RunService.RenderStepped:Connect(function()
            local mr = getLocalRoot()
            local KR = closest and closest:FindFirstChild("HumanoidRootPart")
            if not mr or not KR then return end
            local target = Vector3.new(KR.Position.X, mr.Position.Y, KR.Position.Z)
            local cf = CFrame.new(mr.Position, target)
            myChar:SetPrimaryPartCFrame(cf)
            if not lastVel then
                mr.Velocity = cf.LookVector * 32
                lastVel = mr.Velocity
            else
                lastVel = mr.Velocity:Lerp(lastVel, 0.8)
                mr.Velocity = lastVel
            end
        end)

        local FOVM = myChar:FindFirstChild("FOVMultipliers")
        repeat task.wait(0.1)
        until (FOVM and FOVM:FindFirstChild("HitRegistered"))
            or not (SpeedMults:FindFirstChild("PunchAbility"))

        if conn then conn:Disconnect() end
        task.wait(0.2)
        myChar:SetAttribute("DisableShiftLockMovement", false)
    end)
end
LP.CharacterAdded:Connect(function() task.wait(0.5); setupAutoPunch() end)
setupAutoPunch()

-- ============================================================
-- ⭐ AUTO GENERATOR (from source)
-- ============================================================
local function runAutoGenerator()
    task.spawn(function()
        while State.AutoGenerator do
            task.wait(0.1)
            local myRoot = getLocalRoot()
            if not myRoot or State.IsFixingGenerator or not GameMap then continue end

            for _, Object in ipairs(GameMap:QueryDescendants("Model#Generator:has(#Main)")) do
                local Main = Object:FindFirstChild("Main")
                if Main and (Main.Position - myRoot.Position).Magnitude < 6.7 then
                    State.IsFixingGenerator = true
                    task.spawn(function()
                        local RNG = Random.new()
                        local GenCD = State.GeneratorCooldown
                        if State.SpeedUpNobodysNear then
                            local near = false
                            for _, v in ipairs(Players:GetPlayers()) do
                                if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                    if (v.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude < 15 then
                                        near = true; break
                                    end
                                end
                            end
                            if not near then GenCD = math.max(0.1, GenCD * 0.4) end
                        end

                        repeat
                            task.wait(RNG:NextNumber(GenCD - 0.1 * GenCD, GenCD + 0.1 * GenCD))
                            if not State.AutoGenerator then break end
                            local puzzleUI = PG:FindFirstChild("PuzzleUI")
                            if not puzzleUI then break end
                        until false

                        State.IsFixingGenerator = false
                    end)
                    break
                end
            end
        end
    end)
end

-- ============================================================
-- ⭐ AUTO PICKUP (from source)
-- ============================================================
local function setupAutoPickup()
    if InGame then
        InGame.ChildAdded:Connect(function(Child)
            if Child:IsA("Tool") and State.AutoPickup then
                Child:SetAttribute("JustDropped", true)
                task.delay(1.5, function()
                    if Child then Child:SetAttribute("JustDropped", nil) end
                end)
            end
        end)
    end
end
setupAutoPickup()

-- ============================================================
-- ⭐ AUTO ESCAPE (Nosferatu hook, from source)
-- ============================================================
local function setupAutoEscape()
    if not TempUI then return end
    TempUI.ChildAdded:Connect(function(UIElement)
        if UIElement.Name:upper() == "QTE" and UIElement:FindFirstChildOfClass("UIAspectRatioConstraint") then
            task.spawn(function()
                while UIElement and UIElement.Visible do
                    local CD = State.EscapeCooldown
                    task.wait(Random.new():NextNumber(CD - 0.2 * CD, CD + 0.2 * CD))
                    if State.AutoEscape then
                        for _, v in ipairs(KillersFolder:GetChildren()) do
                            if v.Name:lower() == "nosferatu" then
                                -- Trigger escape via key input
                                pcall(function()
                                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end)
end
setupAutoEscape()

-- ============================================================
-- ⭐ AUTO DISARM (Azure QTE, from source)
-- ============================================================
local function setupAutoDisarm()
    local AzureQTE = KillerAssets and KillerAssets:FindFirstChild("Azure") and 
        KillerAssets.Azure:FindFirstChild("cl_ConstructQTE", true)
    if not AzureQTE or type(hookfunction) ~= "function" then return end

    local ok, RequiredModule = pcall(function() return require(AzureQTE) end)
    if not ok then return end

    task.delay(1, function()
        local origin
        origin = hookfunction(RequiredModule.new, function(...)
            local QTEAzure = origin(...)
            task.delay(0.05, function()
                if typeof(QTEAzure) == "table" and QTEAzure.AddProgress then
                    if State.AutoDisarm then
                        pcall(function() QTEAzure:AddProgress(100) end)
                    end
                end
            end)
            return QTEAzure
        end)
    end)
end
setupAutoDisarm()

-- ============================================================
-- ⭐ INVINCIBLE (GoUnder — from source, simplified)
-- ============================================================
local function runInvincible()
    if not State.Invincible then return end
    local myRoot = getLocalRoot()
    local myHead = getLocalChar() and getLocalChar():FindFirstChild("Head")
    local myHum = getLocalHum()
    if not myRoot or not myHead or not myHum then return end

    if workspace:GetAttribute("Invincible") == nil then
        workspace:SetAttribute("Invincible", true)
        local oldCFrame = myRoot.CFrame
        local underCFrame = oldCFrame * CFrame.new(0, -22, 0)
        myHum.CameraOffset = Vector3.new(0, 12e12, 0)
        task.wait(0.1)
        myRoot.CFrame = underCFrame
        myHead.Anchored = true
        State.IsUnderground = true

        task.spawn(function()
            while State.Invincible and State.IsUnderground do
                task.wait()
                local r = getLocalRoot()
                if not r then break end
                r.Velocity = Vector3.zero
                r.CFrame = underCFrame
            end
            -- Restore
            State.IsUnderground = false
            workspace:SetAttribute("Invincible", nil)
            local r = getLocalRoot()
            if r then r.CFrame = oldCFrame; r.Velocity = Vector3.zero end
            local h = getLocalChar() and getLocalChar():FindFirstChild("Head")
            if h then h.Anchored = false end
            local hum = getLocalHum()
            if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
        end)
    end
end

-- ============================================================
-- ⭐ UI — Rayfield
-- ============================================================
local MainTab        = Window:CreateTab("Main", 4483362458)
local AutomationTab  = Window:CreateTab("Automation", 4483362458)
local SettingsTab    = Window:CreateTab("Settings", 4483362458)

-- ===== MAIN TAB =====
MainTab:CreateSection("Auto Block")
MainTab:CreateToggle({
    Name = "Auto Block",
    CurrentValue = false,
    Flag = "AutoBlock",
    Callback = function(v) State.AutoBlock = v end,
})
MainTab:CreateToggle({
    Name = "Auto Punch",
    CurrentValue = false,
    Flag = "AutoPunch",
    Callback = function(v) State.AutoPunch = v end,
})
MainTab:CreateToggle({
    Name = "Show Hitboxes",
    CurrentValue = false,
    Flag = "ShowHitboxes",
    Callback = function(v) State.ShowHitboxes = v end,
})

MainTab:CreateSection("Blockable Attacks (Whitelist)")
MainTab:CreateParagraph({
    Title = "Only checked attacks fire a block",
    Content = "Uncheck any attack you don't want to block (like Behead).",
})

for _, name in ipairs({"slash","enragedslash","stab","attack","punch","swing","golemslash"}) do
    MainTab:CreateToggle({
        Name = name,
        CurrentValue = true,
        Flag = "WL_" .. name,
        Callback = function(v)
            BlockableAttacks[name] = v and true or nil
        end,
    })
end

MainTab:CreateSection("Character")

MainTab:CreateToggle({
    Name = "Invincible (God Mode)",
    CurrentValue = false,
    Flag = "Invincible",
    Callback = function(v)
        State.Invincible = v
        if v then runInvincible() end
    end,
})

-- ===== AUTOMATION TAB =====
AutomationTab:CreateSection("Generators")

AutomationTab:CreateToggle({
    Name = "Auto Generator",
    CurrentValue = false,
    Flag = "AutoGenerator",
    Callback = function(v)
        State.AutoGenerator = v
        if v then runAutoGenerator() end
    end,
})

AutomationTab:CreateSlider({
    Name = "Generator Cooldown",
    Range = {0.5, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1.5,
    Flag = "GenCooldown",
    Callback = function(v) State.GeneratorCooldown = v end,
})

AutomationTab:CreateToggle({
    Name = "Speed Up When Nobody's Near",
    CurrentValue = false,
    Flag = "SpeedUp",
    Callback = function(v) State.SpeedUpNobodysNear = v end,
})

AutomationTab:CreateSection("Items")

AutomationTab:CreateToggle({
    Name = "Auto Pickup",
    CurrentValue = false,
    Flag = "AutoPickup",
    Callback = function(v) State.AutoPickup = v end,
})

AutomationTab:CreateSection("QTE")

AutomationTab:CreateToggle({
    Name = "Auto Escape (Nosferatu Hook)",
    CurrentValue = false,
    Flag = "AutoEscape",
    Callback = function(v) State.AutoEscape = v end,
})

AutomationTab:CreateSlider({
    Name = "Escape Cooldown",
    Range = {0.2, 1.2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.5,
    Flag = "EscapeCooldown",
    Callback = function(v) State.EscapeCooldown = v end,
})

AutomationTab:CreateToggle({
    Name = "Auto Disarm (Azure QTE)",
    CurrentValue = false,
    Flag = "AutoDisarm",
    Callback = function(v) State.AutoDisarm = v end,
})

-- ===== SETTINGS TAB =====
SettingsTab:CreateSection("Info")
SettingsTab:CreateParagraph({
    Title = "DRBTF HUB v1",
    Content = "I make it by my self",
})

SettingsTab:CreateButton({
    Name = "Refresh Killer Watchers",
    Callback = function()
        State.watchedKillers = {}
        if KillersFolder then
            for _, k in ipairs(KillersFolder:GetChildren()) do handleKiller(k) end
        end
    end,
})

-- ============================================================
-- INIT
-- ============================================================
Rayfield:LoadConfiguration()
print("[ForsakenPlus Rayfield] Loaded v1.8 port")
