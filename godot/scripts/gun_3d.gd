extends Node3D
## 3D shotgun receiver and hitscan firing behaviour. Ammo/reload are owned by Player3D.

signal fired
@export var damage_per_pellet := 12.0
@export var pellet_count := 6
@export var max_distance := 32.0
@export var spread := 0.075

var _cooldown := 0.0

func _process(delta: float) -> void:
    _cooldown = maxf(0.0, _cooldown - delta)

func fire(shooter: CharacterBody3D, camera: Camera3D) -> bool:
    if _cooldown > 0.0:
        return false
    _cooldown = 0.8
    var origin := camera.global_position
    var forward := -camera.global_transform.basis.z
    for pellet in range(pellet_count):
        var jitter := Vector3(randf_range(-spread, spread), randf_range(-spread * 0.7, spread * 0.7), 0.0)
        var direction := (forward + camera.global_transform.basis * jitter).normalized()
        var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance)
        query.exclude = [shooter.get_rid()]
        var hit := shooter.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and hit.collider.is_in_group("enemies"):
            hit.collider.take_damage(damage_per_pellet)
    fired.emit()
    return true
