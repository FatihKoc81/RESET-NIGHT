extends CharacterBody3D
## İnsan savaşçı AI. Tür ve karşı fraksiyon spawner tarafından add_child'dan ÖNCE atanır.

const KIND_STATS := {
    "walker": {"health": 60.0, "speed": 2.1, "damage": 8.0, "points": 100, "scale": 1.0},
    "runner": {"health": 40.0, "speed": 3.7, "damage": 6.0, "points": 150, "scale": 0.96},
    "brute": {"health": 190.0, "speed": 1.8, "damage": 18.0, "points": 300, "scale": 1.28}
}

@export var health := 60.0
@export var walk_speed := 2.0
@export var base_detection_range := 7.0
@export var hearing_range := 10.0
var kind := "walker"
var faction := "attack"
var attack_damage := 8.0
var points := 100
var target: Node3D
var attack_cooldown := 0.0
var stun_time := 0.0
var wander_direction := Vector3.ZERO
var wander_timer := 0.0
var pending_hit := -1.0
var knock := Vector3.ZERO
var dead := false

func _ready() -> void:
    add_to_group("enemies")
    add_to_group("human_raiders")
    add_to_group("faction_" + faction)
    target = get_tree().get_first_node_in_group("player")
    var stats: Dictionary = KIND_STATS.get(kind, KIND_STATS["walker"])
    var intensity := 0.0
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        intensity = float(director.get_intensity())
    health = float(stats["health"]) * (1.0 + intensity * 0.5)
    walk_speed = float(stats["speed"]) * (1.0 + intensity * 0.25)
    attack_damage = float(stats["damage"])
    points = int(stats["points"])
    hearing_range = 11.0 + intensity * 16.0
    var body_scale := float(stats["scale"])
    var visual := get_node_or_null("Visual") as Node3D
    if visual != null:
        visual.scale = Vector3.ONE * body_scale
    var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null and collision.shape is CapsuleShape3D:
        var capsule := (collision.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
        capsule.radius = 0.4 * body_scale
        capsule.height = 1.7 * body_scale
        collision.shape = capsule
        collision.position.y = 0.85 * body_scale

func _physics_process(delta: float) -> void:
    if dead:
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    stun_time = maxf(0.0, stun_time - delta)
    wander_timer -= delta
    knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
        return
    var player_dead := bool(target.get("dead"))
    var offset := target.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    if pending_hit > 0.0:
        pending_hit -= delta
        if pending_hit <= 0.0 and not player_dead and distance <= 2.1:
            target.take_damage(attack_damage)
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    elif player_dead:
        _wander(delta)
    else:
        var detection_range := base_detection_range
        if target.get("flashlight_on"):
            detection_range *= 1.7
        var aware := (distance <= detection_range and _has_line_of_sight()) or distance <= hearing_range
        if aware and distance > 0.01:
            var direction := offset / distance
            if distance > 1.45:
                direction = _steer_around_obstacles(direction)
                rotation.y = atan2(-direction.x, -direction.z)
                velocity.x = direction.x * walk_speed
                velocity.z = direction.z * walk_speed
            else:
                rotation.y = atan2(-direction.x, -direction.z)
            else:
                velocity.x = 0.0
                velocity.z = 0.0
                if attack_cooldown <= 0.0:
                    attack_cooldown = 1.25
                    pending_hit = 0.38
                    var visual := get_node_or_null("Visual")
                    if is_instance_valid(visual) and visual.has_method("trigger_swing"):
                        visual.trigger_swing()
        else:
            _wander(delta)
    velocity.x += knock.x
    velocity.z += knock.z
    for other in get_tree().get_nodes_in_group("enemies"):
        if other == self or not is_instance_valid(other):
            continue
        var away: Vector3 = global_position - other.global_position
        away.y = 0.0
        var gap := away.length()
        if gap < 0.9 and gap > 0.001:
            velocity.x += away.x / gap * (0.9 - gap) * 5.0
            velocity.z += away.z / gap * (0.9 - gap) * 5.0
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _steer_around_obstacles(direction: Vector3) -> Vector3:
    # Keep melee opponents from walking directly into walls, wrecks and barricades.
    var origin := global_position + Vector3.UP * 0.9
    var forward_query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1.45)
    forward_query.exclude = [get_rid()]
    if get_world_3d().direct_space_state.intersect_ray(forward_query).is_empty():
        return direction

    var left := Vector3(-direction.z, 0.0, direction.x).normalized()
    var right := -left
    var state := get_world_3d().direct_space_state
    var left_query := PhysicsRayQueryParameters3D.create(origin, origin + left * 1.8)
    var right_query := PhysicsRayQueryParameters3D.create(origin, origin + right * 1.8)
    left_query.exclude = [get_rid()]
    right_query.exclude = [get_rid()]
    var left_clear := state.intersect_ray(left_query).is_empty()
    var right_clear := state.intersect_ray(right_query).is_empty()
    if left_clear and not right_clear:
        return (direction * 0.35 + left * 0.94).normalized()
    if right_clear and not left_clear:
        return (direction * 0.35 + right * 0.94).normalized()
    if left_clear and right_clear:
        return (direction * 0.35 + (left if randf() < 0.5 else right) * 0.94).normalized()
    # Both sides are tight: slide along the nearer edge rather than pushing into the obstacle.
    return left if randf() < 0.5 else right

func _has_line_of_sight() -> bool:
    var from := global_position + Vector3.UP * 1.25
    var to := target.global_position + Vector3.UP * 1.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    return result.is_empty() or result.collider == target

func _wander(_delta: float) -> void:
    if wander_timer <= 0.0:
        wander_timer = randf_range(1.5, 3.5)
        var angle := randf() * TAU
        wander_direction = Vector3(cos(angle), 0, sin(angle))
    velocity.x = wander_direction.x * walk_speed * 0.35
    velocity.z = wander_direction.z * walk_speed * 0.35
    if wander_direction.length() > 0.1:
        rotation.y = atan2(-wander_direction.x, -wander_direction.z)

func take_damage(amount: float) -> void:
    if dead:
        return
    health -= amount
    if amount >= 3.0:
        _hit_fx()
    if health <= 0.0:
        _die()

func stun(duration: float) -> void:
    stun_time = maxf(stun_time, duration)

func knockback(from_position: Vector3, force: float) -> void:
    var away := global_position - from_position
    away.y = 0.0
    if away.length() > 0.01:
        var resist := 0.35 if kind == "brute" else 1.0
        knock = away.normalized() * force * resist

func _hit_fx() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    var splash := CPUParticles3D.new()
    splash.one_shot = true
    splash.amount = 14
    splash.lifetime = 0.5
    splash.explosiveness = 1.0
    splash.direction = Vector3.UP
    splash.spread = 70.0
    splash.initial_velocity_min = 2.0
    splash.initial_velocity_max = 4.5
    splash.gravity = Vector3(0, -12, 0)
    var drop := SphereMesh.new()
    drop.radius = 0.04
    drop.height = 0.08
    splash.mesh = drop
    var blood := StandardMaterial3D.new()
    blood.albedo_color = Color(0.42, 0.02, 0.03)
    splash.material_override = blood
    scene.add_child(splash)
    splash.global_position = global_position + Vector3(0, 1.3, 0)
    splash.emitting = true
    get_tree().create_timer(1.0).timeout.connect(splash.queue_free)

func _die() -> void:
    if dead:
        return
    dead = true
    remove_from_group("enemies")
    collision_layer = 0
    collision_mask = 0
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.register_enemy_kill()
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        director.register_kill(points)
    _drop_loot()
    var tween := create_tween()
    var visual := get_node_or_null("Visual") as Node3D
    if visual != null:
        tween.tween_property(visual, "rotation_degrees:x", -88.0, 0.4)
    tween.tween_interval(2.5)
    tween.tween_callback(queue_free)

func _drop_loot() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if not is_instance_valid(player):
        return
    var roll := randf()
    var bonus := 0.12 if kind == "brute" else 0.0
    if roll < 0.24 + bonus:
        player.add_ammo(4 if kind == "brute" else 2)
    elif roll < 0.33 + bonus:
        player.add_first_aid(1)
    elif roll < 0.40 + bonus:
        player.add_molotov(1)
