extends Control

const GAME_SCENE := "res://scenes/survival.tscn"
const BG := Color("#080b12")
const PANEL := Color("#111722")
const RUST := Color("#8d3d32")
const GOLD := Color("#c69a60")

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var frame := CenterContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color("#49352f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 42
	style.content_margin_right = 42
	style.content_margin_top = 34
	style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", style)
	frame.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(0, 170)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_path := "res://assets/reset_night_logo.jpg"
	if ResourceLoader.exists(logo_path):
		logo.texture = load(logo_path)
	else:
		var fallback := Label.new()
		fallback.text = "RESET\nNIGHT"
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 58)
		fallback.add_theme_color_override("font_color", GOLD)
		column.add_child(fallback)
	column.add_child(logo)

	var tagline := Label.new()
	tagline.text = "GECE BAŞLADI  •  SABAHI GÖR"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", GOLD)
	tagline.add_theme_font_size_override("font_size", 16)
	column.add_child(tagline)

	var title := Label.new()
	title.text = "HAYATTA KAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#eee5dc"))
	column.add_child(title)

	var description := Label.new()
	description.text = "Şehir karanlığa gömüldü. Kaynakları topla, saldırganlardan kurtul ve gün doğana kadar hayatta kal."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color("#aeb4bf"))
	description.add_theme_font_size_override("font_size", 18)
	column.add_child(description)

	var play := _make_button("HAYATTA KAL", RUST)
	play.pressed.connect(_start_game)
	column.add_child(play)

	var footer := Label.new()
	footer.text = "TEK KİŞİLİK  •  ÇEVRİMDIŞI  •  KAYITLI REKOR"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("#78808d"))
	footer.add_theme_font_size_override("font_size", 13)
	column.add_child(footer)

func _make_button(caption: String, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 66)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#fff8f0"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(12)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
