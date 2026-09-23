--[[
    Forsaken Hitbox Expander
    ============================================================
    Extends YOUR hitbox forward so punches register from further away
    - Toggle ON/OFF
    - Adjustable power (1x - 15x)
    - Velocity-compensated (matches Forsaken's actual hitbox behavior)
    - Custom GUI (no library)
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local safeUIParent = (type(gethui) == "function" and gethui()) or PG

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled      = false,
    Power        = 5,     -- how far forward (studs)
    Width        = 4,     -- hitbox width
    Height       = 5,     -- hitbox height
    ShowVisual   = false, -- render the extended hitbox
}

-- ============================================================
-- STATE
-- ============================================================
local S = {
    myChar     = nil,
    extendPart = nil,
    weld       = nil,
    connection = nil,
    uiRefs     = {},
}

-- ============================================================
-- CORE: FORSAKEN-STYLE HITBOX DRAG
-- ============================================================
-- Creates an invisible part welded to HRP, positioned forward.
-- Uses AssemblyLinearVelocity to compensate for movement lag
-- (same technique Forsaken uses for its hitbox system).

local function cleanupExtend()
    if S.extendPart and S.extendPart.Parent then S.extendPart:Destroy() end
    if S.weld and S.weld.Parent then S.weld:Destroy() end
    S.extendPart = nil
    S.weld = nil
end

local function buildExtendPart(hrp)
    cleanupExtend()

    local part = Instance.new("Part")
    part.Name = "HitboxExtend"
    part.Size = Vector3.new(Config.Width, Config.Height, Config.Width)
    part.Transparency = Config.ShowVisual and 0.5 or 1
    part.Color = Color3.fromRGB(255, 100, 100)
    part.Material = Enum.Material.Neon
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.Anchored = false
    part.CFrame = hrp.CFrame * CFrame.new(0, 0, -Config.Power)
    part.Parent = S.myChar

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp
    weld.Part1 = part
    weld.Parent = part

    S.extendPart = part
    S.weld = weld
end

local function refreshMyChar()
    local c = LP.Character
    if c ~= S.myChar then
        cleanupExtend()
        S.myChar = c
    end
end

local function startLoop()
    if S.connection then S.connection:Disconnect() end

    S.connection = RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        refreshMyChar()

        local char = S.myChar
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Build part if missing
        if not S.extendPart or not S.extendPart.Parent then
            buildExtendPart(hrp)
        end

        -- Update position with velocity compensation
        if S.extendPart then
            S.extendPart.Size = Vector3.new(Config.Width, Config.Height, Config.Width)
            S.extendPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -Config.Power)
            S.extendPart.Transparency = Config.ShowVisual and 0.5 or 1

            -- Velocity compensation: push hitbox ahead based on movement
            -- This is the same technique used in Forsaken's real hitbox system
            local velocity = hrp.AssemblyLinearVelocity
            if velocity.Magnitude > 1 then
                local pingOffset = 6.5 - 10 * math.clamp(LP:GetNetworkPing(), 0, 0.3)
                local velocityOffset = S.extendPart.CFrame:VectorToObjectSpace(velocity)
                S.extendPart.CFrame *= CFrame.new(velocityOffset / pingOffset)
            end
        end
    end)
end

local function stopLoop()
    if S.connection then
        S.connection:Disconnect()
        S.connection = nil
    end
    cleanupExtend()
end

-- ============================================================
-- UI
-- ============================================================
local T = {
    bg      = Color3.fromRGB(18, 18, 22),
    panel   = Color3.fromRGB(28, 28, 34),
    accent  = Color3.fromRGB(255, 80, 80),
    text    = Color3.fromRGB(240, 240, 248),
    subtext = Color3.fromRGB(150, 150, 168),
    border  = Color3.fromRGB(48, 48, 58),
    on      = Color3.fromRGB(65, 185, 100),
    off     = Color3.fromRGB(190, 60, 60),
}

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function stroke(p)
    local s = Instance.new("UIStroke")
    s.Color = T.border
    s.Thickness = 1
    s.Parent = p
end

local screen = mk("ScreenGui", {
    Name = "HitboxExpanderUI", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, safeUIParent)
S.uiRefs.screen = screen

local main = mk("Frame", {
    Size = UDim2.new(0, 280, 0, 240),
    Position = UDim2.new(0, 20, 0.5, -120),
    BackgroundColor3 = T.bg, BorderSizePixel = 0, Active = true,
}, screen)
corner(main, 10); stroke(main)
S.uiRefs.main = main

-- Title
local tb = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, main)
corner(tb, 10)
mk("Frame", {
    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, tb)
mk("Frame", {
    Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 12, 0.5, -8),
    BackgroundColor3 = T.accent, BorderSizePixel = 0,
}, tb)
mk("TextLabel", {
    Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1, Text = "Hitbox Expander",
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tb)

local closeBtn = mk("TextButton", {
    Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -28, 0, 7),
    BackgroundColor3 = T.off, Text = "✕",
    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = T.text,
    BorderSizePixel = 0, AutoButtonColor = false,
}, tb)
corner(closeBtn, 4)
closeBtn.MouseButton1Click:Connect(function() stopLoop(); screen:Destroy() end)

-- Drag
local dragging, dragStart, startPos
tb.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Content
local content = mk("Frame", {
    Size = UDim2.new(1, -16, 1, -46), Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
}, main)
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, content)

-- Toggle
local toggleRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, content)
corner(toggleRow, 6); stroke(toggleRow)
mk("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Enable Hitbox Expander",
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, toggleRow)
local togglePill = mk("TextButton", {
    Size = UDim2.new(0, 46, 0, 20), Position = UDim2.new(1, -56, 0.5, -10),
    BackgroundColor3 = Config.Enabled and T.on or T.off,
    Text = Config.Enabled and "ON" or "OFF",
    Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = T.text,
    BorderSizePixel = 0, AutoButtonColor = false,
}, toggleRow)
corner(togglePill, 10)
togglePill.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    togglePill.BackgroundColor3 = Config.Enabled and T.on or T.off
    togglePill.Text = Config.Enabled and "ON" or "OFF"
    if Config.Enabled then startLoop() else stopLoop() end
end)

-- Power slider
local powerRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, content)
corner(powerRow, 6); stroke(powerRow)
local powerLabel = mk("TextLabel", {
    Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 10, 0, 4),
    BackgroundTransparency = 1, Text = "Power: " .. Config.Power .. " studs",
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = T.subtext,
    TextXAlignment = Enum.TextXAlignment.Left,
}, powerRow)
local track = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 5), Position = UDim2.new(0, 10, 0, 28),
    BackgroundColor3 = T.border, BorderSizePixel = 0,
}, powerRow)
corner(track, 3)
local fill = mk("Frame", {
    Size = UDim2.new((Config.Power - 1) / 14, 0, 1, 0),
    BackgroundColor3 = T.accent, BorderSizePixel = 0,
}, track)
corner(fill, 3)

local draggingSlider = false
local function updateSlider(input)
    local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
    local val = math.floor(1 + rel * 14 + 0.5)
    val = math.clamp(val, 1, 15)
    Config.Power = val
    fill.Size = UDim2.new(rel, 0, 1, 0)
    powerLabel.Text = "Power: " .. val .. " studs"
end
track.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true; updateSlider(input)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
end)

-- Visual toggle
local visualRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, content)
corner(visualRow, 6); stroke(visualRow)
mk("TextLabel", {
    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Show Extended Hitbox",
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, visualRow)
local visualPill = mk("TextButton", {
    Size = UDim2.new(0, 46, 0, 20), Position = UDim2.new(1, -56, 0.5, -10),
    BackgroundColor3 = Config.ShowVisual and T.on or T.off,
    Text = Config.ShowVisual and "ON" or "OFF",
    Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = T.text,
    BorderSizePixel = 0, AutoButtonColor = false,
}, visualRow)
corner(visualPill, 10)
visualPill.MouseButton1Click:Connect(function()
    Config.ShowVisual = not Config.ShowVisual
    visualPill.BackgroundColor3 = Config.ShowVisual and T.on or T.off
    visualPill.Text = Config.ShowVisual and "ON" or "OFF"
end)

-- Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ============================================================
-- INIT
-- ============================================================
print("[Hitbox Expander] Loaded — RightShift toggles UI")
