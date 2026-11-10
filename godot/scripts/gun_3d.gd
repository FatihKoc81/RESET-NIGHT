extends Node3D
## Player-held 3D shotgun visual and firing interface.

signal fired
@export var damage_per_pellet := 12.0
@export var pellet_count := 6
@export var max_distance := 32.0
@export var spread := 0.075

var _cooldown := 0.0
var _ammo := 2
var _reserve := 20
var _reloading := false

func _process(delta: float) -> void:
    _cooldown = maxf(0.0, _cooldown - delta)

func fire(shooter: CharacterBody3D, camera: Camera3D) -> bool:
    if _cooldown > 0.0 or _reloading or _ammo <= 0:
        return false
    _cooldown = 0.8
    _ammo -= 1
    var origin := camera.global_position
    var forward := -camera.global_transform.basis.z
    for i in range(pellet_count):
        var jitter := Vector3(randf_range(-spread, spread), randf_range(-spread * 0.7, spread * 0.7), 0.0)
        var direction := (forward + camera.global_transform.basis * jitter).normalized()
        var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance)
        query.exclude = [shooter.get_rid()]
        var hit := shooter.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and hit.collider.is_in_group("enemies"):
            hit.collider.take_damage(damage_per_pellet)
    fired.emit()
    return true

func reload() -> bool:
    if _reloading or _ammo >= 2 or _reserve <= 0:
        return false
    _reloading = true
    await get_tree().create_timer(2.5).timeout
    var amount := mini(2 - _ammo, _reserve)
    _ammo += amount
    _reserve -= amount
    _reloading = false
    return true

func get_ammo() -> Vector2i:
    return Vector2i(_ammo, _reserve)
