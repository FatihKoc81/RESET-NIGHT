extends CharacterBody3D

const BAT_DAMAGE := 30.0
const BAT_COOLDOWN := 0.7
const BAT_RANGE := 2.8
const STUN_CHANCE := 0.2
const MAG_SIZE := 4
const MOLOTOV_SCENE := preload("res://scenes/weapons/Molotov.tscn")
const FIRST_AID_HEAL := 45.0
const VANGUARD_VISUAL := preload("res://scenes/characters/VanguardSurvivor.tscn")

@export var move_speed := 5.2
@export var max_health := 100.0
var health := 100.0
var stamina := 100.0
var bat_durability := 100.0
var shotgun_ammo := 4
var shotgun_reserve := 24
var molotov_count := 3
var bat_timer := 0.0
var shotgun_timer := 0.0
var reload_timer := 0.0
var invulnerable := 0.0
var yaw := 0.0
var hud: Node
var flashlight_on := true
var player_side := "defense"
var nearby_loot: Node3D
var dead := false

@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var flashlight: SpotLight3D = $CameraPivot/Flashlight

func _ready() -> void:
    add_to_group("player")
    # Explicitly claim the active viewport camera when the gameplay scene starts.
    if is_instance_valid(camera):
        camera.make_current()
    # Ignore the player's own capsule so the third-person camera does not collapse into the body.
    var camera_arm := get_node_or_null("CameraPivot/SpringArm3D") as SpringArm3D
    if is_instance_valid(camera_arm):
        camera_arm.add_excluded_object(get_rid())
        camera_arm.spring_length = 4.2
        camera_arm.margin = 0.18
    _apply_saved_character()
    var session_manager := get_node_or_null("/root/NetworkManager")
    if is_instance_valid(session_manager):
        player_side = str(session_manager.player_side)
    health = max_health
    call_deferred("_find_hud")
    flashlight_on = flashlight.is_on
    var mobile_input := get_node_or_null("/root/MobileInputManager")
    if is_instance_valid(mobile_input):
        mobile_input.is_flashlight_on = flashlight_on
    $InventoryManager.add_item("spiked_bat", 1)
    $InventoryManager.add_item("molotov", molotov_count)
    $InventoryManager.add_item("first_aid", 1)
    molotov_count = 0
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_saved_character() -> void:
    var config := ConfigFile.new()
    if config.load("user://settings.cfg") != OK:
        return
    var character := str(config.get_value("player", "character", "leader"))
    if character == "vanguard":
        var old_visual := get_node_or_null("Visual")
        if is_instance_valid(old_visual):
            remove_child(old_visual)
            old_visual.queue_free()
        var visual := VANGUARD_VISUAL.instantiate()
        visual.name = "Visual"
        add_child(visual)

func _find_hud() -> void:
    hud = get_tree().get_first_node_in_group("hud")
    if hud:
        hud.set_health(health, max_health)

func _unhandled_input(event: InputEvent) -> void:
    if dead:
        return
    if event is InputEventMouseMotion and not OS.has_feature("mobile"):
        yaw -= event.relative.x * 0.003
        rotation.y = yaw

func _physics_process(delta: float) -> void:
    if dead:
        velocity.x = 0.0
        velocity.z = 0.0
        if not is_on_floor():
            velocity.y -= 20.0 * delta
        move_and_slide()
        return
    bat_timer = maxf(0.0, bat_timer - delta)
    shotgun_timer = maxf(0.0, shotgun_timer - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    if reload_timer > 0.0:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var amount := mini(MAG_SIZE - shotgun_ammo, shotgun_reserve)
            shotgun_ammo += amount
            shotgun_reserve -= amount
            _notify("Pompalı dolduruldu")
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var mobile_input := get_node_or_null("/root/MobileInputManager")
    var touch_magnitude := 0.0
    if OS.has_feature("mobile") and is_instance_valid(mobile_input):
        touch_magnitude = mobile_input.move_vector.length()
        if touch_magnitude > 0.01:
            input = mobile_input.move_vector
    # Telefonlarda joystick'i dış halkaya kadar itmek koşuyu başlatır.
    # Klavye ve gamepad tarafında Shift aynı işi görür.
    var wants_sprint := Input.is_key_pressed(KEY_SHIFT) or (OS.has_feature("mobile") and touch_magnitude >= 0.88)
    var sprinting := wants_sprint and input.length() > 0.08 and stamina > 1.0
    if sprinting:
        stamina = maxf(0.0, stamina - 30.0 * delta)
    else:
        stamina = minf(100.0, stamina + 19.0 * delta)
    var current_speed := move_speed * (1.55 if sprinting else 1.0)
    var direction := (global_transform.basis * Vector3(input.x, 0, input.y)).normalized()
    if input.length() > 0.08:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
        var gamepad_active: bool = is_instance_valid(mobile_input) and mobile_input.has_gamepad()
        if not OS.has_feature("mobile") and not gamepad_active:
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

func add_ammo(amount: int) -> void:
    shotgun_reserve += amount
    _notify("+%d pompalı kartuşu" % amount)

func add_first_aid(amount: int) -> void:
    var overflow: int = $InventoryManager.add_item("first_aid", amount)
    if overflow < amount:
        _notify("İlk yardım kiti bulundu")

func add_molotov(amount: int) -> void:
    var overflow: int = $InventoryManager.add_item("molotov", amount)
    if overflow < amount:
        _notify("Molotof bulundu")

func interact() -> void:
    if dead:
        return
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
    if dead:
        return
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
    var mobile_input := get_node_or_null("/root/MobileInputManager")
    if is_instance_valid(mobile_input):
        mobile_input.is_flashlight_on = flashlight_on
    _notify("Fener açık — düşman görüşü arttı" if flashlight_on else "Fener kapalı — gizlilik aktif")

func use_bat() -> void:
    if dead or bat_timer > 0.0:
        return
    bat_timer = BAT_COOLDOWN
    var visual := get_node_or_null("Visual")
    if is_instance_valid(visual) and visual.has_method("trigger_swing"):
        visual.trigger_swing()
    var target := _nearest_enemy(BAT_RANGE, true)
    var damage := BAT_DAMAGE
    if bat_durability <= 0.0:
        damage = 8.0
    if target:
        target.take_damage(damage)
        if target.has_method("knockback"):
            target.knockback(global_position, 5.0)
        bat_durability = maxf(0.0, bat_durability - 0.5)
        if randf() < STUN_CHANCE:
            target.stun(1.0)
        _notify("Çivili sopa: %d hasar" % int(damage) if bat_durability > 0.0 else "Sopa kırıldı — yumruk: 8 hasar")
    else:
        _notify("Sopa havayı yardı")

func throw_molotov() -> void:
    if dead:
        return
    if not $InventoryManager.consume("molotov"):
        _notify("Molotof kalmadı")
        return
    var bottle := MOLOTOV_SCENE.instantiate()
    get_tree().current_scene.add_child(bottle)
    bottle.global_position = global_position + Vector3(0, 1.1, 0) - global_transform.basis.z * 0.8
    bottle.launch(-global_transform.basis.z, 16.0)
    _notify("Molotof: %d" % int($InventoryManager.inventory.get("molotov", 0)))

func fire_shotgun() -> void:
    if dead or shotgun_timer > 0.0 or reload_timer > 0.0:
        return
    if shotgun_ammo <= 0:
        if shotgun_reserve > 0:
            reload_shotgun()
        else:
            _notify("Mermi bitti!")
        return
    shotgun_timer = 0.8
    shotgun_ammo -= 1
    var gun := get_node_or_null("WeaponPivot/Gun3D")
    if is_instance_valid(gun):
        gun.fire(self, camera)
    _notify("Pompalı %d / %d" % [shotgun_ammo, shotgun_reserve])

func reload_shotgun() -> void:
    if dead or reload_timer > 0.0 or shotgun_ammo >= MAG_SIZE or shotgun_reserve <= 0:
        return
    reload_timer = 1.6
    _notify("Dolduruluyor…")

func take_damage(amount: float) -> void:
    if dead or invulnerable > 0.0:
        return
    health = maxf(0.0, health - amount)
    invulnerable = 0.65
    if not is_instance_valid(hud):
        _find_hud()
    if is_instance_valid(hud):
        hud.set_health(health, max_health)
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        director.on_player_hit(amount)
    if health <= 0.0:
        _die()
        return
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver):
        saver.save_game()

func _die() -> void:
    dead = true
    _notify("ARINMA SENİ ALDI")
    var visual := get_node_or_null("Visual") as Node3D
    if visual != null:
        visual.rotation_degrees.x = -80.0
        visual.position.y = 0.25
    var director := get_tree().get_first_node_in_group("director")
    if is_instance_valid(director):
        director.player_died()

func _nearest_enemy(max_range: float, frontal: bool = false) -> Node:
    var nearest: Node
    var best := max_range
    var forward := -global_transform.basis.z
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var to_enemy: Vector3 = enemy.global_position - global_position
        to_enemy.y = 0.0
        var distance := to_enemy.length()
        if distance >= best:
            continue
        if frontal and distance > 0.6 and forward.dot(to_enemy / distance) < 0.2:
            continue
        best = distance
        nearest = enemy
    return nearest

func _notify(message: String) -> void:
    if not is_instance_valid(hud):
        _find_hud()
    if is_instance_valid(hud):
        hud.show_message(message)
