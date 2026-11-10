extends Node3D

const BARRICADE := preload("res://scenes/Barricade.tscn")

func _ready() -> void:
    for item in [Vector3(5, 0, -7), Vector3(-6, 0, -9), Vector3(9, 0, 6), Vector3(-10, 0, 5)]:
        var barrier := BARRICADE.instantiate()
        add_child(barrier)
        barrier.position = item
        barrier.rotation.y = randf_range(-0.25, 0.25)
