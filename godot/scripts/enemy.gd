extends CharacterBody3D

@export var health := 60.0
@export var walk_speed := 2.0
var target: Node3D
var attack_cooldown := 0.0
var stun_time := 0.0

func _ready() -> void:
    add_to_group("enemies")
    target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    stun_time = maxf(0.0, stun_time - delta)
    if not is_instance_valid(target):
        target = get_tree().get_first_node_in_group("player")
        return
    if stun_time > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    else:
        var offset := target.global_position - global_position
        offset.y = 0.0
        if offset.length() > 1.35:
            var direction := offset.normalized()
            velocity.x = direction.x * walk_speed
            velocity.z = direction.z * walk_speed
            rotation.y = atan2(-direction.x, -direction.z)
        else:
            velocity.x = 0.0
            velocity.z = 0.0
            if attack_cooldown <= 0.0:
                attack_cooldown = 1.25
                target.take_damage(8.0)
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()

func stun(duration: float) -> void:
    stun_time = maxf(stun_time, duration)
