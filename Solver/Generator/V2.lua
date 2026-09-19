--[[
    Flow Solver — Rayfield Edition
    ============================================================
    Converted from custom GUI to Rayfield
    - Mode dropdown (Auto-Solve / Show Path)
    - Hook toggle
    - All puzzle-solving logic preserved
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

-- ============================================================
-- LOAD RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- STATE
-- ============================================================
local currentMode = "Auto-Solve"
local isHooked = false
local moduleHooked = false
local activeHighlights = {}
local lastActivePuzzle = nil

local FALLBACK_COLORS = {
    Color3.fromRGB(255, 50, 50), Color3.fromRGB(50, 255, 50),
    Color3.fromRGB(50, 120, 255), Color3.fromRGB(255, 255, 50)
}

-- ============================================================
-- HIGHLIGHT MANAGEMENT
-- ============================================================
local function clearExternalHighlights()
    for _, obj in ipairs(activeHighlights) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    table.clear(activeHighlights)

    if lastActivePuzzle then
        lastActivePuzzle._highlightsDrawn = false
    end
end

-- ============================================================
-- COLOR RESOLUTION
-- ============================================================
local function getExactPuzzleColor(puzzle, colorIndex, cellLookup)
    if puzzle.colors and puzzle.colors[colorIndex] then return puzzle.colors[colorIndex] end
    if puzzle.Colors and puzzle.Colors[colorIndex] then return puzzle.Colors[colorIndex] end

    local endpoints = puzzle.targetPairs and puzzle.targetPairs[colorIndex]
    if endpoints and endpoints[1] then
        local ep = endpoints[1]
        local n1, n2 = `{ep.row}-{ep.col}`, `{ep.row}_{ep.col}`
        local n3, n4 = `Cell-{ep.row}-{ep.col}`, `Cell_{ep.row}_{ep.col}`
        local cellUi = cellLookup[n1] or cellLookup[n2] or cellLookup[n3] or cellLookup[n4]

        if cellUi then
            for _, child in ipairs(cellUi:GetChildren()) do
                if child:IsA("GuiObject") and child.BackgroundTransparency < 1 and child.BackgroundColor3.R > 0.05 then
                    return child.BackgroundColor3
                elseif child:IsA("ImageLabel") and child.ImageColor3 then
                    return child.ImageColor3
                end
            end
            return cellUi.BackgroundColor3
        end
    end
    return FALLBACK_COLORS[((colorIndex - 1) % #FALLBACK_COLORS) + 1]
end

-- ============================================================
-- PATH CALCULATIONS
-- ============================================================
local function getDirection(currentRow, currentCol, otherRow, otherCol)
    if otherRow < currentRow then return "up" end
    if otherRow > currentRow then return "down" end
    if otherCol < currentCol then return "left" end
    if otherCol > currentCol then return "right" end
end

local function getConnections(prev, curr, nextnode)
    local connections = {}
    if prev and curr then
        local dir = getDirection(curr.row, curr.col, prev.row, prev.col)
        if dir == "up" then dir = "down"
        elseif dir == "down" then dir = "up"
        elseif dir == "left" then dir = "right"
        elseif dir == "right" then dir = "left" end
        if dir ~= "" and dir then connections[dir] = true end
    end
    if nextnode and curr then
        local dir = getDirection(curr.row, curr.col, nextnode.row, nextnode.col)
        if dir ~= "" and dir then connections[dir] = true end
    end
    return connections
end

local function isNeighbourLocal(r1, c1, r2, c2)
    if r2 == r1 - 1 and c2 == c1 then return "up" end
    if r2 == r1 + 1 and c2 == c1 then return "down" end
    if r2 == r1 and c2 == c1 - 1 then return "left" end
    if r2 == r1 and c2 == c1 + 1 then return "right" end
    return false
end

local function coordKey(node) return `{node.row}-{node.col}` end

local function orderPathFromEndpoints(path, endpoints)
    if not path or #path == 0 then return path end
    local startEndpoint
    for _, ep in endpoints or {} do
        for _1, n in path do
            if n.row == ep.row and n.col == ep.col then
                startEndpoint = { row = ep.row, col = ep.col }
                break
            end
        end
        if startEndpoint then break end
    end
    if not startEndpoint then
        local inPath = {}
        for _, n in path do inPath[coordKey(n)] = n end
        for _, n in path do
            local neighbours = 0
            local dirs = { { n.row - 1, n.col }, { n.row + 1, n.col }, { n.row, n.col - 1 }, { n.row, n.col + 1 } }
            for _1, _binding in dirs do
                local r, c = _binding[1], _binding[2]
                if inPath[`{r}-{c}`] ~= nil then neighbours += 1 end
            end
            if neighbours == 1 then
                startEndpoint = { row = n.row, col = n.col }
                break
            end
        end
    end
    if not startEndpoint then
        startEndpoint = { row = path[1].row, col = path[1].col }
    end
    local remaining = {}
    for _, n in path do
        remaining[coordKey(n)] = { row = n.row, col = n.col }
    end
    local ordered = {}
    local current = { row = startEndpoint.row, col = startEndpoint.col }
    local _object = table.clone(current)
    setmetatable(_object, nil)
    table.insert(ordered, _object)
    remaining[coordKey(current)] = nil
    while true do
        local _size = 0
        for _ in remaining do _size += 1 end
        if not (_size > 0) then break end
        local foundNext = false
        for key, node in remaining do
            local _value = isNeighbourLocal(current.row, current.col, node.row, node.col)
            if _value ~= "" and _value then
                local _object_1 = table.clone(node)
                setmetatable(_object_1, nil)
                table.insert(ordered, _object_1)
                remaining[key] = nil
                current = node
                foundNext = true
                break
            end
        end
        if not foundNext then return path end
    end
    return ordered
end

-- ============================================================
-- HINT SYSTEM
-- ============================================================
local HintSystem = {}
do
    local _container = HintSystem

    local function HighlightSolutionExternally(self, puzzle)
        if not isHooked or not puzzle or not puzzle.Solution then return end

        -- Smart cache invalidation
        if puzzle._highlightsDrawn then
            local firstHighlight = activeHighlights[1]
            if firstHighlight and firstHighlight:IsDescendantOf(game) then
                return
            else
                puzzle._highlightsDrawn = false
            end
        end

        clearExternalHighlights()

        local base = puzzle.gui or puzzle.frame or puzzle.mainGui

        if base and not base:IsDescendantOf(game) then
            base = nil
        end

        if not base then
            local sampleNode = puzzle.Solution[1] and puzzle.Solution[1][1]
            if sampleNode then
                local r, c = sampleNode.row, sampleNode.col
                local formats = { `{r}-{c}`, `{r}_{c}`, `Cell-{r}-{c}`, `Cell_{r}_{c}` }
                for _, gui in ipairs(Players.LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name ~= "FlowSolverGui" then
                        for _, f in ipairs(formats) do
                            if gui:FindFirstChild(f, true) then
                                base = gui
                                break
                            end
                        end
                    end
                    if base then break end
                end
            end
        end

        if not base then return end

        -- Cache dictionary lookup with validation
        local cacheValid = false
        if puzzle._cellLookup then
            local _, sampleCell = next(puzzle._cellLookup)
            if sampleCell and sampleCell:IsDescendantOf(game) then
                cacheValid = true
            end
        end

        if not cacheValid then
            puzzle._cellLookup = {}
            for _, desc in ipairs(base:GetDescendants()) do
                if desc:IsA("GuiObject") then
                    puzzle._cellLookup[desc.Name] = desc
                end
            end
        end

        local cellLookup = puzzle._cellLookup

        for colorIndex, path in ipairs(puzzle.Solution) do
            if not isHooked then break end
            local assignedColor = getExactPuzzleColor(puzzle, colorIndex, cellLookup)
            local endpoints = puzzle.targetPairs and puzzle.targetPairs[colorIndex]
            local orderedPath = orderPathFromEndpoints(path, endpoints) or path

            for _, node in ipairs(orderedPath) do
                if not isHooked then break end
                local n1, n2 = `{node.row}-{node.col}`, `{node.row}_{node.col}`
                local n3, n4 = `Cell-{node.row}-{node.col}`, `Cell_{node.row}_{node.col}`
                local cellUi = cellLookup[n1] or cellLookup[n2] or cellLookup[n3] or cellLookup[n4]

                if cellUi then
                    local overlay = Instance.new("Frame")
                    overlay.Name = "FlowExternalHighlight"
                    overlay.Size = UDim2.new(1, 0, 1, 0)
                    overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
                    overlay.AnchorPoint = Vector2.new(0.5, 0.5)
                    overlay.BackgroundColor3 = assignedColor
                    overlay.BackgroundTransparency = 0.55
                    overlay.BorderSizePixel = 0
                    overlay.Active = false
                    overlay.ZIndex = cellUi.ZIndex + 1

                    local stroke = Instance.new("UIStroke")
                    stroke.Color = assignedColor
                    stroke.Thickness = 2
                    stroke.Transparency = 0.2
                    stroke.Parent = overlay

                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 4)
                    corner.Parent = overlay

                    overlay.Parent = cellUi
                    table.insert(activeHighlights, overlay)
                end
            end
        end

        puzzle._highlightsDrawn = true
    end
    _container.HighlightSolutionExternally = HighlightSolutionExternally

    local function DrawSolutionOneByOne(self, puzzle, delayTime)
        if delayTime == nil then delayTime = 0.05 end
        if not puzzle or not puzzle.Solution then return nil end
        local totalPaths = #puzzle.Solution
        local indices = {}
        do
            local i = 1
            local _shouldIncrement = false
            while true do
                if _shouldIncrement then i += 1 else _shouldIncrement = true end
                if not (i <= totalPaths) then break end
                table.insert(indices, i)
            end
        end
        for i = #indices - 1, 2, -1 do
            local j = math.random(1, i)
            local temp = indices[i + 1]
            indices[i + 1] = indices[j + 1]
            indices[j + 1] = temp
        end
        for _, colorIndex in indices do
            if not isHooked then break end
            local path = puzzle.Solution[colorIndex]
            local endpoints = puzzle.targetPairs[colorIndex]
            local orderedPath = orderPathFromEndpoints(path, endpoints)
            puzzle.paths[colorIndex] = {}
            for i = 0, #orderedPath - 1 do
                if not isHooked then break end
                local node = orderedPath[i + 1]
                table.insert(puzzle.paths[colorIndex], { row = node.row, col = node.col })
                local prev = orderedPath[i]
                local nextNode = orderedPath[i + 2]
                local conn = getConnections(prev, node, nextNode)
                puzzle.gridConnections = puzzle.gridConnections or {}
                puzzle.gridConnections[`{node.row}-{node.col}`] = conn
                puzzle:updateGui()
                task.wait(delayTime)
            end
            if not isHooked then break end
            puzzle:checkForWin()
        end
        if isHooked then puzzle:checkForWin() end
    end
    _container.DrawSolutionOneByOne = DrawSolutionOneByOne
end

-- ============================================================
-- HOOK LOGIC
-- ============================================================
local function applyHook()
    if not isHooked then
        clearExternalHighlights()
        return
    end

    if not moduleHooked then
        moduleHooked = true

        local _result = ReplicatedStorage:WaitForChild("Modules"):FindFirstChild("Minigames")
        if _result ~= nil then
            _result = _result:FindFirstChild("FlowGameManager")
            if _result ~= nil then
                _result = _result:FindFirstChild("FlowGame")
            end
        end
        local bb = _result
        if bb then
            local FlowGameModule = require(bb)
            local old = FlowGameModule.new
            FlowGameModule.new = function(...)
                local args = { ... }
                local output = { old(table.unpack(args)) }
                local puzzle = output[1]

                if puzzle then
                    lastActivePuzzle = puzzle

                    local oldUpdateGui = puzzle.updateGui
                    if oldUpdateGui then
                        puzzle.updateGui = function(self, ...)
                            local res = oldUpdateGui(self, ...)
                            if isHooked and currentMode == "Show Path" then
                                HintSystem:HighlightSolutionExternally(puzzle)
                            end
                            return res
                        end
                    end

                    task.spawn(function()
                        if not isHooked then return end
                        if currentMode == "Auto-Solve" then
                            HintSystem:DrawSolutionOneByOne(puzzle, 0.04)
                        else
                            HintSystem:HighlightSolutionExternally(puzzle)
                        end
                    end)
                end
                return table.unpack(output)
            end
        end
    end

    if lastActivePuzzle then
        task.spawn(function()
            if currentMode == "Auto-Solve" then
                HintSystem:DrawSolutionOneByOne(lastActivePuzzle, 0.04)
            else
                HintSystem:HighlightSolutionExternally(lastActivePuzzle)
            end
        end)
    end
end

-- ============================================================
-- RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Flow Solver",
    LoadingTitle = "Loading Flow Solver...",
    LoadingSubtitle = "by you",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FlowSolver",
        FileName = "Config",
    },
    KeySystem = false,
})

-- Main tab
local MainTab = Window:CreateTab("Solver", 4483362458)

MainTab:CreateSection("Mode")

MainTab:CreateDropdown({
    Name = "Solver Mode",
    Options = { "Auto-Solve", "Show Path" },
    CurrentOption = { "Auto-Solve" },
    Flag = "SolverMode",
    Callback = function(option)
        currentMode = type(option) == "table" and option[1] or option

        if isHooked and lastActivePuzzle then
            if currentMode == "Show Path" then
                clearExternalHighlights()
                pcall(function() lastActivePuzzle:updateGui() end)
            else
                clearExternalHighlights()
            end
        end

        Rayfield:Notify({
            Title = "Mode Changed",
            Content = "Now using: " .. currentMode,
            Duration = 3,
        })
    end,
})

MainTab:CreateSection("Hook")

MainTab:CreateToggle({
    Name = "Enable Flow Solver",
    CurrentValue = false,
    Flag = "HookEnabled",
    Callback = function(value)
        isHooked = value

        if isHooked then
            applyHook()
            Rayfield:Notify({
                Title = "Hook Enabled",
                Content = "Waiting for Flow puzzle...",
                Duration = 3,
            })
        else
            clearExternalHighlights()
            Rayfield:Notify({
                Title = "Hook Disabled",
                Content = "Solver stopped",
                Duration = 3,
            })
        end
    end,
})

MainTab:CreateSection("Actions")

MainTab:CreateButton({
    Name = "Clear Highlights",
    Callback = function()
        clearExternalHighlights()
        Rayfield:Notify({
            Title = "Cleared",
            Content = "All highlights removed",
            Duration = 2,
        })
    end,
})

MainTab:CreateButton({
    Name = "Force Re-Solve",
    Callback = function()
        if not isHooked then
            Rayfield:Notify({
                Title = "Not Hooked",
                Content = "Enable the solver first",
                Duration = 3,
            })
            return
        end
        if not lastActivePuzzle then
            Rayfield:Notify({
                Title = "No Puzzle",
                Content = "Start a Flow puzzle first",
                Duration = 3,
            })
            return
        end

        task.spawn(function()
            if currentMode == "Auto-Solve" then
                HintSystem:DrawSolutionOneByOne(lastActivePuzzle, 0.04)
            else
                HintSystem:HighlightSolutionExternally(lastActivePuzzle)
            end
        end)

        Rayfield:Notify({
            Title = "Re-Solving",
            Content = "Running solver again",
            Duration = 2,
        })
    end,
})

-- ============================================================
-- INIT
-- ============================================================
print("[Flow Solver] Rayfield UI loaded")
Rayfield:Notify({
    Title = "Flow Solver",
    Content = "Loaded successfully",
    Duration = 4,
})
