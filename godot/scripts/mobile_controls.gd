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
            if event.position.x < screen_size.x * 0.48 and event.position.y > screen_size.y * 0.42 and _touch_index == -1:
                _touch_index = event.index
                _origin = event.position
                _update_move(event.position)
        elif event.index == _touch_index:
            _touch_index = -1
            _input_manager.move_vector = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == _touch_index:
        _update_move(event.position)

func _update_move(position: Vector2) -> void:
    _input_manager.move_vector = ((position - _origin) / 76.0).limit_length(1.0)
