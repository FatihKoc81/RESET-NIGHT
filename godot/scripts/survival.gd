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

func _ready() -> void:
	for i in range(5):
		_spawn_enemy()
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

func _finish(won: bool) -> void:
	game_over = true
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ui := CanvasLayer.new()
	add_child(ui)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position = Vector2(-220, -90)
	box.custom_minimum_size = Vector2(440, 180)
	ui.add_child(overlay)
	ui.add_child(box)
	var label := Label.new()
	label.text = "SABAHI GÖRDÜN!" if won else "GECE SENİ YUTTU"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	box.add_child(label)
	var button := Button.new()
	button.text = "ANA MENÜ"
	button.custom_minimum_size.y = 60
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	box.add_child(button)

func _draw() -> void:
	var view := get_viewport_rect().size
	var camera_offset := player_position - view * 0.5
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#10151b"))
	for x in range(0, int(WORLD_SIZE.x), 180):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color("#202832"), 2.0)
	for y in range(0, int(WORLD_SIZE.y), 180):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color("#202832"), 2.0)
	for enemy in enemies:
		draw_circle(enemy - camera_offset, 19.0, Color("#914b45"))
	draw_circle(player_position - camera_offset, 22.0, Color("#c5b39a"))
	draw_rect(Rect2(Vector2(24, 24), Vector2(220, 16)), Color("#3a2024"))
	draw_rect(Rect2(Vector2(24, 24), Vector2(220.0 * health / 100.0, 16)), Color("#b64c48"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 68), "KALAN SÜRE: %03d" % int(maxf(0, NIGHT_LENGTH - elapsed)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e6ddd0"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 98), "SKOR: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#c69a60"))
