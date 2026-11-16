-- ============================================
-- PAINEL ADMIN v2.0 (completo)
-- + Player List | Fly | Fullbright | Freecam | FOV
-- + Waypoints | Anti-AFK | Auto-Clicker | Anti-Void
-- + Rejoin | Hitbox | Hotkeys | Ping/FPS
-- + Comandos via chat (prefixo "!")
-- ============================================

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local Lighting   = game:GetService("Lighting")
local HttpService= game:GetService("HttpService")
local VirtualUser= game:GetService("VirtualUser")
local TPS        = game:GetService("TeleportService")
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

-- ============ CONFIG ============
local CONFIG_FILE = "AdminPanelConfig.json"
local loadedConfig = nil
pcall(function()
    if isfile and readfile and isfile(CONFIG_FILE) then
        loadedConfig = HttpService:JSONDecode(readfile(CONFIG_FILE))
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
local currentLanguage = "pt"
local customMenuTitle = ""
local customIconText  = ""
local MIN_W, MIN_H = 440, 300

-- New features
local flyEnabled, flySpeed = false, 50
local flyBodyVel, flyBodyGyro, flyConn = nil, nil, nil
local fullbrightEnabled, fullbrightSaved = false, nil
local antiAfkEnabled = false
local autoClickerEnabled, autoClickerCPS = false, 10
local antiVoidEnabled, lastSafeCFrame = false, nil
local freecamEnabled, freecamSpeed, freecamCFrame = false, 40, nil
local savedFreecamSubject, savedFreecamType = nil, nil
local hitboxEnabled, hitboxSize = false, 10
local hitboxSaved = {}
local fovValue, defaultFOV = 70, 70
local waypoints = {}

if loadedConfig then
    speedEnabled    = loadedConfig.speed    and loadedConfig.speed.enabled    or false
    speedValue      = loadedConfig.speed    and loadedConfig.speed.value      or 16
    jumpEnabled     = loadedConfig.jump     and loadedConfig.jump.enabled     or false
    jumpValue       = loadedConfig.jump     and loadedConfig.jump.value       or 50
    infJumpEnabled  = loadedConfig.infJump  or false
    noclipEnabled   = loadedConfig.noclip   or false
    loopTPEnabled   = loadedConfig.loopTP   and loadedConfig.loopTP.enabled   or false
    loopTPTarget    = loadedConfig.loopTP   and loadedConfig.loopTP.target    or ""
    gravityEnabled  = loadedConfig.gravity  or false
    espEnabled      = loadedConfig.esp      or false
    xrayEnabled     = loadedConfig.xray     or false
    spectateEnabled = loadedConfig.spectate and loadedConfig.spectate.enabled or false
    spectateTarget  = loadedConfig.spectate and loadedConfig.spectate.target  or ""
    menuRGBEnabled  = loadedConfig.menuRGB  or false
    iconRGBEnabled  = loadedConfig.iconRGB  or false
    flySpeed        = loadedConfig.flySpeed or 50
    autoClickerCPS  = loadedConfig.autoClickerCPS or 10
    freecamSpeed    = loadedConfig.freecamSpeed or 40
    hitboxSize      = loadedConfig.hitboxSize or 10
    if loadedConfig.language then currentLanguage = loadedConfig.language end
    if loadedConfig.menuTitle then customMenuTitle = loadedConfig.menuTitle end
    if loadedConfig.iconText  then customIconText  = loadedConfig.iconText  end
    if loadedConfig.fov       then fovValue        = loadedConfig.fov       end
    if loadedConfig.waypoints then waypoints       = loadedConfig.waypoints end
end
defaultFOV = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or 70

-- ============ i18n ============
local LANGUAGES = {
    { code="pt", name="Português" }, { code="en", name="English"   },
    { code="es", name="Español"   }, { code="fr", name="Français"  },
    { code="de", name="Deutsch"   }, { code="it", name="Italiano"  },
    { code="nl", name="Nederlands"}, { code="pl", name="Polski"    },
    { code="ru", name="Русский"   }, { code="uk", name="Українська"},
    { code="tr", name="Türkçe"    }, { code="ar", name="العربية"   },
    { code="hi", name="हिन्दी"      }, { code="id", name="Indonesia" },
    { code="vi", name="Tiếng Việt"}, { code="th", name="ไทย"       },
    { code="ja", name="日本語"     }, { code="ko", name="한국어"    },
    { code="zh", name="中文"       }, { code="sv", name="Svenska"   },
}

local TRANSLATIONS = {
    pt = {
        title="PAINEL ADMIN",
        cat_fisico="Físico", cat_magico="Mágico", cat_visual="Visual",
        cat_players="Jogadores", cat_camera="Câmera", cat_waypoints="Waypoints",
        cat_util="Utilidades", cat_status="Status", cat_config="Configurações",
        speed="Velocidade", jump="Pulo", inf_jump="Pulo Infinito",
        fly="Voar", fly_speed="Vel. do Voo",
        teleport="Teleporte", tp_ph="Nome do jogador", tp_btn="TP",
        loop_tp="Loop Teleporte", noclip="Atravessar Paredes",
        get_tp_tool="Pegar TP Tool", gravity="Gravidade Lunar",
        optimize="Otimizar Jogo", esp="ESP Jogadores", xray="Raio X",
        fullbright="Iluminação Total", no_fog="Sem Névoa",
        spectate="Espectador", icon_color="Cor do Ícone", menu_color="Cor do Menu",
        menu_rgb="Menu RGB", icon_rgb="Ícone RGB", language="Idioma",
        menu_title="Nome do Menu", icon_text="Texto do Ícone",
        freecam="Câmera Livre", freecam_speed="Vel. Câmera", fov="Campo de Visão",
        apply="Aplicar",
        wp_name="Nome do Waypoint", wp_save="Salvar Posição",
        wp_goto="Ir", wp_del="Deletar", wp_none="Nenhum waypoint salvo",
        anti_afk="Anti-AFK", auto_clicker="Auto-Clicker", cps="CPS",
        anti_void="Anti-Vazio", rejoin="Rejoin", server_hop="Server Hop",
        reset_char="Resetar Personagem",
        hitbox="Hitbox Expandida", hitbox_size="Tamanho",
        player_list="Lista de Jogadores", search_ph="Buscar jogador...",
        goto="Ir até", follow="Seguir", refresh="Atualizar",
        health="Vida", distance="Distância",
        ping="Ping", fps="FPS",
        hotkeys="Atalhos: F=Fly  N=Noclip  J=InfJump  E=ESP  G=Grav  X=Xray  V=AntiVoid",
        save="Salvar", saved="Configurações salvas!",
        game_name="Nome do Jogo", players="Jogadores",
        moon_phase="Fase da Lua", server="Servidor",
        moon_new="Nova", moon_waxing_crescent="Crescente Côncava",
        moon_first_quarter="Quarto Crescente", moon_waxing_gibbous="Crescente Gibosa",
        moon_full="Cheia", moon_waning_gibbous="Minguante Gibosa",
        moon_last_quarter="Quarto Minguante", moon_waning_crescent="Minguante Côncava",
    },
    en = {
        title="ADMIN PANEL",
        cat_fisico="Physical", cat_magico="Magic", cat_visual="Visual",
        cat_players="Players", cat_camera="Camera", cat_waypoints="Waypoints",
        cat_util="Utilities", cat_status="Status", cat_config="Settings",
        speed="Speed", jump="Jump", inf_jump="Infinite Jump",
        fly="Fly", fly_speed="Fly Speed",
        teleport="Teleport", tp_ph="Player name", tp_btn="TP",
        loop_tp="Loop Teleport", noclip="Noclip",
        get_tp_tool="Get TP Tool", gravity="Moon Gravity",
        optimize="Optimize Game", esp="Player ESP", xray="X-Ray",
        fullbright="Fullbright", no_fog="No Fog",
        spectate="Spectate", icon_color="Icon Color", menu_color="Menu Color",
        menu_rgb="Menu RGB", icon_rgb="Icon RGB", language="Language",
        menu_title="Menu Name", icon_text="Icon Text",
        freecam="Freecam", freecam_speed="Cam Speed", fov="Field of View",
        apply="Apply",
        wp_name="Waypoint Name", wp_save="Save Position",
        wp_goto="Go", wp_del="Delete", wp_none="No waypoints saved",
        anti_afk="Anti-AFK", auto_clicker="Auto-Clicker", cps="CPS",
        anti_void="Anti-Void", rejoin="Rejoin", server_hop="Server Hop",
        reset_char="Reset Character",
        hitbox="Hitbox Expander", hitbox_size="Size",
        player_list="Player List", search_ph="Search player...",
        goto="Go To", follow="Follow", refresh="Refresh",
        health="Health", distance="Distance",
        ping="Ping", fps="FPS",
        hotkeys="Hotkeys: F=Fly  N=Noclip  J=InfJump  E=ESP  G=Grav  X=Xray  V=AntiVoid",
        save="Save", saved="Settings saved!",
        game_name="Game Name", players="Players",
        moon_phase="Moon Phase", server="Server",
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
        menu_title="Nombre del Menú", icon_text="Texto del Icono",
        save="Guardar", saved="¡Guardado!",
        game_name="Nombre del Juego", players="Jugadores",
        moon_phase="Fase Lunar", server="Servidor",
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
        moon_phase="Phase Lunaire", server="Serveur",
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
        moon_phase="Mondphase", server="Server",
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
        moon_phase="Fase Lunare", server="Server",
    },
    nl = {
        title="ADMIN PANEEL", cat_fisico="Fysiek", cat_magico="Magie",
        cat_visual="Visueel", cat_status="Status", cat_config="Instellingen",
        speed="Snelheid", jump="Springen", inf_jump="Oneindig Springen",
        teleport="Teleport", tp_ph="Spelersnaam", tp_btn="TP",
        loop_tp="Loop TP", noclip="Door Muren",
        get_tp_tool="TP Gereedschap", gravity="Maan Zwaartekracht",
        optimize="Spel Optimaliseren", esp="Speler ESP", xray="Röntgen",
        spectate="Toeschouwer", icon_color="Pictogramkleur", menu_color="Menukleur",
        menu_rgb="Menu RGB", icon_rgb="Pictogram RGB", language="Taal",
        save="Opslaan", saved="Opgeslagen!",
        game_name="Spelnaam", players="Spelers",
        moon_phase="Maanfase", server="Server",
    },
    pl = {
        title="PANEL ADMINA", cat_fisico="Fizyka", cat_magico="Magia",
        cat_visual="Wizualne", cat_status="Status", cat_config="Ustawienia",
        speed="Prędkość", jump="Skok", inf_jump="Nieskończony Skok",
        teleport="Teleport", tp_ph="Nazwa gracza", tp_btn="TP",
        loop_tp="Pętla TP", noclip="Przez Ściany",
        get_tp_tool="Narzędzie TP", gravity="Grawitacja Księżycowa",
        optimize="Optymalizuj Grę", esp="ESP Graczy", xray="RTG",
        spectate="Obserwator", icon_color="Kolor Ikony", menu_color="Kolor Menu",
        menu_rgb="Menu RGB", icon_rgb="Ikona RGB", language="Język",
        save="Zapisz", saved="Zapisano!",
        game_name="Nazwa Gry", players="Gracze",
        moon_phase="Faza Księżyca", server="Serwer",
    },
    ru = {
        title="АДМИН-ПАНЕЛЬ", cat_fisico="Физика", cat_magico="Магия",
        cat_visual="Визуал", cat_status="Статус", cat_config="Настройки",
        speed="Скорость", jump="Прыжок", inf_jump="Бесконечный Прыжок",
        teleport="Телепорт", tp_ph="Имя игрока", tp_btn="ТП",
        loop_tp="Цикл ТП", noclip="Сквозь Стены",
        get_tp_tool="ТП-инструмент", gravity="Лунная Гравитация",
        optimize="Оптимизировать Игру", esp="ESP Игроков", xray="Рентген",
        spectate="Наблюдение", icon_color="Цвет Иконки", menu_color="Цвет Меню",
        menu_rgb="Меню RGB", icon_rgb="Иконка RGB", language="Язык",
        save="Сохранить", saved="Сохранено!",
        game_name="Название Игры", players="Игроки",
        moon_phase="Фаза Луны", server="Сервер",
    },
    uk = {
        title="АДМІН-ПАНЕЛЬ", cat_fisico="Фізика", cat_magico="Магія",
        cat_visual="Візуал", cat_status="Статус", cat_config="Налаштування",
        speed="Швидкість", jump="Стрибок", inf_jump="Нескінченний Стрибок",
        teleport="Телепорт", tp_ph="Ім'я гравця", tp_btn="ТП",
        loop_tp="Цикл ТП", noclip="Крізь Стіни",
        get_tp_tool="ТП-інструмент", gravity="Місячна Гравітація",
        optimize="Оптимізувати Гру", esp="ESP Гравців", xray="Рентген",
        spectate="Спостереження", icon_color="Колір Іконки", menu_color="Колір Меню",
        menu_rgb="Меню RGB", icon_rgb="Іконка RGB", language="Мова",
        save="Зберегти", saved="Збережено!",
        game_name="Назва Гри", players="Гравці",
        moon_phase="Фаза Місяця", server="Сервер",
    },
    tr = {
        title="YÖNETİCİ PANELİ", cat_fisico="Fizik", cat_magico="Sihir",
        cat_visual="Görsel", cat_status="Durum", cat_config="Ayarlar",
        speed="Hız", jump="Zıplama", inf_jump="Sonsuz Zıplama",
        teleport="Işınlanma", tp_ph="Oyuncu adı", tp_btn="TP",
        loop_tp="Döngü TP", noclip="Duvarlardan Geç",
        get_tp_tool="TP Aracı Al", gravity="Ay Yerçekimi",
        optimize="Oyunu Optimize Et", esp="Oyuncu ESP", xray="Röntgen",
        spectate="İzleyici", icon_color="Simge Rengi", menu_color="Menü Rengi",
        menu_rgb="Menü RGB", icon_rgb="Simge RGB", language="Dil",
        save="Kaydet", saved="Kaydedildi!",
        game_name="Oyun Adı", players="Oyuncular",
        moon_phase="Ay Evresi", server="Sunucu",
    },
    ar = {
        title="لوحة المسؤول", cat_fisico="فيزيائي", cat_magico="سحري",
        cat_visual="مرئي", cat_status="الحالة", cat_config="الإعدادات",
        speed="السرعة", jump="القفز", inf_jump="قفز لا نهائي",
        teleport="انتقال", tp_ph="اسم اللاعب", tp_btn="نقل",
        loop_tp="تكرار النقل", noclip="عبر الجدران",
        get_tp_tool="أداة النقل", gravity="جاذبية القمر",
        optimize="تحسين اللعبة", esp="ESP اللاعبين", xray="أشعة سينية",
        spectate="مشاهدة", icon_color="لون الأيقونة", menu_color="لون القائمة",
        menu_rgb="قائمة RGB", icon_rgb="أيقونة RGB", language="اللغة",
        save="حفظ", saved="تم الحفظ!",
        game_name="اسم اللعبة", players="اللاعبون",
        moon_phase="طور القمر", server="الخادم",
    },
    hi = {
        title="एडमिन पैनल", cat_fisico="भौतिक", cat_magico="जादू",
        cat_visual="दृश्य", cat_status="स्थिति", cat_config="सेटिंग्स",
        speed="गति", jump="कूद", inf_jump="असीमित कूद",
        teleport="टेलीपोर्ट", tp_ph="खिलाड़ी का नाम", tp_btn="TP",
        loop_tp="लूप TP", noclip="दीवारों के पार",
        get_tp_tool="TP टूल लें", gravity="चंद्र गुरुत्वाकर्षण",
        optimize="गेम अनुकूलित करें", esp="प्लेयर ESP", xray="एक्स-रे",
        spectate="दर्शक", icon_color="आइकन रंग", menu_color="मेनू रंग",
        menu_rgb="मेनू RGB", icon_rgb="आइकन RGB", language="भाषा",
        save="सहेजें", saved="सहेजा गया!",
        game_name="गेम का नाम", players="खिलाड़ी",
        moon_phase="चंद्र चरण", server="सर्वर",
    },
    id = {
        title="PANEL ADMIN", cat_fisico="Fisik", cat_magico="Sihir",
        cat_visual="Visual", cat_status="Status", cat_config="Pengaturan",
        speed="Kecepatan", jump="Lompat", inf_jump="Lompat Tanpa Batas",
        teleport="Teleport", tp_ph="Nama pemain", tp_btn="TP",
        loop_tp="Loop TP", noclip="Tembus Dinding",
        get_tp_tool="Dapatkan TP Tool", gravity="Gravitasi Bulan",
        optimize="Optimalkan Game", esp="ESP Pemain", xray="Sinar-X",
        spectate="Penonton", icon_color="Warna Ikon", menu_color="Warna Menu",
        menu_rgb="Menu RGB", icon_rgb="Ikon RGB", language="Bahasa",
        save="Simpan", saved="Tersimpan!",
        game_name="Nama Game", players="Pemain",
        moon_phase="Fase Bulan", server="Server",
    },
    vi = {
        title="BẢNG QUẢN TRỊ", cat_fisico="Vật Lý", cat_magico="Phép Thuật",
        cat_visual="Hình Ảnh", cat_status="Trạng Thái", cat_config="Cài Đặt",
        speed="Tốc Độ", jump="Nhảy", inf_jump="Nhảy Vô Hạn",
        teleport="Dịch Chuyển", tp_ph="Tên người chơi", tp_btn="TP",
        loop_tp="Lặp TP", noclip="Xuyên Tường",
        get_tp_tool="Lấy TP Tool", gravity="Trọng Lực Mặt Trăng",
        optimize="Tối Ưu Game", esp="ESP Người Chơi", xray="X-Quang",
        spectate="Xem", icon_color="Màu Biểu Tượng", menu_color="Màu Menu",
        menu_rgb="Menu RGB", icon_rgb="Biểu Tượng RGB", language="Ngôn Ngữ",
        save="Lưu", saved="Đã lưu!",
        game_name="Tên Game", players="Người Chơi",
        moon_phase="Pha Mặt Trăng", server="Máy Chủ",
    },
    th = {
        title="แผงผู้ดูแล", cat_fisico="กายภาพ", cat_magico="เวทมนตร์",
        cat_visual="ภาพ", cat_status="สถานะ", cat_config="การตั้งค่า",
        speed="ความเร็ว", jump="กระโดด", inf_jump="กระโดดไม่จำกัด",
        teleport="วาร์ป", tp_ph="ชื่อผู้เล่น", tp_btn="TP",
        loop_tp="วน TP", noclip="ทะลุกำแพง",
        get_tp_tool="รับ TP Tool", gravity="แรงโน้มถ่วงดวงจันทร์",
        optimize="เพิ่มประสิทธิภาพเกม", esp="ESP ผู้เล่น", xray="เอ็กซ์เรย์",
        spectate="ผู้ชม", icon_color="สีไอคอน", menu_color="สีเมนู",
        menu_rgb="เมนู RGB", icon_rgb="ไอคอน RGB", language="ภาษา",
        save="บันทึก", saved="บันทึกแล้ว!",
        game_name="ชื่อเกม", players="ผู้เล่น",
        moon_phase="ข้างขึ้นข้างแรม", server="เซิร์ฟเวอร์",
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
        moon_phase="月相", server="サーバー",
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
        moon_phase="달 위상", server="서버",
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
        moon_phase="月相", server="服务器",
    },
    sv = {
        title="ADMINPANEL", cat_fisico="Fysik", cat_magico="Magi",
        cat_visual="Visuell", cat_status="Status", cat_config="Inställningar",
        speed="Hastighet", jump="Hopp", inf_jump="Oändligt Hopp",
        teleport="Teleport", tp_ph="Spelarnamn", tp_btn="TP",
        loop_tp="Slinga TP", noclip="Genom Väggar",
        get_tp_tool="Skaffa TP-verktyg", gravity="Mån Gravitation",
        optimize="Optimera Spelet", esp="Spelar-ESP", xray="Röntgen",
        spectate="Åskådare", icon_color="Ikonfärg", menu_color="Menyfärg",
        menu_rgb="Meny RGB", icon_rgb="Ikon RGB", language="Språk",
        save="Spara", saved="Sparat!",
        game_name="Spelnamn", players="Spelare",
        moon_phase="Månfas", server="Server",
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
local langBtnRef = nil  -- preenchido em buildSettings; applyLanguage atualiza
local function regLabel(obj, key, field)
    table.insert(langRegistry, { obj = obj, key = key, field = field or "Text" })
end
local function applyLanguage()
    for _, r in ipairs(langRegistry) do
        if r.obj and r.obj.Parent ~= nil then
            pcall(function() r.obj[r.field] = T(r.key) end)
        end
    end
    if langBtnRef and langBtnRef.Parent then
        langBtnRef.Text = getLanguageName(currentLanguage)
    end
end

-- ============ UTILITIES ============
local function getHumanoid()
    return LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
end

local function findPlayerByName(name)
    if not name or name == "" then return nil end
    local lname = name:lower()
    -- Match exato primeiro (Name e DisplayName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower() == lname or p.DisplayName:lower() == lname) then
            return p
        end
    end
    -- Prefixo (Name ou DisplayName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():find(lname, 1, true) == 1
            or p.DisplayName:lower():find(lname, 1, true) == 1) then
            return p
        end
    end
    -- Substring
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():find(lname, 1, true)
            or p.DisplayName:lower():find(lname, 1, true)) then
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

-- FIX: agora usa raycast da câmera (funciona sem Tool equipada)
local function getAimPosition()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local mp = UIS:GetMouseLocation()
    local ray = cam:ScreenPointToRay(mp.X, mp.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    local hit = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
    if hit then return hit.Position end
    return ray.Origin + ray.Direction * 5000
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
local function colorDist(a, b)
    return math.sqrt((a.R-b.R)^2 + (a.G-b.G)^2 + (a.B-b.B)^2)
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
    hitboxSaved = {}
    if gravitySaved then
        gravitySaved.useJumpPower = nil; gravitySaved.jumpPower = nil; gravitySaved.jumpHeight = nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    if hum then hookHumanoidForce(hum) end
    -- Reaplica fly se estava ativo
    if flyEnabled then task.defer(function() startFly() end) end
    -- Reaplica hitbox
    if hitboxEnabled then task.defer(function() applyHitboxAll() end) end
    -- Reencontra humanoid do spectate
    if spectateEnabled and spectateTarget ~= "" then
        local t = findPlayerByName(spectateTarget)
        local cam = Workspace.CurrentCamera
        if t and t.Character and cam then
            local h = t.Character:FindFirstChildOfClass("Humanoid")
            if h then cam.CameraSubject = h; cam.CameraType = Enum.CameraType.Custom end
        end
    end
end

LP.CharacterAdded:Connect(onCharacterAdded)
if LP.Character then onCharacterAdded(LP.Character) end

-- FIX: noclip cleanup ao morrer
LP.CharacterRemoving:Connect(function()
    noclipSaved = {}
    hitboxSaved = {}
    stopFly()
end)

-- ============ ESP ============
local function createESPForPlayer(player)
    if player == LP or espData[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local teamColor = Color3.fromRGB(255, 255, 255)
    if player.Team then teamColor = player.Team.TeamColor.Color end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AP_ESP"; billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 300, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true; billboard.Parent = hrp

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = teamColor
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = player.Name
    label.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.Name = "AP_ESP_HL"; highlight.Adornee = char
    highlight.FillColor = teamColor; highlight.FillTransparency = 0.5
    highlight.OutlineColor = teamColor; highlight.OutlineTransparency = 0
    highlight.Parent = char

    espData[player] = {
        billboard = billboard, highlight = highlight, label = label,
        char = char, teamColor = teamColor,
    }
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
        if hitboxEnabled then task.defer(function() applyHitbox(player) end) end
    end)
    player.CharacterRemoving:Connect(function() destroyESPForPlayer(player) end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayerESP(p) end
Players.PlayerAdded:Connect(function(p)
    hookPlayerESP(p)
    if espEnabled then tryCreateESPLoop(p) end
    if playerListContainer then refreshPlayerList() end
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
    if playerListContainer then refreshPlayerList() end
end)

-- ============ ICON ============
local Icon = Instance.new("TextButton")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(0, 50, 0, 200)
Icon.BackgroundColor3 = Color3.new(0, 0, 0)
Icon.Text = "AP"; Icon.TextColor3 = Color3.new(1, 1, 1)
Icon.TextSize = 22; Icon.Font = Enum.Font.GothamBold
Icon.BorderSizePixel = 0; Icon.AutoButtonColor = false
Icon.Parent = gui
Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 8)
local iconStroke = Instance.new("UIStroke", Icon)
iconStroke.Color = Color3.fromRGB(80, 80, 80)
iconStroke.Thickness = 1
makeDraggable(Icon, Icon)

-- FIX: restaura posição do ícone
if loadedConfig and loadedConfig.iconPos then
    local p = loadedConfig.iconPos
    if p.x and p.y then
        Icon.Position = UDim2.fromOffset(p.x, p.y)
    end
end

local function setIconText(text)
    local t = (text ~= nil and text ~= "") and text or "AP"
    Icon.Text = t
    local len = #t
    if len <= 2 then Icon.TextSize = 22
    elseif len <= 4 then Icon.TextSize = 16
    else Icon.TextSize = 11 end
end

if loadedConfig and loadedConfig.iconColor then
    Icon.BackgroundColor3 = tableToColor(loadedConfig.iconColor)
end
if customIconText ~= "" then setIconText(customIconText) end

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

if loadedConfig and loadedConfig.menuColor then
    Menu.BackgroundColor3 = tableToColor(loadedConfig.menuColor)
end
if loadedConfig and loadedConfig.menuSize then
    local mw = loadedConfig.menuSize.w or 550
    local mh = loadedConfig.menuSize.h or 350
    mw = math.max(MIN_W, mw)
    mh = math.max(MIN_H, mh)
    Menu.Size = UDim2.fromOffset(mw, mh)
end
-- FIX: restaura posição do menu
if loadedConfig and loadedConfig.menuPos then
    local p = loadedConfig.menuPos
    if p.x and p.y then
        Menu.Position = UDim2.fromOffset(p.x, p.y)
    end
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
if loadedConfig and loadedConfig.menuColor then
    TitleBar.BackgroundColor3 = tableToColor(loadedConfig.menuColor)
    TitleBarCover.BackgroundColor3 = tableToColor(loadedConfig.menuColor)
end

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = T("title")
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextTruncate = Enum.TextTruncate.AtEnd
Title.Parent = TitleBar
regLabel(Title, "title")
if customMenuTitle ~= "" then Title.Text = customMenuTitle end

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
RightPanel.Size = UDim2.new(1, -155, 1, -50)
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

-- ===== Resize grip =====
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Name = "ResizeGrip"
ResizeGrip.Size = UDim2.new(0, 16, 0, 16)
ResizeGrip.Position = UDim2.new(1, -18, 1, -18)
ResizeGrip.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ResizeGrip.Text = "◢"
ResizeGrip.TextColor3 = Color3.fromRGB(170, 170, 170)
ResizeGrip.TextSize = 12
ResizeGrip.Font = Enum.Font.GothamBold
ResizeGrip.BorderSizePixel = 0
ResizeGrip.AutoButtonColor = false
ResizeGrip.ZIndex = 5
ResizeGrip.Parent = Menu
Instance.new("UICorner", ResizeGrip).CornerRadius = UDim.new(0, 4)

local resizing = false
local resizeStartPos, resizeStartSize = nil, nil

ResizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = Menu.AbsoluteSize
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
                if conn then conn:Disconnect() end
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if not resizing then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - resizeStartPos
    local newW = math.max(MIN_W, resizeStartSize.X + d.X)
    local newH = math.max(MIN_H, resizeStartSize.Y + d.Y)
    Menu.Size = UDim2.fromOffset(newW, newH)
end)

-- ============ UI REFS ============
local uiRefs = {}

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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
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

    local state = initialState and true or false
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)

    local function setState(newState, skipCallback)
        state = newState and true or false
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if not skipCallback and callback then callback(state) end
    end

    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return { row = row, getState = function() return state end, setState = setState }
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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.new(1, 1, 1)
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

    local state = initState and true or false
    local value = tonumber(initVal or defaultVal)
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)

    local function setState(newState, skipCallback)
        state = newState and true or false
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if not skipCallback and callback then callback(state, value) end
    end
    local function setValue(newValue, skipCallback)
        if not newValue then return end
        value = newValue
        tb.Text = tostring(newValue)
        if not skipCallback and callback then callback(state, value) end
    end

    tb.FocusLost:Connect(function()
        local n = tonumber(tb.Text)
        if n then
            value = n
            if callback then callback(state, value) end
        elseif value then
            tb.Text = tostring(value)
        end
    end)

    btn.MouseButton1Click:Connect(function() setState(not state) end)

    return {
        row = row, getState = function() return state end,
        getValue = function() return value end,
        setState = setState, setValue = setValue,
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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.new(1, 1, 1)
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

local function createInputText(parent, labelKey, placeholderText, callback, initialText)
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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -125, 0, 24)
    tb.Position = UDim2.new(0, 115, 0.5, -12)
    tb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tb.TextColor3 = Color3.new(1, 1, 1)
    tb.Text = initialText or ""
    tb.PlaceholderText = T(placeholderText)
    tb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    tb.Font = Enum.Font.Gotham; tb.TextSize = 13
    tb.BorderSizePixel = 0
    tb.Parent = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)
    regLabel(tb, placeholderText, "PlaceholderText")

    tb.FocusLost:Connect(function()
        if callback then callback(tb.Text) end
    end)
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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.new(1, 1, 1)
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

    local state = initState and true or false
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)

    local function setState(newState, skipCallback)
        state = newState and true or false
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if not skipCallback and callback then callback(state, tb.Text) end
    end
    local function setText(newText, skipCallback)
        tb.Text = newText or ""
        if not skipCallback and callback then callback(state, tb.Text) end
    end

    tb.FocusLost:Connect(function() if callback then callback(state, tb.Text) end end)
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    return {
        row = row, getState = function() return state end,
        getText = function() return tb.Text end,
        setState = setState, setText = setText,
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

local function createButtonRaw(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = color or Color3.fromRGB(0, 120, 200)
    btn.Text = text; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local pad = Instance.new("UIPadding", btn)
    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
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
    row.Size = UDim2.new(1, 0, 0, 64)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = T(labelKey)
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local swCont = Instance.new("Frame")
    swCont.Size = UDim2.new(1, -120, 0, 22)
    swCont.Position = UDim2.new(0, 115, 0, 6)
    swCont.BackgroundTransparency = 1
    swCont.Parent = row
    local swList = Instance.new("UIListLayout")
    swList.FillDirection = Enum.FillDirection.Horizontal
    swList.Padding = UDim.new(0, 4)
    swList.VerticalAlignment = Enum.VerticalAlignment.Center
    swList.Parent = swCont

    local swatches = {}
    local function clearSelection()
        for _, s in pairs(swatches) do
            s.BorderColor3 = Color3.fromRGB(80, 80, 80)
            s.BorderSizePixel = 1
        end
    end

    for _, c in ipairs(COLORS) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 20, 0, 20)
        sw.BackgroundColor3 = c.color
        sw.Text = ""
        sw.BorderSizePixel = 1
        sw.BorderColor3 = Color3.fromRGB(80, 80, 80)
        sw.AutoButtonColor = false
        sw.Parent = swCont
        Instance.new("UICorner", sw).CornerRadius = UDim.new(0, 3)
        swatches[c.name] = sw
        sw.MouseButton1Click:Connect(function()
            if callback then callback(c.color) end
            clearSelection()
            sw.BorderColor3 = Color3.new(1, 1, 1)
            sw.BorderSizePixel = 2
        end)
    end

    local hexCont = Instance.new("Frame")
    hexCont.Size = UDim2.new(1, -120, 0, 22)
    hexCont.Position = UDim2.new(0, 115, 0, 32)
    hexCont.BackgroundTransparency = 1
    hexCont.Parent = row

    local hexLbl = Instance.new("TextLabel")
    hexLbl.Size = UDim2.new(0, 40, 1, 0)
    hexLbl.BackgroundTransparency = 1
    hexLbl.Text = "Hex:"
    hexLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    hexLbl.TextXAlignment = Enum.TextXAlignment.Left
    hexLbl.Font = Enum.Font.Gotham; hexLbl.TextSize = 12
    hexLbl.Parent = hexCont

    local hexTb = Instance.new("TextBox")
    hexTb.Size = UDim2.new(1, -60, 0, 20)
    hexTb.Position = UDim2.new(0, 40, 0.5, -10)
    hexTb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hexTb.TextColor3 = Color3.new(1, 1, 1)
    hexTb.PlaceholderText = "#RRGGBB"
    hexTb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    hexTb.Text = ""
    hexTb.Font = Enum.Font.Gotham; hexTb.TextSize = 12
    hexTb.BorderSizePixel = 0
    hexTb.Parent = hexCont
    Instance.new("UICorner", hexTb).CornerRadius = UDim.new(0, 3)

    local function hexToColor(str)
        str = tostring(str or ""):gsub("#", "")
        if #str == 6 then
            local r = tonumber(str:sub(1, 2), 16)
            local g = tonumber(str:sub(3, 4), 16)
            local b = tonumber(str:sub(5, 6), 16)
            if r and g and b then return Color3.fromRGB(r, g, b) end
        end
        return nil
    end

    hexTb.FocusLost:Connect(function()
        local c = hexToColor(hexTb.Text)
        if c and callback then
            callback(c)
            clearSelection()
            hexTb.Text = string.format("#%02X%02X%02X",
                math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
        end
    end)

    if currentColor then
        for _, s in pairs(swatches) do
            if colorDist(s.BackgroundColor3, currentColor) < 0.05 then
                s.BorderColor3 = Color3.new(1, 1, 1)
                s.BorderSizePixel = 2
            end
        end
        hexTb.Text = string.format("#%02X%02X%02X",
            math.floor(currentColor.R*255),
            math.floor(currentColor.G*255),
            math.floor(currentColor.B*255))
    end

    return row
end

-- ============ STATUS HELPERS ============
local function getMoonPhaseKey()
    local ok, phase = pcall(function() return Lighting.MoonPhase end)
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
    lbl.Text = T(labelKey); lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.Parent = row
    regLabel(lbl, labelKey)

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(1, -160, 1, 0)
    val.Position = UDim2.new(0, 150, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = "..."; val.TextColor3 = Color3.new(1, 1, 1)
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Font = Enum.Font.GothamBold; val.TextSize = 13
    val.TextTruncate = Enum.TextTruncate.AtEnd
    val.Parent = row
    return row, val
end

-- ============ FLY ============
function startFly()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    stopFly()
    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent = hrp
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
    flyConn = RS.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        local c = LP.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h or not flyBodyVel or not flyBodyGyro then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        flyBodyVel.Velocity = dir * flySpeed
        flyBodyGyro.CFrame = cam.CFrame
    end)
end

function stopFly()
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

-- ============ FULLBRIGHT ============
local function enableFullbright()
    if fullbrightSaved then return end
    fullbrightSaved = {
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness     = Lighting.Brightness,
        FogEnd         = Lighting.FogEnd,
        FogStart       = Lighting.FogStart,
        GlobalShadows  = Lighting.GlobalShadows,
        ClockTime      = Lighting.ClockTime,
    }
    Lighting.Ambient        = Color3.fromRGB(180, 180, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    Lighting.Brightness     = 2
    Lighting.FogEnd         = 1e9
    Lighting.FogStart       = 1e9
    Lighting.GlobalShadows  = false
    Lighting.ClockTime       = 14
end

local function disableFullbright()
    if not fullbrightSaved then return end
    Lighting.Ambient        = fullbrightSaved.Ambient
    Lighting.OutdoorAmbient = fullbrightSaved.OutdoorAmbient
    Lighting.Brightness     = fullbrightSaved.Brightness
    Lighting.FogEnd         = fullbrightSaved.FogEnd
    Lighting.FogStart       = fullbrightSaved.FogStart
    Lighting.GlobalShadows  = fullbrightSaved.GlobalShadows
    Lighting.ClockTime       = fullbrightSaved.ClockTime
    fullbrightSaved = nil
end

-- ============ HITBOX ============
function applyHitbox(player)
    if player == LP then return end
    local char = player.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
            and part.Name ~= "Head" then
            if hitboxSaved[part] == nil then
                hitboxSaved[part] = { size = part.Size, transparency = part.Transparency }
            end
            part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            part.Transparency = 0.7
            part.CanCollide = false
        end
    end
end

function applyHitboxAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then applyHitbox(p) end
    end
end

local function removeHitboxAll()
    for part, s in pairs(hitboxSaved) do
        if part and part.Parent then
            part.Size = s.size
            part.Transparency = s.transparency
        end
    end
    hitboxSaved = {}
end

-- ============ ANTI-VOID ============
local function captureSafePosition()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then lastSafeCFrame = hrp.CFrame end
end

RS.Heartbeat:Connect(function()
    if not antiVoidEnabled then return end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp.Position.Y < -50 and lastSafeCFrame then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = lastSafeCFrame + Vector3.new(0, 3, 0)
        end)
    elseif hrp.Position.Y > -30 then
        captureSafePosition()
    end
end)

-- ============ FREECAM ============
local freecamConn = nil

local function startFreecam()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    savedFreecamSubject = cam.CameraSubject
    savedFreecamType = cam.CameraType
    freecamCFrame = cam.CFrame
    cam.CameraType = Enum.CameraType.Scriptable
    freecamConn = RS.RenderStepped:Connect(function(dt)
        if not freecamEnabled then return end
        local c = Workspace.CurrentCamera
        if not c then return end
        local move = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then move += freecamCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= freecamCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= freecamCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then move += freecamCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        freecamCFrame = freecamCFrame + move * (freecamSpeed * dt)
        c.CFrame = freecamCFrame
    end)
end

local function stopFreecam()
    if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
    local cam = Workspace.CurrentCamera
    if cam then
        cam.CameraSubject = savedFreecamSubject or (LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"))
        cam.CameraType = savedFreecamType or Enum.CameraType.Custom
    end
    savedFreecamSubject = nil; savedFreecamType = nil; freecamCFrame = nil
end

-- ============ PLAYER LIST (state externo p/ refresh) ============
local playerListContainer = nil
local playerListSearch = ""
local selectedPlayer = nil

local function refreshPlayerList()
    if not playerListContainer or not playerListContainer.Parent then return end
    for _, c in ipairs(playerListContainer:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local lpChar = LP.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    local lpPos = lpHRP and lpHRP.Position
    local lsearch = playerListSearch:lower()

    local players = Players:GetPlayers()
    table.sort(players, function(a, b) return a.Name:lower() < b.Name:lower() end)

    for _, p in ipairs(players) do
        if p ~= LP then
            local nm = p.Name:lower()
            local dn = p.DisplayName:lower()
            if lsearch == "" or nm:find(lsearch, 1, true) or dn:find(lsearch, 1, true) then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 36)
                row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                row.BorderSizePixel = 0
                row.Parent = playerListContainer
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -240, 1, 0)
                nameLbl.Position = UDim2.new(0, 8, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextColor3 = Color3.new(1, 1, 1)
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                local info = p.Name
                local ch = p.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hum then
                    info = info .. "  [" .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth) .. "]"
                end
                if hrp and lpPos then
                    info = info .. "  " .. math.floor((hrp.Position - lpPos).Magnitude) .. "m"
                end
                nameLbl.Text = info
                nameLbl.Parent = row

                local btnCont = Instance.new("Frame")
                btnCont.Size = UDim2.new(0, 225, 1, 0)
                btnCont.Position = UDim2.new(1, -230, 0, 0)
                btnCont.BackgroundTransparency = 1
                btnCont.Parent = row
                local bl = Instance.new("UIListLayout", btnCont)
                bl.FillDirection = Enum.FillDirection.Horizontal
                bl.Padding = UDim.new(0, 4)
                bl.VerticalAlignment = Enum.VerticalAlignment.Center
                bl.HorizontalAlignment = Enum.HorizontalAlignment.Right

                createButtonRaw(btnCont, "TP", Color3.fromRGB(0, 120, 200), function()
                    tpToPlayer(p)
                end)
                createButtonRaw(btnCont, "Follow", Color3.fromRGB(0, 150, 80), function()
                    loopTPTarget = p.Name
                    loopTPEnabled = true
                    if refOK and uiRefs.loopTP then
                        setRefText(uiRefs.loopTP, p.Name)
                        setRefState(uiRefs.loopTP, true)
                    end
                end)
                createButtonRaw(btnCont, "Spec", Color3.fromRGB(140, 60, 200), function()
                    spectateTarget = p.Name
                    spectateEnabled = true
                    local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    local cam = Workspace.CurrentCamera
                    if h and cam then
                        if not savedCameraSubject then
                            savedCameraSubject = cam.CameraSubject
                            savedCameraType = cam.CameraType
                        end
                        cam.CameraSubject = h
                        cam.CameraType = Enum.CameraType.Custom
                    end
                end)
            end
        end
    end
end

-- ============ BUILDERS ============
local function buildFisico(parent)
    uiRefs.speed = createInputNumToggle(parent, "speed", "16", function(state, value)
        speedEnabled = state
        if value then speedValue = value end
        if not state then
            local hum = getHumanoid()
            if hum and savedSpeed ~= nil then hum.WalkSpeed = savedSpeed end
            savedSpeed = nil
        end
    end, speedEnabled, speedValue)

    uiRefs.jump = createInputNumToggle(parent, "jump", "50", function(state, value)
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
        end
    end, jumpEnabled, jumpValue)

    uiRefs.infJump = createToggle(parent, "inf_jump", function(state) infJumpEnabled = state end, infJumpEnabled)

    uiRefs.fly = createInputNumToggle(parent, "fly", "50", function(state, value)
        flyEnabled = state
        if value then flySpeed = value end
        if state then startFly() else stopFly() end
    end, flyEnabled, flySpeed)

    uiRefs.gravity = createToggle(parent, "gravity", function(state) gravityEnabled = state end, gravityEnabled)
end

local function buildMagico(parent)
    createInputButton(parent, "teleport", "tp_ph", "TP", function(name)
        local target = findPlayerByName(name)
        if target then tpToPlayer(target) end
    end)

    uiRefs.loopTP = createInputTextToggle(parent, "loop_tp", "tp_ph", function(state, name)
        loopTPEnabled = state
        loopTPTarget = name or ""
    end, loopTPEnabled, loopTPTarget)

    uiRefs.noclip = createToggle(parent, "noclip", function(state)
        noclipEnabled = state
        if not state then
            for part, saved in pairs(noclipSaved) do
                if part and part.Parent then part.CanCollide = saved end
            end
            noclipSaved = {}
        end
    end, noclipEnabled)

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
end

local function buildJogadores(parent)
    -- Search bar
    local searchRow = Instance.new("Frame")
    searchRow.Size = UDim2.new(1, 0, 0, 32)
    searchRow.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    searchRow.BorderSizePixel = 0
    searchRow.Parent = parent
    Instance.new("UICorner", searchRow).CornerRadius = UDim.new(0, 4)

    local searchTb = Instance.new("TextBox")
    searchTb.Size = UDim2.new(1, -90, 0, 24)
    searchTb.Position = UDim2.new(0, 8, 0.5, -12)
    searchTb.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    searchTb.TextColor3 = Color3.new(1, 1, 1)
    searchTb.PlaceholderText = T("search_ph")
    searchTb.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    searchTb.Text = ""
    searchTb.Font = Enum.Font.Gotham; searchTb.TextSize = 13
    searchTb.BorderSizePixel = 0
    searchTb.Parent = searchRow
    Instance.new("UICorner", searchTb).CornerRadius = UDim.new(0, 4)
    regLabel(searchTb, "search_ph", "PlaceholderText")

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 76, 0, 24)
    refreshBtn.Position = UDim2.new(1, -84, 0.5, -12)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    refreshBtn.Text = T("refresh")
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.Font = Enum.Font.GothamBold; refreshBtn.TextSize = 12
    refreshBtn.BorderSizePixel = 0; refreshBtn.AutoButtonColor = false
    refreshBtn.Parent = searchRow
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
    regLabel(refreshBtn, "refresh")
    refreshBtn.MouseButton1Click:Connect(function() refreshPlayerList() end)

    searchTb:GetPropertyChangedSignal("Text"):Connect(function()
        playerListSearch = searchTb.Text or ""
        refreshPlayerList()
    end)

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = parent

    local ll = Instance.new("UIListLayout", listFrame)
    ll.Padding = UDim.new(0, 4)

    playerListContainer = listFrame
    refreshPlayerList()

    task.spawn(function()
        while playerListContainer and playerListContainer.Parent do
            task.wait(1)
            if playerListContainer and playerListContainer.Parent then
                refreshPlayerList()
            end
        end
    end)
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

    uiRefs.esp = createToggle(parent, "esp", function(state)
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
    end, espEnabled)

    uiRefs.xray = createToggle(parent, "xray", function(state)
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
    end, xrayEnabled)

    uiRefs.fullbright = createToggle(parent, "fullbright", function(state)
        fullbrightEnabled = state
        if state then enableFullbright() else disableFullbright() end
    end, fullbrightEnabled)

    uiRefs.hitbox = createInputNumToggle(parent, "hitbox", "10", function(state, value)
        hitboxEnabled = state
        if value then hitboxSize = value end
        if state then applyHitboxAll() else removeHitboxAll() end
    end, hitboxEnabled, hitboxSize)
end

local function buildCamera(parent)
    uiRefs.freecam = createInputNumToggle(parent, "freecam", "40", function(state, value)
        freecamEnabled = state
        if value then freecamSpeed = value end
        if state then startFreecam() else stopFreecam() end
    end, freecamEnabled, freecamSpeed)

    uiRefs.fov = createInputNumToggle(parent, "fov", "70", function(state, value)
        if value then
            fovValue = value
            local cam = Workspace.CurrentCamera
            if cam then cam.FieldOfView = state and value or defaultFOV end
        end
    end, false, fovValue)

    uiRefs.spectate = createInputTextToggle(parent, "spectate", "tp_ph", function(state, name)
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
    end, spectateEnabled, spectateTarget)
end

local function buildWaypoints(parent)
    createInputButton(parent, "wp_name", "wp_name", T("wp_save"), function(name)
        if name == "" then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        waypoints[name] = { x = hrp.CFrame.X, y = hrp.CFrame.Y, z = hrp.CFrame.Z }
        showToast("Waypoint salvo: " .. name, Color3.fromRGB(0, 170, 0), 2)
        selectCategory(categories[6]) -- refresh waypoints
    end)

    local names = {}
    for n in pairs(waypoints) do table.insert(names, n) end
    table.sort(names)

    if #names == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 32)
        lbl.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        lbl.Text = T("wp_none"); lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.BorderSizePixel = 0
        lbl.Parent = parent
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
        regLabel(lbl, "wp_none")
        return
    end

    for _, name in ipairs(names) do
        local wp = waypoints[name]
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -170, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
        lbl.Parent = row

        local btnCont = Instance.new("Frame")
        btnCont.Size = UDim2.new(0, 160, 1, 0)
        btnCont.Position = UDim2.new(1, -165, 0, 0)
        btnCont.BackgroundTransparency = 1
        btnCont.Parent = row
        local bl = Instance.new("UIListLayout", btnCont)
        bl.FillDirection = Enum.FillDirection.Horizontal
        bl.Padding = UDim.new(0, 4)
        bl.VerticalAlignment = Enum.VerticalAlignment.Center
        bl.HorizontalAlignment = Enum.HorizontalAlignment.Right

        createButtonRaw(btnCont, T("wp_goto"), Color3.fromRGB(0, 120, 200), function()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and wp then
                pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
                hrp.CFrame = CFrame.new(wp.x, wp.y, wp.z)
            end
        end)
        createButtonRaw(btnCont, T("wp_del"), Color3.fromRGB(200, 50, 50), function()
            waypoints[name] = nil
            showToast("Waypoint removido: " .. name, Color3.fromRGB(200, 60, 60), 2)
            selectCategory(categories[6])
        end)
    end
end

local function buildUtilidades(parent)
    uiRefs.antiAfk = createToggle(parent, "anti_afk", function(state)
        antiAfkEnabled = state
    end, antiAfkEnabled)

    uiRefs.autoClicker = createInputNumToggle(parent, "auto_clicker", "10", function(state, value)
        autoClickerEnabled = state
        if value then autoClickerCPS = value end
    end, autoClickerEnabled, autoClickerCPS)

    uiRefs.antiVoid = createToggle(parent, "anti_void", function(state)
        antiVoidEnabled = state
        if state then
            captureSafePosition()
        end
    end, antiVoidEnabled)

    createButton(parent, "reset_char", function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end)

    createButton(parent, "rejoin", function()
        pcall(function() TPS:Teleport(game.PlaceId, LP) end)
    end)

    createButton(parent, "server_hop", function()
        local function hop()
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local ok, resp = pcall(function() return game:HttpGet(url) end)
            if not ok or not resp then
                showToast("Server hop falhou", Color3.fromRGB(200, 60, 60), 2)
                return
            end
            local data = HttpService:JSONDecode(resp)
            local candidates = {}
            for _, srv in ipairs(data.data or {}) do
                if srv.id and srv.id ~= game.JobId and (srv.playing or 0) < (srv.maxPlayers or 0) then
                    table.insert(candidates, srv.id)
                end
            end
            if #candidates == 0 then
                showToast("Nenhum servidor disponível", Color3.fromRGB(200, 60, 60), 2)
                return
            end
            local chosen = candidates[math.random(1, #candidates)]
            pcall(function() TPS:TeleportToPlaceInstance(game.PlaceId, chosen, LP) end)
        end
        task.spawn(hop)
    end)
end

-- ============ STATUS ============
local statusGeneration = 0
local function buildStatus(parent)
    statusGeneration = statusGeneration + 1
    local myGen = statusGeneration

    local _, gameNameVal = makeInfoRow(parent, "game_name")
    local _, playersVal  = makeInfoRow(parent, "players")
    local _, moonVal     = makeInfoRow(parent, "moon_phase")
    local _, serverVal   = makeInfoRow(parent, "server")
    local _, pingVal     = makeInfoRow(parent, "ping")
    local _, fpsVal      = makeInfoRow(parent, "fps")

    local cachedGameName = game.Name
    task.spawn(function()
        local ok, info = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        end)
        if ok and info and info.Name and info.Name ~= "" then
            cachedGameName = info.Name
        end
    end)

    local fpsAccum, fpsFrames = 0, 0

    local function update()
        if myGen ~= statusGeneration then return false end
        if not gameNameVal.Parent then return false end
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
        -- Ping
        pcall(function()
            local stats = game:GetService("Stats")
            local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            pingVal.Text = ping
        end)
        -- FPS
        local fps = math.floor(1 / math.max(RS.RenderStepped:Wait(), 1e-6))
        fpsVal.Text = tostring(fps)
        return true
    end
    update()
    task.spawn(function()
        while myGen == statusGeneration do
            task.wait(1)
            if not update() then break end
        end
    end)
end

-- ============ SAVE / SETTINGS ============
local function saveConfig()
    local cfg = {
        iconColor = colorToTable(Icon.BackgroundColor3),
        menuColor = colorToTable(Menu.BackgroundColor3),
        menuRGB   = menuRGBEnabled,
        iconRGB   = iconRGBEnabled,
        language  = currentLanguage,
        menuTitle = customMenuTitle,
        iconText  = customIconText,
        menuSize  = { w = math.floor(Menu.AbsoluteSize.X), h = math.floor(Menu.AbsoluteSize.Y) },
        menuPos   = { x = math.floor(Menu.Position.X.Offset), y = math.floor(Menu.Position.Y.Offset) },
        iconPos   = { x = math.floor(Icon.Position.X.Offset), y = math.floor(Icon.Position.Y.Offset) },
        speed     = { enabled = speedEnabled, value = speedValue },
        jump      = { enabled = jumpEnabled,  value = jumpValue  },
        infJump   = infJumpEnabled,
        noclip    = noclipEnabled,
        loopTP    = { enabled = loopTPEnabled, target = loopTPTarget },
        gravity   = gravityEnabled,
        esp       = espEnabled,
        xray      = xrayEnabled,
        spectate  = { enabled = spectateEnabled, target = spectateTarget },
        flySpeed        = flySpeed,
        autoClickerCPS  = autoClickerCPS,
        freecamSpeed    = freecamSpeed,
        hitboxSize      = hitboxSize,
        fov             = fovValue,
        waypoints       = waypoints,
    }
    _G.__AdminPanelCfg = cfg
    local ok, encoded = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok and encoded then
        pcall(function() if writefile then writefile(CONFIG_FILE, encoded) end end)
    end
    showToast(T("saved"), Color3.fromRGB(0, 170, 0), 2)
end

local function buildSettings(parent)
    createInputText(parent, "menu_title", "title", function(text)
        customMenuTitle = text or ""
        if customMenuTitle == "" then
            Title.Text = T("title")
        else
            Title.Text = customMenuTitle
        end
    end, customMenuTitle)

    createInputText(parent, "icon_text", "AP", function(text)
        customIconText = text or ""
        setIconText(customIconText)
    end, customIconText)

    createColorPalette(parent, "icon_color", function(color)
        Icon.BackgroundColor3 = color
    end, Icon.BackgroundColor3)

    createColorPalette(parent, "menu_color", function(color)
        Menu.BackgroundColor3 = color
        TitleBar.BackgroundColor3 = color
        TitleBarCover.BackgroundColor3 = color
    end, Menu.BackgroundColor3)

    createToggle(parent, "menu_rgb", function(state)
        menuRGBEnabled = state
        if not state then menuStroke.Color = Color3.fromRGB(70, 70, 70) end
    end, menuRGBEnabled)

    createToggle(parent, "icon_rgb", function(state)
        iconRGBEnabled = state
        if not state then iconStroke.Color = Color3.fromRGB(80, 80, 80) end
    end, iconRGBEnabled)

    -- Language row
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
    lbl.Text = T("language"); lbl.TextColor3 = Color3.new(1, 1, 1)
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
    langBtnRef = langBtn  -- FIX: para applyLanguage atualizar

    local dropdown
    local function closeDropdown()
        if dropdown then dropdown:Destroy(); dropdown = nil end
    end
    langBtn.MouseButton1Click:Connect(function()
        if dropdown then closeDropdown(); return end
        local itemH = 24
        dropdown = Instance.new("Frame")
        dropdown.Size = UDim2.new(0, 150, 0, math.min(#LANGUAGES * itemH + 4, 300))
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
        local scroll = Instance.new("ScrollingFrame", dropdown)
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 4
        scroll.CanvasSize = UDim2.new(0, 0, 0, #LANGUAGES * itemH)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ll = Instance.new("UIListLayout", scroll)
        for _, lang in ipairs(LANGUAGES) do
            local opt = Instance.new("TextButton")
            opt.Size = UDim2.new(1, 0, 0, itemH)
            opt.BackgroundTransparency = 1
            opt.Text = lang.name
            opt.TextColor3 = Color3.new(1, 1, 1)
            opt.Font = Enum.Font.Gotham; opt.TextSize = 12
            opt.ZIndex = 30
            opt.Parent = scroll
            opt.MouseButton1Click:Connect(function()
                currentLanguage = lang.code
                applyLanguage()
                if customMenuTitle ~= "" then Title.Text = customMenuTitle end
                closeDropdown()
            end)
        end
    end)
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

    -- Hotkeys info
    local hkLbl = Instance.new("TextLabel")
    hkLbl.Size = UDim2.new(1, 0, 0, 32)
    hkLbl.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    hkLbl.Text = T("hotkeys")
    hkLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    hkLbl.Font = Enum.Font.Gotham; hkLbl.TextSize = 11
    hkLbl.BorderSizePixel = 0
    hkLbl.TextWrapped = true
    hkLbl.Parent = parent
    Instance.new("UICorner", hkLbl).CornerRadius = UDim.new(0, 4)
    regLabel(hkLbl, "hotkeys")

    createButton(parent, "save", function() saveConfig() end)
end

-- ============ CATEGORIES ============
local categories = {
    { name = "Físico",     key = "cat_fisico",  builder = buildFisico },
    { name = "Mágico",     key = "cat_magico",  builder = buildMagico },
    { name = "Jogadores",  key = "cat_players", builder = buildJogadores },
    { name = "Visual",     key = "cat_visual",  builder = buildVisual },
    { name = "Câmera",     key = "cat_camera",  builder = buildCamera },
    { name = "Waypoints",  key = "cat_waypoints",builder = buildWaypoints },
    { name = "Utilidades", key = "cat_util",    builder = buildUtilidades },
    { name = "Status",     key = "cat_status",  builder = buildStatus },
    { name = "Configurações", key = "cat_config", builder = buildSettings },
}
local categoryBtns = {}

function selectCategory(cat)
    for _, c in ipairs(RightScroll:GetChildren()) do
        if c:IsA("GuiObject") and not c:IsA("UIListLayout") then c:Destroy() end
    end
    for k in pairs(uiRefs) do uiRefs[k] = nil end

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
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = T(cat.key)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
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

-- FIX: só JumpRequest (removeu duplicação do Space poll)
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

RS.Heartbeat:Connect(function()
    if loopTPEnabled and loopTPTarget ~= "" then
        local target = findPlayerByName(loopTPTarget)
        if target then tpToPlayer(target) end
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if not antiAfkEnabled then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Auto-Clicker
task.spawn(function()
    while true do
        if autoClickerEnabled then
            local cps = math.max(1, math.floor(autoClickerCPS))
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new())
            end)
            task.wait(1 / cps)
        else
            task.wait(0.2)
        end
    end
end)

-- Anti-Void fallback rápido
task.spawn(function()
    while true do
        task.wait(0.2)
        if antiVoidEnabled then
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -50 and lastSafeCFrame then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = lastSafeCFrame + Vector3.new(0, 3, 0)
                end)
            end
        end
    end
end)

-- ESP update + health/distance
local espAccum = 0
RS.Heartbeat:Connect(function(dt)
    if not espEnabled then return end
    espAccum = espAccum + dt
    if espAccum < 0.1 then return end
    espAccum = 0

    local lpChar = LP.Character
    local lpHRP = lpChar and lpChar:FindFirstChild("HumanoidRootPart")
    local lpPos = lpHRP and lpHRP.Position

    for p, d in pairs(espData) do
        local char = p.Character
        if char and d.label and d.label.Parent then
            local newColor = Color3.fromRGB(255, 255, 255)
            if p.Team then newColor = p.Team.TeamColor.Color end
            if d.teamColor ~= newColor then
                d.teamColor = newColor
                d.label.TextColor3 = newColor
                if d.highlight then
                    d.highlight.FillColor = newColor
                    d.highlight.OutlineColor = newColor
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and lpPos then
                local dist = math.floor((hrp.Position - lpPos).Magnitude)
                d.label.Text = string.format("%s [%d/%d] [%dm]",
                    p.Name, math.floor(hum.Health), math.floor(hum.MaxHealth), dist)
            elseif hum then
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

-- RGB animation
local rgbT = 0
RS.RenderStepped:Connect(function(dt)
    rgbT = rgbT + dt
    if menuRGBEnabled then
        menuStroke.Color = Color3.fromHSV((rgbT * 0.2) % 1, 1, 1)
    end
    if iconRGBEnabled then
        iconStroke.Color = Color3.fromHSV((rgbT * 0.2 + 0.5) % 1, 1, 1)
    end
end)

-- Background loops
task.spawn(function()
    while true do
        task.wait(0.25)
        if xrayEnabled then
            if next(xraySaved) == nil then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and not isCharacterPart(obj) then
                        xraySaved[obj] = { t = obj.Transparency, r = obj.Reflectance }
                    end
                end
            end
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

-- ============ HOTKEYS ============
local HOTKEYS = {
    [Enum.KeyCode.F] = function() -- Fly
        flyEnabled = not flyEnabled
        if flyEnabled then startFly() else stopFly() end
        if uiRefs.fly then setRefState(uiRefs.fly, flyEnabled) end
        showToast("Fly " .. (flyEnabled and "ON" or "OFF"), flyEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.N] = function()
        noclipEnabled = not noclipEnabled
        if not noclipEnabled then
            for part, saved in pairs(noclipSaved) do
                if part and part.Parent then part.CanCollide = saved end
            end
            noclipSaved = {}
        end
        if uiRefs.noclip then setRefState(uiRefs.noclip, noclipEnabled) end
        showToast("Noclip " .. (noclipEnabled and "ON" or "OFF"), noclipEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.J] = function()
        infJumpEnabled = not infJumpEnabled
        if uiRefs.infJump then setRefState(uiRefs.infJump, infJumpEnabled) end
        showToast("Inf Jump " .. (infJumpEnabled and "ON" or "OFF"), infJumpEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.E] = function()
        espEnabled = not espEnabled
        if espEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then tryCreateESPLoop(p) end
            end
        else
            local list = {}
            for p in pairs(espData) do table.insert(list, p) end
            for _, p in ipairs(list) do destroyESPForPlayer(p) end
        end
        if uiRefs.esp then setRefState(uiRefs.esp, espEnabled) end
        showToast("ESP " .. (espEnabled and "ON" or "OFF"), espEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.G] = function()
        gravityEnabled = not gravityEnabled
        if uiRefs.gravity then setRefState(uiRefs.gravity, gravityEnabled) end
        showToast("Gravity " .. (gravityEnabled and "ON" or "OFF"), gravityEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.X] = function()
        xrayEnabled = not xrayEnabled
        if xrayEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not isCharacterPart(obj) then
                    if xraySaved[obj] == nil then
                        xraySaved[obj] = { t = obj.Transparency, r = obj.Reflectance }
                    end
                    obj.Transparency = 0.75; obj.Reflectance = 0
                end
            end
        else
            for obj, s in pairs(xraySaved) do
                if obj and obj.Parent then obj.Transparency = s.t; obj.Reflectance = s.r end
            end
            xraySaved = {}
        end
        if uiRefs.xray then setRefState(uiRefs.xray, xrayEnabled) end
        showToast("X-Ray " .. (xrayEnabled and "ON" or "OFF"), xrayEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
    [Enum.KeyCode.V] = function()
        antiVoidEnabled = not antiVoidEnabled
        if antiVoidEnabled then captureSafePosition() end
        if uiRefs.antiVoid then setRefState(uiRefs.antiVoid, antiVoidEnabled) end
        showToast("Anti-Void " .. (antiVoidEnabled and "ON" or "OFF"), antiVoidEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(120,60,60), 1)
    end,
}

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    -- Ignora se está digitando em TextBox
    local focused = UIS:GetFocusedTextBox()
    if focused then return end
    local fn = HOTKEYS[input.KeyCode]
    if fn then
        local ok, err = pcall(fn)
        if not ok then warn("Hotkey error: " .. tostring(err)) end
    end
end)

-- ============================================
-- SISTEMA DE COMANDOS VIA CHAT
-- ============================================
local CMD_PREFIX = "!"

function showToast(text, color, duration)
    duration = duration or 2
    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(0, 400, 0, 42)
    toast.Position = UDim2.new(0.5, -200, 0, 20)
    toast.BackgroundColor3 = color or Color3.fromRGB(0, 170, 0)
    toast.BackgroundTransparency = 0.05
    toast.TextColor3 = Color3.new(1, 1, 1)
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 13
    toast.Text = text
    toast.TextWrapped = true
    toast.Parent = gui
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 6)
    toast.ZIndex = 60
    task.spawn(function()
        task.wait(duration)
        for i = 1, 20 do
            toast.BackgroundTransparency = 0.05 + i / 22
            toast.TextTransparency = i / 20
            task.wait(0.03)
        end
        toast:Destroy()
    end)
end

local function refOK(r) return r and r.row and r.row.Parent ~= nil end
local function setRefState(ref, st) if refOK(ref) then ref.setState(st, true) end end
local function setRefValue(ref, v)  if refOK(ref) then ref.setValue(v, true) end end
local function setRefText(ref, t)   if refOK(ref) then ref.setText(t, true) end end

-- SETTERS
local function cmdSpeed(val)
    local wasEnabled = speedEnabled
    if val then
        speedValue = tonumber(val) or speedValue
        speedEnabled = true
    else
        speedEnabled = not speedEnabled
    end
    local hum = getHumanoid()
    if hum then
        if speedEnabled then
            if not wasEnabled and savedSpeed == nil then savedSpeed = hum.WalkSpeed end
            hum.WalkSpeed = speedValue
        elseif savedSpeed then
            hum.WalkSpeed = savedSpeed; savedSpeed = nil
        end
    end
    if refOK(uiRefs.speed) then
        setRefValue(uiRefs.speed, speedValue)
        setRefState(uiRefs.speed, speedEnabled)
    end
    return "Speed " .. (speedEnabled and ("ON (" .. speedValue .. ")") or "OFF")
end

local function cmdJump(val)
    local wasEnabled = jumpEnabled
    if val then
        jumpValue = tonumber(val) or jumpValue
        jumpEnabled = true
    else
        jumpEnabled = not jumpEnabled
    end
    local hum = getHumanoid()
    if hum then
        if jumpEnabled then
            if not wasEnabled and savedJump == nil then
                savedJump = {
                    useJumpPower = hum.UseJumpPower,
                    jumpPower    = hum.JumpPower,
                    jumpHeight   = hum.JumpHeight,
                }
            end
            if hum.UseJumpPower then hum.JumpPower = jumpValue else hum.JumpHeight = jumpValue end
        elseif savedJump then
            hum.UseJumpPower = savedJump.useJumpPower
            hum.JumpPower    = savedJump.jumpPower
            hum.JumpHeight   = savedJump.jumpHeight
            savedJump = nil
        end
    end
    if refOK(uiRefs.jump) then
        setRefValue(uiRefs.jump, jumpValue)
        setRefState(uiRefs.jump, jumpEnabled)
    end
    return "Jump " .. (jumpEnabled and ("ON (" .. jumpValue .. ")") or "OFF")
end

local function cmdInfJump()
    infJumpEnabled = not infJumpEnabled
    setRefState(uiRefs.infJump, infJumpEnabled)
    return "Infinite Jump " .. (infJumpEnabled and "ON" or "OFF")
end

local function cmdNoclip()
    noclipEnabled = not noclipEnabled
    if not noclipEnabled then
        for part, saved in pairs(noclipSaved) do
            if part and part.Parent then part.CanCollide = saved end
        end
        noclipSaved = {}
    end
    setRefState(uiRefs.noclip, noclipEnabled)
    return "Noclip " .. (noclipEnabled and "ON" or "OFF")
end

local function cmdGravity()
    gravityEnabled = not gravityEnabled
    setRefState(uiRefs.gravity, gravityEnabled)
    return "Gravity " .. (gravityEnabled and "ON" or "OFF")
end

local function cmdESP()
    espEnabled = not espEnabled
    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then tryCreateESPLoop(p) end
        end
    else
        local list = {}
        for p in pairs(espData) do table.insert(list, p) end
        for _, p in ipairs(list) do destroyESPForPlayer(p) end
    end
    setRefState(uiRefs.esp, espEnabled)
    return "ESP " .. (espEnabled and "ON" or "OFF")
end

local function cmdXray()
    xrayEnabled = not xrayEnabled
    if xrayEnabled then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not isCharacterPart(obj) then
                if xraySaved[obj] == nil then
                    xraySaved[obj] = { t = obj.Transparency, r = obj.Reflectance }
                end
                obj.Transparency = 0.75; obj.Reflectance = 0
            end
        end
    else
        for obj, s in pairs(xraySaved) do
            if obj and obj.Parent then obj.Transparency = s.t; obj.Reflectance = s.r end
        end
        xraySaved = {}
    end
    setRefState(uiRefs.xray, xrayEnabled)
    return "X-Ray " .. (xrayEnabled and "ON" or "OFF")
end

local function cmdTp(name)
    if not name then return "Uso: !tp <nome>" end
    local target = findPlayerByName(name)
    if not target then return "Jogador não encontrado: " .. name end
    tpToPlayer(target)
    return "Teleportado para " .. target.Name
end

local function cmdLoopTp(name)
    if name then
        local target = findPlayerByName(name)
        if not target then return "Jogador não encontrado: " .. name end
        loopTPTarget = target.Name
        loopTPEnabled = true
    else
        if loopTPEnabled then
            loopTPEnabled = false; loopTPTarget = ""
        elseif loopTPTarget == "" then
            return "Loop TP precisa de um alvo. Uso: !looptp <nome>"
        else
            loopTPEnabled = true
        end
    end
    if refOK(uiRefs.loopTP) then
        setRefText(uiRefs.loopTP, loopTPTarget)
        setRefState(uiRefs.loopTP, loopTPEnabled)
    end
    return "Loop TP " .. (loopTPEnabled and ("ON (" .. loopTPTarget .. ")") or "OFF")
end

local function cmdSpectate(name)
    if name then
        local target = findPlayerByName(name)
        if not target then return "Jogador não encontrado: " .. name end
        spectateTarget = target.Name; spectateEnabled = true
    else
        if spectateEnabled then
            spectateEnabled = false; spectateTarget = ""; restoreCamera()
        elseif spectateTarget == "" then
            return "Spectate precisa de um alvo. Uso: !spectate <nome>"
        else
            spectateEnabled = true
        end
    end
    if refOK(uiRefs.spectate) then
        setRefText(uiRefs.spectate, spectateTarget)
        setRefState(uiRefs.spectate, spectateEnabled)
    end
    return "Spectate " .. (spectateEnabled and ("ON (" .. spectateTarget .. ")") or "OFF")
end

local function cmdOptimize()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            for _, c in ipairs(obj:GetChildren()) do
                if c:IsA("Texture") or c:IsA("Decal") or c:IsA("SurfaceAppearance") then c:Destroy() end
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
            or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("Light") then obj.Enabled = false
        elseif obj:IsA("Atmosphere") then obj.Density = 0 end
    end
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("PostEffect") then obj.Enabled = false end
    end
    Lighting.GlobalShadows = false; Lighting.FogEnd = 1e5
    return "Jogo otimizado"
end

local function cmdTpTool()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if not bp then return "Sem backpack" end
    local existing = bp:FindFirstChild("TP Tool")
    if existing then existing:Destroy() end
    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"; tool.RequiresHandle = false; tool.CanBeDropped = false
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
    return "TP Tool recebida"
end

local function cmdFly(val)
    if val then flySpeed = tonumber(val) or flySpeed; flyEnabled = true
    else flyEnabled = not flyEnabled end
    if flyEnabled then startFly() else stopFly() end
    if refOK(uiRefs.fly) then
        setRefValue(uiRefs.fly, flySpeed); setRefState(uiRefs.fly, flyEnabled)
    end
    return "Fly " .. (flyEnabled and ("ON (" .. flySpeed .. ")") or "OFF")
end

local function cmdFullbright()
    fullbrightEnabled = not fullbrightEnabled
    if fullbrightEnabled then enableFullbright() else disableFullbright() end
    setRefState(uiRefs.fullbright, fullbrightEnabled)
    return "Fullbright " .. (fullbrightEnabled and "ON" or "OFF")
end

local function cmdAntiAfk()
    antiAfkEnabled = not antiAfkEnabled
    setRefState(uiRefs.antiAfk, antiAfkEnabled)
    return "Anti-AFK " .. (antiAfkEnabled and "ON" or "OFF")
end

local function cmdAutoClicker(val)
    if val then autoClickerCPS = tonumber(val) or autoClickerCPS; autoClickerEnabled = true
    else autoClickerEnabled = not autoClickerEnabled end
    if refOK(uiRefs.autoClicker) then
        setRefValue(uiRefs.autoClicker, autoClickerCPS)
        setRefState(uiRefs.autoClicker, autoClickerEnabled)
    end
    return "Auto-Clicker " .. (autoClickerEnabled and ("ON (" .. autoClickerCPS .. " CPS)") or "OFF")
end

local function cmdAntiVoid()
    antiVoidEnabled = not antiVoidEnabled
    if antiVoidEnabled then captureSafePosition() end
    setRefState(uiRefs.antiVoid, antiVoidEnabled)
    return "Anti-Void " .. (antiVoidEnabled and "ON" or "OFF")
end

local function cmdFov(val)
    val = tonumber(val)
    if not val then return "Uso: !fov <número>" end
    fovValue = val
    local cam = Workspace.CurrentCamera
    if cam then cam.FieldOfView = val end
    return "FOV definido para " .. val
end

local function cmdFreecam()
    freecamEnabled = not freecamEnabled
    if freecamEnabled then startFreecam() else stopFreecam() end
    setRefState(uiRefs.freecam, freecamEnabled)
    return "Freecam " .. (freecamEnabled and "ON" or "OFF")
end

local function cmdRejoin()
    pcall(function() TPS:Teleport(game.PlaceId, LP) end)
    return "Rejoining..."
end

local function cmdReset()
    local hum = getHumanoid()
    if hum then hum.Health = 0; return "Personagem resetado" end
    return "Sem Humanoid"
end

local function cmdPing()
    local stats = game:GetService("Stats")
    local p = stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    return "Ping: " .. p
end

local function cmdWp(args)
    local sub = args[1] and args[1]:lower() or ""
    if sub == "save" then
        local name = args[2]
        if not name then return "Uso: !wp save <nome>" end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return "Sem personagem" end
        waypoints[name] = { x = hrp.CFrame.X, y = hrp.CFrame.Y, z = hrp.CFrame.Z }
        return "Waypoint salvo: " .. name
    elseif sub == "goto" then
        local name = args[2]
        if not name then return "Uso: !wp goto <nome>" end
        local wp = waypoints[name]
        if not wp then return "Waypoint não encontrado: " .. name end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            hrp.CFrame = CFrame.new(wp.x, wp.y, wp.z)
        end
        return "Indo para waypoint: " .. name
    elseif sub == "del" then
        local name = args[2]
        if not name then return "Uso: !wp del <nome>" end
        waypoints[name] = nil
        return "Waypoint removido: " .. name
    elseif sub == "list" then
        local names = {}
        for n in pairs(waypoints) do table.insert(names, n) end
        table.sort(names)
        if #names == 0 then return "Nenhum waypoint" end
        warn("Waypoints: " .. table.concat(names, ", "))
        return #names .. " waypoint(s) no console"
    else
        return "Uso: !wp save|goto|del|list <nome>"
    end
end

local function cmdAllOff()
    if speedEnabled    then cmdSpeed()    end
    if jumpEnabled     then cmdJump()     end
    if infJumpEnabled  then cmdInfJump()  end
    if noclipEnabled   then cmdNoclip()   end
    if gravityEnabled  then cmdGravity()  end
    if espEnabled      then cmdESP()      end
    if xrayEnabled     then cmdXray()     end
    if loopTPEnabled   then cmdLoopTp()   end
    if spectateEnabled then cmdSpectate() end
    if flyEnabled      then cmdFly()      end
    if fullbrightEnabled then cmdFullbright() end
    if antiAfkEnabled  then cmdAntiAfk()  end
    if autoClickerEnabled then cmdAutoClicker() end
    if antiVoidEnabled then cmdAntiVoid() end
    if freecamEnabled  then cmdFreecam()  end
    if hitboxEnabled   then
        hitboxEnabled = false; removeHitboxAll()
    end
    return "Todos os recursos desativados"
end

local function cmdHelp()
    local lines = {
        "Comandos (prefixo " .. CMD_PREFIX .. "):",
        "Físico: !speed [n] | !jump [n] | !infjump | !fly [n] | !gravity",
        "Mágico: !tp <nome> | !looptp [nome] | !tptool | !noclip",
        "Visual: !esp | !xray | !fullbright | !optimize",
        "Câmera: !spectate [nome] | !freecam | !fov <n>",
        "Waypoints: !wp save|goto|del|list <nome>",
        "Util: !antiafk | !autoclicker [cps] | !antivoid | !reset | !rejoin | !ping",
        "Geral: !off | !help",
    }
    warn(table.concat(lines, "\n"))
    showToast("Comandos no console (F9). Use !help para ver todos.", Color3.fromRGB(0, 120, 200), 4)
    return "Ver console"
end

-- PARSER
local COMMANDS = {
    speed       = function(a) return cmdSpeed(a[1])     end,
    jump        = function(a) return cmdJump(a[1])      end,
    infjump     = function()  return cmdInfJump()       end,
    noclip      = function()  return cmdNoclip()        end,
    gravity     = function()  return cmdGravity()       end,
    esp         = function()  return cmdESP()           end,
    xray        = function()  return cmdXray()          end,
    tp          = function(a) return cmdTp(a[1])        end,
    goto        = function(a) return cmdTp(a[1])        end,
    looptp      = function(a) return cmdLoopTp(a[1])    end,
    follow      = function(a) return cmdLoopTp(a[1])    end,
    spectate    = function(a) return cmdSpectate(a[1])  end,
    optimize    = function()  return cmdOptimize()      end,
    tptool      = function()  return cmdTpTool()        end,
    fly         = function(a) return cmdFly(a[1])       end,
    fullbright  = function()  return cmdFullbright()    end,
    antiafk     = function()  return cmdAntiAfk()       end,
    autoclicker = function(a) return cmdAutoClicker(a[1]) end,
    antivoid    = function()  return cmdAntiVoid()      end,
    fov         = function(a) return cmdFov(a[1])       end,
    freecam     = function()  return cmdFreecam()       end,
    rejoin      = function()  return cmdRejoin()        end,
    reset       = function()  return cmdReset()         end,
    ping        = function()  return cmdPing()          end,
    wp          = function(a) return cmdWp(a)           end,
    off         = function()  return cmdAllOff()        end,
    help        = function()  return cmdHelp()          end,
}

local function processChatCommand(text)
    if not text or text:sub(1, #CMD_PREFIX) ~= CMD_PREFIX then return false end
    local body = text:sub(#CMD_PREFIX + 1)
    if body == "" then return false end

    local args = {}
    for word in body:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return false end

    local cmdName = args[1]:lower()
    table.remove(args, 1)

    local handler = COMMANDS[cmdName]
    if not handler then
        showToast("Comando desconhecido: " .. cmdName .. " (use !help)", Color3.fromRGB(200, 60, 60), 2)
        return true
    end

    local ok, result = pcall(handler, args)
    if ok then
        showToast(result or ("OK: " .. cmdName), Color3.fromRGB(0, 170, 0), 2)
    else
        showToast("Erro em !" .. cmdName .. ": " .. tostring(result), Color3.fromRGB(200, 60, 60), 3)
    end
    return true
end

LP.Chatted:Connect(function(message)
    processChatCommand(message)
end)

-- ============ INIT ============
-- Aplica FOV salvo
if fovValue and Workspace.CurrentCamera then
    Workspace.CurrentCamera.FieldOfView = fovValue
end

showToast("Admin Hub v2.0 carregado! Digite !help no chat.", Color3.fromRGB(0, 140, 90), 4)