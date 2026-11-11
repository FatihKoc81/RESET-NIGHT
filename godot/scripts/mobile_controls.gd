extends Control
## Landscape virtual joystick: visible thumb control on lower-left; camera drag is handled by MobileInputManager.

var _touch_index := -1
var _origin := Vector2.ZERO
var _current := Vector2.ZERO
var _input_manager: Node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _input_manager = get_node_or_null("/root/MobileInputManager")
    queue_redraw()

func _input(event: InputEvent) -> void:
    if not OS.has_feature("mobile") or not is_instance_valid(_input_manager):
        return
    var screen_size := get_viewport_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < screen_size.x * 0.40 and event.position.y > screen_size.y * 0.48 and _touch_index == -1:
                _touch_index = event.index
                _origin = Vector2(screen_size.x * 0.16, screen_size.y * 0.78)
                _current = event.position
                _update_move(event.position)
                queue_redraw()
        elif event.index == _touch_index:
            _touch_index = -1
            _input_manager.move_vector = Vector2.ZERO
            queue_redraw()
    elif event is InputEventScreenDrag and event.index == _touch_index:
        _current = event.position
        _update_move(event.position)
        queue_redraw()

func _update_move(position: Vector2) -> void:
    var delta := position - _origin
    _input_manager.move_vector = (delta / 82.0).limit_length(1.0)
    _current = _origin + delta.limit_length(82.0)

func _draw() -> void:
    if not OS.has_feature("mobile"):
        return
    var screen_size := get_viewport_rect().size
    var center := Vector2(screen_size.x * 0.16, screen_size.y * 0.78)
    var knob := _current if _touch_index != -1 else center
    draw_circle(center, 62.0, Color(0.04, 0.06, 0.09, 0.48))
    draw_arc(center, 62.0, 0.0, TAU, 64, Color(0.72, 0.76, 0.82, 0.68), 3.0, true)
    draw_circle(knob, 29.0, Color(0.72, 0.76, 0.82, 0.72))
    draw_arc(knob, 29.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.82), 2.0, true)
