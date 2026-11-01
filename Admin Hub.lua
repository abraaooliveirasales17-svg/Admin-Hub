--[[
    Painel Admin - Roblox Executor
    Desenvolvido em Luau
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remove GUI anterior se existir
if (gethui and gethui():FindFirstChild("PainelAdminGui")) then
    gethui().PainelAdminGui:Destroy()
elseif CoreGui:FindFirstChild("PainelAdminGui") then
    CoreGui.PainelAdminGui:Destroy()
end

-- Configurações e Variáveis de Estado
local Config = {
    IconColor = Color3.fromRGB(25, 25, 25),
    MenuColor = Color3.fromRGB(35, 35, 35),
    IconRGB = false,
    MenuRGB = false,
    Language = "PT", -- PT, EN, ES
    Speed = 16,
    SpeedEnabled = false,
    Jump = 50,
    JumpEnabled = false,
    InfJump = false,
    Noclip = false,
    ESP = false,
    Xray = false,
    TargetTeleport = "",
    LoopTeleportTarget = "",
    LoopTPActive = false
}

-- Dicionário de Idiomas
local Translations = {
    PT = { Fisi = "Físico", Magi = "Mágico", Visu = "Visual", Stat = "Status", Conf = "Configurações" },
    EN = { Fisi = "Physical", Magi = "Magical", Visu = "Visual", Stat = "Status", Conf = "Settings" },
    ES = { Fisi = "Físico", Magi = "Mágico", Visu = "Visual", Stat = "Estado", Conf = "Configuración" }
}

-- Criar ScreenGui principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PainelAdminGui"
ScreenGui.Parent = (gethui and gethui()) or CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--------------------------------------------------------------------------------
-- 1. ÍCONE FLUTUANTE ARRASTÁVEL (AP)
--------------------------------------------------------------------------------
local IconBtn = Instance.new("TextButton")
IconBtn.Name = "IconeAdmin"
IconBtn.Size = UDim2.new(0, 50, 0, 50)
IconBtn.Position = UDim2.new(0, 50, 0, 200)
IconBtn.BackgroundColor3 = Config.IconColor
IconBtn.Text = "AP"
IconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IconBtn.TextSize = 18
IconBtn.Font = Enum.Font.GothamBold
IconBtn.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = IconBtn

local IconStroke = Instance.new("UIStroke")
IconStroke.Thickness = 2
IconStroke.Color = Color3.fromRGB(255, 255, 255)
IconStroke.Parent = IconBtn

-- Sistema de Arrastar o Ícone
local dragging, dragInput, dragStart, startPos
IconBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = IconBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        IconBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--------------------------------------------------------------------------------
-- 2. MENU PRINCIPAL (DIVIDIDO EM DUAS PARTES)
--------------------------------------------------------------------------------
local MainWindow = Instance.new("Frame")
MainWindow.Name = "JanelaPrincipal"
MainWindow.Size = UDim2.new(0, 550, 0, 350)
MainWindow.Position = UDim2.new(0.5, -275, 0.5, -175)
MainWindow.BackgroundColor3 = Config.MenuColor
MainWindow.Visible = false
MainWindow.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim2.new(0, 8)
MainCorner.Parent = MainWindow

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(80, 80, 80)
MainStroke.Parent = MainWindow

-- Abrir/Fechar Menu ao clicar no Ícone
IconBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
end)

-- Arrastar Menu Principal
local menuDragging, menuDragInput, menuDragStart, menuStartPos
MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = true
        menuDragStart = input.Position
        menuStartPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                menuDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        menuDragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if menuDragging and menuDragInput then
        local delta = menuDragInput.Position - menuDragStart
        MainWindow.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
    end
end)

-- Lado Esquerdo: Categorias
local LeftPanel = Instance.new("ScrollingFrame")
LeftPanel.Size = UDim2.new(0, 150, 1, -20)
LeftPanel.Position = UDim2.new(0, 10, 0, 10)
LeftPanel.BackgroundTransparency = 1
LeftPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftPanel.ScrollBarThickness = 4
LeftPanel.Parent = MainWindow

local LeftLayout = Instance.new("UIListLayout")
LeftLayout.Padding = UDim.new(0, 8)
LeftLayout.Parent = LeftPanel

-- Lado Direito: Opções da Categoria Selecionada
local RightPanel = Instance.new("ScrollingFrame")
RightPanel.Size = UDim2.new(1, -170, 1, -20)
RightPanel.Position = UDim2.new(0, 165, 0, 10)
RightPanel.BackgroundTransparency = 1
RightPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
RightPanel.ScrollBarThickness = 4
RightPanel.Parent = MainWindow

local RightLayout = Instance.new("UIListLayout")
RightLayout.Padding = UDim.new(0, 10)
RightLayout.Parent = RightPanel

--------------------------------------------------------------------------------
-- SISTEMA DE ABAS (CATEGORIAS)
--------------------------------------------------------------------------------
local Containers = {}
local activeContainer = nil

local function CriarCategoria(nomeKey, nomeExibicao)
    local CatBtn = Instance.new("TextButton")
    CatBtn.Size = UDim2.new(1, 0, 0, 35)
    CatBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    CatBtn.Text = nomeExibicao
    CatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CatBtn.TextSize = 14
    CatBtn.Font = Enum.Font.GothamSemibold
    CatBtn.Parent = LeftPanel

    local CatCorner = Instance.new("UICorner")
    CatCorner.CornerRadius = UDim2.new(0, 6)
    CatCorner.Parent = CatBtn

    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Visible = false
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.ScrollBarThickness = 4
    Container.Parent = RightPanel

    local CLayout = Instance.new("UIListLayout")
    CLayout.Padding = UDim.new(0, 8)
    CLayout.Parent = Container

    CLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Container.CanvasSize = UDim2.new(0, 0, 0, CLayout.AbsoluteContentSize.Y + 10)
    end)

    Containers[nomeKey] = Container

    CatBtn.MouseButton1Click:Connect(function()
        for _, c in pairs(Containers) do c.Visible = false end
        Container.Visible = true
        activeContainer = Container
    end)

    if not activeContainer then
        Container.Visible = true
        activeContainer = Container
    end

    return Container
end

LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    LeftPanel.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y + 10)
end)

local CatFisico = CriarCategoria("Fisico", "Físico")
local CatMagico = CriarCategoria("Mágico", "Mágico")
local CatVisual = CriarCategoria("Visual", "Visual")
local CatStatus = CriarCategoria("Status", "Status")
local CatConfig = CriarCategoria("Config", "Configurações")

-- Funções Auxiliares de Componentes visuais para as Opções
local function CriarTituloOpcao(parent, texto)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 25)
    lbl.BackgroundTransparency = 1
    lbl.Text = texto
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

--------------------------------------------------------------------------------
-- CATEGORIA: FÍSICO
--------------------------------------------------------------------------------
-- 1. Alterar velocidade
CriarTituloOpcao(CatFisico, "1. Alterar Velocidade")
local VelBox = Instance.new("TextBox")
VelBox.Size = UDim2.new(1, 0, 0, 30)
VelBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
VelBox.PlaceholderText = "Digite a velocidade (ex: 50)"
VelBox.Text = ""
VelBox.TextColor3 = Color3.fromRGB(255, 255, 255)
VelBox.TextSize = 13
VelBox.Font = Enum.Font.Gotham
VelBox.Parent = CatFisico
Instance.new("UICorner", VelBox).CornerRadius = UDim.new(0, 5)

local VelToggle = Instance.new("TextButton")
VelToggle.Size = UDim2.new(1, 0, 0, 30)
VelToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
VelToggle.Text = "Ativar Velocidade: Desativado"
VelToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
VelToggle.TextSize = 13
VelToggle.Font = Enum.Font.GothamBold
VelToggle.Parent = CatFisico
Instance.new("UICorner", VelToggle).CornerRadius = UDim.new(0, 5)

VelToggle.MouseButton1Click:Connect(function()
    Config.SpeedEnabled = not Config.SpeedEnabled
    Config.Speed = tonumber(VelBox.Text) or 16
    if Config.SpeedEnabled then
        VelToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        VelToggle.Text = "Ativar Velocidade: Ativado"
    else
        VelToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        VelToggle.Text = "Ativar Velocidade: Desativado"
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.SpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = Config.Speed
    end
end)

-- 2. Alterar pulo
CriarTituloOpcao(CatFisico, "2. Alterar Pulo")
local JumpBox = Instance.new("TextBox")
JumpBox.Size = UDim2.new(1, 0, 0, 30)
JumpBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
JumpBox.PlaceholderText = "Digite a altura do pulo (ex: 100)"
JumpBox.Text = ""
JumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBox.TextSize = 13
JumpBox.Font = Enum.Font.Gotham
JumpBox.Parent = CatFisico
Instance.new("UICorner", JumpBox).CornerRadius = UDim.new(0, 5)

local JumpToggle = Instance.new("TextButton")
JumpToggle.Size = UDim2.new(1, 0, 0, 30)
JumpToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
JumpToggle.Text = "Ativar Pulo: Desativado"
JumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpToggle.TextSize = 13
JumpToggle.Font = Enum.Font.GothamBold
JumpToggle.Parent = CatFisico
Instance.new("UICorner", JumpToggle).CornerRadius = UDim.new(0, 5)

JumpToggle.MouseButton1Click:Connect(function()
    Config.JumpEnabled = not Config.JumpEnabled
    Config.Jump = tonumber(JumpBox.Text) or 50
    if Config.JumpEnabled then
        JumpToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        JumpToggle.Text = "Ativar Pulo: Ativado"
    else
        JumpToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        JumpToggle.Text = "Ativar Pulo: Desativado"
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.JumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        hum.UseJumpPower = true
        hum.JumpPower = Config.Jump
    end
end)

-- 3. Pulo infinito
CriarTituloOpcao(CatFisico, "3. Pulo Infinito")
local InfJumpToggle = Instance.new("TextButton")
InfJumpToggle.Size = UDim2.new(1, 0, 0, 30)
InfJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
InfJumpToggle.Text = "Pulo Infinito: Desativado"
InfJumpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
InfJumpToggle.TextSize = 13
InfJumpToggle.Font = Enum.Font.GothamBold
InfJumpToggle.Parent = CatFisico
Instance.new("UICorner", InfJumpToggle).CornerRadius = UDim.new(0, 5)

InfJumpToggle.MouseButton1Click:Connect(function()
    Config.InfJump = not Config.InfJump
    if Config.InfJump then
        InfJumpToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        InfJumpToggle.Text = "Pulo Infinito: Ativado"
    else
        InfJumpToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        InfJumpToggle.Text = "Pulo Infinito: Desativado"
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidState.Jumping)
    end
end)

--------------------------------------------------------------------------------
-- CATEGORIA: MÁGICO
--------------------------------------------------------------------------------
-- 1. Teleporte
CriarTituloOpcao(CatMagico, "1. Teleporte para Jogador")
local TPBox = Instance.new("TextBox")
TPBox.Size = UDim2.new(1, 0, 0, 30)
TPBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
TPBox.PlaceholderText = "Nome do jogador..."
TPBox.Text = ""
TPBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TPBox.TextSize = 13
TPBox.Font = Enum.Font.Gotham
TPBox.Parent = CatMagico
Instance.new("UICorner", TPBox).CornerRadius = UDim.new(0, 5)

local TPBtn = Instance.new("TextButton")
TPBtn.Size = UDim2.new(1, 0, 0, 30)
TPBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
TPBtn.Text = "Teleportar Agora"
TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPBtn.TextSize = 13
TPBtn.Font = Enum.Font.GothamBold
TPBtn.Parent = CatMagico
Instance.new("UICorner", TPBtn).CornerRadius = UDim.new(0, 5)

TPBtn.MouseButton1Click:Connect(function()
    local targetName = TPBox.Text:lower()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (plr.Name:lower():sub(1, #targetName) == targetName or plr.DisplayName:lower():sub(1, #targetName) == targetName) then
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
            end
            break
        end
    end
end)

-- 2. Loop Teleporte
CriarTituloOpcao(CatMagico, "2. Loop Teleporte")
local LoopTPBox = Instance.new("TextBox")
LoopTPBox.Size = UDim2.new(1, 0, 0, 30)
LoopTPBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
LoopTPBox.PlaceholderText = "Nome do jogador para loop TP..."
LoopTPBox.Text = ""
LoopTPBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopTPBox.TextSize = 13
LoopTPBox.Font = Enum.Font.Gotham
LoopTPBox.Parent = CatMagico
Instance.new("UICorner", LoopTPBox).CornerRadius = UDim.new(0, 5)

local LoopTPToggle = Instance.new("TextButton")
LoopTPToggle.Size = UDim2.new(1, 0, 0, 30)
LoopTPToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
LoopTPToggle.Text = "Loop TP: Desativado"
LoopTPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopTPToggle.TextSize = 13
LoopTPToggle.Font = Enum.Font.GothamBold
LoopTPToggle.Parent = CatMagico
Instance.new("UICorner", LoopTPToggle).CornerRadius = UDim.new(0, 5)

LoopTPToggle.MouseButton1Click:Connect(function()
    Config.LoopTPActive = not Config.LoopTPActive
    Config.LoopTeleportTarget = LoopTPBox.Text
    if Config.LoopTPActive then
        LoopTPToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        LoopTPToggle.Text = "Loop TP: Ativado"
    else
        LoopTPToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        LoopTPToggle.Text = "Loop TP: Desativado"
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.LoopTPActive then
        local targetName = Config.LoopTeleportTarget:lower()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and (plr.Name:lower():sub(1, #targetName) == targetName or plr.DisplayName:lower():sub(1, #targetName) == targetName) then
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                end
                break
            end
        end
    end
end)

-- 3. Atravessar (Noclip)
CriarTituloOpcao(CatMagico, "3. Atravessar Paredes (Noclip)")
local NoclipToggle = Instance.new("TextButton")
NoclipToggle.Size = UDim2.new(1, 0, 0, 30)
NoclipToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
NoclipToggle.Text = "Atravessar: Desativado"
NoclipToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipToggle.TextSize = 13
NoclipToggle.Font = Enum.Font.GothamBold
NoclipToggle.Parent = CatMagico
Instance.new("UICorner", NoclipToggle).CornerRadius = UDim.new(0, 5)

NoclipToggle.MouseButton1Click:Connect(function()
    Config.Noclip = not Config.Noclip
    if Config.Noclip then
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        NoclipToggle.Text = "Atravessar: Ativado"
    else
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        NoclipToggle.Text = "Atravessar: Desativado"
    end
end)

RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- 4. TP Tool
CriarTituloOpcao(CatMagico, "4. Ferramenta de Teleporte (TP Tool)")
local TPToolBtn = Instance.new("TextButton")
TPToolBtn.Size = UDim2.new(1, 0, 0, 30)
TPToolBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
TPToolBtn.Text = "Pegar TP Tool"
TPToolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPToolBtn.TextSize = 13
TPToolBtn.Font = Enum.Font.GothamBold
TPToolBtn.Parent = CatMagico
Instance.new("UICorner", TPToolBtn).CornerRadius = UDim.new(0, 5)

TPToolBtn.MouseButton1Click:Connect(function()
    local tool = Instance.new("Tool")
    tool.Name = "Admin TP Tool"
    tool.RequiresHandle = false
    tool.Parent = LocalPlayer.Backpack

    tool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        if mouse and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end)
end)

--------------------------------------------------------------------------------
-- CATEGORIA: VISUAL
--------------------------------------------------------------------------------
-- 1. Otimizar
CriarTituloOpcao(CatVisual, "1. Otimizar Jogo (Boost FPS)")
local OptBtn = Instance.new("TextButton")
OptBtn.Size = UDim2.new(1, 0, 0, 30)
OptBtn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
OptBtn.Text = "Otimizar Jogo"
OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OptBtn.TextSize = 13
OptBtn.Font = Enum.Font.GothamBold
OptBtn.Parent = CatVisual
Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 5)

OptBtn.MouseButton1Click:Connect(function()
    Lighting.GlobalShadows = false
    Lighting.Brightness = 2
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
end)

-- 2. ESP
CriarTituloOpcao(CatVisual, "2. ESP (Jogadores)")
local ESPToggle = Instance.new("TextButton")
ESPToggle.Size = UDim2.new(1, 0, 0, 30)
ESPToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ESPToggle.Text = "ESP: Desativado"
ESPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPToggle.TextSize: 13
ESPToggle.Font = Enum.Font.GothamBold
ESPToggle.Parent = CatVisual
Instance.new("UICorner", ESPToggle).CornerRadius = UDim.new(0, 5)

ESPToggle.MouseButton1Click:Connect(function()
    Config.ESP = not Config.ESP
    if Config.ESP then
        ESPToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        ESPToggle.Text = "ESP: Ativado"
    else
        ESPToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        ESPToggle.Text = "ESP: Desativado"
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                if plr.Character:FindFirstChild("AdminESP_Highlight") then plr.Character.AdminESP_Highlight:Destroy() end
                if plr.Character:FindFirstChild("AdminESP_Tag") then plr.Character.AdminESP_Tag:Destroy() end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.ESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                local char = plr.Character
                -- Highlight
                if not char:FindFirstChild("AdminESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "AdminESP_Highlight"
                    hl.Adornee = char
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent = char
                end
                if plr.Team then
                    char.AdminESP_Highlight.FillColor = plr.Team.Color
                    char.AdminESP_Highlight.OutlineColor = plr.Team.Color
                else
                    char.AdminESP_Highlight.FillColor = Color3.fromRGB(255, 255, 255)
                    char.AdminESP_Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                end

                -- BillboardGui (Nome, Vida)
                if not char:FindFirstChild("AdminESP_Tag") then
                    local bg = Instance.new("BillboardGui")
                    bg.Name = "AdminESP_Tag"
                    bg.Size = UDim2.new(0, 150, 0, 50)
                    bg.StudsOffset = Vector3.new(0, 3, 0)
                    bg.AlwaysOnTop = true
                    bg.Parent = char

                    local txt = Instance.new("TextLabel")
                    txt.Name = "Info"
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                    txt.TextSize = 12
                    txt.Font = Enum.Font.GothamBold
                    txt.TextStrokeTransparency = 0
                    txt.Parent = bg
                end
                local hum = char.Humanoid
                char.AdminESP_Tag.Info.Text = plr.Name .. "\nVida: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
            end
        end
    end
end)

-- 3. Raio X
CriarTituloOpcao(CatVisual, "3. Raio X (Transparência do Mapa)")
local XrayToggle = Instance.new("TextButton")
XrayToggle.Size = UDim2.new(1, 0, 0, 30)
XrayToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
XrayToggle.Text = "Raio X: Desativado"
XrayToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
XrayToggle.TextSize = 13
XrayToggle.Font = Enum.Font.GothamBold
XrayToggle.Parent = CatVisual
Instance.new("UICorner", XrayToggle).CornerRadius = UDim.new(0, 5)

XrayToggle.MouseButton1Click:Connect(function()
    Config.Xray = not Config.Xray
    if Config.Xray then
        XrayToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        XrayToggle.Text = "Raio X: Ativado"
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
                local isPlayerOrNPC = false
                for _, p in pairs(Players:GetPlayers()) do
                    if v:IsDescendantOf(p.Character or workspace) then isPlayerOrNPC = true end
                end
                if not isPlayerOrNPC then
                    v.LocalTransparencyModifier = 0.7
                end
            end
        end
    else
        XrayToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        XrayToggle.Text = "Raio X: Desativado"
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = 0
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- CATEGORIA: STATUS
--------------------------------------------------------------------------------
CriarTituloOpcao(CatStatus, "Informações do Servidor e Jogo")

local StatusGameName = Instance.new("TextLabel")
StatusGameName.Size = UDim2.new(1, 0, 0, 25)
StatusGameName.BackgroundTransparency = 1
StatusGameName.TextColor3 = Color3.fromRGB(220, 220, 220)
StatusGameName.TextSize = 12
StatusGameName.Font = Enum.Font.Gotham
StatusGameName.TextXAlignment = Enum.TextXAlignment.Left
StatusGameName.Parent = CatStatus

local StatusPlayers = Instance.new("TextLabel")
StatusPlayers.Size = UDim2.new(1, 0, 0, 25)
StatusPlayers.BackgroundTransparency = 1
StatusPlayers.TextColor3 = Color3.fromRGB(220, 220, 220)
StatusPlayers.TextSize = 12
StatusPlayers.Font = Enum.Font.Gotham
StatusPlayers.TextXAlignment = Enum.TextXAlignment.Left
StatusPlayers.Parent = CatStatus

local StatusMoon = Instance.new("TextLabel")
StatusMoon.Size = UDim2.new(1, 0, 0, 25)
StatusMoon.BackgroundTransparency = 1
StatusMoon.TextColor3 = Color3.fromRGB(220, 220, 220)
StatusMoon.TextSize = 12
StatusMoon.Font = Enum.Font.Gotham
StatusMoon.TextXAlignment = Enum.TextXAlignment.Left
StatusMoon.Parent = CatStatus

local StatusServer = Instance.new("TextLabel")
StatusServer.Size = UDim2.new(1, 0, 0, 25)
StatusServer.BackgroundTransparency = 1
StatusServer.TextColor3 = Color3.fromRGB(220, 220, 220)
StatusServer.TextSize = 12
StatusServer.Font = Enum.Font.Gotham
StatusServer.TextXAlignment = Enum.TextXAlignment.Left
StatusServer.Parent = CatStatus

-- Atualizar Status em tempo real
task.spawn(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    local gameName = success and info.Name or game.Name

    while true do
        StatusGameName.Text = "🎮 Jogo: " .. gameName
        StatusPlayers.Text = "👥 Players: " .. #Players:GetPlayers() .. " / " .. Players.MaxPlayers
        
        -- Cálculo estimado da fase da lua baseado no tempo do Lighting ou ClockTime
        local timeOfDay = Lighting.ClockTime
        local moonPhase = "Lua Crescente"
        if timeOfDay >= 0 and timeOfDay < 6 then
            moonPhase = "Lua Cheia 🌕"
        elseif timeOfDay >= 6 and timeOfDay < 12 then
            moonPhase = "Quarto Menguante 🌗"
        elseif timeOfDay >= 12 and timeOfDay < 18 then
            moonPhase = "Lua Nova 🌑"
        else
            moonPhase = "Quarto Crescente 🌓"
        end
        StatusMoon.Text = "🌙 Fase da Lua: " .. moonPhase
        StatusServer.Text = "🌐 Servidor ID: " .. game.JobId:sub(1, 10) .. "..."
        
        task.wait(1)
    end
end)

--------------------------------------------------------------------------------
-- CATEGORIA: CONFIGURAÇÕES
--------------------------------------------------------------------------------
-- 1. Cor do ícone & 2. Cor do menu (Presets rápidos / Paleta)
CriarTituloOpcao(CatConfig, "1 & 2. Cores do Ícone e Menu")

local function CriarBotaoCor(texto, corIcone, corMenu)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = corMenu
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = CatConfig
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        IconBtn.BackgroundColor3 = corIcone
        MainWindow.BackgroundColor3 = corMenu
        Config.IconColor = corIcone
        Config.MenuColor = corMenu
    end)
end

CriarBotaoCor("Tema: Escuro Padrão", Color3.fromRGB(25, 25, 25), Color3.fromRGB(35, 35, 35))
CriarBotaoCor("Tema: Azul Neon", Color3.fromRGB(0, 120, 255), Color3.fromRGB(20, 30, 50))
CriarBotaoCor("Tema: Roxo Místico", Color3.fromRGB(120, 40, 200), Color3.fromRGB(30, 20, 45))

-- 3. Menu RGB & 4. Ícone RGB
CriarTituloOpcao(CatConfig, "3 & 4. Contornos RGB")

local MenuRGBToggle = Instance.new("TextButton")
MenuRGBToggle.Size = UDim2.new(1, 0, 0, 30)
MenuRGBToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
MenuRGBToggle.Text = "Menu RGB: Desativado"
MenuRGBToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuRGBToggle.TextSize = 13
MenuRGBToggle.Font = Enum.Font.GothamBold
MenuRGBToggle.Parent = CatConfig
Instance.new("UICorner", MenuRGBToggle).CornerRadius = UDim.new(0, 5)

MenuRGBToggle.MouseButton1Click:Connect(function()
    Config.MenuRGB = not Config.MenuRGB
    if Config.MenuRGB then
        MenuRGBToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        MenuRGBToggle.Text = "Menu RGB: Ativado"
    else
        MenuRGBToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        MenuRGBToggle.Text = "Menu RGB: Desativado"
        MainStroke.Color = Color3.fromRGB(80, 80, 80)
    end
end)

local IconRGBToggle = Instance.new("TextButton")
IconRGBToggle.Size = UDim2.new(1, 0, 0, 30)
IconRGBToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
IconRGBToggle.Text = "Ícone RGB: Desativado"
IconRGBToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
IconRGBToggle.TextSize = 13
IconRGBToggle.Font = Enum.Font.GothamBold
IconRGBToggle.Parent = CatConfig
Instance.new("UICorner", IconRGBToggle).CornerRadius = UDim.new(0, 5)

IconRGBToggle.MouseButton1Click:Connect(function()
    Config.IconRGB = not Config.IconRGB
    if Config.IconRGB then
        IconRGBToggle.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
        IconRGBToggle.Text = "Ícone RGB: Ativado"
    else
        IconRGBToggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        IconRGBToggle.Text = "Ícone RGB: Desativado"
        IconStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end)

RunService.RenderStepped:Connect(function()
    local hue = tick() % 5 / 5
    local rgbColor = Color3.fromHSV(hue, 1, 1)
    if Config.MenuRGB then
        MainStroke.Color = rgbColor
    end
    if Config.IconRGB then
        IconStroke.Color = rgbColor
    end
end)

-- 5. Idioma
CriarTituloOpcao(CatConfig, "5. Idioma do Menu")
local LangBtn = Instance.new("TextButton")
LangBtn.Size = UDim2.new(1, 0, 0, 30)
LangBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 150)
LangBtn.Text = "Idioma Atual: Português (PT)"
LangBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LangBtn.TextSize = 13
LangBtn.Font = Enum.Font.GothamBold
LangBtn.Parent = CatConfig
Instance.new("UICorner", LangBtn).CornerRadius = UDim.new(0, 5)

LangBtn.MouseButton1Click:Connect(function()
    if Config.Language == "PT" then
        Config.Language = "EN"
        LangBtn.Text = "Current Language: English (EN)"
    elseif Config.Language == "EN" then
        Config.Language = "ES"
        LangBtn.Text = "Idioma Actual: Español (ES)"
    else
        Config.Language = "PT"
        LangBtn.Text = "Idioma Atual: Português (PT)"
    end
end)

-- 6. Salvar Configurações
CriarTituloOpcao(CatConfig, "6. Salvar Progresso/Configurações")
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(1, 0, 0, 30)
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
SaveBtn.Text = "Salvar Configurações"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize = 13
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = CatConfig
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 5)

SaveBtn.MouseButton1Click:Connect(function()
    local success = pcall(function()
        if writefile then
            local data = HttpService:JSONEncode({
                Speed = Config.Speed,
                Jump = Config.Jump,
                Language = Config.Language
            })
            writefile("PainelAdmin_Config.json", data)
        end
    end)
    SaveBtn.Text = success and "Configurações Salvas!" or "Erro ao Salvar (Executor sem suporte)"
    task.delay(2, function()
        SaveBtn.Text = "Salvar Configurações"
    end)
end)

print("Painel Admin carregado com sucesso!")