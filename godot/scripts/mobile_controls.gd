extends Control
## Invisible left-side virtual joystick. HUD action buttons remain separate controls.

var _touch_index := -1
var _origin := Vector2.ZERO
var _input_manager: Node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _input_manager = get_node_or_null("/root/MobileInputManager")

func _input(event: InputEvent) -> void:
    if not OS.has_feature("mobile") or not is_instance_valid(_input_manager):
        return
    var screen_size := get_viewport_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if _is_joystick_start_area(event.position, screen_size) and _touch_index == -1:
                _touch_index = event.index
                _origin = event.position
                _update_move(event.position)
        elif event.index == _touch_index:
            _touch_index = -1
            _input_manager.move_vector = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == _touch_index:
        _update_move(event.position)

func _update_move(position: Vector2) -> void:
    var screen_size := get_viewport_rect().size
    var joystick_radius := clampf(minf(screen_size.x, screen_size.y) * 0.11, 56.0, 110.0)
    _input_manager.move_vector = ((position - _origin) / joystick_radius).limit_length(1.0)

func _is_joystick_start_area(position: Vector2, screen_size: Vector2) -> bool:
    # Reserve the lower-left area for movement; leave the right side to HUD actions.
    return position.x < screen_size.x * 0.45 and position.y > screen_size.y * 0.45
