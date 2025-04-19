--// SERVICES & SETUP
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local players = game:GetService("Players")
local cam = workspace.CurrentCamera
local lp = players.LocalPlayer
local mouse = lp:GetMouse()

--// GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "CleanESP_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 360)
frame.Position = UDim2.new(0.5, -160, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

--// Tab Buttons
local tabs = {}
local currentTab = "Visuals"

local function makeTab(name, xPos)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 100, 0, 30)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabs[name] = btn
    return btn
end

makeTab("Visuals", 10).MouseButton1Click:Connect(function() currentTab = "Visuals" end)
makeTab("Aim", 110).MouseButton1Click:Connect(function() currentTab = "Aim" end)

--// Helpers
local y = 60
local elements = {}

local function nextPos()
    y += 40
    return UDim2.new(0, 20, 0, y - 40)
end

local function makeButton(name, text, tab)
    local btn = Instance.new("TextButton", frame)
    btn.Name = name
    btn.Position = nextPos()
    btn.Size = UDim2.new(0, 280, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Visible = (tab == currentTab)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(elements, {obj = btn, tab = tab})
    return btn
end

local function makeTextbox(name, placeholder, tab)
    local tb = Instance.new("TextBox", frame)
    tb.Name = name
    tb.Position = nextPos()
    tb.Size = UDim2.new(0, 280, 0, 30)
    tb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.PlaceholderText = placeholder
    tb.Text = ""
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 14
    tb.BorderSizePixel = 0
    tb.Visible = (tab == currentTab)
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
    table.insert(elements, {obj = tb, tab = tab})
    return tb
end

--// TAB SWITCHER
rs.RenderStepped:Connect(function()
    for _, e in ipairs(elements) do
        e.obj.Visible = (e.tab == currentTab)
    end
end)

--// UI Elements
local highlightBtn = makeButton("HighlightBtn", "Highlight Players (Off)", "Visuals")
local colorBox = makeTextbox("ColorBox", "Highlight Color (e.g. 255,0,0)", "Visuals")
local espBtn = makeButton("ESPBtn", "ESP Boxes (Off)", "Visuals")
local flyBtn = makeButton("FlyBtn", "Toggle Fly (Off)", "Visuals")
local skeletonBtn = makeButton("SkeletonBtn", "Skeleton ESP (Off)", "Visuals") -- NEW

y = 60
local aimlockToggle = makeButton("AimToggle", "Toggle Aimlock (Off)", "Aim")
local holdKeyBtn = makeButton("HoldKeyBtn", "Set Hold Key", "Aim")
local aimPartBox = makeTextbox("AimPart", "Target Part: Head / Torso / HRP", "Aim")
local fovBox = makeTextbox("FOVBox", "FOV Radius", "Aim")
local modeToggle = makeButton("ModeToggle", "Mode: Cam Lock", "Aim")

--// Variables
local espEnabled = false
local aimEnabled = false
local highlightEnabled = false
local holdKey = Enum.KeyCode.Q
local holdDown = false
local aimPart = "Head"
local aimMode = "Cam"
local fovRadius = 100
local highlightColor = Color3.new(1, 0, 0)

local flyEnabled = false
local flySpeed = 3
local flyVelocity = Vector3.zero
local direction = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}

local skeletonEnabled = false
local skeletonLines = {}

--// Highlight
local function updateHighlights()
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hl = plr.Character:FindFirstChild("ESP_HIGHLIGHT")
            if highlightEnabled then
                if not hl then
                    local newHl = Instance.new("Highlight", plr.Character)
                    newHl.Name = "ESP_HIGHLIGHT"
                    newHl.FillColor = highlightColor
                    newHl.FillTransparency = 0.5
                    newHl.OutlineColor = Color3.new(1, 1, 1)
                    newHl.OutlineTransparency = 0
                    newHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                else
                    hl.Enabled = true
                end
            else
                if hl then hl.Enabled = false end
            end
        end
    end
end

players.PlayerAdded:Connect(function() task.wait(2) updateHighlights() end)
rs.RenderStepped:Connect(updateHighlights)

--// ESP
local espBoxes = {}

local function updateESP()
    for _, box in pairs(espBoxes) do box:Remove() end
    espBoxes = {}

    if not espEnabled then return end

    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local box = Drawing.new("Square")
                box.Size = Vector2.new(50, 75)
                box.Position = Vector2.new(pos.X - 25, pos.Y - 75)
                box.Thickness = 1
                box.Color = Color3.fromRGB(255, 255, 255)
                box.Visible = true
                table.insert(espBoxes, box)
            end
        end
    end
end

--// Skeleton ESP
local function drawLine(p1, p2)
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = Color3.new(1, 1, 1)
    line.From = p1
    line.To = p2
    line.Visible = true
    return line
end

local function updateSkeleton()
    for _, group in pairs(skeletonLines) do
        for _, line in pairs(group) do
            line:Remove()
        end
    end
    skeletonLines = {}

    if not skeletonEnabled then return end

    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local char = plr.Character
            local parts = {
                Head = char:FindFirstChild("Head"),
                Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
                HRP = char:FindFirstChild("HumanoidRootPart"),
                LeftArm = char:FindFirstChild("LeftUpperArm"),
                RightArm = char:FindFirstChild("RightUpperArm"),
                LeftLeg = char:FindFirstChild("LeftUpperLeg"),
                RightLeg = char:FindFirstChild("RightUpperLeg")
            }

            local lines = {}

            local function drawBone(a, b)
                if parts[a] and parts[b] then
                    local aPos, aOnScreen = cam:WorldToViewportPoint(parts[a].Position)
                    local bPos, bOnScreen = cam:WorldToViewportPoint(parts[b].Position)
                    if aOnScreen and bOnScreen then
                        table.insert(lines, drawLine(Vector2.new(aPos.X, aPos.Y), Vector2.new(bPos.X, bPos.Y)))
                    end
                end
            end

            drawBone("Head", "Torso")
            drawBone("Torso", "LeftArm")
            drawBone("Torso", "RightArm")
            drawBone("Torso", "LeftLeg")
            drawBone("Torso", "RightLeg")

            table.insert(skeletonLines, lines)
        end
    end
end

--// FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Filled = false
fovCircle.Thickness = 1
fovCircle.Transparency = 1
fovCircle.NumSides = 64
fovCircle.Visible = true

rs.RenderStepped:Connect(function()
    local mPos = uis:GetMouseLocation()
    fovCircle.Position = Vector2.new(mPos.X, mPos.Y)
    fovCircle.Radius = fovRadius
end)

--// Closest Target + Aimbot
local function getClosest()
    local closest, dist = nil, fovRadius
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= lp and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = plr.Character:FindFirstChild(aimPart) or plr.Character:FindFirstChild("Head")
            if part then
                local screenPoint, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local diff = (Vector2.new(screenPoint.X, screenPoint.Y) - uis:GetMouseLocation()).Magnitude
                    if diff < dist then
                        closest = part
                        dist = diff
                    end
                end
            end
        end
    end
    return closest
end

--// Aimbot + Wallbang Simulation
local function shootThroughWalls(targetPosition)
    local rayOrigin = cam.CFrame.Position
    local rayDirection = (targetPosition - rayOrigin).unit * 999
    local hitPart, hitPos = workspace:Raycast(rayOrigin, rayDirection)
    if hitPart and hitPart.Parent:FindFirstChild("Humanoid") then
        hitPart.Parent.Humanoid:TakeDamage(25)
    end
end

rs.RenderStepped:Connect(function()
    updateESP()
    updateSkeleton()
end)

rs.RenderStepped:Connect(function()
    if aimEnabled and holdDown then
        local target = getClosest()
        if target then
            local targetPos = target.Position
            if aimMode == "Cam" then
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), 0.1)
                shootThroughWalls(targetPos)
            elseif aimMode == "Mouse" then
                local screenPos = cam:WorldToViewportPoint(targetPos)
                local mousePos = uis:GetMouseLocation()
                local delta = Vector2.new(screenPos.X, screenPos.Y) - mousePos
                mousemoverel(delta.X * 0.2, delta.Y * 0.2)
                shootThroughWalls(targetPos)
            end
        end
    end
end)

--// Fly Movement
rs.RenderStepped:Connect(function(dt)
    if flyEnabled and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local root = lp.Character.HumanoidRootPart
        local camCF = cam.CFrame
        local moveDir = Vector3.zero

        if direction.F == 1 then moveDir += camCF.LookVector end
        if direction.B == 1 then moveDir -= camCF.LookVector end
        if direction.L == 1 then moveDir -= camCF.RightVector end
        if direction.R == 1 then moveDir += camCF.RightVector end
        if direction.U == 1 then moveDir += camCF.UpVector end
        if direction.D == 1 then moveDir -= camCF.UpVector end

        flyVelocity = moveDir.Magnitude > 0 and moveDir.Unit * flySpeed or Vector3.zero
        root.Velocity = flyVelocity
        root.AssemblyLinearVelocity = flyVelocity
    end
end)

--// Input
uis.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end
    if input.KeyCode == holdKey or input.UserInputType == holdKey then
        holdDown = true
    end
    if input.KeyCode == Enum.KeyCode.W then direction.F = 1 end
    if input.KeyCode == Enum.KeyCode.S then direction.B = 1 end
    if input.KeyCode == Enum.KeyCode.A then direction.L = 1 end
    if input.KeyCode == Enum.KeyCode.D then direction.R = 1 end
    if input.KeyCode == Enum.KeyCode.Space then direction.U = 1 end
    if input.KeyCode == Enum.KeyCode.LeftShift then direction.D = 1 end
end)

uis.InputEnded:Connect(function(input)
    if input.KeyCode == holdKey or input.UserInputType == holdKey then
        holdDown = false
    end
    if input.KeyCode == Enum.KeyCode.W then direction.F = 0 end
    if input.KeyCode == Enum.KeyCode.S then direction.B = 0 end
    if input.KeyCode == Enum.KeyCode.A then direction.L = 0 end
    if input.KeyCode == Enum.KeyCode.D then direction.R = 0 end
    if input.KeyCode == Enum.KeyCode.Space then direction.U = 0 end
    if input.KeyCode == Enum.KeyCode.LeftShift then direction.D = 0 end
end)

--// Button Actions
highlightBtn.MouseButton1Click:Connect(function()
    highlightEnabled = not highlightEnabled
    highlightBtn.Text = highlightEnabled and "Highlight Players (On)" or "Highlight Players (Off)"
    updateHighlights()
end)

colorBox.FocusLost:Connect(function()
    local txt = colorBox.Text
    local r, g, b = txt:match("(%d+),%s*(%d+),%s*(%d+)")
    if r and g and b then
        highlightColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
        updateHighlights()
    end
end)

espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP Boxes (On)" or "ESP Boxes (Off)"
end)

skeletonBtn.MouseButton1Click:Connect(function()
    skeletonEnabled = not skeletonEnabled
    skeletonBtn.Text = skeletonEnabled and "Skeleton ESP (On)" or "Skeleton ESP (Off)"
end)

aimlockToggle.MouseButton1Click:Connect(function()
    aimEnabled = not aimEnabled
    aimlockToggle.Text = aimEnabled and "Toggle Aimlock (On)" or "Toggle Aimlock (Off)"
end)

holdKeyBtn.MouseButton1Click:Connect(function()
    holdKeyBtn.Text = "Press any key/mouse..."
    local conn
    conn = uis.InputBegan:Connect(function(input)
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            holdKey = input.KeyCode
            holdKeyBtn.Text = "Hold Key: " .. holdKey.Name
            conn:Disconnect()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            holdKey = input.UserInputType
            local name = (holdKey == Enum.UserInputType.MouseButton1) and "Mouse1" or "Mouse2"
            holdKeyBtn.Text = "Hold Key: " .. name
            conn:Disconnect()
        end
    end)
end)

aimPartBox.FocusLost:Connect(function()
    local text = aimPartBox.Text:lower()
    if text:find("head") then
        aimPart = "Head"
    elseif text:find("torso") then
        aimPart = "UpperTorso"
    elseif text:find("hrp") then
        aimPart = "HumanoidRootPart"
    end
end)

fovBox.FocusLost:Connect(function()
    local num = tonumber(fovBox.Text)
    if num then
        fovRadius = num
    end
end)

modeToggle.MouseButton1Click:Connect(function()
    aimMode = (aimMode == "Cam") and "Mouse" or "Cam"
    modeToggle.Text = "Mode: " .. (aimMode == "Cam" and "Cam Lock" or "Mouse Lock")
end)

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = flyEnabled and "Toggle Fly (On)" or "Toggle Fly (Off)"
end)
