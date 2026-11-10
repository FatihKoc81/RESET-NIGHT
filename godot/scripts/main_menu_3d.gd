extends Control

const GAME_SCENE := "res://scenes/maps/Map3D.tscn"
const BUILDER = preload("res://scripts/ui_asset_builder.gd")
const PORT := 2456

var _body: VBoxContainer
var _notice: Label
var _content: VBoxContainer
var _continue_button: Button
var _join_address: LineEdit
var _lobby_status: Label
var _selected_character := "leader"
var _settings := ConfigFile.new()

func _ready() -> void:
    theme = BUILDER.new().setup_theme()
    _settings.load("user://settings.cfg")
    _selected_character = str(_settings.get_value("player", "character", "leader"))
    _build_shell()
    _show_home()
    get_viewport().size_changed.connect(_layout_menu)
    _layout_menu()

func _build_shell() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("#080a0e")
    add_child(background)

    var haze := ColorRect.new()
    haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
    haze.color = Color(0.12, 0.025, 0.035, 0.20)
    background.add_child(haze)

    var scroll := ScrollContainer.new()
    scroll.name = "MenuScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 14
    scroll.offset_top = 18
    scroll.offset_right = -14
    scroll.offset_bottom = -18
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)

    _content = VBoxContainer.new()
    _content.name = "MenuContent"
    _content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content.add_theme_constant_override("separation", 12)
    scroll.add_child(_content)

    var eyebrow := _label("SURVIVE THE DARK", 13, "#b5a7a2")
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _content.add_child(eyebrow)
    var title := _label("RESET NIGHT", 38, "#d32f2f")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _content.add_child(title)
    var subtitle := _label("ÇEVRİMİÇİ / ÇEVRİMDIŞI DESTEKLİ", 13, "#d4c4bd")
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _content.add_child(subtitle)

    var line := HSeparator.new()
    _content.add_child(line)
    _body = VBoxContainer.new()
    _body.name = "MenuPage"
    _body.add_theme_constant_override("separation", 10)
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content.add_child(_body)

    _notice = _label("", 12, "#e1b8ad")
    _notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _content.add_child(_notice)

    var footer := _label("RESET NIGHT  •  SURVIVAL EXPERIENCE", 10, "#77716e")
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _content.add_child(footer)

func _layout_menu() -> void:
    if is_instance_valid(_content):
        _content.custom_minimum_size.x = maxf(280.0, size.x - 28.0)

func _label(value: String, font_size: int, color: String) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(color))
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func _clear_page() -> void:
    for child in _body.get_children():
        child.queue_free()
    _notice.text = ""

func _add_button(caption: String, action: Callable, min_height: int = 54) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(0, min_height)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    _body.add_child(button)
    return button

func _add_page_title(value: String) -> void:
    var label := _label(value, 22, "#f0e8e3")
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _body.add_child(label)

func _show_home() -> void:
    _clear_page()
    _add_page_title("GECE ÇÖKTÜ. HAYATTA KAL.")
    _add_button("🎮  OYNA / MOD SEÇİMİ", _show_modes, 64)
    _add_button("👤  KARAKTER SEÇİMİ / EŞYALAR", _show_characters)
    _add_button("⚙  AYARLAR", _show_settings)
    _add_button("🏆  LİDERLİK TABLOSU", _show_leaderboard)
    _continue_button = _add_button("▣  KAYITLI OYUNA DEVAM ET", _continue_game)
    _continue_button.disabled = not FileAccess.file_exists("user://save_game.dat")
    _add_button("✕  ÇIKIŞ", _exit_game, 46)

func _show_modes() -> void:
    _clear_page()
    _add_page_title("OYUN MODLARI")
    _add_button("💀  SOLO HAYATTA KALMA\nTek kişilik • Dalga tabanlı gece koruması", _start_solo, 76)
    _add_button("👥  CO-OP HAYATTA KALMA\n2–4 kişilik • Çevrimiçi / Yerel ağ", _show_coop, 76)
    _add_button("📜  HİKAYE & GÖREV MODU\nŞehirden kaçış • Bölge temizleme", _start_story, 76)
    _add_button("←  ANA MENÜ", _show_home, 46)

func _start_solo() -> void:
    _start_map("solo")

func _start_story() -> void:
    _start_map("story")

func _start_map(mode: String) -> void:
    var manager := get_node_or_null("/root/NetworkManager")
    if is_instance_valid(manager):
        manager.game_mode = mode
        if mode != "coop":
            manager.close_session()
    var error := get_tree().change_scene_to_file(GAME_SCENE)
    if error != OK:
        _notice.text = "Oyun alanı açılamadı. Hata kodu: %d" % error

func _show_coop() -> void:
    _clear_page()
    _add_page_title("CO-OP LOBİSİ")
    _body.add_child(_label("2–4 oyuncu • Aynı Wi-Fi / LAN veya yönlendirilebilir IP", 13, "#c4b9b4"))
    _add_button("ODA OLUŞTUR (HOST)", _host_game, 58)
    _join_address = LineEdit.new()
    _join_address.placeholder_text = "Oda sahibinin IP adresi (örn. 192.168.1.10)"
    _join_address.custom_minimum_size.y = 48
    _body.add_child(_join_address)
    _add_button("ODAYA KATIL", _join_game, 54)
    _lobby_status = _label("Henüz bir lobiye bağlanmadın.", 13, "#d4c4bd")
    _body.add_child(_lobby_status)
    _add_button("OYUNU BAŞLAT (HOST)", _start_coop, 58)
    _add_button("LOBİDEN AYRIL", _leave_lobby, 46)
    _add_button("←  MODLARA DÖN", _show_modes, 46)
    var manager := get_node_or_null("/root/NetworkManager")
    if is_instance_valid(manager):
        if not manager.lobby_status_changed.is_connected(_on_lobby_status_changed):
            manager.lobby_status_changed.connect(_on_lobby_status_changed)
        _lobby_status.text = manager.status_text

func _host_game() -> void:
    var manager := get_node_or_null("/root/NetworkManager")
    if not is_instance_valid(manager):
        _notice.text = "Ağ yöneticisi yüklenemedi."
        return
    var result: int = manager.host_game(PORT, 3)
    if result == OK:
        _lobby_status.text = manager.status_text
    else:
        _lobby_status.text = "Oda açılamadı. Hata kodu: %d" % result

func _join_game() -> void:
    var manager := get_node_or_null("/root/NetworkManager")
    if not is_instance_valid(manager):
        _notice.text = "Ağ yöneticisi yüklenemedi."
        return
    var address := _join_address.text.strip_edges()
    if address.is_empty():
        _lobby_status.text = "Katılmak için oda sahibinin IP adresini yaz."
        return
    var result: int = manager.join_game(address, PORT)
    if result == OK:
        _lobby_status.text = manager.status_text
    else:
        _lobby_status.text = "Bağlantı başlatılamadı. Hata kodu: %d" % result

func _on_lobby_status_changed(message: String) -> void:
    if is_instance_valid(_lobby_status):
        _lobby_status.text = message

func _leave_lobby() -> void:
    var manager := get_node_or_null("/root/NetworkManager")
    if is_instance_valid(manager):
        manager.close_session()
        _lobby_status.text = manager.status_text

func _start_coop() -> void:
    var manager := get_node_or_null("/root/NetworkManager")
    if not is_instance_valid(manager) or not manager.is_host:
        _lobby_status.text = "Oyunu yalnızca oda sahibi başlatabilir."
        return
    manager.game_mode = "coop"
    _start_map("coop")

func _show_characters() -> void:
    _clear_page()
    _add_page_title("KARAKTER SEÇİMİ / EŞYALAR")
    _body.add_child(_label("Aktif karakter: " + _character_title(_selected_character), 16, "#e6d8cf"))
    _add_button("🧥  LİDER / DERİ CEKET", func(): _select_character("leader"))
    _add_button("🪖  ÖNCÜ / TAKTİK EKİPMAN", func(): _select_character("vanguard"))
    _body.add_child(_label("Eşya ve envanter yönetimi oyun içinde açılır. Karakter görselleri çizgi roman shader stilindedir.", 13, "#c4b9b4"))
    _add_button("←  ANA MENÜ", _show_home, 46)

func _select_character(value: String) -> void:
    _selected_character = value
    _settings.set_value("player", "character", value)
    _settings.save("user://settings.cfg")
    _show_characters()

func _character_title(value: String) -> String:
    return "Lider" if value == "leader" else "Öncü"

func _show_settings() -> void:
    _clear_page()
    _add_page_title("AYARLAR")
    _body.add_child(_label("SES", 15, "#e6d8cf"))
    var volume := HSlider.new()
    volume.min_value = 0.0
    volume.max_value = 1.0
    volume.step = 0.05
    volume.value = float(_settings.get_value("audio", "master", 0.8))
    volume.value_changed.connect(_set_master_volume)
    _body.add_child(volume)
    _body.add_child(_label("DOKUNMATİK HASSASİYET", 15, "#e6d8cf"))
    var sensitivity := HSlider.new()
    sensitivity.min_value = 0.5
    sensitivity.max_value = 2.0
    sensitivity.step = 0.05
    sensitivity.value = float(_settings.get_value("controls", "touch_sensitivity", 1.0))
    sensitivity.value_changed.connect(_set_touch_sensitivity)
    _body.add_child(sensitivity)
    _body.add_child(_label("Grafik profili: Mobil uyumlu GL Compatibility (Godot proje ayarı).", 12, "#c4b9b4"))
    _add_button("←  ANA MENÜ", _show_home, 46)

func _set_master_volume(value: float) -> void:
    var bus := AudioServer.get_bus_index("Master")
    if bus >= 0:
        AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))
    _settings.set_value("audio", "master", value)
    _settings.save("user://settings.cfg")

func _set_touch_sensitivity(value: float) -> void:
    _settings.set_value("controls", "touch_sensitivity", value)
    _settings.save("user://settings.cfg")
    var mobile_input := get_node_or_null("/root/MobileInputManager")
    if is_instance_valid(mobile_input) and mobile_input.has_method("set_touch_sensitivity"):
        mobile_input.set_touch_sensitivity(0.005 * value)

func _show_leaderboard() -> void:
    _clear_page()
    _add_page_title("LİDERLİK TABLOSU")
    _body.add_child(_label("Çevrimiçi skor tablosu için sunucu/API henüz yapılandırılmadı. Bu ekran hazır; gerçek sıralama servisi bağlandığında skorlar burada gösterilecek.", 14, "#c4b9b4"))
    _add_button("←  ANA MENÜ", _show_home, 46)

func _continue_game() -> void:
    _start_map("solo")
    await get_tree().process_frame
    await get_tree().process_frame
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.load_game()

func _exit_game() -> void:
    get_tree().quit()
