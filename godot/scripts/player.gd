extends CharacterBody3D

const BAT_DAMAGE := 25.0
const BAT_COOLDOWN := 1.2
const BAT_RANGE := 2.4
const STUN_CHANCE := 0.15
const MOLOTOV_SCENE := preload("res://scenes/weapons/Molotov.tscn")
const FIRST_AID_HEAL := 45.0

@export var move_speed := 5.2
@export var max_health := 100.0
var health := 100.0
var shotgun_ammo := 2
var shotgun_reserve := 20
var molotov_count := 3
var bat_timer := 0.0
var shotgun_timer := 0.0
var reload_timer := 0.0
var invulnerable := 0.0
var yaw := 0.0
var hud: Node
var flashlight_on := true
var nearby_loot: Node3D

@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var flashlight: SpotLight3D = $CameraPivot/Flashlight

func _ready() -> void:
    add_to_group("player")
    health = max_health
    call_deferred("_find_hud")
    flashlight_on = flashlight.is_on
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _find_hud() -> void:
    hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_health(health, max_health)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and not OS.has_feature("mobile"):
        yaw -= event.relative.x * 0.003
        rotation.y = yaw

func _physics_process(delta: float) -> void:
    bat_timer = maxf(0.0, bat_timer - delta)
    shotgun_timer = maxf(0.0, shotgun_timer - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    if reload_timer > 0.0:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var amount := mini(2 - shotgun_ammo, shotgun_reserve)
            shotgun_ammo += amount
            shotgun_reserve -= amount
            _notify("Pompalı dolduruldu")
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (global_transform.basis * Vector3(input.x, 0, input.y)).normalized()
    if input.length() > 0.08:
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        if not OS.has_feature("mobile"):
            rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 8.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if Input.is_action_just_pressed("attack"):
        use_bat()
    if Input.is_action_just_pressed("throw_molotov"):
        throw_molotov()
    if Input.is_action_just_pressed("fire_shotgun"):
        fire_shotgun()
    if Input.is_action_just_pressed("reload"):
        reload_shotgun()
    if Input.is_action_just_pressed("toggle_flashlight"):
        toggle_flashlight()
    if Input.is_action_just_pressed("interact"):
        interact()
    if Input.is_action_just_pressed("use_first_aid"):
        use_first_aid()

func interact() -> void:
    var nearest: Node3D
    var nearest_distance := 2.8
    for container in get_tree().get_nodes_in_group("loot_containers"):
        if not is_instance_valid(container):
            continue
        var distance := global_position.distance_to(container.global_position)
        if distance < nearest_distance:
            nearest = container
            nearest_distance = distance
    if nearest:
        if nearest.searched:
            _notify("Bu sandık zaten arandı")
        elif nearest.searching:
            _notify("Sandık aranıyor...")
        else:
            nearest.begin_search()
            _notify("Sandık aranıyor... 2 saniye")
    else:
        _notify("Yakında aranabilir sandık yok")

func use_first_aid() -> void:
    if health >= max_health:
        _notify("Sağlığın zaten dolu")
        return
    var bag := $InventoryManager
    if bag.consume("first_aid"):
        health = minf(max_health, health + FIRST_AID_HEAL)
        if is_instance_valid(hud):
            hud.set_health(health, max_health)
        _notify("İlk yardım kullanıldı: +45 sağlık")
    else:
        _notify("İlk yardım kitin yok")

func craft_item(recipe_id: String) -> void:
    if $InventoryManager.craft(recipe_id):
        _notify("Üretildi: " + str($InventoryManager.RECIPES[recipe_id].name))
    else:
        _notify("Malzeme yetersiz veya çanta dolu")

func toggle_flashlight() -> void:
    flashlight.toggle()
    flashlight_on = flashlight.is_on
    _notify("Fener açık — düşman görüşü arttı" if flashlight_on else "Fener kapalı — gizlilik aktif")

func use_bat() -> void:
    if bat_timer > 0.0:
        return
    bat_timer = BAT_COOLDOWN
    var target := _nearest_enemy(BAT_RANGE)
    if target:
        target.take_damage(BAT_DAMAGE)
        if randf() < STUN_CHANCE:
            target.stun(1.0)
    _notify("Çivili sopa: 25 hasar")

func throw_molotov() -> void:
    if molotov_count <= 0:
        _notify("Molotof kalmadı")
        return
    molotov_count -= 1
    $InventoryManager.consume("molotov") if int($InventoryManager.inventory.get("molotov", 0)) > 0 else null
    var bottle := MOLOTOV_SCENE.instantiate()
    get_tree().current_scene.add_child(bottle)
    bottle.global_position = global_position + Vector3(0, 1.1, 0) - global_transform.basis.z * 0.8
    bottle.launch(-global_transform.basis.z, 16.0)
    _notify("Molotof: %d" % molotov_count)

func fire_shotgun() -> void:
    if shotgun_timer > 0.0:
        return
    if shotgun_ammo <= 0:
        _notify("Pompalı boş — doldur")
        return
    shotgun_timer = 0.8
    shotgun_ammo -= 1
    var origin := camera.global_position
    var forward := -camera.global_transform.basis.z
    for pellet in range(6):
        var spread := Vector3(randf_range(-0.075, 0.075), randf_range(-0.055, 0.055), 0.0)
        var direction := (forward + camera.global_transform.basis * spread).normalized()
        var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 32.0)
        query.exclude = [get_rid()]
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if hit and hit.collider.is_in_group("enemies"):
            hit.collider.take_damage(12.0)
    _notify("Pompalı %d / %d" % [shotgun_ammo, shotgun_reserve])

func reload_shotgun() -> void:
    if reload_timer > 0.0 or shotgun_ammo >= 2 or shotgun_reserve <= 0:
        return
    reload_timer = 2.5
    _notify("Dolduruluyor…")

func take_damage(amount: float) -> void:
    if invulnerable > 0.0:
        return
    health = maxf(0.0, health - amount)
    invulnerable = 0.65
    if not is_instance_valid(hud):
        _find_hud()
    if is_instance_valid(hud):
        hud.set_health(health, max_health)
    if health <= 0.0:
        _notify("GECE KAZANDI — karakter düştü")

func _nearest_enemy(max_range: float) -> Node:
    var nearest: Node
    var best := max_range
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var distance := global_position.distance_to(enemy.global_position)
        if distance < best:
            best = distance
            nearest = enemy
    return nearest

func _notify(message: String) -> void:
    if not is_instance_valid(hud):
        _find_hud()
    if is_instance_valid(hud):
        hud.show_message(message)
