extends SceneTree

const SCENES := [
    "res://scenes/ui/MainMenu3D.tscn",
    "res://scenes/maps/Map3D.tscn",
    "res://scenes/player/Player3D.tscn",
    "res://scenes/ui/MobileControls.tscn",
    "res://scenes/enemies/HumanRaider.tscn",
    "res://scenes/enemies/Enemy.tscn"
]

func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    var failures: Array[String] = []
    for path in SCENES:
        var packed := ResourceLoader.load(path) as PackedScene
        if packed == null:
            failures.append("%s: PackedScene yüklenemedi" % path)
            continue
        var instance := packed.instantiate()
        if instance == null:
            failures.append("%s: instantiate başarısız" % path)
            continue
        root.add_child(instance)
        await process_frame
        instance.queue_free()
        await process_frame
        print("SCENE OK: ", path)
    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("SCENE VALIDATION PASSED")
    quit(0)
