extends Control

const GAME_SCENE := "res://scenes/Main3D.tscn"
const BUILDER = preload("res://scripts/ui_asset_builder.gd")

var _continue_button: Button
var _notice: Label

func _ready() -> void:
    _build_menu()
    get_viewport().size_changed.connect(_layout_menu)
    _layout_menu()
    _continue_button.disabled = not FileAccess.file_exists("user://save_game.dat")

func _build_menu() -> void:
    theme = BUILDER.new().setup_theme()
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("#0a0b0e")
    add_child(background)

    var haze := ColorRect.new()
    haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
    haze.color = Color(0.10, 0.025, 0.035, 0.24)
    background.add_child(haze)

    var content := VBoxContainer.new()
    content.name = "MenuContent"
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    content.add_theme_constant_override("separation", 12)
    content.custom_minimum_size = Vector2(340, 480)
    add_child(content)

    var eyebrow := Label.new()
    eyebrow.text = "SURVIVE THE DARK"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 13)
    eyebrow.add_theme_color_override("font_color", Color("#b5a7a2"))
    content.add_child(eyebrow)

    var title := Label.new()
    title.text = "RESET NIGHT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color("#d32f2f"))
    content.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "GECE ÇÖKTÜ. HAYATTA KAL."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("#aaa5a0"))
    content.add_child(subtitle)

    var gap := Control.new()
    gap.custom_minimum_size.y = 16
    content.add_child(gap)

    _add_button(content, "▶  OYUNA BAŞLA", _start_game)
    _continue_button = _add_button(content, "▣  DEVAM ET", _continue_game)
    _add_button(content, "⚙  AYARLAR", _open_settings)
    _add_button(content, "⌖  KONTROLLER", _show_controls)
    _add_button(content, "✕  ÇIKIŞ", _exit_game)

    _notice = Label.new()
    _notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _notice.add_theme_font_size_override("font_size", 12)
    _notice.add_theme_color_override("font_color", Color("#d6b8b8"))
    content.add_child(_notice)

    var footer := Label.new()
    footer.text = "RESET NIGHT  •  SINGLE PLAYER SURVIVAL"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override("font_color", Color("#77716e"))
    content.add_child(footer)

func _add_button(parent: VBoxContainer, caption: String, action: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(320, 52)
    button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    button.pressed.connect(action)
    parent.add_child(button)
    return button

func _layout_menu() -> void:
    var content := get_node_or_null("MenuContent") as Control
    if content:
        var w := minf(360.0, size.x - 32.0)
        content.custom_minimum_size.x = w
        content.position = Vector2((size.x - w) * 0.5, (size.y - 480.0) * 0.5)

func _start_game() -> void:
    get_tree().change_scene_to_file(GAME_SCENE)

func _continue_game() -> void:
    if not FileAccess.file_exists("user://save_game.dat"):
        _notice.text = "Henüz kayıtlı oyun bulunamadı."
        return
    get_tree().change_scene_to_file(GAME_SCENE)
    await get_tree().process_frame
    await get_tree().process_frame
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.load_game()

func _open_settings() -> void:
    _notice.text = "Ayarlar oyun içinde HUD üzerindeki AYARLAR bölümünden açılır."

func _show_controls() -> void:
    _notice.text = "HAREKET: sol alt joystick  •  KAMERA: sağ ekranı sürükle\nSALDIRI: SOPA / POMPALI  •  ETKİLEŞİM: ARA"

func _exit_game() -> void:
    get_tree().quit()
