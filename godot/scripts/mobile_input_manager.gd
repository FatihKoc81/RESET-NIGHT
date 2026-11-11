extends Node
## Unified Android touch + standard HID/XInput gamepad input bridge.

const DEFAULT_SENSITIVITY := 0.005
const SETTINGS_PATH := "user://mobile_settings.cfg"
var move_vector: Vector2 = Vector2.ZERO
var is_flashlight_on := true
var touch_sensitivity := DEFAULT_SENSITIVITY
var _look_touch := -1
var _player: Node3D
var _camera_pivot: Node3D
var _active_gamepad := -1
var _last_gamepad_name := ""

func _ready() -> void:
    _load_settings()
    _install_gamepad_mappings()
    Input.joy_connection_changed.connect(_on_joy_connection_changed)
    _refresh_gamepad()

func _process(_delta: float) -> void:
    if _active_gamepad < 0:
        return
    var look := Vector2(
        Input.get_joy_axis(_active_gamepad, JOY_AXIS_RIGHT_X),
        Input.get_joy_axis(_active_gamepad, JOY_AXIS_RIGHT_Y)
    )
    if look.length() > 0.16:
        _find_camera()
        if is_instance_valid(_player) and is_instance_valid(_camera_pivot):
            _player.rotation.y -= look.x * touch_sensitivity * 42.0
            _camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - look.y * touch_sensitivity * 30.0, deg_to_rad(-55.0), deg_to_rad(35.0))

func _input(event: InputEvent) -> void:
    if not OS.has_feature("mobile"):
        return
    var screen_size := get_viewport().get_visible_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x >= screen_size.x * 0.5 and event.position.y < screen_size.y * 0.56 and _look_touch == -1:
                _look_touch = event.index
                _find_camera()
        elif event.index == _look_touch:
            _look_touch = -1
    elif event is InputEventScreenDrag and event.index == _look_touch:
        _rotate_camera(event.relative)

func _install_gamepad_mappings() -> void:
    _bind_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
    _bind_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
    _bind_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
    _bind_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
    _bind_button("attack", JOY_BUTTON_X)
    _bind_button("interact", JOY_BUTTON_A)
    _bind_button("reload", JOY_BUTTON_B)
    _bind_button("toggle_inventory", JOY_BUTTON_Y)
    _bind_button("toggle_flashlight", JOY_BUTTON_LEFT_SHOULDER)
    _bind_button("fire_shotgun", JOY_BUTTON_RIGHT_SHOULDER)
    _bind_button("throw_molotov", JOY_BUTTON_RIGHT_STICK)
    _bind_button("use_first_aid", JOY_BUTTON_LEFT_STICK)
    _bind_button("pause_game", JOY_BUTTON_START)
    _bind_button("toggle_map", JOY_BUTTON_BACK)
    _bind_button("move_forward", JOY_BUTTON_DPAD_UP)
    _bind_button("move_back", JOY_BUTTON_DPAD_DOWN)
    _bind_button("move_left", JOY_BUTTON_DPAD_LEFT)
    _bind_button("move_right", JOY_BUTTON_DPAD_RIGHT)
    _bind_axis("fire_shotgun", JOY_AXIS_TRIGGER_RIGHT, 1.0)
    _bind_axis("attack", JOY_AXIS_TRIGGER_LEFT, 1.0)

func _bind_button(action: String, button_index: int) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for existing in InputMap.action_get_events(action):
        if existing is InputEventJoypadButton and existing.button_index == button_index:
            return
    var event := InputEventJoypadButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action, event)

func _bind_axis(action: String, axis_index: int, direction: float) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for existing in InputMap.action_get_events(action):
        if existing is InputEventJoypadMotion and existing.axis == axis_index and signf(existing.axis_value) == direction:
            return
    var event := InputEventJoypadMotion.new()
    event.axis = axis_index
    event.axis_value = direction
    InputMap.action_add_event(action, event)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
    _refresh_gamepad()

func _refresh_gamepad() -> void:
    var pads := Input.get_connected_joypads()
    _active_gamepad = int(pads[0]) if not pads.is_empty() else -1
    _last_gamepad_name = Input.get_joy_name(_active_gamepad) if _active_gamepad >= 0 else ""
    if _active_gamepad >= 0:
        print("RESET NIGHT gamepad connected: ", _last_gamepad_name)

func get_gamepad_name() -> String:
    return _last_gamepad_name

func has_gamepad() -> bool:
    return _active_gamepad >= 0

func _find_camera() -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player")
    if is_instance_valid(_player):
        _camera_pivot = _player.get_node_or_null("CameraPivot")

func _rotate_camera(relative: Vector2) -> void:
    _find_camera()
    if not is_instance_valid(_player) or not is_instance_valid(_camera_pivot):
        return
    _player.rotation.y -= relative.x * touch_sensitivity
    _camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - relative.y * touch_sensitivity, deg_to_rad(-55.0), deg_to_rad(35.0))

func set_touch_sensitivity(value: float) -> void:
    touch_sensitivity = clampf(value, 0.001, 0.015)
    var config := ConfigFile.new()
    config.set_value("touch", "sensitivity", touch_sensitivity)
    config.save(SETTINGS_PATH)

func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        touch_sensitivity = clampf(float(config.get_value("touch", "sensitivity", DEFAULT_SENSITIVITY)), 0.001, 0.015)
