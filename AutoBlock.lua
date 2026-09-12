-- ============================================================
-- Forsaken Auto Block — Custom UI v2
-- Features: animations, dropdown popups, sliders, save/load,
-- keybind, notifications, search, watermark, full AntiFlick
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local lp                = Players.LocalPlayer
local PlayerGui         = lp:WaitForChild("PlayerGui")
local KF                = workspace:WaitForChild("Players"):WaitForChild("Killers")
local RE                = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("RemoteEvent")

-- ============================================================
-- THEME + TWEENS
-- ============================================================
local Theme = {
    bg       = Color3.fromRGB(18, 18, 22),
    panel    = Color3.fromRGB(28, 28, 34),
    panel2   = Color3.fromRGB(38, 38, 46),
    accent   = Color3.fromRGB(130, 95, 255),
    accent2  = Color3.fromRGB(175, 145, 255),
    text     = Color3.fromRGB(240, 240, 248),
    subtext  = Color3.fromRGB(150, 150, 168),
    border   = Color3.fromRGB(48, 48, 58),
    on       = Color3.fromRGB(65, 185, 100),
    off      = Color3.fromRGB(190, 60, 60),
    btn      = Color3.fromRGB(44, 44, 52),
    btnHover = Color3.fromRGB(60, 60, 72),
    shadow   = Color3.fromRGB(8, 8, 12),
}

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = p; return c end
local function stroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or Theme.border; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local notifHolder
local function getNotifHolder()
    if notifHolder and notifHolder.Parent then return notifHolder end
    notifHolder = mk("Frame", {
        Name = "NotifHolder",
        Size = UDim2.new(0, 300, 1, -40),
        Position = UDim2.new(1, -320, 0, 20),
        BackgroundTransparency = 1,
        Parent = PlayerGui:FindFirstChild("CustomAutoBlockUI") or PlayerGui,
    }, PlayerGui)
    mk("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Top }, notifHolder)
    return notifHolder
end

local function notify(title, text, dur)
    dur = dur or 3
    local holder = getNotifHolder()
    local card = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    }, holder)
    corner(card, 8); stroke(card, Theme.accent, 1)

    local bar = mk("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
    }, card)
    corner(bar, 3)

    local tl = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    local txt = mk("TextLabel", {
        Size = UDim2.new(1, -20, 0, 26),
        Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.subtext,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, card)

    card.Position = UDim2.new(0, 320, 0, 0)
    tween(card, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
    task.delay(dur, function()
        local out = tween(card, 0.25, { Position = UDim2.new(0, 320, 0, 0), BackgroundTransparency = 1 })
        out.Completed:Connect(function() card:Destroy() end)
    end)
end

-- ============================================================
-- UI LIBRARY
-- ============================================================
local UILib = {}

function UILib:CreateWindow(opts)
    local screen = mk("ScreenGui", {
        Name = "CustomAutoBlockUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    }, PlayerGui)

    -- ===== SHADOW =====
    local shadow = mk("Frame", {
        Size = UDim2.new(0, 620, 0, 420),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Theme.shadow,
        BorderSizePixel = 0,
        ZIndex = 0,
    }, screen)
    corner(shadow, 12)
    mk("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.4)
        })
    }, shadow)

    -- ===== MAIN =====
    local main = mk("Frame", {
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -310, 0.5, -210),
        BackgroundColor3 = Theme.bg,
        BorderSizePixel = 0,
        Active = true,
        ClipsDescendants = true,
        ZIndex = 1,
    }, screen)
    corner(main, 12); stroke(main, Theme.border)

    -- Animate in
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    tween(main, 0.35, {
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -310, 0.5, -210),
    }, Enum.EasingStyle.Back)

    -- ===== TITLE BAR =====
    local tb = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, main)
    corner(tb, 12)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 1, -15), BackgroundColor3 = Theme.panel, BorderSizePixel = 0, ZIndex = 2 }, tb)

    -- Accent strip
    mk("Frame", {
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, tb)

    local titleLbl = mk("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.Title or "Forsaken",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, tb)

    local subLbl = mk("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text = "  ·  " .. (opts.Subtitle or ""),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.accent2,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, tb)

    -- Close
    local closeBtn = mk("TextButton", {
        Size = UDim2.new(0, 28, 0, 24),
        Position = UDim2.new(1, -36, 0, 8),
        BackgroundColor3 = Theme.off,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.text,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
    }, tb)
    corner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(220, 75, 75) }) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.15, { BackgroundColor3 = Theme.off }) end)
    closeBtn.MouseButton1Click:Connect(function()
        local t = tween(main, 0.2, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) })
        t.Completed:Connect(function() screen:Destroy() end)
    end)

    -- Minimize
    local minBtn = mk("TextButton", {
        Size = UDim2.new(0, 28, 0, 24),
        Position = UDim2.new(1, -70, 0, 8),
        BackgroundColor3 = Theme.btn,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.text,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
    }, tb)
    corner(minBtn, 6)
    minBtn.MouseEnter:Connect(function() tween(minBtn, 0.15, { BackgroundColor3 = Theme.btnHover }) end)
    minBtn.MouseLeave:Connect(function() tween(minBtn, 0.15, { BackgroundColor3 = Theme.btn }) end)

    -- ===== SIDEBAR =====
    local side = mk("Frame", {
        Size = UDim2.new(0, 150, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, main)

    local searchBox = mk("TextBox", {
        Size = UDim2.new(1, -16, 0, 26),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Theme.bg,
        Text = "",
        PlaceholderText = "🔍  Search...",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.text,
        PlaceholderColor3 = Theme.subtext,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, side)
    corner(searchBox, 6); stroke(searchBox, Theme.border)
    mk("UIPadding", { PaddingLeft = UDim.new(0, 8) }, searchBox)

    local sideScroll = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -48),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 2,
    }, side)
    mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)
    mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sideScroll)

    -- ===== CONTENT AREA =====
    local content = mk("Frame", {
        Size = UDim2.new(1, -154, 1, -48),
        Position = UDim2.new(0, 152, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 2,
    }, main)

    local win = { screen = screen, main = main, tabs = {}, active = nil }

    function win:AddTab(name)
        local btn = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.bg,
            Text = "   " .. name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = Theme.subtext,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 3,
        }, sideScroll)
        corner(btn, 6)

        local indicator = mk("Frame", {
            Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = Theme.accent,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 4,
        }, btn)
        corner(indicator, 2)

        local page = mk("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 3,
        }, content)
        mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, page)

        local tab = { name = name, button = btn, page = page, indicator = indicator, boxes = {} }

        btn.MouseEnter:Connect(function()
            if self.active ~= tab then tween(btn, 0.15, { BackgroundColor3 = Theme.panel2 }) end
        end)
        btn.MouseLeave:Connect(function()
            if self.active ~= tab then tween(btn, 0.15, { BackgroundColor3 = Theme.bg }) end
        end)

        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.tabs) do
                t.page.Visible = (t == tab)
                tween(t.button, 0.15, { BackgroundColor3 = (t == tab) and Theme.accent or Theme.bg })
                tween(t.button, 0.15, { TextColor3 = (t == tab) and Theme.text or Theme.subtext })
                t.indicator.Visible = (t == tab)
            end
            self.active = tab
        end)

        function tab:AddGroupbox(title)
            local gb = mk("Frame", {
                Size = UDim2.new(1, -8, 0, 0),
                BackgroundColor3 = Theme.panel,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 3,
            }, page)
            corner(gb, 10); stroke(gb, Theme.border)
            mk("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }, gb)

            local titleRow = mk("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                ZIndex = 3,
            }, gb)
            mk("Frame", {
                Size = UDim2.new(0, 3, 0, 14),
                Position = UDim2.new(0, 0, 0.5, -7),
                BackgroundColor3 = Theme.accent,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, titleRow)
            mk("TextLabel", {
                Size = UDim2.new(1, -12, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = title,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Theme.accent2,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3,
            }, titleRow)

            local list = mk("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 26),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 3,
            }, gb)
            mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

            local gbo = {}

            function gbo:AddLabel(text)
                mk("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Theme.subtext,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 3,
                }, list)
            end

            function gbo:AddDivider()
                local d = mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.border, BorderSizePixel = 0, ZIndex = 3 }, list)
                mk("UIGradient", {
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                }, d)
            end

            function gbo:AddToggle(opts)
                local state = opts.Default or false
                local row = mk("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.bg,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, list)
                corner(row, 6); stroke(row, Theme.border)

                mk("TextLabel", {
                    Size = UDim2.new(1, -70, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = opts.Text or "",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)

                local pill = mk("TextButton", {
                    Size = UDim2.new(0, 46, 0, 20),
                    Position = UDim2.new(1, -56, 0.5, -10),
                    BackgroundColor3 = state and Theme.on or Theme.off,
                    Text = state and "ON" or "OFF",
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextColor3 = Theme.text,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 4,
                }, row)
                corner(pill, 10)

                pill.MouseButton1Click:Connect(function()
                    state = not state
                    tween(pill, 0.15, { BackgroundColor3 = state and Theme.on or Theme.off })
                    pill.Text = state and "ON" or "OFF"
                    if opts.Callback then opts.Callback(state) end
                end)
            end

            function gbo:AddInput(opts)
                local row = mk("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundColor3 = Theme.bg,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, list)
                corner(row, 6); stroke(row, Theme.border)

                mk("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 14),
                    Position = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Text = opts.Text or "",
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Theme.subtext,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)

                local box = mk("TextBox", {
                    Size = UDim2.new(1, -20, 0, 22),
                    Position = UDim2.new(0, 10, 0, 20),
                    BackgroundColor3 = Theme.panel,
                    Text = tostring(opts.Default or ""),
                    PlaceholderText = opts.Placeholder or "",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.text,
                    PlaceholderColor3 = Theme.subtext,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)
                corner(box, 4); stroke(box, Theme.border)
                mk("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, box)

                box.Focused:Connect(function() tween(box, 0.15, { BackgroundColor3 = Theme.panel2 }); box.UIStroke.Color = Theme.accent end)
                box.FocusLost:Connect(function()
                    tween(box, 0.15, { BackgroundColor3 = Theme.panel }); box.UIStroke.Color = Theme.border
                    if opts.Callback then
                        local v = box.Text
                        if opts.Numeric then v = tonumber(v); if v == nil then return end end
                        opts.Callback(v)
                    end
                end)
            end

            function gbo:AddSlider(opts)
                local min, max = opts.Min or 0, opts.Max or 100
                local val = opts.Default or min
                local row = mk("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundColor3 = Theme.bg,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, list)
                corner(row, 6); stroke(row, Theme.border)

                local lbl = mk("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 14),
                    Position = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Text = (opts.Text or "") .. "  —  " .. tostring(val),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Theme.subtext,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)

                local track = mk("Frame", {
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 0, 30),
                    BackgroundColor3 = Theme.panel2,
                    BorderSizePixel = 0,
                    ZIndex = 4,
                }, row)
                corner(track, 3)

                local fill = mk("Frame", {
                    Size = UDim2.new((val - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.accent,
                    BorderSizePixel = 0,
                    ZIndex = 4,
                }, track)
                corner(fill, 3)

                local knob = mk("Frame", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new((val - min) / (max - min), -6, 0.5, -6),
                    BackgroundColor3 = Theme.text,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, track)
                corner(knob, 6)

                local dragging = false
                local function update(input)
                    local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    val = math.floor(min + rel * (max - min) + 0.5)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, -6, 0.5, -6)
                    lbl.Text = (opts.Text or "") .. "  —  " .. tostring(val)
                    if opts.Callback then opts.Callback(val) end
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; update(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        update(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
            end

            function gbo:AddButton(text, callback)
                local btn = mk("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.btn,
                    Text = text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 12,
                    TextColor3 = Theme.text,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    ZIndex = 3,
                }, list)
                corner(btn, 6); stroke(btn, Theme.border)
                btn.MouseEnter:Connect(function() tween(btn, 0.15, { BackgroundColor3 = Theme.btnHover }) end)
                btn.MouseLeave:Connect(function() tween(btn, 0.15, { BackgroundColor3 = Theme.btn }) end)
                btn.MouseButton1Click:Connect(function()
                    tween(btn, 0.08, { BackgroundColor3 = Theme.accent })
                    task.delay(0.1, function() tween(btn, 0.15, { BackgroundColor3 = Theme.btn }) end)
                    if callback then callback() end
                end)
            end

            function gbo:AddDropdown(opts)
                local values = opts.Values or {}
                local current = opts.Default or values[1]
                if not table.find(values, current) then current = values[1] end

                local row = mk("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundColor3 = Theme.bg,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, list)
                corner(row, 6); stroke(row, Theme.border)

                mk("TextLabel", {
                    Size = UDim2.new(1, -20, 0, 14),
                    Position = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Text = opts.Text or "",
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Theme.subtext,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)

                local btn = mk("TextButton", {
                    Size = UDim2.new(1, -20, 0, 22),
                    Position = UDim2.new(0, 10, 0, 20),
                    BackgroundColor3 = Theme.panel,
                    Text = "  " .. tostring(current) .. "   ▾",
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.text,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                }, row)
                corner(btn, 4); stroke(btn, Theme.border)

                -- popup (parented to screen so it draws over everything)
                local popup = mk("ScrollingFrame", {
                    Size = UDim2.new(0, 200, 0, math.min(#values * 26, 200)),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Theme.panel2,
                    BorderSizePixel = 0,
                    Visible = false,
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme.accent,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 100,
                }, screen)
                corner(popup, 6); stroke(popup, Theme.accent)
                local pl = mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
                mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, popup)

                local open = false
                local buttons = {}
                for _, v in ipairs(values) do
                    local ob = mk("TextButton", {
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundColor3 = Theme.panel,
                        Text = "  " .. tostring(v),
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextColor3 = Theme.text,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 101,
                    }, popup)
                    corner(ob, 4)
                    ob.MouseEnter:Connect(function() tween(ob, 0.1, { BackgroundColor3 = Theme.accent }) end)
                    ob.MouseLeave:Connect(function() tween(ob, 0.1, { BackgroundColor3 = Theme.panel }) end)
                    ob.MouseButton1Click:Connect(function()
                        current = v
                        btn.Text = "  " .. tostring(v) .. "   ▾"
                        open = false; popup.Visible = false
                        if opts.Callback then opts.Callback(v) end
                    end)
                    table.insert(buttons, ob)
                end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        popup.Position = UDim2.new(0, btn.AbsolutePosition.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4)
                        popup.Visible = true
                    else
                        popup.Visible = false
                    end
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local mx, my = input.Position.X, input.Position.Y
                        local p = popup.AbsolutePosition
                        local s = popup.AbsoluteSize
                        if not (mx >= p.X and mx <= p.X + s.X and my >= p.Y and my <= p.Y + s.Y) then
                            open = false; popup.Visible = false
                        end
                    end
                end)
            end

            table.insert(tab.boxes, gbo)
            return gbo
        end

        table.insert(self.tabs, tab)
        return tab
    end

    -- ===== SEARCH =====
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, t in ipairs(self.tabs) do
            t.button.Visible = (q == "") or t.name:lower():find(q, 1, true) ~= nil
        end
    end)

    -- ===== DRAG =====
    local dragging, dragStart, startPos
    tb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ===== KEYBIND =====
    local uiVisible = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            uiVisible = not uiVisible
            main.Visible = uiVisible
        end
    end)

    -- Select first tab
    if #self.tabs > 0 then
        local first = self.tabs[1]
        first.page.Visible = true
        first.button.BackgroundColor3 = Theme.accent
        first.button.TextColor3 = Theme.text
        first.indicator.Visible = true
        self.active = first
    end

    return win
end

-- ============================================================
-- CONFIG SAVE/LOAD (uses writefile if available)
-- ============================================================
local Cfg = {
    AutoBlock = false, AutoBlockAudio = false, BlockType = "Block",
    DetectionRange = 18, FacingCheck = false, FacingDot = -0.3,
    BlockDelay = 0, MessageWhenBlock = false, BlockMessage = "",
    MessageWhenPunch = false, PunchMessage = "",
    DoublePunch = false, HitboxDrag = false, HDTspeed = 5.6, HDTdelay = 0,
    AutoPunch = false, AimPunch = false, FlingPunch = false, FlingPower = 10000,
    PredictionValue = 4, CustomBlock = false, CustomBlockId = "",
    CustomPunch = false, CustomPunchId = "", CustomCharge = false, CustomChargeId = "",
    ESP = true, AntiFlick = false, AntiFlickParts = 4, AntiFlickDelay = 0,
    AntiFlickStagger = 0.02, AntiFlickOffset = 2.7, AntiFlickSizeMul = 1,
    PredictiveBlock = false, EdgeKiller = 3, PredictionStrength = 1, PredictionTurnStrength = 1,
}

local function saveConfig()
    if not writefile then notify("Save", "Executor doesn't support writefile", 3); return end
    local ok, enc = pcall(function() return game:GetService("HttpService"):JSONEncode(Cfg) end)
    if ok then
        pcall(function() writefile("forsaken_ab_v2.json", enc) end)
        notify("Config Saved", "Saved to forsaken_ab_v2.json", 3)
    end
end

local function loadConfig()
    if not (isfile and readfile) then notify("Load", "Executor doesn't support readfile", 3); return end
    if not isfile("forsaken_ab_v2.json") then notify("Load", "No saved config found", 3); return end
    local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("forsaken_ab_v2.json")) end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do Cfg[k] = v end
        notify("Config Loaded", "Restart script to apply", 3)
    end
end

-- ============================================================
-- ID TABLES
-- ============================================================
local autoBlockTriggerAnims = {
    "126830014841198","126355327951215","121086746534252","18885909645",
    "98456918873918","105458270463374","83829782357897","125403313786645",
    "118298475669935","82113744478546","70371667919898","99135633258223",
    "97167027849946","109230267448394","139835501033932","126896426760253",
    "109667959938617","126681776859538","129976080405072","121293883585738",
    "81639435858902","137314737492715","92173139187970","122709416391","879895330952"
}

local autoBlockTriggerSounds = {
    ["102228729296384"]=true,["140242176732868"]=true,["112809109188560"]=true,
    ["136323728355613"]=true,["115026634746636"]=true,["84116622032112"]=true,
    ["108907358619313"]=true,["127793641088496"]=true,["86174610237192"]=true,
    ["95079963655241"]=true,["101199185291628"]=true,["119942598489800"]=true,
    ["84307400688050"]=true,["113037804008732"]=true,["105200830849301"]=true,
    ["75330693422988"]=true,["82221759983649"]=true,["81702359653578"]=true,
    ["108610718831698"]=true,["112395455254818"]=true,["109431876587852"]=true,
    ["109348678063422"]=true,["85853080745515"]=true,["12222216"]=true,
    ["105840448036441"]=true,["114742322778642"]=true,["119583605486352"]=true,
    ["79980897195554"]=true,["71805956520207"]=true,["79391273191671"]=true,
    ["89004992452376"]=true,["101553872555606"]=true,["101698569375359"]=true,
    ["106300477136129"]=true,["116581754553533"]=true,["117231507259853"]=true,
    ["119089145505438"]=true,["121954639447247"]=true,["125213046326879"]=true,
    ["131406927389838"]=true,["71834552297085"]=true,["805165833096"]=true,
}

local blockAnimIds  = {"72722244508749","96959123077498","95802026624883"}
local punchAnimIds  = {"87259391926321","140703210927645","136007065400978","129843313690921","86709774283672","108807732150251","138040001965654","86096387000557"}
local chargeAnimIds = {"106014898538300"}
local killerNames   = {"c00lkidd","Jason","JohnDoe","1x1x1x1","Noli","Slasher","Sixer"}

-- ============================================================
-- HELPERS + REMOTE FIRING
-- ============================================================
local function fireGuiBlock()  RE:FireServer("UseActorAbility", { buffer.fromstring("\"Block\"") })  end
local function fireGuiPunch()  RE:FireServer("UseActorAbility", { buffer.fromstring("\"Punch\"") })  end
local function fireGuiCharge() RE:FireServer("UseActorAbility", { buffer.fromstring("\"Charge\"") }) end
local function fireGuiClone()  RE:FireServer("UseActorAbility", { buffer.fromstring("\"Clone\"") })  end

local function isFacing(localRoot, targetRoot)
    if not Cfg.FacingCheck then return true end
    local dx = localRoot.Position.X - targetRoot.Position.X
    local dy = localRoot.Position.Y - targetRoot.Position.Y
    local dz = localRoot.Position.Z - targetRoot.Position.Z
    local mag = math.sqrt(dx*dx + dy*dy + dz*dz)
    if mag == 0 then return true end
    local inv = 1 / mag
    local lv = targetRoot.CFrame.LookVector
    return (lv.X*(dx*inv) + lv.Y*(dy*inv) + lv.Z*(dz*inv)) > (Cfg.FacingDot or -0.3)
end

local function getNearestKillerModel()
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local closest, closestDist = nil, math.huge
    for _, k in ipairs(KF:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (hrp.Position - myRoot.Position).Magnitude
            if d < closestDist then closest, closestDist = k, d end
        end
    end
    return closest
end

-- ============================================================
-- AUTO BLOCK (ANIMATION)
-- ============================================================
local lastBlockTime = 0
RunService.RenderStepped:Connect(function()
    if not Cfg.AutoBlock then return end
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local gui = PlayerGui:FindFirstChild("MainUI")
    local blockBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Block")
    local cooldown = blockBtn and blockBtn:FindFirstChild("CooldownTime")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if hrp and animator and (hrp.Position - myRoot.Position).Magnitude <= Cfg.DetectionRange then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local id = tostring(track.Animation.AnimationId):match("%d+")
                    if table.find(autoBlockTriggerAnims, id) and isFacing(myRoot, hrp) then
                        if cooldown and cooldown.Text == "" and tick() - lastBlockTime > 0.3 then
                            lastBlockTime = tick()
                            task.wait(Cfg.BlockDelay)
                            if Cfg.BlockType == "Block" then fireGuiBlock()
                            elseif Cfg.BlockType == "Charge" then fireGuiCharge()
                            elseif Cfg.BlockType == "7n7 Clone" then fireGuiClone() end
                            if Cfg.DoublePunch then fireGuiPunch() end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- AUTO BLOCK (AUDIO)
-- ============================================================
local hookedSounds = {}
local soundBlockedUntil = {}
local lastLocalBlockTime = 0

local function extractSoundId(sound)
    local sid = sound.SoundId
    if not sid then return nil end
    sid = tostring(sid)
    return sid:match("rbxassetid://(%d+)") or sid:match("://(%d+)") or sid:match("^(%d+)$")
end

local function attemptSoundBlock(sound)
    if not Cfg.AutoBlockAudio or not sound or not sound.IsPlaying then return end
    local id = extractSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end

    local now = tick()
    if soundBlockedUntil[sound] and now < soundBlockedUntil[sound] then return end
    if now - lastLocalBlockTime < 0.35 then return end

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local parent = sound.Parent
    local pos
    if parent and parent:IsA("BasePart") then pos = parent.Position
    elseif parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then pos = parent.Parent.Position end
    if not pos then return end
    if (pos - myRoot.Position).Magnitude > Cfg.DetectionRange + 3 then return end

    local gui = PlayerGui:FindFirstChild("MainUI")
    local blockBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Block")
    local cooldown = blockBtn and blockBtn:FindFirstChild("CooldownTime")
    if not cooldown or cooldown.Text ~= "" then return end

    if Cfg.BlockType == "Block" then fireGuiBlock()
    elseif Cfg.BlockType == "Charge" then fireGuiCharge()
    elseif Cfg.BlockType == "7n7 Clone" then fireGuiClone() end
    if Cfg.DoublePunch then fireGuiPunch() end

    lastLocalBlockTime = now
    soundBlockedUntil[sound] = now + 1.0
end

local function hookSound(sound)
    if hookedSounds[sound] then return end
    hookedSounds[sound] = true
    sound.Played:Connect(function() attemptSoundBlock(sound) end)
    sound:GetPropertyChangedSignal("IsPlaying"):Connect(function() if sound.IsPlaying then attemptSoundBlock(sound) end end)
    sound.Destroying:Connect(function() hookedSounds[sound] = nil end)
    if sound.IsPlaying then attemptSoundBlock(sound) end
end

for _, d in ipairs(KF:GetDescendants()) do if d:IsA("Sound") then hookSound(d) end end
KF.DescendantAdded:Connect(function(d) if d:IsA("Sound") then hookSound(d) end end)

-- ============================================================
-- ANTI-FLICK / BETTER DETECTION (parts spawning)
-- ============================================================
local function attemptAntiFlick(sound)
    if not Cfg.AntiFlick or not sound or not sound.IsPlaying then return end
    local id = extractSoundId(sound)
    if not id or not autoBlockTriggerSounds[id] then return end

    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local parent = sound.Parent
    local pos
    if parent and parent:IsA("BasePart") then pos = parent.Position
    elseif parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then pos = parent.Parent.Position end
    if not pos then return end

    local killer = nil
    for _, k in ipairs(KF:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - pos).Magnitude < 5 then killer = hrp; break end
    end
    if not killer then return end

    task.spawn(function()
        task.wait(Cfg.AntiFlickDelay or 0)
        local baseSize = Vector3.new(5.5, 7.5, 8.5) * (Cfg.AntiFlickSizeMul or 1)
        for i = 1, (Cfg.AntiFlickParts or 4) do
            if not killer or not killer.Parent then break end
            local d = (Cfg.AntiFlickOffset or 2.7) + (i-1) * 0.2
            local spawnPos = killer.Position + killer.CFrame.LookVector * d
            local p = Instance.new("Part")
            p.Size = baseSize
            p.Transparency = 0.5
            p.Anchored = true
            p.CanCollide = false
            p.CFrame = CFrame.new(spawnPos, killer.Position)
            p.BrickColor = BrickColor.new("Bright blue")
            p.Parent = workspace
            Debris:AddItem(p, 0.2)

            if (p.Position - myRoot.Position).Magnitude < 6 then
                if Cfg.BlockType == "Block" then fireGuiBlock()
                elseif Cfg.BlockType == "Charge" then fireGuiCharge() end
                break
            end
            task.wait(Cfg.AntiFlickStagger or 0.02)
        end
    end)
end

-- Wire anti-flick to sound triggers
for _, d in ipairs(KF:GetDescendants()) do
    if d:IsA("Sound") then d.Played:Connect(function() attemptAntiFlick(d) end) end
end
KF.DescendantAdded:Connect(function(d)
    if d:IsA("Sound") then d.Played:Connect(function() attemptAntiFlick(d) end) end
end)

-- ============================================================
-- AUTO PUNCH
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Cfg.AutoPunch then return end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local gui = PlayerGui:FindFirstChild("MainUI")
    local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
    local charges = punchBtn and punchBtn:FindFirstChild("Charges")
    if not charges or charges.Text ~= "1" then return end
    for _, name in ipairs(killerNames) do
        local k = KF:FindFirstChild(name)
        if k and k:FindFirstChild("HumanoidRootPart") then
            if (k.HumanoidRootPart.Position - myRoot.Position).Magnitude <= 10 then
                fireGuiPunch(); break
            end
        end
    end
end)

-- ============================================================
-- AIM PUNCH
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Cfg.AimPunch then return end
    local myChar = lp.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator or not myRoot then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local id = tostring(track.Animation.AnimationId):match("%d+")
        if table.find(punchAnimIds, id) then
            local k = getNearestKillerModel()
            if k then
                local hrp = k:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local predicted = hrp.Position + hrp.CFrame.LookVector * Cfg.PredictionValue
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, predicted)
                end
            end
        end
    end
end)

-- ============================================================
-- HITBOX DRAGGING
-- ============================================================
local function getKillerHRP(k) return k and (k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart) end
local hdtActive = false

local function beginDrag(killer)
    if hdtActive or not killer then return end
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local target = getKillerHRP(killer)
    if not target then return end

    hdtActive = true
    local oldW, oldJ = hum.WalkSpeed, hum.JumpPower
    hum.WalkSpeed, hum.JumpPower = 0, 0

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not hdtActive then
            conn:Disconnect(); pcall(function() bv:Destroy() end)
            if hum then hum.WalkSpeed, hum.JumpPower = oldW, oldJ end
            return
        end
        if not (char.Parent and killer.Parent) then hdtActive = false; return end
        target = getKillerHRP(killer)
        if not target then hdtActive = false; return end
        local diff = target.Position - hrp.Position
        local horiz = Vector3.new(diff.X, 0, diff.Z)
        if horiz.Magnitude > 0.01 then bv.Velocity = horiz.Unit * Cfg.HDTspeed end
        if diff.Magnitude <= 2 then hdtActive = false end
    end)

    task.delay(1.4, function() hdtActive = false end)
end

RunService.RenderStepped:Connect(function()
    if not Cfg.HitboxDrag then return end
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local id = tostring(track.Animation.AnimationId):match("%d+")
        if table.find(blockAnimIds, id) and (track.TimePosition or 0) <= 0.12 then
            local k = getNearestKillerModel()
            if k then task.wait(Cfg.HDTdelay); task.spawn(beginDrag, k) end
        end
    end
end)

-- ============================================================
-- KILLER ESP
-- ============================================================
local function addESP(obj)
    if not obj:IsA("Model") or obj:FindFirstChild("ESP_Highlight") or not obj:FindFirstChild("HumanoidRootPart") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj; hl.Parent = obj

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"; bb.Size = UDim2.new(0, 100, 0, 50)
    bb.AlwaysOnTop = true; bb.Adornee = obj.HumanoidRootPart; bb.Parent = obj
    local tl = Instance.new("TextLabel")
    tl.Name = "ESP_Text"; tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = Color3.fromRGB(255, 60, 60)
    tl.TextScaled = true; tl.Font = Enum.Font.SourceSansBold
    tl.Text = obj.Name; tl.Parent = bb
end

local function clearESP(obj)
    if obj:FindFirstChild("ESP_Highlight") then obj.ESP_Highlight:Destroy() end
    if obj:FindFirstChild("ESP_Billboard") then obj.ESP_Billboard:Destroy() end
end

local function refreshESP()
    for _, k in ipairs(KF:GetChildren()) do
        if Cfg.ESP then addESP(k) else clearESP(k) end
    end
end

KF.ChildAdded:Connect(function(c) if Cfg.ESP then task.wait(0.1); addESP(c) end end)
KF.ChildRemoved:Connect(clearESP)

RunService.RenderStepped:Connect(function()
    if not Cfg.ESP then return end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, k in ipairs(KF:GetChildren()) do
        local bb = k:FindFirstChild("ESP_Billboard")
        if bb and bb:FindFirstChild("ESP_Text") and k:FindFirstChild("HumanoidRootPart") then
            local d = (k.HumanoidRootPart.Position - hrp.Position).Magnitude
            bb.ESP_Text.Text = string.format("%s\n[%d]", k.Name, d)
        end
    end
end)

-- ============================================================
-- MESSAGE WHEN BLOCK/PUNCH
-- ============================================================
local function sendChat(msg)
    if not msg or msg:match("^%s*$") then return end
    pcall(function() game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(msg) end)
end

local _pb, _pp, _lastBM, _lastPM = {}, {}, 0, 0
RunService.RenderStepped:Connect(function()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    local curB, curP = {}, {}
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local id = tostring(track.Animation.AnimationId):match("%d+")
        if table.find(blockAnimIds, id) then
            curB[id] = true
            if not _pb[id] and Cfg.MessageWhenBlock and tick() - _lastBM > 0.6 then
                sendChat(Cfg.BlockMessage); _lastBM = tick()
            end
        end
        if table.find(punchAnimIds, id) then
            curP[id] = true
            if not _pp[id] and Cfg.MessageWhenPunch and tick() - _lastPM > 0.6 then
                sendChat(Cfg.PunchMessage); _lastPM = tick()
            end
        end
    end
    _pb, _pp = curB, curP
end)

-- ============================================================
-- BUILD UI
-- ============================================================
local Window = UILib:CreateWindow({ Title = "Forsaken", Subtitle = "Auto Block v2" })

-- NOTICE
local noticeTab = Window:AddTab("Notice")
local ng = noticeTab:AddGroupbox("Welcome")
ng:AddLabel("Thanks for using the script.")
ng:AddLabel("RightShift toggles the UI.")
ng:AddDivider()
ng:AddLabel("Save / Load your config from the Misc tab.")

-- AUTO BLOCK
local abTab = Window:AddTab("Auto Block")
local abGb = abTab:AddGroupbox("Auto Block")
abGb:AddToggle({ Text = "Auto Block (Animation)", Default = Cfg.AutoBlock, Callback = function(v) Cfg.AutoBlock = v end })
abGb:AddToggle({ Text = "Auto Block (Audio)", Default = Cfg.AutoBlockAudio, Callback = function(v) Cfg.AutoBlockAudio = v end })
abGb:AddDropdown({ Text = "Block Type", Values = {"Block","Charge","7n7 Clone"}, Default = Cfg.BlockType,
    Callback = function(v) Cfg.BlockType = v end })
abGb:AddSlider({ Text = "Detection Range", Min = 5, Max = 40, Default = Cfg.DetectionRange,
    Callback = function(v) Cfg.DetectionRange = v end })
abGb:AddInput({ Text = "Block Delay (s)", Default = tostring(Cfg.BlockDelay), Numeric = true, Callback = function(v) Cfg.BlockDelay = v end })
abGb:AddDivider()
abGb:AddToggle({ Text = "Facing Check", Default = Cfg.FacingCheck, Callback = function(v) Cfg.FacingCheck = v end })
abGb:AddSlider({ Text = "Facing DOT ×10 (-10 = -1)", Min = -10, Max = 10, Default = -3,
    Callback = function(v) Cfg.FacingDot = v / 10 end })
abGb:AddDivider()
abGb:AddToggle({ Text = "Message When Blocking", Default = Cfg.MessageWhenBlock, Callback = function(v) Cfg.MessageWhenBlock = v end })
abGb:AddInput({ Text = "Block Message", Default = Cfg.BlockMessage, Callback = function(v) Cfg.BlockMessage = v end })

-- BETTER DETECTION
local bdTab = Window:AddTab("BD")
local bdGb = bdTab:AddGroupbox("Better Detection")
bdGb:AddToggle({ Text = "Anti-Flick", Default = Cfg.AntiFlick, Callback = function(v) Cfg.AntiFlick = v end })
bdGb:AddSlider({ Text = "Parts to spawn", Min = 1, Max = 10, Default = Cfg.AntiFlickParts, Callback = function(v) Cfg.AntiFlickParts = v end })
bdGb:AddSlider({ Text = "Delay before parts ×100", Min = 0, Max = 100, Default = Cfg.AntiFlickDelay * 100,
    Callback = function(v) Cfg.AntiFlickDelay = v / 100 end })
bdGb:AddSlider({ Text = "Stagger ×100", Min = 0, Max = 20, Default = Cfg.AntiFlickStagger * 100,
    Callback = function(v) Cfg.AntiFlickStagger = v / 100 end })
bdGb:AddSlider({ Text = "Offset studs ×10", Min = 5, Max = 60, Default = Cfg.AntiFlickOffset * 10,
    Callback = function(v) Cfg.AntiFlickOffset = v / 10 end })
bdGb:AddSlider({ Text = "Size Multiplier ×10", Min = 5, Max = 30, Default = Cfg.AntiFlickSizeMul * 10,
    Callback = function(v) Cfg.AntiFlickSizeMul = v / 10 end })

-- PREDICTIVE
local pTab = Window:AddTab("Predictive")
local pGb = pTab:AddGroupbox("Predictive Auto Block")
pGb:AddToggle({ Text = "Enable", Default = Cfg.PredictiveBlock, Callback = function(v) Cfg.PredictiveBlock = v end })
pGb:AddSlider({ Text = "Edge Killer Delay (s)", Min = 1, Max = 10, Default = Cfg.EdgeKiller, Callback = function(v) Cfg.EdgeKiller = v end })

local predictiveCooldown, killerInRangeSince = 0, nil
RunService.RenderStepped:Connect(function()
    if not Cfg.PredictiveBlock or tick() < predictiveCooldown then return end
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local inRange = false
    for _, k in ipairs(KF:GetChildren()) do
        local hrp = k:FindFirstChild("HumanoidRootPart")
        if hrp and (myHRP.Position - hrp.Position).Magnitude <= Cfg.DetectionRange then inRange = true break end
    end
    if inRange then
        if not killerInRangeSince then killerInRangeSince = tick()
        elseif tick() - killerInRangeSince >= Cfg.EdgeKiller then
            fireGuiBlock(); predictiveCooldown = tick() + 2; killerInRangeSince = nil
        end
    else killerInRangeSince = nil end
end)

-- TECHS
local tTab = Window:AddTab("Techs")
local tGb = tTab:AddGroupbox("Combat Techs")
tGb:AddToggle({ Text = "Double Punch", Default = Cfg.DoublePunch, Callback = function(v) Cfg.DoublePunch = v end })
tGb:AddToggle({ Text = "Hitbox Dragging", Default = Cfg.HitboxDrag, Callback = function(v) Cfg.HitboxDrag = v end })
tGb:AddSlider({ Text = "HDT Speed ×10", Min = 10, Max = 100, Default = Cfg.HDTspeed * 10,
    Callback = function(v) Cfg.HDTspeed = v / 10 end })
tGb:AddSlider({ Text = "HDT Delay ×100", Min = 0, Max = 50, Default = Cfg.HDTdelay * 100,
    Callback = function(v) Cfg.HDTdelay = v / 100 end })
tGb:AddDivider()
tGb:AddButton("Fake Lag", function()
    pcall(function()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://136252471123500"
        local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
        animator:LoadAnimation(anim):Play()
    end)
end)

-- AUTO PUNCH
local apTab = Window:AddTab("Auto Punch")
local apGb = apTab:AddGroupbox("Auto Punch")
apGb:AddToggle({ Text = "Auto Punch", Default = Cfg.AutoPunch, Callback = function(v) Cfg.AutoPunch = v end })
apGb:AddToggle({ Text = "Punch Aimbot", Default = Cfg.AimPunch, Callback = function(v) Cfg.AimPunch = v end })
apGb:AddSlider({ Text = "Aim Prediction ×10", Min = 0, Max = 100, Default = Cfg.PredictionValue * 10,
    Callback = function(v) Cfg.PredictionValue = v / 10 end })
apGb:AddDivider()
apGb:AddToggle({ Text = "Message When Punching", Default = Cfg.MessageWhenPunch, Callback = function(v) Cfg.MessageWhenPunch = v end })
apGb:AddInput({ Text = "Punch Message", Default = Cfg.PunchMessage, Callback = function(v) Cfg.PunchMessage = v end })

-- CUSTOM ANIMS
local cTab = Window:AddTab("Custom Anims")
local cGb = cTab:AddGroupbox("Custom Animations")
cGb:AddToggle({ Text = "Custom Block", Default = Cfg.CustomBlock, Callback = function(v) Cfg.CustomBlock = v end })
cGb:AddInput({ Text = "Block Anim ID", Default = Cfg.CustomBlockId, Callback = function(v) Cfg.CustomBlockId = v end })
cGb:AddDivider()
cGb:AddToggle({ Text = "Custom Punch", Default = Cfg.CustomPunch, Callback = function(v) Cfg.CustomPunch = v end })
cGb:AddInput({ Text = "Punch Anim ID", Default = Cfg.CustomPunchId, Callback = function(v) Cfg.CustomPunchId = v end })

-- MISC
local mTab = Window:AddTab("Misc")
local mGb = mTab:AddGroupbox("Miscellaneous")
mGb:AddToggle({ Text = "Killer ESP", Default = Cfg.ESP, Callback = function(v) Cfg.ESP = v; refreshESP() end })
mGb:AddDivider()
mGb:AddButton("Save Config", saveConfig)
mGb:AddButton("Load Config", loadConfig)
mGb:AddDivider()
mGb:AddButton("Infinite Yield", function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
end)
mGb:AddButton("Unload Script", function() Window.screen:Destroy() end)

notify("Forsaken", "Auto Block v2 loaded! RightShift toggles UI.", 5)
