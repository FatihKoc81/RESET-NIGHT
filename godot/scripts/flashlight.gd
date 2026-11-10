extends SpotLight3D
## Player-mounted 90-degree cone flashlight.

@export var flashlight_energy := 1.5
@export var flashlight_range := 24.0
var is_on := true

func _ready() -> void:
    light_energy = flashlight_energy
    spot_angle = 90.0
    spot_range = flashlight_range
    shadow_enabled = true
    light_color = Color(0.78, 0.86, 1.0)
    set_enabled(true)

func toggle() -> void:
    set_enabled(not is_on)

func set_enabled(value: bool) -> void:
    is_on = value
    visible = value
