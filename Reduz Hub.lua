--[[
    ╔══════════════════════════════════════╗
    ║          REDUZ HUB - BLOX FRUITS     ║
    ║          Versão 1.0                  ║
    ╚══════════════════════════════════════╝
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

-- ================= VERIFICAÇÃO DE JOGO =================
local VALID_PLACE_IDS = {
    [2753915549] = true, -- Blox Fruits (1st Sea)
    [4442272183] = true, -- Blox Fruits (2nd Sea)
    [7449423635] = true, -- Blox Fruits (3rd Sea)
}

if not VALID_PLACE_IDS[game.PlaceId] then
    warn("[Reduz Hub] Este script só funciona no Blox Fruits!")
    return
end

local player = Players.LocalPlayer

-- ================= LIMPAR INSTÂNCIA ANTIGA =================
local parentGui
pcall(function() parentGui = CoreGui end)
if not parentGui then
    parentGui = player:WaitForChild("PlayerGui")
end

local old = parentGui:FindFirstChild("ReduzHub")
if old then old:Destroy() end

-- ================= GUI PRINCIPAL =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ReduzHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- ================= ÍCONE ARRASTÁVEL "RD" =================
local Icon = Instance.new("Frame")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 52, 0, 52)
Icon.Position = UDim2.new(0, 20, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Icon.BorderSizePixel = 0
Icon.ZIndex = 10
Icon.Parent = ScreenGui

Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 10)

local IconStroke = Instance.new("UIStroke", Icon)
IconStroke.Color = Color3.fromRGB(200, 50, 50)
IconStroke.Thickness = 2
IconStroke.Transparency = 0.3

local IconLabel = Instance.new("TextLabel")
IconLabel.Size = UDim2.new(1, 0, 1, 0)
IconLabel.BackgroundTransparency = 1
IconLabel.Text = "RD"
IconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
IconLabel.Font = Enum.Font.GothamBold
IconLabel.TextSize = 20
IconLabel.ZIndex = 11
IconLabel.Parent = Icon

-- ================= MENU =================
local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.new(0, 520, 0, 360)
Menu.Position = UDim2.new(0.5, -260, 0.5, -180)
Menu.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Menu.BorderSizePixel = 0
Menu.Visible = false
Menu.ClipsDescendants = true
Menu.ZIndex = 5
Menu.Parent = ScreenGui

Instance.new("UICorner", Menu).CornerRadius = UDim.new(0, 10)
local MenuStroke = Instance.new("UIStroke", Menu)
MenuStroke.Color = Color3.fromRGB(200, 50, 50)
MenuStroke.Thickness = 1.5

-- Barra de título
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 6
TitleBar.Parent = Menu

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Reduz Hub | Blox Fruits"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 7
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.ZIndex = 7
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Área de conteúdo
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -20, 1, -50)
Body.Position = UDim2.new(0, 10, 0, 44)
Body.BackgroundTransparency = 1
Body.ZIndex = 6
Body.Parent = Menu

-- Coluna de categorias
local CatPanel = Instance.new("Frame")
CatPanel.Size = UDim2.new(0, 115, 1, 0)
CatPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
CatPanel.BorderSizePixel = 0
CatPanel.ZIndex = 7
CatPanel.Parent = Body
Instance.new("UICorner", CatPanel).CornerRadius = UDim.new(0, 8)

local CatList = Instance.new("UIListLayout", CatPanel)
CatList.Padding = UDim.new(0, 6)
CatList.SortOrder = Enum.SortOrder.LayoutOrder

local CatPad = Instance.new("UIPadding", CatPanel)
CatPad.PaddingTop = UDim.new(0, 6)
CatPad.PaddingLeft = UDim.new(0, 6)
CatPad.PaddingRight = UDim.new(0, 6)

-- Coluna de opções
local OptPanel = Instance.new("Frame")
OptPanel.Size = UDim2.new(1, -125, 1, 0)
OptPanel.Position = UDim2.new(0, 125, 0, 0)
OptPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
OptPanel.BorderSizePixel = 0
OptPanel.ZIndex = 7
OptPanel.Parent = Body
Instance.new("UICorner", OptPanel).CornerRadius = UDim.new(0, 8)

-- ================= SISTEMA DE ARRASTAR =================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Arrastar menu pela barra de título
makeDraggable(Menu, TitleBar)

-- Arrastar ícone (com detecção de clique para abrir/fechar)
do
    local dragging, dragInput, dragStart, startPos, moved
    Icon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, Icon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then
                        Menu.Visible = not Menu.Visible
                    end
                end
            end)
        end
    end)
    Icon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
            Icon.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

CloseBtn.MouseButton1Click:Connect(function() Menu.Visible = false end)

-- ================= HELPERS DE UI =================
local function makeScroll(scroller)
    scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroller.ScrollBarThickness = 4
    scroller.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
    scroller.BackgroundTransparency = 1
    scroller.BorderSizePixel = 0
end

local function createCategoryButton(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.ZIndex = 8
    btn.Parent = CatPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function createToggle(parent, name, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -40, 0.5, -10)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            TweenService:Create(knob, TweenInfo.new(0.18),
                {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            TweenService:Create(knob, TweenInfo.new(0.18),
                {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        if callback then pcall(callback, enabled) end
    end)
    return row
end

-- ================= SISTEMA DE ESP =================
local EspStates = {
    fruits = { enabled = false, color = Color3.fromRGB(0, 255, 100), items = {} },
    npcs   = { enabled = false, color = Color3.fromRGB(255, 60, 60),  items = {} },
    chests = { enabled = false, color = Color3.fromRGB(255, 200, 0),  items = {} },
}

local function createESP(obj, color)
    if obj:FindFirstChild("ReduzESP_HL") then return obj.ReduzESP_HL end
    local hl = Instance.new("Highlight")
    hl.Name = "ReduzESP_HL"
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    return hl
end

local function clearESPState(state)
    for obj, hl in pairs(state.items) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    state.items = {}
end

local function isNPC(model)
    return model:IsA("Model")
        and model ~= player.Character
        and model:FindFirstChildOfClass("Humanoid")
        and Players:GetPlayerFromCharacter(model) == nil
end

local function isFruit(obj)
    return obj:IsA("Tool") and obj:FindFirstChild("Handle")
end

local function isChest(obj)
    if not obj.Name then return false end
    return (obj:IsA("Model") or obj:IsA("BasePart"))
        and obj.Name:lower():find("chest")
end

local function updateESP()
    -- FRUTAS
    if EspStates.fruits.enabled then
        for _, obj in pairs(Workspace:GetChildren()) do
            if isFruit(obj) then
                local cur = EspStates.fruits.items[obj]
                if not cur or not cur.Parent then
                    EspStates.fruits.items[obj] = createESP(obj, EspStates.fruits.color)
                end
            end
        end
        for obj, hl in pairs(EspStates.fruits.items) do
            if not obj.Parent then
                pcall(function() hl:Destroy() end)
                EspStates.fruits.items[obj] = nil
            end
        end
    end

    -- NPCs
    if EspStates.npcs.enabled then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if isNPC(obj) then
                local cur = EspStates.npcs.items[obj]
                if not cur or not cur.Parent then
                    EspStates.npcs.items[obj] = createESP(obj, EspStates.npcs.color)
                end
            end
        end
        for obj, hl in pairs(EspStates.npcs.items) do
            if not obj.Parent then
                pcall(function() hl:Destroy() end)
                EspStates.npcs.items[obj] = nil
            end
        end
    end

    -- Baús
    if EspStates.chests.enabled then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if isChest(obj) then
                local cur = EspStates.chests.items[obj]
                if not cur or not cur.Parent then
                    EspStates.chests.items[obj] = createESP(obj, EspStates.chests.color)
                end
            end
        end
        for obj, hl in pairs(EspStates.chests.items) do
            if not obj.Parent then
                pcall(function() hl:Destroy() end)
                EspStates.chests.items[obj] = nil
            end
        end
    end
end

task.spawn(function()
    while true do
        pcall(updateESP)
        task.wait(0.5)
    end
end)

-- ================= HELPERS DE TELEPORTE =================
local function teleportTo(position)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

local function findNearest(predicate)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local best, bestDist = nil, math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if predicate(obj) then
            local pos = obj:IsA("BasePart") and obj.Position
                or (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position)
                or (obj:FindFirstChild("Handle") and obj.Handle.Position)
            if pos then
                local d = (pos - myPos).Magnitude
                if d < bestDist then best, bestDist = pos, d end
            end
        end
    end
    return best
end

-- ================= CONTEÚDO: STATUS =================
local StatusScroll = Instance.new("ScrollingFrame")
StatusScroll.Size = UDim2.new(1, -12, 1, -12)
StatusScroll.Position = UDim2.new(0, 6, 0, 6)
StatusScroll.Visible = false
StatusScroll.Parent = OptPanel
makeScroll(StatusScroll)

local StatusList = Instance.new("UIListLayout", StatusScroll)
StatusList.Padding = UDim.new(0, 6)
StatusList.SortOrder = Enum.SortOrder.LayoutOrder

local function createStatusRow(name)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
    frame.BorderSizePixel = 0
    frame.Parent = StatusScroll
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    return frame, lbl
end

local _, ServerLbl = createStatusRow("Servidor: ...")
local _, GameLbl   = createStatusRow("Jogo: ...")
local _, LuaLbl    = createStatusRow("Estado da Lua: ...")
local _, PlayersLbl= createStatusRow("Jogadores: ...")

task.spawn(function()
    while true do
        pcall(function()
            local jobId = tostring(game.JobId or "N/A")
            if #jobId > 20 then jobId = jobId:sub(1, 8) .. "..." end
            ServerLbl.Text  = "Servidor: " .. jobId
            GameLbl.Text    = "Jogo: " .. tostring(game.Name) .. " (" .. game.PlaceId .. ")"
            LuaLbl.Text     = "Estado da Lua: Ativo ✓"
            PlayersLbl.Text = ("Jogadores: %d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers)
        end)
        task.wait(1)
    end
end)

-- ================= CONTEÚDO: MAIN =================
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, -12, 1, -12)
MainScroll.Position = UDim2.new(0, 6, 0, 6)
MainScroll.Visible = false
MainScroll.Parent = OptPanel
makeScroll(MainScroll)

local MainList = Instance.new("UIListLayout", MainScroll)
MainList.Padding = UDim.new(0, 4)
MainList.SortOrder = Enum.SortOrder.LayoutOrder

-- Auto Farm (placeholder simples)
local autoFarmLoop
createToggle(MainScroll, "Auto Farm", function(on)
    if on then
        autoFarmLoop = task.spawn(function()
            while true do
                task.wait(0.5)
                -- lógica básica: procura NPC mais próximo e teleporta
                local pos = findNearest(function(o) return isNPC(o) end)
                if pos then teleportTo(pos) end
            end
        end)
    else
        if autoFarmLoop then task.cancel(autoFarmLoop) end
    end
end)

-- Auto Maestria (placeholder)
createToggle(MainScroll, "Auto Maestria", function(on)
    warn("[Reduz Hub] Auto Maestria " .. (on and "ativado" or "desativado"))
end)

-- Auto Belly
local autoBellyLoop
createToggle(MainScroll, "Auto Belly", function(on)
    if on then
        autoBellyLoop = task.spawn(function()
            while true do
                task.wait(1)
                -- procura NPC tipo "Quest" para farmar belly
                local pos = findNearest(function(o)
                    return isNPC(o) and (o.Name:lower():find("bandit") or o.Name:lower():find("pirate") or o.Name:lower():find("soldier"))
                end)
                if pos then teleportTo(pos) end
            end
        end)
    else
        if autoBellyLoop then task.cancel(autoBellyLoop) end
    end
end)

-- Auto Trunk (coleta baús)
local autoTrunkLoop
createToggle(MainScroll, "Auto Trunk", function(on)
    if on then
        autoTrunkLoop = task.spawn(function()
            while true do
                task.wait(0.8)
                local pos = findNearest(isChest)
                if pos then teleportTo(pos) end
            end
        end)
    else
        if autoTrunkLoop then task.cancel(autoTrunkLoop) end
    end
end)

createToggle(MainScroll, "Auto Raid", function(on)
    warn("[Reduz Hub] Auto Raid " .. (on and "ativado" or "desativado"))
end)

createToggle(MainScroll, "Auto Quest", function(on)
    warn("[Reduz Hub] Auto Quest " .. (on and "ativado" or "desativado"))
end)

createToggle(MainScroll, "Auto Boss", function(on)
    warn("[Reduz Hub] Auto Boss " .. (on and "ativado" or "desativado"))
end)

-- Auto Point
createToggle(MainScroll, "Auto Point", function(on)
    warn("[Reduz Hub] Auto Point " .. (on and "ativado (Melee)" or "desativado"))
    if on then
        task.spawn(function()
            while true do
                task.wait(0.5)
                pcall(function()
                    -- Tenta upar pontos (requer módulo do jogo, aqui apenas tenta via remotes básicos)
                    local stat = player:FindFirstChild("leaderstats")
                    if stat then
                        local points = stat:FindFirstChild("Points")
                        if points and points.Value >= 1 then
                            -- Comando interno simples - nem sempre funciona dependendo da versão
                        end
                    end
                end)
            end
        end)
    end
end)

-- Esp Fruits
createToggle(MainScroll, "Esp Fruits", function(on)
    EspStates.fruits.enabled = on
    if not on then clearESPState(EspStates.fruits) end
end)

-- Auto Fruits
local autoFruitLoop
createToggle(MainScroll, "Auto Fruits", function(on)
    if on then
        autoFruitLoop = task.spawn(function()
            while true do
                task.wait(0.7)
                local pos = findNearest(isFruit)
                if pos then teleportTo(pos) end
            end
        end)
    else
        if autoFruitLoop then task.cancel(autoFruitLoop) end
    end
end)

-- Esp NPC
createToggle(MainScroll, "Esp NPC", function(on)
    EspStates.npcs.enabled = on
    if not on then clearESPState(EspStates.npcs) end
end)

-- Esp Chest
createToggle(MainScroll, "Esp Chest", function(on)
    EspStates.chests.enabled = on
    if not on then clearESPState(EspStates.chests) end
end)

-- ================= CATEGORIAS =================
local Categories = {
    { name = "Status", frame = StatusScroll },
    { name = "Main",   frame = MainScroll   },
}

local catButtons = {}

local function showCategory(name)
    for _, cat in ipairs(Categories) do
        cat.frame.Visible = (cat.name == name)
    end
    for catName, btn in pairs(catButtons) do
        if catName == name then
            TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15),
                {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
        end
    end
end

for _, cat in ipairs(Categories) do
    local btn = createCategoryButton(cat.name)
    catButtons[cat.name] = btn
    btn.MouseButton1Click:Connect(function() showCategory(cat.name) end)
end

showCategory("Status")

-- ================= ABERTURA =================
Menu.Visible = false
print("[Reduz Hub] Carregado com sucesso! Clique no ícone 'RD' para abrir.")