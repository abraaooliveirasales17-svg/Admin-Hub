--[[ ============================================
     AP ADMIN PANEL
     Script completo com TODAS as funcionalidades
     ============================================ ]]

-- Serviços
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RS           = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local HttpService  = game:GetService("HttpService")
local MPS          = game:GetService("MarketplaceService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Cleanup anterior
local old = PG:FindFirstChild("AP_AdminPanel")
if old then old:Destroy() end

-- ================= CONFIG (SALVAR/CARREGAR) =================
local CONFIG_FILE = "AP_AdminPanel_Config.json"
local Config = {
    IconColor = {0, 0, 0},
    MenuColor = {20, 20, 25},
    MenuRGB   = false,
    IconRGB   = false,
    Language  = "pt",
}

if isfile and readfile and isfile(CONFIG_FILE) then
    pcall(function()
        local d = HttpService:JSONDecode(readfile(CONFIG_FILE))
        for k, v in pairs(d) do Config[k] = v end
    end)
end

local function saveCfg()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        end)
    end
end

-- ================= TRADUÇÕES (12 idiomas) =================
local Trans = {
    pt = {cat_phys="Físico",cat_magic="Mágico",cat_visual="Visual",cat_status="Status",cat_config="Configurações",
        speed="Alterar Velocidade",jump="Alterar Pulo",infjump="Pulo Infinito",
        tp="Teleporte",looptp="Loop Teleporte",noclip="Atravessar",tptool="TP Tool",
        optimize="Otimizar",esp="ESP",xray="Raio X",
        gamename="Nome do Jogo",playercount="Jogadores",moonstate="Estado da Lua",servername="Nome do Servidor",
        iconcolor="Cor do Ícone",menucolor="Cor do Menu",menurgb="Menu RGB",iconrgb="Ícone RGB",language="Idioma",save="Salvar",
        on="Ativar",off="Desativar",tp_btn="Teleportar",give_tool="Dar Tool",
        quantity="Quantidade",player_name="Nome do Jogador",apply="Aplicar",
        select_lang="Selecionar Idioma",max_players="Máximo",current_players="Atuais",
        saved="Salvo com sucesso!",not_found="Jogador não encontrado"},

    en = {cat_phys="Physical",cat_magic="Magic",cat_visual="Visual",cat_status="Status",cat_config="Settings",
        speed="Change Speed",jump="Change Jump",infjump="Infinite Jump",
        tp="Teleport",looptp="Loop Teleport",noclip="Noclip",tptool="TP Tool",
        optimize="Optimize",esp="ESP",xray="X-Ray",
        gamename="Game Name",playercount="Players",moonstate="Moon State",servername="Server Name",
        iconcolor="Icon Color",menucolor="Menu Color",menurgb="Menu RGB",iconrgb="Icon RGB",language="Language",save="Save",
        on="Enable",off="Disable",tp_btn="Teleport",give_tool="Give Tool",
        quantity="Amount",player_name="Player Name",apply="Apply",
        select_lang="Select Language",max_players="Max",current_players="Current",
        saved="Saved successfully!",not_found="Player not found"},

    es = {cat_phys="Físico",cat_magic="Mágico",cat_visual="Visual",cat_status="Estado",cat_config="Ajustes",
        speed="Cambiar Velocidad",jump="Cambiar Salto",infjump="Salto Infinito",
        tp="Teletransporte",looptp="Loop TP",noclip="Atravesar",tptool="TP Tool",
        optimize="Optimizar",esp="ESP",xray="Rayos X",
        gamename="Nombre del Juego",playercount="Jugadores",moonstate="Estado Luna",servername="Servidor",
        iconcolor="Color Icono",menucolor="Color Menú",menurgb="Menú RGB",iconrgb="Icono RGB",language="Idioma",save="Guardar",
        on="Activar",off="Desactivar",tp_btn="Teletransportar",give_tool="Dar Tool",
        quantity="Cantidad",player_name="Nombre",apply="Aplicar",
        select_lang="Idioma",max_players="Máx",current_players="Actuales",
        saved="¡Guardado!",not_found="Jugador no encontrado"},

    fr = {cat_phys="Physique",cat_magic="Magique",cat_visual="Visuel",cat_status="Statut",cat_config="Paramètres",
        speed="Vitesse",jump="Saut",infjump="Saut Infini",
        tp="Téléportation",looptp="Boucle TP",noclip="Traverser",tptool="TP Tool",
        optimize="Optimiser",esp="ESP",xray="Rayons X",
        gamename="Nom du Jeu",playercount="Joueurs",moonstate="État Lune",servername="Serveur",
        iconcolor="Couleur Icône",menucolor="Couleur Menu",menurgb="Menu RGB",iconrgb="Icône RGB",language="Langue",save="Sauver",
        on="Activer",off="Désactiver",tp_btn="Téléporter",give_tool="Donner Tool",
        quantity="Quantité",player_name="Nom",apply="Appliquer",
        select_lang="Langue",max_players="Max",current_players="Actuels",
        saved="Sauvegardé!",not_found="Joueur introuvable"},

    de = {cat_phys="Physisch",cat_magic="Magisch",cat_visual="Visuell",cat_status="Status",cat_config="Einstellungen",
        speed="Geschwindigkeit",jump="Sprung",infjump="Unendlich Springen",
        tp="Teleport",looptp="Loop TP",noclip="Durchgehen",tptool="TP Tool",
        optimize="Optimieren",esp="ESP",xray="Röntgen",
        gamename="Spielname",playercount="Spieler",moonstate="Mondstatus",servername="Server",
        iconcolor="Icon Farbe",menucolor="Menü Farbe",menurgb="Menü RGB",iconrgb="Icon RGB",language="Sprache",save="Speichern",
        on="Aktivieren",off="Deaktivieren",tp_btn="Teleportieren",give_tool="Tool geben",
        quantity="Menge",player_name="Name",apply="Anwenden",
        select_lang="Sprache",max_players="Max",current_players="Aktuell",
        saved="Gespeichert!",not_found="Spieler nicht gefunden"},

    it = {cat_phys="Fisico",cat_magic="Magico",cat_visual="Visuale",cat_status="Stato",cat_config="Impostazioni",
        speed="Velocità",jump="Salto",infjump="Salto Infinito",
        tp="Teletrasporto",looptp="Loop TP",noclip="Attraversa",tptool="TP Tool",
        optimize="Ottimizza",esp="ESP",xray="Raggi X",
        gamename="Nome Gioco",playercount="Giocatori",moonstate="Stato Luna",servername="Server",
        iconcolor="Colore Icona",menucolor="Colore Menu",menurgb="Menu RGB",iconrgb="Icona RGB",language="Lingua",save="Salva",
        on="Attiva",off="Disattiva",tp_btn="Teletrasporta",give_tool="Dai Tool",
        quantity="Quantità",player_name="Nome",apply="Applica",
        select_lang="Lingua",max_players="Max",current_players="Attuali",
        saved="Salvato!",not_found="Giocatore non trovato"},

    ru = {cat_phys="Физика",cat_magic="Магия",cat_visual="Визуал",cat_status="Статус",cat_config="Настройки",
        speed="Скорость",jump="Прыжок",infjump="Беск. Прыжок",
        tp="Телепорт",looptp="Цикл TP",noclip="Сквозь стены",tptool="TP Tool",
        optimize="Оптимизация",esp="ESP",xray="Рентген",
        gamename="Название игры",playercount="Игроки",moonstate="Состояние луны",servername="Сервер",
        iconcolor="Цвет иконки",menucolor="Цвет меню",menurgb="Меню RGB",iconrgb="Иконка RGB",language="Язык",save="Сохранить",
        on="Вкл",off="Выкл",tp_btn="Телепорт",give_tool="Дать Tool",
        quantity="Кол-во",player_name="Имя",apply="Применить",
        select_lang="Язык",max_players="Макс",current_players="Сейчас",
        saved="Сохранено!",not_found="Игрок не найден"},

    ja = {cat_phys="物理",cat_magic="魔法",cat_visual="ビジュアル",cat_status="ステータス",cat_config="設定",
        speed="速度変更",jump="ジャンプ変更",infjump="無限ジャンプ",
        tp="テレポート",looptp="ループTP",noclip="壁抜け",tptool="TPツール",
        optimize="最適化",esp="ESP",xray="X線",
        gamename="ゲーム名",playercount="プレイヤー",moonstate="月の状態",servername="サーバー名",
        iconcolor="アイコン色",menucolor="メニュー色",menurgb="メニューRGB",iconrgb="アイコンRGB",language="言語",save="保存",
        on="有効",off="無効",tp_btn="テレポート",give_tool="ツール取得",
        quantity="数量",player_name="名前",apply="適用",
        select_lang="言語選択",max_players="最大",current_players="現在",
        saved="保存しました!",not_found="プレイヤーが見つかりません"},

    zh = {cat_phys="物理",cat_magic="魔法",cat_visual="视觉",cat_status="状态",cat_config="设置",
        speed="修改速度",jump="修改跳跃",infjump="无限跳跃",
        tp="传送",looptp="循环传送",noclip="穿墙",tptool="TP工具",
        optimize="优化",esp="ESP",xray="透视",
        gamename="游戏名称",playercount="玩家",moonstate="月亮状态",servername="服务器",
        iconcolor="图标颜色",menucolor="菜单颜色",menurgb="菜单RGB",iconrgb="图标RGB",language="语言",save="保存",
        on="启用",off="禁用",tp_btn="传送",give_tool="给予工具",
        quantity="数量",player_name="名字",apply="应用",
        select_lang="选择语言",max_players="最大",current_players="当前",
        saved="已保存!",not_found="找不到玩家"},

    ko = {cat_phys="물리",cat_magic="마법",cat_visual="시각",cat_status="상태",cat_config="설정",
        speed="속도 변경",jump="점프 변경",infjump="무한 점프",
        tp="텔레포트",looptp="루프 TP",noclip="벽 통과",tptool="TP 도구",
        optimize="최적화",esp="ESP",xray="엑스레이",
        gamename="게임 이름",playercount="플레이어",moonstate="달 상태",servername="서버",
        iconcolor="아이콘 색",menucolor="메뉴 색",menurgb="메뉴 RGB",iconrgb="아이콘 RGB",language="언어",save="저장",
        on="활성화",off="비활성화",tp_btn="텔레포트",give_tool="도구 지급",
        quantity="수량",player_name="이름",apply="적용",
        select_lang="언어 선택",max_players="최대",current_players="현재",
        saved="저장됨!",not_found="플레이어를 찾을 수 없음"},

    ar = {cat_phys="جسدي",cat_magic="سحري",cat_visual="بصري",cat_status="الحالة",cat_config="الإعدادات",
        speed="تغيير السرعة",jump="تغيير القفز",infjump="قفز لا نهائي",
        tp="انتقال",looptp="حلقة انتقال",noclip="اختراق",tptool="أداة TP",
        optimize="تحسين",esp="ESP",xray="أشعة سينية",
        gamename="اسم اللعبة",playercount="اللاعبون",moonstate="حالة القمر",servername="السيرفر",
        iconcolor="لون الأيقونة",menucolor="لون القائمة",menurgb="قائمة RGB",iconrgb="أيقونة RGB",language="اللغة",save="حفظ",
        on="تفعيل",off="تعطيل",tp_btn="انتقال",give_tool="إعطاء أداة",
        quantity="الكمية",player_name="الاسم",apply="تطبيق",
        select_lang="اختر اللغة",max_players="الأقصى",current_players="الحالي",
        saved="تم الحفظ!",not_found="لم يتم العثور"},

    hi = {cat_phys="शारीरिक",cat_magic="जादुई",cat_visual="दृश्य",cat_status="स्थिति",cat_config="सेटिंग्स",
        speed="गति बदलें",jump="कूद बदलें",infjump="अनंत कूद",
        tp="टेलीपोर्ट",looptp="लूप TP",noclip="दीवार पार",tptool="TP टूल",
        optimize="अनुकूलित",esp="ESP",xray="एक्स-रे",
        gamename="गेम का नाम",playercount="खिलाड़ी",moonstate="चांद स्थिति",servername="सर्वर",
        iconcolor="आइकन रंग",menucolor="मेनू रंग",menurgb="मेनू RGB",iconrgb="आइकन RGB",language="भाषा",save="सहेजें",
        on="सक्रिय",off="निष्क्रिय",tp_btn="टेलीपोर्ट",give_tool="टूल दें",
        quantity="मात्रा",player_name="नाम",apply="लागू करें",
        select_lang="भाषा चुनें",max_players="अधिकतम",current_players="वर्तमान",
        saved="सहेजा गया!",not_found="खिलाड़ी नहीं मिला"},
}

local function tr(k)
    local lang = Trans[Config.Language] or Trans.pt
    return lang[k] or Trans.pt[k] or k
end

local function C3(t) return Color3.fromRGB(t[1], t[2], t[3]) end

-- ================= HELPERS =================
local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then pcall(function() inst[k] = v end) end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(inst, r)
    return new("UICorner", {Parent = inst, CornerRadius = UDim.new(0, r or 6)})
end

local function makeDraggable(frame, handle, onClick)
    handle = handle or frame
    local dragging, dragStart, startPos, moved
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; moved = false
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging and not moved and onClick then onClick() end
                    dragging = false
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then moved = true end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ================= GUI PRINCIPAL =================
local ScreenGui = new("ScreenGui", {
    Name = "AP_AdminPanel",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = PG,
    IgnoreGuiInset = true,
})

-- ===== ÍCONE ARRASTÁVEL (AP branco em fundo preto) =====
local Icon = new("Frame", {
    Parent = ScreenGui,
    Name = "Icon",
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0, 20, 0.5, -27),
    BackgroundColor3 = C3(Config.IconColor),
    BorderSizePixel = 0,
    Active = true,
})
corner(Icon, 12)

local IconText = new("TextLabel", {
    Parent = Icon,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "AP",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack,
    TextScaled = true,
    Text = "AP",
})

local IconStroke = new("UIStroke", {
    Parent = Icon,
    Color = Color3.fromRGB(255, 0, 0),
    Thickness = 2,
    Transparency = 1,
})

-- ===== MENU PRINCIPAL =====
local Menu = new("Frame", {
    Parent = ScreenGui,
    Name = "Menu",
    Size = UDim2.new(0, 600, 0, 400),
    Position = UDim2.new(0.5, -300, 0.5, -200),
    BackgroundColor3 = C3(Config.MenuColor),
    BorderSizePixel = 0,
    Visible = false,
})
corner(Menu, 10)

local MenuStroke = new("UIStroke", {
    Parent = Menu,
    Color = Color3.fromRGB(255, 0, 0),
    Thickness = 2,
    Transparency = 1,
})

-- Header (arrastável)
local Header = new("Frame", {
    Parent = Menu,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderSizePixel = 0,
    Name = "Header",
})
corner(Header, 10)

new("Frame", { -- cobrir borda inferior do corner
    Parent = Header,
    Size = UDim2.new(1, 0, 0, 10),
    Position = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderSizePixel = 0,
})

new("TextLabel", {
    Parent = Header,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Text = "AP ADMIN PANEL",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local CloseBtn = new("TextButton", {
    Parent = Header,
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0,
})
corner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    Menu.Visible = false
end)

-- ===== SIDEBAR (categorias à esquerda) =====
local Sidebar = new("ScrollingFrame", {
    Parent = Menu,
    Size = UDim2.new(0, 160, 1, -50),
    Position = UDim2.new(0, 5, 0, 45),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})

-- ===== ÁREA DE CONTEÚDO (direita) =====
local Content = new("Frame", {
    Parent = Menu,
    Size = UDim2.new(1, -175, 1, -50),
    Position = UDim2.new(0, 170, 0, 45),
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 0,
})
corner(Content, 8)

-- ===== Arrastar Menu / Ícone =====
makeDraggable(Menu, Header)
makeDraggable(Icon, Icon, function()
    Menu.Visible = not Menu.Visible
end)

-- ================= SISTEMA DE CATEGORIAS =================
local Categories = {}
local CurrentCategory = nil
local CategoryButtons = {}

local function createCategory(key, labelKey)
    local btn = new("TextButton", {
        Parent = Sidebar,
        Size = UDim2.new(1, -5, 0, 36),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        Text = tr(labelKey),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    corner(btn, 6)
    new("UIPadding", {Parent = btn, PaddingLeft = UDim.new(0, 10)})
    
    local container = new("ScrollingFrame", {
        Parent = Content,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    new("UIListLayout", {
        Parent = container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    new("UIPadding", {Parent = container, PaddingTop = UDim.new(0, 4)})
    
    Categories[key] = {button = btn, container = container, labelKey = labelKey, key = key}
    table.insert(CategoryButtons, {btn = btn, key = key})
    
    btn.MouseButton1Click:Connect(function()
        for _, c in pairs(Categories) do
            c.container.Visible = false
            c.button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        end
        container.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        CurrentCategory = key
    end)
end

-- Criar categorias na ordem
createCategory("phys", "cat_phys")
createCategory("magic", "cat_magic")
createCategory("visual", "cat_visual")
createCategory("status", "cat_status")
createCategory("config", "cat_config")

-- ================= HELPERS DE OPÇÕES =================
local function makeRow(parent, labelText)
    local row = new("Frame", {
        Parent = parent,
        Size = UDim2.new(1, -10, 0, 40),
        BackgroundColor3 = Color3.fromRGB(40, 40, 55),
        BorderSizePixel = 0,
    })
    corner(row, 6)
    local lbl = new("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return row, lbl
end

local function makeToggle(parent, labelKey, callback)
    local row = makeRow(parent, tr(labelKey))
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 100, 0, 28),
        Position = UDim2.new(1, -110, 0, 6),
        BackgroundColor3 = Color3.fromRGB(180, 50, 50),
        Text = tr("off"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 70) or Color3.fromRGB(180, 50, 50)
        btn.Text = state and tr("on") or tr("off")
        callback(state)
    end)
    return row, btn
end

local function makeTextToggle(parent, labelKey, placeholderKey, callback)
    local row = makeRow(parent, tr(labelKey))
    local box = new("TextBox", {
        Parent = row,
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0.55, 0, 0, 6),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        PlaceholderText = tr(placeholderKey),
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(box, 4)
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(1, -100, 0, 6),
        BackgroundColor3 = Color3.fromRGB(180, 50, 50),
        Text = tr("off"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 180, 70) or Color3.fromRGB(180, 50, 50)
        btn.Text = state and tr("on") or tr("off")
        callback(state, box)
    end)
    return row, box, btn
end

local function makeTextButton(parent, labelKey, placeholderKey, callback)
    local row = makeRow(parent, tr(labelKey))
    local box = new("TextBox", {
        Parent = row,
        Size = UDim2.new(0, 160, 0, 28),
        Position = UDim2.new(0.45, 0, 0, 6),
        BackgroundColor3 = Color3.fromRGB(25, 25, 35),
        PlaceholderText = tr(placeholderKey),
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(box, 4)
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 100, 0, 28),
        Position = UDim2.new(1, -110, 0, 6),
        BackgroundColor3 = Color3.fromRGB(60, 100, 200),
        Text = tr(labelKey) == tr("tp") and tr("tp_btn") or tr("apply"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    btn.MouseButton1Click:Connect(function()
        callback(box.Text)
    end)
    return row, box, btn
end

local function makeButton(parent, labelKey, callback)
    local row = makeRow(parent, tr(labelKey))
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 120, 0, 28),
        Position = UDim2.new(1, -130, 0, 6),
        BackgroundColor3 = Color3.fromRGB(60, 100, 200),
        Text = tr("apply"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    btn.MouseButton1Click:Connect(callback)
    return row, btn
end

local function makeLabel(parent, labelKey)
    local row = makeRow(parent, tr(labelKey))
    local val = new("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "...",
        TextColor3 = Color3.fromRGB(150, 220, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    new("UIPadding", {Parent = val, PaddingRight = UDim.new(0, 10)})
    return row, val
end

-- ================= FEATURES =================

-- ---------- FÍSICO ----------
local speedActive, speedValue = false, 16
local jumpActive, jumpValue = false, 50
local infJumpActive = false

local physC = Categories.phys.container
makeTextToggle(physC, "speed", "quantity", function(s, box)
    speedActive = s
    if s then
        local n = tonumber(box.Text)
        speedValue = n or 16
        RS.Heartbeat:Connect(function()
            if not speedActive then return end
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = speedValue end
        end)
    end
end)

makeTextToggle(physC, "jump", "quantity", function(s, box)
    jumpActive = s
    if s then
        local n = tonumber(box.Text)
        jumpValue = n or 50
        RS.Heartbeat:Connect(function()
            if not jumpActive then return end
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.UseJumpPower then hum.JumpPower = jumpValue
                else hum.JumpHeight = jumpValue end
            end
        end)
    end
end)

makeToggle(physC, "infjump", function(s)
    infJumpActive = s
end)

UIS.JumpRequest:Connect(function()
    if infJumpActive then
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ---------- MÁGICO ----------
local magicC = Categories.magic.container
local loopTPActive, loopTPTarget = false, nil
local noclipActive = false

local function findPlayer(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() or p.DisplayName:lower() == name:lower() then
            return p
        end
    end
    return nil
end

local function tpToPlayer(name)
    local target = findPlayer(name)
    if not target or not target.Character then return end
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if myHRP and tHRP then
        myHRP.CFrame = tHRP.CFrame + Vector3.new(0, 0, 3)
    end
end

makeTextButton(magicC, "tp", "player_name", function(text)
    tpToPlayer(text)
end)

makeTextToggle(magicC, "looptp", "player_name", function(s, box)
    loopTPActive = s
    if s then
        local name = box.Text
        task.spawn(function()
            while loopTPActive do
                tpToPlayer(name)
                task.wait(0.1)
            end
        end)
    end
end)

makeToggle(magicC, "noclip", function(s)
    noclipActive = s
end)

makeButton(magicC, "tptool", function()
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.5, 0.5, 0.5)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Parent = tool
    tool.Activated:Connect(function()
        local mouse = LP:GetMouse()
        local target = mouse.Hit.Position
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
        end
    end)
    tool.Parent = bp
end)

-- Noclip loop
RS.Heartbeat:Connect(function()
    if not noclipActive then return end
    local ch = LP.Character
    if ch then
        for _, p in pairs(ch:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end)

-- ---------- VISUAL ----------
local visualC = Categories.visual.container

-- Otimizar
makeButton(visualC, "optimize", function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ParticleEmitter")
            or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")
            or obj:IsA("Beam") or obj:IsA("Trail") then
            pcall(function() obj:Destroy() end)
        end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
            end)
        end
    end
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere") then
            pcall(function() obj:Destroy() end)
        end
    end
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 1
    end)
end)

-- ESP
local ESPActive = false
local espObjects, espConns = {}, {}

local function getPColor(plr)
    if plr.Team then return plr.Team.TeamColor.Color end
    return plr.TeamColor.Color
end

local function clearESP()
    for _, o in pairs(espObjects) do
        if o and o.Parent then ocall = pcall(function() o:Destroy() end) end
    end
    espObjects = {}
    for _, c in pairs(espConns) do pcall(function() c:Disconnect() end) end
    espConns = {}
end

local function setupESPFor(plr)
    if plr == LP then return end
    local function onChar(char)
        if not ESPActive then return end
        local hl = Instance.new("Highlight")
        hl.Name = "AP_ESP"
        hl.FillColor = getPColor(plr)
        hl.OutlineColor = getPColor(plr)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        table.insert(espObjects, hl)
        
        local head = char:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "AP_ESP_BB"
            bb.Size = UDim2.new(0, 200, 0, 60)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = head
            table.insert(espObjects, bb)
            
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = Color3.new(1, 1, 1)
            nameLbl.TextStrokeTransparency = 0
            nameLbl.TextScaled = true
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.Text = plr.Name
            nameLbl.Parent = bb
            
            local hpLbl = Instance.new("TextLabel")
            hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
            hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
            hpLbl.BackgroundTransparency = 1
            hpLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            hpLbl.TextStrokeTransparency = 0
            hpLbl.TextScaled = true
            hpLbl.Font = Enum.Font.GothamBold
            hpLbl.Parent = bb
            
            table.insert(espConns, RS.Heartbeat:Connect(function()
                if not ESPActive then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hpLbl.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    local c = getPColor(plr)
                    hl.FillColor = c
                    hl.OutlineColor = c
                end
            end))
        end
    end
    if plr.Character then onChar(plr.Character) end
    table.insert(espConns, plr.CharacterAdded:Connect(onChar))
end

makeToggle(visualC, "esp", function(s)
    ESPActive = s
    if s then
        for _, plr in pairs(Players:GetPlayers()) do setupESPFor(plr) end
        table.insert(espConns, Players.PlayerAdded:Connect(setupESPFor))
    else
        clearESP()
    end
end)

-- Raio X
local xrayData = {}
local xrayActive = false

local function isCharPart(part)
    local p = part.Parent
    while p do
        if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then return true end
        p = p.Parent
    end
    return false
end

makeToggle(visualC, "xray", function(s)
    xrayActive = s
    if s then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not isCharPart(obj) then
                if xrayData[obj] == nil then
                    xrayData[obj] = obj.Transparency
                    obj.Transparency = 0.7
                end
            end
        end
    else
        for obj, orig in pairs(xrayData) do
            if obj and obj.Parent then pcall(function() obj.Transparency = orig end) end
        end
        xrayData = {}
    end
end)

-- ---------- STATUS ----------
local statusC = Categories.status.container
local lbl_game, lbl_players, lbl_moon, lbl_server

lbl_game    = select(2, makeLabel(statusC, "gamename"))
lbl_players = select(2, makeLabel(statusC, "playercount"))
lbl_moon    = select(2, makeLabel(statusC, "moonstate"))
lbl_server  = select(2, makeLabel(statusC, "servername"))

local function updateStatus()
    -- Nome do jogo
    local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
    lbl_game.Text = (ok and info and info.Name) or game.Name
    
    -- Jogadores
    lbl_players.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
    
    -- Lua
    local hour = (Lighting:GetMinutesAfterMidnight() / 60) % 24
    if hour >= 18 or hour < 6 then
        lbl_moon.Text = "🌙 Noite"
    elseif hour >= 6 and hour < 12 then
        lbl_moon.Text = "🌅 Manhã"
    elseif hour >= 12 and hour < 18 then
        lbl_moon.Text = "☀️ Tarde"
    end
    
    -- Servidor
    lbl_server.Text = game.JobId ~= "" and game.JobId:sub(1, 12) .. "..." or "Local"
end
task.spawn(function()
    while task.wait(2) do updateStatus() end
end)
updateStatus()

-- ---------- CONFIGURAÇÕES ----------
local configC = Categories.config.container

-- Color Picker (helper)
local function openColorPicker(initial, onPick)
    local picker = new("Frame", {
        Parent = Menu,
        Size = UDim2.new(0, 260, 0, 240),
        Position = UDim2.new(0.5, -130, 0.5, -120),
        BackgroundColor3 = Color3.fromRGB(30, 30, 45),
        BorderSizePixel = 0,
        ZIndex = 50,
    })
    corner(picker, 10)
    new("UIStroke", {Parent = picker, Color = Color3.fromRGB(100, 100, 255), Thickness = 2})
    
    new("TextLabel", {
        Parent = picker,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = "🎨",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
    })
    
    local colors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 128, 0),
        Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0),
        Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 0, 255),
        Color3.fromRGB(128, 0, 255), Color3.fromRGB(255, 0, 255),
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
        Color3.fromRGB(128, 128, 128), Color3.fromRGB(20, 20, 25),
        Color3.fromRGB(50, 50, 70), Color3.fromRGB(100, 50, 200),
        Color3.fromRGB(200, 100, 50), Color3.fromRGB(0, 150, 100),
    }
    for i, c in ipairs(colors) do
        local s = new("TextButton", {
            Parent = picker,
            Size = UDim2.new(0, 50, 0, 30),
            Position = UDim2.new(0, 10 + ((i-1) % 4) * 60, 0, 35 + math.floor((i-1)/4) * 35),
            BackgroundColor3 = c,
            Text = "",
            BorderSizePixel = 0,
        })
        corner(s, 4)
        s.MouseButton1Click:Connect(function()
            onPick(c)
            picker:Destroy()
        end)
    end
    
    -- Hex input
    local hexBox = new("TextBox", {
        Parent = picker,
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 10, 1, -70),
        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
        PlaceholderText = "Hex ex: FF00FF",
        Text = "",
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(hexBox, 4)
    
    local applyBtn = new("TextButton", {
        Parent = picker,
        Size = UDim2.new(1, -20, 0, 28),
        Position = UDim2.new(0, 10, 1, -36),
        BackgroundColor3 = Color3.fromRGB(60, 100, 200),
        Text = "✔",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
    })
    corner(applyBtn, 4)
    applyBtn.MouseButton1Click:Connect(function()
        local hex = hexBox.Text:gsub("#", "")
        if #hex == 6 then
            local r = tonumber(hex:sub(1,2), 16)
            local g = tonumber(hex:sub(3,4), 16)
            local b = tonumber(hex:sub(5,6), 16)
            if r and g and b then
                onPick(Color3.fromRGB(r, g, b))
                picker:Destroy()
            end
        end
    end)
end

-- Cor do ícone
do
    local row = makeRow(configC, tr("iconcolor"))
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 100, 0, 28),
        Position = UDim2.new(1, -110, 0, 6),
        BackgroundColor3 = C3(Config.IconColor),
        Text = "🎨",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    btn.MouseButton1Click:Connect(function()
        openColorPicker(C3(Config.IconColor), function(c)
            Config.IconColor = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
            Icon.BackgroundColor3 = c
            btn.BackgroundColor3 = c
            saveCfg()
        end)
    end)
end

-- Cor do menu
do
    local row = makeRow(configC, tr("menucolor"))
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 100, 0, 28),
        Position = UDim2.new(1, -110, 0, 6),
        BackgroundColor3 = C3(Config.MenuColor),
        Text = "🎨",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    btn.MouseButton1Click:Connect(function()
        openColorPicker(C3(Config.MenuColor), function(c)
            Config.MenuColor = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
            Menu.BackgroundColor3 = c
            btn.BackgroundColor3 = c
            saveCfg()
        end)
    end)
end

-- Menu RGB
makeToggle(configC, "menurgb", function(s)
    Config.MenuRGB = s
    if not s then
        pcall(function() MenuStroke.Transparency = 1 end)
    else
        pcall(function() MenuStroke.Transparency = 0 end)
    end
    saveCfg()
end)

-- Ícone RGB
makeToggle(configC, "iconrgb", function(s)
    Config.IconRGB = s
    if not s then
        pcall(function() IconStroke.Transparency = 1 end)
    else
        pcall(function() IconStroke.Transparency = 0 end)
    end
    saveCfg()
end)

-- Idioma
do
    local row = makeRow(configC, tr("language"))
    local btn = new("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 120, 0, 28),
        Position = UDim2.new(1, -130, 0, 6),
        BackgroundColor3 = Color3.fromRGB(60, 100, 200),
        Text = Config.Language:upper(),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
    })
    corner(btn, 4)
    
    btn.MouseButton1Click:Connect(function()
        local list = new("ScrollingFrame", {
            Parent = Menu,
            Size = UDim2.new(0, 200, 0, 300),
            Position = UDim2.new(0.5, -100, 0.5, -150),
            BackgroundColor3 = Color3.fromRGB(30, 30, 45),
            BorderSizePixel = 0,
            ZIndex = 50,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })
        corner(list, 8)
        new("UIListLayout", {Parent = list, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
        new("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
        
        local langs = {
            {c="pt", n="Português"}, {c="en", n="English"}, {c="es", n="Español"},
            {c="fr", n="Français"}, {c="de", n="Deutsch"}, {c="it", n="Italiano"},
            {c="ru", n="Русский"}, {c="ja", n="日本語"}, {c="zh", n="中文"},
            {c="ko", n="한국어"}, {c="ar", n="العربية"}, {c="hi", n="हिन्दी"},
        }
        for _, lang in ipairs(langs) do
            local b = new("TextButton", {
                Parent = list,
                Size = UDim2.new(1, -6, 0, 32),
                BackgroundColor3 = Color3.fromRGB(40, 40, 55),
                Text = lang.n .. " (" .. lang.c .. ")",
                TextColor3 = Color3.new(1, 1, 1),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                BorderSizePixel = 0,
            })
            corner(b, 4)
            b.MouseButton1Click:Connect(function()
                Config.Language = lang.c
                btn.Text = lang.c:upper()
                saveCfg()
                list:Destroy()
                -- Atualizar todos os textos visíveis
                for _, cat in pairs(Categories) do
                    cat.button.Text = tr(cat.labelKey)
                end
            end)
        end
    end)
end

-- Salvar
makeButton(configC, "save", function()
    saveCfg()
    -- Feedback visual
    local notif = new("TextLabel", {
        Parent = Menu,
        Size = UDim2.new(0, 200, 0, 40),
        Position = UDim2.new(0.5, -100, 1, -50),
        BackgroundColor3 = Color3.fromRGB(50, 180, 70),
        Text = "✔ " .. tr("saved"),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        BorderSizePixel = 0,
        ZIndex = 100,
    })
    corner(notif, 8)
    task.delay(2, function()
        pcall(function() notif:Destroy() end)
    end)
end)

-- ================= RGB LOOP =================
RS.Heartbeat:Connect(function()
    local hue = (tick() * 0.3) % 1
    local c = Color3.fromHSV(hue, 1, 1)
    if Config.MenuRGB then
        pcall(function() MenuStroke.Color = c; MenuStroke.Transparency = 0 end)
    end
    if Config.IconRGB then
        pcall(function() IconStroke.Color = c; IconStroke.Transparency = 0 end)
    end
end)

-- Inicial: aplicar configurações salvas
if Config.MenuRGB then MenuStroke.Transparency = 0 end
if Config.IconRGB then IconStroke.Transparency = 0 end

-- Abrir primeira categoria
Categories.phys.button.MouseButton1Click:Fire()
-- (ou manualmente)
for _, c in pairs(Categories) do
    c.container.Visible = false
end
Categories.phys.container.Visible = true
Categories.phys.button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
CurrentCategory = "phys"

print("[AP ADMIN PANEL] Carregado com sucesso!")