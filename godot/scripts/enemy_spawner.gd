extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")
@export var spawn_interval := 4.0
@export var max_enemies := 12
var timer := 1.5
var player: Node3D

func _ready() -> void:
    player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
    timer -= delta
    if timer > 0.0:
        return
    timer = maxf(1.2, spawn_interval - float(Time.get_ticks_msec()) / 180000.0)
    if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
        return
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
        return
    var angle := randf() * TAU
    var distance := randf_range(13.0, 20.0)
    var enemy := ENEMY_SCENE.instantiate()
    get_tree().current_scene.add_child(enemy)
    enemy.global_position = player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
