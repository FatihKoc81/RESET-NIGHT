extends CanvasLayer

var player: Node
var health_label: Label
var message_label: Label
var ammo_label: Label
var joystick_origin := Vector2.ZERO
var joystick_touch := -1
var joystick_vector := Vector2.ZERO
var inventory_panel: PanelContainer
var inventory_label: Label
var inventory_button: Button
var save_button: Button
var load_button: Button

func _ready() -> void:
    add_to_group("hud")
    player = get_tree().get_first_node_in_group("player")
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)
    health_label = _label(root, "SAĞLIK 100", Vector2(22, 18), Vector2(220, 54), 22)
    ammo_label = _label(root, "POMPALI 2 / 20  •  MOLOTOF 3", Vector2(22, 54), Vector2(360, 42), 15)
    message_label = _label(root, "RESET NIGHT", Vector2(0, 18), Vector2(600, 48), 20)
    message_label.anchor_left = 0.5
    message_label.anchor_right = 0.5
    message_label.position.x = -300
    _make_action(root, "SOPA", Vector2(-250, -145), "use_bat")
    _make_action(root, "MOLOTOF", Vector2(-155, -145), "throw_molotov")
    _make_action(root, "POMPALI", Vector2(-250, -65), "fire_shotgun")
    _make_action(root, "DOLDUR", Vector2(-155, -65), "reload_shotgun")
    _make_action(root, "FENER", Vector2(-60, -65), "toggle_flashlight")
    _make_action(root, "ARA (E)", Vector2(-250, -225), "interact")
    _make_action(root, "İLK YARDIM", Vector2(-155, -225), "use_first_aid")
    _build_inventory_panel(root)
    _build_save_controls(root)
    root.gui_input.connect(_on_root_input)

func _build_save_controls(root: Control) -> void:
    save_button = Button.new()
    save_button.text = "KAYDET"
    save_button.position = Vector2(22, 455)
    save_button.size = Vector2(118, 44)
    save_button.pressed.connect(_save_game)
    root.add_child(save_button)
    load_button = Button.new()
    load_button.text = "YÜKLE"
    load_button.position = Vector2(148, 455)
    load_button.size = Vector2(118, 44)
    load_button.pressed.connect(_load_game)
    root.add_child(load_button)

func _save_game() -> void:
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver) and saver.save_game():
        if is_instance_valid(player):
            player._notify("Oyun kaydedildi")
    else:
        if is_instance_valid(player):
            player._notify("Kayıt yapılamadı")

func _load_game() -> void:
    var saver := get_node_or_null("/root/SaveManager")
    if is_instance_valid(saver) and saver.load_game():
        _refresh_inventory()
    elif is_instance_valid(player):
        player._notify("Kayıt dosyası bulunamadı")


func _build_settings_controls(root: Control) -> void:
    settings_button = Button.new()
    settings_button.text = "AYARLAR"
    settings_button.position = Vector2(22, 160)
    settings_button.size = Vector2(118, 44)
    settings_button.pressed.connect(_toggle_settings)
    root.add_child(settings_button)
    settings_panel = PanelContainer.new()
    settings_panel.position = Vector2(22, 212)
    settings_panel.size = Vector2(280, 100)
    settings_panel.visible = false
    root.add_child(settings_panel)
    var column := VBoxContainer.new()
    settings_panel.add_child(column)
    var title := Label.new()
    title.text = "KAMERA HASSASİYETİ"
    column.add_child(title)
    sensitivity_slider = HSlider.new()
    sensitivity_slider.min_value = 0.001
    sensitivity_slider.max_value = 0.015
    sensitivity_slider.step = 0.001
    sensitivity_slider.value = 0.005
    var manager := get_node_or_null("/root/MobileInputManager")
    if is_instance_valid(manager):
        sensitivity_slider.value = manager.touch_sensitivity
    sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
    column.add_child(sensitivity_slider)

func _toggle_settings() -> void:
    settings_panel.visible = not settings_panel.visible

func _on_sensitivity_changed(value: float) -> void:
    var manager := get_node_or_null("/root/MobileInputManager")
    if is_instance_valid(manager):
        manager.set_touch_sensitivity(value)

func _build_inventory_panel(root: Control) -> void:
    inventory_button = Button.new()
    inventory_button.text = "ÇANTA (I)"
    inventory_button.position = Vector2(22, 105)
    inventory_button.size = Vector2(118, 48)
    inventory_button.pressed.connect(_toggle_inventory)
    root.add_child(inventory_button)
    inventory_panel = PanelContainer.new()
    inventory_panel.position = Vector2(22, 160)
    inventory_panel.size = Vector2(300, 300)
    inventory_panel.visible = false
    root.add_child(inventory_panel)
    var column := VBoxContainer.new()
    inventory_panel.add_child(column)
    inventory_label = _label(column, "ÇANTA", Vector2.ZERO, Vector2(280, 170), 16)
    _craft_button(column, "Molotof üret (Kumaş 1 + Alkol 1)", "molotov")
    _craft_button(column, "İlk yardım üret (Kumaş 2 + Alkol 1)", "first_aid")
    _craft_button(column, "Dikenli sopa takviyesi (Hurda 2 + Tel 2)", "spiked_bat_upgrade")

func _craft_button(parent: Control, title: String, recipe_id: String) -> void:
    var button := Button.new()
    button.text = title
    button.pressed.connect(_craft.bind(recipe_id))
    parent.add_child(button)

func _craft(recipe_id: String) -> void:
    if is_instance_valid(player) and player.has_method("craft_item"):
        player.craft_item(recipe_id)
    _refresh_inventory()

func _toggle_inventory() -> void:
    inventory_panel.visible = not inventory_panel.visible
    _refresh_inventory()

func _refresh_inventory() -> void:
    if not is_instance_valid(inventory_label) or not is_instance_valid(player):
        return
    var bag := player.get_node_or_null("InventoryManager")
    if is_instance_valid(bag):
        inventory_label.text = bag.get_inventory_text()

func _label(parent: Control, text_value: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = pos
    label.size = size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.75))
    parent.add_child(label)
    return label

func _make_action(parent: Control, title: String, offset: Vector2, method_name: String) -> void:
    var button := Button.new()
    button.text = title
    button.size = Vector2(86, 62)
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.position = offset
    button.add_theme_font_size_override("font_size", 13)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.pressed.connect(_call_player.bind(method_name))
    parent.add_child(button)

func _call_player(method_name: String) -> void:
    if is_instance_valid(player) and player.has_method(method_name):
        player.call(method_name)

func set_health(value: float, _maximum: float) -> void:
    if is_instance_valid(health_label):
        health_label.text = "SAĞLIK %d" % int(value)

func show_message(value: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = value
        await get_tree().create_timer(1.8).timeout
        if is_instance_valid(message_label):
            message_label.text = "RESET NIGHT"

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("toggle_inventory") and is_instance_valid(inventory_panel):
        _toggle_inventory()
    _refresh_inventory()
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")
    if is_instance_valid(player) and is_instance_valid(ammo_label):
        ammo_label.text = "POMPALI %d / %d  •  MOLOTOF %d" % [player.shotgun_ammo, player.shotgun_reserve, int(player.get_node("InventoryManager").inventory.get("molotov", 0))]
