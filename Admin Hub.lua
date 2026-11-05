-- ============================================
-- PAINEL ADMIN - VERSAO FORCADA + STATUS/CONFIG
-- Resiste a reset client-side; nao burla anti-cheat server-side
-- ============================================

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local RS      = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
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

-- ============ CONFIG (load antes de construir UI) ============
local CONFIG_FILE = "AdminPanelConfig.json"
local loadedConfig = nil
pcall(function()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local content = readfile(CONFIG_FILE)
        loadedConfig = HttpService:JSONDecode(content)
    end
end)
if _G.__AdminPanelCfg and not loadedConfig then loadedConfig = _G.__AdminPanelCfg end

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
local menuRGBEnabled = false
local iconRGBEnabled = false
local currentLanguage = (loadedConfig and loadedConfig.language) or "pt"
local ctl = {}   -- referencias dos controles para save/load

-- ============ i18n ============
local LANGUAGES = {
    { code = "pt", name = "Português" },
    { code = "en", name = "English"   },
    { code = "es", name = "Español"   },
    { code = "fr", name = "Français"  },
    { code = "de", name = "Deutsch"   },
    { code = "it", name = "Italiano"  },
    { code = "ja", name = "日本語"     },
    { code = "ko", name = "한국어"     },
    { code = "zh", name = "中文"       },
    { code = "ru", name = "Русский"   },
}

local TRANSLATIONS = {
    pt = {
        title="PAINEL ADMIN",
        cat_fisico="Físico", cat_magico="Mágico", cat_visual="Visual",
        cat_status="Status", cat_config="Configurações",
        speed="Velocidade", jump="Pulo", inf_jump="Pulo Infinito",
        teleport="Teleporte", tp_ph="Nome do jogador", tp_btn="TP",
        loop_tp="Loop Teleporte", noclip="Atravessar Paredes",
        get_tp_tool="Pegar TP Tool", gravity="Gravidade Lunar",
        optimize="Otimizar Jogo", esp="ESP Jogadores", xray="Raio X",
        spectate="Espectador", icon_color="Cor do Ícone", menu_color="Cor do Menu",
        menu_rgb="Menu RGB", icon_rgb="Ícone RGB", language="Idioma",
        save="Salvar", saved="Configurações salvas!",
        game_name="Nome do Jogo", players="Jogadores",
        moon_phase="Fase da Lua", server="Servidor", loading="Carregando...",
        moon_new="Nova", moon_waxing_crescent="Crescente Côncava",
        moon_first_quarter="Quarto Crescente", moon_waxing_gibbous="Crescente Gibosa",
        moon_full="Cheia", moon_waning_gibbous="Minguante Gibosa",
        moon_last_quarter="Quarto Minguante", moon_waning_crescent="Minguante Côncava",
    },
    en = {
        title="ADMIN PANEL",
        cat_fisico="Physical", cat_magico="Magic", cat_visual="Visual",
        cat_status="Status", cat_config="Settings",
        speed="Speed", jump="Jump", inf_jump="Infinite Jump",
        teleport="Teleport", tp_ph="Player name", tp_btn="TP",
        loop_tp="Loop Teleport", noclip="Noclip",
        get_tp_tool="Get TP Tool", gravity="Moon Gravity",
        optimize="Optimize Game", esp="Player ESP", xray="X-Ray",
        spectate="Spectate", icon_color="Icon Color", menu_color="Menu Color",
        menu_rgb="Menu RGB", icon_rgb="Icon RGB", language="Language",
        save="Save", saved="Settings saved!",
        game_name="Game Name", players="Players",
        moon_phase="Moon Phase", server="Server", loading="Loading...",
        moon_new="New", moon_waxing_crescent="Waxing Crescent",
        moon_first_quarter="First Quarter", moon_waxing_gibbous="Waxing Gibbous",
        moon_full="Full", moon_waning_gibbous="Waning Gibbous",
        moon_last_quarter="Last Quarter", moon_waning_crescent="Waning Crescent",
    },
    es = {
        title="PANEL ADMIN", cat_fisico="Físico", cat_magico="Mágico",
        cat_visual="Visual", cat_status="Estado", cat_config="Ajustes",
        speed="Velocidad", jump="Salto", inf_jump="Salto Infinito",
        teleport="Teletransporte", tp_ph="Nombre del jugador", tp_btn="TP",
        loop_tp="Bucle TP", noclip="Atravesar Paredes",
        get_tp_tool="Obtener TP Tool", gravity="Gravedad Lunar",
        optimize="Optimizar Juego", esp="ESP Jugadores", xray="Rayos X",
        spectate="Espectador", icon_color="Color del Icono", menu_color="Color del Menú",
        menu_rgb="Menú RGB", icon_rgb="Icono RGB", language="Idioma",
        save="Guardar", saved="¡Guardado!",
        game_name="Nombre del Juego", players="Jugadores",
        moon_phase="Fase Lunar", server="Servidor", loading="Cargando...",
    },
    fr = {
        title="PANNEAU ADMIN", cat_fisico="Physique", cat_magico="Magique",
        cat_visual="Visuel", cat_status="Statut", cat_config="Paramètres",
        speed="Vitesse", jump="Saut", inf_jump="Saut Infini",
        teleport="Téléportation", tp_ph="Nom du joueur", tp_btn="TP",
        loop_tp="Boucle TP", noclip="Traverser les Murs",
        get_tp_tool="Obtenir TP Tool", gravity="Gravité Lunaire",
        optimize="Optimiser le Jeu", esp="ESP Joueurs", xray="Rayons X",
        spectate="Spectateur", icon_color="Couleur de l'Icone", menu_color="Couleur du Menu",
        menu_rgb="Menu RGB", icon_rgb="Icone RGB", language="Langue",
        save="Sauvegarder", saved="Sauvegardé !",
        game_name="Nom du Jeu", players="Joueurs",
        moon_phase="Phase Lunaire", server="Serveur", loading="Chargement...",
    },
    de = {
        title="ADMIN-PANEL", cat_fisico="Physisch", cat_magico="Magisch",
        cat_visual="Visuell", cat_status="Status", cat_config="Einstellungen",
        speed="Geschwindigkeit", jump="Sprung", inf_jump="Unendlicher Sprung",
        teleport="Teleport", tp_ph="Spielername", tp_btn="TP",
        loop_tp="Schleifen-TP", noclip="Durch Wände",
        get_tp_tool="TP-Werkzeug holen", gravity="Mondgravitation",
        optimize="Spiel Optimieren", esp="Spieler-ESP", xray="Röntgen",
        spectate="Zuschauer", icon_color="Symbolfarbe", menu_color="Menüfarbe",
        menu_rgb="Menü RGB", icon_rgb="Symbol RGB", language="Sprache",
        save="Speichern", saved="Gespeichert!",
        game_name="Spielname", players="Spieler",
        moon_phase="Mondphase", server="Server", loading="Lädt...",
    },
    it = {
        title="PANNELLO ADMIN", cat_fisico="Fisico", cat_magico="Magico",
        cat_visual="Visivo", cat_status="Stato", cat_config="Impostazioni",
        speed="Velocità", jump="Salto", inf_jump="Salto Infinito",
        teleport="Teletrasporto", tp_ph="Nome giocatore", tp_btn="TP",
        loop_tp="Loop TP", noclip="Attraversa Muri",
        get_tp_tool="Ottieni TP Tool", gravity="Gravità Lunare",
        optimize="Ottimizza Gioco", esp="ESP Giocatori", xray="Raggi X",
        spectate="Spettatore", icon_color="Colore Icona", menu_color="Colore Menu",
        menu_rgb="Menu RGB", icon_rgb="Icona RGB", language="Lingua",
        save="Salva", saved="Salvato!",
        game_name="Nome Gioco", players="Giocatori",
        moon_phase="Fase Lunare", server="Server", loading="Caricamento...",
    },
    ja = {
        title="管理者パネル", cat_fisico="物理", cat_magico="魔法",
        cat_visual="ビジュアル", cat_status="ステータス", cat_config="設定",
        speed="速度", jump="ジャンプ", inf_jump="無限ジャンプ",
        teleport="テレポート", tp_ph="プレイヤー名", tp_btn="TP",
        loop_tp="ループテレポート", noclip="壁抜け",
        get_tp_tool="TPツールを取得", gravity="月の重力",
        optimize="ゲームを最適化", esp="プレイヤーESP", xray="X線",
        spectate="観戦", icon_color="アイコンの色", menu_color="メニューの色",
        menu_rgb="メニューRGB", icon_rgb="アイコンRGB", language="言語",
        save="保存", saved="保存しました！",
        game_name="ゲーム名", players="プレイヤー",
        moon_phase="月相", server="サーバー", loading="読み込み中...",
    },
    ko = {
        title="관리자 패널", cat_fisico="물리", cat_magico="마법",
        cat_visual="시각", cat_status="상태", cat_config="설정",
        speed="속도", jump="점프", inf_jump="무한 점프",
        teleport="텔레포트", tp_ph="플레이어 이름", tp_btn="TP",
        loop_tp="루프 텔레포트", noclip="벽 통과",
        get_tp_tool="TP 도구 받기", gravity="달 중력",
        optimize="게임 최적화", esp="플레이어 ESP", xray="엑스레이",
        spectate="관전", icon_color="아이콘 색상", menu_color="메뉴 색상",
        menu_rgb="메뉴 RGB", icon_rgb="아이콘 RGB", language="언어",
        save="저장", saved="저장됨!",
        game_name="게임 이름", players="플레이어",
        moon_phase="달 위상", server="서버", loading="로딩 중...",
    },
    zh = {
        title="管理员面板", cat_fisico="物理", cat_magico="魔法",
        cat_visual="视觉", cat_status="状态", cat_config="设置",
        speed="速度", jump="跳跃", inf_jump="无限跳跃",
        teleport="传送", tp_ph="玩家名称", tp_btn="传送",
        loop_tp="循环传送", noclip="穿墙",
        get_tp_tool="获取传送工具", gravity="月球重力",
        optimize="优化游戏", esp="玩家ESP", xray="X光",
        spectate="观战", icon_color="图标颜色", menu_color="菜单颜色",
        menu_rgb="菜单RGB", icon_rgb="图标RGB", language="语言",
        save="保存", saved="已保存！",
        game_name="游戏名称", players="玩家",
        moon_phase="月相", server="服务器", loading="加载中...",
    },
    ru = {
        title="АДМИН-ПАНЕЛЬ", cat_fisico="Физика", cat_magico="Магия",
        cat_visual="Визуал", cat_status="Статус", cat_config="Настройки",
        speed="Скорость", jump="Прыжок", inf_jump="Бесконечный Прыжок",
        teleport="Телепорт", tp_ph="Имя игрока", tp_btn="ТП",
        loop_tp="Цикл ТП", noclip="Сквозь Стены",
        get_tp_tool="Получить ТП-инструмент", gravity="Лунная Гравитация",
        optimize="Оптимизировать Игру", esp="ESP Игроков", xray="Рентген",
        spectate="Наблюдение", icon_color="Цвет Иконки", menu_color="Цвет Меню",
        menu_rgb="Меню RGB", icon_rgb="Иконка RGB", language="Язык",
        save="Сохранить", saved="Сохранено!",
        game_name="Название Игры", players="Игроки",
        moon_phase="Фаза Луны", server="Сервер", loading="Загрузка...",
    },
}

local function T(key)
    local lang = TRANSLATIONS[currentLanguage]
    if lang and lang[key] then return lang[key] end
    if TRANSLATIONS.en and TRANSLATIONS.en[key] then return TRANSLATIONS.en[key] end
    return key
end

local function getLanguageName(code)
    for _, l in ipairs(LANGUAGES) do if l.code == code then return l.name end end
    return code
end

local langRegistry = {}
local function regLabel(obj, key, field)
    table.insert(langRegistry, { obj = obj, key = key, field = field or "Text" })
end
local function applyLanguage()
    for _, r in ipairs(langRegistry) do
        if r.obj and r.obj.Parent ~= nil then
            pcall(function() r.obj[r.field] = T(r.key) end)
        end
    end
end

-- ============ UTILITIES ============
local function getHumanoid()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local lname = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower() == lname or p.DisplayName:lower() == lname) then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():sub(1,#lname) == lname
            or p.DisplayName:lower():sub(1,#lname) == lname) then return p end
    end
    return nil
end

local function tpToPlayer(target)
    if not target or not target.Character or not LP.Character then return end
    local thrp = target.Character:FindFirstChild("HumanoidRootPart")
    local lhrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if thrp and lhrp then
        pcall(function() lhrp.AssemblyLinearVelocity = Vector3.zero end)
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

local function getAimPosition()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local ok, unitRay = pcall(function() return Mouse.UnitRay end)
    if not ok or not unitRay then
        local mh = Mouse.Hit
        return mh and mh.Position
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 10000, params)
    if result then return result.Position end
    local mh = Mouse.Hit
    return mh and mh.Position
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

local function colorToTable(c)
    return { r = math.floor(c.R*255), g = math.floor(c.G*255), b = math.floor(c.B*255) }
end
local function tableToColor(t)
    if not t then return nil end
    return Color3.fromRGB(t.r or 0, t.g or 0, t.b or 0)
end

-- ============ FORCE HOOKS ============
local function hookHumanoidForce(hum)
    if not hum then return end
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if speedEnabled and hum.WalkSpeed ~= speedValue then hum.WalkSpeed = speedValue end
    end)
    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if jumpEnabled and hum.UseJumpPower and hum.JumpPower ~= jumpValue then hum.JumpPower = jumpValue end
    end)
    hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
        if jumpEnabled and not hum.UseJumpPower and hum.JumpHeight ~= jumpValue then hum.JumpHeight = jumpValue end
    end)
    hum:GetPropertyChangedSignal("UseJumpPower"):Connect(function()
        if jumpEnabled then
            if hum.UseJumpPower then hum.JumpPower = jumpValue else hum.JumpHeight = jumpValue end
        end
    end)
end

local function onCharacterAdded(char)
    savedSpeed = nil; savedJump = nil; noclipSaved = {}
    if gravitySaved then
        gravitySaved.useJumpPower = nil; gravitySaved.jumpPower = nil; gravitySaved.jumpHeight = nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if hum then hookHumanoidForce(hum) end
end

LP.CharacterAdded:Connect(onCharacterAdded)
if LP.Character then onCharacterAdded(LP.Character) end

-- ============ ESP ============
local function createESPForPlayer(player)
    if player == LP or espData[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AP_ESP"; billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 250, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true; billboard.Parent = hrp

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
    highlight.Name = "AP_ESP_HL"; highlight.Adornee = char
    highlight.FillColor = teamColor; highlight.FillTransparency = 0.5
    highlight.OutlineColor = teamColor; highlight.OutlineTransparency = 0
    highlight.Parent = char

    espData[player] = { billboard = billboard, highlight = highlight, label = label, char = char }
end

local function destroyESPForPlayer(player)
    local d = espData[player]
    if d then
        if d.billboard then d.billboard:Destroy() end
        if d.highlight then d.highlight:Destroy() end
        espData[player] = nil
    end
end

local function refreshESPForPlayer(player)
    if player == LP then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local d = espData[player]
    if not hrp then if d then destroyESPForPlayer(player) end return end
    local broken = false
    if not d then broken = true
    elseif not d.billboard or not d.billboard.Parent then broken = true
    elseif d.billboard.Adornee ~= hrp then broken = true
    elseif not d.highlight or not d.highlight.Parent or d.char ~= char then broken = true end
    if broken then
        destroyESPForPlayer(player)
        createESPForPlayer(player)
    end
end

local function refreshAllESP()
    if not espEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do refreshESPForPlayer(p) end
end

local function tryCreateESPLoop(player)
    task.spawn(function()
        for _ = 1, 30 do
            if not espEnabled then return end
            if player.Parent ~= Players then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then refreshESPForPlayer(player); return end
            task.wait(0.1)
        end
    end)
end

local espHooked = {}
local function hookPlayerESP(player)
    if player == LP or espHooked[player] then return end
    espHooked[player] = true
    player.CharacterAdded:Connect(function()
        destroyESPForPlayer(player)
        if espEnabled then tryCreateESPLoop(player) end
    end)
    player.CharacterRemoving:Connect(function() destroyESPForPlayer(player) end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayerESP(p) end
Players.PlayerAdded:Connect(function(p)
    hookPlayerESP(p)
    if espEnabled then tryCreateESPLoop(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    destroyESPForPlayer(p); espHooked[p] = nil
    if spectateEnabled and spectateTarget ~= "" then
        local match = (p.Name:lower() == spectateTarget:lower()
                    or p.DisplayName:lower() == spectateTarget:lower())
        if match then
            spectateEnabled = false; spectateTarget = ""; restoreCamera()
        end
    end
end)

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

-- aplica config carregada nas cores
if loadedConfig then
    local c1 = tableToColor(loadedConfig.iconColor)
    if c1 then Icon.BackgroundColor3 = c1 end
    local c2 = tableToColor(loadedConfig.menuColor)
    if c2 then Menu.BackgroundColor3 = c2 end
end

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
Title.Text = T("title")
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = TitleBar
regLabel(Title, "title")

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -33, 0.5, -13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0; CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Menu.Visible = false end)
makeDraggable(Menu, TitleBar)

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
leftPad.PaddingTop = UDim.new(0, 6); leftPad.PaddingLeft = UDim.new(0, 6); leftPad.PaddingRight = UDim.new(0, 6)
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
local function createToggle(parent, labelKey, callback, initialState)
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
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 24)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    local function setState(v, fire)
        state = v and true or false
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if fire and callback then callback(state) end
    end
    if initialState then setState(true, false) end

    btn.MouseButton1Click:Connect(function() setState(not state, true) end)
    return {
        row = row,
        setState = setState,
        getState = function() return state end,
    }
end

local function createInputNumToggle(parent, labelKey, defaultVal, callback, initState, initVal)
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
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 80, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Text = tostring(initVal or defaultVal)
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13
    tb.BorderSizePixel = 0; tb.ClearTextOnFocus = true
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 24)
    btn.Position = UDim2.new(1, -65, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    local value = tonumber(initVal or defaultVal)

    local function setState(s, v, fire)
        state = s and true or false
        if v then value = v; tb.Text = tostring(v) end
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if fire and callback then callback(state, value) end
    end
    if initState then setState(true, value, false) end

    tb.FocusLost:Connect(function()
        local n = tonumber(tb.Text)
        if n then
            value = n
            if callback then callback(state, value) end
        elseif value then
            tb.Text = tostring(value)
        end
    end)

    btn.MouseButton1Click:Connect(function() setState(not state, nil, true) end)

    return {
        row = row,
        setState = setState,
        getState = function() return state end,
        getValue = function() return value end,
    }
end

local function createInputButton(parent, labelKey, placeholderKey, btnText, callback)
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
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 130, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.PlaceholderText = T(placeholderKey)
    tb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)
    regLabel(tb, placeholderKey, "PlaceholderText")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 24)
    btn.Position = UDim2.new(1, -80, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    btn.Text = btnText; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() if callback then callback(tb.Text) end end)
    return row
end

local function createInputTextToggle(parent, labelKey, placeholderKey, callback, initState, initText)
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
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(0, 130, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Text = initText or ""
    tb.PlaceholderText = T(placeholderKey)
    tb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)
    regLabel(tb, placeholderKey, "PlaceholderText")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 24)
    btn.Position = UDim2.new(1, -80, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = "OFF"; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = false
    local function setState(s, text, fire)
        state = s and true or false
        if text ~= nil then tb.Text = text end
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if fire and callback then callback(state, tb.Text) end
    end
    if initState then setState(true, initText, false) end

    tb.FocusLost:Connect(function() if callback then callback(state, tb.Text) end end)
    btn.MouseButton1Click:Connect(function() setState(not state, nil, true) end)

    return {
        row = row,
        setState = setState,
        getState = function() return state end,
        getText = function() return tb.Text end,
    }
end

local function createButton(parent, labelKey, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    btn.Text = T(labelKey); btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    regLabel(btn, labelKey)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return btn
end

-- ============ COLOR PALETTE ============
local COLORS = {
    { name = "Red",    color = Color3.fromRGB(255, 60, 60)  },
    { name = "Orange", color = Color3.fromRGB(255, 140, 60) },
    { name = "Yellow", color = Color3.fromRGB(255, 220, 60) },
    { name = "Green",  color = Color3.fromRGB(60, 200, 100) },
    { name = "Cyan",   color = Color3.fromRGB(60, 200, 220) },
    { name = "Blue",   color = Color3.fromRGB(60, 140, 255) },
    { name = "Purple", color = Color3.fromRGB(160, 80, 220) },
    { name = "Pink",   color = Color3.fromRGB(240, 100, 180)},
    { name = "White",  color = Color3.fromRGB(240, 240, 240)},
    { name = "Black",  color = Color3.fromRGB(30, 30, 30)  },
}

local function createColorPalette(parent, labelKey, callback, currentColor)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -120, 1, 0)
    cont.Position = UDim2.new(0, 115, 0, 0)
    cont.BackgroundTransparency = 1
    cont.Parent = row
    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.Padding = UDim.new(0, 4)
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Parent = cont

    local swatches = {}
    for _, c in ipairs(COLORS) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 22, 0, 22)
        sw.BackgroundColor3 = c.color
        sw.Text = ""
        sw.BorderSizePixel = 1
        sw.BorderColor3 = Color3.fromRGB(80, 80, 80)
        sw.AutoButtonColor = false
        sw.Parent = cont
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 3)
        swatches[c.name] = sw
        sw.MouseButton1Click:Connect(function()
            if callback then callback(c.color) end
            for _, s in pairs(swatches) do s.BorderColor3 = Color3.fromRGB(80, 80, 80); s.BorderSizePixel = 1 end
            sw.BorderColor3 = Color3.new(1, 1, 1); sw.BorderSizePixel = 2
        end)
    end
    -- marca cor atual
    if currentColor then
        for name, s in pairs(swatches) do
            if (s.BackgroundColor3 - currentColor).Magnitude < 0.05 then
                s.BorderColor3 = Color3.new(1, 1, 1); s.BorderSizePixel = 2
            end
        end
    end
    return row
end

-- ============ STATUS HELPERS ============
local function getMoonPhaseKey()
    local ok, phase = pcall(function() return Lighting:GetMoonPhase() end)
    if not ok or not phase then return nil end
    local map = {
        [Enum.MoonPhase.New]             = "moon_new",
        [Enum.MoonPhase.WaxingCrescent]  = "moon_waxing_crescent",
        [Enum.MoonPhase.FirstQuarter]    = "moon_first_quarter",
        [Enum.MoonPhase.WaxingGibbous]   = "moon_waxing_gibbous",
        [Enum.MoonPhase.Full]            = "moon_full",
        [Enum.MoonPhase.WaningGibbous]   = "moon_waning_gibbous",
        [Enum.MoonPhase.LastQuarter]     = "moon_last_quarter",
        [Enum.MoonPhase.WaningCrescent]  = "moon_waning_crescent",
    }
    return map[phase], phase
end

local function makeInfoRow(parent, labelKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 140, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -160, 1, 0)
    val.Position = UDim2.new(0, 150, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = "..."
    val.TextColor3 = Color3.new(1, 1, 1)
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Font = Enum.Font.GothamBold; val.TextSize = 13
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = row

    return row, val
end

-- ============ BUILDERS ============
local function buildFisico(parent)
    ctl.speed = createInputNumToggle(parent, "speed", "16", function(state, value)
        speedEnabled = state
        if value then speedValue = value end
        if not state then
            local hum = getHumanoid()
            if hum and savedSpeed ~= nil then hum.WalkSpeed = savedSpeed end
            savedSpeed = nil
        end
    end,
    loadedConfig and loadedConfig.speed and loadedConfig.speed.enabled,
    loadedConfig and loadedConfig.speed and loadedConfig.speed.value)

    ctl.jump = createInputNumToggle(parent, "jump", "50", function(state, value)
        jumpEnabled = state
        if value then jumpValue = value end
        if not state then
            local hum = getHumanoid()
            if hum and savedJump then
                hum.UseJumpPower = savedJump.useJumpPower
                hum.JumpPower   = savedJump.jumpPower
                hum.JumpHeight  = savedJump.jumpHeight
            end
            savedJump = nil
        else
            local hum = getHumanoid()
            if hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end) end
        end
    end,
    loadedConfig and loadedConfig.jump and loadedConfig.jump.enabled,
    loadedConfig and loadedConfig.jump and loadedConfig.jump.value)

    ctl.infJump = createToggle(parent, "inf_jump", function(state)
        infJumpEnabled = state
        local hum = getHumanoid()
        if state and hum then pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end) end
    end, loadedConfig and loadedConfig.infJump)
end

local function buildMagico(parent)
    createInputButton(parent, "teleport", "tp_ph", "TP", function(name)
        local target = findPlayerByName(name)
        if target then tpToPlayer(target) end
    end)

    ctl.loopTP = createInputTextToggle(parent, "loop_tp", "tp_ph", function(state, name)
        loopTPEnabled = state
        loopTPTarget = name or ""
    end,
    loadedConfig and loadedConfig.loopTP and loadedConfig.loopTP.enabled,
    loadedConfig and loadedConfig.loopTP and loadedConfig.loopTP.target)

    ctl.noclip = createToggle(parent, "noclip", function(state)
        noclipEnabled = state
        if not state then
            for part, saved in pairs(noclipSaved) do
                if part and part.Parent then part.CanCollide = saved end
            end
            noclipSaved = {}
        end
    end, loadedConfig and loadedConfig.noclip)

    createButton(parent, "get_tp_tool", function()
        local bp = LP:FindFirstChildOfClass("Backpack")
        if not bp then return end
        local existing = bp:FindFirstChild("TP Tool")
        if existing then existing:Destroy() end

        local tool = Instance.new("Tool")
        tool.Name = "TP Tool"
        tool.RequiresHandle = false
        tool.CanBeDropped = false
        tool.Activated:Connect(function()
            local pos = getAimPosition()
            if pos and LP.Character then
                local lhrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if lhrp then
                    pcall(function() lhrp.AssemblyLinearVelocity = Vector3.zero end)
                    lhrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                end
            end
        end)
        tool.Parent = bp
    end)

    ctl.gravity = createToggle(parent, "gravity", function(state) gravityEnabled = state end,
        loadedConfig and loadedConfig.gravity)
end

local function buildVisual(parent)
    createButton(parent, "optimize", function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                for _, c in ipairs(obj:GetChildren()) do
                    if c:IsA("Texture") or c:IsA("Decal") or c:IsA("SurfaceAppearance") then c:Destroy() end
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

    ctl.esp = createToggle(parent, "esp", function(state)
        espEnabled = state
        if state then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then tryCreateESPLoop(p) end
            end
        else
            local list = {}
            for p in pairs(espData) do table.insert(list, p) end
            for _, p in ipairs(list) do destroyESPForPlayer(p) end
        end
    end, loadedConfig and loadedConfig.esp)

    ctl.xray = createToggle(parent, "xray", function(state)
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
    end, loadedConfig and loadedConfig.xray)

    ctl.spectate = createInputTextToggle(parent, "spectate", "tp_ph", function(state, name)
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
    end,
    loadedConfig and loadedConfig.spectate and loadedConfig.spectate.enabled,
    loadedConfig and loadedConfig.spectate and loadedConfig.spectate.target)
end

-- ============ STATUS CATEGORY ============
local function buildStatus(parent)
    local _, gameNameVal  = makeInfoRow(parent, "game_name")
    local _, playersVal   = makeInfoRow(parent, "players")
    local _, moonVal      = makeInfoRow(parent, "moon_phase")
    local _, serverVal    = makeInfoRow(parent, "server")

    local cachedGameName = game.Name
    task.spawn(function()
        local ok, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if ok and info and info.Name and info.Name ~= "" then
            cachedGameName = info.Name
        end
    end)

    local function update()
        if not parent or not parent.Parent then return end
        gameNameVal.Text = cachedGameName
        playersVal.Text  = string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers)
        local key = getMoonPhaseKey()
        moonVal.Text = key and T(key) or "N/A"
        local jid = game.JobId
        if jid == nil or jid == "" then
            serverVal.Text = "Studio / Local"
        else
            serverVal.Text = jid
        end
    end
    update()
    task.spawn(function()
        while parent and parent.Parent do
            task.wait(1)
            update()
        end
    end)
end

-- ============ SETTINGS CATEGORY ============
local function saveConfig()
    local cfg = {
        iconColor = colorToTable(Icon.BackgroundColor3),
        menuColor = colorToTable(Menu.BackgroundColor3),
        menuRGB   = menuRGBEnabled,
        iconRGB   = iconRGBEnabled,
        language  = currentLanguage,
        speed     = ctl.speed and { enabled = ctl.speed.getState(), value = ctl.speed.getValue() } or nil,
        jump      = ctl.jump  and { enabled = ctl.jump.getState(),  value = ctl.jump.getValue()  } or nil,
        infJump   = ctl.infJump and ctl.infJump.getState() or nil,
        noclip    = ctl.noclip and ctl.noclip.getState() or nil,
        loopTP    = ctl.loopTP and { enabled = ctl.loopTP.getState(), target = ctl.loopTP.getText() } or nil,
        gravity   = ctl.gravity and ctl.gravity.getState() or nil,
        esp       = ctl.esp and ctl.esp.getState() or nil,
        xray      = ctl.xray and ctl.xray.getState() or nil,
        spectate  = ctl.spectate and { enabled = ctl.spectate.getState(), target = ctl.spectate.getText() } or nil,
    }
    _G.__AdminPanelCfg = cfg
    local ok, encoded = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok and encoded then
        pcall(function()
            if writefile then writefile(CONFIG_FILE, encoded) end
        end)
    end
    -- toast
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 250, 0, 34)
    toast.Position = UDim2.new(0.5, -125, 1, -50)
    toast.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    toast.TextColor3 = Color3.new(1, 1, 1)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 14
    toast.Text = T("saved")
    toast.Parent = gui
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
    toast.ZIndex = 50
    task.spawn(function()
        for i = 1, 20 do
            toast.BackgroundTransparency = i / 20
            toast.TextTransparency = i / 20
            task.wait(0.05)
        end
        toast:Destroy()
    end)
end

local function buildSettings(parent)
    createColorPalette(parent, "icon_color", function(color)
        Icon.BackgroundColor3 = color
    end, Icon.BackgroundColor3)

    createColorPalette(parent, "menu_color", function(color)
        Menu.BackgroundColor3 = color
        TitleBar.BackgroundColor3 = color
        TitleBarCover.BackgroundColor3 = color
    end, Menu.BackgroundColor3)

    ctl.menuRGB = createToggle(parent, "menu_rgb", function(state)
        menuRGBEnabled = state
        if not state then menuStroke.Color = Color3.fromRGB(70, 70, 70) end
    end, loadedConfig and loadedConfig.menuRGB or false)

    ctl.iconRGB = createToggle(parent, "icon_rgb", function(state)
        iconRGBEnabled = state
        if not state then iconStroke.Color = Color3.fromRGB(80, 80, 80) end
    end, loadedConfig and loadedConfig.iconRGB or false)

    -- Language selector
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
    lbl.Text = T("language")
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, "language")

    local langBtn = Instance.new("TextButton")
    langBtn.Size = UDim2.new(0, 150, 0, 24)
    langBtn.Position = UDim2.new(1, -160, 0.5, -12)
    langBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    langBtn.Text = getLanguageName(currentLanguage)
    langBtn.TextColor3 = Color3.new(1, 1, 1)
    langBtn.Font = Enum.Font.GothamBold; langBtn.TextSize = 12
    langBtn.BorderSizePixel = 0; langBtn.AutoButtonColor = false
    langBtn.Parent = row
    Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 4)

    local dropdown
    local function closeDropdown()
        if dropdown then dropdown:Destroy(); dropdown = nil end
    end

    langBtn.MouseButton1Click:Connect(function()
        if dropdown then closeDropdown(); return end
        dropdown = Instance.new("Frame")
        dropdown.Size = UDim2.new(0, 150, 0, #LANGUAGES * 26 + 4)
        dropdown.Position = UDim2.fromOffset(
            langBtn.AbsolutePosition.X,
            langBtn.AbsolutePosition.Y + langBtn.AbsoluteSize.Y + 2
        )
        dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdown.BorderSizePixel = 0
        dropdown.ZIndex = 30
        dropdown.Parent = gui
        Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", dropdown).Color = Color3.fromRGB(90, 90, 90)

        local ll = Instance.new("UIListLayout")
        ll.Parent = dropdown

        for _, lang in ipairs(LANGUAGES) do
            local opt = Instance.new("TextButton")
            opt.Size = UDim2.new(1, 0, 0, 26)
            opt.BackgroundTransparency = 1
            opt.Text = lang.name
            opt.TextColor3 = Color3.new(1, 1, 1)
            opt.Font = Enum.Font.Gotham; opt.TextSize = 12
            opt.ZIndex = 30
            opt.Parent = dropdown
            opt.MouseButton1Click:Connect(function()
                currentLanguage = lang.code
                applyLanguage()
                langBtn.Text = lang.name
                closeDropdown()
            end)
        end
    end)

    -- fecha dropdown clicando fora
    UIS.InputBegan:Connect(function(input)
        if dropdown and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position
            local ap = dropdown.AbsolutePosition
            local as = dropdown.AbsoluteSize
            if pos.X < ap.X or pos.X > ap.X + as.X or pos.Y < ap.Y or pos.Y > ap.Y + as.Y then
                closeDropdown()
            end
        end
    end)

    -- Save button
    createButton(parent, "save", function() saveConfig() end)
end

-- ============ CATEGORIES ============
local categories = {
    { name = "Físico",        key = "cat_fisico", builder = buildFisico },
    { name = "Mágico",        key = "cat_magico", builder = buildMagico },
    { name = "Visual",        key = "cat_visual", builder = buildVisual },
    { name = "Status",        key = "cat_status", builder = buildStatus },
    { name = "Configurações", key = "cat_config", builder = buildSettings },
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
    btn.Text = T(cat.key)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = LeftPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    regLabel(btn, cat.key)
    btn.MouseButton1Click:Connect(function() selectCategory(cat) end)
    categoryBtns[cat.name] = btn
end
selectCategory(categories[1])

-- ============ FEATURE LOOPS ============
RS.Stepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if speedEnabled then
        if savedSpeed == nil then savedSpeed = hum.WalkSpeed end
        if hum.WalkSpeed ~= speedValue then hum.WalkSpeed = speedValue end
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
            if hum.JumpPower ~= jumpValue then hum.JumpPower = jumpValue end
        else
            if hum.JumpHeight ~= jumpValue then hum.JumpHeight = jumpValue end
        end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
    end

    if infJumpEnabled then
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
    end

    if noclipEnabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipSaved[part] == nil then noclipSaved[part] = part.CanCollide end
                if part.CanCollide then part.CanCollide = false end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end)
        end
    end
end)

local _spaceWasDown = false
RS.Stepped:Connect(function()
    if not infJumpEnabled then _spaceWasDown = UIS:IsKeyDown(Enum.KeyCode.Space); return end
    local spaceDown = UIS:IsKeyDown(Enum.KeyCode.Space)
    if spaceDown and not _spaceWasDown then
        local hum = getHumanoid()
        if hum then
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.Freefall
                or st == Enum.HumanoidStateType.FallingDown
                or st == Enum.HumanoidStateType.Jumping then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                local lhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if lhrp then
                    local power = math.clamp(hum.JumpPower > 0 and hum.JumpPower or 50, 30, 100)
                    lhrp.AssemblyLinearVelocity = Vector3.new(
                        lhrp.AssemblyLinearVelocity.X, power, lhrp.AssemblyLinearVelocity.Z
                    )
                end
            end
        end
    end
    _spaceWasDown = spaceDown
end)

RS.Heartbeat:Connect(function()
    if loopTPEnabled and loopTPTarget ~= "" then
        local target = findPlayerByName(loopTPTarget)
        if target then tpToPlayer(target) end
    end
end)

RS.Heartbeat:Connect(function()
    if not espEnabled then return end
    for p, d in pairs(espData) do
        if p.Character and d.label and d.label.Parent then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                d.label.Text = string.format("%s [%d/%d]",
                    p.Name, math.floor(hum.Health), math.floor(hum.MaxHealth))
            end
        end
    end
end)

RS.Stepped:Connect(function()
    if gravityEnabled then
        local hum = getHumanoid()
        if hum then
            if gravitySaved == nil then gravitySaved = { gravity = Workspace.Gravity } end
            if gravitySaved.useJumpPower == nil then
                gravitySaved.useJumpPower = hum.UseJumpPower
                gravitySaved.jumpPower = hum.JumpPower
                gravitySaved.jumpHeight = hum.JumpHeight
            end
            local targetGravity = gravitySaved.gravity * GRAVITY_FACTOR
            if Workspace.Gravity ~= targetGravity then Workspace.Gravity = targetGravity end
            if gravitySaved.useJumpPower then
                local basePower = jumpEnabled and jumpValue or gravitySaved.jumpPower
                local target = basePower * math.sqrt(GRAVITY_FACTOR)
                if hum.JumpPower ~= target then hum.JumpPower = target end
            else
                local target = jumpEnabled and jumpValue or gravitySaved.jumpHeight
                if hum.JumpHeight ~= target then hum.JumpHeight = target end
            end
        end
    elseif gravitySaved ~= nil then
        Workspace.Gravity = gravitySaved.gravity
        local hum = getHumanoid()
        if hum and gravitySaved.useJumpPower ~= nil then
            hum.UseJumpPower = gravitySaved.useJumpPower
            hum.JumpPower = gravitySaved.jumpPower
            hum.JumpHeight = gravitySaved.jumpHeight
        end
        gravitySaved = nil
    end
end)

RS.RenderStepped:Connect(function()
    if not spectateEnabled or spectateTarget == "" then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local target = findPlayerByName(spectateTarget)
    if target and target.Character then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum and camera.CameraSubject ~= hum then camera.CameraSubject = hum end
        if camera.CameraType ~= Enum.CameraType.Custom then camera.CameraType = Enum.CameraType.Custom end
    end
end)

-- ============ RGB ANIMATION ============
local rgbT = 0
RS.RenderStepped:Connect(function(dt)
    rgbT = rgbT + dt
    if menuRGBEnabled then
        local h = (rgbT * 0.2) % 1
        menuStroke.Color = Color3.fromHSV(h, 1, 1)
    end
    if iconRGBEnabled then
        local h = (rgbT * 0.2 + 0.5) % 1
        iconStroke.Color = Color3.fromHSV(h, 1, 1)
    end
end)

-- ============ BACKGROUND LOOPS ============
task.spawn(function()
    while true do
        task.wait(0.25)
        if xrayEnabled then
            for obj in pairs(xraySaved) do
                if obj and obj.Parent and obj.Transparency ~= 0.75 then
                    obj.Transparency = 0.75
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        refreshAllESP()
        task.wait(1)
    end
end)