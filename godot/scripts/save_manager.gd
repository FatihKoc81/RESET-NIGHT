extends Node
## Local Android/desktop persistence. File lives in Godot's user:// directory.

const SAVE_PATH := "user://save_game.dat"
const BARRICADE_SCENE := preload("res://scenes/Barricade.tscn")
var elapsed_time_seconds := 0.0
var current_night := 1
var enemies_eliminated := 0
var total_score := 0
var _autosave_timer := 0.0
var _busy := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    await get_tree().process_frame
    load_game()

func _process(delta: float) -> void:
    elapsed_time_seconds += delta
    _autosave_timer += delta
    if _autosave_timer >= 30.0:
        _autosave_timer = 0.0
        save_game()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_game()

func register_enemy_kill() -> void:
    enemies_eliminated += 1
    total_score += 100
    save_game()

func save_game() -> bool:
    if _busy:
        return false
    var player := get_tree().get_first_node_in_group("player")
    if not is_instance_valid(player):
        return false
    _busy = true
    var pos: Vector3 = player.global_position
    var bag: Node = player.get_node_or_null("InventoryManager")
    var items: Array[Dictionary] = []
    if is_instance_valid(bag):
        for item_id in bag.ITEMS:
            var amount := int(bag.inventory.get(item_id, 0))
            if amount > 0:
                var item_entry := {"id": item_id, "amount": amount}
                if item_id == "spiked_bat":
                    item_entry["durability"] = float(player.bat_durability)
                items.append(item_entry)
    var barricades: Array[Dictionary] = []
    var barricade_root := get_tree().current_scene.get_node_or_null("Barricades")
    if is_instance_valid(barricade_root):
        for barrier in barricade_root.get_children():
            if barrier is StaticBody3D:
                barricades.append({
                    "type": "wooden_barricade",
                    "health": float(barrier.get("health")),
                    "position": _vector_to_dict(barrier.global_position),
                    "rotation_y": barrier.rotation.y
                })
    var searched_containers: Array[Dictionary] = []
    for container in get_tree().get_nodes_in_group("loot_containers"):
        searched_containers.append({
            "position": _vector_to_dict(container.global_position),
            "searched": bool(container.searched)
        })
    var data := {
        "version": 1,
        "saved_at_unix": int(Time.get_unix_time_from_system()),
        "player_stats": {
            "health": float(player.health),
            "stamina": float(player.stamina),
            "position": _vector_to_dict(pos),
            "rotation_y": float(player.rotation.y),
            "flashlight_on": bool(player.flashlight_on),
            "shotgun_ammo": int(player.shotgun_ammo),
            "shotgun_reserve": int(player.shotgun_reserve),
            "bat_durability": float(player.bat_durability)
        },
        "survival_stats": {
            "current_night": current_night,
            "elapsed_time_seconds": elapsed_time_seconds,
            "enemies_eliminated": enemies_eliminated,
            "total_score": total_score
        },
        "inventory": items,
        "placed_barricades": barricades,
        "loot_containers": searched_containers
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        _busy = false
        push_warning("RESET NIGHT save failed: " + error_string(FileAccess.get_open_error()))
        return false
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    _busy = false
    return true

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_warning("RESET NIGHT save could not be opened")
        return false
    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("RESET NIGHT save data is invalid")
        return false
    var data: Dictionary = parsed
    var player := get_tree().get_first_node_in_group("player")
    if not is_instance_valid(player):
        return false
    var stats: Dictionary = data.get("player_stats", {})
    player.health = clampf(float(stats.get("health", player.max_health)), 0.0, player.max_health)
    player.stamina = clampf(float(stats.get("stamina", 100.0)), 0.0, 100.0)
    player.global_position = _dict_to_vector(stats.get("position", {"x":0.0,"y":1.0,"z":0.0}))
    player.rotation.y = float(stats.get("rotation_y", 0.0))
    player.flashlight_on = bool(stats.get("flashlight_on", true))
    player.flashlight.set_enabled(player.flashlight_on)
    player.shotgun_ammo = int(stats.get("shotgun_ammo", 2))
    player.shotgun_reserve = int(stats.get("shotgun_reserve", 20))
    player.bat_durability = clampf(float(stats.get("bat_durability", 100.0)), 0.0, 100.0)
    var bag: Node = player.get_node_or_null("InventoryManager")
    if is_instance_valid(bag):
        for item_id in bag.ITEMS:
            bag.inventory[item_id] = 0
        for entry in data.get("inventory", []):
            if typeof(entry) == TYPE_DICTIONARY:
                bag.add_item(str(entry.get("id", "")), int(entry.get("amount", 0)))
                if str(entry.get("id", "")) == "spiked_bat":
                    player.bat_durability = clampf(float(entry.get("durability", player.bat_durability)), 0.0, 100.0)
    var survival: Dictionary = data.get("survival_stats", {})
    current_night = int(survival.get("current_night", 1))
    elapsed_time_seconds = float(survival.get("elapsed_time_seconds", 0.0))
    enemies_eliminated = int(survival.get("enemies_eliminated", 0))
    total_score = int(survival.get("total_score", 0))
    _restore_barricades(data.get("placed_barricades", []))
    _restore_loot_states(data.get("loot_containers", []))
    if is_instance_valid(player.hud):
        player.hud.set_health(player.health, player.max_health)
    player._notify("Kayıt yüklendi")
    return true

func _restore_barricades(entries: Array) -> void:
    var root := get_tree().current_scene.get_node_or_null("Barricades")
    if not is_instance_valid(root):
        return
    for child in root.get_children():
        child.queue_free()
    for entry in entries:
        if typeof(entry) != TYPE_DICTIONARY or str(entry.get("type", "")) != "wooden_barricade":
            continue
        var barrier := BARRICADE_SCENE.instantiate()
        root.add_child(barrier)
        barrier.global_position = _dict_to_vector(entry.get("position", {}))
        barrier.rotation.y = float(entry.get("rotation_y", 0.0))
        barrier.health = float(entry.get("health", 90.0))

func _restore_loot_states(entries: Array) -> void:
    var containers := get_tree().get_nodes_in_group("loot_containers")
    for container in containers:
        container.searched = false
        for entry in entries:
            if typeof(entry) == TYPE_DICTIONARY:
                var saved_pos := _dict_to_vector(entry.get("position", {}))
                if container.global_position.distance_to(saved_pos) < 0.2:
                    container.searched = bool(entry.get("searched", false))
                    break

func _vector_to_dict(value: Vector3) -> Dictionary:
    return {"x": value.x, "y": value.y, "z": value.z}

func _dict_to_vector(value: Variant) -> Vector3:
    if typeof(value) != TYPE_DICTIONARY:
        return Vector3(0, 1, 0)
    return Vector3(float(value.get("x", 0.0)), float(value.get("y", 1.0)), float(value.get("z", 0.0)))
