-- ============================================
-- PAINEL ADMIN
-- ============================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
if not LP then return end
local Mouse = LP:GetMouse()

-- ============ PARENT GUI ============
local function getGuiParent()
    local cg = game:GetService("CoreGui")
    local ok = pcall(function()
        local t = Instance.new("Folder"); t.Parent = cg; t:Destroy()
    end)
    if ok then return cg end
    return LP:WaitForChild("PlayerGui")
end

local parentGui = getGuiParent()
pcall(function()
    local old = parentGui:FindFirstChild("AdminPanelGui")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanelGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = parentGui

-- ============ STATES ============
local speedEnabled, speedValue = false, 16
local savedSpeed = nil
local jumpEnabled, jumpValue = false, 50
local savedJump = nil
local infJumpEnabled = false
local noclipEnabled, noclipSaved = false, {}
local loopTPEnabled, loopTPTarget = false, ""
local espEnabled, espData = false, {}
local xrayEnabled, xraySaved = false, {}
local gravityEnabled = false
local GRAVITY_FACTOR = 0.15
local gravitySaved = nil
local spectateEnabled, spectateTarget = false, ""
local savedCameraSubject, savedCameraType = nil, nil

-- ============ UTILITIES ============
local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local lname = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower() == lname or p.DisplayName:lower() == lname) then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():sub(1, #lname) == lname or p.DisplayName:lower():sub(1, #lname) == lname) then
            return p
        end
    end
    return nil
end

local function tpToPlayer(target)
    if not target or not target.Character or not LP.Character then return end
    local thrp = target.Character:FindFirstChild("HumanoidRootPart")
    local lhrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if thrp and lhrp then
        lhrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
    end
end

local function isCharacterPart(part)
    local cur = part
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then return true end
        cur = cur.Parent
    end
    return false
end

local function restoreCamera()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local subject = savedCameraSubject
    if not subject or not subject.Parent then
        subject = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    end
    camera.CameraSubject = subject
    camera.CameraType = savedCameraType or Enum.CameraType.Custom
    savedCameraSubject = nil
    savedCameraType = nil
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ============ ESP ============
local function createESPForPlayer(player)
    if player == LP or espData[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AP_ESP"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 250, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = hrp

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = player.Name
    label.Parent = billboard

    local teamColor = Color3.fromRGB(255, 255, 255)
    if player.Team then teamColor = player.Team.TeamColor.Color end

    local highlight = Instance.new("Highlight")
    highlight.Name = "AP_ESP_HL"
    highlight.Adornee = char
    highlight.FillColor = teamColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = teamColor
    highlight.OutlineTransparency = 0
    highlight.Parent = char

    espData[player] = { billboard = billboard, highlight = highlight, label = label }
end

local function destroyESPForPlayer(player)
    local d = espData[player]
    if d then
        if d.billboard then d.billboard:Destroy() end
        if d.highlight then d.highlight:Destroy() end
        espData[player] = nil
    end
end

-- ============ ICON ============
local Icon = Instance.new("TextButton")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(0, 50, 0, 200)
Icon.BackgroundColor3 = Color3.new(0, 0, 0)
Icon.Text = "AP"
Icon.TextColor3 = Color3.new(1, 1, 1)
Icon.TextSize = 22
Icon.Font = Enum.Font.GothamBold
Icon.BorderSizePixel = 0
Icon.AutoButtonColor = false
Icon.Parent = gui
Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 8)
local iconStroke = Instance.new("UIStroke", Icon)
iconStroke.Color = Color3.fromRGB(80, 80, 80)
iconStroke.Thickness = 1
makeDraggable(Icon, Icon)

-- ============ MENU ============
local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.new(0, 550, 0, 350)
Menu.Position = UDim2.new(0.5, -275, 0.5, -175)
Menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Menu.BorderSizePixel = 0
Menu.Visible = false
Menu.Parent = gui
Instance.new("UICorner", Menu).CornerRadius = UDim.new(0, 10)
local menuStroke = Instance.new("UIStroke", Menu)
menuStroke.Color = Color3.fromRGB(70, 70, 70)
menuStroke.Thickness = 1

-- icon click vs drag
local iconDown = nil
Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        iconDown = input.Position
    end
end)
Icon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if iconDown then
            local d = input.Position - iconDown
            if math.abs(d.X) < 5 and math.abs(d.Y) < 5 then
                Menu.Visible = not Menu.Visible
            end
            iconDown = nil
        end
    end
end)

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Menu
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local TitleBarCover = Instance.new("Frame")
TitleBarCover.Size = UDim2.new(1, 0, 0, 10)
TitleBarCover.Position = UDim2.new(0, 0, 1, -10)
TitleBarCover.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBarCover.BorderSizePixel = 0
TitleBarCover.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PAINEL ADMIN"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -33, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Menu.Visible = false end)
makeDraggable(Menu, TitleBar)

-- Panels
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 130, 1, -50)
LeftPanel.Position = UDim2.new(0, 10, 0, 45)
LeftPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = Menu
Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 8)
local leftList = Instance.new("UIListLayout")
leftList.Padding = UDim.new(0, 5)
leftList.SortOrder = Enum.SortOrder.LayoutOrder
leftList.Parent = LeftPanel
local leftPad = Instance.new("UIPadding")
leftPad.PaddingTop = UDim.new(0, 6)
leftPad.PaddingLeft = UDim.new(0, 6)
leftPad.PaddingRight = UDim.new(0, 6)
leftPad.Parent = LeftPanel

local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0, 395, 1, -50)
RightPanel.Position = UDim2.new(0, 148, 0, 45)
RightPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = Menu
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)

local RightScroll = Instance.new("ScrollingFrame")
RightScroll.Size = UDim2.new(1, -10, 1, -10)
RightScroll.Position = UDim2.new(0, 5, 0, 5)
RightScroll.BackgroundTransparency = 1
RightScroll.BorderSizePixel = 0
RightScroll.ScrollBarThickness = 4
RightScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
RightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
RightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
RightScroll.Parent = RightPanel
local rightList = Instance.new("UIListLayout")
rightList.Padding = UDim.new(0, 6)
rightList.SortOrder = Enum.SortOrder.LayoutOrder
rightList.Parent = RightScroll

-- ============ UI HELPERS ============
local function createToggle(parent, labelText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -75, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 24)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if callback then callback(state) end
    end)
    return row
end

local function createInputNumToggle(parent, labelText, defaultVal, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 80, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Text = tostring(defaultVal)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.ClearTextOnFocus = true
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 24)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    local value = tonumber(defaultVal)

    tb.FocusLost:Connect(function()
        local n = tonumber(tb.Text)
        if n then
            value = n
            if callback then callback(state, value) end
        elseif value then
            tb.Text = tostring(value)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if not value then
            local n = tonumber(tb.Text)
            if n then value = n end
        end
        if callback then callback(state, value) end
    end)
    return row
end

local function createInputButton(parent, labelText, placeholder, btnText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 130, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 24)
    btn.Position = UDim2.new(1, -80, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    btn.Text = btnText
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function()
        if callback then callback(tb.Text) end
    end)
    return row
end

local function createInputTextToggle(parent, labelText, placeholder, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 130, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    tb.Font = Enum.Font.Gotham
    tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 24)
    btn.Position = UDim2.new(1, -80, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    tb.FocusLost:Connect(function()
        if callback then callback(state, tb.Text) end
    end)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if callback then callback(state, tb.Text) end
    end)
    return row
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- ============ BUILDERS ============
local function buildFisico(parent)
    createInputNumToggle(parent, "Velocidade", "16", function(state, value)
        speedEnabled = state
        if value then speedValue = value end
        if not state then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum and savedSpeed ~= nil then
                hum.WalkSpeed = savedSpeed
            end
            savedSpeed = nil
        end
    end)

    createInputNumToggle(parent, "Pulo", "50", function(state, value)
        jumpEnabled = state
        if value then jumpValue = value end
        if not state then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum and savedJump then
                hum.UseJumpPower = savedJump.useJumpPower
                hum.JumpPower   = savedJump.jumpPower
                hum.JumpHeight  = savedJump.jumpHeight
            end
            savedJump = nil
        end
    end)

    createToggle(parent, "Pulo Infinito", function(state)
        infJumpEnabled = state
    end)
end

local function buildMagico(parent)
    createInputButton(parent, "Teleporte", "Nome do jogador", "TP", function(name)
        local target = findPlayerByName(name)
        if target then tpToPlayer(target) end
    end)

    createInputTextToggle(parent, "Loop Teleporte", "Nome do jogador", function(state, name)
        loopTPEnabled = state
        loopTPTarget = name or ""
    end)

    createToggle(parent, "Atravessar Paredes", function(state)
        noclipEnabled = state
        if not state then
            for part, saved in pairs(noclipSaved) do
                if part and part.Parent then part.CanCollide = saved end
            end
            noclipSaved = {}
        end
    end)

    createButton(parent, "Pegar TP Tool", function()
        local bp = LP:FindFirstChildOfClass("Backpack")
        if not bp then return end
        local existing = bp:FindFirstChild("TP Tool")
        if existing then existing:Destroy() end

        local tool = Instance.new("Tool")
        tool.Name = "TP Tool"
        tool.RequiresHandle = false
        tool.CanBeDropped = false
        tool.Activated:Connect(function()
            local hit = Mouse.Hit
            if hit and LP.Character then
                LP.Character:MoveTo(hit.Position + Vector3.new(0, 3, 0))
            end
        end)
        tool.Parent = bp
    end)

    -- GRAVIDADE LUNAR (só toggle)
    createToggle(parent, "Gravidade Lunar", function(state)
        gravityEnabled = state
    end)
end

local function buildVisual(parent)
    createButton(parent, "Otimizar Jogo", function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                for _, c in ipairs(obj:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") or c:IsA("SurfaceAppearance") then
                        c:Destroy()
                    end
                end
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("Light") then
                obj.Enabled = false
            elseif obj:IsA("Atmosphere") then
                obj.Density = 0
            end
        end
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") then obj.Enabled = false end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e5
    end)

    createToggle(parent, "ESP Jogadores", function(state)
        espEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do createESPForPlayer(p) end
        else
            local list = {}
            for p in pairs(espData) do table.insert(list, p) end
            for _, p in ipairs(list) do destroyESPForPlayer(p) end
        end
    end)

    createToggle(parent, "Raio X", function(state)
        xrayEnabled = state
        if state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not isCharacterPart(obj) then
                    if xraySaved[obj] == nil then
                        xraySaved[obj] = { t = obj.Transparency, r = obj.Reflectance }
                    end
                    obj.Transparency = 0.75
                    obj.Reflectance = 0
                end
            end
        else
            for obj, s in pairs(xraySaved) do
                if obj and obj.Parent then
                    obj.Transparency = s.t
                    obj.Reflectance = s.r
                end
            end
            xraySaved = {}
        end
    end)

    createInputTextToggle(parent, "Espectador", "Nome do jogador", function(state, name)
        spectateEnabled = state
        spectateTarget = name or ""
        if state then
            local target = findPlayerByName(spectateTarget)
            if target and target.Character then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                local camera = Workspace.CurrentCamera
                if hum and camera then
                    if not savedCameraSubject then
                        savedCameraSubject = camera.CameraSubject
                        savedCameraType = camera.CameraType
                    end
                    camera.CameraSubject = hum
                    camera.CameraType = Enum.CameraType.Custom
                end
            end
        else
            restoreCamera()
        end
    end)
end

-- ============ CATEGORIES ============
local categories = {
    { name = "Físico", builder = buildFisico },
    { name = "Mágico", builder = buildMagico },
    { name = "Visual", builder = buildVisual },
}
local categoryBtns = {}

local function selectCategory(cat)
    for _, c in ipairs(RightScroll:GetChildren()) do
        if c:IsA("GuiObject") and not c:IsA("UIListLayout") then c:Destroy() end
    end
    for name, btn in pairs(categoryBtns) do
        if name == cat.name then
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.TextColor3 = Color3.new(1, 1, 1)
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    cat.builder(RightScroll)
end

for _, cat in ipairs(categories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = cat.name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = LeftPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() selectCategory(cat) end)
    categoryBtns[cat.name] = btn
end
selectCategory(categories[1])

-- ============ FEATURE LOOPS ============

-- Velocidade/Pulo salvam valor original e restauram
RS.Heartbeat:Connect(function()
    if not LP.Character then return end
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if speedEnabled then
        if savedSpeed == nil then savedSpeed = hum.WalkSpeed end
        hum.WalkSpeed = speedValue
    end

    if jumpEnabled then
        if savedJump == nil then
            savedJump = {
                useJumpPower = hum.UseJumpPower,
                jumpPower    = hum.JumpPower,
                jumpHeight   = hum.JumpHeight,
            }
        end
        if hum.UseJumpPower then
            hum.JumpPower = jumpValue
        else
            hum.JumpHeight = jumpValue
        end
    end
end)

-- Se o personagem respawnar, zera os valores salvos para recalcular
LP.CharacterAdded:Connect(function()
    savedSpeed = nil
    savedJump = nil
    noclipSaved = {}
    if gravitySaved then
        gravitySaved.useJumpPower = nil
        gravitySaved.jumpPower = nil
        gravitySaved.jumpHeight = nil
    end
end)

UIS.JumpRequest:Connect(function()
    if infJumpEnabled and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RS.Stepped:Connect(function()
    if noclipEnabled and LP.Character then
        for _, part in ipairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipSaved[part] == nil then noclipSaved[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
end)

RS.Heartbeat:Connect(function()
    if loopTPEnabled and loopTPTarget ~= "" then
        local target = findPlayerByName(loopTPTarget)
        if target then tpToPlayer(target) end
    end
end)

-- Atualiza o texto do ESP com nome/vida
RS.Heartbeat:Connect(function()
    if not espEnabled then return end
    for p, d in pairs(espData) do
        if p.Character and d.label then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                d.label.Text = string.format("%s [%d/%d]",
                    p.Name, math.floor(hum.Health), math.floor(hum.MaxHealth))
            end
        end
    end
end)

-- GRAVIDADE LUNAR: reduz gravidade e compensa o impulso
-- para manter a MESMA altura de pulo, só caindo mais devagar
RS.Heartbeat:Connect(function()
    if gravityEnabled then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if gravitySaved == nil then
                gravitySaved = { gravity = Workspace.Gravity }
            end
            if gravitySaved.useJumpPower == nil then
                gravitySaved.useJumpPower = hum.UseJumpPower
                gravitySaved.jumpPower = hum.JumpPower
                gravitySaved.jumpHeight = hum.JumpHeight
            end

            Workspace.Gravity = gravitySaved.gravity * GRAVITY_FACTOR

            if gravitySaved.useJumpPower then
                local basePower = jumpEnabled and jumpValue or gravitySaved.jumpPower
                hum.JumpPower = basePower * math.sqrt(GRAVITY_FACTOR)
            else
                local baseHeight = jumpEnabled and jumpValue or gravitySaved.jumpHeight
                hum.JumpHeight = baseHeight
            end
        end
    elseif gravitySaved ~= nil then
        Workspace.Gravity = gravitySaved.gravity
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and gravitySaved.useJumpPower ~= nil then
            hum.UseJumpPower = gravitySaved.useJumpPower
            hum.JumpPower = gravitySaved.jumpPower
            hum.JumpHeight = gravitySaved.jumpHeight
        end
        gravitySaved = nil
    end
end)

-- Espectador: mantém a câmera apontada pro alvo (sobrevive a respawn)
RS.Heartbeat:Connect(function()
    if not spectateEnabled or spectateTarget == "" then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local target = findPlayerByName(spectateTarget)
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum and camera.CameraSubject ~= hum then
            camera.CameraSubject = hum
        end
    end
end)

-- ESP atualiza a cada 1 segundo
task.spawn(function()
    while true do
        task.wait(1)
        if espEnabled then
            for p, d in pairs(espData) do
                local char = p and p.Parent and p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local billboardAlive = d.billboard and d.billboard.Parent
                if not hrp or not billboardAlive then
                    if d.billboard then d.billboard:Destroy() end
                    if d.highlight then d.highlight:Destroy() end
                    espData[p] = nil
                end
            end

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and not espData[p] then
                    createESPForPlayer(p)
                end
            end
        end
    end
end)

-- Limpeza imediata quando o jogador sai
Players.PlayerRemoving:Connect(function(p)
    destroyESPForPlayer(p)
    if spectateEnabled and spectateTarget ~= "" then
        local match = (p.Name:lower() == spectateTarget:lower()
                    or p.DisplayName:lower() == spectateTarget:lower())
        if match then
            spectateEnabled = false
            spectateTarget = ""
            restoreCamera()
        end
    end
end)