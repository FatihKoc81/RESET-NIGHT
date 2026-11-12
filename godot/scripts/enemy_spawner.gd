extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
@export var spawn_interval := 4.0
@export var max_enemies := 12
var timer := 1.5
var player: Node3D
var _spawn_rng := RandomNumberGenerator.new()

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")
    _spawn_rng.randomize()

func _process(delta: float) -> void:
    var world_clock := get_node_or_null("/root/WorldBroadcast")
    if is_instance_valid(world_clock) and not world_clock.is_purge_night:
        return
    timer -= delta
    if timer > 0.0:
        return
    timer = maxf(1.2, spawn_interval - float(Time.get_ticks_msec()) / 180000.0)
    if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    var spawn_position := _find_spawn_position()
    if spawn_position == Vector3.INF:
        return
    var enemy := ENEMY_SCENE.instantiate()
    get_tree().current_scene.add_child(enemy)
    enemy.global_position = spawn_position

func _find_spawn_position() -> Vector3:
    if not is_instance_valid(player):
        return Vector3.INF
    var space := get_world_3d().direct_space_state
    for attempt in range(10):
        var angle := _spawn_rng.randf_range(0.0, TAU)
        var distance := _spawn_rng.randf_range(14.0, 22.0)
        var offset := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
        var candidate := player.global_position + offset
        var floor_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 8.0, candidate + Vector3.DOWN * 12.0)
        floor_query.exclude = [player.get_rid()]
        var floor_hit := space.intersect_ray(floor_query)
        if floor_hit.is_empty():
            continue
        if floor_hit.normal.dot(Vector3.UP) < 0.72:
            continue
        var grounded_position: Vector3 = floor_hit.position + Vector3.UP * 0.06
        var sight_query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.2, grounded_position + Vector3.UP * 1.0)
        sight_query.exclude = [player.get_rid()]
        var sight_hit := space.intersect_ray(sight_query)
        if sight_hit.is_empty():
            continue
        return grounded_position
    return Vector3.INF
