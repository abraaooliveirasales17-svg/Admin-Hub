--!nocheck
-- ██████╗  █████╗ ██╗███╗   ██╗███████╗██╗         
-- ██╔══██╗██╔══██╗██║████╗  ██║██╔════╝██║         
-- ██████╔╝███████║██║██╔██╗ ██║█████╗  ██║         
-- ██╔═══╝ ██╔══██║██║██║╚██╗██║██╔══╝  ██║         
-- ██║     ██║  ██║██║██║ ╚████║███████╗███████╗    
-- ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝    
-- Painel Admin - Admin Panel for Roblox

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ███ Parent GUI (executor-safe) ███
local ParentGui
if gethui then pcall(function() ParentGui = gethui() end) end
if not ParentGui then pcall(function() ParentGui = game:GetService("CoreGui") end) end
if not ParentGui then ParentGui = LocalPlayer:WaitForChild("PlayerGui") end

pcall(function()
    local old = ParentGui:FindFirstChild("PainelAdmin")
    if old then old:Destroy() end
end)

-- ███ State ███
local State = {
    speedValue = 16, speedEnabled = false,
    jumpValue = 50, jumpEnabled = false,
    infiniteJump = false,
    teleportName = "", loopTeleportName = "", loopTeleportEnabled = false,
    noclipEnabled = false,
    espEnabled = false, xrayEnabled = false,
    iconColor = Color3.fromRGB(0, 0, 0),
    menuColor = Color3.fromRGB(15, 15, 15),
    menuRGB = false, iconRGB = false,
    language = "pt-BR",
    currentCategory = "fisico",
}

-- ███ Translations ███
local T = {
    ["pt-BR"] = {
        name = "Português", fisico = "Físico", magico = "Mágico", visual = "Visual",
        status = "Status", configuracoes = "Configurações",
        alterarVelocidade = "Alterar Velocidade", alterarPulo = "Alterar Pulo",
        puloInfinito = "Pulo Infinito", teleporte = "Teleporte",
        loopTeleporte = "Loop Teleporte", atravessar = "Atravessar",
        tpTool = "TP Tool", otimizar = "Otimizar", esp = "ESP", raioX = "Raio X",
        nomeJogo = "Nome do Jogo", maxJogadores = "Máximo de Jogadores",
        jogadoresAtuais = "Jogadores Atuais", estadoLua = "Estado da Lua",
        nomeServidor = "Nome do Servidor", corIcone = "Cor do Ícone",
        corMenu = "Cor do Menu", menuRGB = "Menu RGB", iconeRGB = "Ícone RGB",
        idioma = "Idioma", salvar = "Salvar", ativar = "Ativar", desativar = "Desativar",
        buscar = "Buscar", tp = "Teleportar", nomeJogador = "Nome do jogador",
        valorVelocidade = "Valor de velocidade", valorPulo = "Valor do pulo",
        salvando = "Salvando...", salvo = "Salvo!",
    },
    ["en-US"] = {
        name = "English", fisico = "Physical", magico = "Magic", visual = "Visual",
        status = "Status", configuracoes = "Settings",
        alterarVelocidade = "Change Speed", alterarPulo = "Change Jump",
        puloInfinito = "Infinite Jump", teleporte = "Teleport",
        loopTeleporte = "Loop Teleport", atravessar = "Noclip",
        tpTool = "TP Tool", otimizar = "Optimize", esp = "ESP", raioX = "X-Ray",
        nomeJogo = "Game Name", maxJogadores = "Max Players",
        jogadoresAtuais = "Current Players", estadoLua = "Moon State",
        nomeServidor = "Server Name", corIcone = "Icon Color",
        corMenu = "Menu Color", menuRGB = "Menu RGB", iconeRGB = "Icon RGB",
        idioma = "Language", salvar = "Save", ativar = "Enable", desativar = "Disable",
        buscar = "Find", tp = "Teleport", nomeJogador = "Player name",
        valorVelocidade = "Speed value", valorPulo = "Jump value",
        salvando = "Saving...", salvo = "Saved!",
    },
    ["es-ES"] = {
        name = "Español", fisico = "Físico", magico = "Mágico", visual = "Visual",
        status = "Estado", configuracoes = "Configuraciones",
        alterarVelocidade = "Cambiar Velocidad", alterarPulo = "Cambiar Salto",
        puloInfinito = "Salto Infinito", teleporte = "Teletransporte",
        loopTeleporte = "Teletransporte Bucle", atravessar = "Atravesar",
        tpTool = "TP Tool", otimizar = "Optimizar", esp = "ESP", raioX = "Rayos X",
        nomeJogo = "Nombre del Juego", maxJogadores = "Máx. Jugadores",
        jogadoresAtuais = "Jugadores Actuales", estadoLua = "Estado de la Luna",
        nomeServidor = "Nombre del Servidor", corIcone = "Color del Icono",
        corMenu = "Color del Menú", menuRGB = "Menú RGB", iconeRGB = "Icono RGB",
        idioma = "Idioma", salvar = "Guardar", ativar = "Activar", desativar = "Desactivar",
        buscar = "Buscar", tp = "Teletransportar", nomeJogador = "Nombre del jugador",
        valorVelocidade = "Valor de velocidad", valorPulo = "Valor de salto",
        salvando = "Guardando...", salvo = "¡Guardado!",
    },
    ["fr-FR"] = {
        name = "Français", fisico = "Physique", magico = "Magique", visual = "Visuel",
        status = "Statut", configuracoes = "Paramètres",
        alterarVelocidade = "Changer Vitesse", alterarPulo = "Changer Saut",
        puloInfinito = "Saut Infini", teleporte = "Téléportation",
        loopTeleporte = "Téléportation en Boucle", atravessar = "Traverser",
        tpTool = "TP Tool", otimizar = "Optimiser", esp = "ESP", raioX = "Rayons X",
        nomeJogo = "Nom du Jeu", maxJogadores = "Joueurs Max",
        jogadoresAtuais = "Joueurs Actuels", estadoLua = "État de la Lune",
        nomeServidor = "Nom du Serveur", corIcone = "Couleur de l'Icône",
        corMenu = "Couleur du Menu", menuRGB = "Menu RGB", iconeRGB = "Icône RGB",
        idioma = "Langue", salvar = "Sauvegarder", ativar = "Activer", desativar = "Désactiver",
        buscar = "Chercher", tp = "Téléporter", nomeJogador = "Nom du joueur",
        valorVelocidade = "Valeur vitesse", valorPulo = "Valeur saut",
        salvando = "Sauvegarde...", salvo = "Sauvegardé!",
    },
    ["de-DE"] = {
        name = "Deutsch", fisico = "Physisch", magico = "Magisch", visual = "Visuell",
        status = "Status", configuracoes = "Einstellungen",
        alterarVelocidade = "Geschwindigkeit Ändern", alterarPulo = "Sprung Ändern",
        puloInfinito = "Unendlicher Sprung", teleporte = "Teleport",
        loopTeleporte = "Loop Teleport", atravessar = "Durchgehen",
        tpTool = "TP Tool", otimizar = "Optimieren", esp = "ESP", raioX = "Röntgen",
        nomeJogo = "Spielname", maxJogadores = "Max. Spieler",
        jogadoresAtuais = "Aktuelle Spieler", estadoLua = "Mondstatus",
        nomeServidor = "Servername", corIcone = "Symbolfarbe",
        corMenu = "Menüfarbe", menuRGB = "Menü RGB", iconeRGB = "Symbol RGB",
        idioma = "Sprache", salvar = "Speichern", ativar = "Aktivieren", desativar = "Deaktivieren",
        buscar = "Suchen", tp = "Teleportieren", nomeJogador = "Spielername",
        valorVelocidade = "Geschwindigkeitswert", valorPulo = "Sprungwert",
        salvando = "Speichern...", salvo = "Gespeichert!",
    },
    ["it-IT"] = {
        name = "Italiano", fisico = "Fisico", magico = "Magico", visual = "Visivo",
        status = "Stato", configuracoes = "Impostazioni",
        alterarVelocidade = "Cambia Velocità", alterarPulo = "Cambia Salto",
        puloInfinito = "Salto Infinito", teleporte = "Teletrasporto",
        loopTeleporte = "Teletrasporto Loop", atravessar = "Attraversa",
        tpTool = "TP Tool", otimizar = "Ottimizza", esp = "ESP", raioX = "Raggi X",
        nomeJogo = "Nome del Gioco", maxJogadores = "Giocatori Max",
        jogadoresAtuais = "Giocatori Attuali", estadoLua = "Stato della Luna",
        nomeServidor = "Nome del Server", corIcone = "Colore Icona",
        corMenu = "Colore Menu", menuRGB = "Menu RGB", iconeRGB = "Icona RGB",
        idioma = "Lingua", salvar = "Salva", ativar = "Attiva", desativar = "Disattiva",
        buscar = "Cerca", tp = "Teletrasporta", nomeJogador = "Nome del giocatore",
        valorVelocidade = "Valore velocità", valorPulo = "Valore salto",
        salvando = "Salvataggio...", salvo = "Salvato!",
    },
    ["ja-JP"] = {
        name = "日本語", fisico = "物理", magico = "魔法", visual = "ビジュアル",
        status = "ステータス", configuracoes = "設定",
        alterarVelocidade = "速度変更", alterarPulo = "ジャンプ変更",
        puloInfinito = "無限ジャンプ", teleporte = "テレポート",
        loopTeleporte = "ループテレポート", atravessar = "壁抜け",
        tpTool = "TPツール", otimizar = "最適化", esp = "ESP", raioX = "X線",
        nomeJogo = "ゲーム名", maxJogadores = "最大プレイヤー",
        jogadoresAtuais = "現在のプレイヤー", estadoLua = "月の状態",
        nomeServidor = "サーバー名", corIcone = "アイコン色",
        corMenu = "メニュー色", menuRGB = "メニューRGB", iconeRGB = "アイコンRGB",
        idioma = "言語", salvar = "保存", ativar = "有効", desativar = "無効",
        buscar = "検索", tp = "テレポート", nomeJogador = "プレイヤー名",
        valorVelocidade = "速度の値", valorPulo = "ジャンプの値",
        salvando = "保存中...", salvo = "保存済み!",
    },
    ["ru-RU"] = {
        name = "Русский", fisico = "Физика", magico = "Магия", visual = "Визуал",
        status = "Статус", configuracoes = "Настройки",
        alterarVelocidade = "Изменить Скорость", alterarPulo = "Изменить Прыжок",
        puloInfinito = "Бесконечный Прыжок", teleporte = "Телепорт",
        loopTeleporte = "Цикл Телепорт", atravessar = "Проход Сквозь Стены",
        tpTool = "TP Инструмент", otimizar = "Оптимизировать", esp = "ESP", raioX = "Рентген",
        nomeJogo = "Название Игры", maxJogadores = "Макс. Игроков",
        jogadoresAtuais = "Текущие Игроки", estadoLua = "Состояние Луны",
        nomeServidor = "Имя Сервера", corIcone = "Цвет Иконки",
        corMenu = "Цвет Меню", menuRGB = "Меню RGB", iconeRGB = "Иконка RGB",
        idioma = "Язык", salvar = "Сохранить", ativar = "Вкл", desativar = "Выкл",
        buscar = "Поиск", tp = "Телепорт", nomeJogador = "Имя игрока",
        valorVelocidade = "Знач. скорости", valorPulo = "Знач. прыжка",
        salvando = "Сохранение...", salvo = "Сохранено!",
    },
    ["zh-CN"] = {
        name = "中文", fisico = "物理", magico = "魔法", visual = "视觉",
        status = "状态", configuracoes = "设置",
        alterarVelocidade = "更改速度", alterarPulo = "更改跳跃",
        puloInfinito = "无限跳跃", teleporte = "传送",
        loopTeleporte = "循环传送", atravessar = "穿墙",
        tpTool = "传送工具", otimizar = "优化", esp = "透视", raioX = "X光",
        nomeJogo = "游戏名称", maxJogadores = "最大玩家",
        jogadoresAtuais = "当前玩家", estadoLua = "月亮状态",
        nomeServidor = "服务器名称", corIcone = "图标颜色",
        corMenu = "菜单颜色", menuRGB = "菜单RGB", iconeRGB = "图标RGB",
        idioma = "语言", salvar = "保存", ativar = "启用", desativar = "禁用",
        buscar = "查找", tp = "传送", nomeJogador = "玩家名称",
        valorVelocidade = "速度值", valorPulo = "跳跃值",
        salvando = "保存中...", salvo = "已保存!",
    },
    ["ko-KR"] = {
        name = "한국어", fisico = "물리", magico = "마법", visual = "시각",
        status = "상태", configuracoes = "설정",
        alterarVelocidade = "속도 변경", alterarPulo = "점프 변경",
        puloInfinito = "무한 점프", teleporte = "텔레포트",
        loopTeleporte = "루프 텔레포트", atravessar = "벽 통과",
        tpTool = "TP 도구", otimizar = "최적화", esp = "ESP", raioX = "엑스레이",
        nomeJogo = "게임 이름", maxJogadores = "최대 플레이어",
        jogadoresAtuais = "현재 플레이어", estadoLua = "달 상태",
        nomeServidor = "서버 이름", corIcone = "아이콘 색상",
        corMenu = "메뉴 색상", menuRGB = "메뉴 RGB", iconeRGB = "아이콘 RGB",
        idioma = "언어", salvar = "저장", ativar = "켜기", desativar = "끄기",
        buscar = "찾기", tp = "텔레포트", nomeJogador = "플레이어 이름",
        valorVelocidade = "속도 값", valorPulo = "점프 값",
        salvando = "저장 중...", salvo = "저장됨!",
    },
}

local function T_(key)
    local lang = T[State.language] or T["pt-BR"]
    return lang[key] or T["pt-BR"][key] or key
end

-- ███ Theme ███
local ACCENT = Color3.fromRGB(0, 170, 255)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local SUBTEXT = Color3.fromRGB(160, 160, 160)
local BG_DARK = Color3.fromRGB(25, 25, 25)

-- ███ Helpers ███
local function makeDraggable(frame, dragArea)
    dragArea = dragArea or frame
    local dragging, dragInput, dragStart, startPos

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function createToggle(parent, labelText, initialState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 32)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = TEXT_COLOR
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -40, 0.5, -10)
    track.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    track.BorderSizePixel = 0
    track.Parent = container
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = track

    local isOn = initialState or false

    local function apply(v)
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        }):Play()
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = v and ACCENT or Color3.fromRGB(55, 55, 55)
        }):Play()
    end

    apply(isOn)

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        apply(isOn)
        if callback then callback(isOn) end
    end)

    return {
        Frame = container,
        GetState = function() return isOn end,
    }
end

local function createTextbox(parent, placeholder, defaultText, onChanged)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 32)
    container.BackgroundTransparency = 1

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 1, 0)
    box.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    box.TextColor3 = TEXT_COLOR
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = SUBTEXT
    box.Text = defaultText or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = box

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = box

    if onChanged then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            onChanged(box.Text)
        end)
    end

    return { Frame = container, TextBox = box }
end

local function createButton(parent, text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or ACCENT
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (color or ACCENT):Lerp(Color3.fromRGB(255, 255, 255), 0.2)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color or ACCENT
        }):Play()
    end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

local function createLabel(parent, text, height)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, height or 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = TEXT_COLOR
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

local function createSectionTitle(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = ACCENT
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- ███ ScreenGui ███
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PainelAdmin"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = ParentGui

-- ███ Icon ███
local Icon = Instance.new("TextButton")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 52, 0, 52)
Icon.Position = UDim2.new(0, 40, 0, 40)
Icon.BackgroundColor3 = State.iconColor
Icon.BorderSizePixel = 0
Icon.Text = ""
Icon.AutoButtonColor = false
Icon.ZIndex = 10
Icon.Parent = ScreenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 12)
iconCorner.Parent = Icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(255, 255, 255)
iconStroke.Thickness = 0
iconStroke.Parent = Icon

local apText = Instance.new("TextLabel")
apText.Size = UDim2.new(1, 0, 1, 0)
apText.BackgroundTransparency = 1
apText.Text = "AP"
apText.TextColor3 = Color3.fromRGB(255, 255, 255)
apText.Font = Enum.Font.GothamBold
apText.TextSize = 20
apText.ZIndex = 11
apText.Parent = Icon

-- ███ Main Menu ███
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 640, 0, 440)
Main.Position = UDim2.new(0.5, -320, 0.5, -220)
Main.BackgroundColor3 = State.menuColor
Main.BorderSizePixel = 0
Main.Visible = false
Main.ZIndex = 5
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = Main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 60)
mainStroke.Thickness = 1
mainStroke.Parent = Main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = Main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 20)
titleFix.Position = UDim2.new(0, 0, 1, -20)
titleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -80, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "PAINEL ADMIN"
titleText.TextColor3 = TEXT_COLOR
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 15
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

makeDraggable(Main, titleBar)

closeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- Sidebar (categories)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = BG_DARK
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 0)
sidebarCorner.Parent = Sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = Sidebar

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 8)
sidebarPadding.Parent = Sidebar

-- Content area
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -160, 1, -40)
Content.Position = UDim2.new(0, 160, 0, 40)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = ACCENT
Content.Parent = Main

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = Content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 12)
contentPadding.PaddingLeft = UDim.new(0, 12)
contentPadding.PaddingRight = UDim.new(0, 12)
contentPadding.Parent = Content

-- ███ Builders for categories ███
local categoryButtons = {}
local rebuildContent
local applyIconColor
local applyMenuColor

local function clearContent()
    for _, v in ipairs(Content:GetChildren()) do
        if v:IsA("GuiObject") then v:Destroy() end
    end
end

local function setActiveCategory(cat)
    State.currentCategory = cat
    for name, btn in pairs(categoryButtons) do
        if name == cat then
            btn.BackgroundColor3 = ACCENT
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = SUBTEXT
        end
    end
    rebuildContent()
end

-- Shared ESP management
local espInstances = {}

local function getTeamColor(plr)
    if plr.TeamColor then return plr.TeamColor.Color end
    if plr.Team then return plr.Team.TeamColor.Color end
    return Color3.fromRGB(255, 80, 80)
end

local function clearESP()
    for _, inst in pairs(espInstances) do
        pcall(function()
            if inst and inst.Parent then inst:Destroy() end
        end)
    end
    espInstances = {}
end

local function createESPFor(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if espInstances[plr] then
        for _, inst in ipairs(espInstances[plr]) do
            pcall(function() if inst and inst.Parent then inst:Destroy() end end)
        end
    end
    espInstances[plr] = {}

    local teamColor = getTeamColor(plr)

    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillColor = teamColor
    hl.FillTransparency = 0.55
    hl.OutlineColor = teamColor
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    table.insert(espInstances[plr], hl)

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = hrp
    bb.Size = UDim2.new(0, 220, 0, 44)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = char
    table.insert(espInstances[plr], bb)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = teamColor
    nameLbl.TextStrokeTransparency = 0
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.Text = plr.Name
    nameLbl.Parent = bb

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, 0, 0.5, 0)
    infoLbl.Position = UDim2.new(0, 0, 0.5, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLbl.TextStrokeTransparency = 0
    infoLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLbl.Font = Enum.Font.Gotham
    infoLbl.TextSize = 12
    infoLbl.Text = ""
    infoLbl.Parent = bb

    task.spawn(function()
        while State.espEnabled and char.Parent and bb.Parent do
            local hum = char:FindFirstChildOfClass("Humanoid")
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if hum and myHrp and hrp and hrp.Parent then
                local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
                infoLbl.Text = string.format("❤ %d | 📏 %dm", math.floor(hum.Health), dist)
            end
            task.wait(0.4)
        end
    end)
end

local function refreshESP()
    clearESP()
    if not State.espEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        createESPFor(plr)
    end
end

-- X-Ray management
local xraySaved = {}

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    if not model then return false end
    if model:FindFirstChildOfClass("Humanoid") then return true end
    return false
end

local function applyXray()
    xraySaved = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and not isCharacterPart(inst) then
            if inst.Transparency < 0.5 then
                xraySaved[inst] = inst.Transparency
                inst.Transparency = 0.5
            end
        end
    end
end

local function clearXray()
    for inst, tr in pairs(xraySaved) do
        pcall(function()
            if inst and inst.Parent then inst.Transparency = tr end
        end)
    end
    xraySaved = {}
end

-- ███ Build content per category ███
rebuildContent = function()
    clearContent()
    local cat = State.currentCategory

    if cat == "fisico" then
        createSectionTitle(Content, "▶ " .. T_("fisico")).LayoutOrder = 1

        local speedBox = createTextbox(Content, T_("valorVelocidade"), tostring(State.speedValue), function(text)
            local n = tonumber(text)
            if n then State.speedValue = n end
        end)
        speedBox.Frame.LayoutOrder = 2

        local speedTog = createToggle(Content, T_("alterarVelocidade"), State.speedEnabled, function(v)
            State.speedEnabled = v
        end)
        speedTog.Frame.LayoutOrder = 3

        local jumpBox = createTextbox(Content, T_("valorPulo"), tostring(State.jumpValue), function(text)
            local n = tonumber(text)
            if n then State.jumpValue = n end
        end)
        jumpBox.Frame.LayoutOrder = 4

        local jumpTog = createToggle(Content, T_("alterarPulo"), State.jumpEnabled, function(v)
            State.jumpEnabled = v
        end)
        jumpTog.Frame.LayoutOrder = 5

        local infTog = createToggle(Content, T_("puloInfinito"), State.infiniteJump, function(v)
            State.infiniteJump = v
        end)
        infTog.Frame.LayoutOrder = 6

    elseif cat == "magico" then
        createSectionTitle(Content, "▶ " .. T_("magico")).LayoutOrder = 1

        local tpBox = createTextbox(Content, T_("nomeJogador"), State.teleportName, function(text)
            State.teleportName = text
        end)
        tpBox.Frame.LayoutOrder = 2

        createButton(Content, T_("tp") .. " (1x)", function()
            local target = State.teleportName
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower():sub(1, #target) == target:lower() and #target > 0 then
                    local myChar = LocalPlayer.Character
                    local tChar = plr.Character
                    if myChar and tChar then
                        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                        local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                        if myHrp and tHrp then
                            myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                        end
                    end
                    break
                end
            end
        end).LayoutOrder = 3

        local loopBox = createTextbox(Content, T_("nomeJogador"), State.loopTeleportName, function(text)
            State.loopTeleportName = text
        end)
        loopBox.Frame.LayoutOrder = 4

        local loopTog = createToggle(Content, T_("loopTeleporte"), State.loopTeleportEnabled, function(v)
            State.loopTeleportEnabled = v
        end)
        loopTog.Frame.LayoutOrder = 5

        local noclipTog = createToggle(Content, T_("atravessar"), State.noclipEnabled, function(v)
            State.noclipEnabled = v
        end)
        noclipTog.Frame.LayoutOrder = 6

        createButton(Content, T_("tpTool") .. " (dar item)", function()
            if LocalPlayer.Backpack:FindFirstChild("TP Tool") then return end
            local tool = Instance.new("Tool")
            tool.Name = "TP Tool"
            tool.RequiresHandle = false
            tool.CanBeDropped = false

            local conn
            tool.Equipped:Connect(function(mouse)
                conn = mouse.Button1Down:Connect(function()
                    local hit = mouse.Hit
                    if hit then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
                        end
                    end
                end)
            end)
            tool.Unequipped:Connect(function()
                if conn then conn:Disconnect() end
            end)
            tool.Parent = LocalPlayer.Backpack
        end).LayoutOrder = 7

    elseif cat == "visual" then
        createSectionTitle(Content, "▶ " .. T_("visual")).LayoutOrder = 1

        createButton(Content, T_("otimizar"), function()
            pcall(function() Lighting.GlobalShadows = false end)
            pcall(function() Lighting.FogEnd = 1e9 end)
            pcall(function() Lighting.Brightness = 0 end)
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            for _, inst in ipairs(Lighting:GetChildren()) do
                if inst:IsA("PostEffect") or inst:IsA("Sky") or inst:IsA("Atmosphere") or inst:IsA("Clouds") then
                    pcall(function() inst:Destroy() end)
                end
            end
            for _, inst in ipairs(Workspace:GetDescendants()) do
                if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
                    pcall(function() inst.Enabled = false end)
                end
                if inst:IsA("BasePart") and inst.Material ~= Enum.Material.SmoothPlastic then
                    pcall(function() inst.Material = Enum.Material.SmoothPlastic end)
                end
                if inst:IsA("Decal") or inst:IsA("Texture") then
                    pcall(function() inst.Transparency = 1 end)
                end
                if inst:IsA("MeshPart") then
                    pcall(function() inst.RenderFidelity = Enum.RenderFidelity.Performance end)
                end
            end
        end).LayoutOrder = 2

        local espTog = createToggle(Content, T_("esp"), State.espEnabled, function(v)
            State.espEnabled = v
            refreshESP()
        end)
        espTog.Frame.LayoutOrder = 3

        local xrayTog = createToggle(Content, T_("raioX"), State.xrayEnabled, function(v)
            State.xrayEnabled = v
            if v then applyXray() else clearXray() end
        end)
        xrayTog.Frame.LayoutOrder = 4

    elseif cat == "status" then
        createSectionTitle(Content, "▶ " .. T_("status")).LayoutOrder = 1

        local function addStatusLine(key, value)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -10, 0, 28)
            f.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            f.BorderSizePixel = 0
            f.Parent = Content
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = f

            local k = Instance.new("TextLabel")
            k.Size = UDim2.new(0.5, -8, 1, 0)
            k.Position = UDim2.new(0, 8, 0, 0)
            k.BackgroundTransparency = 1
            k.Text = key
            k.TextColor3 = SUBTEXT
            k.Font = Enum.Font.Gotham
            k.TextSize = 13
            k.TextXAlignment = Enum.TextXAlignment.Left
            k.Parent = f

            local v = Instance.new("TextLabel")
            v.Size = UDim2.new(0.5, -8, 1, 0)
            v.Position = UDim2.new(0.5, 0, 0, 0)
            v.BackgroundTransparency = 1
            v.Text = tostring(value)
            v.TextColor3 = TEXT_COLOR
            v.Font = Enum.Font.GothamBold
            v.TextSize = 13
            v.TextXAlignment = Enum.TextXAlignment.Right
            v.Parent = f
            return f
        end

        addStatusLine(T_("nomeJogo"), game.Name).LayoutOrder = 2
        addStatusLine(T_("maxJogadores"), Players.MaxPlayers).LayoutOrder = 3
        addStatusLine(T_("jogadoresAtuais"), #Players:GetPlayers()).LayoutOrder = 4

        local moonText = "N/A"
        pcall(function()
            local phase = Lighting:GetMoonPhase()
            moonText = tostring(phase.Name or phase)
        end)
        addStatusLine(T_("estadoLua"), moonText).LayoutOrder = 5
        addStatusLine(T_("nomeServidor"), game.JobId ~= "" and game.JobId or tostring(game.PlaceId)).LayoutOrder = 6

        task.delay(1, function()
            -- update player count live
            task.spawn(function()
                while State.currentCategory == "status" do
                    task.wait(2)
                    local found = false
                    for _, f in ipairs(Content:GetChildren()) do
                        if f:IsA("Frame") then
                            local labels = f:GetChildren()
                            for _, l in ipairs(labels) do
                                if l:IsA("TextLabel") and l.Text == T_("jogadoresAtuais") then
                                    found = true
                                    local val = f:FindFirstChildWhichIsA("TextLabel", true)
                                    for _, child in ipairs(f:GetChildren()) do
                                        if child:IsA("TextLabel") and child ~= l then
                                            child.Text = tostring(#Players:GetPlayers())
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if not found then break end
                end
            end)
        end)

    elseif cat == "configuracoes" then
        createSectionTitle(Content, "▶ " .. T_("configuracoes")).LayoutOrder = 1

        -- Icon color palette
        createLabel(Content, T_("corIcone"), 20).LayoutOrder = 2
        local iconPalette = Instance.new("Frame")
        iconPalette.Size = UDim2.new(1, -10, 0, 72)
        iconPalette.BackgroundTransparency = 1
        iconPalette.LayoutOrder = 3
        iconPalette.Parent = Content
        local iconGrid = Instance.new("UIGridLayout")
        iconGrid.CellSize = UDim2.new(0, 28, 0, 28)
        iconGrid.CellPadding = UDim2.new(0, 5, 0, 5)
        iconGrid.Parent = iconPalette

        local palette = {
            Color3.fromRGB(0, 0, 0), Color3.fromRGB(50, 50, 50), Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 255, 50),
            Color3.fromRGB(50, 255, 50), Color3.fromRGB(0, 200, 200), Color3.fromRGB(0, 170, 255),
            Color3.fromRGB(100, 50, 255), Color3.fromRGB(200, 50, 200), Color3.fromRGB(255, 100, 200),
        }
        for _, c in ipairs(palette) do
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = c
            btn.Text = ""
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(90, 90, 90)
            btn.Parent = iconPalette
            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(0, 4)
            cc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                State.iconColor = c
                applyIconColor()
            end)
        end

        -- Menu color palette
        createLabel(Content, T_("corMenu"), 20).LayoutOrder = 4
        local menuPalette = Instance.new("Frame")
        menuPalette.Size = UDim2.new(1, -10, 0, 72)
        menuPalette.BackgroundTransparency = 1
        menuPalette.LayoutOrder = 5
        menuPalette.Parent = Content
        local menuGrid = Instance.new("UIGridLayout")
        menuGrid.CellSize = UDim2.new(0, 28, 0, 28)
        menuGrid.CellPadding = UDim2.new(0, 5, 0, 5)
        menuGrid.Parent = menuPalette

        for _, c in ipairs(palette) do
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = c
            btn.Text = ""
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(90, 90, 90)
            btn.Parent = menuPalette
            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(0, 4)
            cc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                State.menuColor = c
                applyMenuColor()
            end)
        end

        local menuRGBTog = createToggle(Content, T_("menuRGB"), State.menuRGB, function(v)
            State.menuRGB = v
            if not v then
                mainStroke.Color = Color3.fromRGB(60, 60, 60)
            else
                mainStroke.Thickness = 2
            end
        end)
        menuRGBTog.Frame.LayoutOrder = 6

        local iconRGBTog = createToggle(Content, T_("iconeRGB"), State.iconRGB, function(v)
            State.iconRGB = v
            if not v then
                iconStroke.Thickness = 0
            else
                iconStroke.Thickness = 2
            end
        end)
        iconRGBTog.Frame.LayoutOrder = 7

        -- Language
        createLabel(Content, T_("idioma"), 20).LayoutOrder = 8
        local langFrame = Instance.new("Frame")
        langFrame.Size = UDim2.new(1, -10, 0, 32)
        langFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        langFrame.BorderSizePixel = 0
        langFrame.LayoutOrder = 9
        langFrame.Parent = Content
        local lc = Instance.new("UICorner")
        lc.CornerRadius = UDim.new(0, 6)
        lc.Parent = langFrame

        local langBtn = Instance.new("TextButton")
        langBtn.Size = UDim2.new(1, 0, 1, 0)
        langBtn.BackgroundTransparency = 1
        langBtn.Text = (T[State.language] and T[State.language].name) or "Português"
        langBtn.TextColor3 = TEXT_COLOR
        langBtn.Font = Enum.Font.Gotham
        langBtn.TextSize = 13
        langBtn.Parent = langFrame

        local dropdown = Instance.new("Frame")
        dropdown.Size = UDim2.new(1, -10, 0, 200)
        dropdown.Position = UDim2.new(0, 5, 1, 4)
        dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        dropdown.Visible = false
        dropdown.ZIndex = 50
        dropdown.LayoutOrder = 10
        dropdown.Parent = Content
        local ddCorner = Instance.new("UICorner")
        ddCorner.CornerRadius = UDim.new(0, 6)
        ddCorner.Parent = dropdown
        local ddScroll = Instance.new("ScrollingFrame")
        ddScroll.Size = UDim2.new(1, -8, 1, -8)
        ddScroll.Position = UDim2.new(0, 4, 0, 4)
        ddScroll.BackgroundTransparency = 1
        ddScroll.BorderSizePixel = 0
        ddScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        ddScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ddScroll.ScrollBarThickness = 3
        ddScroll.Parent = dropdown
        local ddLayout = Instance.new("UIListLayout")
        ddLayout.Padding = UDim.new(0, 2)
        ddLayout.Parent = ddScroll

        langBtn.MouseButton1Click:Connect(function()
            dropdown.Visible = not dropdown.Visible
        end)

        for code, data in pairs(T) do
            local opt = Instance.new("TextButton")
            opt.Size = UDim2.new(1, 0, 0, 26)
            opt.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            opt.Text = data.name
            opt.TextColor3 = TEXT_COLOR
            opt.Font = Enum.Font.Gotham
            opt.TextSize = 13
            opt.BorderSizePixel = 0
            opt.Parent = ddScroll
            opt.MouseButton1Click:Connect(function()
                State.language = code
                dropdown.Visible = false
                -- Rebuild everything to apply language
                buildUI()
            end)
        end

        -- Save button
        local saveBtn = createButton(Content, "💾 " .. T_("salvar"), function()
            pcall(function()
                if writefile then
                    local data = HttpService:JSONEncode({
                        iconColor = {State.iconColor.R, State.iconColor.G, State.iconColor.B},
                        menuColor = {State.menuColor.R, State.menuColor.G, State.menuColor.B},
                        menuRGB = State.menuRGB,
                        iconRGB = State.iconRGB,
                        language = State.language,
                    })
                    writefile("painel_admin_save.json", data)
                    saveBtn.Text = "💾 " .. T_("salvo")
                    task.delay(2, function() saveBtn.Text = "💾 " .. T_("salvar") end)
                end
            end)
        end)
        saveBtn.LayoutOrder = 11
    end
end

-- ███ Apply color helpers ███
applyIconColor = function()
    if not State.iconRGB then
        Icon.BackgroundColor3 = State.iconColor
    end
end

applyMenuColor = function()
    Main.BackgroundColor3 = State.menuColor
end

-- ███ Category buttons ███
local categories = {
    { key = "fisico", icon = "⚡" },
    { key = "magico", icon = "✦" },
    { key = "visual", icon = "👁" },
    { key = "status", icon = "📊" },
    { key = "configuracoes", icon = "⚙" },
}

local function buildCategoryButtons()
    for _, btn in pairs(categoryButtons) do btn:Destroy() end
    categoryButtons = {}
    for i, cat in ipairs(categories) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.Text = cat.icon .. "  " .. T_(cat.key)
        btn.TextColor3 = SUBTEXT
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.Parent = Sidebar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        categoryButtons[cat.key] = btn
        btn.MouseButton1Click:Connect(function()
            setActiveCategory(cat.key)
        end)
    end
end

-- ███ buildUI (rebuild on language change) ███
function buildUI()
    buildCategoryButtons()
    titleText.Text = "PAINEL ADMIN"
    applyIconColor()
    applyMenuColor()
    setActiveCategory(State.currentCategory or "fisico")
end

-- ███ Icon interaction ███
makeDraggable(Icon)

local lastClick = 0
Icon.MouseButton1Click:Connect(function()
    local now = tick()
    if now - lastClick < 0.4 then return end -- prevent drag-click
    Main.Visible = not Main.Visible
end)

Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        lastClick = tick()
    end
end)

-- ███ RGB loop ███
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    if State.menuRGB then
        hue = (hue + dt * 0.5) % 1
        mainStroke.Color = Color3.fromHSV(hue, 1, 1)
        mainStroke.Thickness = 2
    end
    if State.iconRGB then
        iconStroke.Color = Color3.fromHSV((hue + 0.35) % 1, 1, 1)
        iconStroke.Thickness = 2
    end
end)

-- ███ Movement loop (speed, jump) ███
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if State.speedEnabled then
        hum.WalkSpeed = State.speedValue
    end
    if State.jumpEnabled then
        if hum.UseJumpPower then
            hum.JumpPower = State.jumpValue
        else
            hum.JumpHeight = State.jumpValue
        end
    end
end)

-- ███ Infinite jump ███
UserInputService.JumpRequest:Connect(function()
    if State.infiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ███ Loop teleport ███
task.spawn(function()
    while true do
        task.wait(0.2)
        if State.loopTeleportEnabled and State.loopTeleportName ~= "" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Name:lower():sub(1, #State.loopTeleportName) == State.loopTeleportName:lower() then
                    local myChar = LocalPlayer.Character
                    local tChar = plr.Character
                    if myChar and tChar then
                        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                        local tHrp = tChar:FindFirstChild("HumanoidRootPart")
                        if myHrp and tHrp then
                            myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                        end
                    end
                    break
                end
            end
        end
    end
end)

-- ███ Noclip loop ███
RunService.Stepped:Connect(function()
    if State.noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ███ ESP auto-refresh on player/character events ███
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.espEnabled then createESPFor(plr) end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if espInstances[plr] then
        for _, inst in ipairs(espInstances[plr]) do
            pcall(function() if inst and inst.Parent then inst:Destroy() end end)
        end
        espInstances[plr] = nil
    end
end)

-- ███ Load saved config ███
pcall(function()
    if isfile and isfile("painel_admin_save.json") and readfile then
        local data = HttpService:JSONDecode(readfile("painel_admin_save.json"))
        if data.iconColor then
            State.iconColor = Color3.new(data.iconColor[1], data.iconColor[2], data.iconColor[3])
        end
        if data.menuColor then
            State.menuColor = Color3.new(data.menuColor[1], data.menuColor[2], data.menuColor[3])
        end
        if data.menuRGB ~= nil then State.menuRGB = data.menuRGB end
        if data.iconRGB ~= nil then State.iconRGB = data.iconRGB end
        if data.language and T[data.language] then State.language = data.language end
    end
end)

-- ███ Init ███
buildUI()

-- Notification
local notif = Instance.new("TextLabel")
notif.Size = UDim2.new(0, 260, 0, 40)
notif.Position = UDim2.new(0.5, -130, 0, 20)
notif.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
notif.TextColor3 = Color3.fromRGB(0, 200, 100)
notif.Font = Enum.Font.GothamBold
notif.TextSize = 14
notif.Text = "✔ Painel Admin carregado!"
notif.BorderSizePixel = 0
notif.Parent = ScreenGui
local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0, 8)
nc.Parent = notif
task.delay(3, function()
    TweenService:Create(notif, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
    task.wait(0.6)
    notif:Destroy()
end)

print("[Painel Admin] Carregado com sucesso!")