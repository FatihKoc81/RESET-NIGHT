extends Node3D
## Gece ilerledikçe artan düşman akışı. Dalga zamanlarını game_director.gd tetikler.

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
const MAP_LIMIT := 31.0
@export var base_interval := 3.6
@export var base_max := 8
var timer := 2.0
var player: Node3D
var _spawn_rng := RandomNumberGenerator.new()

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")
    _spawn_rng.randomize()

func _process(delta: float) -> void:
    var intensity := 0.0
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        if bool(director.finished):
            return
        intensity = float(director.get_intensity())
    timer -= delta
    if timer > 0.0:
        return
    timer = lerpf(base_interval, 0.9, intensity)
    var max_now := base_max + int(round(intensity * 14.0))
    if get_tree().get_nodes_in_group("enemies").size() >= max_now:
        return
    spawn_one(_pick_kind(intensity))

func spawn_wave(count: int) -> void:
    var intensity := 0.0
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        intensity = float(director.get_intensity())
    for i in range(count):
        spawn_one(_pick_kind(intensity + 0.15))

func _pick_kind(intensity: float) -> String:
    var roll := _spawn_rng.randf()
    if intensity > 0.3 and roll < 0.12:
        return "brute"
    if roll < 0.15 + intensity * 0.35:
        return "runner"
    return "walker"

func spawn_one(kind: String) -> void:
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    var spawn_position := _find_spawn_position()
    if spawn_position == Vector3.INF:
        return
    var enemy := ENEMY_SCENE.instantiate()
    enemy.kind = kind
    var session_manager := get_node_or_null("/root/NetworkManager")
    var player_side := str(session_manager.player_side) if is_instance_valid(session_manager) else "defense"
    enemy.faction = "attack" if player_side == "defense" else "defense"
    get_tree().current_scene.add_child(enemy)
    enemy.global_position = spawn_position

func _find_spawn_position() -> Vector3:
    if not is_instance_valid(player):
        return Vector3.INF
    var space := get_world_3d().direct_space_state
    var fallback := Vector3.INF
    for attempt in range(14):
        var angle := _spawn_rng.randf_range(0.0, TAU)
        var distance := _spawn_rng.randf_range(15.0, 24.0)
        var candidate := player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
        if absf(candidate.x) > MAP_LIMIT or absf(candidate.z) > MAP_LIMIT:
            continue
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
        if not sight_hit.is_empty():
            return grounded_position
        if fallback == Vector3.INF:
            fallback = grounded_position
    return fallback
