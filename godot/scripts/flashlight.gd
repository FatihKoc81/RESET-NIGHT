extends SpotLight3D
## Kamera pivotuna bağlı 45 derece oyuncu feneri.

@export var flashlight_energy := 2.8
@export var flashlight_range := 16.0
@export var flashlight_angle := 45.0
var is_on := true

func _ready() -> void:
    light_energy = flashlight_energy
    spot_angle = flashlight_angle
    spot_range = flashlight_range
    shadow_enabled = true
    light_color = Color(0.78, 0.86, 1.0)
    set_enabled(true)

func toggle() -> void:
    set_enabled(not is_on)

func set_enabled(value: bool) -> void:
    is_on = value
    visible = value
