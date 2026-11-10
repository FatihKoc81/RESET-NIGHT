extends Control
## Drawn HUD layer for health, stamina, radar and weapon status.

var _player: Node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
    if not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player")
    queue_redraw()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    if not is_instance_valid(_player):
        return
    var health := float(_player.get("health"))
    var max_health := maxf(1.0, float(_player.get("max_health")))
    var stamina := float(_player.get("stamina"))
    _draw_bar(Vector2(22, 54), Vector2(220, 13), health / max_health, Color("#c52d39"), "SAĞLIK")
    _draw_bar(Vector2(22, 78), Vector2(180, 9), stamina / 100.0, Color("#e0a13b"), "DAYANIKLILIK")
    var radar := Rect2(size.x - 166, 18, 144, 144)
    draw_rect(radar, Color(0.035, 0.055, 0.065, 0.92), true)
    draw_rect(radar, Color("#8b3030"), false, 2.0)
    var center := radar.position + radar.size * 0.5
    for i in range(1, 4):
        var p := float(i) / 4.0
        draw_line(Vector2(radar.position.x + radar.size.x * p, radar.position.y + 8), Vector2(radar.position.x + radar.size.x * p, radar.end.y - 8), Color(0.7, 0.18, 0.2, 0.25), 1.0)
        draw_line(Vector2(radar.position.x + 8, radar.position.y + radar.size.y * p), Vector2(radar.end.x - 8, radar.position.y + radar.size.y * p), Color(0.7, 0.18, 0.2, 0.25), 1.0)
    draw_circle(center, 4.0, Color("#ff4545"))
    draw_line(center, center + Vector2(0, -42), Color("#ff4545"), 2.0)
    draw_string(font, radar.position + Vector2(9, 17), "RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9b8b8"))
    var ammo := int(_player.get("shotgun_ammo"))
    var reserve := int(_player.get("shotgun_reserve"))
    var weapon := Rect2(size.x - 236, size.y - 74, 214, 52)
    draw_rect(weapon, Color(0.035, 0.045, 0.055, 0.94), true)
    draw_rect(weapon, Color("#8b3030"), false, 2.0)
    draw_string(font, weapon.position + Vector2(12, 19), "POMPALI", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#bdb4ad"))
    draw_string(font, weapon.position + Vector2(12, 42), "%02d / %02d" % [ammo, reserve], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#f4e9d2"))

func _draw_bar(pos: Vector2, bar_size: Vector2, ratio: float, fill: Color, caption: String) -> void:
    draw_string(ThemeDB.fallback_font, pos + Vector2(0, -5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d4c9c2"))
    draw_rect(Rect2(pos, bar_size), Color("#211d20"), true)
    var inner := Rect2(pos + Vector2(2, 2), Vector2(maxf(0.0, (bar_size.x - 4.0) * clampf(ratio, 0.0, 1.0)), bar_size.y - 4.0))
    draw_rect(inner, fill, true)
    draw_rect(Rect2(pos, bar_size), Color("#744040"), false, 1.0)
