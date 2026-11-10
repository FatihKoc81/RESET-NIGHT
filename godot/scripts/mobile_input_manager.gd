extends Node
## Android touch input bridge. Left side drives movement; upper-right drag rotates the camera.

const DEFAULT_SENSITIVITY := 0.005
const SETTINGS_PATH := "user://mobile_settings.cfg"

var move_vector: Vector2 = Vector2.ZERO
var is_flashlight_on: bool = true
var touch_sensitivity: float = DEFAULT_SENSITIVITY
var _look_touch := -1
var _player: Node3D
var _camera_pivot: Node3D

func _ready() -> void:
    _load_settings()

func _input(event: InputEvent) -> void:
    if not OS.has_feature("mobile"):
        return
    var screen_size := get_viewport().get_visible_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x >= screen_size.x * 0.5 and event.position.y < screen_size.y * 0.68 and _look_touch == -1:
                _look_touch = event.index
                _find_camera()
        elif event.index == _look_touch:
            _look_touch = -1
    elif event is InputEventScreenDrag and event.index == _look_touch:
        _rotate_camera(event.relative)

func _find_camera() -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player")
    if is_instance_valid(_player):
        _camera_pivot = _player.get_node_or_null("CameraPivot")

func _rotate_camera(relative: Vector2) -> void:
    if not is_instance_valid(_player) or not is_instance_valid(_camera_pivot):
        _find_camera()
    if not is_instance_valid(_player) or not is_instance_valid(_camera_pivot):
        return
    _player.rotation.y -= relative.x * touch_sensitivity
    _camera_pivot.rotation.x = clampf(
        _camera_pivot.rotation.x - relative.y * touch_sensitivity,
        deg_to_rad(-55.0),
        deg_to_rad(35.0)
    )

func set_touch_sensitivity(value: float) -> void:
    touch_sensitivity = clampf(value, 0.001, 0.015)
    var config := ConfigFile.new()
    config.set_value("touch", "sensitivity", touch_sensitivity)
    config.save(SETTINGS_PATH)

func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        touch_sensitivity = clampf(float(config.get_value("touch", "sensitivity", DEFAULT_SENSITIVITY)), 0.001, 0.015)
