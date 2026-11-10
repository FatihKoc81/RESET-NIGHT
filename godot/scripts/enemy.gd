extends CharacterBody3D

@export var health := 60.0
@export var walk_speed := 2.0
@export var base_detection_range := 10.0
var target: Node3D
var attack_cooldown := 0.0
var stun_time := 0.0
var wander_direction := Vector3.ZERO
var wander_timer := 0.0

func _ready() -> void:
    add_to_group("enemies")
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    stun_time = maxf(0.0, stun_time - delta)
    wander_timer -= delta
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    else:
        var offset := target.global_position - global_position
        offset.y = 0.0
        var detection_range := base_detection_range
        if target.get("flashlight_on"):
            detection_range *= 1.8
        var can_see_player := offset.length() <= detection_range and _has_line_of_sight()
        if can_see_player:
            var direction := offset.normalized()
            if offset.length() > 1.35:
                velocity.x = direction.x * walk_speed
                velocity.z = direction.z * walk_speed
                rotation.y = atan2(-direction.x, -direction.z)
            else:
                velocity.x = 0.0
                velocity.z = 0.0
                if attack_cooldown <= 0.0:
                    attack_cooldown = 1.25
                    target.take_damage(8.0)
        else:
            _wander(delta)
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _has_line_of_sight() -> bool:
    var from := global_position + Vector3.UP * 1.25
    var to := target.global_position + Vector3.UP * 1.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    return result.is_empty() or result.collider == target

func _wander(delta: float) -> void:
    if wander_timer <= 0.0:
        wander_timer = randf_range(1.5, 3.5)
        var angle := randf() * TAU
        wander_direction = Vector3(cos(angle), 0, sin(angle))
    velocity.x = wander_direction.x * walk_speed * 0.35
    velocity.z = wander_direction.z * walk_speed * 0.35
    if wander_direction.length() > 0.1:
        rotation.y = atan2(-wander_direction.x, -wander_direction.z)

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()

func stun(duration: float) -> void:
    stun_time = maxf(stun_time, duration)
