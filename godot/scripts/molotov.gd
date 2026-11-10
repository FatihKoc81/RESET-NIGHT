extends Area3D

@export var fire_damage_per_second := 15.0
@export var fire_duration := 5.0
var velocity := Vector3.ZERO
var flying := true
var age := 0.0
var burning := false
var burn_time := 0.0

func launch(direction: Vector3, speed: float) -> void:
    velocity = direction.normalized() * speed + Vector3.UP * 5.0

func _physics_process(delta: float) -> void:
    age += delta
    if flying:
        velocity.y -= 15.0 * delta
        global_position += velocity * delta
        if age >= 0.9 or global_position.y <= 0.2:
            _ignite()
    elif burning:
        burn_time += delta
        for body in get_overlapping_bodies():
            if body.is_in_group("enemies") and body.has_method("take_damage"):
                body.take_damage(fire_damage_per_second * delta)
            elif body.has_method("burn"):
                body.burn(fire_damage_per_second * delta)
        if burn_time >= fire_duration:
            queue_free()

func _ignite() -> void:
    flying = false
    burning = true
    velocity = Vector3.ZERO
    global_position.y = 0.2
    $Bottle.visible = false
    $CollisionShape3D.disabled = false
    monitoring = true
    $FuseLight.light_energy = 3.0
