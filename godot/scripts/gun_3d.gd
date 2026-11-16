extends Node3D
## 3D pompalı tüfek: hitscan atış, hafif nişan yardımı ve namlu parlaması. Mermi/reload player.gd'dedir.

signal fired
@export var damage_per_pellet := 14.0
@export var pellet_count := 6
@export var max_distance := 32.0
@export var spread := 0.07
@export var aim_assist_dot := 0.975

var _cooldown := 0.0

func _process(delta: float) -> void:
    _cooldown = maxf(0.0, _cooldown - delta)

func fire(shooter: CharacterBody3D, camera: Camera3D) -> bool:
    if _cooldown > 0.0:
        return false
    _cooldown = 0.8
    var origin := camera.global_position
    var forward := _assist_direction(origin, -camera.global_transform.basis.z)
    for pellet in range(pellet_count):
        var jitter := Vector3(randf_range(-spread, spread), randf_range(-spread * 0.7, spread * 0.7), 0.0)
        var direction := (forward + camera.global_transform.basis * jitter).normalized()
        var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance)
        query.exclude = [shooter.get_rid()]
        var hit := shooter.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty() and hit.collider.is_in_group("enemies"):
            hit.collider.take_damage(damage_per_pellet)
            if hit.collider.has_method("knockback"):
                hit.collider.knockback(shooter.global_position, 2.5)
    _muzzle_flash()
    fired.emit()
    return true

func _assist_direction(origin: Vector3, forward: Vector3) -> Vector3:
    var best := forward
    var best_dot := aim_assist_dot
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var target_position: Vector3 = enemy.global_position + Vector3.UP * 1.2
        var to_enemy := (target_position - origin).normalized()
        var alignment := forward.dot(to_enemy)
        if alignment > best_dot:
            best_dot = alignment
            best = forward.lerp(to_enemy, 0.7).normalized()
    return best

func _muzzle_flash() -> void:
    var flash := OmniLight3D.new()
    flash.light_color = Color(1.0, 0.7, 0.35)
    flash.light_energy = 6.0
    flash.omni_range = 9.0
    add_child(flash)
    flash.position = Vector3(0, 0.02, -0.8)
    get_tree().create_timer(0.07).timeout.connect(flash.queue_free)
