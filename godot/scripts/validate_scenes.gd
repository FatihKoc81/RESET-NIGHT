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

    # Boot the complete playable scene and validate its actual runtime wiring.
    var playable := ResourceLoader.load(PLAYABLE_SCENE) as PackedScene
    if playable == null:
        failures.append("%s: oynanabilir ana sahne yüklenemedi" % PLAYABLE_SCENE)
    else:
        var game := playable.instantiate()
        if game == null:
            failures.append("%s: ana sahne instantiate edilemedi" % PLAYABLE_SCENE)
        else:
            root.add_child(game)
            current_scene = game
            await process_frame
            await process_frame
            await process_frame
            var player := get_first_node_in_group("player")
            var director := get_first_node_in_group("director")
            var hud := get_first_node_in_group("hud")
            var camera: Camera3D = null
            if is_instance_valid(player):
                camera = player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
            var spawner := game.get_node_or_null("EnemySpawner")
            if not is_instance_valid(player):
                failures.append("Main3D: oyuncu grubu bulunamadı")
            if not is_instance_valid(director):
                failures.append("Main3D: GameDirector başlatılmadı")
            else:
                if float(director.get("time_left")) <= 0.0:
                    failures.append("Main3D: ilk bölüm gece sayacı başlamadı")
                if not director.has_method("_update_objective"):
                    failures.append("Main3D: ilk bölüm görev sistemi eksik")
                if get_nodes_in_group("loot_containers").size() != 3:
                    failures.append("Main3D: ilk bölümde üç malzeme sandığı bulunamadı")
            if not is_instance_valid(hud):
                failures.append("Main3D: HUD başlatılmadı")
            if not is_instance_valid(camera):
                failures.append("Main3D: oyuncunun üçüncü şahıs kamerası bulunamadı")
            elif get_root().get_camera_3d() != camera:
                camera.make_current()
                await process_frame
                if get_root().get_camera_3d() != camera:
                    failures.append("Main3D: üçüncü şahıs kamerası viewport tarafından etkinleştirilemedi")
            if not is_instance_valid(spawner):
                failures.append("Main3D: EnemySpawner eksik")
            elif is_instance_valid(player):
                var faction_manager := root.get_node_or_null("NetworkManager")
                if not is_instance_valid(faction_manager):
                    failures.append("Main3D: fraksiyon yöneticisi bulunamadı")
                else:
                    # SAVUNMA oyuncusuna SALDIRI tarafında insan düşman üretilmeli.
                    faction_manager.player_side = "defense"
                    spawner.spawn_one("walker")
                    await physics_frame
                    var spawned := get_nodes_in_group("enemies")
                    if spawned.is_empty():
                        failures.append("Main3D: SAVUNMA akışında insan düşman üretilemedi")
                    else:
                        var first_enemy: Node = spawned[0]
                        if str(first_enemy.get("faction")) != "attack":
                            failures.append("Main3D: SAVUNMA oyuncusunun karşısında SALDIRI fraksiyonu üretilmedi")
                        if not first_enemy.is_in_group("human_raiders"):
                            failures.append("Main3D: üretilen düşman insan NPC grubunda değil")
                        var human_visual := first_enemy.get_node_or_null("Visual")
                        if not is_instance_valid(human_visual):
                            failures.append("Main3D: insan düşmanın 3D görseli eksik")
                        else:
                            var visual_script := human_visual.get_script() as Script
                            if visual_script == null or visual_script.resource_path != "res://scripts/character_art.gd":
                                failures.append("Main3D: düşman görseli doğrulanmış insan karakter betiğini kullanmıyor")
                    for enemy in get_nodes_in_group("enemies"):
                        enemy.queue_free()
                    await physics_frame

                    # SALDIRI oyuncusuna SAVUNMA tarafında insan düşman üretilmeli.
                    faction_manager.player_side = "attack"
                    spawner.spawn_one("walker")
                    await physics_frame
                    spawned = get_nodes_in_group("enemies")
                    if spawned.is_empty():
                        failures.append("Main3D: SALDIRI akışında insan düşman üretilemedi")
                    else:
                        var second_enemy: Node = spawned[0]
                        if str(second_enemy.get("faction")) != "defense":
                            failures.append("Main3D: SALDIRI oyuncusunun karşısında SAVUNMA fraksiyonu üretilmedi")
                        if not second_enemy.is_in_group("human_raiders"):
                            failures.append("Main3D: SALDIRI akışındaki karşı karakter insan NPC değil")
                    for enemy in get_nodes_in_group("enemies"):
                        enemy.queue_free()
                    await physics_frame

            if is_instance_valid(hud):
                if not hud.has_method("toggle_pause") or not hud.has_method("toggle_inventory"):
                    failures.append("Main3D: pause/inventory HUD actions eksik")
                else:
                    hud.toggle_inventory()
                    var inventory_panel := hud.get("inventory_panel") as Control
                    if not is_instance_valid(inventory_panel) or not inventory_panel.visible:
                        failures.append("Main3D: envanter paneli açılamadı")
                    hud.toggle_inventory()
                    hud.toggle_pause()
                    await process_frame
                    if not paused:
                        failures.append("Main3D: duraklatma çalışmadı")
                    hud.toggle_pause()
                    await process_frame
                    if paused:
                        failures.append("Main3D: oyuna devam et çalışmıyor")
            if failures.is_empty():
                print("PLAYABLE BOOT OK: player, camera, HUD, director, enemy, inventory, pause/resume")
            current_scene = null
            game.queue_free()
            await process_frame
            await process_frame
            await process_frame

    if not failures.is_empty():
        for failure in failures:
            push_error(failure)
        quit(1)
        return
    print("SCENE VALIDATION PASSED")
    quit(0)
