--[[
    Forsaken+ Auto Block + Auto Punch — Rayfield (Whitelist Edition)
    ============================================================
    Only blocks attacks whose animation name matches the whitelist.
    Behead, and other unblockables are NOT in the list → won't trigger.
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris            = game:GetService("Debris")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- ============================================================
-- LOAD RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Forsaken+ Auto Block",
    LoadingTitle = "Forsaken+",
    LoadingSubtitle = "Whitelist AB",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ForsakenPlus",
        FileName = "ABConfig",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ============================================================
-- REFERENCES
-- ============================================================
local function getMainUI() return PG:FindFirstChild("MainUI") end
local function getAbilityContainer()
    local m = getMainUI()
    return m and m:FindFirstChild("AbilityContainer")
end

local function getRemote()
    local ok, remote = pcall(function()
        return ReplicatedStorage.Modules.Network:FindFirstChildOfClass("RemoteEvent")
    end)
    return ok and remote or nil
end

local function getKillersFolder()
    local pf = workspace:FindFirstChild("Players")
    return pf and pf:FindFirstChild("Killers")
end

local function getSurvivorsFolder()
    local pf = workspace:FindFirstChild("Players")
    return pf and pf:FindFirstChild("Survivors")
end

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
-- ⭐ BLOCKABLE ATTACK WHITELIST ⭐
-- ============================================================
-- Only these animation names will trigger a block.
-- Behead, Gashing Wounds, and other unblockables are NOT here.
-- Add/remove names based on what you want to block.
local BlockableAttacks = {
    ["slash"]        = true,
    ["enragedslash"] = true,
    ["stab"]         = true,
    ["attack"]       = true,
    ["punch"]        = true,
    ["swing"]        = true,
    ["golemslash"]   = true,
    -- ["behead"]    = true,  -- intentionally excluded
    -- ["gash"]      = true,  -- intentionally excluded
}

-- ============================================================
-- CONFIG
-- ============================================================
local CustomHitboxes = {
    ["golemslash"] = {
        Size   = Vector3.new(6, 2, 7),
        Offset = CFrame.new(0, 0, -5.5),
    },
}

local DefaultSize    = Vector3.new(5, 5, 6)
local DefaultOffset  = CFrame.new(0, 0, -3)
local SizeMultiplier = 2.2
local CheckLoops     = 12
local CheckDelay     = 0.02
local HitboxLifetime = 0.4

-- ============================================================
-- STATE
-- ============================================================
local AutoBlockEnabled = false
local AutoPunchEnabled = false
local ShowHitboxes     = false
local watched          = {}
local hasFiresignal    = type(firesignal) == "function"
local debugPrint       = false

-- ============================================================
-- FIRING
-- ============================================================
local function fireBlock()
    local cont = getAbilityContainer()
    local btn = cont and cont:FindFirstChild("Block")
    if hasFiresignal and btn then
        local ok = pcall(function() firesignal(btn.MouseButton1Click) end)
        if ok then return end
    end
    local Remote = getRemote()
    if Remote then
        pcall(function() Remote:FireServer("UseActorAbility", {"Block"}) end)
    end
end

local function firePunch()
    local cont = getAbilityContainer()
    local btn = cont and cont:FindFirstChild("Punch")
    if hasFiresignal and btn then
        local ok = pcall(function() firesignal(btn.MouseButton1Click) end)
        if ok then return end
    end
    local Remote = getRemote()
    if Remote then
        pcall(function() Remote:FireServer("UseActorAbility", {"Punch"}) end)
    end
end

-- ============================================================
-- HITBOX OVERLAP
-- ============================================================
local function checkOverlap(part, targetHitbox)
    local params = OverlapParams.new()
    params.MaxParts = 1
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { targetHitbox }
    local hits = workspace:GetPartsInPart(part, params)
    return #hits > 0
end

-- ============================================================
-- ⭐ GET ANIMATION NAME ⭐
-- ============================================================
-- Returns a lowercase name like "slash" / "stab" / "punch"
-- Tries Animation.Name first, then falls back to the ID.
local function getAnimationName(Track)
    if not Track or not Track.Animation then return nil end

    -- Method 1: Roblox Animation.Name (most reliable)
    local animName = Track.Animation.Name
    if animName and animName ~= "" then
        return string.lower(animName)
    end

    -- Method 2: Fallback — try to match ID against a name map
    -- (Only works if the game has a GetAnimationType equivalent;
    --  if you have that function, replace this block with a call to it.)
    local id = tostring(Track.Animation.AnimationId):match("%d+")
    if id and debugPrint then
        print("[AB] Unknown animation ID:", id)
    end

    return nil
end

-- ============================================================
-- HANDLE KILLER
-- ============================================================
local function handleKiller(Killer)
    if not Killer:IsA("Model") then return end
    if watched[Killer] then return end
    watched[Killer] = true

    local Humanoid = Killer:FindFirstChildOfClass("Humanoid") or Killer:WaitForChild("Humanoid", 5)
    local QueryHitbox = Killer:FindFirstChild("QueryHitbox") or Killer:WaitForChild("QueryHitbox", 5)
    if not Humanoid or not QueryHitbox then return end

    local KillerAnimator = Humanoid:FindFirstChildOfClass("Animator")
    if not KillerAnimator then return end

    KillerAnimator.AnimationPlayed:Connect(function(Track)
        if not AutoBlockEnabled then return end
        if not Players:GetPlayerFromCharacter(Killer) then return end

        -- ⭐ WHITELIST CHECK — only block known blockable attacks
        local animName = getAnimationName(Track)
        if not animName then return end
        if not BlockableAttacks[animName] then
            if debugPrint then
                print("[AB] Skipped (not in whitelist):", animName)
            end
            return
        end

        if debugPrint then
            print("[AB] Whitelisted attack detected:", animName)
        end

        local MyChar = getLocalChar()
        if not MyChar then return end
        local MyQueryHitbox = MyChar:FindFirstChild("QueryHitbox")
        if not MyQueryHitbox then return end

        local survivors = getSurvivorsFolder()
        if survivors and MyChar.Parent ~= survivors then return end

        -- Choose hitbox config
        local Custom = CustomHitboxes[animName] or CustomHitboxes[string.lower(Killer.Name)]
        local Size   = (Custom and Custom.Size or DefaultSize) * SizeMultiplier
        local Offset = Custom and Custom.Offset or DefaultOffset

        for i = 1, CheckLoops do
            if not AutoBlockEnabled then break end
            if not MyChar.Parent then break end
            if not QueryHitbox.Parent then break end

            local Part = Instance.new("Part")
            Part.Name         = "KillerDetectHitbox"
            Part.Size         = Size
            Part.CFrame       = QueryHitbox.CFrame * Offset
            Part.CanCollide   = false
            Part.Anchored     = true
            Part.CastShadow   = false
            Part.Material     = Enum.Material.ForceField
            Part.Color        = Color3.new(0, 0, 0)
            Part.Transparency = ShowHitboxes and 0.5 or 1
            Part.Parent       = workspace
            Debris:AddItem(Part, HitboxLifetime)

            if checkOverlap(Part, MyQueryHitbox) then
                fireBlock()
                break
            end

            task.wait(CheckDelay)
        end
    end)
end

-- ============================================================
-- SETUP KILLER WATCHERS
-- ============================================================
local function setupKillers()
    local KF = getKillersFolder()
    if not KF then return end
    for _, k in ipairs(KF:GetChildren()) do
        handleKiller(k)
    end
    KF.ChildAdded:Connect(handleKiller)
end

-- ============================================================
-- AUTO PUNCH
-- ============================================================
local function setupAutoPunch()
    local MyChar = getLocalChar()
    local MyHum = getLocalHum()
    if not MyChar or not MyHum then return end

    MyChar:GetAttributeChangedSignal("TimesHit"):Connect(function()
        if not AutoPunchEnabled then return end

        local SpeedMults = MyChar:FindFirstChild("SpeedMultipliers")
        if not SpeedMults or not SpeedMults:FindFirstChild("GuestBlocking") then return end

        local Overheal = MyHum:GetAttribute("Overheal")
        if not Overheal or Overheal < 10 then return end

        local KF = getKillersFolder()
        local MyRoot = getLocalRoot()
        if not KF or not MyRoot then return end

        local closest, closestDist = nil, 55
        for _, v in ipairs(KF:GetChildren()) do
            if Players:GetPlayerFromCharacter(v) then
                local vr = v:FindFirstChild("HumanoidRootPart")
                if vr then
                    local d = (vr.Position - MyRoot.Position).Magnitude
                    if d < closestDist then closest, closestDist = v, d end
                end
            end
        end
        if not closest then return end

        task.wait(0.08)
        MyChar:SetAttribute("DisableShiftLockMovement", true)
        firePunch()

        local conn
        local lastVel
        conn = RunService.RenderStepped:Connect(function()
            local MyRootNow = getLocalRoot()
            local KR = closest and closest:FindFirstChild("HumanoidRootPart")
            if not MyRootNow or not KR then return end
            local target = Vector3.new(KR.Position.X, MyRootNow.Position.Y, KR.Position.Z)
            local cf = CFrame.new(MyRootNow.Position, target)
            MyChar:SetPrimaryPartCFrame(cf)
            if not lastVel then
                MyRootNow.Velocity = cf.LookVector * 32
                lastVel = MyRootNow.Velocity
            else
                lastVel = MyRootNow.Velocity:Lerp(lastVel, 0.8)
                MyRootNow.Velocity = lastVel
            end
        end)

        local FOVMults = MyChar:FindFirstChild("FOVMultipliers")
        repeat
            task.wait(0.1)
        until (FOVMults and FOVMults:FindFirstChild("HitRegistered"))
            or not (SpeedMults:FindFirstChild("PunchAbility"))

        if conn then conn:Disconnect() end
        task.wait(0.2)
        MyChar:SetAttribute("DisableShiftLockMovement", false)
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    setupAutoPunch()
end)

-- ============================================================
-- UI
-- ============================================================
local MainTab     = Window:CreateTab("Main", 4483362458)
local WhitelistTab = Window:CreateTab("Whitelist", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

MainTab:CreateSection("Auto Block")

MainTab:CreateToggle({
    Name = "Auto Block",
    CurrentValue = false,
    Flag = "AutoBlock",
    Callback = function(v) AutoBlockEnabled = v end,
})

MainTab:CreateToggle({
    Name = "Auto Punch",
    CurrentValue = false,
    Flag = "AutoPunch",
    Callback = function(v) AutoPunchEnabled = v end,
})

MainTab:CreateSection("Debug")

MainTab:CreateToggle({
    Name = "Show Hitboxes",
    CurrentValue = false,
    Flag = "ShowHitboxes",
    Callback = function(v) ShowHitboxes = v end,
})

MainTab:CreateToggle({
    Name = "Print Detected Attacks",
    CurrentValue = false,
    Flag = "DebugPrint",
    Callback = function(v) debugPrint = v end,
})

-- ============================================================
-- WHITELIST TAB (toggle per attack name)
-- ============================================================
WhitelistTab:CreateSection("Blockable Attacks")
WhitelistTab:CreateParagraph({
    Title = "Only checked attacks fire a block",
    Content = "Uncheck Behead, Gash, or anything unblockable to prevent wasted blocks.",
})

local allAttacks = {
    "slash", "enragedslash", "stab", "attack",
    "punch", "swing", "golemslash", "behead", "gash",
}

for _, name in ipairs(allAttacks) do
    WhitelistTab:CreateToggle({
        Name = name,
        CurrentValue = BlockableAttacks[name] == true,
        Flag = "WL_" .. name,
        Callback = function(v)
            BlockableAttacks[name] = v and true or nil
        end,
    })
end

-- ============================================================
-- SETTINGS TAB
-- ============================================================
SettingsTab:CreateSection("Info")
SettingsTab:CreateButton({
    Name = "Refresh Killer Watchers",
    Callback = function()
        watched = {}
        setupKillers()
    end,
})

-- ============================================================
-- INIT
-- ============================================================
setupKillers()
setupAutoPunch()

Rayfield:LoadConfiguration()

print("[Forsaken Auto Block Script Loaded]")
