extends Node3D
@export_enum("leader","vanguard","walker") var archetype := "leader"
@export var animated := true
var la: Node3D
var ra: Node3D
var ll: Node3D
var rl: Node3D
var head: Node3D
var phase := 0.0
var outline: Shader
func _ready():
    outline = load("res://shaders/ink_outline.gdshader")
    build()
func _process(delta):
    if not animated: return
    phase += delta * (1.6 if archetype == "walker" else 2.6)
    var stride = sin(phase) * (0.09 if archetype == "walker" else 0.2)
    ll.rotation.x = stride
    rl.rotation.x = -stride
    if archetype == "walker":
        la.rotation.x = -1.0 + stride * 0.2
        ra.rotation.x = -1.0 - stride * 0.2
        la.rotation.z = -0.22 + sin(phase) * 0.03
        ra.rotation.z = 0.22 - sin(phase) * 0.03
        rotation.z = sin(phase * 0.5) * 0.045
        head.rotation.z = sin(phase * 0.7) * 0.06
    elif archetype == "leader":
        la.rotation.x = -stride * 0.4
        ra.rotation.x = -0.65 + stride * 0.2
    else:
        la.rotation.x = -stride * 0.6
        ra.rotation.x = stride * 0.6
func build():
    var skin = mat("#77736f")
    var cloth = mat("#24262a")
    var pants = mat("#353638")
    var metal = mat("#aaa39a",0.55)
    var dark = mat("#111214")
    var wound = mat("#4c2023")
    capsule("Torso",0.34,0.66,cloth,Vector3(0,1.16,0))
    box("Chest",Vector3(0.52,0.4,0.2),pants,Vector3(0,1.24,-0.12))
    head = Node3D.new()
    head.position = Vector3(0,1.72,0)
    add_child(head)
    sphere(head,"Head",Vector3(0.23,0.27,0.22),skin,Vector3.ZERO)
    box("Hair",Vector3(0.42,0.10,0.4),dark,Vector3(0,1.96,0.015))
    sphere(self,"LeftEye",Vector3(0.045,0.035,0.025),mat("#d0ccc3"),Vector3(-0.085,1.77,-0.205))
    sphere(self,"RightEye",Vector3(0.045,0.035,0.025),mat("#d0ccc3"),Vector3(0.085,1.77,-0.205))
    box("EyeShadeL",Vector3(0.10,0.055,0.025),dark,Vector3(-0.085,1.79,-0.225))
    box("EyeShadeR",Vector3(0.10,0.055,0.025),dark,Vector3(0.085,1.79,-0.225))
    box("MouthScar",Vector3(0.12,0.025,0.025),wound,Vector3(0,1.62,-0.225))
    ll = limb("LeftLeg",Vector3(-0.16,0.72,0),0.13,0.62,pants)
    rl = limb("RightLeg",Vector3(0.16,0.72,0),0.13,0.62,pants)
    la = limb("LeftArm",Vector3(-0.43,1.38,0),0.105,0.57,skin)
    ra = limb("RightArm",Vector3(0.43,1.38,0),0.105,0.57,skin)
    sphere(self,"LeftHand",Vector3(0.12,0.12,0.12),skin,Vector3(-0.43,1.08,0))
    sphere(self,"RightHand",Vector3(0.12,0.12,0.12),skin,Vector3(0.43,1.08,0))
    box("BootL",Vector3(0.22,0.13,0.34),dark,Vector3(-0.16,0.12,-0.06))
    box("BootR",Vector3(0.22,0.13,0.34),dark,Vector3(0.16,0.12,-0.06))
    if archetype == "leader":
        box("LeatherJacketLapel",Vector3(0.16,0.46,0.08),dark,Vector3(-0.12,1.38,-0.19))
        box("LeatherJacketLapelR",Vector3(0.16,0.46,0.08),dark,Vector3(0.12,1.38,-0.19))
        cylinder("SpikedBat",0.055,0.085,0.95,mat("#57483c"),Vector3(0.48,1.42,-0.10))
        for i in range(8):
            var barb = cylinder("BarbedWire%d" % i,0.012,0.012,0.23,metal,Vector3(0.48,1.43+i*0.06,-0.12))
            barb.rotation_degrees = Vector3(90,0,45+i*25)
        ra.rotation.x = -0.65
    elif archetype == "vanguard":
        box("TacticalVest",Vector3(0.55,0.5,0.23),pants,Vector3(0,1.22,-0.14))
        for i in range(3):
            box("AmmoPouch%d" % i,Vector3(0.11,0.14,0.07),metal,Vector3(-0.17+i*0.17,1.18,-0.27))
        cylinder("AxeHandle",0.035,0.035,0.82,mat("#5b4634"),Vector3(0.52,1.2,-0.1))
        box("AxeHead",Vector3(0.34,0.20,0.07),metal,Vector3(0.69,1.56,-0.1))
        var gun = box("BackShotgun",Vector3(0.13,0.92,0.13),mat("#363432"),Vector3(0.20,1.45,0.19))
        gun.rotation_degrees.z = -12
    else:
        box("TornShirt",Vector3(0.60,0.42,0.25),mat("#45413e"),Vector3(0,1.25,-0.02))
        box("TornHemA",Vector3(0.20,0.15,0.12),dark,Vector3(-0.18,0.94,-0.02))
        box("TornHemB",Vector3(0.18,0.12,0.12),dark,Vector3(0.18,0.92,-0.02))
        box("CheekWound",Vector3(0.07,0.10,0.025),wound,Vector3(-0.16,1.70,-0.20))
        box("NeckWound",Vector3(0.12,0.05,0.025),wound,Vector3(0.04,1.49,-0.19))
        la.rotation.x = -1.0
        ra.rotation.x = -1.0
        la.rotation.z = -0.22
        ra.rotation.z = 0.22
func limb(label,pos,radius,length,material):
    var pivot = Node3D.new()
    pivot.name = label
    pivot.position = pos
    add_child(pivot)
    capsule(label+"Mesh",radius,length,material,Vector3(0,-length*0.5,0),pivot)
    return pivot
func capsule(label,radius,height,material,pos,parent=null):
    var mesh = CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return add_mesh(label,mesh,material,pos,parent)
func sphere(parent,label,dimensions,material,pos):
    var mesh = SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    var node = add_mesh(label,mesh,material,pos,parent)
    node.scale = dimensions * 2.0
func box(label,dimensions,material,pos):
    var mesh = BoxMesh.new()
    mesh.size = dimensions
    return add_mesh(label,mesh,material,pos)
func cylinder(label,top,bottom,height,material,pos):
    var mesh = CylinderMesh.new()
    mesh.top_radius = top
    mesh.bottom_radius = bottom
    mesh.height = height
    return add_mesh(label,mesh,material,pos)
func add_mesh(label,mesh,material,pos,parent=null):
    var node = MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    (self if parent == null else parent).add_child(node)
    return node
func mat(color,rough=0.92):
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(color)
    material.roughness = rough
    material.metallic = 0.08
    var ink = ShaderMaterial.new()
    ink.shader = outline
    material.next_pass = ink
    return material
