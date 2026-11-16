extends Node3D

const LOOT_SCENE := preload("res://scenes/interactables/LootContainer3D.tscn")
const DIRECTOR_SCRIPT := preload("res://scripts/game_director.gd")
## RESET NIGHT procedural 3D street kit. Primitive meshes are placeholders for final art assets.

var asphalt: StandardMaterial3D
var sidewalk: StandardMaterial3D
var concrete: StandardMaterial3D
var brick: StandardMaterial3D
var metal: StandardMaterial3D
var car_paint: StandardMaterial3D
var warm_glow: StandardMaterial3D
var window_lit: StandardMaterial3D
var window_dark: StandardMaterial3D
var neon_red: StandardMaterial3D
var dumpster_green: StandardMaterial3D

func _ready() -> void:
    _make_materials()
    _build_ground()
    _build_street_props()
    _build_walls_and_fences()
    _build_loot_containers()
    _build_city()
    _apply_mobile_visibility_ranges()
    _start_director()

func _make_materials() -> void:
    asphalt = _mat(Color(0.055, 0.063, 0.073), 0.95)
    sidewalk = _mat(Color(0.19, 0.20, 0.21), 0.9)
    concrete = _mat(Color(0.12, 0.13, 0.14), 0.9)
    brick = _mat(Color(0.19, 0.105, 0.085), 0.95)
    metal = _mat(Color(0.095, 0.11, 0.12), 0.72, 0.45)
    car_paint = _mat(Color(0.12, 0.16, 0.17), 0.82, 0.2)
    warm_glow = _mat(Color(0.8, 0.24, 0.045), 0.5, 0.0, true)
    window_lit = _mat(Color(0.95, 0.62, 0.22), 0.5, 0.0, true)
    window_dark = _mat(Color(0.025, 0.03, 0.04), 0.25, 0.1)
    neon_red = _mat(Color(1.0, 0.1, 0.22), 0.4, 0.0, true)
    dumpster_green = _mat(Color(0.07, 0.15, 0.10), 0.7, 0.3)
    _texture_material(asphalt, 0.22, 0.04)
    _texture_material(sidewalk, 0.3, 0.06)
    _texture_material(concrete, 0.3, 0.05)
    _texture_material(brick, 0.45, 0.09)

func _mat(color: Color, rough: float, metallic: float = 0.0, emission: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = rough
    material.metallic = metallic
    if emission:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = 1.4
    return material

func _build_ground() -> void:
    _box(null, Vector3(0, -0.42, 0), Vector3(70, 0.8, 70), asphalt, true)
    _box(null, Vector3(0, 0.015, -7.0), Vector3(70, 0.08, 12), asphalt, false)
    _box(null, Vector3(0, 0.08, -14.0), Vector3(70, 0.22, 1.8), sidewalk, true)
    _box(null, Vector3(0, 0.08, 0.0), Vector3(70, 0.22, 1.8), sidewalk, true)
    _box(null, Vector3(0, 0.08, 7.0), Vector3(70, 0.22, 1.8), sidewalk, true)
    _box(null, Vector3(0, 0.08, 14.0), Vector3(70, 0.22, 1.8), sidewalk, true)
    for i in range(12):
        var x := -28.0 + float(i) * 5.0
        _box(null, Vector3(x, 0.025, -7.0), Vector3(0.12, 0.025, 0.75), concrete, false)
    for i in range(8):
        var x := -25.0 + float(i) * 7.0
        _box(null, Vector3(x, 0.025, 0.0), Vector3(0.08, 0.025, 0.45), concrete, false)

func _build_street_props() -> void:
    _car_wreck(Vector3(-8, 0, -7), -0.12)
    _car_wreck(Vector3(11, 0, -9), 0.18)
    _abandoned_house(Vector3(25, 0, -18))
    _street_lamp(Vector3(-15, 0, -13))
    _street_lamp(Vector3(17, 0, -13))
    _street_lamp(Vector3(-18, 0, 8))
    _burning_barrel(Vector3(5, 0, 5))
    _burning_barrel(Vector3(-12, 0, 3))

func _build_walls_and_fences() -> void:
    for i in range(5):
        _box($NavigationRegion3D/EnvironmentProps3D, Vector3(-25.0 + float(i) * 2.0, 0.8, 15.0), Vector3(1.95, 1.6, 0.45), brick, true)
    _fence(Vector3(22, 0, 4), 10.0)
    _fence(Vector3(-22, 0, -5), 8.0)
    _box($NavigationRegion3D/EnvironmentProps3D, Vector3(4, 0.45, -2), Vector3(2.1, 0.9, 1.2), concrete, true)
    _box($NavigationRegion3D/EnvironmentProps3D, Vector3(-3, 0.35, 9), Vector3(1.5, 0.7, 1.0), concrete, true)

func _box(parent: Node, pos: Vector3, size: Vector3, material: Material, collision: bool) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    if parent:
        parent.add_child(body)
    else:
        $NavigationRegion3D/GroundTiles/GridMap3D.add_child(body)
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    if collision:
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        body.add_child(shape_node)
    return body

func _cylinder(parent: Node, pos: Vector3, radius: float, height: float, material: Material, collision: bool = false) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    parent.add_child(body)
    var mesh_instance := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    if collision:
        var shape_node := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = radius
        shape.height = height
        shape_node.shape = shape
        body.add_child(shape_node)
    return body

func _car_wreck(pos: Vector3, angle: float) -> void:
    var root := StaticBody3D.new()
    root.position = pos
    root.rotation.y = angle
    $NavigationRegion3D/EnvironmentProps3D.add_child(root)
    _add_box_mesh(root, Vector3(0, 0.75, 0), Vector3(3.7, 1.05, 1.75), car_paint, true)
    _add_box_mesh(root, Vector3(0, 1.35, 0), Vector3(1.8, 0.65, 1.55), concrete, false)
    for x in [-1.25, 1.25]:
        for z in [-0.92, 0.92]:
            var wheel := MeshInstance3D.new()
            var wheel_mesh := CylinderMesh.new()
            wheel_mesh.top_radius = 0.42
            wheel_mesh.bottom_radius = 0.42
            wheel_mesh.height = 0.24
            wheel.mesh = wheel_mesh
            wheel.material_override = metal
            wheel.position = Vector3(x, 0.42, z)
            wheel.rotation.z = PI / 2
            root.add_child(wheel)

func _add_box_mesh(parent: Node, pos: Vector3, size: Vector3, material: Material, collision: bool) -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = pos
    parent.add_child(mesh_instance)
    if collision:
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        shape_node.position = pos
        parent.add_child(shape_node)

func _street_lamp(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    $NavigationRegion3D/EnvironmentProps3D.add_child(root)
    _cylinder(root, Vector3(0, 3.0, 0), 0.09, 6.0, metal, true)
    _box(root, Vector3(0.48, 5.85, 0), Vector3(1.0, 0.12, 0.16), metal, false)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0.85, 5.6, 0)
    lamp.light_color = Color(1.0, 0.68, 0.38)
    lamp.light_energy = 1.15
    lamp.omni_range = 9.0
    lamp.shadow_enabled = false
    root.add_child(lamp)

func _burning_barrel(pos: Vector3) -> void:
    var root := Node3D.new()
    root.position = pos
    $NavigationRegion3D/EnvironmentProps3D.add_child(root)
    _cylinder(root, Vector3(0, 0.55, 0), 0.42, 1.1, metal, true)
    var flame := MeshInstance3D.new()
    var flame_mesh := SphereMesh.new()
    flame_mesh.radius = 0.28
    flame_mesh.height = 0.8
    flame.mesh = flame_mesh
    flame.material_override = warm_glow
    flame.position = Vector3(0, 1.25, 0)
    root.add_child(flame)
    var light := OmniLight3D.new()
    light.position = Vector3(0, 1.4, 0)
    light.light_color = Color(1.0, 0.28, 0.07)
    light.light_energy = 2.0
    light.omni_range = 7.0
    light.shadow_enabled = false
    root.add_child(light)

func _fence(pos: Vector3, length: float) -> void:
    var root := Node3D.new()
    root.position = pos
    $NavigationRegion3D/EnvironmentProps3D.add_child(root)
    var count := int(length / 2.0)
    for i in range(count + 1):
        _cylinder(root, Vector3(float(i) * 2.0, 1.25, 0), 0.055, 2.5, metal, true)
    _box(root, Vector3(length * 0.5, 0.25, 0), Vector3(length, 0.07, 0.07), metal, false)
    _box(root, Vector3(length * 0.5, 2.35, 0), Vector3(length, 0.07, 0.07), metal, false)

func _abandoned_house(pos: Vector3) -> void:
    var root := StaticBody3D.new()
    root.position = pos
    $NavigationRegion3D/EnvironmentProps3D.add_child(root)
    _add_box_mesh(root, Vector3(0, 0.12, 0), Vector3(11.0, 0.24, 8.0), concrete, true)
    _add_box_mesh(root, Vector3(0, 1.65, -3.85), Vector3(11.0, 3.3, 0.3), brick, true)
    _add_box_mesh(root, Vector3(-5.35, 1.65, 0), Vector3(0.3, 3.3, 7.7), brick, true)
    _add_box_mesh(root, Vector3(5.35, 1.65, 0), Vector3(0.3, 3.3, 7.7), brick, true)
    _add_box_mesh(root, Vector3(-3.75, 1.65, 3.85), Vector3(3.2, 3.3, 0.3), brick, true)
    _add_box_mesh(root, Vector3(3.75, 1.65, 3.85), Vector3(3.2, 3.3, 0.3), brick, true)
    _add_box_mesh(root, Vector3(0, 3.05, 3.85), Vector3(4.3, 0.5, 0.3), brick, true)
    _add_box_mesh(root, Vector3(0, 1.25, -1.0), Vector3(0.25, 2.5, 4.8), concrete, true)
    _add_box_mesh(root, Vector3(-5.12, 2.0, -1.2), Vector3(0.12, 0.18, 2.0), metal, true)
    _add_box_mesh(root, Vector3(5.12, 2.0, -1.2), Vector3(0.12, 0.18, 2.0), metal, true)
    _add_box_mesh(root, Vector3(0, 3.35, 0), Vector3(11.4, 0.28, 8.4), concrete, true)

func _build_loot_containers() -> void:
    _spawn_loot(Vector3(-3.5, 0.0, -3.5), "Terk edilmiş sandık")
    _spawn_loot(Vector3(14.0, 0.0, 2.0), "Araç bagajı")
    _spawn_loot(Vector3(-17.0, 0.0, 10.0), "Malzeme dolabı")

func _spawn_loot(pos: Vector3, label: String) -> void:
    var container := LOOT_SCENE.instantiate()
    container.position = pos
    container.container_label = label
    $NavigationRegion3D/EnvironmentProps3D.add_child(container)

func _apply_mobile_visibility_ranges() -> void:
    var props := $NavigationRegion3D/EnvironmentProps3D
    for node in props.find_children("*", "MeshInstance3D", true, false):
        var mesh_instance := node as MeshInstance3D
        mesh_instance.visibility_range_end = 70.0
        mesh_instance.visibility_range_end_margin = 10.0
        mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

# ------------------------------------------------------------ gerçekçilik / şehir

func _noise_texture(frequency: float, as_normal: bool) -> NoiseTexture2D:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = frequency
    var texture := NoiseTexture2D.new()
    texture.width = 256
    texture.height = 256
    texture.seamless = true
    texture.noise = noise
    if as_normal:
        texture.as_normal_map = true
        texture.bump_strength = 7.0
    else:
        var ramp := Gradient.new()
        ramp.set_color(0, Color(0.45, 0.45, 0.45))
        ramp.set_color(1, Color(1.0, 1.0, 1.0))
        texture.color_ramp = ramp
    return texture

func _texture_material(material: StandardMaterial3D, tiling: float, frequency: float) -> void:
    material.albedo_texture = _noise_texture(frequency, false)
    material.normal_enabled = true
    material.normal_texture = _noise_texture(frequency * 2.5, true)
    material.normal_scale = 0.9
    material.uv1_triplanar = true
    material.uv1_scale = Vector3(tiling, tiling, tiling)

func _build_city() -> void:
    var props := $NavigationRegion3D/EnvironmentProps3D
    # Sınır duvarları: oyuncu ve düşmanlar haritadan düşmesin.
    _box(props, Vector3(0, 2.0, -34.6), Vector3(70, 4.0, 0.8), concrete, true)
    _box(props, Vector3(0, 2.0, 34.6), Vector3(70, 4.0, 0.8), concrete, true)
    _box(props, Vector3(-34.6, 2.0, 0), Vector3(0.8, 4.0, 70), concrete, true)
    _box(props, Vector3(34.6, 2.0, 0), Vector3(0.8, 4.0, 70), concrete, true)
    # Kuzey sırası (ön yüz güneye bakar) ve güney sırası (ön yüz kuzeye bakar).
    _building(Vector3(-24, 0, -26), Vector3(12, 9, 10), 1.0)
    _building(Vector3(-9, 0, -26), Vector3(12, 12, 10), 1.0)
    _building(Vector3(6, 0, -26), Vector3(12, 8, 10), 1.0)
    _building(Vector3(-22, 0, 26), Vector3(12, 10, 10), -1.0)
    _building(Vector3(-6, 0, 26), Vector3(14, 12, 10), -1.0)
    _building(Vector3(12, 0, 26), Vector3(12, 9, 10), -1.0)
    _building(Vector3(27, 0, 26), Vector3(10, 11, 10), -1.0)
    # Ek araçlar, çöp konteynerleri ve yanan variller
    _car_wreck(Vector3(-20, 0, -8), 0.5)
    _car_wreck(Vector3(18, 0, -5), -0.4)
    _car_wreck(Vector3(1, 0, 12), 1.4)
    _burning_barrel(Vector3(20, 0, -8))
    _burning_barrel(Vector3(-20, 0, -15))
    _box(props, Vector3(-13, 0.65, -15.5), Vector3(2.2, 1.3, 1.2), dumpster_green, true)
    _box(props, Vector3(13, 0.65, 8.5), Vector3(2.2, 1.3, 1.2), dumpster_green, true)
    for crate in [Vector3(8, 0.5, 12), Vector3(9.1, 0.5, 12.2), Vector3(8.5, 1.5, 12.1), Vector3(-9, 0.5, -3), Vector3(-26, 0.5, 4)]:
        _box(props, crate, Vector3(1.0, 1.0, 1.0), brick, true)

func _building(pos: Vector3, size: Vector3, front_sign: float) -> void:
    var props := $NavigationRegion3D/EnvironmentProps3D
    _box(props, pos + Vector3(0, size.y * 0.5, 0), size, brick, true)
    _box(props, pos + Vector3(0, size.y + 0.15, 0), Vector3(size.x + 0.5, 0.3, size.z + 0.5), concrete, false)
    var front_z := pos.z + front_sign * (size.z * 0.5 + 0.05)
    var columns := maxi(1, int(size.x / 3.0))
    var rows := maxi(1, int((size.y - 1.5) / 3.2))
    for row in range(rows):
        for column in range(columns):
            var window_x := pos.x - size.x * 0.5 + (float(column) + 0.5) * (size.x / float(columns))
            var window_y := 2.6 + float(row) * 3.2
            var lit := randf() < 0.3
            _add_box_mesh(props, Vector3(window_x, window_y, front_z), Vector3(1.3, 1.5, 0.1), window_lit if lit else window_dark, false)
    var door_mat := metal
    _add_box_mesh(props, Vector3(pos.x, 1.1, front_z), Vector3(1.4, 2.2, 0.12), door_mat, false)
    if randf() < 0.5:
        var sign_y := 4.2
        _add_box_mesh(props, Vector3(pos.x + size.x * 0.3, sign_y, front_z + front_sign * 0.1), Vector3(2.2, 0.5, 0.1), neon_red, false)
        var glow := OmniLight3D.new()
        glow.position = Vector3(pos.x + size.x * 0.3, sign_y, front_z + front_sign * 1.5)
        glow.light_color = Color(1.0, 0.1, 0.22)
        glow.light_energy = 1.4
        glow.omni_range = 8.0
        props.add_child(glow)

func _start_director() -> void:
    var director := Node.new()
    director.name = "GameDirector"
    director.set_script(DIRECTOR_SCRIPT)
    add_child(director)
