extends SceneTree

const SCENES := [
    "res://scenes/ui/MainMenu3D.tscn",
    "res://scenes/maps/Map3D.tscn",
    "res://scenes/player/Player3D.tscn",
    "res://scenes/ui/MobileControls.tscn",
    "res://scenes/enemies/HumanRaider.tscn",
    "res://scenes/enemies/Enemy.tscn"
]
const PLAYABLE_SCENE := "res://scenes/Main3D.tscn"

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

    # The old validator checked individual pieces but never booted the actual
    # gameplay scene. Catch missing player/camera/HUD/director wiring here.
    var playable := ResourceLoader.load(PLAYABLE_SCENE) as PackedScene
    if playable == null:
        failures.append("%s: oynanabilir ana sahne yüklenemedi" % PLAYABLE_SCENE)
    else:
        var game := playable.instantiate()
        if game == null:
            failures.append("%s: ana sahne instantiate edilemedi" % PLAYABLE_SCENE)
        else:
            root.add_child(game)
            await process_frame
            await process_frame
            var player := get_first_node_in_group("player")
            var director := get_first_node_in_group("director")
            var hud := get_first_node_in_group("hud")
            var camera := game.find_child("Camera3D", true, false) as Camera3D
            var spawner := game.get_node_or_null("EnemySpawner")
            if not is_instance_valid(player):
                failures.append("Main3D: oyuncu grubu bulunamadı")
            if not is_instance_valid(director):
                failures.append("Main3D: GameDirector başlatılmadı")
            if not is_instance_valid(hud):
                failures.append("Main3D: HUD başlatılmadı")
            if not is_instance_valid(camera) or not camera.current:
                failures.append("Main3D: aktif üçüncü şahıs kamerası yok")
            if not is_instance_valid(spawner):
                failures.append("Main3D: EnemySpawner eksik")
            elif is_instance_valid(player):
                spawner.spawn_one("walker")
                await physics_frame
                if get_nodes_in_group("enemies").is_empty():
                    failures.append("Main3D: insan düşman üretilemedi")
            if failures.is_empty():
                print("PLAYABLE BOOT OK: player, camera, HUD, director, enemy spawner, human enemy")
            game.queue_free()
            await process_frame

    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("SCENE VALIDATION PASSED")
    quit(0)
