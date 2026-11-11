extends Node3D
## Stylized human hostile survivor, not a zombie.

func _ready() -> void:
    var coat := StandardMaterial3D.new()
    coat.albedo_color = Color("#252a31")
    coat.roughness = 0.9
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#92715f")
    var pants := StandardMaterial3D.new()
    pants.albedo_color = Color("#171b20")
    _capsule("Body", Vector3(0, 1.05, 0), 0.36, 0.9, coat)
    _capsule("Head", Vector3(0, 1.78, 0), 0.19, 0.38, skin)
    _capsule("LegLeft", Vector3(-0.14, 0.42, 0), 0.12, 0.62, pants)
    _capsule("LegRight", Vector3(0.14, 0.42, 0), 0.12, 0.62, pants)
    _capsule("ArmLeft", Vector3(-0.43, 1.12, 0), 0.105, 0.62, coat)
    _capsule("ArmRight", Vector3(0.43, 1.12, 0), 0.105, 0.62, coat)

func _capsule(label: String, pos: Vector3, radius: float, height: float, material: Material) -> void:
    var mesh_node := MeshInstance3D.new()
    mesh_node.name = label
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    mesh_node.mesh = mesh
    mesh_node.material_override = material
    mesh_node.position = pos
    add_child(mesh_node)
