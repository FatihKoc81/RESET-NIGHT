extends Control

const GAME_SCENE := "res://scenes/survival.tscn"
const PANEL := Color("#10151e")
const RUST := Color("#7f302d")
const GOLD := Color("#c59a62")
var overlay: PanelContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#07090e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.48, 0.48, 0.48, 0.42)
	if ResourceLoader.exists("res://assets/reset_night_logo.jpg"):
		art.texture = load("res://assets/reset_night_logo.jpg")
	add_child(art)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.03, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.045, 0.06, 0.94)
	panel_style.border_color = Color("#60463a")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 38
	panel_style.content_margin_right = 38
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)

	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(0, 155)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/reset_night_logo.jpg"):
		logo.texture = load("res://assets/reset_night_logo.jpg")
	col.add_child(logo)

	var strap := _label("GECE BAŞLADI  •  SABAHI GÖR", 15, GOLD)
	col.add_child(strap)
	var title := _label("RESET NIGHT", 34, Color("#e8ded2"))
	col.add_child(title)
	var subtitle := _label("Şehir karanlığa gömüldü. Kaynakları topla, saldırganlardan kurtul ve gün doğana kadar hayatta kal.", 16, Color("#aeb4bf"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(subtitle)

	var start := _button("OYUNA BAŞLA", RUST)
	start.pressed.connect(func(): get_tree().change_scene_to_file(GAME_SCENE))
	col.add_child(start)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var settings := _button("AYARLAR", Color("#263241"))
	settings.pressed.connect(func(): _show_info("AYARLAR", "Ses ve kontrol seçenekleri bir sonraki geliştirme aşamasında açılacak."))
	row.add_child(settings)
	var inventory := _button("ENVANTER", Color("#263241"))
	inventory.pressed.connect(func(): _show_info("ENVANTER", "Envanter sistemi hazırlanıyor."))
	row.add_child(inventory)

	var exit := _button("ÇIKIŞ", Color("#302326"))
	exit.pressed.connect(func(): get_tree().quit())
	col.add_child(exit)

	var footer := _label("TEK KİŞİLİK  •  ÇEVRİMDIŞI  •  KAYITLI REKOR", 12, Color("#777f8b"))
	col.add_child(footer)

func _label(value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _button(caption: String, color: Color) -> Button:
	var b := Button.new()
	b.text = caption
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("#fff5e9"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = Color("#98704e")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.14)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	return b

func _show_info(heading: String, message: String) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.position = Vector2(-210, -90)
	overlay.custom_minimum_size = Vector2(420, 180)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)
	var box := VBoxContainer.new()
	overlay.add_child(box)
	box.add_child(_label(heading, 22, GOLD))
	var body := _label(message, 15, Color("#e1ded8"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	var close := _button("KAPAT", RUST)
	close.pressed.connect(func(): overlay.queue_free())
	box.add_child(close)
