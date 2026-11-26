extends Node
## RESET NIGHT oyun yöneticisi: gece sayacı, dalgalar, skor, ölüm ve şafak (zafer) ekranı.

const NIGHT_LENGTH := 420.0
const SUPPLY_CACHE_GOAL := 3
const SUPPLY_CACHE_REWARD := 750
const SAVE_PATH := "user://save_game.dat"
const RECORD_PATH := "user://records.cfg"
const MENU_SCENE := "res://scenes/ui/MainMenu3D.tscn"
const WAVES := [
    {"at": 0.20, "count": 5, "text": "İLK DALGA — MASKELİLER GELİYOR!"},
    {"at": 0.45, "count": 8, "text": "SİRENLER ÇALIYOR — DALGA YAKLAŞIYOR!"},
    {"at": 0.70, "count": 11, "text": "ÜÇÜNCÜ DALGA — SAVUN KENDİNİ!"},
    {"at": 0.90, "count": 14, "text": "SON DALGA — ŞAFAĞA AZ KALDI!"}
]

var time_left := NIGHT_LENGTH
var finished := false
var kills := 0
var score := 0
var caches_found := 0
var _objective_refresh := 0.0
var _wave_index := 0
var _flash_alpha := 0.0
var _phase_timer := 0.0
var _layer: CanvasLayer
var _timer_label: Label
var _stats_label: Label
var _objective_label: Label
var _phase_label: Label
var _flash: ColorRect
var _end_root: Control
var _end_title: Label
var _end_text: Label
var _fog_env: Environment

func _ready() -> void:
    add_to_group("director")
    _build_ui()
    var world := get_tree().root.find_child("WorldEnvironment", true, false)
    if world is WorldEnvironment:
        _fog_env = (world as WorldEnvironment).environment
    _show_phase("ARINMA BAŞLADI — MAHALLEYİ SAVUN, ŞAFAĞI GÖR", 4.5)
    _update_objective()

func get_intensity() -> float:
    return clampf(1.0 - time_left / NIGHT_LENGTH, 0.0, 1.0)

func register_kill(points: int) -> void:
    kills += 1
    score += points

func on_player_hit(amount: float) -> void:
    _flash_alpha = clampf(0.25 + amount / 40.0, 0.25, 0.6)

func player_died() -> void:
    _end(false)

func _process(delta: float) -> void:
    if finished:
        return
    time_left = maxf(0.0, time_left - delta)
    _objective_refresh -= delta
    if _objective_refresh <= 0.0:
        _objective_refresh = 0.35
        _update_objective()
    var secs := int(ceil(time_left))
    _timer_label.text = "ŞAFAĞA  %02d:%02d" % [floori(secs / 60.0), secs % 60]
    _stats_label.text = "ÖLDÜRÜLEN %d     SKOR %d" % [kills, score]
    if _flash_alpha > 0.0:
        _flash_alpha = maxf(0.0, _flash_alpha - delta * 0.9)
        _flash.color = Color(0.7, 0.0, 0.02, _flash_alpha)
    if _phase_timer > 0.0:
        _phase_timer -= delta
        _phase_label.modulate.a = clampf(_phase_timer, 0.0, 1.0)
    if _wave_index < WAVES.size() and get_intensity() >= float(WAVES[_wave_index]["at"]):
        var wave: Dictionary = WAVES[_wave_index]
        _wave_index += 1
        _show_phase(str(wave["text"]), 4.0)
        _spawn_wave(int(wave["count"]))
    if _fog_env != null:
        var t := get_intensity()
        _fog_env.fog_light_color = Color(0.13, 0.15, 0.20).lerp(Color(0.26, 0.07, 0.08), t)
    if time_left <= 0.0:
        _end(true)

func _spawn_wave(count: int) -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var spawner := scene.get_node_or_null("EnemySpawner")
    if spawner != null and spawner.has_method("spawn_wave"):
        spawner.spawn_wave(count)

func _update_objective() -> void:
    var found := 0
    var total := 0
    for container in get_tree().get_nodes_in_group("loot_containers"):
        if not is_instance_valid(container):
            continue
        total += 1
        if bool(container.get("searched")):
            found += 1
    caches_found = found
    if is_instance_valid(_objective_label):
        _objective_label.text = "GÖREV: HAYATTA KAL  •  MALZEME SANDIKLARI %d/%d" % [found, mini(SUPPLY_CACHE_GOAL, total)]

func _show_phase(text: String, seconds: float) -> void:
    if _phase_label == null:
        return
    _phase_label.text = text
    _phase_timer = seconds
    _phase_label.modulate.a = 1.0

func _end(won: bool) -> void:
    if finished:
        return
    finished = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var survived := int(NIGHT_LENGTH - time_left)
    var cache_bonus := SUPPLY_CACHE_REWARD if won and caches_found >= SUPPLY_CACHE_GOAL else 0
    var final_score := score + (1500 if won else 0) + cache_bonus
    var best := _save_record(final_score)
    _end_title.text = "ŞAFAK DOĞDU — HAYATTA KALDIN" if won else "ARINMA SENİ ALDI"
    _end_title.add_theme_color_override("font_color", Color("#7fd18b") if won else Color("#ff5b55"))
    _end_text.text = "Dayanılan süre: %02d:%02d\nÖldürülen: %d\nSkor: %d\nREKOR: %d" % [floori(survived / 60.0), survived % 60, kills, final_score, best]
    _end_root.visible = true
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.set("_busy", true)
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    get_tree().paused = true

func _save_record(final_score: int) -> int:
    var config := ConfigFile.new()
    config.load(RECORD_PATH)
    var best := int(config.get_value("records", "best_score", 0))
    if final_score > best:
        best = final_score
        config.set_value("records", "best_score", best)
        config.save(RECORD_PATH)
    return best

func _release_save_lock() -> void:
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.set("_busy", false)

func _restart() -> void:
    _release_save_lock()
    get_tree().paused = false
    get_tree().reload_current_scene()

func _to_menu() -> void:
    _release_save_lock()
    get_tree().paused = false
    get_tree().change_scene_to_file(MENU_SCENE)

# ---------------------------------------------------------------- arayüz

func _build_ui() -> void:
    _layer = CanvasLayer.new()
    _layer.layer = 30
    _layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layer.add_child(root)

    _flash = ColorRect.new()
    _flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _flash.color = Color(0.7, 0.0, 0.02, 0.0)
    root.add_child(_flash)

    _add_crosshair(root)

    _timer_label = _make_label(root, 26, Color("#f2c078"))
    _timer_label.anchor_left = 0.5
    _timer_label.anchor_right = 0.5
    _timer_label.offset_left = -170.0
    _timer_label.offset_right = 170.0
    _timer_label.offset_top = 62.0
    _timer_label.offset_bottom = 98.0
    _timer_label.text = "ŞAFAĞA  07:00"

    _stats_label = _make_label(root, 15, Color("#e8dccf"))
    _stats_label.anchor_left = 0.5
    _stats_label.anchor_right = 0.5
    _stats_label.offset_left = -170.0
    _stats_label.offset_right = 170.0
    _stats_label.offset_top = 98.0
    _stats_label.offset_bottom = 124.0

    _objective_label = _make_label(root, 14, Color("#e8dccf"))
    _objective_label.anchor_left = 0.5
    _objective_label.anchor_right = 0.5
    _objective_label.offset_left = -230.0
    _objective_label.offset_right = 230.0
    _objective_label.offset_top = 126.0
    _objective_label.offset_bottom = 151.0
    _phase_label = _make_label(root, 30, Color("#ff5b55"))
    _phase_label.anchor_left = 0.0
    _phase_label.anchor_right = 1.0
    _phase_label.anchor_top = 0.28
    _phase_label.anchor_bottom = 0.28
    _phase_label.offset_top = 0.0
    _phase_label.offset_bottom = 60.0
    _phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _phase_label.modulate.a = 0.0

    _build_end_screen(root)

func _add_crosshair(root: Control) -> void:
    var parts := [Rect2(-12, -1, 7, 2), Rect2(5, -1, 7, 2), Rect2(-1, -12, 2, 7), Rect2(-1, 5, 2, 7)]
    for item in parts:
        var rect: Rect2 = item
        var bar := ColorRect.new()
        bar.color = Color(1.0, 1.0, 1.0, 0.8)
        bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        bar.anchor_left = 0.5
        bar.anchor_right = 0.5
        bar.anchor_top = 0.5
        bar.anchor_bottom = 0.5
        bar.offset_left = rect.position.x
        bar.offset_top = rect.position.y
        bar.offset_right = rect.end.x
        bar.offset_bottom = rect.end.y
        root.add_child(bar)

func _make_label(parent: Control, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
    label.add_theme_constant_override("outline_size", 5)
    parent.add_child(label)
    return label

func _build_end_screen(root: Control) -> void:
    _end_root = Control.new()
    _end_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _end_root.mouse_filter = Control.MOUSE_FILTER_STOP
    _end_root.visible = false
    root.add_child(_end_root)
    var dim := ColorRect.new()
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0.0, 0.0, 0.0, 0.72)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _end_root.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _end_root.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(440, 0)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#0b0d11")
    panel_style.border_color = Color("#8b2028")
    panel_style.set_border_width_all(3)
    panel_style.set_corner_radius_all(8)
    panel_style.set_content_margin_all(22)
    panel.add_theme_stylebox_override("panel", panel_style)
    center.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    panel.add_child(column)
    _end_title = Label.new()
    _end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _end_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _end_title.add_theme_font_size_override("font_size", 30)
    column.add_child(_end_title)
    _end_text = Label.new()
    _end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _end_text.add_theme_font_size_override("font_size", 19)
    _end_text.add_theme_color_override("font_color", Color("#e8dccf"))
    column.add_child(_end_text)
    column.add_child(_make_button("TEKRAR DENE", _restart))
    column.add_child(_make_button("ANA MENÜ", _to_menu))

func _make_button(caption: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(0, 62)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color.WHITE)
    for state in ["normal", "hover", "pressed", "focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#3a1216") if state != "pressed" else Color("#6b1a20")
        style.border_color = Color("#8b2028")
        style.set_border_width_all(2)
        style.set_corner_radius_all(6)
        button.add_theme_stylebox_override(state, style)
    button.pressed.connect(action)
    return button
