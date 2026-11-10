extends StaticBody3D

@export var health := 90.0

func burn(amount: float) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()
    else:
        var saver := get_node_or_null("/root/SaveManager")
        if is_instance_valid(saver):
            saver.save_game()
