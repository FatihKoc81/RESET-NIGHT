extends CanvasLayer

var player: Node
var health_label: Label
var message_label: Label
var ammo_label: Label
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var joystick_vector := Vector2.ZERO

func _ready() -> void:
    add_to_group("hud")
    player = get_tree().get_first_node_in_group("player")
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)
    health_label = _label(root, "SAĞLIK 100", Vector2(22, 18), Vector2(220, 54), 22)
    ammo_label = _label(root, "POMPALI 2 / 20  •  MOLOTOF 3", Vector2(22, 54), Vector2(360, 42), 15)
    message_label = _label(root, "RESET NIGHT", Vector2(0, 18), Vector2(600, 48), 20)
    message_label.anchor_left = 0.5
    message_label.anchor_right = 0.5
    message_label.position.x = -300
    _make_action(root, "SOPA", Vector2(-250, -145), "use_bat")
    _make_action(root, "MOLOTOF", Vector2(-155, -145), "throw_molotov")
    _make_action(root, "POMPALI", Vector2(-250, -65), "fire_shotgun")
    _make_action(root, "DOLDUR", Vector2(-155, -65), "reload_shotgun")
    root.gui_input.connect(_on_root_input)

func _label(parent: Control, text_value: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = pos
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.75))
    parent.add_child(label)
    return label

func _make_action(parent: Control, title: String, offset: Vector2, method_name: String) -> void:
    var button := Button.new()
    button.text = title
    button.size = Vector2(86, 62)
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.position = offset
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.pressed.connect(_call_player.bind(method_name))
    parent.add_child(button)

func _call_player(method_name: String) -> void:
    if is_instance_valid(player) and player.has_method(method_name):
        player.call(method_name)

func _on_root_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.48 and event.position.y > get_viewport().get_visible_rect().size.y * 0.45:
            joystick_touch = event.index
            joystick_origin = event.position
            _update_joystick(event.position)
        elif not event.pressed and event.index == joystick_touch:
            joystick_touch = -1
            joystick_vector = Vector2.ZERO
            _set_move_actions(Vector2.ZERO)
    elif event is InputEventScreenDrag and event.index == joystick_touch:
        _update_joystick(event.position)

func _update_joystick(position: Vector2) -> void:
    joystick_vector = (position - joystick_origin).limit_length(75.0) / 75.0
    _set_move_actions(joystick_vector)

func _set_move_actions(value: Vector2) -> void:
    _set_action("move_left", value.x < -0.22)
    _set_action("move_right", value.x > 0.22)
    _set_action("move_forward", value.y < -0.22)
    _set_action("move_back", value.y > 0.22)

func _set_action(action: String, pressed: bool) -> void:
    if pressed and not Input.is_action_pressed(action):
        Input.action_press(action)
    elif not pressed and Input.is_action_pressed(action):
        Input.action_release(action)

func set_health(value: float, _maximum: float) -> void:
    if is_instance_valid(health_label):
        health_label.text = "SAĞLIK %d" % int(value)

func show_message(value: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = value
        await get_tree().create_timer(1.8).timeout
        if is_instance_valid(message_label):
            message_label.text = "RESET NIGHT"

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
    if is_instance_valid(player) and is_instance_valid(ammo_label):
        ammo_label.text = "POMPALI %d / %d  •  MOLOTOF %d" % [player.shotgun_ammo, player.shotgun_reserve, player.molotov_count]
