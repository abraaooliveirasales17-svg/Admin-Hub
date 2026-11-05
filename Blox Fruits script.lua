--============================================================
-- BLOX FRUITS – MOBILE HUB (UI + FUNÇÕES CLIENT-SIDE)
-- Compatibilidade pretendida: Android / Arceus X Neo
-- Sem backdoors, sem ofuscação, sem loops destrutivos
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- 1. CONFIGURAÇÕES GLOBAIS E ESTADO
--============================================================
local Config = {
    ESP = {
        Players = false,
        Fruits  = false,
        Chests  = false,
        NPCs    = false,
        Bosses  = false,
        Distance = 2000,
        PlayerColor = Color3.fromRGB(0, 170, 255),
        FruitColor  = Color3.fromRGB(255, 215, 0),
        ChestColor  = Color3.fromRGB(255, 140, 0),
        NPCColor    = Color3.fromRGB(180, 180, 180),
        BossColor   = Color3.fromRGB(255, 0, 80),
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
    },
    Teleport = {
        Method = "Tween", -- "Instant" ou "Tween"
    }
}

local ESP_Objects = {} -- armazena highlights para limpeza

--============================================================
-- 2. MÓDULO DE UI (CRIADO MANUALMENTE, SEM BIBLIOTECAS EXTERNAS)
--============================================================
local function createUI()
    local old = PlayerGui:FindFirstChild("BloxFruitsMobileHub")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BloxFruitsMobileHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    -- Janela principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true -- arrastar nativo do Roblox
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    -- Barra de título
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ Blox Fruits Hub"
    Title.TextColor3 = Color3.fromRGB(200, 180, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    -- Botão minimizar
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -72, 0, 5)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 18
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Parent = TitleBar
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

    -- Botão fechar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -36, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    -- Container de abas
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, -20, 0, 32)
    TabBar.Position = UDim2.new(0, 10, 0, 48)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = MainFrame

    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 6)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabBar

    -- Área de conteúdo (scroll)
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -100)
    Content.Position = UDim2.new(0, 10, 0, 88)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 200)
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.Parent = MainFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content

    -- Função auxiliar para criar abas
    local currentTab = nil
    local function createTab(name, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 0, 1, 0)
        btn.AutomaticSize = Enum.AutomaticSize.X
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.LayoutOrder = order
        btn.Parent = TabBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 0, 0)
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BackgroundTransparency = 1
        page.LayoutOrder = order
        page.Parent = Content

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        btn.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                currentTab.page.Visible = false
            end
            btn.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
            page.Visible = true
            currentTab = { btn = btn, page = page }
        end)
        return page
    end

    -- Funções auxiliares para componentes
    local function addSection(parent, text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 28)
        lbl.BackgroundTransparency = 1
        lbl.Text = "── " .. text .. " ──"
        lbl.TextColor3 = Color3.fromRGB(140, 120, 220)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent
        return lbl
    end

    local function addButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 42) -- botão grande para mobile
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 75)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230, 230, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(callback)
            if not ok then warn("[UI] Erro no botão: " .. tostring(err)) end
        end)
        return btn
    end

    local function addToggle(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundTransparency = 1
        frame.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 40, 0, 22)
        toggle.Position = UDim2.new(1, -40, 0, 7)
        toggle.BackgroundColor3 = default and Color3.fromRGB(80, 60, 160) or Color3.fromRGB(60, 60, 80)
        toggle.Text = ""
        toggle.Parent = frame
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

        local state = default
        toggle.MouseButton1Click:Connect(function()
            state = not state
            toggle.BackgroundColor3 = state and Color3.fromRGB(80, 60, 160) or Color3.fromRGB(60, 60, 80)
            pcall(callback, state)
        end)
    end

    local function addSlider(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundTransparency = 1
        frame.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = text .. ": " .. default
        lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 6)
        bar.Position = UDim2.new(0, 0, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        bar.BorderSizePixel = 0
        bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local dragging = false
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local relX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(relX, 0, 1, 0)
                local value = math.floor(min + (max - min) * relX)
                lbl.Text = text .. ": " .. value
                pcall(callback, value)
            end
        end)
    end

    -- Criar abas
    local farmPage = createTab("Farm", 1)
    local fruitPage = createTab("Frutas", 2)
    local combatPage = createTab("Combate", 3)
    local tpPage = createTab("TP", 4)
    local espPage = createTab("ESP", 5)
    local playerPage = createTab("Player", 6)
    local configPage = createTab("Config", 7)

    -- Preencher abas (exemplos; funções chamadas depois)
    addSection(farmPage, "Farm")
    addToggle(farmPage, "Auto Farm (experimental)", false, function(v) Config.AutoFarm = v end)
    addButton(farmPage, "Level Farm (iniciar)", function() startLevelFarm() end)

    addSection(fruitPage, "Frutas")
    addToggle(fruitPage, "Fruit ESP", false, function(v) Config.ESP.Fruits = v; updateESP() end)
    addButton(fruitPage, "Listar Frutas no Inventário", function() listFruits() end)

    addSection(combatPage, "Combate")
    addSlider(combatPage, "Alcance de combate", 10, 100, 30, function(v) Config.CombatRange = v end)

    addSection(tpPage, "Teleporte")
    addButton(tpPage, "Sea 1 – Starter Island", function() teleportTo("Starter Island") end)
    addButton(tpPage, "Sea 1 – Middle Town", function() teleportTo("Middle Town") end)
    addButton(tpPage, "Sea 2 – Kingdom of Rose", function() teleportTo("Kingdom of Rose") end)

    addSection(espPage, "ESP")
    addToggle(espPage, "Player ESP", false, function(v) Config.ESP.Players = v; updateESP() end)
    addToggle(espPage, "Chest ESP", false, function(v) Config.ESP.Chests = v; updateESP() end)
    addToggle(espPage, "NPC ESP", false, function(v) Config.ESP.NPCs = v; updateESP() end)
    addSlider(espPage, "Distância ESP", 100, 5000, 2000, function(v) Config.ESP.Distance = v end)

    addSection(playerPage, "Jogador")
    addSlider(playerPage, "Velocidade", 16, 200, 16, function(v) Config.Player.WalkSpeed = v; applyPlayerStats() end)
    addSlider(playerPage, "Pulo", 50, 300, 50, function(v) Config.Player.JumpPower = v; applyPlayerStats() end)

    addSection(configPage, "Configurações")
    addButton(configPage, "Salvar preferências", function() saveConfig() end)
    addButton(configPage, "Carregar preferências", function() loadConfig() end)
    addButton(configPage, "Reiniciar interface", function() createUI() end)

    -- Ações dos botões de título
    MinimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        local mini = Instance.new("TextButton")
        mini.Name = "MiniButton"
        mini.Size = UDim2.new(0, 100, 0, 32)
        mini.Position = UDim2.new(0, 10, 0, 10)
        mini.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
        mini.Text = "Mostrar Hub"
        mini.TextColor3 = Color3.fromRGB(255, 255, 255)
        mini.TextSize = 12
        mini.Parent = ScreenGui
        Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
        mini.MouseButton1Click:Connect(function()
            MainFrame.Visible = true
            mini:Destroy()
        end)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Ativar primeira aba
    if not currentTab then
        TabBar:GetChildren()[1].MouseButton1Click:Fire()
    end
end

--============================================================
-- 3. TELEPORTE (COORDENADAS CFrame)
--============================================================
local IslandCFrames = {
    ["Starter Island"] = CFrame.new(0, 10, 0), -- substitua por coordenada real
    ["Middle Town"] = CFrame.new(-1500, 220, 1369),
    ["Zombie Island"] = CFrame.new(-5622, 492, -781),
    ["Two Snow Mountain"] = CFrame.new(753, 408, -5274),
    ["Punk Hazard"] = CFrame.new(-6127, 15, -5040),
    ["Cursed Ship"] = CFrame.new(923, 125, 32885),
    ["Ice Castle"] = CFrame.new(6148, 294, -6741),
    ["Forgotten Island"] = CFrame.new(-3032, 317, -10075),
    ["Ussop Island"] = CFrame.new(4816, 8, 2863),
    ["Mini Sky Island"] = CFrame.new(-288, 49326, -35248),
    ["Great Tree"] = CFrame.new(2681, 1682, -7190),
    ["Castle On The Sea"] = CFrame.new(-5075, 314, -3150),
    ["Port Town"] = CFrame.new(-290, 6, 5343),
    ["Hydra Island"] = CFrame.new(5228, 604, 345),
    ["Floating Turtle"] = CFrame.new(-13274, 531, -7579),
    ["Haunted Castle"] = CFrame.new(-9515, 164, 5786),
    ["Ice Cream Island"] = CFrame.new(-902, 79, -10988),
    ["Peanut Island"] = CFrame.new(-2062, 50, -10232),
    ["Cake Island"] = CFrame.new(-1884, 19, -11666),
    ["Cocoa Island"] = CFrame.new(87, 73, -12319),
    ["Candy Island"] = CFrame.new(-1014, 149, -14555),
    -- Adicione outras coordenadas conforme necessário
}

local function teleportTo(islandName)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = IslandCFrames[islandName]
    if not target then
        warn("[TP] Ilha não encontrada: " .. islandName)
        return
    end

    if Config.Teleport.Method == "Tween" then
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, { CFrame = target })
        tween:Play()
    else
        hrp.CFrame = target
    end
end

--============================================================
-- 4. ESP (HIGHLIGHT)
--============================================================
local function clearESP()
    for _, obj in pairs(ESP_Objects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESP_Objects = {}
end

local function addHighlight(instance, color, name)
    if not instance or not instance.Parent then return end
    local existing = instance:FindFirstChild("ESP_Highlight")
    if existing then existing:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = instance
    hl.FillColor = color
    hl.FillTransparency = 0.6
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = instance
    table.insert(ESP_Objects, hl)
end

local function updateESP()
    clearESP()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Player ESP
    if Config.ESP.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - root.Position).Magnitude <= Config.ESP.Distance then
                    addHighlight(plr.Character, Config.ESP.PlayerColor)
                end
            end
        end
    end

    -- Fruit ESP (procura por modelos de frutas no Workspace)
    if Config.ESP.Fruits then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:find("Fruit") then
                local primary = obj.PrimaryPart
                if primary and (primary.Position - root.Position).Magnitude <= Config.ESP.Distance then
                    addHighlight(obj, Config.ESP.FruitColor)
                end
            end
        end
    end

    -- Chest ESP (baús geralmente são modelos com "Chest" no nome)
    if Config.ESP.Chests then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name:lower():find("chest") then
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primary and (primary.Position - root.Position).Magnitude <= Config.ESP.Distance then
                    addHighlight(obj, Config.ESP.ChestColor)
                end
            end
        end
    end

    -- NPC ESP (Humanoides não jogadores)
    if Config.ESP.NPCs then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                local plr = Players:GetPlayerFromCharacter(obj)
                if not plr then -- é NPC
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - root.Position).Magnitude <= Config.ESP.Distance then
                        addHighlight(obj, Config.ESP.NPCColor)
                    end
                end
            end
        end
    end
end

-- Loop de atualização do ESP (a cada 1 segundo, para economizar recursos)
task.spawn(function()
    while true do
        task.wait(1)
        if Config.ESP.Players or Config.ESP.Fruits or Config.ESP.Chests or Config.ESP.NPCs then
            pcall(updateESP)
        end
    end
end)

--============================================================
-- 5. JOGADOR (VELOCIDADE / PULO)
--============================================================
local function applyPlayerStats()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    hum.WalkSpeed = Config.Player.WalkSpeed
    hum.JumpPower = Config.Player.JumpPower
end

--============================================================
-- 6. CONFIGURAÇÕES (SALVAR / CARREGAR)
--============================================================
local CONFIG_FILE = "BloxFruitsHub_Config.json"

local function saveConfig()
    if not writefile or not isfile then
        warn("[Config] writefile não suportado neste executor.")
        return
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if ok then
        writefile(CONFIG_FILE, encoded)
        print("[Config] Preferências salvas.")
    else
        warn("[Config] Falha ao salvar: " .. tostring(encoded))
    end
end

local function loadConfig()
    if not readfile or not isfile then
        warn("[Config] readfile não suportado neste executor.")
        return
    end
    if not isfile(CONFIG_FILE) then
        warn("[Config] Arquivo não encontrado.")
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if type(v) == "table" then
                for subK, subV in pairs(v) do
                    if Config[k] and Config[k][subK] ~= nil then
                        Config[k][subK] = subV
                    end
                end
            elseif Config[k] ~= nil then
                Config[k] = v
            end
        end
        applyPlayerStats()
        updateESP()
        print("[Config] Preferências carregadas.")
    else
        warn("[Config] Falha ao carregar: " .. tostring(data))
    end
end

--============================================================
-- 7. FUNÇÕES DE FARM (EXPERIMENTAIS)
--============================================================
local function startLevelFarm()
    -- Auto farm básico: move até NPCs e ataca com a arma equipada.
    -- ATENÇÃO: Pode violar os ToS e não funciona se houver anti-cheat.
    task.spawn(function()
        while Config.AutoFarm do
            task.wait(1)
            local char = LocalPlayer.Character
            if not char then break end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then break end

            local closestNPC, closestDist = nil, math.huge
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    local plr = Players:GetPlayerFromCharacter(obj)
                    if not plr then
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                            if dist < closestDist and dist < (Config.CombatRange or 30) then
                                closestNPC = obj
                                closestDist = dist
                            end
                        end
                    end
                end
            end
            if closestNPC then
                local targetPos = closestNPC.HumanoidRootPart.Position
                hum:MoveTo(targetPos)
                -- Tentar atacar com ferramenta equipada
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end)
end

local function listFruits()
    -- Lista frutas do inventário via remote (pode falhar)
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if not remotes then return end
    local commF = remotes:FindFirstChild("CommF_")
    if not commF then return end
    local ok, fruits = pcall(function()
        return commF:InvokeServer("GetFruits")
    end)
    if ok and fruits then
        print("Frutas no inventário:")
        for _, fruit in pairs(fruits) do
            print("- " .. tostring(fruit.Name))
        end
    else
        warn("[Frutas] Não foi possível obter a lista.")
    end
end

--============================================================
-- 8. INICIALIZAÇÃO
--============================================================
createUI()
applyPlayerStats()
print("[Blox Fruits Hub] Carregado com sucesso.")