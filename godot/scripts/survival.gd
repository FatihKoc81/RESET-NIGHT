extends Node2D

const WORLD_SIZE := Vector2(2200, 1400)
const PLAYER_SPEED := 300.0
const NIGHT_LENGTH := 180.0

var player_position := WORLD_SIZE * 0.5
var enemies: Array[Vector2] = []
var elapsed := 0.0
var health := 100.0
var score := 0
var spawn_clock := 0.0
var game_over := false
var health_bar: ProgressBar
var health_text: Label
var time_text: Label
var score_text: Label
var minimap: Control

func _ready() -> void:
	for i in range(5):
		_spawn_enemy()
	_build_hud()
	queue_redraw()

func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	spawn_clock += delta
	if spawn_clock >= 3.5:
		spawn_clock = 0.0
		_spawn_enemy()
	_update_player(delta)
	_update_enemies(delta)
	if elapsed >= NIGHT_LENGTH:
		_finish(true)
	elif health <= 0:
		_finish(false)
	_update_hud()
	queue_redraw()

func _update_player(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_position += direction * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, 24.0, WORLD_SIZE.x - 24.0)
	player_position.y = clampf(player_position.y, 24.0, WORLD_SIZE.y - 24.0)
	if Input.is_action_just_pressed("attack"):
		_attack()

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size()):
		var direction := (player_position - enemies[i]).normalized()
		enemies[i] += direction * 105.0 * delta
		if enemies[i].distance_to(player_position) < 42.0:
			health = maxf(0.0, health - 18.0 * delta)

func _spawn_enemy() -> void:
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * 620.0
	enemies.append((player_position + offset).clamp(Vector2.ZERO, WORLD_SIZE))

func _attack() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].distance_to(player_position) < 145.0:
			enemies.remove_at(i)
			score += 10

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var top_left := PanelContainer.new()
	top_left.position = Vector2(22, 18)
	top_left.custom_minimum_size = Vector2(270, 82)
	_style_panel(top_left)
	root.add_child(top_left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 5)
	top_left.add_child(left_box)
	health_text = _hud_label("SAĞLIK  100%", 17, Color("#e8ded2"))
	left_box.add_child(health_text)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(240, 17)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	left_box.add_child(health_bar)
	time_text = _hud_label("KALAN SÜRE  03:00", 15, Color("#d6b17a"))
	left_box.add_child(time_text)

	var top_right := PanelContainer.new()
	top_right.anchor_left = 1.0
	top_right.anchor_right = 1.0
	top_right.offset_left = -150
	top_right.offset_right = -20
	top_right.offset_top = 18
	top_right.offset_bottom = 148
	_style_panel(top_right)
	root.add_child(top_right)
	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(125, 125)
	minimap.draw.connect(_draw_minimap.bind(minimap))
	top_right.add_child(minimap)

	var bottom_left := HBoxContainer.new()
	bottom_left.anchor_top = 1.0
	bottom_left.anchor_bottom = 1.0
	bottom_left.offset_left = 22
	bottom_left.offset_top = -100
	bottom_left.offset_bottom = -22
	bottom_left.add_theme_constant_override("separation", 7)
	root.add_child(bottom_left)
	for action in ["move_left", "move_up", "move_down", "move_right"]:
		var caption := {"move_left":"◀", "move_up":"▲", "move_down":"▼", "move_right":"▶"}[action]
		bottom_left.add_child(_touch_button(caption, action, Vector2(62, 66)))

	var bottom_right := VBoxContainer.new()
	bottom_right.anchor_left = 1.0
	bottom_right.anchor_top = 1.0
	bottom_right.anchor_right = 1.0
	bottom_right.anchor_bottom = 1.0
	bottom_right.offset_left = -230
	bottom_right.offset_top = -142
	bottom_right.offset_right = -20
	bottom_right.offset_bottom = -20
	bottom_right.add_theme_constant_override("separation", 8)
	root.add_child(bottom_right)
	score_text = _hud_label("SKOR  0  •  CEPHANE  ∞", 15, Color("#e4c18e"))
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_right.add_child(score_text)
	var attack := _touch_button("SALDIR", "attack", Vector2(205, 76))
	bottom_right.add_child(attack)

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.06, 0.88)
	style.border_color = Color("#76513b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

func _hud_label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _touch_button(caption: String, action: String, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = dimensions
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#fff2e4"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.19, 0.88)
	style.border_color = Color("#8c6248")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	var down := style.duplicate()
	down.bg_color = Color("#77332f")
	button.add_theme_stylebox_override("pressed", down)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	return button

func _update_hud() -> void:
	if is_instance_valid(health_bar):
		health_bar.value = health
		health_text.text = "SAĞLIK  %d%%" % int(health)
		time_text.text = "KALAN SÜRE  %02d:%02d" % [int((NIGHT_LENGTH - elapsed) / 60.0), int((NIGHT_LENGTH - elapsed)) % 60]
		score_text.text = "SKOR  %d  •  CEPHANE  ∞" % score
		minimap.queue_redraw()

func _draw_minimap(control: Control) -> void:
	var center := control.size * 0.5
	var radius := minf(control.size.x, control.size.y) * 0.46
	control.draw_circle(center, radius, Color(0.025, 0.035, 0.045, 0.95))
	control.draw_arc(center, radius, 0, TAU, 64, Color("#987052"), 2.0)
	control.draw_circle(center, 4.5, Color("#e6d1ad"))
	for enemy in enemies:
		var relative := (enemy - player_position) / WORLD_SIZE * 250.0
		var dot := center + relative
		if dot.distance_to(center) < radius - 5:
			control.draw_circle(dot, 3.0, Color("#c24b45"))

func _finish(won: bool) -> void:
	game_over = true
	var layer := CanvasLayer.new()
	add_child(layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 180)
	_style_panel(panel)
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := _hud_label("SABAHI GÖRDÜN!" if won else "GECE SENİ YUTTU", 30, Color("#d6b17a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var result := _hud_label("TOPLAM SKOR: %d" % score, 18, Color("#eee4d8"))
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result)
	var button := Button.new()
	button.text = "ANA MENÜ"
	button.custom_minimum_size.y = 54
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	box.add_child(button)

func _draw() -> void:
	var view := get_viewport_rect().size
	var camera_offset := player_position - view * 0.5
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#10151b"))
	for x in range(0, int(WORLD_SIZE.x), 180):
		draw_line(Vector2(x, 0) - camera_offset, Vector2(x, WORLD_SIZE.y) - camera_offset, Color("#202832"), 2.0)
	for y in range(0, int(WORLD_SIZE.y), 180):
		draw_line(Vector2(0, y) - camera_offset, Vector2(WORLD_SIZE.x, y) - camera_offset, Color("#202832"), 2.0)
	for enemy in enemies:
		draw_circle(enemy - camera_offset, 19.0, Color("#914b45"))
	draw_circle(player_position - camera_offset, 22.0, Color("#c5b39a"))
