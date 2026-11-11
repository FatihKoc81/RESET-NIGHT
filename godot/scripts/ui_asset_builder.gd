@tool
extends Node
## Shared RESET NIGHT UI theme.

func setup_theme() -> Theme:
    var result := Theme.new()
    var normal := _style(Color("#1a1d24"), Color("#8b0000"), 2)
    var hover := _style(Color("#2a171b"), Color("#d32f2f"), 2)
    var pressed := _style(Color("#3a0d0d"), Color("#ff3333"), 3)
    result.set_stylebox("normal", "Button", normal)
    result.set_stylebox("hover", "Button", hover)
    result.set_stylebox("pressed", "Button", pressed)
    result.set_stylebox("focus", "Button", hover)
    result.set_color("font_color", "Button", Color("#f2eee8"))
    result.set_color("font_hover_color", "Button", Color.WHITE)
    result.set_color("font_pressed_color", "Button", Color.WHITE)
    result.set_font_size("font_size", "Button", 18)
    result.set_stylebox("panel", "PanelContainer", _panel())
    return result

func _style(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(width)
    s.corner_radius_top_left = 16
    s.corner_radius_top_right = 16
    s.corner_radius_bottom_left = 16
    s.corner_radius_bottom_right = 16
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 15
    s.content_margin_bottom = 15
    return s

func _panel() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#11151b")
    s.border_color = Color("#6f2929")
    s.set_border_width_all(2)
    s.corner_radius_top_left = 16
    s.corner_radius_top_right = 16
    s.corner_radius_bottom_left = 16
    s.corner_radius_bottom_right = 16
    return s
