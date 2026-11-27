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
    # Thin bottom-left bars (art direction: green health, white stamina), kept
    # below the virtual joystick, which is centred at 78% of the screen height.
    var bars_y := size.y - 30.0
    _draw_bar(Vector2(22, bars_y - 12.0), Vector2(170, 7), health / max_health, Color("#4fbf5a"), "")
    _draw_bar(Vector2(22, bars_y), Vector2(140, 5), stamina / 100.0, Color("#e9ecef"), "")
    _draw_heart(Vector2(10, bars_y - 8.5))
    var radar := Rect2(size.x - 166, 18, 144, 144)
    draw_rect(radar, Color(0.035, 0.055, 0.065, 0.92), true)
    draw_rect(radar, Color("#8b3030"), false, 2.0)
    var center := radar.position + radar.size * 0.5
    for i in range(1, 4):
        var p := float(i) / 4.0
        draw_line(Vector2(radar.position.x + radar.size.x * p, radar.position.y + 8), Vector2(radar.position.x + radar.size.x * p, radar.end.y - 8), Color(0.7, 0.18, 0.2, 0.25), 1.0)
        draw_line(Vector2(radar.position.x + 8, radar.position.y + radar.size.y * p), Vector2(radar.end.x - 8, radar.position.y + radar.size.y * p), Color(0.7, 0.18, 0.2, 0.25), 1.0)
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var rel: Vector3 = enemy.global_position - _player.global_position
        var local_pos: Vector3 = _player.global_transform.basis.inverse() * rel
        var dot := Vector2(local_pos.x, local_pos.z) * 2.4
        if absf(dot.x) < 64.0 and absf(dot.y) < 64.0:
            draw_circle(center + dot, 3.0, Color("#ffb347"))
    draw_circle(center, 4.0, Color("#ff4545"))
    draw_line(center, center + Vector2(0, -42), Color("#ff4545"), 2.0)
    draw_string(font, radar.position + Vector2(9, 17), "RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9b8b8"))
    var ammo := int(_player.get("shotgun_ammo"))
    var reserve := int(_player.get("shotgun_reserve"))
    # Keep weapon information centered along the bottom so it never sits beneath
    # the right-hand action buttons on phones with different aspect ratios.
    var weapon := Rect2((size.x - 190.0) * 0.5, size.y - 62.0, 190.0, 46.0)
    draw_rect(weapon, Color(0.035, 0.045, 0.055, 0.88), true)
    draw_rect(weapon, Color("#8b3030"), false, 1.5)
    _draw_shotgun_icon(weapon.position + Vector2(118, 14))
    draw_string(font, weapon.position + Vector2(10, 17), "POMPALI", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#bdb4ad"))
    draw_string(font, weapon.position + Vector2(10, 38), "%02d / %02d" % [ammo, reserve], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#f4e9d2"))

func _draw_bar(pos: Vector2, bar_size: Vector2, ratio: float, fill: Color, caption: String) -> void:
    if caption != "":
        draw_string(ThemeDB.fallback_font, pos + Vector2(0, -5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d4c9c2"))
    draw_rect(Rect2(pos, bar_size), Color(0.06, 0.065, 0.07, 0.75), true)
    var inner := Rect2(pos + Vector2(1, 1), Vector2(maxf(0.0, (bar_size.x - 2.0) * clampf(ratio, 0.0, 1.0)), bar_size.y - 2.0))
    draw_rect(inner, fill, true)
    draw_rect(Rect2(pos, bar_size), Color(0.75, 0.78, 0.8, 0.35), false, 1.0)

func _draw_heart(pos: Vector2) -> void:
    var c := Color("#4fbf5a")
    draw_circle(pos + Vector2(-2.0, 0), 2.6, c)
    draw_circle(pos + Vector2(2.0, 0), 2.6, c)
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-4.6, 0.6), pos + Vector2(4.6, 0.6), pos + Vector2(0, 5.5)]), c)

## Minimal silhouette of the pump shotgun for the weapon slot.
func _draw_shotgun_icon(pos: Vector2) -> void:
    var c := Color("#e9e2d6")
    draw_rect(Rect2(pos, Vector2(52, 4)), c, true)
    draw_rect(Rect2(pos + Vector2(20, 4), Vector2(16, 3)), c, true)
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-2, 0), pos + Vector2(-16, 3), pos + Vector2(-18, 12), pos + Vector2(-8, 12), pos + Vector2(2, 6)]), c)
